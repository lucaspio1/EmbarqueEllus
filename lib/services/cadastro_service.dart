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
        print('✅ [CadastroService] Dados carregados para cadastro de pulseiras: $colegio');
      } else {
        passageirosCadastro.value = [];
        _stopSyncTimer();
        print('❌ [CadastroService] Erro ao buscar dados: ${response.statusCode}');
      }
    } catch (e) {
      passageirosCadastro.value = [];
      _stopSyncTimer();
      print('❌ [CadastroService] Erro de conexão ao buscar dados: $e');
    }
  }

  Future<void> saveLocalData(String colegio, String onibus, List<Passageiro> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('colegio_cadastro', colegio);
    await prefs.setString('onibus_cadastro', onibus);
    await prefs.setString('flowType_cadastro', 'pulseiras');

    final listaJson = json.encode(lista.map((p) => p.toJson()).toList());
    await prefs.setString('passageiros_cadastro_json', listaJson);

    // 🔎 Debug
    print("📌 [CadastroService] Dados salvos no local:");
    print("   colegio_cadastro = $colegio");
    print("   onibus_cadastro = $onibus");
    print("   flowType_cadastro = pulseiras");
    print("   passageiros_cadastro_json = ${lista.length} passageiros");
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

        print('✅ [CadastroService] Lista de passageiros carregada do armazenamento local.');
      } catch (e) {
        print('❌ [CadastroService] Erro ao carregar lista local: $e');
        passageirosCadastro.value = [];
      }
    } else {
      passageirosCadastro.value = [];
      print('⚠️ [CadastroService] Nenhuma lista encontrada no armazenamento local.');
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

      // 🔎 Debug
      print("📌 [CadastroService] Pulseira atualizada para ${updatedPassageiro.nome}: ${updatedPassageiro.pulseira}");

      saveLocalData(
        _colegioSelecionado,
        _onibusSelecionado,
        currentList,
      );

      print('📌 [CadastroService] Adicionado à lista de sincronização: ${updatedPassageiro.nome}');
      print('   Total pendentes: ${_pendentesDeSincronizacao.length}');

      if (_syncTimer == null || !_syncTimer!.isActive) {
        _startSyncTimer();
      }
    }
  }

  Future<void> _savePendingData() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = json.encode(_pendentesDeSincronizacao.map((p) => p.toJson()).toList());
    await prefs.setString('pending_sync_data_cadastro', pendingJson);
    print('📌 [CadastroService] Lista de sincronização salva localmente (${_pendentesDeSincronizacao.length} itens).');
  }

  Future<void> _loadPendingData() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString('pending_sync_data_cadastro');
    if (pendingJson != null) {
      try {
        final List<dynamic> jsonData = json.decode(pendingJson);
        _pendentesDeSincronizacao = List<Passageiro>.from(
            jsonData.map((json) => Passageiro.fromJson(json)));
        print('📌 [CadastroService] Lista de sincronização carregada (${_pendentesDeSincronizacao.length} itens).');
        if (_pendentesDeSincronizacao.isNotEmpty) {
          _startSyncTimer();
        }
      } catch (e) {
        print('❌ [CadastroService] Erro ao carregar lista de sincronização: $e');
        _pendentesDeSincronizacao.clear();
      }
    }
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _syncChanges();
    });
    print('⏳ [CadastroService] Timer de sincronização iniciado.');
  }

  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('⏹️ [CadastroService] Timer de sincronização parado.');
  }

  Future<void> _syncChanges() async {
    if (_pendentesDeSincronizacao.isEmpty) {
      _stopSyncTimer();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_sync_data_cadastro');
      print('✅ [CadastroService] Sincronização concluída, lista limpa.');
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
          print('✅ [CadastroService] Sincronização ok: ${passageiroParaSincronizar.nome}');
        } else {
          print('❌ [CadastroService] Erro API: ${responseData['mensagem']}');
          _pendentesDeSincronizacao.add(passageiroParaSincronizar);
          _savePendingData();
        }
      } else if (response.statusCode == 302) {
        print('⚠️ [CadastroService] Redirecionamento 302 ignorado, sync considerado ok para ${passageiroParaSincronizar.nome}');
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [CadastroService] Erro ao sincronizar ${passageiroParaSincronizar.nome}: $e');
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
