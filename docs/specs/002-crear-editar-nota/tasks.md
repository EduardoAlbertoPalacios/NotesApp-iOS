# Tareas 002 — Crear y editar notas

Desglose del [plan 002](plan.md) (aprobado el 2026-11-11). Cada tarea es una unidad pequeña y verificable; se hacen en orden salvo las marcadas **[P]**, que pueden ir en paralelo con la anterior.

- **Responsable:** *yo* (agente principal), *test-writer* (pruebas, según `.claude/rules/forma-de-trabajar.md`), *test-runner*, *architecture-reviewer* o *tú*.
- **Hecho cuando:** criterio que se comprueba antes de marcarla.

## Decisiones tomadas

| Id | Pregunta | Decisión (2026-11-11) | Afecta |
|---|---|---|---|
| D-1 | Color de una nota nueva | Siempre aguamarina (`NoteColor.aqua`) | T-05 |
| D-2 | Categoría de las notas de ejemplo | Sin categoría: `SampleNotes` no cambia | T-04 |

---

## Paso 0 — Preparación

- [ ] **T-00 · Rama de trabajo** — *yo*
  Crear `feat/002-note-editor` desde `feat/001-notes-grid`.
  **Hecho cuando:** `git branch --show-current` muestra la rama nueva y el árbol está limpio.

## Paso 1 — Domain (`feat(domain)`)

- [ ] **T-01 · Categoría en el modelo** — *yo* · RF-2, RF-14 a RF-19
  `enum NoteCategory: String, CaseIterable, Sendable { case work, personal }` y `Note.category: NoteCategory?` con `nil` por defecto en el `init`.
  **Hecho cuando:** el paquete compila sin tocar `SampleNotes` ni las pruebas existentes.
- [ ] **T-02 · Contrato del repositorio** — *yo* · RF-33
  `NoteRepository.delete(id:) async throws(AppError)` y `nextSequence() async throws(AppError) -> Int`, con su documentación, **y su implementación en `Data`** (`NoteLocalDataSource`, `NoteRepositoryImpl`, `UnavailableNoteRepository`), adelantada desde T-10 para que cada commit compile. Sus pruebas siguen en T-11.
  **Hecho cuando:** el paquete compila.
- [ ] **T-03 · Borrador y resultado** — *yo* · RF-32 a RF-37
  `NoteDraft` (`id`, `isNew`, `title`, `blocks`, `category`, `isPinned`) y `enum NoteSaveResult { saved(Note), deleted, skipped }`, ambos `Equatable` y `Sendable`.
  **Hecho cuando:** compilan y son `public`.
- [ ] **T-04 · Fakes de pruebas** — *test-writer* · depende de T-02
  Añadir `delete` y `nextSequence` a `FakeNoteRepository` en `DomainTests/Support` y `PresentationTests/Support`.
  **Hecho cuando:** las 78 pruebas unitarias existentes siguen en verde.
- [ ] **T-05 · `SaveNoteUseCase`** — *yo* · depende de T-03 · RF-12, RF-13, RF-23, RF-28, RF-32 a RF-37
  Reglas del plan: vacía tras quitar espacios; descartar bloques de texto vacíos; nueva sin guardar ⇒ `.skipped`; nueva guardada y vaciada ⇒ borra ⇒ `.deleted`; existente vaciada ⇒ `.skipped`; igual a `lastSaved` ⇒ `.skipped`; si no, guarda con `updatedAt = now`, conservando `color` y `sequence` o, la primera vez, con `NoteColor.aqua` (D-1) y `nextSequence()`.
  **Hecho cuando:** compila y cada rama devuelve el resultado esperado en T-06.
- [ ] **T-06 · Pruebas de Domain** — *test-writer* · depende de T-04 y T-05
  Cada rama de T-05, espacios y saltos de línea, tareas conservadas, `sequence` y color de la primera vez, errores del repositorio como `AppError`.
- [ ] **T-07 · Cierre del paso 1** — *test-runner* + *yo*
  **Hecho cuando:** `DomainTests` y `PresentationTests` en verde y commit `feat(domain): add note category and SaveNoteUseCase`.

