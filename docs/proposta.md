# Proposta e Planejamento da Aplicação Mobile

## 1. Nome da aplicação
TreinoLog

## 2. Problema que a aplicação pretende resolver
Muitas pessoas que praticam musculação perdem o controle de cargas, séries e evolução ao longo do tempo, anotando treinos em papel, em aplicativos de notas ou simplesmente não registrando nada. Isso dificulta saber se estão progredindo de verdade e também prejudica hábitos saudáveis complementares, como a hidratação adequada ao longo do dia.

## 3. Público-alvo
Praticantes de musculação que querem acompanhar sua evolução de treino de forma simples e prática, sem depender de planilhas ou aplicativos complexos e pagos, além de manter um controle básico de hidratação diária.

## 4. Objetivo principal
Permitir que o usuário registre seus treinos (exercícios, séries, repetições e cargas), acompanhe sua evolução ao longo do tempo através de gráficos simples, e mantenha o controle da ingestão diária de água.

## 5. Principais funcionalidades
- Registro de treino do dia (exercício, séries, repetições, peso/carga)
- Histórico de treinos realizados
- Gráfico de progresso por exercício (evolução de carga ao longo do tempo)
- Controle de hidratação diária (contador de copos de água com meta diária)
- Perfil básico do usuário

## 6. Telas previstas
1. Tela Inicial (resumo do dia: treino + hidratação)
2. Tela de Novo Treino (registro de exercícios)
3. Tela de Histórico de Treinos
4. Tela de Progresso (gráfico de evolução por exercício)
5. Tela de Perfil/Configurações

## 7. Fluxo básico de navegação entre as telas
```
Tela Inicial (resumo do dia)
    ├── Registrar novo treino → Tela de Novo Treino → volta à Tela Inicial
    ├── Ver histórico → Tela de Histórico de Treinos
    ├── Ver progresso de um exercício → Tela de Progresso
    ├── Marcar copo de água bebido (direto na Tela Inicial)
    └── Acessar Perfil → Tela de Perfil/Configurações
```

## 8. Tecnologia escolhida para o desenvolvimento mobile
Flutter (Dart) — multiplataforma (Android/iOS), boa curva de aprendizado e ampla documentação.

## 9. Tecnologia escolhida para o backend
Não haverá backend em nuvem nesta fase do projeto. Os dados serão armazenados localmente no próprio dispositivo, o que reduz a complexidade de implementação e é suficiente para o escopo proposto.

## 10. Necessidade ou não de comunicação com APIs externas
Não é necessária comunicação com APIs externas para o funcionamento das funcionalidades essenciais do aplicativo.

## 11. Forma prevista de armazenamento de dados
Armazenamento local no dispositivo, utilizando um banco de dados local (SQLite, através do pacote `sqflite`) para os registros de treino e histórico, e armazenamento simples de chave-valor (`shared_preferences`) para configurações do usuário e contador diário de hidratação.

## 12. Repositório Git
https://github.com/Gabriel-Dev77/TreinoLog

## 13. Estrutura inicial de diretórios do projeto
```
TreinoLog/
├── android/
├── ios/
├── lib/
│ ├── main.dart
│ ├── screens/
│ │ ├── home_screen.dart
│ │ ├── new_workout_screen.dart
│ │ ├── history_screen.dart
│ │ ├── progress_screen.dart
│ │ └── profile_screen.dart
│ ├── widgets/
│ ├── models/
│ ├── services/
│ │ └── database_service.dart
│ └── utils/
├── assets/
│ ├── images/
│ └── fonts/
├── test/
├── docs/
│ └── proposta.md
├── pubspec.yaml
└── README.md
```
