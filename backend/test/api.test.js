import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { openDatabase } from '../src/db.js';
import { createApp } from '../src/app.js';

process.env.NODE_ENV = 'test';

let server;
let base;

before(async () => {
  const app = createApp(openDatabase(':memory:'));
  await new Promise((resolve) => {
    server = app.listen(0, resolve);
  });
  base = `http://localhost:${server.address().port}`;
});

after(() => server.close());

async function chamar(metodo, caminho, corpo) {
  const res = await fetch(base + caminho, {
    method: metodo,
    headers: { 'Content-Type': 'application/json' },
    body: corpo === undefined ? undefined : typeof corpo === 'string' ? corpo : JSON.stringify(corpo),
  });
  const texto = await res.text();
  return { status: res.status, body: texto ? JSON.parse(texto) : null };
}

const treinoValido = {
  data: '2026-10-25T10:30:00.000',
  exercicios: [
    { nome: 'Supino reto', series: 4, repeticoes: 10, carga: 60 },
    { nome: 'Agachamento', series: 3, repeticoes: 12, carga: 80.5 },
  ],
};

test('GET /health responde ok', async () => {
  const r = await chamar('GET', '/health');
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'ok');
});

test('fluxo completo: criar → listar → editar → excluir', async () => {
  // Criar
  const criado = await chamar('POST', '/workouts', treinoValido);
  assert.equal(criado.status, 201);
  assert.ok(criado.body.id);
  assert.equal(criado.body.exercicios.length, 2);
  assert.equal(criado.body.exercicios[0].nome, 'Supino reto');

  // Visualizar
  const lista = await chamar('GET', '/workouts');
  assert.equal(lista.status, 200);
  assert.ok(lista.body.some((t) => t.id === criado.body.id));

  // Alterar
  const exId = criado.body.exercicios[0].id;
  const editado = await chamar('PUT', `/workouts/${criado.body.id}/exercises/${exId}`, {
    nome: 'Supino inclinado',
    series: 5,
    repeticoes: 8,
    carga: 65,
  });
  assert.equal(editado.status, 200);
  assert.equal(editado.body.exercicios[0].nome, 'Supino inclinado');
  assert.equal(editado.body.exercicios[0].carga, 65);

  // Excluir
  const apagado = await chamar('DELETE', `/workouts/${criado.body.id}`);
  assert.equal(apagado.status, 204);

  const depois = await chamar('GET', `/workouts/${criado.body.id}`);
  assert.equal(depois.status, 404);
});

test('rejeita treino sem exercícios', async () => {
  const r = await chamar('POST', '/workouts', { exercicios: [] });
  assert.equal(r.status, 400);
  assert.ok(r.body.detalhes.length > 0);
});

test('rejeita exercício com valores inválidos', async () => {
  const r = await chamar('POST', '/workouts', {
    exercicios: [{ nome: '  ', series: 0, repeticoes: -1, carga: 5000 }],
  });
  assert.equal(r.status, 400);
  assert.equal(r.body.detalhes.length, 4);
});

test('rejeita JSON malformado', async () => {
  const r = await chamar('POST', '/workouts', '{ isso não é json');
  assert.equal(r.status, 400);
});

test('editar exercício inexistente retorna 404', async () => {
  const r = await chamar('PUT', '/workouts/nao-existe/exercises/nada', {
    nome: 'X',
    series: 1,
    repeticoes: 1,
    carga: 0,
  });
  assert.equal(r.status, 404);
});

test('excluir treino inexistente retorna 404', async () => {
  const r = await chamar('DELETE', '/workouts/nao-existe');
  assert.equal(r.status, 404);
});
