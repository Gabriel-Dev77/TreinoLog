# Etapa 2 – Implementação do Protótipo de Interface

## Telas implementadas
- Tela Inicial: resumo diário (treino do dia + hidratação) e acesso à Tela de Perfil
- Tela de Novo Treino: formulário para registrar exercícios (nome, séries, repetições, carga)
- Tela de Histórico: lista dos treinos já registrados, com data/hora
- Tela de Progresso: evolução de carga por exercício, em formato de gráfico de barras
- Tela de Perfil: acessível pelo ícone na Tela Inicial

## Principais componentes utilizados
- `Scaffold`, `AppBar`, `BottomNavigationBar` — estrutura e navegação principal
- `Card`, `ListView.builder`, `GridView.builder` — exibição de listas e grades
- `TextField` + `TextEditingController` — campos de formulário
- `ElevatedButton`, `OutlinedButton`, `IconButton` — ações do usuário
- `SnackBar` — feedback visual de ações (ex: "Treino salvo com sucesso!")
- `LayoutBuilder`, `ConstrainedBox` — adaptação de layout

## Componentes reutilizáveis
- `ExerciseTile`: exibe os dados de um exercício; utilizado tanto na Tela de Novo Treino quanto na Tela de Histórico.
- `ResponsiveContainer`: limita a largura máxima do conteúdo em telas grandes; utilizado nas telas Inicial, Novo Treino, Histórico e Progresso.

## Elementos de entrada de dados
- Campo de texto para nome do exercício
- Campos numéricos para séries, repetições e carga (kg)
- Botão para adicionar exercício à lista do treino
- Botão para salvar o treino completo

## Estratégias de adaptação a diferentes tamanhos de tela
- `LayoutBuilder` na Tela de Novo Treino: em telas estreitas, os campos de série/repetição/carga são empilhados verticalmente; em telas largas, ficam lado a lado.
- `LayoutBuilder` na Tela de Progresso: alterna entre 1 e 2 colunas de cards, conforme a largura disponível.
- `ResponsiveContainer`: limita a largura máxima do conteúdo (700–900px) em telas muito largas, evitando um layout esticado.
- `SingleChildScrollView`: evita que o conteúdo "estoure" a tela em dispositivos menores.

## Instruções para execução da aplicação
```bash
flutter pub get
flutter run
```

## Principais decisões de interface tomadas nesta etapa
- Conforme especificado na etapa, não há persistência de dados nem comunicação com servidor: os treinos são armazenados em memória através da classe `WorkoutStore`, sendo perdidos ao reiniciar o app.
- A Tela de Perfil foi mantida fora do menu de navegação inferior para não sobrecarregar a interface, sendo acessada por um ícone na Tela Inicial.
- O gráfico de progresso foi implementado com widgets nativos do Flutter (sem bibliotecas externas), priorizando simplicidade e leveza.