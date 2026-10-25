# Etapa 5 – Primeira Versão Funcional com Backend

## Visão geral da arquitetura

Nesta etapa o TreinoLog passou a ter **frontend e backend separados**:

```
┌──────────────────────────┐        HTTP + JSON        ┌───────────────────────────┐
│  App Flutter (frontend)  │  ───────────────────────► │  API REST (backend)       │
│                          │                           │  Node.js + Express        │
│  telas → WorkoutStore →  │  ◄─────────────────────── │  validação → repositório  │
│  ApiService              │                           │  → SQLite (treinolog.db)  │
│  cache: SharedPreferences│                           │                           │
└──────────────────────────┘                           └───────────────────────────┘
```

| Responsabilidade | Onde fica |
|---|---|
| Interface, navegação, validação de formulário, feedback visual | App Flutter (`lib/`) |
| Comunicação HTTP com a API | `lib/services/api_service.dart` |
| Estado dos treinos e cache local | `lib/services/workout_store.dart` |
| Regras de negócio e validação definitiva | Backend (`backend/src/validation.js`) |
| Armazenamento oficial dos dados | Backend, banco SQLite (`backend/data/treinolog.db`) |

## Fluxo completo de negócio implementado

**Registrar → visualizar → alterar → excluir um treino** (CRUD completo, com os dados guardados no servidor):

1. **Criar**: na aba *Novo Treino*, o usuário adiciona exercícios (nome, séries, repetições, carga) e toca em *Salvar treino*. O app envia `POST /workouts`; o backend valida, grava no SQLite e devolve o treino com os ids gerados.
2. **Visualizar**: a aba *Histórico* busca `GET /workouts` e lista os treinos (mais recentes primeiro). A aba *Início* mostra o resumo do dia e a aba *Progresso* monta o gráfico de evolução de carga com os mesmos dados.
3. **Alterar**: tocando em um treino, abre-se *Detalhes do Treino*. Ao tocar em um exercício, um formulário permite editar os valores; ao salvar, o app envia `PUT /workouts/:id/exercises/:exerciseId`.
4. **Excluir**: pelo ícone de lixeira (no Histórico ou em Detalhes), após confirmação, o app envia `DELETE /workouts/:id` e o treino some de todas as telas.

## Passo a passo para executar o fluxo

1. Inicie o backend (ver *Instruções para execução e teste*) e confirme que `http://localhost:3000/health` responde `{"status":"ok"}`.
2. Inicie o app Flutter.
3. Vá até **Novo Treino**, preencha *Supino reto*, *4*, *10*, *60* e toque em **Adicionar exercício**. Adicione mais um exercício, se quiser.
4. Toque em **Salvar treino** → aparece a mensagem verde *"Treino salvo com sucesso!"*.
5. Vá até **Histórico** → o treino aparece no topo da lista. (Ele também aparece em `http://localhost:3000/workouts` no navegador, comprovando que está no servidor.)
6. Toque no treino → **Detalhes do Treino** → toque em *Supino reto*, mude a carga para *65* e toque em **Salvar** → mensagem *"Exercício atualizado"*.
7. Volte ao **Progresso** e veja a nova carga no gráfico.
8. Em **Detalhes** (ou no Histórico), toque na lixeira → confirme em **Excluir** → mensagem *"Treino excluído"* e o treino deixa de aparecer.

## Funcionalidades integradas nesta etapa

- **Backend próprio** (`backend/`): API REST em Node.js + Express com banco SQLite, nas rotas:

  | Método | Rota | Descrição | Respostas |
  |---|---|---|---|
  | GET | `/health` | Verifica se a API está no ar | 200 |
  | GET | `/workouts` | Lista todos os treinos | 200 |
  | GET | `/workouts/:id` | Busca um treino | 200, 404 |
  | POST | `/workouts` | Cria um treino com seus exercícios | 201, 400 |
  | PUT | `/workouts/:workoutId/exercises/:exerciseId` | Edita um exercício | 200, 400, 404 |
  | DELETE | `/workouts/:id` | Exclui um treino (e seus exercícios) | 204, 404 |

