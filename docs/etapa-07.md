# Etapa 7 – Gerenciamento de Estado Global e Recursos do Dispositivo

## Resumo

| Item | Escolha |
|---|---|
| Mecanismo de estado global | **Provider** (`provider` 6.1), com classes `ChangeNotifier` |
| Estados globais | Treinos (`WorkoutProvider`), configurações do usuário (`SettingsProvider`) e hidratação + lembretes (`HydrationProvider`) |
| Recurso nativo principal | **Notificações locais** do Android (`flutter_local_notifications` 23), usadas como lembretes de beber água |
| Recurso nativo extra | **Compartilhamento** do sistema (`share_plus` 13), para enviar o resumo de um treino |

## Mecanismo de gerenciamento de estado utilizado

Foi utilizado o pacote **Provider**, a solução de gerenciamento de estado recomendada na documentação oficial do Flutter para apps deste porte.

Funcionamento:

1. Cada estado global é uma classe que estende `ChangeNotifier`. Quando um dado muda, a classe chama `notifyListeners()`.
2. Em `lib/main.dart`, os estados são criados uma única vez, carregados antes do app abrir e colocados no topo da árvore de widgets com `MultiProvider`:

   ```dart
   MultiProvider(
     providers: [
       ChangeNotifierProvider.value(value: settings),
       ChangeNotifierProvider.value(value: hydration),
       ChangeNotifierProvider.value(value: workouts),
     ],
     child: const TreinoLogApp(),
   )
   ```
3. As telas acessam os estados de duas formas:
   - `context.watch<T>()` lê o dado e **redesenha a tela** sempre que ele mudar;
   - `context.read<T>()` apenas executa uma ação, como `addWorkout` ou `adicionarCopo`, sem redesenhar.

**Antes (até a Etapa 6):** os treinos ficavam numa classe com campos `static` (`WorkoutStore`), e cada tela precisava de um `ValueListenableBuilder` manual. A hidratação era um `setState` dentro da tela Início: ninguém mais conseguia ler o valor, e ele **voltava a zero toda vez que o app fechava**. O nome no Perfil era um texto fixo no código.

**Depois:** `WorkoutStore` foi substituído pelo `WorkoutProvider`, e a hidratação e as configurações viraram estados globais salvos no aparelho.

## Estados tratados globalmente

### 1. Treinos: `WorkoutProvider` (`lib/providers/workout_provider.dart`)
- Lista de treinos (sincronizada com o backend da Etapa 5, com cache local).
- Indicador `offline` (falha de conexão com o servidor).
- Ações: `refresh`, `addWorkout`, `removeWorkout`, `updateExercise`, `findById`, `treinosDoDia`.

### 2. Configurações do usuário: `SettingsProvider` (`lib/providers/settings_provider.dart`)
- Nome do usuário.
- Meta diária de água, entre 4 e 20 copos.
- Lembretes ligados ou desligados e o intervalo entre eles (1 a 4 horas).
- Salvas no aparelho com `SharedPreferences`.

### 3. Hidratação e lembretes: `HydrationProvider` (`lib/providers/hydration_provider.dart`)
- Copos de água registrados hoje. São salvos no aparelho e **zerados automaticamente quando o dia muda**.
- Situação dos lembretes (`StatusLembretes`): `ativos`, `desativados`, `permissaoNegada`, `indisponivel` ou `erro`.
- Horário do próximo lembrete.
- Depende do `SettingsProvider`: escuta as mudanças dele e refaz a agenda de notificações.

## Justificativa para o tratamento desses estados como globais

| Estado | Telas e partes do app que usam | Por que global |
|---|---|---|
| Treinos | Início (treinos de hoje), Novo Treino (cria), Histórico (lista e exclui), Detalhes (edita, exclui e compartilha), Progresso (gráfico), Perfil (total de treinos), faixa de "sem conexão" | Uma alteração feita em uma tela precisa aparecer em todas as outras sem recarregar. Exemplo: salvar um treino no Novo Treino atualiza na hora o resumo da Início, o Histórico e o gráfico do Progresso |
| Configurações | Perfil (edita), Início (saudação e meta), lembretes (meta, intervalo, ligado/desligado) | São definidas em uma tela e usadas em outras. Mudar a meta no Perfil precisa atualizar a Início e os textos e horários dos lembretes |
| Hidratação | Início (registra e desfaz copos, mostra o próximo lembrete), Perfil (mostra o progresso do dia e controla os lembretes), notificações (param quando a meta é atingida) | O mesmo contador é lido por duas telas e pelo agendador de notificações. Como estado local de uma tela, ele se perdia ao fechar o app e nenhuma outra parte conseguia saber quantos copos já foram registrados |

