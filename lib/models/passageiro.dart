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
  String? flowType; // Adicionei o flowType aqui

  Passageiro({
    required this.colegio,
    required this.turma,
    required this.nome,
    required this.cpf,
    required this.rg,
    required this.embarque,
    required this.pulseira,
    required this.foto,
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
      flowType: json['flowType']?.toString(), // CORREÇÃO: Adicionar leitura do flowType
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
      'flowType': flowType, // CORREÇÃO: Adicionar o flowType no JSON
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
      flowType: flowType ?? this.flowType,
    );
  }
}