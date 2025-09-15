import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:embarque_app/models/passageiro.dart';
import 'package:embarque_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BaladaService {
  static final BaladaService _instance = BaladaService._internal();

  factory BaladaService() => _instance;

  BaladaService._internal() {
    _loadPendingData();
  }

  final ValueNotifier<List<Passageiro>> passageirosBalada = ValueNotifier([]);

  Timer? _syncTimer;
  List<Map<String, dynamic>> _pendentesDeSincronizacao = [];

  // Carregar todos os alunos da aba "todos"
  Future<void> fetchAllStudents() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl?todos=true'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<Passageiro> fetchedList = List<Passageiro>.from(
            jsonData['passageiros'].map((json) => Passageiro.fromJson(json)));

        fetchedList.forEach((passageiro) => passageiro.flowType = 'balada');
        passageirosBalada.value = fetchedList;

        _pendentesDeSincronizacao.clear();
        _startSyncTimer();
        print('✅ [BaladaService] ${fetchedList.length} alunos carregados para controle de balada');
      } else {
        passageirosBalada.value = [];
        _stopSyncTimer();
        print('❌ [BaladaService] Erro ao buscar dados: ${response.statusCode}');
      }
    } catch (e) {
      passageirosBalada.value = [];
      _stopSyncTimer();
      print('❌ [BaladaService] Erro de conexão: $e');
    }
  }

  Future<void> saveLocalData(List<Passageiro> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('flowType_balada', 'balada');

    final listaJson = json.encode(lista.map((p) => p.toJson()).toList());
    await prefs.setString('passageiros_balada_json', listaJson);

    print('📌 [BaladaService] Dados da balada salvos localmente.');
  }

  Future<void> loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    String? listaJson = prefs.getString('passageiros_balada_json');

    if (listaJson != null) {
      try {
        final List<dynamic> jsonData = json.decode(listaJson);
        final List<Passageiro> loadedList = List<Passageiro>.from(
            jsonData.map((json) => Passageiro.fromJson(json)));

        loadedList.forEach((passageiro) => passageiro.flowType = 'balada');
        passageirosBalada.value = loadedList;

        print('✅ [BaladaService] Lista da balada carregada do local.');
      } catch (e) {
        print('❌ [BaladaService] Erro ao carregar lista local: $e');
        passageirosBalada.value = [];
      }
    } else {
      passageirosBalada.value = [];
      print('⚠️ [BaladaService] Nenhuma lista da balada encontrada no local.');
    }
  }

  // Atualizar status do quarto por nome do aluno
  void updateLocalDataByName(String nomeAluno, {String? novoStatusQuarto}) {
    final currentList = List<Passageiro>.from(passageirosBalada.value);
    final index = currentList.indexWhere((p) => p.nome.toLowerCase().trim() == nomeAluno.toLowerCase().trim());

    if (index != -1) {
      Passageiro updatedPassageiro = currentList[index].copyWith(
        statusQuarto: novoStatusQuarto ?? currentList[index].statusQuarto,
      );

      currentList[index] = updatedPassageiro;
      passageirosBalada.value = currentList;

      _pendentesDeSincronizacao.add({
        'nome': updatedPassageiro.nome,
        'novoStatusQuarto': updatedPassageiro.statusQuarto,
      });
      _savePendingData();

      saveLocalData(currentList);

      print('📌 [BaladaService] Status quarto atualizado: ${updatedPassageiro.nome} -> ${updatedPassageiro.statusQuarto}');

      if (_syncTimer == null || !_syncTimer!.isActive) {
        _startSyncTimer();
      }
    } else {
      print('⚠️ [BaladaService] Aluno não encontrado: $nomeAluno');
    }
  }

  // Atualizar status do quarto por pulseira
  void updateLocalDataByPulseira(String codigoPulseira, {String? novoStatusQuarto}) {
    final currentList = List<Passageiro>.from(passageirosBalada.value);
    final index = currentList.indexWhere((p) => p.pulseira.trim() == codigoPulseira.trim());

    if (index != -1) {
      Passageiro updatedPassageiro = currentList[index].copyWith(
        statusQuarto: novoStatusQuarto ?? currentList[index].statusQuarto,
      );

      currentList[index] = updatedPassageiro;
      passageirosBalada.value = currentList;

      _pendentesDeSincronizacao.add({
        'pulseira': codigoPulseira,
        'nome': updatedPassageiro.nome,
        'novoStatusQuarto': updatedPassageiro.statusQuarto,
      });
      _savePendingData();

      saveLocalData(currentList);

      print('📌 [BaladaService] Status quarto atualizado por pulseira: ${updatedPassageiro.nome} (${codigoPulseira}) -> ${updatedPassageiro.statusQuarto}');

      if (_syncTimer == null || !_syncTimer!.isActive) {
        _startSyncTimer();
      }
    } else {
      print('⚠️ [BaladaService] Pulseira não encontrada: $codigoPulseira');
    }
  }

  // Buscar passageiro por pulseira
  Passageiro? findPassageiroByPulseira(String codigoPulseira) {
    final currentList = passageirosBalada.value;
    try {
      return currentList.firstWhere((p) => p.pulseira.trim() == codigoPulseira.trim());
    } catch (e) {
      return null;
    }
  }

  Future<void> _savePendingData() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = json.encode(_pendentesDeSincronizacao);
    await prefs.setString('pending_sync_data_balada', pendingJson);
    print('📌 [BaladaService] Lista de sincronização salva (${_pendentesDeSincronizacao.length} itens).');
  }

  Future<void> _loadPendingData() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString('pending_sync_data_balada');
    if (pendingJson != null) {
      try {
        final List<dynamic> jsonData = json.decode(pendingJson);
        _pendentesDeSincronizacao = List<Map<String, dynamic>>.from(jsonData);
        print('📌 [BaladaService] Lista de sincronização carregada (${_pendentesDeSincronizacao.length} itens).');
        if (_pendentesDeSincronizacao.isNotEmpty) {
          _startSyncTimer();
        }
      } catch (e) {
        print('❌ [BaladaService] Erro ao carregar sincronização: $e');
        _pendentesDeSincronizacao.clear();
      }
    }
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _syncChanges();
    });
    print('⏳ [BaladaService] Timer de sincronização iniciado.');
  }

  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('⏹️ [BaladaService] Timer de sincronização parado.');
  }

  Future<void> _syncChanges() async {
    if (_pendentesDeSincronizacao.isEmpty) {
      _stopSyncTimer();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_sync_data_balada');
      print('✅ [BaladaService] Sincronização balada concluída.');
      return;
    }

    final item = _pendentesDeSincronizacao.removeAt(0);
    _savePendingData();

    try {
      final requestBody = {
        'todos': true, // Sempre buscar na aba "todos"
        'operacao': 'quarto',
        'novoStatusQuarto': item['novoStatusQuarto'],
      };

      // Buscar por pulseira ou nome
      if (item['pulseira'] != null) {
        requestBody['pulseira'] = item['pulseira'];
      } else {
        requestBody['nome'] = item['nome'];
      }

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
          print('✅ [BaladaService] Sync balada OK: ${responseData['nome']}');
        } else {
          print('❌ [BaladaService] Erro API: ${responseData['mensagem']}');
          _pendentesDeSincronizacao.add(item);
          _savePendingData();
        }
      } else if (response.statusCode == 302) {
        print('⚠️ [BaladaService] Redirecionamento 302 ignorado, sync OK: ${item['nome']}');
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [BaladaService] Erro ao sincronizar balada: $e');
      _pendentesDeSincronizacao.add(item);
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

  // Limpar dados da balada
  Future<void> clearBaladaData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('flowType_balada');
    await prefs.remove('passageiros_balada_json');
    await prefs.remove('pending_sync_data_balada');

    passageirosBalada.value = [];
    _pendentesDeSincronizacao.clear();
    _stopSyncTimer();

    print('📌 [BaladaService] Dados da balada limpos.');
  }
}