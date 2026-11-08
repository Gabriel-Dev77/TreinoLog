# Etapa 6 – Integração com API ou Serviço Externo

## Identificação do serviço utilizado

**wger Workout Manager – API REST pública** (https://wger.de)

O wger é um projeto de código aberto (licença AGPL) que mantém um **catálogo colaborativo de exercícios de musculação**. Cada exercício tem nome em vários idiomas, descrição de execução, categoria, músculos trabalhados, equipamentos e imagens, e os dados são publicados sob licença CC-BY-SA.

Ele foi escolhido porque se encaixa no escopo do TreinoLog e resolve um problema real do app. Até a Etapa 5, o usuário digitava o nome de cada exercício à mão, sem nenhuma referência de como executá-lo. Com o catálogo, ele pode:

- pesquisar exercícios e ver como executá-los, quais músculos trabalham e qual equipamento usam;
- escolher um exercício do catálogo ao registrar um treino, que fica **vinculado** a ele;
- trocar o vínculo de um exercício já salvo;
- abrir, a partir de um treino salvo, a ficha do exercício no catálogo.

## Endereço do serviço (base URL)

```
https://wger.de/api/v2
```

O endereço fica em `lib/config/wger_config.dart` e pode ser trocado sem alterar o código (por exemplo, para uma instalação própria do wger):

```bash
flutter run --dart-define=WGER_URL=https://meu-wger.exemplo.com/api/v2
```

## Configuração e credenciais

**Nenhuma credencial é necessária.** Os endpoints de leitura de exercícios do wger são públicos: não exigem cadastro, chave de API nem token. Por isso, nenhum dado sensível é guardado no código nem no repositório.

Outras configurações relevantes:

- **CORS:** o wger libera o acesso de qualquer origem nas rotas `/api/`, então a integração funciona também no Flutter Web.
- **Imagens no Flutter Web:** as imagens do wger ficam fora de `/api/` e não liberam CORS. Para contornar isso, o widget `CatalogImage` usa `webHtmlElementStrategy: WebHtmlElementStrategy.fallback`, que exibe a imagem como um elemento `<img>` do navegador. Se a imagem mesmo assim não carregar, aparece um ícone no lugar.
- **Android:** a permissão `INTERNET` já foi adicionada ao `AndroidManifest.xml` na Etapa 5.
- **Limites de uso:** o wger não limita leituras de exercícios. Mesmo assim, o app só busca depois que o usuário para de digitar (600 ms) e com pelo menos 3 letras, para não fazer uma requisição a cada tecla. Se o serviço responder `429 Too Many Requests`, o app mostra uma mensagem pedindo para aguardar.

## Endpoints utilizados

| Operação | Método | Endpoint | Onde é usado no app |
|---|---|---|---|
| Buscar exercícios por nome | `GET` | `/exerciseinfo/?name__search={termo}&language__code=pt,en&limit=20` | Tela *Catálogo de exercícios* (aberta pela Início, pelo Novo Treino e pela edição de exercício) |
| Consultar um exercício pelo id | `GET` | `/exerciseinfo/{id}/` | Tela de detalhes do exercício (pela lista do catálogo ou pelo botão ⓘ em *Detalhes do Treino*) |

Parâmetros da busca:

| Parâmetro | Valor enviado | Significado |
|---|---|---|
| `name__search` | texto digitado (ex: `supino`) | Busca aproximada pelo nome, que tolera pequenos erros de digitação |
| `language__code` | `pt,en` | Procura em português e em inglês; o catálogo tem bem mais exercícios em inglês |
| `limit` | `20` | Quantidade máxima de resultados |

### Operações de envio e atualização

A API pública do wger é **somente leitura** para quem não tem conta. Por isso, os dados obtidos do catálogo são **enviados e atualizados no backend do próprio TreinoLog** (Etapa 5), que guarda o vínculo de cada exercício com o catálogo no campo `wgerId`:

| Operação | Método | Endpoint (backend TreinoLog) | Dado vindo do wger |
|---|---|---|---|
| Envio | `POST` | `http://localhost:3000/workouts` | `wgerId` do exercício escolhido no catálogo |
| Atualização | `PUT` | `http://localhost:3000/workouts/{id}/exercises/{exerciseId}` | Novo `wgerId` (troca pelo catálogo) ou `null` (remove o vínculo) |

Para isso, o backend recebeu a coluna `wger_id` na tabela `exercises`, com migração automática para bancos criados na Etapa 5, além da validação do campo (inteiro positivo ou `null`).

## Estrutura dos dados

### Dados enviados ao wger

As duas consultas são `GET`, então **não há corpo na requisição**. Os parâmetros vão na URL, e o cabeçalho enviado é `Accept: application/json`.

```
GET https://wger.de/api/v2/exerciseinfo/?name__search=supino&language__code=pt%2Cen&limit=20
```

### Dados recebidos do wger

**Busca (`GET /exerciseinfo/?...`)**: resposta paginada:

```json
{
  "count": 1,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 73,
      "uuid": "c0ab0f5f-...",
      "category": { "id": 11, "name": "Chest" },
      "muscles": [
        { "id": 4, "name": "Pectoralis major", "name_en": "Chest", "is_front": true }
      ],
      "muscles_secondary": [
        { "id": 5, "name": "Triceps brachii", "name_en": "Triceps", "is_front": false }
      ],
      "equipment": [ { "id": 1, "name": "Barbell" }, { "id": 8, "name": "Bench" } ],
      "images": [
        {
          "id": 1,
          "image": "https://wger.de/media/exercise-images/73/....png",
          "is_main": true,
          "thumbnails": { "small": "https://...", "medium": "https://..." }
        }
      ],
      "translations": [
        { "id": 192, "name": "Bench Press", "description": "<p>Lie on the bench...</p>", "language": 2 },
        { "id": 900, "name": "Supino reto", "description": "<p>Deite no banco...</p>", "language": 7 }
      ]
    }
  ]
}
```

**Detalhe (`GET /exerciseinfo/{id}/`)**: o mesmo objeto de um item de `results`, sem a paginação.

A resposta tem outros campos (licenças, autores, vídeos, datas), que o app ignora.

### Conversão para o modelo do app

O JSON é convertido em `CatalogExercise` (`lib/models/catalog_exercise.dart`) pelo construtor `CatalogExercise.fromWger`:

| Campo do app | Origem no JSON do wger | Tratamento |
|---|---|---|
| `id` | `id` | Obrigatório. Sem ele, o item é descartado |
| `nome` | `translations[].name` | Prefere português (`language: 7`) e, na falta dele, inglês (`language: 2`) |
| `nomeIngles` | tradução com `language: 2` | Exibido como apoio quando o nome principal é em português |
| `descricao` | `translations[].description` | HTML convertido em texto (parágrafos e listas) |
| `categoria` | `category.name` | Traduzido (ex: `Chest` → `Peito`) |
| `musculos` / `musculosSecundarios` | `muscles[]` / `muscles_secondary[]` | Usa `name_en` traduzido (ex: `Chest` → `Peitoral`) ou, se vier vazio, o nome em latim (`name`) |
| `equipamentos` | `equipment[].name` | Traduzido (ex: `Barbell` → `Barra`) |
| `imagemUrl` / `miniaturaUrl` | `images[]` (`is_main` primeiro) | Usa `thumbnails.small` na lista e a imagem inteira nos detalhes |

Itens sem `id` ou sem nenhum nome são ignorados, sem derrubar a busca inteira.

### Dados enviados ao backend do TreinoLog (envio e atualização)

`POST /workouts`: o exercício escolhido no catálogo leva o `wgerId`. Exercícios digitados à mão não enviam o campo, ou enviam `null`:

```json
{
  "data": "2026-11-08T18:30:00.000",
  "exercicios": [
    { "nome": "Supino reto", "series": 4, "repeticoes": 10, "carga": 60, "wgerId": 73 },
    { "nome": "Meu exercício", "series": 3, "repeticoes": 12, "carga": 20, "wgerId": null }
  ]
}
```

`PUT /workouts/{id}/exercises/{exerciseId}`:

```json
{ "nome": "Rosca direta", "series": 3, "repeticoes": 12, "carga": 20, "wgerId": 91 }
```

O backend responde com o treino completo, e cada exercício traz o seu `wgerId`.

## Fluxo de comunicação

```
┌─────────────────────────────── App Flutter ───────────────────────────────┐
│                                                                            │
│  ExerciseCatalogScreen ──► WgerService ──── GET /exerciseinfo/?... ───────────►  wger.de
│        │   (debounce 600 ms,       │    ◄──── JSON (count, results[]) ─────────
│        │    estados da tela)       └─► CatalogExercise.fromWger()          │
│        ▼                                                                   │
│  escolhe exercício ──► NewWorkoutScreen / edição (wgerId) ──► WorkoutStore │
│                                                                   │        │
│                                                ApiService ── POST/PUT ───────►  Backend TreinoLog
│                                                                            │      (SQLite: wger_id)
│  Detalhes do Treino ── botão ⓘ ──► CatalogExerciseDetailScreen             │
│                                        └─► WgerService ── GET /exerciseinfo/{id}/ ──►  wger.de
└────────────────────────────────────────────────────────────────────────────┘
```

Passo a passo:

1. O usuário abre o catálogo (pelo card na *Início*, pelo ícone 🔍 no campo de nome do *Novo Treino* ou na edição de um exercício) e digita o nome.
2. Quando ele para de digitar por 600 ms, com pelo menos 3 letras, o `WgerService` faz `GET /exerciseinfo/?name__search=...`.
3. A resposta JSON é validada e convertida em uma lista de `CatalogExercise`.
4. A tela mostra o estado correspondente: carregando, resultados, nenhum resultado ou erro.
5. Se o usuário digitar de novo antes da resposta chegar, a resposta antiga é descartada. Cada busca recebe um número, e só a mais recente é exibida.
6. Ao tocar em um exercício, a tela de detalhes consulta `GET /exerciseinfo/{id}/` e mostra imagem, categoria, músculos, equipamentos e a descrição de execução.
7. No modo seleção, *Usar no treino* (ou o botão ⊕ da lista) devolve o exercício ao formulário, que preenche o nome e guarda o `wgerId`. Um chip "Catálogo: ..." mostra o vínculo, que pode ser removido no X.
8. Ao salvar o treino (**envio**) ou editar o exercício (**atualização**), o `wgerId` vai para o backend do TreinoLog junto com os demais dados.
9. Em *Detalhes do Treino*, exercícios vinculados aparecem com o ícone de livro e o botão ⓘ, que consulta novamente o wger pelo id salvo.

## Tratamento dos estados

Os estados ficam em uma classe `sealed` (`lib/models/request_state.dart`). Com ela, o compilador obriga cada tela a tratar todos os casos. O widget `RequestStateView` (`lib/widgets/request_state_view.dart`) desenha cada estado do mesmo jeito em todas as telas que consultam o wger:

| Estado | Quando acontece | O que o usuário vê |
|---|---|---|
| **Inicial** (`RequestIdle`) | Campo de busca vazio ou com menos de 3 letras | Ícone de lupa e a instrução *"Digite pelo menos 3 letras..."* |
| **Carregando** (`RequestLoading`) | Requisição em andamento | Indicador circular e *"Buscando no catálogo..."* ou *"Carregando detalhes do exercício..."*, anunciados pelo leitor de tela (`liveRegion`) |
| **Sucesso** (`RequestSuccess`) | Resposta 200 com dados | Lista de exercícios com miniatura, categoria e músculos, com a contagem de resultados; ou a ficha completa do exercício |
| **Ausência de dados** (`RequestEmpty`) | Resposta 200 com `results` vazio | Ícone de busca vazia e *"Nenhum exercício encontrado para 'x'"*, com a dica de buscar em inglês |
| **Erro** (`RequestError`) | Sem internet, demora acima de 12 s, status 4xx/5xx, 429 ou JSON inválido | Ícone de nuvem cortada, mensagem específica do problema e botão **Tentar novamente** |

Mensagens de erro (`WgerException`, em `lib/services/wger_service.dart`):

| Situação | Mensagem |
|---|---|
| Sem conexão / DNS / falha de rede | *"Não foi possível acessar o catálogo de exercícios. Verifique sua conexão com a internet."* |
| Tempo esgotado (12 s) | *"O catálogo de exercícios demorou para responder. Tente novamente."* |
| 404 | *"Exercício não encontrado no catálogo."* |
| 429 | *"Muitas consultas ao catálogo em pouco tempo. Aguarde um instante."* |
| Outros códigos de erro | *"O catálogo está indisponível no momento (código N)."* |
| Resposta fora do formato | *"O catálogo respondeu em um formato inesperado."* |

Outros cuidados:

- Uma falha no wger **não afeta o resto do app**. Registrar, listar e editar treinos continua funcionando, porque o vínculo com o catálogo é opcional.
- O envio e a atualização no backend mantêm o tratamento de estados da Etapa 5: botão com spinner durante o envio, SnackBar de sucesso ou erro e aviso de "sem conexão".
- Imagens que falham ao carregar mostram um ícone no lugar, sem quebrar a tela.

## Instruções para executar e testar a integração

### Executar

O catálogo depende apenas de internet. Para salvar treinos, o backend da Etapa 5 também precisa estar rodando.

```bash
# Terminal 1 – backend
cd backend
npm install
npm start

# Terminal 2 – app
flutter pub get
flutter run -d chrome     # ou: flutter run (emulador/celular)
```

> Se o backend já tinha dados da Etapa 5, basta reiniciá-lo: a coluna `wger_id` é criada automaticamente.

### Testar manualmente

1. **Consulta:** na *Início*, toque em **Catálogo de exercícios** e digite `supino` → aparece *"Buscando no catálogo..."* e depois a lista. Toque em um item para ver os detalhes.
2. **Ausência de dados:** busque `xyzxyz` → mensagem de nenhum resultado.
3. **Envio:** em *Novo Treino*, toque no ícone 🔍 do campo de nome, busque `bench press` e toque em ⊕ (ou em *Usar no treino*) → o nome é preenchido e aparece o chip *"Catálogo: ..."*. Preencha séries, repetições e carga, adicione o exercício e salve o treino.
4. **Conferir no servidor:** abra `http://localhost:3000/workouts` no navegador → o exercício aparece com `"wgerId": <número>`.
5. **Consulta pelo treino salvo:** em *Histórico*, abra o treino → o exercício tem o ícone de livro. Toque em ⓘ para abrir a ficha do catálogo.
6. **Atualização:** toque em ✏️, use o ícone 🔍 do campo *Nome* para escolher outro exercício (ou toque no X do chip para remover o vínculo) e salve. Confira o novo `wgerId` em `http://localhost:3000/workouts`.
7. **Erro:** desligue a internet (ou o Wi-Fi do emulador) e faça uma busca → mensagem de erro com **Tentar novamente**. Religue a internet e toque no botão.

Também é possível testar a API do wger direto no navegador:

```
https://wger.de/api/v2/exerciseinfo/?name__search=supino&language__code=pt,en&limit=5
https://wger.de/api/v2/exerciseinfo/73/
```

### Testes automatizados

```bash
flutter test          # app: conversão do JSON do wger e estados do WgerService
cd backend && npm test   # backend: envio/atualização do wgerId e migração do banco
```

- `test/wger_service_test.dart` simula as respostas do wger com `MockClient`, então não precisa de internet. Ele cobre:
  - a montagem da URL de busca;
  - a conversão do JSON, com preferência pelo português, traduções e limpeza do HTML;
  - a lista vazia;
  - os itens incompletos;
  - os erros HTTP 503 e 404, a falha de rede e o JSON inválido.
- `backend/test/api.test.js` cobre o envio e a atualização do `wgerId`, além da rejeição de um `wgerId` inválido.
- `backend/test/db.test.js` cobre a migração de um banco da Etapa 5.

## Principais arquivos desta etapa

| Arquivo | Responsabilidade |
|---|---|
| `lib/config/wger_config.dart` | Base URL, idiomas, limite de resultados e timeout |
| `lib/services/wger_service.dart` | Requisições HTTP ao wger e tratamento de erros |
| `lib/models/catalog_exercise.dart` | Modelo e conversão do JSON do wger |
| `lib/models/request_state.dart` | Estados da comunicação (inicial, carregando, sucesso, vazio, erro) |
| `lib/widgets/request_state_view.dart` | Exibição padronizada de cada estado |
| `lib/widgets/catalog_image.dart` | Imagem do exercício com espaço reservado e fallback |
| `lib/screens/exercise_catalog_screen.dart` | Busca no catálogo (navegação e seleção) |
| `lib/screens/catalog_exercise_detail_screen.dart` | Ficha do exercício |
| `lib/screens/new_workout_screen.dart`, `workout_details_screen.dart` | Uso do catálogo no envio e na atualização |
| `backend/src/db.js`, `validation.js`, `repository.js` | Coluna `wger_id`, migração e validação |

## Créditos

Dados de exercícios fornecidos pelo projeto **wger** (https://wger.de), sob licença **CC-BY-SA 4.0**. A fonte é citada na tela de detalhes do exercício.
