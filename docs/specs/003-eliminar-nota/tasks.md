# Tareas 003 — Eliminar notas

Desglose del [plan 003](plan.md) (aprobado el 2026-11-26). Cada tarea es una unidad pequeña y verificable; se hacen en orden salvo las marcadas **[P]**, que pueden ir en paralelo con la anterior.

- **Responsable:** *yo* (agente principal), *test-writer* (pruebas, según `.claude/rules/forma-de-trabajar.md`), *test-runner*, *architecture-reviewer* o *tú*.
- **Hecho cuando:** criterio que se comprueba antes de marcarla. Si no se indica, basta con que el paquete compile.

## Decisiones tomadas

| Id | Pregunta | Decisión (2026-11-26) | Afecta |
|---|---|---|---|
| D-1 | Cómo se elimina | Borrado real en el almacén; "Deshacer" vuelve a guardar una copia | T-03, T-05 |
| D-2 | Copia de una nota existente vaciada en el editor | Su última versión guardada | T-03 |
| D-3 | Error al eliminar | Alerta "No se pudo eliminar la nota" con "Aceptar" | T-09, T-11 |
| D-4 | Duración del error al deshacer | La del aviso: 5 s, o sin límite con VoiceOver | T-17 |
| D-5 | Aspecto del aviso y del estado vacío | Cápsula inferior sobre "Nueva nota"; dos líneas centradas | T-19 |

---

## Paso 0 — Preparación

- [ ] **T-00 · Rama de trabajo** — *yo*
  `git switch main && git pull` y crear `feat/003-delete-note`. Las carpetas sin seguimiento `docs/specs/003-eliminar-nota/` y el cambio de `MEMORY.md` pasan con el cambio de rama.
  **Hecho cuando:** `git branch --show-current` muestra la rama nueva, `main` incluye el PR #1 y las 142 pruebas unitarias + las de UI existentes siguen en verde.

## Paso 1 — Domain (`feat(domain)`)

- [ ] **T-01 · Limpieza compartida del borrador** — *yo*
  Extraer de `SaveNoteUseCase` a una función `internal` de `Domain` la limpieza de título (espacios y saltos de línea) y de bloques de texto en blanco, y la comprobación de "vacía". `SaveNoteUseCase` la usa sin cambiar su comportamiento.
  **Hecho cuando:** las pruebas existentes de `SaveNoteUseCaseTests` siguen en verde sin modificarlas.
- [ ] **T-02 · Resultado de eliminar** [P] — *yo* · RF-9, RF-17
  `public enum NoteDeletionResult: Equatable, Sendable { case deleted(Note), discarded }`.
- [ ] **T-03 · `DeleteNoteUseCase`** — *yo* · depende de T-01 y T-02 · RF-4, RF-7 a RF-9, RF-17, RF-18 · D-1, D-2
  `callAsFunction(_ draft: NoteDraft, lastSaved: Note?) async throws(AppError) -> NoteDeletionResult`, con `DateProvider`:
  - vacía y nueva ⇒ borra si hay `lastSaved` ⇒ `.discarded`;
  - vacía y existente ⇒ borra ⇒ `.deleted(lastSaved)`;
  - con contenido y `lastSaved` ⇒ borra ⇒ `.deleted` con el contenido del borrador y la fecha, el color y el `sequence` de `lastSaved`;
  - con contenido y sin `lastSaved` ⇒ no borra ⇒ `.deleted` con `NoteColor.aqua`, ahora y `nextSequence()`.
- [ ] **T-04 · `RestoreNoteUseCase`** [P] — *yo* · RF-16
  `callAsFunction(_ note: Note) async throws(AppError)` que llama a `repository.save([note])`.
- [ ] **T-05 · Pruebas de Domain** — *test-writer* · depende de T-03 y T-04
  Cada rama de T-03; que la copia conserva categoría, fijada, tareas, color, fecha y `sequence`; espacios y bloques vacíos; que no se borra nada para una nota nueva nunca guardada; errores de `delete` y `nextSequence` como `AppError`; `RestoreNoteUseCase` guarda la nota tal cual y propaga el error.
- [ ] **T-06 · Cierre del paso 1** — *test-runner* + *yo*
  **Hecho cuando:** `DomainTests` y `PresentationTests` en verde y commit `feat(domain): add DeleteNoteUseCase and RestoreNoteUseCase`.

## Paso 2 — Editor en Presentation (`feat(presentation)`)

- [ ] **T-07 · Estado, intents y efectos del editor** — *yo* · RF-4, RF-5, RF-27
  `NoteEditorIntent.deleteTapped` y `.deleteErrorDismissed`; `NoteEditorEffect.deleted(Note)`; `NoteEditorState.isDeleteErrorPresented`.
