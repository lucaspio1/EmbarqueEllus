import 'package:flutter/material.dart';
import 'package:embarque_app/screens/cadastro_pulseiras_screen.dart';
import 'package:embarque_app/screens/onibus_scanner_screen.dart';
import 'package:embarque_app/screens/pulseiras_scanner_screen.dart';

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OnibusScannerScreen(flowType: 'embarque')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFa3c734),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              child: const Text('Controle Balada', style: TextStyle(fontSize: 18, color: Color(0xFF150F0B))),
            ),
            ElevatedButton(
              onPressed: () {
                // NAVEGAÇÃO PARA A NOVA TELA INDEPENDENTE
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PulseirasScannerScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFa3c734),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              child: const Text('Cadastro de Pulseira', style: TextStyle(fontSize: 18, color: Color(0xFF150F0B))),
            ),
          ],
        ),
      ),
    );
  }
}
