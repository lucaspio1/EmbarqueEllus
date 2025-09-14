import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:embarque_app/models/passageiro.dart';
import 'package:embarque_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CadastroService {
  static final CadastroService _instance = CadastroService._internal();

  factory CadastroService() => _instance;

  CadastroService._internal() {
    _loadPendingData();
  }

  final ValueNotifier<List<Passageiro>> passageirosCadastro = ValueNotifier([]);

  String _colegioSelecionado = '';
  String _onibusSelecionado = '';
  Timer? _syncTimer;
  List<Passageiro> _pendentesDeSincronizacao = [];

  Future<void> fetchData(String colegio, String? onibus) async {
    _colegioSelecionado = colegio;
    _onibusSelecionado = onibus ?? '';

    try {
      final response = await http.get(Uri.parse('$apiUrl?colegio=$colegio&onibus=$onibus'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<Passageiro> fetchedList = List<Passageiro>.from(
            jsonData['passageiros'].map((json) => Passageiro.fromJson(json)));

        fetchedList.forEach((passageiro) => passageiro.flowType = 'pulseiras');
        passageirosCadastro.value = fetchedList;

        _pendentesDeSincronizacao.clear();
        _startSyncTimer();
        print('Dados carregados para cadastro de pulseiras: $colegio. Timer de sincronização ativo.');
      } else {
        passageirosCadastro.value = [];
        _stopSyncTimer();
      }
    } catch (e) {
      passageirosCadastro.value = [];
      _stopSyncTimer();
      print('Erro de conexão ao buscar dados: $e');
    }
  }

  Future<void> saveLocalData(String colegio, String onibus, List<Passageiro> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('colegio_cadastro', colegio);
    await prefs.setString('onibus_cadastro', onibus);
    await prefs.setString('flowType_cadastro', 'pulseiras');

    final listaJson = json.encode(lista.map((p) => p.toJson()).toList());
    await prefs.setString('passageiros_cadastro_json', listaJson);

    print('Dados do cadastro de pulseiras e lista de passageiros salvos localmente.');
  }

  Future<void> loadLocalData(String colegio, String onibus) async {
    final prefs = await SharedPreferences.getInstance();
    _colegioSelecionado = colegio;
    _onibusSelecionado = onibus;

    String? listaJson = prefs.getString('passageiros_cadastro_json');

    if (listaJson != null) {
      try {
        final List<dynamic> jsonData = json.decode(listaJson);
        final List<Passageiro> loadedList = List<Passageiro>.from(
            jsonData.map((json) => Passageiro.fromJson(json)));

        loadedList.forEach((passageiro) => passageiro.flowType = 'pulseiras');
        passageirosCadastro.value = loadedList;

        print('Lista de passageiros carregada do armazenamento local para cadastro de pulseiras.');
      } catch (e) {
        print('Erro ao carregar lista de passageiros local para cadastro de pulseiras: $e');
        passageirosCadastro.value = [];
      }
    } else {
      passageirosCadastro.value = [];
      print('Nenhuma lista de passageiros encontrada no armazenamento local para cadastro de pulseiras.');
    }
  }

  void updateLocalData(Passageiro passageiro, {String? novaPulseira}) {
    final currentList = List<Passageiro>.from(passageirosCadastro.value);
    final index = currentList.indexWhere((p) => p.nome == passageiro.nome);

    if (index != -1) {
      Passageiro updatedPassageiro = currentList[index].copyWith(
        pulseira: novaPulseira ?? passageiro.pulseira,
      );

      currentList[index] = updatedPassageiro;
      passageirosCadastro.value = currentList;

      _pendentesDeSincronizacao.add(updatedPassageiro);
      _savePendingData();

      saveLocalData(
          _colegioSelecionado,
          _onibusSelecionado,
          currentList);

      print('Adicionado à lista de sincronização: ${updatedPassageiro.nome}');
      print('Total de pendentes: ${_pendentesDeSincronizacao.length}');

      if (_syncTimer == null || !_syncTimer!.isActive) {
        _startSyncTimer();
      }
    }
  }

  Future<void> _savePendingData() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = json.encode(_pendentesDeSincronizacao.map((p) => p.toJson()).toList());
    await prefs.setString('pending_sync_data_cadastro', pendingJson);
    print('Lista de sincronização para cadastro salva localmente.');
  }

  Future<void> _loadPendingData() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString('pending_sync_data_cadastro');
    if (pendingJson != null) {
      try {
        final List<dynamic> jsonData = json.decode(pendingJson);
        _pendentesDeSincronizacao = List<Passageiro>.from(jsonData.map((json) => Passageiro.fromJson(json)));
        print('Lista de sincronização para cadastro carregada do armazenamento local. Total: ${_pendentesDeSincronizacao.length}');
        if (_pendentesDeSincronizacao.isNotEmpty) {
          _startSyncTimer();
        }
      } catch (e) {
        print('Erro ao carregar lista de sincronização local para cadastro: $e');
        _pendentesDeSincronizacao.clear();
      }
    }
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _syncChanges();
    });
  }

  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _syncChanges() async {
    if (_pendentesDeSincronizacao.isEmpty) {
      _stopSyncTimer();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_sync_data_cadastro');
      print('Sincronização do cadastro concluída. Lista de pendentes limpa.');
      return;
    }

    final passageiroParaSincronizar = _pendentesDeSincronizacao.removeAt(0);
    _savePendingData();

    try {
      final requestBody = {
        'colegio': _colegioSelecionado,
        'nome': passageiroParaSincronizar.nome,
        'novaPulseira': passageiroParaSincronizar.pulseira,
        'operacao': 'cadastro',
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'sucesso') {
          print('✅ Sincronização bem-sucedida para: ${passageiroParaSincronizar.nome}');
        } else {
          print('❌ Erro na API: ${responseData['mensagem']}');
          _pendentesDeSincronizacao.add(passageiroParaSincronizar);
          _savePendingData();
        }
      } else if (response.statusCode == 302) {
        print('⚠️ Redirecionamento 302 ignorar, sincronização considerada concluída para: ${passageiroParaSincronizar.nome}');
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao sincronizar dados: $e');
      _pendentesDeSincronizacao.add(passageiroParaSincronizar);
      _savePendingData();
    }
  }

  void forceSyncAll() {
    while (_pendentesDeSincronizacao.isNotEmpty) {
      _syncChanges();
    }
  }
}