Estados que pertencem a uma única tela continuaram **locais**, com `setState`. É o caso do texto dos campos do formulário de Novo Treino, do resultado da busca no catálogo e do indicador "salvando...". Torná-los globais não traria benefício.

## Recurso nativo utilizado

### Principal: notificações locais (lembretes de hidratação)

- **Pacote:** `flutter_local_notifications` 23.0.3, com `timezone` 0.11 para informar a data e hora do agendamento.
- **Código:** `lib/services/reminder_service.dart` (classe `NotificationReminderService`).
- **O que faz:** agenda no sistema operacional lembretes para beber água a cada 1, 2, 3 ou 4 horas, das 8h às 22h. Como o agendamento é feito pelo próprio Android (AlarmManager), **as notificações chegam mesmo com o app fechado**.
- **Integração com o app:**
  - o texto da notificação usa o progresso real do dia, por exemplo *"Você registrou 3 de 8 copos hoje"*;
  - ao bater a meta, os lembretes do dia param, e no dia seguinte voltam;
  - mudar a meta ou o intervalo no Perfil refaz a agenda na hora;
  - ao tocar na notificação, o app abre.
- A regra dos horários fica numa função pura e testável, `planejarLembretes` (`lib/utils/reminder_planner.dart`). Ela agenda os horários restantes de hoje e todos os de amanhã, para os lembretes continuarem chegando mesmo que o app não seja aberto no dia seguinte. A agenda é refeita sempre que o app é aberto ou um copo é registrado.

### Extra: compartilhamento

- **Pacote:** `share_plus` 13.3.1. **Código:** `lib/services/share_service.dart`.
- **O que faz:** na tela **Detalhes do Treino**, o botão de compartilhar abre a janela de compartilhamento do sistema com um resumo do treino. Dá para enviar por WhatsApp, Telegram, e-mail ou qualquer outro app instalado.

```
🏋️ Meu treino de 22/11/2026 às 18:05

• Supino reto: 4x10 com 60 kg
• Flexão: 3x15 (peso corporal)

2 exercício(s) · volume total: 2400 kg
Registrado com o TreinoLog
```

## Justificativa da escolha do recurso

- **Pertinência ao projeto:** o controle de hidratação faz parte da proposta do TreinoLog desde a Etapa 1, mas até aqui era só um contador manual que dependia do usuário lembrar de abrir o app. Notificações transformam a meta diária num hábito, que é o objetivo declarado na proposta.
- **Integração real com o estado global:** o recurso depende dos três tipos de dado do app. A meta e o intervalo vêm das configurações, o texto e a parada ao bater a meta vêm do contador de copos, e o status volta para as telas Início e Perfil.
- **Funciona com o app fechado**, o que um recurso só de interface não faria.
- **Compartilhamento (extra):** registrar e mostrar a evolução é comum entre quem treina. Ele não exige permissão e funciona também no navegador, então complementa as notificações, que são exclusivas do Android.

## Permissões necessárias

Declaradas em `android/app/src/main/AndroidManifest.xml`:

| Permissão | Para que serve | Como é concedida |
|---|---|---|
| `POST_NOTIFICATIONS` | Exibir notificações | **Android 13 ou superior:** o app pede ao usuário, com a caixa "Permitir que TreinoLog envie notificações?", quando ele liga os lembretes no Perfil. **Android 12 ou inferior:** concedida automaticamente na instalação |
| `RECEIVE_BOOT_COMPLETED` | Reagendar os lembretes depois que o celular é reiniciado | Automática (não aparece para o usuário) |
| `INTERNET` | Backend e catálogo (etapas anteriores) | Automática |

Outros pontos sobre permissões:

- **Não** é usada a permissão de alarmes exatos (`SCHEDULE_EXACT_ALARM`). Os lembretes usam o modo `inexactAllowWhileIdle`, em que o Android pode atrasar alguns minutos para economizar bateria. Isso é aceitável para um lembrete de água e evita pedir uma permissão especial ao usuário.
- A permissão é pedida **só quando o usuário liga os lembretes**, não ao abrir o app. Assim ele entende o motivo do pedido.
- O **compartilhamento não exige nenhuma permissão**.

Também foram declarados no manifest os dois *receivers* do plugin, `ScheduledNotificationReceiver` e `ScheduledNotificationBootReceiver`. No `android/app/build.gradle.kts`, foram feitos os ajustes exigidos pelo plugin: *desugaring* (`isCoreLibraryDesugaringEnabled` e `desugar_jdk_libs`) e `compileSdk` 37. O Android Gradle Plugin foi atualizado para 9.1.1 em `android/settings.gradle.kts`.