## Paso 2 — Data (`feat(data)`)

- [ ] **T-08 · Esquema V2 y migración** — *yo* · RF-31
  `NotesSchemaV2` con `NoteEntity.categoryRawValue: String?`; `NotesMigrationPlan` con V1, V2 y `MigrationStage.lightweight`; `typealias NoteEntity = NotesSchemaV2.NoteEntity`; `DataAssembly` abre V2.
  **Hecho cuando:** la app compila y arranca sobre un almacén V1 existente sin perder notas (comprobado en T-11).
- [ ] **T-09 · Mappers** — *yo* · depende de T-08 · RF-14 a RF-19
  `toDomain`, `toEntity` y `update(from:)` con la categoría; valor desconocido ⇒ `.corruptedData`.
- [ ] **T-10 · Data source y repositorios** [P] — *yo* · depende de T-08 · RF-33
  `delete(id:)` y `nextSequence()` ya se implementaron en T-02. Aquí solo se revisan junto con el esquema V2.
- [ ] **T-11 · Pruebas de Data** — *test-writer* · depende de T-09 y T-10
  Mapper con y sin categoría y con valor desconocido; borrar; siguiente secuencia; la observación vuelve a emitir tras borrar; **migración V1 → V2** con archivo temporal que conserva las notas sin categoría.
- [ ] **T-12 · Cierre del paso 2** — *test-runner* + *yo*
  **Hecho cuando:** `DataTests` en verde y commit `feat(data): add note category schema v2 and delete`.

## Paso 3 — Editor en Presentation (`feat(presentation)`)

- [ ] **T-13 · Navegación compartida** — *yo*
  `public enum NotesDestination: Hashable { case newNote, note(Note) }` en `Presentation/Notes`.
- [ ] **T-14 · Estado, intents y efectos** — *yo* · RF-1 a RF-4, RF-8, RF-9
  `NoteEditorState` (con `saveStatus`, `isDiscardDialogPresented`, `headerDate`, `isTitleEmpty`, `isContentEmpty`), `NoteEditorIntent` y `NoteEditorEffect.close`. Estado inicial a partir de `NotesDestination`, con un bloque de texto vacío al final si hace falta.
- [ ] **T-15 · `NoteEditorViewModel`** — *yo* · depende de T-05 y T-14 · RF-14 a RF-28, RF-38 a RF-44
  Intents de edición; espera de 1 s con `any Clock<Duration>` reiniciada en cada cambio; `lastSaved` tras `.saved`; `.backTapped` guarda y emite `.close` o abre el diálogo; `discardConfirmed` emite `.close`; `keepEditingTapped` cierra el diálogo; `effects()` según `CLAUDE.md`; la cancelación no cambia el estado.
- [ ] **T-16 · Textos y recursos** [P] — *yo* · RF-8, RF-9, RF-14, RF-26, RF-38, RF-42
  `Localizable.xcstrings`: "Título", "Escribir nota…", "Categoría", "Trabajo", "Proyectos, reuniones y tareas", "Personal", "Recordatorios y vida diaria", "Todos los cambios guardados", mensaje de error, textos del diálogo, "Sin título" y etiquetas de accesibilidad. Color Sets de la etiqueta y del selector.
- [ ] **T-17 · Vistas del editor** — *yo* · depende de T-14 y T-16 · RF-5 a RF-13, RF-16 a RF-20, RF-26, RF-38, RF-42, RF-45 a RF-50
  `NoteEditorScreen` sin estado y subvistas (barra superior, cabecera, selector, título, bloques, indicador o error, barra inferior estática, diálogo). `NoteEditorAccessibilityID` con identificadores para todo lo que tocan las pruebas de UI.
- [ ] **T-18 · `NoteEditorRoute`** — *yo* · depende de T-15 y T-17 · RF-5, RF-25
  `public`; crea el ViewModel, `.navigationBarBackButtonHidden(true)`, consume efectos y hace `dismiss()`.
