import 'package:flutter/material.dart';
import 'package:embarque_app/screens/onibus_scanner_screen.dart';
import 'package:embarque_app/screens/cadastro_pulseiras_screen.dart';
import 'package:embarque_app/services/data_service.dart';
import 'package:embarque_app/screens/embarque_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:embarque_app/screens/pulseiras_scanner_screen.dart';
import 'package:embarque_app/services/cadastro_service.dart';

class ControleEmbarqueScreen extends StatelessWidget {
  const ControleEmbarqueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Embarque'),
        backgroundColor: const Color(0xFF4C643C),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card explicativo
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Color(0xFF4C643C)),
                      SizedBox(height: 16),
                      Text(
                        'Escolha a operação desejada:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Embarque: Controlar entrada dos alunos no ônibus\n• Cadastro de Pulseira: Registrar pulseiras dos alunos',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Botão Embarque
              ElevatedButton.icon(
                onPressed: () async {
                  print('📌 [ControleEmbarqueScreen] Verificando sessão de embarque...');

                  final prefs = await SharedPreferences.getInstance();
                  final colegioSalvo = prefs.getString('colegio');
                  final onibusSalvo = prefs.getString('onibus');
                  final flowTypeSalvo = prefs.getString('flowType');

                  print('📌 [ControleEmbarqueScreen] Sessão encontrada: colegio=$colegioSalvo, onibus=$onibusSalvo, flowType=$flowTypeSalvo');

                  if (colegioSalvo != null && onibusSalvo != null && flowTypeSalvo == 'embarque') {
                    // Retomar sessão existente
                    await DataService().loadLocalData(colegioSalvo, onibusSalvo);
                    final totalAlunos = DataService().passageirosEmbarque.value.length;

                    print('📌 [ControleEmbarqueScreen] Retomando sessão de embarque com $totalAlunos alunos');

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmbarqueScreen(
                          colegio: colegioSalvo,
                          onibus: onibusSalvo,
                          totalAlunos: totalAlunos,
                        ),
                      ),
                    );
                  } else {
                    // Nova sessão
                    print('📌 [ControleEmbarqueScreen] Iniciando nova sessão de embarque');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OnibusScannerScreen(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.directions_bus, size: 24),
                label: const Text('EMBARQUE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C643C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botão Cadastro de Pulseira
              ElevatedButton.icon(
                onPressed: () async {
                  print('📌 [ControleEmbarqueScreen] Verificando sessão de cadastro...');

                  final prefs = await SharedPreferences.getInstance();
                  final colegioSalvo = prefs.getString('colegio_cadastro');
                  final onibusSalvo = prefs.getString('onibus_cadastro');
                  final flowTypeSalvo = prefs.getString('flowType_cadastro');

                  print('📌 [ControleEmbarqueScreen] Sessão cadastro: colegio=$colegioSalvo, onibus=$onibusSalvo, flowType=$flowTypeSalvo');

                  if (colegioSalvo != null && onibusSalvo != null && flowTypeSalvo == 'pulseiras') {
                    // Retomar sessão existente
                    await CadastroService().loadLocalData(colegioSalvo, onibusSalvo);

                    print('📌 [ControleEmbarqueScreen] Retomando sessão de cadastro');

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CadastroPulseirasScreen(colegio: colegioSalvo),
                      ),
                    );
                  } else {
                    // Nova sessão
                    print('📌 [ControleEmbarqueScreen] Iniciando nova sessão de cadastro');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PulseirasScannerScreen(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.qr_code_2, size: 24),
                label: const Text('CADASTRO DE PULSEIRA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFa3c734),
                  foregroundColor: const Color(0xFF150F0B),
                  minimumSize: const Size.fromHeight(60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Informações adicionais
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dica: O app salva automaticamente seu progresso. Você pode sair e retomar onde parou.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}