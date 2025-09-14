import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:embarque_app/models/passageiro.dart';
import 'package:embarque_app/screens/scanner_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro de Pulseiras - ${widget.colegio}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<List<Passageiro>>(
              valueListenable: cadastroService.passageirosCadastro,
              builder: (context, passageiros, child) {
                if (passageiros.isEmpty) {
                  return const Center(child: Text('Nenhum passageiro encontrado.'));
                }

                return ListView.builder(
                  itemCount: passageiros.length,
                  itemBuilder: (context, index) {
                    final passageiro = passageiros[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Nome: ${passageiro.nome}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Status: ${passageiro.embarque}'),
                                  Text('RG: ${passageiro.rg}'),
                                  const SizedBox(height: 10),
                                  Text('Pulseira: ${passageiro.pulseira}'),
                                  const SizedBox(height: 10),

                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final scannedResult = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ScannerScreen(),
                                        ),
                                      );

                                      if (!mounted) return;

                                      if (scannedResult != null && scannedResult is String) {
                                        // Atualiza os dados localmente
                                        cadastroService.updateLocalData(passageiro, novaPulseira: scannedResult);

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Pulseira atualizada localmente! Sincronizando...')),
                                        );
                                        // Força uma reconstrução da tela para garantir que o estado seja consistente.
                                        setState(() {});
                                      }
                                    },
                                    icon: const Icon(Icons.qr_code_scanner),
                                    label: const Text('Escanear Pulseira'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      minimumSize: const Size.fromHeight(40),
                                    ),
                                  ),
                                ],
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _showConfirmacaoEncerramento(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('ENCERRAR CADASTRO', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmacaoEncerramento(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Encerramento'),
          content: const Text('Você já concluiu o cadastro de pulseiras?'),
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('colegio_cadastro');
    await prefs.remove('onibus_cadastro');
    await prefs.remove('flowType_cadastro');
    await prefs.remove('passageiros_cadastro_json');

    Navigator.of(dialogContext).pop();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainMenuScreen()),
          (Route<dynamic> route) => false,
    );
  }
}