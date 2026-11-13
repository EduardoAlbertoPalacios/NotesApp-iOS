# Plan 002 — Crear y editar notas

Implementa la [spec 002](spec.md) (aprobada el 2026-11-11). Sigue `CLAUDE.md` y `.claude/rules/`. Toca `Domain`, `Data`, `Presentation` y `NotesApp`.

## Decisiones técnicas

| Tema | Decisión | Por qué |
|---|---|---|
| Categoría | `enum NoteCategory { work, personal }` en `Domain` y `Note.category: NoteCategory?` (por defecto `nil`) | RF-2, RF-14 a RF-19: la nota puede no tener categoría |
| Esquema | `NotesSchemaV2` con `NoteEntity.categoryRawValue: String?` y un `MigrationStage.lightweight` de V1 a V2 | Regla de `CLAUDE.md`: cada cambio en un `@Model` lleva esquema nuevo y migración. Las notas existentes quedan sin categoría |
| Reglas de guardado | Un solo caso de uso, `SaveNoteUseCase(draft:lastSaved:) async throws(AppError) -> NoteSaveResult`, con resultado `.saved(Note)`, `.deleted` o `.skipped` | Concentra en `Domain` las reglas de RF-28 y RF-32 a RF-37; el ViewModel solo reacciona al resultado |
| Borrador | `NoteDraft` en `Domain`: `id`, `isNew`, `title`, `blocks`, `category`, `isPinned` | `isNew` distingue una nota creada desde "Nueva nota" (vacía ⇒ se elimina, RF-33) de una existente (vacía ⇒ no se guarda, RF-36 y RF-37) |
| Nota vacía | Título y contenido vacíos tras quitar espacios y saltos de línea. Los bloques de texto vacíos se descartan al guardar | Evita guardar una nota "con contenido" que solo tiene espacios |
| Sin cambios | `.skipped` si el borrador coincide con `lastSaved` en título, bloques, categoría y fijada | RF-28: abrir y salir sin cambiar nada no altera la fecha. Cubre también cambiar algo y volver a dejarlo como estaba |
| "Sin título" | Se guarda el título vacío; la tarjeta de "Mis notas" muestra "Sin título" (String Catalog), y el editor muestra el campo vacío con el texto de ayuda "Título" | Resuelve la duda abierta: el texto visible queda localizado y el usuario no tiene que borrar "Sin título" para escribir su título. **Interpreta RF-34** ("la guardará con el título 'Sin título'") como lo que el usuario ve, no como el valor almacenado |
| `sequence` de una nota nueva | `NoteRepository.nextSequence() async throws(AppError) -> Int` (máximo actual + 1), pedido por `SaveNoteUseCase` en el primer guardado | Mantiene el desempate por orden de creación del plan 001 sin depender de lo que tenga cargado la UI |
| Borrar | `NoteRepository.delete(id:) async throws(AppError)` | RF-33. Solo lo usa `SaveNoteUseCase`; borrar notas sigue fuera de alcance como acción del usuario |
| Guardado automático | El ViewModel reinicia una tarea de espera en cada cambio y guarda al terminar `clock.sleep(for: .seconds(1))`. `any Clock<Duration>` inyectado (`ContinuousClock` en producción) | RF-21 a RF-24. `CLAUDE.md`: el tiempo se inyecta para poder probarlo. Es una `Task` normal, no `Task.detached` |
| Volver | Intent `.backTapped`: cancela la espera, guarda lo pendiente y emite `.close`. Si el guardado falla, `state.isDiscardDialogPresented = true` | RF-25, RF-42 a RF-44. El diálogo es estado, no efecto, para que no se pierda |
| Botón de volver del sistema | `.navigationBarBackButtonHidden(true)` y botón propio, como en el diseño | Garantiza que toda salida pasa por `.backTapped`. Desactiva el gesto de deslizar para volver (ver Riesgos) |
| Navegación | `enum NotesDestination: Hashable { case newNote, note(Note) }` en `Presentation`. `NoteListViewModel` emite `NoteListEffect.open(NotesDestination)`; `NoteListRoute` lo entrega por un closure `onOpen` a `NotesAppApp`, que mantiene el `path` del `NavigationStack` y crea `NoteEditorRoute` | `Presentation` no conoce `AppContainer`; la raíz de la app une las pantallas. Llegan los primeros efectos de la lista, como anticipó el plan 001 |
| Nota que se edita | El destino lleva el `Note` completo desde la lista | La lista ya tiene la nota actualizada; no hace falta una lectura por `id` |
| Contenido editable | Cada bloque `.text` es un `TextField(axis: .vertical)`; cada bloque `.task` es una fila de solo lectura con su casilla. Si el último bloque no es de texto, el editor añade uno vacío al final para poder escribir | RF-7, RF-11 a RF-13: texto simple editable y tareas visibles sin cambios |
| Color de una nota nueva | Siempre `NoteColor.aqua`, decidido el 2026-11-11 | La spec no lo definía y `Note.color` es obligatorio para la tarjeta |
| Controles sin función | Vistas estáticas, no `Button` vacíos, como en el plan 001 | RF-45, RF-46 |
| Error al guardar | `state.saveStatus = .failed`: se muestra un mensaje en lugar de "Todos los cambios guardados". El siguiente cambio vuelve a intentar el guardado | RF-38 a RF-41 |
| Modo de pruebas de UI | Se reutiliza `-UITestingLoadFailure`: la lista muestra el error, "Nueva nota" sigue disponible y cualquier guardado falla | Permite probar el mensaje y el diálogo de descarte sin un modo nuevo |

