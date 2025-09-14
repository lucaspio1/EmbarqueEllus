import 'package:flutter/material.dart';
import 'package:embarque_app/screens/onibus_scanner_screen.dart';
import 'package:embarque_app/screens/selecao_colegio_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:embarque_app/services/data_service.dart';
import 'package:embarque_app/screens/embarque_screen.dart';
import 'package:embarque_app/screens/controle_embarque_screen.dart';
import 'package:embarque_app/screens/cadastro_pulseiras_screen.dart';
import 'package:embarque_app/services/cadastro_service.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    _checkActiveSession();
  }

  Future<void> _checkActiveSession() async {
    final prefs = await SharedPreferences.getInstance();

    // Tentativa de carregar sessão de embarque
    final colegioEmbarqueSalvo = prefs.getString('colegio');
    final onibusEmbarqueSalvo = prefs.getString('onibus');
    final flowTypeEmbarqueSalvo = prefs.getString('flowType');

    if (colegioEmbarqueSalvo != null && onibusEmbarqueSalvo != null && flowTypeEmbarqueSalvo == 'embarque') {
      await DataService().loadLocalData(colegioEmbarqueSalvo, onibusEmbarqueSalvo, 'embarque');
      final totalAlunos = DataService().passageirosEmbarque.value.length;
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmbarqueScreen(
              colegio: colegioEmbarqueSalvo,
              onibus: onibusEmbarqueSalvo,
              totalAlunos: totalAlunos,
            ),
          ),
        );
      }
      return; // Sessão de embarque encontrada, parar aqui.
    }

    // Tentativa de carregar sessão de cadastro
    final colegioCadastroSalvo = prefs.getString('colegio_cadastro');
    final onibusCadastroSalvo = prefs.getString('onibus_cadastro');
    final flowTypeCadastroSalvo = prefs.getString('flowType_cadastro');

    if (colegioCadastroSalvo != null && onibusCadastroSalvo != null && flowTypeCadastroSalvo == 'pulseiras') {
      await CadastroService().loadLocalData(colegioCadastroSalvo, onibusCadastroSalvo);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CadastroPulseirasScreen(colegio: colegioCadastroSalvo),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD1D2D1),
      body: Card(
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              decoration: const BoxDecoration(
                color: Color(0xFF4C643C),
              ),
              child: const Text(
                'Ehlus',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ControleEmbarqueScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4C643C),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          child: const Text('Controle Embarque', style: TextStyle(fontSize: 18, color: Color(0xFF150F0B))),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SelecaoColegioScreen()),
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
