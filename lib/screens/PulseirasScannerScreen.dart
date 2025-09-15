import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isTorchActive = false;
  bool _isCameraFacingFront = false;
  bool _hasScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código da Pulseira'),
        backgroundColor: const Color(0xFFa3c734),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            print('📌 [ScannerScreen] Usuário cancelou o scan');
            await _markReturningFromScanner();
            Navigator.pop(context, null);
          },
        ),
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
              if (_hasScanned) return; // Evita múltiplas leituras

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first.rawValue;
                if (barcode != null && barcode.trim().isNotEmpty) {
                  _hasScanned = true;

                  print("📌 [ScannerScreen] Pulseira lida: $barcode");

                  // Marcar que estamos voltando de um scanner
                  await _markReturningFromScanner();

                  // Retornar o código escaneado
                  Navigator.pop(context, barcode.trim());
                }
              }
            },
          ),
          // Overlay com instruções
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Posicione o código da pulseira dentro do quadro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'O scan será automático quando detectado',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          // Quadro de foco
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFa3c734),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Cantos do quadro
                  ...List.generate(4, (index) {
                    return Positioned(
                      top: index < 2 ? -1 : null,
                      bottom: index >= 2 ? -1 : null,
                      left: index % 2 == 0 ? -1 : null,
                      right: index % 2 == 1 ? -1 : null,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: index < 2 ? BorderSide(color: const Color(0xFFa3c734), width: 6) : BorderSide.none,
                            bottom: index >= 2 ? BorderSide(color: const Color(0xFFa3c734), width: 6) : BorderSide.none,
                            left: index % 2 == 0 ? BorderSide(color: const Color(0xFFa3c734), width: 6) : BorderSide.none,
                            right: index % 2 == 1 ? BorderSide(color: const Color(0xFFa3c734), width: 6) : BorderSide.none,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markReturningFromScanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('returning_from_scanner', true);
    print('📌 [ScannerScreen] Marcado como retornando do scanner');
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}