### Propuestas para las dudas abiertas de la spec

| Duda | Propuesta |
|---|---|
| Indicador mientras se guarda | Sin texto mientras haya cambios pendientes; "Todos los cambios guardados" cuando se confirma el guardado. Una nota nueva sin guardar no muestra nada |
| Reintento tras un fallo | Automático con el siguiente cambio. Sin botón de reintentar; al volver aparece el diálogo de descarte |
| "Sin título" en el editor | Campo vacío con el texto de ayuda "Título" (ver la decisión de arriba) |
| Quitar la categoría | No se puede: tocar la categoría ya seleccionada no hace nada |
| Fecha de una nota nueva sin guardar | La del momento de abrir el editor ("Hoy, 9:41"), con el formato de la spec 001 |
| Editor en modo oscuro | Mismos colores de fondo y texto que "Mis notas" en oscuro (Color Sets del plan 001) |

## Pasos

Cada paso termina con el agente `test-writer` (pruebas), el agente `test-runner` (todo en verde) y un commit.

### Paso 1 — Domain (`feat(domain)`)
- `NoteCategory` y `Note.category` (con `nil` por defecto en el `init`, para no tocar `SampleNotes`).
- `NoteRepository`: `delete(id:)` y `nextSequence()`.
- `NoteDraft`, `NoteSaveResult` y `SaveNoteUseCase` (con `DateProvider` para `updatedAt`):
  - Vacía y nueva sin guardar ⇒ `.skipped`. Vacía y nueva ya guardada ⇒ borra ⇒ `.deleted`. Vacía y existente ⇒ `.skipped`.
  - Igual a `lastSaved` ⇒ `.skipped`.
  - En otro caso guarda con `updatedAt = now`, conservando `color` y `sequence` de `lastSaved`, o pidiendo `nextSequence()` y usando `NoteColor.aqua` si es la primera vez.
- Pruebas: cada rama anterior, quitar espacios, descartar bloques de texto vacíos, conservar tareas, errores del repositorio que llegan como `AppError`. Los fakes de `Support/` añaden `delete` y `nextSequence`.

