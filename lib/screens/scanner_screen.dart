import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isTorchActive = false;
  bool _isCameraFacingFront = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código de Barras'),
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
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final barcode = barcodes.first.rawValue;
            if (barcode != null) {
              // 🔎 Debug do código lido
              print("📌 [ScannerScreen] Código lido: $barcode");
              Navigator.pop(context, barcode);
            }
          }
        },
      ),
    );
  }
}
