import { DatabaseSync } from 'node:sqlite';
import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

// Estrutura do banco: um treino tem vários exercícios (relação 1:N).
// ON DELETE CASCADE faz os exercícios serem apagados junto com o treino.
const SCHEMA = `
  CREATE TABLE IF NOT EXISTS workouts (
    id   TEXT PRIMARY KEY,
    data TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS exercises (
    id         TEXT PRIMARY KEY,
    workout_id TEXT NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    ordem      INTEGER NOT NULL,
    nome       TEXT NOT NULL,
    series     INTEGER NOT NULL,
    repeticoes INTEGER NOT NULL,
    carga      REAL NOT NULL
  );

  CREATE INDEX IF NOT EXISTS idx_exercises_workout ON exercises(workout_id);
`;

/**
 * Abre (ou cria) o banco SQLite.
 * Use ':memory:' para um banco temporário (usado nos testes).
 */
export function openDatabase(file) {
  if (file !== ':memory:') {
    mkdirSync(dirname(file), { recursive: true });
  }

  const db = new DatabaseSync(file);
  db.exec('PRAGMA foreign_keys = ON;');
  db.exec(SCHEMA);
  return db;
}
