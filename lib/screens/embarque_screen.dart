import 'package:flutter/material.dart';
import 'package:embarque_app/models/passageiro.dart';
import 'package:embarque_app/services/data_service.dart';
import 'package:embarque_app/screens/main_menu_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmbarqueScreen extends StatefulWidget {
  final String colegio;
  final String onibus;
  final int totalAlunos;
  const EmbarqueScreen({
    required this.colegio,
    required this.onibus,
    required this.totalAlunos,
    super.key
  });

  @override
  State<EmbarqueScreen> createState() => _EmbarqueScreenState();
}

class _EmbarqueScreenState extends State<EmbarqueScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final dataService = DataService();

  @override
  void initState() {
    super.initState();
    _nomeController.addListener(_filtrarPassageiros);
  }

  @override
  void dispose() {
    _nomeController.removeListener(_filtrarPassageiros);
    _nomeController.dispose();
    super.dispose();
  }

  void _filtrarPassageiros() {
    setState(() {});
  }

  void _confirmarEmbarque(Passageiro passageiro) {
    dataService.updateLocalData(passageiro, novoEmbarque: 'SIM');
    _nomeController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Embarque confirmado! Sincronizando...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Embarque - ${widget.colegio}'),
        backgroundColor: const Color(0xFF4C643C),
      ),
      body: ValueListenableBuilder<List<Passageiro>>(
        valueListenable: dataService.passageirosEmbarque, // Usa a lista de embarque
        builder: (context, passageirosDaLista, child) {
          final termoDeBusca = _nomeController.text.trim().toLowerCase();
          final listaExibida = termoDeBusca.isEmpty
              ? passageirosDaLista
              : passageirosDaLista.where((p) => p.nome.toLowerCase().contains(termoDeBusca)).toList();

          final totalEmbarcados = passageirosDaLista.where((p) => p.embarque == 'SIM').length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Colégio: ${widget.colegio}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Ônibus: ${widget.onibus}', style: const TextStyle(fontSize: 16)),
                            Text('Total de alunos: ${widget.totalAlunos}', style: const TextStyle(fontSize: 16)),
                            Text('Total de embarques: $totalEmbarcados', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar Aluno',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Expanded(
                child: listaExibida.isEmpty
                    ? const Center(child: Text('Nenhum aluno encontrado.', style: TextStyle(fontStyle: FontStyle.italic)))
                    : ListView.builder(
                  itemCount: listaExibida.length,
                  itemBuilder: (context, index) {
                    final passageiro = listaExibida[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nome: ${passageiro.nome}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('RG: ${passageiro.rg}'),
                              Text('Embarque: ${passageiro.embarque}', style: TextStyle(color: passageiro.embarque == 'SIM' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: passageiro.embarque != 'SIM' ? () => _confirmarEmbarque(passageiro) : null,
                                icon: const Icon(Icons.check),
                                label: const Text('Confirmar Embarque'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  minimumSize: const Size.fromHeight(40),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => _showConfirmacaoEncerramento(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text('ENCERRAR EMBARQUE', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showConfirmacaoEncerramento(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Encerramento'),
          content: const Text('Você já concluiu o embarque?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Sim, Encerrar'),
              onPressed: () {
                _encerrarEmbarque(dialogContext);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _encerrarEmbarque(BuildContext dialogContext) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('colegio');
    await prefs.remove('onibus');
    await prefs.remove('totalAlunos');

    Navigator.of(dialogContext).pop();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainMenuScreen()),
          (Route<dynamic> route) => false,
    );
  }
}
