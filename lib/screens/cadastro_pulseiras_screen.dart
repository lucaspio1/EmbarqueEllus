import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:embarque_app/models/passageiro.dart';
import 'package:embarque_app/screens/PulseirasScannerScreen.dart';
import 'package:embarque_app/main.dart';
import 'package:embarque_app/services/cadastro_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:embarque_app/screens/main_menu_screen.dart';

class CadastroPulseirasScreen extends StatefulWidget {
  final String colegio;
  const CadastroPulseirasScreen({required this.colegio, super.key});

  @override
  State<CadastroPulseirasScreen> createState() => _CadastroPulseirasScreenState();
}

class _CadastroPulseirasScreenState extends State<CadastroPulseirasScreen> {
  final cadastroService = CadastroService();
  final TextEditingController _nomeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nomeController.addListener(_filtrarPassageiros);
    print('📌 [CadastroPulseirasScreen] Tela de cadastro iniciada para ${widget.colegio}');
  }

  @override
  void dispose() {
    _nomeController.removeListener(_filtrarPassageiros);
    _nomeController.dispose();
    super.dispose();
  }

  void _filtrarPassageiros() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro de Pulseiras - ${widget.colegio}'),
        backgroundColor: const Color(0xFFa3c734),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ValueListenableBuilder<List<Passageiro>>(
                      valueListenable: cadastroService.passageirosCadastro,
                      builder: (context, passageiros, child) {
                        final totalComPulseira = passageiros.where((p) => p.pulseira.isNotEmpty && p.pulseira != 'Não Informado').length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Colégio: ${widget.colegio}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Total de alunos: ${passageiros.length}', style: const TextStyle(fontSize: 16)),
                            Text('Pulseiras cadastradas: $totalComPulseira',
                                style: TextStyle(fontSize: 16,
                                    color: totalComPulseira == passageiros.length ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.bold)),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar Aluno por Nome',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search),
                    prefixIcon: Icon(Icons.person_search),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<Passageiro>>(
              valueListenable: cadastroService.passageirosCadastro,
              builder: (context, passageiros, child) {
                if (passageiros.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Nenhum passageiro encontrado.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final termoDeBusca = _nomeController.text.trim().toLowerCase();
                final listaExibida = termoDeBusca.isEmpty
                    ? passageiros
                    : passageiros.where((p) => p.nome.toLowerCase().contains(termoDeBusca)).toList();

                if (listaExibida.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Nenhum aluno encontrado com "$termoDeBusca"',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: listaExibida.length,
                  itemBuilder: (context, index) {
                    final passageiro = listaExibida[index];
                    final temPulseira = passageiro.pulseira.isNotEmpty && passageiro.pulseira != 'Não Informado';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      elevation: 4,
                      color: temPulseira ? Colors.green.shade50 : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nome: ${passageiro.nome}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('RG: ${passageiro.rg}'),
                            Text('Turma: ${passageiro.turma}'),
                            Text('Status: ${passageiro.embarque}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('Pulseira: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: temPulseira ? Colors.green : Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    temPulseira ? passageiro.pulseira : 'PENDENTE',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                print('📌 [CadastroPulseirasScreen] Iniciando scan para ${passageiro.nome}');

                                // Marcar que vamos usar o scanner (para evitar redirecionamento)
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setBool('using_scanner', true);

                                final scannedResult = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ScannerScreen(),
                                  ),
                                );

                                // Remover flag após retorno
                                await prefs.remove('using_scanner');

                                if (!mounted) return;

                                if (scannedResult != null && scannedResult is String) {
                                  print('📌 [CadastroPulseirasScreen] Pulseira escaneada: $scannedResult para ${passageiro.nome}');

                                  // Atualiza os dados localmente
                                  cadastroService.updateLocalData(passageiro, novaPulseira: scannedResult);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Pulseira $scannedResult cadastrada para ${passageiro.nome}!'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );

                                  // Forçar rebuild para mostrar a atualização
                                  setState(() {});
                                } else {
                                  print('⚠️ [CadastroPulseirasScreen] Scan cancelado ou inválido');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Scan cancelado'),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(temPulseira ? Icons.edit : Icons.qr_code_scanner),
                              label: Text(temPulseira ? 'ALTERAR PULSEIRA' : 'ESCANEAR PULSEIRA'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: temPulseira ? Colors.orange : Colors.blue,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _showConfirmacaoEncerramento(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('ENCERRAR CADASTRO',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmacaoEncerramento(BuildContext context) {
    final passageiros = cadastroService.passageirosCadastro.value;
    final totalComPulseira = passageiros.where((p) => p.pulseira.isNotEmpty && p.pulseira != 'Não Informado').length;
    final totalSemPulseira = passageiros.length - totalComPulseira;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Encerramento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Resumo do cadastro:'),
              const SizedBox(height: 8),
              Text('• Pulseiras cadastradas: $totalComPulseira'),
              Text('• Pendentes: $totalSemPulseira'),
              const SizedBox(height: 16),
              Text(
                totalSemPulseira > 0
                    ? 'Ainda há $totalSemPulseira alunos sem pulseira. Deseja realmente encerrar?'
                    : 'Todos os alunos têm pulseiras cadastradas. Deseja encerrar?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: totalSemPulseira > 0 ? Colors.orange : Colors.green,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Sim, Encerrar'),
              onPressed: () {
                _encerrarCadastro(dialogContext);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _encerrarCadastro(BuildContext dialogContext) async {
    print('📌 [CadastroPulseirasScreen] Encerrando cadastro...');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('colegio_cadastro');
    await prefs.remove('onibus_cadastro');
    await prefs.remove('flowType_cadastro');
    await prefs.remove('passageiros_cadastro_json');

    print('📌 [CadastroPulseirasScreen] Dados de sessão removidos');

    Navigator.of(dialogContext).pop();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainMenuScreen()),
          (Route<dynamic> route) => false,
    );
  }
}