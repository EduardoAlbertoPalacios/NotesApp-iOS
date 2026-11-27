# Plan 003 — Eliminar notas

Implementa la [spec 003](spec.md) (aprobada el 2026-11-26). Sigue `CLAUDE.md` y `.claude/rules/`. Toca `Domain`, `Presentation` y `NotesApp`. **No toca `Data`**: `NoteRepository` ya tiene `delete(id:)`, `save(_:)` y `nextSequence()` (plan 002), y la observación vuelve a emitir tras cada guardado o borrado.

## Decisiones técnicas

| Tema | Decisión | Por qué |
|---|---|---|
| Qué es eliminar | Borrado real en el almacén al elegir "Eliminar nota", no un borrado lógico. "Deshacer" vuelve a guardar una copia de la nota | RF-4, RF-23. Con borrado real, cerrar la app a la fuerza con el aviso visible deja la eliminación definitiva sin código extra (RF-22, requisitos no funcionales). Un borrado lógico exigiría cambiar el esquema y filtrar en todas las lecturas |
| Reglas de eliminación | `DeleteNoteUseCase(_ draft: NoteDraft, lastSaved: Note?) async throws(AppError) -> NoteDeletionResult`, con resultado `.deleted(Note)` (la copia para deshacer) o `.discarded` | Concentra en `Domain` RF-7 a RF-9 y RF-17 a RF-18, igual que `SaveNoteUseCase` concentra las reglas de guardado. El ViewModel solo reacciona al resultado |
| Copia para deshacer | Se construye con lo que hay en el editor (título y bloques limpiados como en `SaveNoteUseCase`), y con la fecha, el color y el `sequence` de `lastSaved` | RF-17, RF-18. Al conservar `updatedAt`, `isPinned` y `sequence`, `NoteOrdering` la devuelve a la misma posición (RF-19) sin guardar el índice |
| Nota nueva con texto nunca guardada | Copia con `NoteColor.aqua`, `updatedAt` = ahora y `sequence` = `nextSequence()`. No se borra nada del almacén | RF-7, RF-17. No había posición previa en la lista; aparece donde aparecería al guardarla |
| Nota nueva vacía | `.discarded`. Si ya llegó a guardarse, se borra antes | RF-9 y RF-32/RF-33 de la spec 002 |
| Nota existente vaciada en el editor | La copia usa la última versión guardada (`lastSaved`), no el estado vacío | La spec 002 (RF-36) nunca guarda una nota existente vacía; restaurarla vacía la contradiría |
| Deshacer | `RestoreNoteUseCase(_ note: Note) async throws(AppError)`, que guarda la copia con `repository.save([note])` | RF-16. Un caso de uso por acción, como pide `CLAUDE.md` |
| Paso de la copia del editor a la lista | `NoteEditorEffect.deleted(Note)`. `NoteEditorRoute` recibe `onDeleted: (Note) -> Void`, lo llama y hace `dismiss()`. `NotesAppApp` guarda la copia en `@State var lastDeletion: NoteDeletion?` (un `id` único y la nota) y se la pasa a `NoteListRoute(deletion:)`, que la convierte en el intent `.noteDeleted(NoteDeletion)` con `.onChange(of:initial:)`. El ViewModel ignora un `id` ya procesado | `Presentation` no navega entre features. La raíz ya une las pantallas (plan 002). El `id` evita que el mismo aviso salga dos veces si la vista se vuelve a evaluar. La lista ya está viva bajo el editor, así que no se pierde nada |
| Aviso | Estado, no efecto: `NoteListState.undoBanner: NoteListBanner?` con dos casos, `.deleted(Note)` ("Nota eliminada" + "Deshacer") y `.restoreFailed` ("No se pudo recuperar la nota") | `CLAUDE.md`: lo que debe sobrevivir y mostrarse se modela en el estado. Un solo aviso a la vez |
| Duración | El ViewModel arranca una espera con `clock.sleep(for: .seconds(5))` sobre un `any Clock<Duration>` inyectado y, al terminar, oculta el aviso | RF-12. El tiempo se inyecta para probarlo con `ManualClock` |
| VoiceOver | `NoteListRoute` lee `@Environment(\.accessibilityVoiceOverEnabled)` y envía `.voiceOverChanged(Bool)` al aparecer y en cada cambio. Con VoiceOver activo no hay espera; si se desactiva con el aviso visible, empiezan 5 s nuevos | RF-12, RF-13. La regla vive en el ViewModel y la vista solo informa del dato |
| Eliminación definitiva | Ocultar el aviso por cualquier motivo descarta la copia: al pasar 5 s, con `.noteTapped`, con `.newNoteTapped` y con `.movedToBackground` (la Route lo envía al cambiar `scenePhase` a `.background`) | RF-14, RF-20 a RF-23. No hay nada más que borrar: el almacén ya no tiene la nota |
| Mensaje de error al deshacer | Ocupa el sitio del aviso con las mismas reglas de duración (5 s, o sin límite con VoiceOver) | RF-30. La spec no fija su duración; se reutiliza la del aviso (ver Propuestas) |
| Menú ⋯ | `Menu` de SwiftUI con un `Button("Eliminar nota")` **sin** `role: .destructive`, en lugar del icono estático | RF-1 a RF-3. Sin rol destructivo el texto no sale en rojo. Cerrar el menú no envía ningún intent |
| Eliminar en el editor | Intent `.deleteTapped`: cancela la espera del guardado automático, aguarda un guardado en curso (como `.backTapped`) y llama a `DeleteNoteUseCase`. `.deleted(note)` ⇒ efecto `.deleted(note)`; `.discarded` ⇒ efecto `.close` | RF-4, RF-5, RF-8. Evita que un guardado automático pendiente vuelva a crear la nota tras borrarla |
| Fallo al eliminar | `state.isDeleteErrorPresented = true`: alerta "No se pudo eliminar la nota" con "Aceptar". No cambia título, bloques ni `lastSaved` | RF-27 a RF-29. Estado, no efecto, para que no se pierda |
| Estado vacío | `NoteListScreen` muestra el mensaje centrado cuando `!isLoading`, sin error y sin notas. El buscador, los filtros y "Nueva nota" se quedan como están | RF-24 a RF-26 |
| Accesibilidad | El aviso se anuncia con `AccessibilityNotification.Announcement("Nota eliminada")` al aparecer. El botón ⋯ conserva la etiqueta "Más opciones" | RF-32, RF-33 |
| Modo de pruebas de UI | Se reutiliza `-UITestingLoadFailure` para el fallo al eliminar. El fallo al deshacer solo se prueba en unitarias | Con el almacén siempre caído no se puede eliminar, así que nunca se llega a "Deshacer". Un modo nuevo solo para eso no compensa |

