// main_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:embarque_app/screens/selecao_colegio_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:embarque_app/services/data_service.dart';
import 'package:embarque_app/screens/embarque_screen.dart';
import 'package:embarque_app/screens/controle_embarque_screen.dart';
import 'package:embarque_app/screens/cadastro_pulseiras_screen.dart';
import 'package:embarque_app/services/cadastro_service.dart';
// Importe a tela de controle de balada
import 'package:embarque_app/screens/controle_balada_screen.dart'; // <-- Adicione esta linha

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

    // Verificar se estamos voltando de um scanner (não deve redirecionar automaticamente)
    final isReturningFromScanner = prefs.getBool('returning_from_scanner') ?? false;
    if (isReturningFromScanner) {
      await prefs.remove('returning_from_scanner');
      print("📌 [MainMenuScreen] Voltando de scanner, não redirecionando automaticamente");
      return;
    }

    // VERIFICAÇÃO 1: Sessão de embarque
    final colegioEmbarque = prefs.getString('colegio');
    final onibusEmbarque = prefs.getString('onibus');
    final flowTypeEmbarque = prefs.getString('flowType');

    print("📌 [MainMenuScreen] Verificando sessão embarque:");
    print("   colegio=$colegioEmbarque");
    print("   onibus=$onibusEmbarque");
    print("   flowType=$flowTypeEmbarque");

    if (colegioEmbarque != null &&
        onibusEmbarque != null &&
        flowTypeEmbarque == 'embarque') {

      print("✅ [MainMenuScreen] Sessão de embarque encontrada! Retomando...");

      await DataService().loadLocalData(colegioEmbarque, onibusEmbarque);
      final totalAlunos = DataService().passageirosEmbarque.value.length;

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmbarqueScreen(
              colegio: colegioEmbarque,
              onibus: onibusEmbarque,
              totalAlunos: totalAlunos,
            ),
          ),
        );
      }
      return; // Parar aqui, sessão de embarque tem prioridade
    }

    // VERIFICAÇÃO 2: Sessão de cadastro (apenas se não há sessão de embarque)
    final colegioCadastro = prefs.getString('colegio_cadastro');
    final onibusCadastro = prefs.getString('onibus_cadastro');
    final flowTypeCadastro = prefs.getString('flowType_cadastro');

    print("📌 [MainMenuScreen] Verificando sessão cadastro:");
    print("   colegio_cadastro=$colegioCadastro");
    print("   onibus_cadastro=$onibusCadastro");
    print("   flowType_cadastro=$flowTypeCadastro");

    if (colegioCadastro != null &&
        onibusCadastro != null &&
        flowTypeCadastro == 'pulseiras') {

      print("✅ [MainMenuScreen] Sessão de cadastro encontrada! Retomando...");

      await CadastroService().loadLocalData(colegioCadastro, onibusCadastro);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CadastroPulseirasScreen(colegio: colegioCadastro),
          ),
        );
      }
      return;
    }

    print("📌 [MainMenuScreen] Nenhuma sessão ativa encontrada. Mostrando menu principal.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD1D2D1),
      body: SafeArea(
        child: Card(
          elevation: 8,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 24.0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF4C643C),
                      Color(0xFF3A4F2A),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ellus',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Educação e Turismo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Selecione uma opção:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4C643C),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Botão Controle Embarque
                      Container(
                        width: double.infinity,
                        height: 80,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            print("📌 [MainMenuScreen] Navegando para Controle Embarque");
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ControleEmbarqueScreen()),
                            );
                          },
                          icon: const Icon(Icons.directions_bus, size: 32),
                          label: const Text(
                            'CONTROLE EMBARQUE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4C643C),
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: const Color(0xFF4C643C).withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Botão Controle Balada
                      Container(
                        width: double.infinity,
                        height: 80,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            print("📌 [MainMenuScreen] Navegando para Controle Balada");
                            // Altere a navegação aqui para a nova tela
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ControleBaladaScreen()), // <-- Altere esta linha
                            );
                          },
                          icon: const Icon(Icons.celebration, size: 32),
                          label: const Text(
                            'CONTROLE BALADA',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFa3c734),
                            foregroundColor: const Color(0xFF150F0B),
                            elevation: 8,
                            shadowColor: const Color(0xFFa3c734).withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Footer info
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'O app salva automaticamente seu progresso durante o uso.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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