// Regras de negócio para os dados recebidos do app.
// O app também valida antes de enviar, mas o backend nunca confia
// apenas no cliente: tudo que chega pela rede é validado de novo aqui.

export const LIMITES = {
  nomeMax: 60,
  seriesMin: 1,
  seriesMax: 50,
  repeticoesMin: 1,
  repeticoesMax: 500,
  cargaMin: 0,
  cargaMax: 1000,
  exerciciosMax: 50,
};

/**
 * Valida um exercício.
 * Retorna { valor, erros } — se `erros` estiver vazio, `valor` está pronto para salvar.
 */
export function validarExercicio(entrada, prefixo = '') {
  const erros = [];
  const e = entrada ?? {};

  const nome = typeof e.nome === 'string' ? e.nome.trim() : '';
  if (!nome) {
    erros.push(`${prefixo}nome é obrigatório`);
  } else if (nome.length > LIMITES.nomeMax) {
    erros.push(`${prefixo}nome deve ter no máximo ${LIMITES.nomeMax} caracteres`);
  }

  if (!Number.isInteger(e.series) || e.series < LIMITES.seriesMin || e.series > LIMITES.seriesMax) {
    erros.push(`${prefixo}séries deve ser um número inteiro entre ${LIMITES.seriesMin} e ${LIMITES.seriesMax}`);
  }

  if (!Number.isInteger(e.repeticoes) || e.repeticoes < LIMITES.repeticoesMin || e.repeticoes > LIMITES.repeticoesMax) {
    erros.push(`${prefixo}repetições deve ser um número inteiro entre ${LIMITES.repeticoesMin} e ${LIMITES.repeticoesMax}`);
  }

  if (typeof e.carga !== 'number' || !Number.isFinite(e.carga) || e.carga < LIMITES.cargaMin || e.carga > LIMITES.cargaMax) {
    erros.push(`${prefixo}carga deve ser um número entre ${LIMITES.cargaMin} e ${LIMITES.cargaMax} kg`);
  }

  return {
    erros,
    valor: { nome, series: e.series, repeticoes: e.repeticoes, carga: e.carga },
  };
}

/**
 * Valida um treino completo (data opcional + lista de exercícios).
 */
export function validarTreino(entrada) {
  const erros = [];
  const t = entrada ?? {};

  let data = new Date();
  if (t.data !== undefined) {
    const convertida = typeof t.data === 'string' ? new Date(t.data) : null;
    if (!convertida || Number.isNaN(convertida.getTime())) {
      erros.push('data deve estar no formato ISO 8601 (ex: 2026-10-25T10:30:00)');
    } else {
      data = convertida;
    }
  }

  const exercicios = [];
  if (!Array.isArray(t.exercicios) || t.exercicios.length === 0) {
    erros.push('o treino precisa ter pelo menos um exercício');
  } else if (t.exercicios.length > LIMITES.exerciciosMax) {
    erros.push(`o treino pode ter no máximo ${LIMITES.exerciciosMax} exercícios`);
  } else {
    t.exercicios.forEach((ex, i) => {
      const r = validarExercicio(ex, `exercício ${i + 1}: `);
      erros.push(...r.erros);
      exercicios.push(r.valor);
    });
  }

  // Mantém a data como o app enviou (string ISO), para não mudar o fuso.
  const dataTexto = typeof t.data === 'string' && erros.length === 0 ? t.data : data.toISOString();

  return { erros, valor: { data: dataTexto, exercicios } };
}