- [ ] **T-19 · Previews** [P] — *yo* · depende de T-17
  Nueva vacía, con texto, con tareas, fijada con categoría, error de guardado, diálogo, texto grande y modo oscuro.
- [ ] **T-20 · Pruebas del editor** — *test-writer* · depende de T-15
  Reloj manual en `PresentationTests/Support`; casos del plan (1 s exacto, ráfaga ⇒ un guardado, volver con pendientes, fallo ⇒ diálogo, descartar, seguir editando, `.deleted`, `.skipped`, re-suscripción a `effects()`, cancelación) y etiquetas de accesibilidad.
- [ ] **T-21 · Cierre del paso 3** — *test-runner* + *yo*
  **Hecho cuando:** `PresentationTests` en verde y commit `feat(presentation): add note editor`.

## Paso 4 — Lista en Presentation (`feat(presentation)`)

- [ ] **T-22 · Intents y efectos de la lista** — *yo* · RF-1, RF-4
  `NoteListIntent.newNoteTapped` y `.noteTapped(Note)`; `NoteListEffect.open(NotesDestination)` y `effects()`. Quitar el comentario de la excepción del plan 001.
- [ ] **T-23 · Botones y tarjeta sin título** — *yo* · depende de T-22 · RF-1, RF-4, RF-34
  "Nueva nota" y tarjetas como `Button`, conservando `NoteListAccessibilityID.newNoteButton`; identificador por tarjeta; "Sin título" en la tarjeta y en su etiqueta de VoiceOver.
- [ ] **T-24 · `NoteListRoute`** — *yo* · depende de T-22
  Parámetro `onOpen: (NotesDestination) -> Void` y consumo de efectos en `.task`.
- [ ] **T-25 · Pruebas de la lista** — *test-writer* · depende de T-22 y T-23
  Los dos intents emiten el efecto correcto, re-suscripción a `effects()` y tarjeta sin título.
- [ ] **T-26 · Cierre del paso 4** — *test-runner* + *yo*
  **Hecho cuando:** `PresentationTests` en verde y commit `feat(presentation): open editor from note list`.

## Paso 5 — App (`feat(app)`)

- [ ] **T-27 · Composition root y navegación** — *yo* · RF-1, RF-4, RF-5, RF-29, RF-30
  `AppContainer.saveNote`; `NotesAppApp` con `@State path: [NotesDestination]`, `.navigationDestination(for:)` y `ContinuousClock()`.
  **Hecho cuando:** la app compila y en el simulador "Nueva nota" y las tarjetas abren el editor.
- [ ] **T-28 · Cierre del paso 5** — *test-runner* + *yo*
  **Hecho cuando:** todas las pruebas (unitarias y las 9 de UI existentes) en verde y commit `feat(app): navigate to note editor`.

## Paso 6 — Pruebas de UI (`test(app)`)

- [ ] **T-29 · `NoteEditorUITests`** — *test-writer* · depende de T-27
  Los once flujos del paso 6 del plan, incluidos los de `-UITestingLoadFailure` y el relanzamiento.
- [ ] **T-30 · Cierre del paso 6** — *test-runner* + *yo*
  **Hecho cuando:** `NotesAppUITests` en verde y commit `test(app): cover note editor flows`.

## Paso 7 — Cierre

- [ ] **T-31 · Revisión de arquitectura** — *architecture-reviewer*
  **Hecho cuando:** responde "Sin violaciones de arquitectura" o se corrigen sus hallazgos.
- [ ] **T-32 · Demo manual** — *tú*
  iPhone en claro y oscuro, VoiceOver y texto grande, comparado con la captura del editor. iPad pendiente mientras no haya simulador.
- [ ] **T-33 · Memoria y PR** — *yo*
  Actualizar `MEMORY.md` y abrir el PR con `/create-pr` (hacia `feat/001-notes-grid` o `main`, según el estado de la 001).

## Cobertura de RF

Todos los RF-1 a RF-50 están asignados a al menos una tarea de implementación y a una de prueba; el detalle está en la tabla de trazabilidad del plan.
