/// Um lembrete de hidratação a ser agendado no aparelho.
class LembreteAgendado {
  final int id;
  final DateTime quando;
  final String titulo;
  final String corpo;

  const LembreteAgendado({
    required this.id,
    required this.quando,
    required this.titulo,
    required this.corpo,
  });
}

/// Primeiro id usado pelos lembretes agendados.
const int idBaseLembretes = 100;

/// Calcula os horários dos lembretes de hidratação.
///
/// Regras:
/// - lembretes de [intervaloHoras] em [intervaloHoras] horas, entre
///   [inicioHora] e [fimHora] (ex: 8h, 10h, 12h ... 22h);
/// - hoje: só os horários que ainda não passaram, e nenhum se a meta do dia
///   já foi atingida;
/// - dias seguintes (até completar [dias]): todos os horários. Assim os
///   lembretes continuam chegando mesmo que o app não seja aberto amanhã.
///   Toda vez que o app é aberto ou um copo é registrado, a agenda é refeita.
///
/// É uma função pura (não acessa o plugin nem o relógio do sistema), por
/// isso pode ser testada facilmente.
List<LembreteAgendado> planejarLembretes({
  required DateTime agora,
  required int coposHoje,
  required int meta,
  required int intervaloHoras,
  int inicioHora = 8,
  int fimHora = 22,
  int dias = 2,
}) {
  assert(intervaloHoras > 0);
  final lembretes = <LembreteAgendado>[];
  // Margem para não agendar algo "para agora" que já teria passado.
  final limite = agora.add(const Duration(minutes: 1));

  for (var dia = 0; dia < dias; dia++) {
    final hoje = dia == 0;
    if (hoje && coposHoje >= meta) continue;

    for (var hora = inicioHora; hora <= fimHora; hora += intervaloHoras) {
      // DateTime ajusta sozinho a virada de mês/ano (ex: dia 32 → dia 1).
      final quando = DateTime(agora.year, agora.month, agora.day + dia, hora);
      if (!quando.isAfter(limite)) continue;

      lembretes.add(
        LembreteAgendado(
          id: idBaseLembretes + lembretes.length,
          quando: quando,
          titulo: 'Hora de beber água 💧',
          corpo: hoje
              ? 'Você registrou $coposHoje de $meta copos hoje. Que tal mais um?'
              : 'Beba um copo de água e registre no TreinoLog. Meta do dia: $meta copos.',
        ),
      );
    }
  }
  return lembretes;
}