### Propuestas para lo que la spec deja abierto

| Tema | Propuesta |
|---|---|
| Texto del error al eliminar | "No se pudo eliminar la nota", en una alerta con "Aceptar" |
| Duración del mensaje de error al deshacer | La misma que el aviso: 5 s, o sin límite con VoiceOver activo |
| Aspecto del aviso | Cápsula en la parte inferior, por encima del botón "Nueva nota", con el fondo de la barra inferior del editor (Color Set del plan 002), texto a la izquierda y "Deshacer" en negrita a la derecha. Sigue el modo claro u oscuro |
| Aspecto del estado vacío | Dos líneas centradas: "Aún no tienes notas." con estilo de título y "Crea la primera." en gris secundario |

## Pasos

Cada paso termina con el agente `test-writer` (pruebas), el agente `test-runner` (todo en verde) y un commit.

### Paso 0 — Rama
- `git switch main && git pull` (el PR #1 con las specs 001 y 002 ya está fusionado en `origin/main`) y crear `feat/003-delete-note`. Las carpetas `docs/specs/003-eliminar-nota/` (aún sin seguimiento en git) pasan con el cambio de rama.

### Paso 1 — Domain (`feat(domain)`)
- `NoteDeletionResult` (`.deleted(Note)`, `.discarded`), `Equatable` y `Sendable`.
- `DeleteNoteUseCase` (con `DateProvider` para la copia de una nota nueva):
  - Borrador vacío y nuevo ⇒ borra si hay `lastSaved` ⇒ `.discarded`.
  - Borrador vacío y existente ⇒ borra ⇒ `.deleted(lastSaved)`.
  - Con contenido y `lastSaved` ⇒ borra ⇒ `.deleted` con el contenido del borrador y la fecha, el color y el `sequence` de `lastSaved`.
  - Con contenido y sin `lastSaved` ⇒ no borra nada ⇒ `.deleted` con `aqua`, ahora y `nextSequence()`.
- La limpieza de título y bloques se extrae de `SaveNoteUseCase` a una función `internal` compartida, sin cambiar su comportamiento.
- `RestoreNoteUseCase`.
- Pruebas: cada rama anterior, que la copia conserva categoría, fijada, tareas y color, espacios y bloques vacíos, y errores del repositorio que llegan como `AppError`. Las pruebas de `SaveNoteUseCase` deben seguir en verde.

### Paso 2 — Editor en Presentation (`feat(presentation)`)
- `NoteEditorIntent`: `.deleteTapped` y `.deleteErrorDismissed`. `NoteEditorEffect.deleted(Note)`. `NoteEditorState.isDeleteErrorPresented`.
- `NoteEditorViewModel`: recibe `DeleteNoteUseCase` y aplica la lógica de eliminar descrita arriba. Ignora `.deleteTapped` mientras vuelve o elimina.
- `NoteEditorScreen`: `Menu` en el botón ⋯ con "Eliminar nota" y la alerta de error. Identificadores nuevos en `NoteEditorAccessibilityID` (`deleteMenuItem`).
- `NoteEditorRoute`: nuevos parámetros `deleteNote` y `onDeleted`.
- Textos nuevos en `Localizable.xcstrings`: "Eliminar nota", "No se pudo eliminar la nota", "Aceptar".
- `#Preview`: alerta de error al eliminar.
- Pruebas del ViewModel: eliminar una nota existente, una nueva con texto y una nueva vacía; con un guardado automático pendiente (no se guarda después); con un guardado en curso; un fallo (estado intacto y alerta); `.deleteErrorDismissed`; y que la cancelación no se muestre como error.

### Paso 3 — Lista en Presentation (`feat(presentation)`)
- `NoteDeletion` (`public`, `Equatable`, `Sendable`: `id` y `note`) en `Notes/`.
- `NoteListIntent`: `.noteDeleted(NoteDeletion)`, `.undoTapped`, `.voiceOverChanged(Bool)`, `.movedToBackground`. `.noteTapped` y `.newNoteTapped` también ocultan el aviso.
- `NoteListState.banner` y el derivado `isEmpty` (no carga, sin error, sin notas).
- `NoteListViewModel`: recibe `RestoreNoteUseCase` y el `Clock`, y gestiona la espera de 5 s según VoiceOver.
- `NoteListScreen`: aviso en la parte inferior, estado vacío y anuncio de VoiceOver. Identificadores nuevos en `NoteListAccessibilityID` (`undoBanner`, `undoButton`, `emptyState`).
- `NoteListRoute`: parámetros `restoreNote` y `deletion`, y envío de VoiceOver y `scenePhase`.
- Textos nuevos: "Nota eliminada", "Deshacer", "No se pudo recuperar la nota", "Aún no tienes notas.", "Crea la primera.".
- `#Preview`: aviso de nota eliminada, error al deshacer, estado vacío y estado vacío con aviso.
- Pruebas del ViewModel con `ManualClock`: el aviso aparece; se oculta a los 5 s y no antes; "Deshacer" restaura y oculta; fallo al deshacer ⇒ mensaje de error; VoiceOver activo ⇒ no caduca; desactivar VoiceOver ⇒ 5 s nuevos; tocar una tarjeta, "Nueva nota" o pasar a segundo plano lo ocultan; una `NoteDeletion` repetida no muestra el aviso dos veces; re-suscripción a `effects()`.

### Paso 4 — App (`feat(app)`)
- `AppContainer`: `deleteNote` y `restoreNote` con el mismo repositorio.
- `NotesAppApp`: `@State lastDeletion: NoteDeletion?`, `onDeleted` en el editor y `deletion` en la lista.

### Paso 5 — Pruebas de UI (`test(app)`)
`NoteDeletionUITests` en `NotesAppUITests`:
- El menú ⋯ muestra "Eliminar nota". Cerrarlo sin elegir deja el editor igual.
- Eliminar una nota de ejemplo ⇒ vuelve a "Mis notas", la tarjeta desaparece y aparece "Nota eliminada".
- "Deshacer" ⇒ la tarjeta vuelve en su posición, con su categoría y fijada.
- Esperar a que el aviso desaparezca (unos 5 s) ⇒ la nota no vuelve.
- Abrir otra nota con el aviso visible ⇒ al volver, no hay aviso.
- Crear una nota con texto sin esperar el guardado y eliminarla ⇒ "Deshacer" la recupera con ese texto.
- "Nueva nota" vacía ⇒ eliminar ⇒ sin aviso.
- Eliminar todas las notas ⇒ estado vacío; "Deshacer" la última ⇒ vuelve la cuadrícula.
- Con `-UITestingLoadFailure`: crear una nota, escribir y eliminar ⇒ alerta de error y el editor conserva el texto.
- Relanzar la app tras una eliminación definitiva ⇒ la nota no está.

### Paso 6 — Cierre
- `test-runner` con todo en verde y `architecture-reviewer` sin violaciones.
- Demo manual en iPhone (claro y oscuro, VoiceOver, texto grande) según los criterios de finalización.
- Actualizar `MEMORY.md` y abrir el PR con `/create-pr`.

## Trazabilidad RF → prueba

| RF | Dónde se prueba |
|---|---|
| RF-1 a RF-3 | UI + preview |
| RF-4 a RF-6 | Unitaria del ViewModel del editor + UI |
| RF-7, RF-8 | Unitaria de `DeleteNoteUseCase` y del ViewModel del editor + UI |
| RF-9 | Unitaria de `DeleteNoteUseCase` + UI |
| RF-10, RF-11 | Unitaria del ViewModel de la lista + UI |
| RF-12 a RF-15 | Unitaria del ViewModel de la lista con `ManualClock` + UI (5 s reales) |
| RF-16 a RF-19 | Unitaria de `DeleteNoteUseCase`, `RestoreNoteUseCase` y del ViewModel de la lista + UI |
| RF-20 a RF-23 | Unitaria del ViewModel de la lista + UI |
| RF-24 a RF-26 | Unitaria del estado (`isEmpty`) + preview + UI |
| RF-27 a RF-29 | Unitaria del ViewModel del editor + UI con `-UITestingLoadFailure` |
| RF-30, RF-31 | Unitaria del ViewModel de la lista |
| RF-32 a RF-34 | Demo manual (VoiceOver y texto grande) + preview de texto grande |

## Riesgos y pendientes
- **Fallo al deshacer sin prueba de UI:** solo se cubre en unitarias (ver la decisión "Modo de pruebas de UI").
- **VoiceOver en XCUITest:** no se puede activar desde las pruebas de UI. RF-13 y RF-32 se cubren con pruebas unitarias y con la demo manual.
- **Prueba de UI con espera real de 5 s:** es más lenta. Se usa `waitForNonExistence(timeout:)` con margen, no `sleep`.
- **Posición de una nota nueva nunca guardada al deshacer:** aparece como la más reciente de su grupo, porque antes no estaba en la lista. Es coherente con la spec (RF-19 habla de la posición que ocupaba), pero conviene verlo en la demo.
- **Diseño:** solo hay referencia (Android) para el menú. El aviso y el estado vacío siguen las propuestas de arriba; se revisan en la demo.
- **iPad:** sigue sin haber simulador; la demo en iPad queda pendiente, como en las specs 001 y 002.
