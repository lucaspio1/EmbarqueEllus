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
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final colegioSalvo = prefs.getString('colegio');
                  final onibusSalvo = prefs.getString('onibus');
                  final flowTypeSalvo = prefs.getString('flowType');

                  if (colegioSalvo != null && onibusSalvo != null && flowTypeSalvo == 'embarque') {
                    await DataService().loadLocalData(colegioSalvo, onibusSalvo, 'embarque');
                    final totalAlunos = DataService().passageirosEmbarque.value.length;
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OnibusScannerScreen(flowType: 'embarque'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFa3c734),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text('Embarque', style: TextStyle(fontSize: 18, color: Color(0xFF150F0B))),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final colegioSalvo = prefs.getString('colegio_cadastro');
                  final onibusSalvo = prefs.getString('onibus_cadastro');
                  final flowTypeSalvo = prefs.getString('flowType_cadastro');

                  if (colegioSalvo != null && onibusSalvo != null && flowTypeSalvo == 'pulseiras') {
                    await CadastroService().loadLocalData(colegioSalvo, onibusSalvo);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CadastroPulseirasScreen(colegio: colegioSalvo),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PulseirasScannerScreen(),
                      ),
                    );
                  }
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
      ),
    );
  }
}
