## TreinoLog

Aplicativo mobile para registro e acompanhamento de treinos de musculação, com controle de hidratação diária, desenvolvido de forma progressiva ao longo da disciplina.

## Sobre o projeto

Este repositório contém o desenvolvimento progressivo da aplicação TreinoLog, elaborada como trabalho da disciplina de Desenvolvimento Mobile.

A proposta completa do projeto (problema, público-alvo, funcionalidades, telas, fluxo de navegação e tecnologias) está disponível em [`docs/proposta.md`](docs/proposta.md).

## Arquitetura

A partir da Etapa 5, o projeto é dividido em **frontend mobile** (Flutter) e **backend** (API REST), que se comunicam por HTTP com JSON. Detalhes em [`docs/etapa-05.md`](docs/etapa-05.md).

## Tecnologias utilizadas

- **Frontend mobile:** Flutter (Dart), pacote `http` para consumo da API
- **Backend:** Node.js + Express (API REST)
- **Banco de dados:** SQLite (módulo nativo `node:sqlite`), no servidor
- **Cache local no app:** `shared_preferences` (permite consultar os treinos sem conexão)

## Estrutura do projeto

```
TreinoLog/
├── backend/                  # API REST (Node.js + Express + SQLite)
│   ├── src/
│   │   ├── server.js         # ponto de entrada (porta 3000)
│   │   ├── app.js            # rotas HTTP
│   │   ├── validation.js     # regras de validação
│   │   ├── repository.js     # acesso ao banco (SQL)
│   │   └── db.js             # conexão e criação das tabelas
│   ├── test/api.test.js      # testes da API
│   └── package.json
├── lib/                      # App Flutter
│   ├── main.dart
│   ├── config/               # endereço da API
│   ├── models/               # Workout, Exercise
│   ├── screens/              # telas
│   ├── services/             # ApiService, WorkoutStore, FeedbackService
│   ├── theme/
│   ├── utils/                # validadores de formulário
│   └── widgets/              # componentes reutilizáveis
├── test/                     # testes do app
├── docs/                     # documentação de cada etapa
├── pubspec.yaml
└── README.md
```

## Como executar

Pré-requisitos: Flutter SDK e Node.js 22.13 ou superior.

**1. Backend** (deixe rodando em um terminal):
```bash
cd backend
npm install
npm start
```

**2. App** (em outro terminal):
```bash
flutter pub get
flutter run
```

O app se conecta a `http://localhost:3000` (Web/desktop) ou `http://10.0.2.2:3000` (emulador Android). Para celular físico, use `flutter run --dart-define=API_URL=http://IP-DO-SEU-PC:3000`.

**Testes:** `npm test` (dentro de `backend/`) e `flutter test` (na raiz).

## Autor

- Gabriel Pereira Oliveira
- Disciplina: Tecnologia de Construção de Software 2

## Status do desenvolvimento

- Etapa 1: Proposta e planejamento (ver [`docs/proposta.md`](docs/proposta.md))
- Etapa 2: Protótipo de interface (ver [`docs/etapa-02.md`](docs/etapa-02.md))
- Etapa 3: Navegação, UX e acessibilidade (ver [`docs/etapa-03.md`](docs/etapa-03.md))
- Etapa 4: Persistência local de dados (ver [`docs/etapa-04.md`](docs/etapa-04.md))
- Etapa 5: Primeira versão funcional com backend (ver [`docs/etapa-05.md`](docs/etapa-05.md))
