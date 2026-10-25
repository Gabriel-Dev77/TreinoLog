import { randomUUID } from 'node:crypto';

// Camada de acesso a dados: só aqui existe SQL.
// As rotas (app.js) chamam estas funções e não sabem nada do banco.

function montarTreino(db, linha) {
  const exercicios = db
    .prepare(
      `SELECT id, nome, series, repeticoes, carga
         FROM exercises
        WHERE workout_id = ?
        ORDER BY ordem`,
    )
    .all(linha.id)
    .map((e) => ({ ...e }));

  return { id: linha.id, data: linha.data, exercicios };
}

export function listarTreinos(db) {
  const linhas = db.prepare('SELECT id, data FROM workouts ORDER BY data').all();
  return linhas.map((l) => montarTreino(db, l));
}

export function buscarTreino(db, id) {
  const linha = db.prepare('SELECT id, data FROM workouts WHERE id = ?').get(id);
  return linha ? montarTreino(db, linha) : null;
}

export function criarTreino(db, { data, exercicios }) {
  const id = randomUUID();
  const inserirTreino = db.prepare('INSERT INTO workouts (id, data) VALUES (?, ?)');
  const inserirExercicio = db.prepare(
    `INSERT INTO exercises (id, workout_id, ordem, nome, series, repeticoes, carga)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
  );

  // Transação: ou salva o treino com todos os exercícios, ou não salva nada.
  db.exec('BEGIN');
  try {
    inserirTreino.run(id, data);
    exercicios.forEach((e, i) => {
      inserirExercicio.run(randomUUID(), id, i, e.nome, e.series, e.repeticoes, e.carga);
    });
    db.exec('COMMIT');
  } catch (erro) {
    db.exec('ROLLBACK');
    throw erro;
  }

  return buscarTreino(db, id);
}

/**
 * Atualiza um exercício de um treino.
 * Retorna o treino atualizado, ou null se o treino/exercício não existir.
 */
export function atualizarExercicio(db, workoutId, exerciseId, { nome, series, repeticoes, carga }) {
  const resultado = db
    .prepare(
      `UPDATE exercises
          SET nome = ?, series = ?, repeticoes = ?, carga = ?
        WHERE id = ? AND workout_id = ?`,
    )
    .run(nome, series, repeticoes, carga, exerciseId, workoutId);

  if (resultado.changes === 0) return null;
  return buscarTreino(db, workoutId);
}

/** Retorna true se apagou, false se o treino não existia. */
export function excluirTreino(db, id) {
  const resultado = db.prepare('DELETE FROM workouts WHERE id = ?').run(id);
  return resultado.changes > 0;
}
