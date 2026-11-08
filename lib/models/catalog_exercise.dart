import '../config/wger_config.dart';

/// Exercício vindo do catálogo externo wger (somente leitura).
///
/// Representa a parte da resposta de `GET /exerciseinfo/` que o app usa.
/// O JSON completo do wger tem muito mais campos (licenças, autores,
/// vídeos...), que são ignorados.
class CatalogExercise {
  final int id;
  final String nome;

  /// Nome em inglês, mostrado como apoio quando o nome principal é em português.
  final String? nomeIngles;
  final String categoria;
  final String descricao;
  final List<String> musculos;
  final List<String> musculosSecundarios;
  final List<String> equipamentos;
  final String? imagemUrl;
  final String? miniaturaUrl;

  const CatalogExercise({
    required this.id,
    required this.nome,
    this.nomeIngles,
    required this.categoria,
    required this.descricao,
    required this.musculos,
    required this.musculosSecundarios,
    required this.equipamentos,
    this.imagemUrl,
    this.miniaturaUrl,
  });

  /// Converte um item de `results` da resposta do wger.
  ///
  /// Formato de entrada (resumido):
  /// ```json
  /// {
  ///   "id": 73,
  ///   "category": {"id": 11, "name": "Chest"},
  ///   "muscles": [{"id": 4, "name": "Pectoralis major", "name_en": "Chest"}],
  ///   "muscles_secondary": [...],
  ///   "equipment": [{"id": 1, "name": "Barbell"}],
  ///   "images": [{"image": "https://...", "is_main": true,
  ///               "thumbnails": {"small": "https://...", "medium": "https://..."}}],
  ///   "translations": [{"name": "Bench Press", "description": "<p>...</p>", "language": 2}]
  /// }
  /// ```
  ///
  /// Lança [FormatException] se faltar o id ou não houver nenhum nome.
  factory CatalogExercise.fromWger(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) throw const FormatException('exercício sem id');

    final traducoes = (json['translations'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((t) => (t['name'] as String? ?? '').trim().isNotEmpty)
        .toList();
    if (traducoes.isEmpty) throw const FormatException('exercício sem nome');

    Map<String, dynamic>? traducaoDoIdioma(String codigo) {
      final idIdioma = WgerConfig.idsIdioma[codigo];
      for (final t in traducoes) {
        if (t['language'] == idIdioma) return t;
      }
      return null;
    }

    // Usa a primeira tradução disponível na ordem de preferência (pt, en...).
    Map<String, dynamic> principal = traducoes.first;
    for (final codigo in WgerConfig.idiomas) {
      final t = traducaoDoIdioma(codigo);
      if (t != null) {
        principal = t;
        break;
      }
    }

    final nome = (principal['name'] as String).trim();
    final ingles = (traducaoDoIdioma('en')?['name'] as String?)?.trim();

    // Descrição: a do idioma principal; se vier vazia, tenta a em inglês.
    var descricao = limparHtml(principal['description'] as String? ?? '');
    if (descricao.isEmpty) {
      descricao = limparHtml(traducaoDoIdioma('en')?['description'] as String? ?? '');
    }

    final categoriaJson = json['category'];
    final categoria = categoriaJson is Map<String, dynamic>
        ? _traduzir(_categorias, categoriaJson['name'] as String? ?? '')
        : '';

    // Imagem principal (is_main) ou, se não houver, a primeira.
    final imagens = (json['images'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((i) => i['image'] is String)
        .toList();
    Map<String, dynamic>? imagem;
    if (imagens.isNotEmpty) {
      imagem = imagens.firstWhere((i) => i['is_main'] == true, orElse: () => imagens.first);
    }
    final miniaturas = imagem?['thumbnails'];
    final imagemUrl = imagem?['image'] as String?;
    final miniaturaUrl = miniaturas is Map<String, dynamic>
        ? (miniaturas['small'] as String? ?? imagemUrl)
        : imagemUrl;

    return CatalogExercise(
      id: id,
      nome: nome,
      nomeIngles: (ingles != null && ingles.isNotEmpty && ingles != nome) ? ingles : null,
      categoria: categoria,
      descricao: descricao,
      musculos: _musculos(json['muscles']),
      musculosSecundarios: _musculos(json['muscles_secondary']),
      equipamentos: (json['equipment'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((e) => _traduzir(_equipamentos, e['name'] as String? ?? ''))
          .where((e) => e.isNotEmpty)
          .toList(),
      imagemUrl: imagemUrl,
      miniaturaUrl: miniaturaUrl,
    );
  }

  /// A descrição do wger vem em HTML (`<p>`, `<ul><li>`...).
  /// Converte para texto simples, mantendo parágrafos e listas legíveis.
  static String limparHtml(String html) {
    var texto = html
        .replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<\s*li[^>]*>', caseSensitive: false), '\n• ')
        .replaceAll(RegExp(r'</\s*(p|li|ul|ol|h\d)\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&');

    texto = texto
        .split('\n')
        .map((linha) => linha.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return texto.trim();
  }

  static List<String> _musculos(dynamic lista) {
    return (lista as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((m) {
          final comum = (m['name_en'] as String? ?? '').trim();
          // name_en ("Chest") é o nome popular; name é o nome em latim.
          return comum.isNotEmpty
              ? _traduzir(_musculosPt, comum)
              : (m['name'] as String? ?? '').trim();
        })
        .where((m) => m.isNotEmpty)
        .toList();
  }

  static String _traduzir(Map<String, String> tabela, String valor) =>
      tabela[valor.trim()] ?? valor.trim();

  // O wger devolve estes nomes sempre em inglês; traduzimos os mais comuns.
  static const _categorias = {
    'Abs': 'Abdômen',
    'Arms': 'Braços',
    'Back': 'Costas',
    'Calves': 'Panturrilhas',
    'Cardio': 'Cardio',
    'Chest': 'Peito',
    'Legs': 'Pernas',
    'Shoulders': 'Ombros',
  };

  static const _musculosPt = {
    'Abs': 'Abdômen',
    'Biceps': 'Bíceps',
    'Calves': 'Panturrilhas',
    'Chest': 'Peitoral',
    'Glutes': 'Glúteos',
    'Hamstrings': 'Posterior da coxa',
    'Lats': 'Dorsais',
    'Quads': 'Quadríceps',
    'Shoulders': 'Ombros',
    'Triceps': 'Tríceps',
    'Traps': 'Trapézio',
    'Lower back': 'Lombar',
    'Obliques': 'Oblíquos',
  };

  static const _equipamentos = {
    'Barbell': 'Barra',
    'Bench': 'Banco',
    'Dumbbell': 'Halteres',
    'Gym mat': 'Colchonete',
    'Incline bench': 'Banco inclinado',
    'Kettlebell': 'Kettlebell',
    'Pull-up bar': 'Barra fixa',
    'Resistance band': 'Elástico',
    'SZ-Bar': 'Barra W',
    'Swiss Ball': 'Bola suíça',
    'none (bodyweight exercise)': 'Peso corporal',
  };
}
