# Etapa 3 – Navegação, UX e Acessibilidade

## Estrutura de navegação implementada
- Navegação principal por **Bottom Tab Bar** (BottomNavigationBar), com 5 abas: Início, Novo Treino, Histórico, Progresso e Perfil.
- `IndexedStack` preserva o estado de cada aba ao alternar entre elas, evitando perda de dados preenchidos ao trocar de tela.
- Diálogos modais (`AlertDialog`) são usados como camada adicional de navegação para confirmações de ações destrutivas.

## Telas e mecanismos de acesso
| Tela | Como se acessa |
|---|---|
| Início | Aba "Início" da bottom tab bar (tela padrão ao abrir o app) |
| Novo Treino | Aba "Novo Treino" |
| Histórico | Aba "Histórico" |
| Progresso | Aba "Progresso" |
| Perfil | Aba "Perfil" |

## Menus, abas e mecanismos de navegação
- **Bottom Tab Bar**: escolhida por posicionar todas as rotas principais na "Zona Natural" do polegar (thumb zone), reduzindo o esforço físico de navegação, especialmente relevante já que cerca de 75% das interações mobile usam apenas um polegar.
- Todas as 5 telas do aplicativo (incluindo o Perfil) foram unificadas na bottom tab bar, tornando a navegação totalmente "descobrível" — o usuário não precisa localizar ícones escondidos em outras partes da interface para acessar qualquer funcionalidade.
- **Diálogo de confirmação (AlertDialog)**: usado antes de excluir um treino, funcionando como uma camada extra de decisão para ações destrutivas.

## Mecanismos de feedback visual implementados
- `SnackBar` customizado (via `FeedbackService`) para toda ação relevante: adicionar exercício, salvar treino, excluir treino, atingir meta de hidratação.
- Toda mensagem combina **cor + ícone + texto**, para não depender apenas da cor (acessível a usuários com daltonismo).
- Feedback háptico (vibração) acompanha ações de sucesso e erro, reforçando a percepção da ação além do visual.
- Estados desabilitados (ex: botão "Registrar copo de água" fica desabilitado ao atingir a meta) comunicam visualmente que a ação não está mais disponível.
- **Skeleton screen** na Tela de Histórico: exibe uma estrutura de blocos cinza por um breve instante antes dos dados, reduzindo a percepção de espera.

## Principais decisões de UX adotadas
- Botões de ação primária (Salvar treino, Adicionar exercício) usam largura total da tela, facilitando o toque (Lei de Fitts: alvo grande).
- Ação destrutiva (excluir treino) exige confirmação explícita em diálogo — aumento proposital de "atrito" para evitar exclusões acidentais.
- O Perfil foi movido do ícone no AppBar para uma aba própria na bottom tab bar, priorizando a descoberta imediata de todas as funcionalidades em vez de escondê-las atrás de ícones secundários.
- Paleta de cores e tipografia centralizadas em `AppTheme`, garantindo consistência visual em todas as telas.

## Medidas de acessibilidade implementadas
- **Contraste**: paleta de cores definida em `AppTheme` com tons escuros sobre fundo claro, buscando atender à recomendação WCAG AA (mínimo 4.5:1 para texto normal).
- **Alvos de toque**: botões e ícones interativos configurados com no mínimo 48x48dp (`minimumSize`/`constraints`), conforme diretriz do Material Design.
- **`Semantics`**: aplicado nos itens da bottom tab bar e nos principais botões e campos (label, hint, button/textField), descrevendo o quê é o elemento e o que a ação faz.
- **`MergeSemantics`**: usado em `ExerciseTile` para unir ícone, nome e detalhes do exercício em um único bloco de leitura, evitando fragmentação para usuários de leitor de tela.
- **`ExcludeSemantics`**: usado em ícones puramente decorativos (halter, gota d'água, avatar de perfil), evitando ruído sonoro desnecessário na navegação por leitor de tela.
- **`liveRegion`**: usado no contador de hidratação, para que leitores de tela anunciem automaticamente a mudança de valor sem exigir nova navegação manual até o texto.
- Nunca a cor é o único indicador de estado: mensagens de sucesso/erro sempre têm ícone + texto.

## Instruções para execução e teste da navegação
```bash
flutter pub get
flutter run
```
Para testar a navegação:
1. Use as 5 abas inferiores para alternar entre Início, Novo Treino, Histórico, Progresso e Perfil.
2. Em Novo Treino, adicione exercícios e salve um treino (observe o feedback visual e o feedback háptico).
3. No Histórico, tente excluir um treino e observe a confirmação exigida antes da exclusão.
4. Aumente a hidratação até a meta diária e observe o botão ficar desabilitado.

Para testar a acessibilidade, é possível ativar o leitor de tela do sistema operacional (TalkBack no Android ou VoiceOver no iOS/macOS) e navegar pelo app usando apenas gestos de leitura, sem olhar para a tela.'