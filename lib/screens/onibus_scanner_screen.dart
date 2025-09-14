import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:embarque_app/screens/embarque_screen.dart';
import 'package:embarque_app/services/data_service.dart';
import 'package:embarque_app/main.dart';
import 'package:http/http.dart' as http;
import 'package:embarque_app/models/passageiro.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnibusScannerScreen extends StatefulWidget {
  const OnibusScannerScreen({super.key});

  @override
  State<OnibusScannerScreen> createState() => _OnibusScannerScreenState();
}

class _OnibusScannerScreenState extends State<OnibusScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isTorchActive = false;
  bool _isCameraFacingFront = false;
  bool _isProcessing = false;
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR Code - Embarque'),
        backgroundColor: const Color(0xFF4C643C),
        actions: [
          IconButton(
            color: Colors.white,
            icon: Icon(
              _isTorchActive ? Icons.flash_on : Icons.flash_off,
              color: _isTorchActive ? Colors.yellow : Colors.grey,
            ),
            iconSize: 32.0,
            onPressed: () {
              cameraController.toggleTorch();
              setState(() {
                _isTorchActive = !_isTorchActive;
              });
            },
          ),
          IconButton(
            color: Colors.white,
            icon: Icon(
              _isCameraFacingFront ? Icons.camera_front : Icons.camera_rear,
              color: Colors.white,
            ),
            iconSize: 32.0,
            onPressed: () {
              cameraController.switchCamera();
              setState(() {
                _isCameraFacingFront = !_isCameraFacingFront;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) async {
              if (_isProcessing || _isNavigating) return;
              _isProcessing = true;
              print('📌 [OnibusScannerScreen] QR Code detectado para embarque');

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first.rawValue;
                if (barcode != null) {
                  print('📌 [OnibusScannerScreen] Valor lido: $barcode');
                  final partes = barcode.split(';');

                  if (partes.length == 2) {
                    final colegio = partes[0];
                    final onibus = partes[1];
                    print('📌 [OnibusScannerScreen] Colégio=$colegio, Ônibus=$onibus');

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Carregando dados do colégio $colegio, ônibus $onibus...')),
                    );

                    await _fetchDataAndNavigate(colegio, onibus);
                  } else {
                    print('❌ [OnibusScannerScreen] Formato incorreto do QR Code');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Formato do QR Code incorreto. Tente novamente.')),
                    );
                  }
                }
              }
              _isProcessing = false;
            },
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _fetchDataAndNavigate(String colegio, String onibus) async {
    try {
      print('📌 [OnibusScannerScreen] Iniciando fetch para embarque...');

      final prefs = await SharedPreferences.getInstance();

      // Limpar dados de cadastro se existirem
      await prefs.remove('colegio_cadastro');
      await prefs.remove('onibus_cadastro');
      await prefs.remove('flowType_cadastro');
      await prefs.remove('passageiros_cadastro_json');

      await DataService().fetchData(colegio, onibus: onibus);

      if (!mounted) {
        print('⚠️ [OnibusScannerScreen] Widget não montado, abortando navegação');
        return;
      }

      List<Passageiro> passageiros = DataService().passageirosEmbarque.value;
      final totalAlunos = passageiros.length;

      print('✅ [OnibusScannerScreen] Dados carregados. Total: $totalAlunos alunos');

      await DataService().saveLocalData(colegio, onibus, passageiros);

      if (mounted && !_isNavigating) {
        _isNavigating = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmbarqueScreen(
              colegio: colegio,
              onibus: onibus,
              totalAlunos: totalAlunos,
            ),
          ),
        );
      }

    } catch (e) {
      if (!mounted) return;
      print('❌ [OnibusScannerScreen] Erro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }
}