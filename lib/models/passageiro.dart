import 'package:embarque_app/services/data_service.dart';

class Passageiro {
  final String colegio;
  final String turma;
  final String nome;
  final String cpf;
  final String rg;
  final String embarque;
  final String pulseira;
  final String foto;
  final String statusQuarto; // Novo campo
  String? flowType;

  Passageiro({
    required this.colegio,
    required this.turma,
    required this.nome,
    required this.cpf,
    required this.rg,
    required this.embarque,
    required this.pulseira,
    required this.foto,
    this.statusQuarto = '', // Valor padrão vazio
    this.flowType,
  });

  factory Passageiro.fromJson(Map<String, dynamic> json) {
    return Passageiro(
      colegio: json['colegio']?.toString() ?? '',
      turma: json['turma']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      cpf: json['cpf']?.toString() ?? '',
      rg: json['rg']?.toString() ?? '',
      embarque: json['embarque']?.toString() ?? '',
      pulseira: json['pulseira']?.toString() ?? '',
      foto: json['foto']?.toString() ?? '',
      statusQuarto: json['statusQuarto']?.toString() ?? '', // Novo campo
      flowType: json['flowType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'colegio': colegio,
      'turma': turma,
      'nome': nome,
      'cpf': cpf,
      'rg': rg,
      'embarque': embarque,
      'pulseira': pulseira,
      'foto': foto,
      'statusQuarto': statusQuarto, // Novo campo
      'flowType': flowType,
    };
  }

  Passageiro copyWith({
    String? colegio,
    String? turma,
    String? nome,
    String? cpf,
    String? rg,
    String? embarque,
    String? pulseira,
    String? foto,
    String? statusQuarto, // Novo campo
    String? flowType,
  }) {
    return Passageiro(
      colegio: colegio ?? this.colegio,
      turma: turma ?? this.turma,
      nome: nome ?? this.nome,
      cpf: cpf ?? this.cpf,
      rg: rg ?? this.rg,
      embarque: embarque ?? this.embarque,
      pulseira: pulseira ?? this.pulseira,
      foto: foto ?? this.foto,
      statusQuarto: statusQuarto ?? this.statusQuarto, // Novo campo
      flowType: flowType ?? this.flowType,
    );
  }

  // Métodos auxiliares para verificar status
  bool get estaNaBalada => statusQuarto.toUpperCase() != 'ON';
  bool get estaNoQuarto => statusQuarto.toUpperCase() == 'ON';
  bool get jaEmbarcou => embarque.toUpperCase() == 'SIM';
  bool get temPulseira => pulseira.isNotEmpty && pulseira != 'Não Informado';
}