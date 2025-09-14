import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:embarque_app/models/passageiro.dart';
import 'package:embarque_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataService {
  static final DataService _instance = DataService._internal();

  factory DataService() => _instance;

  DataService._internal() {
    _loadPendingData();
  }

  // Listas separadas para cada fluxo
  final ValueNotifier<List<Passageiro>> passageirosEmbarque = ValueNotifier([]);
  final ValueNotifier<List<Passageiro>> passageirosCadastro = ValueNotifier([]);

  String _colegioSelecionado = '';
  String _onibusSelecionado = '';
  String _flowType = '';
  Timer? _syncTimer;
  List<Passageiro> _pendentesDeSincronizacao = [];

  Future<void> fetchData(String colegio, String flowType, {String? onibus}) async {
    _colegioSelecionado = colegio;
    _onibusSelecionado = onibus ?? '';
    _flowType = flowType;

    try {
      final response = await http.get(Uri.parse('$apiUrl?colegio=$colegio&onibus=$onibus'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<Passageiro> fetchedList = List<Passageiro>.from(
            jsonData['passageiros'].map((json) => Passageiro.fromJson(json)));

        fetchedList.forEach((passageiro) => passageiro.flowType = flowType);

        if (_flowType == 'embarque') {
          passageirosEmbarque.value = fetchedList;
        } else if (_flowType == 'pulseiras') {
          passageirosCadastro.value = fetchedList;
        }

        _pendentesDeSincronizacao.clear();
        _startSyncTimer();
        print('Dados carregados para $_flowType: $colegio. Timer de sincronização ativo.');
      } else {
        if (_flowType == 'embarque') {
          passageirosEmbarque.value = [];
        } else if (_flowType == 'pulseiras') {
          passageirosCadastro.value = [];
        }
        _stopSyncTimer();
      }
    } catch (e) {
      if (_flowType == 'embarque') {
        passageirosEmbarque.value = [];
      } else if (_flowType == 'pulseiras') {
        passageirosCadastro.value = [];
      }
      _stopSyncTimer();
      print('Erro de conexão ao buscar dados: $e');
    }
  }

  Future<void> saveLocalData(String colegio, String onibus, String flowType, List<Passageiro> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('colegio', colegio);
    await prefs.setString('onibus', onibus);
    await prefs.setString('flowType', flowType);

    final listaJson = json.encode(lista.map((p) => p.toJson()).toList());
    if (flowType == 'embarque') {
      await prefs.setString('passageiros_embarque_json', listaJson);
    } else if (flowType == 'pulseiras') {
      await prefs.setString('passageiros_cadastro_json', listaJson);
    }

    print('Dados do $flowType e lista de passageiros salvos localmente.');
  }

  Future<void> loadLocalData(String colegio, String onibus, String flowType) async {
    final prefs = await SharedPreferences.getInstance();
    _colegioSelecionado = colegio;
    _onibusSelecionado = onibus;
    _flowType = flowType;

    String? listaJson;
    if (flowType == 'embarque') {
      listaJson = prefs.getString('passageiros_embarque_json');
    } else if (flowType == 'pulseiras') {
      listaJson = prefs.getString('passageiros_cadastro_json');
    }

    if (listaJson != null) {
      try {
        final List<dynamic> jsonData = json.decode(listaJson);
        final List<Passageiro> loadedList = List<Passageiro>.from(
            jsonData.map((json) => Passageiro.fromJson(json)));

        // CORREÇÃO: Assegura que o flowType é setado após o carregamento local.
        loadedList.forEach((passageiro) => passageiro.flowType = flowType);

        if (flowType == 'embarque') {
          passageirosEmbarque.value = loadedList;
        } else if (flowType == 'pulseiras') {
          passageirosCadastro.value = loadedList;
        }

        print('Lista de passageiros carregada do armazenamento local para $flowType.');
      } catch (e) {
        print('Erro ao carregar lista de passageiros local para $flowType: $e');
        if (flowType == 'embarque') {
          passageirosEmbarque.value = [];
        } else if (flowType == 'pulseiras') {
          passageirosCadastro.value = [];
        }
      }
    } else {
      if (flowType == 'embarque') {
        passageirosEmbarque.value = [];
      } else if (flowType == 'pulseiras') {
        passageirosCadastro.value = [];
      }
      print('Nenhuma lista de passageiros encontrada no armazenamento local para $flowType.');
    }
  }

  Future<void> _savePendingData() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = json.encode(_pendentesDeSincronizacao.map((p) => p.toJson()).toList());
    await prefs.setString('pending_sync_data', pendingJson);
    print('Lista de sincronização salva localmente.');
  }

  Future<void> _loadPendingData() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString('pending_sync_data');
    if (pendingJson != null) {
      try {
        final List<dynamic> jsonData = json.decode(pendingJson);
        _pendentesDeSincronizacao = List<Passageiro>.from(jsonData.map((json) => Passageiro.fromJson(json)));
        print('Lista de sincronização carregada do armazenamento local. Total: ${_pendentesDeSincronizacao.length}');
        if (_pendentesDeSincronizacao.isNotEmpty) {
          _startSyncTimer();
        }
      } catch (e) {
        print('Erro ao carregar lista de sincronização local: $e');
        _pendentesDeSincronizacao.clear();
      }
    }
  }

  void updateLocalData(Passageiro passageiro,
      {String? novoEmbarque, String? novaPulseira}) {
    ValueNotifier<List<Passageiro>> targetList;
    if (passageiro.flowType == 'embarque') {
      targetList = passageirosEmbarque;
    } else {
      targetList = passageirosCadastro;
    }

    final currentList = List<Passageiro>.from(targetList.value);
    final index = currentList.indexWhere((p) => p.nome == passageiro.nome);

    if (index != -1) {
      Passageiro updatedPassageiro = currentList[index].copyWith(
        embarque: novoEmbarque ?? passageiro.embarque,
        pulseira: novaPulseira ?? passageiro.pulseira,
      );

      currentList[index] = updatedPassageiro;
      targetList.value = currentList;

      _pendentesDeSincronizacao.add(updatedPassageiro);
      _savePendingData();

      saveLocalData(
          _colegioSelecionado,
          _onibusSelecionado,
          passageiro.flowType!,
          currentList);

      print('Adicionado à lista de sincronização: ${updatedPassageiro.nome}');
      print('Total de pendentes: ${_pendentesDeSincronizacao.length}');

      if (_syncTimer == null || !_syncTimer!.isActive) {
        _startSyncTimer();
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
      await prefs.remove('pending_sync_data');
      print('Sincronização concluída. Lista de pendentes limpa.');
      return;
    }

    final passageiroParaSincronizar = _pendentesDeSincronizacao.removeAt(0);
    _savePendingData();

    try {
      final requestBody = {
        'colegio': _colegioSelecionado,
        'nome': passageiroParaSincronizar.nome,
        'novoStatus': passageiroParaSincronizar.embarque,
        'novaPulseira': passageiroParaSincronizar.pulseira,
        'operacao': 'geral',
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
        print('⚠️ Redirecionamento 302 ignorado, sincronização considerada concluída para: ${passageiroParaSincronizar.nome}');
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

  int getPendingCount() {
    return _pendentesDeSincronizacao.length;
  }
}