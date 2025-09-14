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
    print('📌 [EmbarqueScreen] Tela de embarque iniciada para ${widget.colegio}');
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
    print('📌 [EmbarqueScreen] Confirmando embarque: ${passageiro.nome}');
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
        valueListenable: dataService.passageirosEmbarque,
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
                            Text('Total de embarques: $totalEmbarcados',
                                style: TextStyle(fontSize: 16,
                                    color: totalEmbarcados == widget.totalAlunos ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar Aluno por Nome',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.search),
                        prefixIcon: Icon(Icons.person_search),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Expanded(
                child: listaExibida.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        termoDeBusca.isEmpty ? 'Nenhum aluno encontrado.' : 'Nenhum aluno encontrado com "$termoDeBusca"',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: listaExibida.length,
                  itemBuilder: (context, index) {
                    final passageiro = listaExibida[index];
                    final jaEmbarcou = passageiro.embarque == 'SIM';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: Card(
                        elevation: 4,
                        color: jaEmbarcou ? Colors.green.shade50 : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nome: ${passageiro.nome}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('RG: ${passageiro.rg}'),
                              Text('Turma: ${passageiro.turma}'),
                              Row(
                                children: [
                                  Text('Status: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: jaEmbarcou ? Colors.green : Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      jaEmbarcou ? 'EMBARCADO' : 'PENDENTE',
                                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: jaEmbarcou ? null : () => _confirmarEmbarque(passageiro),
                                icon: Icon(jaEmbarcou ? Icons.check_circle : Icons.check),
                                label: Text(jaEmbarcou ? 'JÁ EMBARCADO' : 'CONFIRMAR EMBARQUE'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: jaEmbarcou ? Colors.grey : Colors.green,
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
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _showConfirmacaoEncerramento(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text('ENCERRAR EMBARQUE',
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showConfirmacaoEncerramento(BuildContext context) {
    final totalEmbarcados = dataService.passageirosEmbarque.value.where((p) => p.embarque == 'SIM').length;
    final totalPendentes = widget.totalAlunos - totalEmbarcados;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Encerramento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Resumo do embarque:'),
              const SizedBox(height: 8),
              Text('• Embarcados: $totalEmbarcados'),
              Text('• Pendentes: $totalPendentes'),
              const SizedBox(height: 16),
              Text(
                totalPendentes > 0
                    ? 'Ainda há $totalPendentes alunos pendentes. Deseja realmente encerrar?'
                    : 'Todos os alunos foram embarcados. Deseja encerrar?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: totalPendentes > 0 ? Colors.orange : Colors.green,
                ),
              ),
            ],
          ),
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
    print('📌 [EmbarqueScreen] Encerrando embarque...');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('colegio');
    await prefs.remove('onibus');
    await prefs.remove('flowType');
    await prefs.remove('passageiros_embarque_json');

    print('📌 [EmbarqueScreen] Dados de sessão removidos');

    Navigator.of(dialogContext).pop();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainMenuScreen()),
          (Route<dynamic> route) => false,
    );
  }
}