- [ ] **T-08 · Eliminar en `NoteEditorViewModel`** — *yo* · depende de T-03 y T-07 · RF-4, RF-5, RF-8, RF-9, RF-27 a RF-29
  Recibe `DeleteNoteUseCase`. `.deleteTapped`: ignora si ya está volviendo o eliminando; cancela la espera del guardado automático y aguarda un guardado en curso; `.deleted(note)` ⇒ efecto `.deleted(note)`; `.discarded` ⇒ `.close`; error ⇒ `isDeleteErrorPresented = true` sin tocar el borrador ni `lastSaved`. Una cancelación no cambia el estado.
- [ ] **T-09 · Textos del editor** [P] — *yo* · RF-1, RF-28 · D-3
  En `Localizable.xcstrings`, solo las claves nuevas: "Eliminar nota", "No se pudo eliminar la nota", "Aceptar".
- [ ] **T-10 · Menú ⋯ y alerta** — *yo* · depende de T-07 y T-09 · RF-1 a RF-3, RF-28, RF-33
  En `NoteEditorScreen`, el icono estático ⋯ pasa a ser un `Menu` con `Button("Eliminar nota")` sin `role: .destructive`, con la etiqueta "Más opciones". Alerta ligada a `isDeleteErrorPresented`. `NoteEditorAccessibilityID.deleteMenuItem`.
  **Hecho cuando:** compila y la preview muestra el menú con el texto en color normal.
- [ ] **T-11 · `NoteEditorRoute`** — *yo* · depende de T-08 · RF-5
  Parámetros `deleteNote: DeleteNoteUseCase` y `onDeleted: @MainActor (Note) -> Void`. Con `.deleted(note)`: llama a `onDeleted(note)` y hace `dismiss()`.
- [ ] **T-12 · Previews del editor** [P] — *yo* · depende de T-10
  Alerta de error al eliminar, en claro y oscuro.
- [ ] **T-13 · Pruebas del editor** — *test-writer* · depende de T-08
  Fakes de `PresentationTests/Support` con soporte para eliminar. Eliminar una nota existente, una nueva con texto y una nueva vacía; con guardado automático pendiente (no hay guardado posterior aunque avance el `ManualClock`); con un guardado en curso; fallo ⇒ alerta y estado intacto; `.deleteErrorDismissed`; `.deleteTapped` repetido ⇒ una sola eliminación; cancelación; re-suscripción a `effects()`.
- [ ] **T-14 · Cierre del paso 2** — *test-runner* + *yo*
  **Hecho cuando:** `PresentationTests` en verde, la app compila (aún sin `onDeleted` conectado se pasa un cierre vacío desde `NotesAppApp`) y commit `feat(presentation): delete note from editor menu`.

## Paso 3 — Lista en Presentation (`feat(presentation)`)

- [ ] **T-15 · `NoteDeletion`** — *yo* · RF-10
  `public struct NoteDeletion: Equatable, Sendable` con `id: UUID` (nuevo en cada eliminación) y `note: Note`, en `Presentation/Notes`.
- [ ] **T-16 · Estado e intents de la lista** — *yo* · depende de T-15 · RF-10, RF-24, RF-30
  `NoteListBanner` (`.deleted(Note)`, `.restoreFailed`); `NoteListState.banner` y el derivado `isEmpty` (no carga, sin error, sin notas). `NoteListIntent`: `.noteDeleted(NoteDeletion)`, `.undoTapped`, `.voiceOverChanged(Bool)`, `.movedToBackground`.
- [ ] **T-17 · Aviso en `NoteListViewModel`** — *yo* · depende de T-04 y T-16 · RF-10 a RF-23, RF-30, RF-31 · D-4
  Recibe `RestoreNoteUseCase` y `any Clock<Duration>`. Muestra el aviso con `.noteDeleted` (ignora un `id` ya procesado); espera de 5 s solo con VoiceOver desactivado, reiniciada al desactivarlo; `.undoTapped` restaura y oculta, o muestra `.restoreFailed` con las mismas reglas de duración; `.noteTapped`, `.newNoteTapped` y `.movedToBackground` ocultan el aviso y descartan la copia. Una cancelación no cambia el estado.
- [ ] **T-18 · Textos de la lista** [P] — *yo* · RF-10, RF-24, RF-30, RF-32
  Solo las claves nuevas: "Nota eliminada", "Deshacer", "No se pudo recuperar la nota", "Aún no tienes notas.", "Crea la primera.".
- [ ] **T-19 · Aviso y estado vacío en `NoteListScreen`** — *yo* · depende de T-16 y T-18 · RF-10, RF-11, RF-24 a RF-26, RF-32 a RF-34 · D-5
  Cápsula inferior sobre "Nueva nota" que no bloquea el desplazamiento; anuncio "Nota eliminada" a VoiceOver al aparecer; estado vacío centrado con "Nueva nota" visible; Dynamic Type. `NoteListAccessibilityID`: `undoBanner`, `undoButton`, `emptyState`.
