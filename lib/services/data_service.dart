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

  // APENAS para embarque
  final ValueNotifier<List<Passageiro>> passageirosEmbarque = ValueNotifier([]);

  String _colegioSelecionado = '';
  String _onibusSelecionado = '';
  Timer? _syncTimer;
  List<Passageiro> _pendentesDeSincronizacao = [];

  Future<void> fetchData(String colegio, {String? onibus}) async {
    _colegioSelecionado = colegio;
    _onibusSelecionado = onibus ?? '';

    try {
      final response = await http.get(Uri.parse('$apiUrl?colegio=$colegio&onibus=$onibus'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<Passageiro> fetchedList = List<Passageiro>.from(
            jsonData['passageiros'].map((json) => Passageiro.fromJson(json)));

        fetchedList.forEach((passageiro) => passageiro.flowType = 'embarque');
        passageirosEmbarque.value = fetchedList;

        _pendentesDeSincronizacao.clear();
        _startSyncTimer();
        print('✅ [DataService] Dados carregados para embarque: $colegio');
      } else {
        passageirosEmbarque.value = [];
        _stopSyncTimer();
        print('❌ [DataService] Erro ao buscar dados: ${response.statusCode}');
      }
    } catch (e) {
      passageirosEmbarque.value = [];
      _stopSyncTimer();
      print('❌ [DataService] Erro de conexão: $e');
    }
  }

  Future<void> saveLocalData(String colegio, String onibus, List<Passageiro> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('colegio', colegio);
    await prefs.setString('onibus', onibus);
    await prefs.setString('flowType', 'embarque');

    final listaJson = json.encode(lista.map((p) => p.toJson()).toList());
    await prefs.setString('passageiros_embarque_json', listaJson);

    print('📌 [DataService] Dados do embarque salvos localmente.');
  }

  Future<void> loadLocalData(String colegio, String onibus) async {
    final prefs = await SharedPreferences.getInstance();
    _colegioSelecionado = colegio;
    _onibusSelecionado = onibus;

    String? listaJson = prefs.getString('passageiros_embarque_json');

    if (listaJson != null) {
      try {
        final List<dynamic> jsonData = json.decode(listaJson);
        final List<Passageiro> loadedList = List<Passageiro>.from(
            jsonData.map((json) => Passageiro.fromJson(json)));

        loadedList.forEach((passageiro) => passageiro.flowType = 'embarque');
        passageirosEmbarque.value = loadedList;

        print('✅ [DataService] Lista de embarque carregada do local.');
      } catch (e) {
        print('❌ [DataService] Erro ao carregar lista local: $e');
        passageirosEmbarque.value = [];
      }
    } else {
      passageirosEmbarque.value = [];
      print('⚠️ [DataService] Nenhuma lista de embarque encontrada no local.');
    }
  }

  void updateLocalData(Passageiro passageiro, {String? novoEmbarque}) {
    final currentList = List<Passageiro>.from(passageirosEmbarque.value);
    final index = currentList.indexWhere((p) => p.nome == passageiro.nome);

    if (index != -1) {
      Passageiro updatedPassageiro = currentList[index].copyWith(
        embarque: novoEmbarque ?? passageiro.embarque,
      );

      currentList[index] = updatedPassageiro;
      passageirosEmbarque.value = currentList;

      _pendentesDeSincronizacao.add(updatedPassageiro);
      _savePendingData();

      saveLocalData(_colegioSelecionado, _onibusSelecionado, currentList);

      print('📌 [DataService] Embarque atualizado: ${updatedPassageiro.nome} -> ${updatedPassageiro.embarque}');

      if (_syncTimer == null || !_syncTimer!.isActive) {
        _startSyncTimer();
      }
    }
  }

  Future<void> _savePendingData() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = json.encode(_pendentesDeSincronizacao.map((p) => p.toJson()).toList());
    await prefs.setString('pending_sync_data_embarque', pendingJson);
    print('📌 [DataService] Lista de sincronização salva (${_pendentesDeSincronizacao.length} itens).');
  }

  Future<void> _loadPendingData() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString('pending_sync_data_embarque');
    if (pendingJson != null) {
      try {
        final List<dynamic> jsonData = json.decode(pendingJson);
        _pendentesDeSincronizacao = List<Passageiro>.from(
            jsonData.map((json) => Passageiro.fromJson(json)));
        print('📌 [DataService] Lista de sincronização carregada (${_pendentesDeSincronizacao.length} itens).');
        if (_pendentesDeSincronizacao.isNotEmpty) {
          _startSyncTimer();
        }
      } catch (e) {
        print('❌ [DataService] Erro ao carregar sincronização: $e');
        _pendentesDeSincronizacao.clear();
      }
    }
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _syncChanges();
    });
    print('⏳ [DataService] Timer de sincronização iniciado.');
  }

  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('⏹️ [DataService] Timer de sincronização parado.');
  }

  Future<void> _syncChanges() async {
    if (_pendentesDeSincronizacao.isEmpty) {
      _stopSyncTimer();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_sync_data_embarque');
      print('✅ [DataService] Sincronização embarque concluída.');
      return;
    }

    final passageiroParaSincronizar = _pendentesDeSincronizacao.removeAt(0);
    _savePendingData();

    try {
      final requestBody = {
        'colegio': _colegioSelecionado,
        'nome': passageiroParaSincronizar.nome,
        'novoStatus': passageiroParaSincronizar.embarque,
        'operacao': 'embarque',
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
          print('✅ [DataService] Sync embarque OK: ${passageiroParaSincronizar.nome}');
        } else {
          print('❌ [DataService] Erro API: ${responseData['mensagem']}');
          _pendentesDeSincronizacao.add(passageiroParaSincronizar);
          _savePendingData();
        }
      } else if (response.statusCode == 302) {
        print('⚠️ [DataService] Redirecionamento 302 ignorado, sync OK: ${passageiroParaSincronizar.nome}');
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [DataService] Erro ao sincronizar embarque: $e');
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