## Descrição do fluxo de utilização do recurso

### Lembretes de hidratação

```
Perfil ─► liga "Lembrar de beber água"
            │
            ▼
   HydrationProvider.ativarLembretes()
            │
            ├─ recurso indisponível (navegador) ──► aviso "Indisponível neste dispositivo"
            │
            ├─ pede permissão (Android 13+) ──► negada ──► switch continua desligado,
            │                                             aviso + botão "Abrir configurações"
            ▼ concedida
   SettingsProvider.lembretesAtivos = true  (salvo no aparelho)
            │  notifyListeners
            ▼
   HydrationProvider.reagendar()
     └─ planejarLembretes(agora, copos, meta, intervalo) ─► lista de horários
     └─ NotificationReminderService.agendar(lista) ─► zonedSchedule() no Android
            │
            ▼
   Início e Perfil mostram "Próximo lembrete: hoje às 14:00"

   ...com o app fechado, no horário agendado:
   Android exibe "Hora de beber água 💧 — Você registrou 3 de 8 copos hoje..."
            │ usuário toca
            ▼
   App abre ─► Início ─► "Registrar copo de água"
            └─ HydrationProvider.adicionarCopo() ─► salva ─► reagenda
               (ao bater a meta: cancela os lembretes de hoje, mantém os de amanhã)
```

Situações que também refazem a agenda:

- mudança da meta ou do intervalo no Perfil;
- desfazer um copo;
- **voltar para o app** (`AppLifecycleListener` em `main.dart`). Isso zera o contador se o dia mudou e detecta se o usuário retirou a permissão nas configurações do Android.

O botão **"Enviar lembrete de teste"** no Perfil mostra uma notificação na hora, para conferir se tudo está funcionando.

### Compartilhamento

Histórico → abrir um treino → botão de compartilhar → janela do sistema → escolher o app de destino. A tela mostra o resultado: *"Treino compartilhado!"* ou *"Compartilhamento cancelado"*.

## Tratamento de falhas ou indisponibilidade do recurso

| Situação | Como o app trata |
|---|---|
| **Plataforma sem o recurso** (Flutter Web/Chrome, desktop) | `suportado` retorna `false` e o status fica `indisponivel`. O Perfil mostra *"Indisponível neste dispositivo"* com a explicação, e a Início mostra *"Lembretes não disponíveis neste dispositivo"*. Contador de água, treinos e o resto do app funcionam normalmente |
| **Usuário nega a permissão** | O switch **não** é ligado, o status fica `permissaoNegada` e aparece uma mensagem de erro. No Perfil surge um card explicando o motivo, com o botão **"Abrir configurações"**, que abre a tela de notificações do app no Android |
| **Negou mais de uma vez** (o Android não mostra mais a caixa) | O pedido retorna "negado" na hora, então cai no caso anterior e o usuário é levado às configurações do sistema |
| **Permissão retirada depois**, nas configurações do Android | Ao voltar para o app, a verificação detecta, cancela a agenda e mostra o card de permissão negada. Ao permitir de novo e voltar, os lembretes são reagendados sozinhos |
| **Não foi possível abrir as configurações** | Mensagem com o caminho manual: *Configurações > Apps > TreinoLog > Notificações* |
| **Erro inesperado do plugin ao agendar** | Exceção capturada, status `erro`, mensagem *"Não foi possível agendar os lembretes"* e registro no console (`debugPrint`). O app não fecha |
| **Celular reiniciado** | O `ScheduledNotificationBootReceiver` reagenda as notificações pendentes |
| **Fabricantes que matam apps em segundo plano** (Xiaomi, Huawei...) | Limitação do sistema, que pode atrasar ou bloquear lembretes. Como a agenda é refeita sempre que o app abre, os lembretes se recuperam no próximo uso |
| **Compartilhamento falha ou não existe** | O resumo do treino é **copiado para a área de transferência**, com o aviso *"O resumo foi copiado: cole onde quiser"*. Se nem a cópia funcionar, aparece uma mensagem de erro |
| **Usuário fecha a janela de compartilhamento** | Mensagem informativa *"Compartilhamento cancelado"* |

Para que essas situações possam ser testadas sem celular, o serviço de notificações implementa a interface `AgendadorLembretes`, e os testes usam uma implementação falsa (ver abaixo).

## Instruções para execução e teste

### Executar

Os lembretes precisam de **um celular ou emulador Android**. No Chrome o app funciona, mas mostra o recurso como indisponível.