- **Integração do app com a API**: o `WorkoutStore` (Etapa 4) manteve a mesma interface usada pelas telas, mas agora cada operação passa pela `ApiService` antes de atualizar a lista local.
- **Cache local / modo offline**: a última lista recebida do servidor continua salva no `SharedPreferences` (mecanismo da Etapa 4). Se o backend estiver fora do ar, o app abre normalmente, mostra os treinos já conhecidos e exibe um aviso de "sem conexão", bloqueando apenas as alterações.
- **Funcionalidades das etapas anteriores mantidas**: navegação por abas (Etapa 3), acessibilidade com `Semantics` (Etapa 3), feedback com cor + ícone + vibração (Etapa 3), resumo do dia e controle de hidratação, gráfico de progresso (Etapa 2).
- **Novidades na interface**: remover um exercício da lista antes de salvar, excluir o treino pela tela de detalhes, "puxar para atualizar" e botão de atualizar no Histórico.

## Tratamento de entradas inválidas

A validação acontece **em duas camadas**, com os mesmos limites:

| Campo | Regra |
|---|---|
| Nome do exercício | obrigatório, até 60 caracteres |
| Séries | número inteiro de 1 a 50 |
| Repetições | número inteiro de 1 a 500 |
| Carga (kg) | número de 0 a 1000 (aceita vírgula ou ponto; 0 = peso corporal) |
| Treino | pelo menos 1 e no máximo 50 exercícios |

1. **No app** (`lib/utils/validators.dart`): os formulários de *Novo Treino* e *Editar exercício* usam `Form` + `TextFormField` com `validator`. O erro aparece em vermelho embaixo do campo correspondente e nada é enviado ao servidor enquanto houver campo inválido. Os campos numéricos também usam `inputFormatters`, que impedem digitar letras.
2. **No backend** (`backend/src/validation.js`): toda requisição é validada de novo, pois a API não pode confiar apenas no cliente. Dados inválidos retornam **HTTP 400** com a lista de problemas (`{"erro": "Dados inválidos", "detalhes": [...]}`), e o app mostra a primeira mensagem ao usuário. JSON malformado também retorna 400, e ids inexistentes retornam 404.

Também são tratados os **erros de comunicação**: servidor desligado, sem rede ou demora acima de 8 segundos geram uma mensagem clara (*"Não foi possível conectar ao servidor..."*) em vez de travar ou fechar o app.

## Mecanismos de feedback utilizados

- **SnackBar padronizado** (`FeedbackService`): verde para sucesso (treino salvo, exercício atualizado, treino excluído), vermelho para erro (validação, falha de rede, erro do servidor) e azul para informações (exercício adicionado ou removido da lista). Sempre com cor + ícone + texto, acompanhado de vibração.
- **Indicadores de carregamento**: o botão *Salvar treino* mostra um spinner com o texto *"Enviando ao servidor..."* e fica desabilitado durante o envio, evitando treinos duplicados. A tela de detalhes mostra uma barra de progresso durante edição ou exclusão, e o Histórico mostra o *skeleton* enquanto busca os dados pela primeira vez.
- **Erros nos campos**: mensagens embaixo de cada campo inválido do formulário.
- **Aviso de sem conexão** (`OfflineBanner`): faixa laranja no topo das telas quando o servidor não responde, com botão *"Tentar de novo"*. Ela é anunciada pelo leitor de tela (`liveRegion`) e some sozinha quando a conexão volta.
- **Estado de erro no Histórico**: se não há dados nem conexão, a tela explica o problema e oferece *"Tentar novamente"*.
- **Confirmação** antes de excluir (`AlertDialog`).

## Principais decisões técnicas realizadas

