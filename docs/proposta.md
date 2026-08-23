# Proposta e Planejamento da Aplicação Mobile

## 1. Nome da aplicação
Aprenda Brincando

## 2. Problema que a aplicação pretende resolver
Crianças com dificuldades de aprendizagem (como dislexia, TDAH e discalculia) frequentemente têm dificuldade em acompanhar o ritmo tradicional de ensino, o que gera desmotivação e defasagem escolar. Faltam ferramentas acessíveis, lúdicas e adaptadas que ajudem essas crianças a desenvolver habilidades de leitura, escrita e raciocínio lógico de forma prazerosa e no próprio ritmo.

## 3. Público-alvo
Crianças de 6 a 10 anos com dificuldades de aprendizagem (diagnosticadas ou em processo de avaliação), pais/responsáveis e professores/psicopedagogos que acompanham essas crianças.

## 4. Objetivo principal
Oferecer minigames educativos e adaptativos que estimulem leitura, escrita, memória e raciocínio lógico-matemático, com acompanhamento de progresso para pais e educadores.

## 5. Principais funcionalidades
- Minigames de leitura (reconhecimento de letras/sílabas/palavras)
- Minigames de matemática básica (contagem, associação de números)
- Jogo de memória e atenção
- Sistema de progresso/níveis (gamificação com estrelas ou medalhas)
- Painel para pais/responsáveis acompanharem o desempenho da criança
- Perfil personalizável por criança (avatar, nome)

## 6. Telas previstas
1. Tela de Login/Seleção de Perfil (criança ou responsável)
2. Tela Inicial (Menu de Jogos)
3. Tela do Jogo (ex: jogo de associação de letras)
4. Tela de Resultado/Recompensa (estrelas, parabéns, avanço de nível)
5. Tela de Progresso (visão do responsável — gráfico de desempenho)
6. Tela de Perfil/Configurações

## 7. Fluxo básico de navegação entre as telas
```
Login/Seleção de Perfil
        ↓
   Tela Inicial (Menu)
        ↓
   Escolhe um Jogo → Tela do Jogo → Tela de Resultado → volta ao Menu
        ↓
Responsável acessa "Progresso" a partir do Menu ou Perfil
```

## 8. Tecnologia escolhida para o desenvolvimento mobile
**Flutter (Dart)** — multiplataforma (Android/iOS), boa performance para interfaces lúdicas e ricas em animação, curva de aprendizado tranquila.

## 9. Tecnologia escolhida para o backend
**Firebase (Firestore + Firebase Authentication)** — dispensa a necessidade de montar um servidor próprio, possui plano gratuito e boa integração com Flutter.

## 10. Necessidade ou não de comunicação com APIs externas
Sim. Está prevista a integração com uma API de texto-para-fala (Text-to-Speech), utilizada para narrar as instruções dos jogos, já que o público-alvo tem dificuldade de leitura.

## 11. Forma prevista de armazenamento de dados
- **Firestore (NoSQL)**: perfis das crianças, progresso, pontuações e configurações
- **Firebase Authentication**: autenticação dos responsáveis
- **Armazenamento local (cache)**: dados básicos para funcionamento offline

## 12. Repositório Git
(https://github.com/Gabriel-Dev77/Aprenda-Brincando)

## 13. Estrutura inicial de diretórios do projeto
```
aprenda_brincando/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   ├── game_screen.dart
│   │   ├── result_screen.dart
│   │   ├── progress_screen.dart
│   │   └── profile_screen.dart
│   ├── widgets/
│   ├── models/
│   ├── services/
│   │   └── firebase_service.dart
│   └── utils/
├── assets/
│   ├── images/
│   ├── sounds/
│   └── fonts/
├── test/
├── docs/
│   └── proposta.md
├── pubspec.yaml
└── README.md
```