```bash
# Terminal 1 – backend (Etapa 5)
cd backend
npm start

# Terminal 2 – app no celular (conectado pelo cabo, com depuração USB ativa)
flutter pub get
flutter devices                 # confirme que o celular aparece
flutter run -d <id-do-celular> --dart-define=API_URL=http://<IP-do-PC>:3000
```

> Na primeira compilação depois desta etapa, o Gradle pode baixar o Android SDK 37 e a biblioteca de *desugaring*. Isso pode levar alguns minutos.

### Testar o estado global

1. **Perfil:** digite seu nome e toque em ✓ → a **Início** passa a mostrar *"Olá, <nome>!"*.
2. **Perfil:** mude a meta de água com − e + → a **Início** mostra a nova meta na hora.
3. **Início:** registre 2 copos → o **Perfil** mostra *"Hoje: 2 de N copos"*.
4. **Feche o app completamente e abra de novo** → os 2 copos continuam lá. Até a Etapa 6 eles voltavam a zero.
5. **Novo Treino:** salve um treino → **Início** (treinos de hoje), **Histórico**, **Progresso** e **Perfil** (total de treinos) atualizam sem recarregar.

### Testar as notificações

1. **Perfil →** ligue **"Lembrar de beber água"** → no Android 13+, toque em **Permitir**. Deve aparecer *"Lembretes ligados!"* e *"Próximo lembrete: ... às HH:00"*.
2. Toque em **"Enviar lembrete de teste"** → a notificação aparece na barra na hora.
3. **Feche o app** e aguarde o horário do próximo lembrete. Para testar mais rápido, escolha o intervalo de **1h**. A notificação aparece com o progresso do dia.
4. Toque na notificação → o app abre.
5. Registre copos até bater a meta → a Início mostra *"Próximo lembrete: amanhã às 08:00"*.

### Testar as falhas

1. **Permissão negada:** desinstale o app (ou limpe os dados), instale de novo, ligue os lembretes e toque em **Não permitir** → o switch continua desligado e aparece o card com **"Abrir configurações"**.
2. **Permissão retirada:** com os lembretes ligados, vá em *Configurações do Android > Apps > TreinoLog > Notificações*, desative e volte ao app → o Perfil mostra o aviso de permissão negada.
3. **Recurso indisponível:** rode `flutter run -d chrome` → o Perfil mostra *"Indisponível neste dispositivo"* e o resto do app funciona.

### Testar o compartilhamento

**Histórico →** abra um treino → toque no ícone de compartilhar → escolha o WhatsApp, por exemplo. Para testar o cancelamento, feche a janela sem escolher nada.

### Testes automatizados

```bash
flutter test
```

`test/estado_global_test.dart` usa um agendador de notificações **falso**, então roda sem celular. Ele cobre:

- **Horários dos lembretes:** só os de hoje que ainda não passaram, nenhum hoje quando a meta foi atingida, e a virada de mês.
- **Contador de água:**
  - fica salvo depois de fechar o app;
  - zera quando o dia muda, tanto com o app aberto quanto ao abrir só no dia seguinte.
- **Estado global compartilhado:** a meta muda no Perfil e o estado de hidratação reage e avisa as telas.
- **Permissão:**
  - concedida: os lembretes são agendados;
  - negada: a opção não liga;
  - retirada depois: os lembretes são cancelados.
- **Recurso indisponível:** o app continua funcionando.
- **Desligar os lembretes:** a agenda é cancelada.
- **Compartilhamento:** o texto do resumo do treino.

## Principais arquivos desta etapa

| Arquivo | Responsabilidade |
|---|---|
| `lib/main.dart` | Cria os estados globais, `MultiProvider` e `AppLifecycleListener` |
| `lib/providers/workout_provider.dart` | Estado global de treinos (substitui `lib/services/workout_store.dart`, removido) |
| `lib/providers/settings_provider.dart` | Estado global de configurações |
| `lib/providers/hydration_provider.dart` | Estado global de hidratação e controle dos lembretes |
| `lib/services/reminder_service.dart` | Recurso nativo: notificações (interface `AgendadorLembretes` e implementação Android) |
| `lib/utils/reminder_planner.dart` | Cálculo dos horários dos lembretes |
| `lib/services/share_service.dart` | Recurso nativo: compartilhamento, com cópia para a área de transferência como alternativa |
| `lib/screens/profile_screen.dart` | Nome, meta, lembretes, permissão e teste de notificação |
| `lib/screens/home_screen.dart` | Usa os três estados globais |
| `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts`, `android/settings.gradle.kts` | Permissões, receivers, *desugaring*, compileSdk e versão do AGP |
| `test/estado_global_test.dart` | Testes da etapa |
