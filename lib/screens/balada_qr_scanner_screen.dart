import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:embarque_app/services/balada_service.dart';
import 'package:embarque_app/models/passageiro.dart';

class BaladaQrScannerScreen extends StatefulWidget {
  final String flowType;

  const BaladaQrScannerScreen({super.key, required this.flowType});

  @override
  _BaladaQrScannerScreenState createState() => _BaladaQrScannerScreenState();
}

class _BaladaQrScannerScreenState extends State<BaladaQrScannerScreen> {
  final BaladaService _baladaService = BaladaService();
  final MobileScannerController cameraController = MobileScannerController();

  String _lastScannedCode = '';

  void _handleScanResult(String codigoPulseira) {
    // Evita processar o mesmo código várias vezes seguidas
    if (codigoPulseira == _lastScannedCode) {
      return;
    }

    setState(() {
      _lastScannedCode = codigoPulseira;
    });

    final Passageiro? passageiro = _baladaService.findPassageiroByPulseira(codigoPulseira);

    if (passageiro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pulseira não encontrada na lista.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String novoStatus;
    if (widget.flowType == 'saida') {
      novoStatus = 'OFF';
    } else {
      novoStatus = 'ON';
    }

    if (passageiro.statusQuarto.toUpperCase() == novoStatus.toUpperCase()) {
      final mensagem = novoStatus == 'ON'
          ? '${passageiro.nome} já está no quarto.'
          : '${passageiro.nome} já está fora da balada.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _baladaService.updateLocalDataByPulseira(codigoPulseira, novoStatusQuarto: novoStatus);

    String mensagem;
    Color cor;
    if (novoStatus == 'ON') {
      mensagem = '${passageiro.nome} - Entrada no quarto registrada!';
      cor = Colors.green;
    } else {
      mensagem = '${passageiro.nome} - Saída para balada registrada!';
      cor = Colors.blue;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: cor,
      ),
    );

    // Limpa o último código escaneado após um pequeno delay para permitir novos scans.
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _lastScannedCode = '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.flowType == 'saida' ? 'Saída para Balada' : 'Entrada para o Quarto'),
        backgroundColor: widget.flowType == 'saida' ? Colors.red.shade400 : const Color(0xFFa3c734),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScanResult(barcode.rawValue!);
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Voltar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}