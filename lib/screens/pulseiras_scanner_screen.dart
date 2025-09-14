import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:embarque_app/screens/cadastro_pulseiras_screen.dart';
import 'package:embarque_app/services/cadastro_service.dart'; // CORREÇÃO: Usar o novo serviço
import 'package:embarque_app/main.dart';
import 'package:http/http.dart' as http;
import 'package:embarque_app/models/passageiro.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PulseirasScannerScreen extends StatefulWidget {
  const PulseirasScannerScreen({super.key});

  @override
  State<PulseirasScannerScreen> createState() => _PulseirasScannerScreenState();
}

class _PulseirasScannerScreenState extends State<PulseirasScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isTorchActive = false;
  bool _isCameraFacingFront = false;
  bool _isProcessing = false;
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR Code do Ônibus (Pulseiras)'),
        backgroundColor: const Color(0xFFa3c734),
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

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first.rawValue;
                if (barcode != null) {
                  final partes = barcode.split(';');

                  if (partes.length == 2) {
                    final colegio = partes[0];
                    final onibus = partes[1];

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Carregando dados para $colegio, ônibus $onibus...')),
                    );

                    await _fetchDataAndNavigate(colegio, onibus);
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Formato do QR Code incorreto. Por favor, tente novamente.')),
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('colegio');
      await prefs.remove('onibus');
      await prefs.remove('flowType');
      await prefs.remove('passageiros_embarque_json');

      await CadastroService().fetchData(colegio, onibus); // CORREÇÃO: Usar o novo serviço

      if (!mounted) {
        return;
      }

      List<Passageiro> passageiros = CadastroService().passageirosCadastro.value; // CORREÇÃO: Usar o novo serviço

      await CadastroService().saveLocalData(colegio, onibus, passageiros); // CORREÇÃO: Usar o novo serviço

      if (mounted && !_isNavigating) {
        _isNavigating = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CadastroPulseirasScreen(colegio: colegio),
          ),
        );
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }
}
