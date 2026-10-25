import express from 'express';
import cors from 'cors';
import { validarExercicio, validarTreino } from './validation.js';
import * as repo from './repository.js';

/**
 * Cria a aplicação Express.
 * Recebe o banco como parâmetro para que os testes possam usar um banco em memória.
 */
export function createApp(db) {
  const app = express();

  // CORS: necessário para o app rodando no navegador (Flutter Web)
  // conseguir chamar a API em outra porta.
  app.use(cors());
  app.use(express.json({ limit: '100kb' }));

  // Log simples de cada requisição no terminal.
  app.use((req, res, next) => {
    res.on('finish', () => {
      if (process.env.NODE_ENV !== 'test') {
        console.log(`${req.method} ${req.originalUrl} -> ${res.statusCode}`);
      }
    });
    next();
  });

  // Verifica se a API está no ar.
  app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
  });

  // LISTAR todos os treinos (ordem cronológica).
  app.get('/workouts', (req, res) => {
    res.json(repo.listarTreinos(db));
  });

  // BUSCAR um treino pelo id.
  app.get('/workouts/:id', (req, res) => {
    const treino = repo.buscarTreino(db, req.params.id);
    if (!treino) return res.status(404).json({ erro: 'Treino não encontrado' });
    res.json(treino);
  });

  // CRIAR um treino com seus exercícios.
  app.post('/workouts', (req, res) => {
    const { erros, valor } = validarTreino(req.body);
    if (erros.length > 0) {
      return res.status(400).json({ erro: 'Dados inválidos', detalhes: erros });
    }
    const criado = repo.criarTreino(db, valor);
    res.status(201).json(criado);
  });

  // ATUALIZAR um exercício de um treino.
  app.put('/workouts/:workoutId/exercises/:exerciseId', (req, res) => {
    const { erros, valor } = validarExercicio(req.body);
    if (erros.length > 0) {
      return res.status(400).json({ erro: 'Dados inválidos', detalhes: erros });
    }
    const atualizado = repo.atualizarExercicio(db, req.params.workoutId, req.params.exerciseId, valor);
    if (!atualizado) return res.status(404).json({ erro: 'Treino ou exercício não encontrado' });
    res.json(atualizado);
  });

  // EXCLUIR um treino (os exercícios vão junto).
  app.delete('/workouts/:id', (req, res) => {
    const apagou = repo.excluirTreino(db, req.params.id);
    if (!apagou) return res.status(404).json({ erro: 'Treino não encontrado' });
    res.status(204).end();
  });

  // Rota inexistente.
  app.use((req, res) => {
    res.status(404).json({ erro: 'Rota não encontrada' });
  });

  // Tratamento central de erros (JSON malformado, falhas inesperadas).
  app.use((err, req, res, next) => {
    if (err.type === 'entity.parse.failed') {
      return res.status(400).json({ erro: 'JSON inválido no corpo da requisição' });
    }
    console.error(err);
    res.status(500).json({ erro: 'Erro interno do servidor' });
  });

  return app;
}
