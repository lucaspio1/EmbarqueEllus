import 'package:flutter/material.dart';
import 'package:embarque_app/screens/onibus_scanner_screen.dart';
import 'package:embarque_app/screens/OnibusScannerCadastroScreen.dart';

class MenuColegioScreen extends StatelessWidget {
  final String colegio;

  const MenuColegioScreen({required this.colegio, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Opções do Colégio $colegio'),
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
                      Icon(Icons.school, size: 48, color: Color(0xFF4C643C)),
                      SizedBox(height: 16),
                      Text(
                        'Colégio: $colegio',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Selecione a operação desejada:',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Botão Controle Balada (Embarque)
              ElevatedButton.icon(
                onPressed: () {
                  print('📌 [MenuColegioScreen] Navegando para embarque do $colegio');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OnibusScannerScreen(), // Sem parâmetro flowType
                    ),
                  );
                },
                icon: const Icon(Icons.directions_bus, size: 24),
                label: const Text('CONTROLE BALADA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                onPressed: () {
                  print('📌 [MenuColegioScreen] Navegando para cadastro de pulseiras');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PulseirasScannerScreen(), // Scanner específico para pulseiras
                    ),
                  );
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
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Controle Balada: Gerencia entrada dos alunos\nCadastro de Pulseira: Registra pulseiras identificadoras',
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