### Paso 2 — Data (`feat(data)`)
- `NotesSchemaV2` (`NoteEntity` con `categoryRawValue: String?`), `NotesMigrationPlan` con V1, V2 y la etapa ligera. `typealias NoteEntity = NotesSchemaV2.NoteEntity`.
- Mappers: categoría de ida y vuelta; un valor desconocido ⇒ `.corruptedData`.
- `NoteLocalDataSource`: `delete(id:)` y `nextSequence()` (consulta ordenada por `sequence` descendente con `fetchLimit = 1`).
- `NoteRepositoryImpl` y `UnavailableNoteRepository`: los dos métodos nuevos.
- Pruebas: mapper con y sin categoría, borrar, siguiente secuencia (vacío ⇒ 0), observación que vuelve a emitir tras borrar, y **migración V1 → V2** con un archivo temporal (skill `write-tests`) que conserva las notas y les deja la categoría vacía.

### Paso 3 — Editor en Presentation (`feat(presentation)`)
Carpeta `Notes/Editor`:
- `NoteEditorState`: `title`, `blocks`, `category`, `isPinned`, `headerDate`, `saveStatus` (`.idle`, `.saved`, `.failed`), `isDiscardDialogPresented`. Derivados: `isTitleEmpty`, `isContentEmpty` (para los textos de ayuda, RF-8 y RF-9).
- `NoteEditorIntent`: `titleChanged`, `textBlockChanged(index:text:)`, `categoryTapped`, `pinTapped`, `backTapped`, `discardConfirmed`, `keepEditingTapped`.
- `NoteEditorEffect`: `.close`.
- `NoteEditorViewModel`: depende de `SaveNoteUseCase`, del `Clock` y del `DateProvider` (fecha de cabecera); guarda `lastSaved` tras cada `.saved`.
- `NoteEditorRoute` (`public`): crea el ViewModel desde un `NotesDestination`, oculta el botón de volver del sistema y hace `dismiss()` con `.close`.
- `NoteEditorScreen` y subvistas: barra superior, cabecera (etiqueta de categoría y fecha), selector de categoría, título, bloques, indicador o mensaje de error, barra inferior estática y diálogo de descarte.
- Recursos: textos nuevos en `Localizable.xcstrings` ("Título", "Escribir nota…", "Categoría", las dos categorías y sus descripciones, "Todos los cambios guardados", el mensaje de error, el diálogo y las etiquetas de accesibilidad); colores de la etiqueta y del selector como Color Sets; SF Symbols para los botones.
- Accesibilidad: el botón de fijar con valor "Fijada"/"Sin fijar" (RF-47), las categorías con el rasgo de seleccionado (RF-48), etiquetas de todos los botones (RF-49), Dynamic Type (RF-50).
- `#Preview`: nota nueva vacía, nota con texto, nota con tareas, fijada con categoría, error de guardado, diálogo de descarte, texto grande y modo oscuro.
- Pruebas del ViewModel con un reloj manual en `Support/`: guardado tras 1 s y no antes, varios cambios seguidos ⇒ un solo guardado, volver con cambios pendientes, volver tras un fallo ⇒ diálogo, descartar y seguir editando, `.deleted` y `.skipped`, re-suscripción a `effects()`, y que la cancelación no se muestre como error.

### Paso 4 — Lista en Presentation (`feat(presentation)`)
- `NoteListIntent`: `.newNoteTapped` y `.noteTapped(Note)`. `NoteListEffect.open(NotesDestination)` con `effects()` según `CLAUDE.md`.
- `NoteListScreen`: "Nueva nota" y las tarjetas pasan a ser `Button` (se conserva `NoteListAccessibilityID.newNoteButton`).
- `NoteCardView`: muestra "Sin título" cuando el título está vacío, también en la etiqueta de VoiceOver.
- `NoteListRoute`: recibe `onOpen: (NotesDestination) -> Void` y consume los efectos en `.task`.
- Pruebas: los dos intents emiten el efecto correcto y la tarjeta sin título.

### Paso 5 — App (`feat(app)`)
- `AppContainer`: crea `SaveNoteUseCase` con el mismo repositorio.
- `NotesAppApp`: `@State path: [NotesDestination]` y `.navigationDestination(for: NotesDestination.self)` con `NoteEditorRoute`.

