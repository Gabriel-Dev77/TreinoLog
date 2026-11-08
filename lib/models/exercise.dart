class Exercise {
  final String id;
  final String nome;
  final int series;
  final int repeticoes;
  final double carga;

  /// Etapa 6: id do exercício no catálogo externo wger.
  /// Fica null quando o exercício foi digitado à mão.
  final int? wgerId;

  Exercise({
    required this.id,
    required this.nome,
    required this.series,
    required this.repeticoes,
    required this.carga,
    this.wgerId,
  });

  // Cria uma cópia do exercício com alguns campos alterados.
  // Usado na operação de ATUALIZAÇÃO (update).
  // Como `null` em wgerId significa "não mudar", use [removerWgerId]
  // para desvincular o exercício do catálogo.
  Exercise copyWith({
    String? nome,
    int? series,
    int? repeticoes,
    double? carga,
    int? wgerId,
    bool removerWgerId = false,
  }) {
    return Exercise(
      id: id,
      nome: nome ?? this.nome,
      series: series ?? this.series,
      repeticoes: repeticoes ?? this.repeticoes,
      carga: carga ?? this.carga,
      wgerId: removerWgerId ? null : (wgerId ?? this.wgerId),
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
      'wgerId': wgerId,
    };
  }

  // Reconstrói o objeto a partir do Map lido do servidor ou do cache local.
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      nome: json['nome'] as String,
      series: json['series'] as int,
      repeticoes: json['repeticoes'] as int,
      carga: (json['carga'] as num).toDouble(),
      // Dados antigos (cache da Etapa 5) não têm esse campo.
      wgerId: (json['wgerId'] as num?)?.toInt(),
    );
  }
}
