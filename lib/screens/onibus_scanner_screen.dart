import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:embarque_app/screens/embarque_screen.dart';
import 'package:embarque_app/services/data_service.dart';
import 'package:embarque_app/main.dart';
import 'package:http/http.dart' as http;
import 'package:embarque_app/models/passageiro.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:embarque_app/screens/cadastro_pulseiras_screen.dart';

class OnibusScannerScreen extends StatefulWidget {
  final String? flowType;
  const OnibusScannerScreen({super.key, this.flowType});

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
        title: const Text('Escanear QR Code do Ônibus'),
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
              print('Scanner detectou um QR Code. Processando...');

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first.rawValue;
                if (barcode != null) {
                  print('Valor do QR Code lido: $barcode');
                  final partes = barcode.split(';');

                  if (partes.length == 2) {
                    final colegio = partes[0];
                    final onibus = partes[1];
                    print('Informações extraídas: Colégio=$colegio, Ônibus=$onibus');

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Carregando dados do colégio $colegio, ônibus $onibus...')),
                    );

                    await _fetchDataAndNavigate(colegio, onibus, widget.flowType);
                  } else {
                    print('ERRO: Formato do QR Code incorreto. Esperado: "colegio;onibus"');
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

  Future<void> _fetchDataAndNavigate(String colegio, String onibus, String? flowType) async {
    try {
      print('Iniciando _fetchDataAndNavigate...');

      final prefs = await SharedPreferences.getInstance();

      // CORREÇÃO: Limpar dados de sessão antigos para o outro fluxo
      if (flowType == 'embarque') {
        await prefs.remove('passageiros_cadastro_json');
      } else {
        await prefs.remove('passageiros_embarque_json');
      }

      await DataService().fetchData(colegio, flowType ?? 'embarque', onibus: onibus);

      if (!mounted) {
        print('Widget não está montado. Abortando navegação.');
        return;
      }

      List<Passageiro> passageiros;
      if (flowType == 'pulseiras') {
        passageiros = DataService().passageirosCadastro.value;
      } else {
        passageiros = DataService().passageirosEmbarque.value;
      }
      final totalAlunos = passageiros.length;

      print('Dados do serviço de dados atualizados. Total de alunos: $totalAlunos');

      await prefs.setString('flowType', flowType ?? 'embarque');
      await DataService().saveLocalData(colegio, onibus, flowType ?? 'embarque', passageiros);

      if (mounted && !_isNavigating) {
        _isNavigating = true;
        if (flowType == 'pulseiras') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CadastroPulseirasScreen(colegio: colegio),
            ),
          );
        } else {
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
      }

    } catch (e) {
      if (!mounted) return;
      print('ERRO DE CONEXÃO ou PARSE: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }
}