### Paso 6 — Pruebas de UI (`test(app)`)
`NoteEditorUITests` en `NotesAppUITests`:
- Crear una nota con título y contenido, volver y verla primera de las no fijadas, con el contador actualizado.
- Crear una nota solo con contenido ⇒ "Sin título" en la cuadrícula.
- Abrir "Nueva nota" y volver sin escribir ⇒ la cuadrícula no cambia.
- Editar "Ideas sueltas", fijarla y elegir "Trabajo" ⇒ pasa al grupo de fijadas.
- Abrir una nota y volver sin cambios ⇒ misma posición.
- Abrir "La compra" ⇒ tareas visibles; tocar una casilla no la cambia.
- Vaciar una nota existente y volver ⇒ conserva su texto.
- Textos de ayuda "Título" y "Escribir nota…".
- Con `-UITestingLoadFailure`: escribir ⇒ mensaje de error; volver ⇒ diálogo; "Seguir editando" mantiene el texto; "Descartar" regresa.
- Persistencia al relanzar la app.
- Tocar los controles sin función no cambia nada.

### Paso 7 — Cierre
- `test-runner` con todo en verde y `architecture-reviewer` sin violaciones.
- Demo manual en iPhone (claro y oscuro, VoiceOver, texto grande) según los criterios de finalización.
- Actualizar `MEMORY.md` y abrir el PR con `/create-pr`.

## Trazabilidad RF → prueba

| RF | Dónde se prueba |
|---|---|
| RF-1 a RF-6 | Unitaria de los ViewModels (lista y editor) + UI |
| RF-7 a RF-10 | Preview + UI |
| RF-11 a RF-13 | Unitaria de `SaveNoteUseCase` (conserva tareas) + UI |
| RF-14 a RF-19 | Unitaria del ViewModel + mapper (`DataTests`) + UI |
| RF-20 a RF-22 | Unitaria del ViewModel + UI |
| RF-23, RF-24 | Unitaria del ViewModel con reloj manual |
| RF-25 | Unitaria del ViewModel + UI |
| RF-26 | Unitaria del ViewModel (`saveStatus`) + preview |
| RF-27, RF-28 | Unitaria de `SaveNoteUseCase` + UI |
| RF-29, RF-30 | Unitaria de `NoteOrdering` (ya existe) + UI |
| RF-31 | Unitaria de persistencia + migración (`DataTests`) + UI (relanzar) |
| RF-32 a RF-37 | Unitaria de `SaveNoteUseCase` + UI |
| RF-38 a RF-44 | Unitaria del ViewModel + UI con `-UITestingLoadFailure` |
| RF-45, RF-46 | UI |
| RF-47 a RF-50 | Unitaria de las etiquetas de accesibilidad + demo manual |

## Riesgos y pendientes
- **Gesto de volver:** ocultar el botón del sistema desactiva el deslizamiento desde el borde. Es la forma más simple de que toda salida guarde (RF-25) y pueda mostrar el diálogo (RF-42). Recuperar el gesto exigiría interceptarlo con UIKit; queda para otra iteración.
- **Borrado que falla:** si al volver con una nota nueva vaciada falla el borrado, se trata como un fallo de guardado y aparece el diálogo; "Descartar" deja la nota con su último texto guardado.
- **Diseño:** solo hay una captura del editor en modo claro y el MCP de Figma no tiene cupo. Colores, espaciados y tipografía se aproximan a partir de la captura y de la paleta del plan 001.
- **iPad:** sigue sin haber simulador disponible; la demo en iPad queda pendiente, como en la 001.
- **Rama:** la spec 001 aún no está en `main`. Propongo crear `feat/002-note-editor` a partir de `feat/001-notes-grid` y rebasarla cuando se fusione la 001.

## Decisiones tomadas tras aprobar el plan (2026-11-11)
1. **Color de una nota nueva:** siempre aguamarina (`NoteColor.aqua`).
2. **Categoría de las notas de ejemplo:** se quedan sin categoría; `SampleNotes` no cambia.
