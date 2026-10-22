class Exercise {
  final String id;
  final String nome;
  final int series;
  final int repeticoes;
  final double carga;

  Exercise({
    required this.id,
    required this.nome,
    required this.series,
    required this.repeticoes,
    required this.carga,
  });

  // Cria uma cópia do exercício com alguns campos alterados.
  // Usado na operação de ATUALIZAÇÃO (update).
  Exercise copyWith({
    String? nome,
    int? series,
    int? repeticoes,
    double? carga,
  }) {
    return Exercise(
      id: id,
      nome: nome ?? this.nome,
      series: series ?? this.series,
      repeticoes: repeticoes ?? this.repeticoes,
      carga: carga ?? this.carga,
    );
  }

  // Transforma o objeto num Map simples, pronto para virar texto JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'series': series,
      'repeticoes': repeticoes,
      'carga': carga,
    };
  }

  // Reconstrói o objeto a partir do Map lido do armazenamento local.
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      nome: json['nome'] as String,
      series: json['series'] as int,
      repeticoes: json['repeticoes'] as int,
      carga: (json['carga'] as num).toDouble(),
    );
  }
}