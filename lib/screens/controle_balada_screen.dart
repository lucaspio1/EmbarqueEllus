import 'package:flutter/material.dart';
import 'package:embarque_app/screens/balada_qr_scanner_screen.dart';
import 'package:embarque_app/services/balada_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ControleBaladaScreen extends StatelessWidget {
  const ControleBaladaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Balada'),
        backgroundColor: const Color(0xFFa3c734),
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
                elevation: 6,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFa3c734).withOpacity(0.1),
                        Color(0xFFa3c734).withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFa3c734).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          child: const Icon(
                            Icons.celebration,
                            color: Color(0xFFa3c734),
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Controle de Balada',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4C643C),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gerencie a entrada e saída dos alunos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Botão Saída para Balada
              Container(
                height: 80,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    print('📌 [ControleBaladaScreen] Iniciando fluxo de saída para a balada...');

                    final BaladaService baladaService = BaladaService();
                    await baladaService.fetchAllStudents();

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BaladaQrScannerScreen(flowType: 'saida',),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, size: 32),
                  label: const Text(
                    'Saída para Balada',
                    style: TextStyle(fontSize: 20),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botão Entrada para o Quarto
              Container(
                height: 80,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    print('📌 [ControleBaladaScreen] Iniciando fluxo de entrada para o quarto...');

                    final BaladaService baladaService = BaladaService();
                    await baladaService.fetchAllStudents();

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BaladaQrScannerScreen(flowType: 'entrada'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.login, size: 32),
                  label: const Text(
                    'Entrada para o Quarto',
                    style: TextStyle(fontSize: 20),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFa3c734),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}