- **Node.js + Express no backend**: é uma das stacks mais usadas para APIs REST, tem pouca configuração inicial e roda igual em Windows, Linux e macOS.
- **SQLite nativo do Node (`node:sqlite`)**: dispensa instalar um servidor de banco (como MySQL ou PostgreSQL) e não exige compilar dependências nativas no Windows. Os dados ficam em um único arquivo (`backend/data/treinolog.db`). O modelo é relacional, com tabelas `workouts` e `exercises` (1:N, `ON DELETE CASCADE`), e a criação usa **transação**, para que um treino nunca fique salvo pela metade.
- **Organização do backend em camadas**: `app.js` (rotas HTTP) → `validation.js` (regras de negócio) → `repository.js` (único lugar com SQL) → `db.js` (conexão e esquema). O banco é injetado em `createApp(db)`, o que permite testar com um banco em memória.
- **O servidor gera os ids** (UUID). O app usa ids temporários apenas na lista do formulário, antes de salvar.
- **O servidor confirma antes da tela mudar**: a lista local só é atualizada depois de a API responder com sucesso. Assim, o que o usuário vê é sempre o que está gravado no servidor.
- **SharedPreferences reaproveitado como cache**, e não mais como armazenamento principal. Isso atende à "persistência local, quando aplicável" e permite consultar os treinos mesmo sem conexão. Alterações sem conexão são bloqueadas de propósito, porque sincronizar edições feitas offline exigiria resolver conflitos e está fora do escopo desta etapa.
- **Interface do `WorkoutStore` preservada**: as telas continuam chamando `addWorkout`, `removeWorkout` e `updateExercise`, então a troca da persistência local para o backend ficou concentrada na camada de serviço.
- **Endereço da API configurável** (`lib/config/api_config.dart`): o padrão é `10.0.2.2:3000` no emulador Android e `localhost:3000` no Web e no desktop, com troca por `--dart-define=API_URL=...`.
- **CORS habilitado** no backend, necessário para o Flutter Web chamar a API em outra porta.
- **Android**: adicionadas a permissão `INTERNET` e `usesCleartextTraffic` no `AndroidManifest.xml`, pois a API local roda em HTTP (sem HTTPS).

## Instruções para execução e teste

### Pré-requisitos
- Flutter SDK
- **Node.js 22.13 ou superior** (recomendado: versão LTS mais recente). Verifique com `node --version`.

### 1. Backend
```bash
cd backend
npm install
npm start
```
A API sobe em `http://localhost:3000` e cria o banco em `backend/data/treinolog.db`.

> O Node pode exibir o aviso `ExperimentalWarning: SQLite is an experimental feature`. É apenas um aviso e não afeta o funcionamento.

Testes automatizados da API (cobrem o fluxo criar → listar → editar → excluir e os casos de entrada inválida):
```bash
cd backend
npm test
```

Teste manual pelo terminal (opcional):
```bash
curl http://localhost:3000/health
curl -X POST http://localhost:3000/workouts -H "Content-Type: application/json" -d "{\"exercicios\":[{\"nome\":\"Supino\",\"series\":4,\"repeticoes\":10,\"carga\":60}]}"
curl http://localhost:3000/workouts
```

### 2. App Flutter
Em outro terminal, com o backend rodando:
```bash
flutter pub get
flutter run -d chrome        # Web
flutter run                  # emulador Android (usa 10.0.2.2:3000 automaticamente)
```
Celular físico na mesma rede Wi-Fi (troque pelo IP do seu computador, obtido com `ipconfig`):
```bash
flutter run --dart-define=API_URL=http://192.168.0.10:3000
```

Testes do app (validação dos campos e conversão JSON dos modelos):
```bash
flutter test
```

### 3. Testando entradas inválidas e falhas
- Em *Novo Treino*, toque em **Adicionar exercício** com os campos vazios, ou informe séries = 0 ou carga = 2000. Os erros aparecem embaixo dos campos.
- Toque em **Salvar treino** sem exercícios → mensagem de erro.
- **Pare o backend** (Ctrl+C) e tente salvar um treino → mensagem *"Não foi possível conectar ao servidor"*. A faixa laranja de "sem conexão" aparece, mas os treinos já carregados continuam visíveis. Inicie o backend de novo e toque em **Tentar de novo**.

### Observação sobre dados da Etapa 4
Os treinos salvos apenas no aparelho durante a Etapa 4 não são enviados automaticamente para o servidor. A partir desta etapa, o servidor é a fonte oficial dos dados, e o cache local é substituído pela lista do servidor na primeira sincronização.
