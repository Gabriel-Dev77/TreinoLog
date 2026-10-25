import { openDatabase } from './db.js';
import { createApp } from './app.js';

const PORT = Number(process.env.PORT) || 3000;
const DB_FILE = process.env.DB_FILE || 'data/treinolog.db';

const db = openDatabase(DB_FILE);
const app = createApp(db);

// '0.0.0.0' aceita conexões de outros dispositivos da rede
// (ex: celular físico na mesma Wi-Fi), não só do próprio computador.
app.listen(PORT, '0.0.0.0', () => {
  console.log(`TreinoLog API rodando em http://localhost:${PORT}`);
  console.log(`Banco de dados: ${DB_FILE}`);
});
