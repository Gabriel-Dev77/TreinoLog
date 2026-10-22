# Etapa 4 – Persistência Local de Dados

## Mecanismo de persistência utilizado
SharedPreferences, com os dados serializados em formato JSON.

## Justificativa da escolha
A proposta inicial (Etapa 1) previa o uso de SQLite via `sqflite`. Essa escolha foi revista nesta etapa pelos seguintes motivos:

- O `sqflite` não possui suporte nativo ao Flutter Web, ambiente usado como principal forma de teste deste projeto ao longo do desenvolvimento. Usá-lo exigiria configuração adicional específica para Web (`sqflite_common_ffi_web`), aumentando a complexidade sem necessidade real.
- O `shared_preferences` funciona de forma uniforme em Web, Android, iOS e desktop, sem exigir plugins nativos específicos por plataforma.
- Para o volume de dados da aplicação (lista de treinos de um único usuário, sem relacionamentos complexos entre múltiplas tabelas), um banco relacional traria complexidade desnecessária. Uma estrutura simples, serializada em JSON e armazenada como string, atende integralmente aos requisitos de CRUD exigidos.

## Estrutura dos dados armazenados
Os dados são salvos sob uma única chave (`treinolog_workouts`) no SharedPreferences, como uma string JSON representando uma lista de treinos:

```json
[
  {
    "id": "1760000000000000",
    "data": "2026-10-21T10:30:00.000",
    "exercicios": [
      {
        "id": "1760000000000001",
        "nome": "Supino reto",
        "series": 4,
        "repeticoes": 10,
        "carga": 60.0
      }
    ]
  }
]
```

## Descrição das operações de persistência implementadas
Implementadas na classe `WorkoutStore` (`lib/services/workout_store.dart`):

| Operação | Método | Onde é acionada |
|---|---|---|
| Criar | `WorkoutStore.addWorkout()` | Tela "Novo Treino", ao salvar um treino |
| Recuperar | `WorkoutStore.init()` | Executado em `main()`, antes do app abrir |
| Atualizar | `WorkoutStore.updateExercise()` | Tela "Detalhes do Treino", ao editar um exercício |
| Remover | `WorkoutStore.removeWorkout()` | Tela "Histórico", ao excluir um treino (com confirmação) |

Todas as operações de escrita (`addWorkout`, `removeWorkout`, `updateExercise`) atualizam a lista em memória e, em seguida, persistem o estado inteiro no SharedPreferences através do método privado `_salvar()`.

## Telas que utilizam os dados persistidos
- **Novo Treino**: cria novos registros.
- **Histórico**: exibe e remove os treinos salvos.
- **Detalhes do Treino**: exibe e permite editar exercícios de um treino específico.
- **Progresso**: lê os dados persistidos para montar o gráfico de evolução de carga.

## Instruções para execução e teste
```bash
flutter pub get
flutter run
```

## Procedimento para verificar a persistência após encerramento e reabertura
1. Abrir o aplicativo e ir até "Novo Treino".
2. Registrar ao menos um exercício e salvar o treino.
3. Conferir no "Histórico" que o treino aparece.
4. Fechar completamente o aplicativo (no navegador: recarregar a página com F5; no celular: fechar o app pelos aplicativos recentes).
5. Reabrir o aplicativo e acessar novamente o "Histórico".
6. Confirmar que o treino registrado continua presente, comprovando a persistência dos dados entre sessões.