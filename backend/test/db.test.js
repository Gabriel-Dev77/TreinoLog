import { test } from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { openDatabase } from '../src/db.js';

test('migra banco da Etapa 5 adicionando a coluna wger_id', () => {
  const pasta = mkdtempSync(join(tmpdir(), 'treinolog-'));
  const arquivo = join(pasta, 'antigo.db');

  try {
    // Banco no formato antigo (sem wger_id), com um exercício já salvo.
    const antigo = new DatabaseSync(arquivo);
    antigo.exec(`
      CREATE TABLE workouts (id TEXT PRIMARY KEY, data TEXT NOT NULL);
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY, workout_id TEXT NOT NULL, ordem INTEGER NOT NULL,
        nome TEXT NOT NULL, series INTEGER NOT NULL, repeticoes INTEGER NOT NULL, carga REAL NOT NULL
      );
      INSERT INTO workouts VALUES ('w1', '2026-10-25T10:00:00');
      INSERT INTO exercises VALUES ('e1', 'w1', 0, 'Supino', 4, 10, 60);
    `);
    antigo.close();

    const db = openDatabase(arquivo);
    const colunas = db.prepare('PRAGMA table_info(exercises)').all().map((c) => c.name);
    assert.ok(colunas.includes('wger_id'));

    const linha = db.prepare('SELECT nome, wger_id FROM exercises WHERE id = ?').get('e1');
    assert.equal(linha.nome, 'Supino');
    assert.equal(linha.wger_id, null);
    db.close();
  } finally {
    rmSync(pasta, { recursive: true, force: true });
  }
});
