import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:embarque_app/screens/menu_colegio_screen.dart';
import 'package:embarque_app/main.dart';
import 'package:embarque_app/services/data_service.dart';

class SelecaoColegioScreen extends StatefulWidget {
  const SelecaoColegioScreen({super.key});

  @override
  State<SelecaoColegioScreen> createState() => _SelecaoColegioScreenState();
}

class _SelecaoColegioScreenState extends State<SelecaoColegioScreen> {
  List<String> _colegios = [];
  String _mensagem = 'Carregando colégios...';
  bool _isFetchingData = false;

  @override
  void initState() {
    super.initState();
    _carregarColegios();
  }

  Future<void> _carregarColegios() async {
    setState(() {
      _mensagem = 'Carregando colégios...';
    });
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          _colegios = List<String>.from(jsonData);
          _mensagem = '';
        });
      } else {
        setState(() {
          _mensagem = 'Erro ao carregar colégios. Código: ${response.statusCode}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensagem = 'Erro de conexão: $e';
      });
    }
  }

  Future<void> _handleColegioSelection(String colegio) async {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuColegioScreen(colegio: colegio),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Colégio'),
      ),
      body: _mensagem.isNotEmpty
          ? Center(child: Text(_mensagem))
          : ListView.builder(
        itemCount: _colegios.length,
        itemBuilder: (context, index) {
          final colegio = _colegios[index];
          return ListTile(
            title: Text(colegio),
            onTap: () {
              _handleColegioSelection(colegio);
            },
          );
        },
      ),
    );
  }
}