- [ ] **T-20 · `NoteListRoute`** — *yo* · depende de T-17 · RF-13, RF-22
  Parámetros `restoreNote` y `deletion: NoteDeletion?`; `.onChange(of: deletion, initial: true)` ⇒ `.noteDeleted`; `accessibilityVoiceOverEnabled` ⇒ `.voiceOverChanged` al aparecer y al cambiar; `scenePhase == .background` ⇒ `.movedToBackground`. `ContinuousClock()` por defecto.
- [ ] **T-21 · Previews de la lista** [P] — *yo* · depende de T-19
  Aviso de nota eliminada, error al deshacer, estado vacío, estado vacío con aviso y texto grande; en claro y oscuro.
- [ ] **T-22 · Pruebas de la lista** — *test-writer* · depende de T-17
  Con `ManualClock`: aparece el aviso; se oculta a los 5 s y no antes; "Deshacer" restaura con la copia exacta y oculta; fallo al deshacer ⇒ `.restoreFailed`, que también caduca; VoiceOver activo ⇒ no caduca; desactivarlo ⇒ 5 s nuevos; tarjeta, "Nueva nota" y segundo plano lo ocultan; `NoteDeletion` repetida ⇒ un solo aviso; `isEmpty` en sus cuatro combinaciones; re-suscripción a `effects()`.
- [ ] **T-23 · Cierre del paso 3** — *test-runner* + *yo*
  **Hecho cuando:** `PresentationTests` en verde, la app compila y commit `feat(presentation): add undo banner and empty state to note list`.

## Paso 4 — App (`feat(app)`)

- [ ] **T-24 · Composition root y conexión** — *yo* · depende de T-11 y T-20 · RF-5, RF-10, RF-16
  `AppContainer.deleteNote` y `.restoreNote` con el mismo repositorio. `NotesAppApp`: `@State lastDeletion: NoteDeletion?`; `onDeleted: { lastDeletion = NoteDeletion(note: $0) }` en el editor y `deletion: lastDeletion` en la lista.
  **Hecho cuando:** en el simulador, eliminar una nota vuelve a "Mis notas" con el aviso y "Deshacer" la recupera.
- [ ] **T-25 · Cierre del paso 4** — *test-runner* + *yo*
  **Hecho cuando:** todas las pruebas (unitarias y de UI existentes) en verde y commit `feat(app): connect note deletion and undo`.

## Paso 5 — Pruebas de UI (`test(app)`)

- [ ] **T-26 · `NoteDeletionUITests`** — *test-writer* · depende de T-24
  Los diez flujos del paso 5 del plan: menú y cierre sin elegir; eliminar; deshacer en su posición; caducidad a los 5 s; abrir otra nota con el aviso; nota nueva sin guardar recuperada; nota nueva vacía sin aviso; estado vacío y deshacer la última; `-UITestingLoadFailure` ⇒ alerta; relanzar tras una eliminación definitiva.
- [ ] **T-27 · Cierre del paso 5** — *test-runner* + *yo*
  **Hecho cuando:** `NotesAppUITests` en verde y commit `test(app): cover note deletion flows`.

## Paso 6 — Cierre

- [ ] **T-28 · Revisión de arquitectura** — *architecture-reviewer*
  **Hecho cuando:** responde "Sin violaciones de arquitectura" o se corrigen sus hallazgos.
- [ ] **T-29 · Demo manual** — *tú*
  iPhone en claro y oscuro: los flujos de los criterios de finalización de la spec, con VoiceOver (el aviso no caduca y se anuncia) y texto grande. Revisar el aspecto del aviso y del estado vacío (D-5) y la posición de una nota nueva recuperada. iPad pendiente mientras no haya simulador.
- [ ] **T-30 · Memoria y PR** — *yo*
  Actualizar `MEMORY.md` y abrir el PR hacia `main` con `/create-pr`.

## Cobertura de RF

| RF | Implementación | Prueba |
|---|---|---|
| RF-1 a RF-3 | T-10 | T-26 |
| RF-4 a RF-6 | T-03, T-08, T-11 | T-05, T-13, T-26 |
| RF-7 a RF-9 | T-03, T-08 | T-05, T-13, T-26 |
| RF-10 a RF-15 | T-17, T-19, T-20 | T-22, T-26 |
| RF-16 a RF-19 | T-03, T-04, T-17 | T-05, T-22, T-26 |
| RF-20 a RF-23 | T-17, T-20 | T-22, T-26 |
| RF-24 a RF-26 | T-16, T-19 | T-22, T-26 |
| RF-27 a RF-29 | T-08, T-10 | T-13, T-26 |
| RF-30, RF-31 | T-17 | T-22 |
| RF-32 a RF-34 | T-10, T-19 | T-29 (demo manual) |
