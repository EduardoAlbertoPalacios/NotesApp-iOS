# Plan 004 — Buscar notas

Implementa la [spec 004](spec.md) (aprobada el 2026-11-27). Sigue `CLAUDE.md` y `.claude/rules/`. Toca `Domain` y `Presentation`. **No toca `Data` ni `NotesApp`**: la búsqueda filtra en memoria las notas que ya llegan por `ObserveNotesUseCase`, y `NoteListRoute` guarda el texto para restaurarlo sin pasar por la raíz.

## Decisiones técnicas

| Tema | Decisión | Por qué |
|---|---|---|
| Dónde se filtra | En memoria, sobre la lista que ya emite `ObserveNotesUseCase`. No hay consulta nueva al almacén | Las notas ya están cargadas y ordenadas. Con hasta 1 000 notas de texto corto, recorrerlas es del orden de milisegundos (RNF de rapidez). Una consulta con `#Predicate` no sabe ignorar tildes conservando la "ñ" (RF-9, RF-10) |
| Reglas de coincidencia | `NoteSearch` en `Domain`: `enum` sin casos con funciones `static` puras: `matches(_ note: Note, query: String) -> Bool` y `filter(_ notes: [Note], query: String) -> [Note]` | Son reglas puras y sin estado, como `NoteOrdering`. `CLAUDE.md` permite usarlas desde el ViewModel sin caso de uso. Quedan en `Domain` y se prueban sin UI |
| Normalización | Carácter a carácter: la "ñ"/"Ñ" pasa a "ñ"; el resto se pliega con `folding(options: [.caseInsensitive, .diacriticInsensitive], locale: es)`. Se aplica igual al texto buscado y al de la nota | RF-8 a RF-10. Plegar la cadena entera convertiría "ñ" en "n" |
| Palabras | El texto buscado se parte por espacios en blanco y se descartan las vacías. Una nota coincide si **cada** palabra aparece (como subcadena) en el texto de la nota | RF-11 a RF-13. Sin palabras (vacío o solo espacios) ⇒ no hay búsqueda (RF-4) |
| Texto de la nota | Título + texto de los bloques `.text` + texto de cada `.task` (completada o no), unidos con saltos de línea | RF-5 a RF-7. El salto de línea impide que una palabra "coincida" uniendo el final de un campo con el principio del siguiente. Categoría, color y fecha no entran |
| Orden | `filter` conserva el orden de entrada; la lista ya llega ordenada por `NoteOrdering` | RF-14 sin volver a ordenar |
| Estado | `NoteListState`: `notes` sigue siendo **todas** las notas (lo usa el contador y el estado vacío) y se añaden `searchText: String` y `results: [Note]`. Derivados: `isSearching` (hay palabras), `visibleNotes` (`results` si busca, `notes` si no), `isSearchEnabled` (cargado, sin error y con notas) y `hasNoResults` (busca, hay notas y `results` está vacío) | `results` se guarda en el estado y no se calcula en la vista: la vista se reevalúa cada minuto (`TimelineView`) y en cada cambio; filtrar ahí repetiría trabajo |
| Cuándo se filtra | El ViewModel recalcula `results` al cambiar el texto (`.searchTextChanged`) y cada vez que llegan notas nuevas del stream | RF-1, RF-3, RF-26 a RF-29: editar, crear, eliminar o "Deshacer" ya hacen que el stream vuelva a emitir |
| Última nota eliminada | Al llegar una lista vacía con búsqueda activa (y ya cargada), el ViewModel vacía `searchText` | RF-33. Con la lista vacía el buscador queda deshabilitado (RF-32) y no tendría sentido conservar un texto que no se puede borrar |
| Cargando o con error | El texto se acepta y se conserva en cualquier momento; el buscador solo se deshabilita en la vista. Al llegar las notas se filtra con el texto conservado | RF-35 a RF-38 |
| Intents | `.searchTextChanged(String)` y `.clearSearchTapped` | RF-1, RF-3, RF-21, RF-22. `.noteTapped` y `.newNoteTapped` no tocan la búsqueda (RF-25) |
| Buscador | `TextField` con `prompt` "Buscar en tus notas", `.submitLabel(.search)` y un `Binding` que lee `state.searchText` y envía `.searchTextChanged`. Botón propio de borrar (`xmark.circle.fill`) dentro de la cápsula, visible solo con texto. `.disabled(!state.isSearchEnabled)` | Mantiene la cápsula del Figma (RNF de apariencia). SwiftUI no tiene botón de borrar nativo en `TextField`. El texto vive en el estado del ViewModel, no en la vista |
| Teclado | La tecla "Buscar" cierra el teclado por defecto en un `TextField`. Desplazar: `.scrollDismissesKeyboard(.immediately)` en el `ScrollView` | RF-23, RF-24 sin estado de foco en la vista |
| Contador y resultados | Con búsqueda, la cabecera muestra `NoteListStrings.results(count)` ("1 resultado" / "%lld resultados", plural en `Localizable.xcstrings`; "0 resultados" sale de la variante `other`) en lugar de `counter` | RF-15 a RF-17 |
| Sin resultados | Vista centrada con "No hay notas que coincidan con «%@»", con el texto sin espacios exteriores, en lugar de la cuadrícula. Tiene prioridad sobre la cuadrícula pero no sobre carga, error ni estado vacío | RF-18, RF-19: si no hay notas, gana "Aún no tienes notas…" |
| Restaurar tras un cierre del sistema | `@SceneStorage("noteList.searchText")` en `NoteListRoute`. Al aparecer, si tiene texto, envía `.searchTextChanged(guardado)`; con cada cambio de `state.searchText` lo actualiza | RF-30, RF-31: iOS restaura `SceneStorage` cuando el sistema cerró la app en segundo plano y lo descarta cuando el usuario la cierra desde el selector de apps. Es exactamente la distinción que pide la spec, sin código propio de persistencia |
| Anuncio de VoiceOver | Cada cambio del texto reinicia una espera de 1 s con el `Clock` inyectado (el mismo que usa el aviso de "Deshacer"). Al terminar, si hay búsqueda, el ViewModel emite el efecto `.announce(NoteListAnnouncement)` con `.results(Int)` o `.noMatches(String)`; `NoteListRoute` lo traduce y lo publica con `AccessibilityNotification.Announcement` | RF-42 a RF-44. Es un evento de una sola vez: si la lista no está visible, perderlo es correcto. La espera se prueba con `ManualClock`. Publicar un anuncio sin VoiceOver no hace nada, así que no se condiciona a `isVoiceOverRunning` |
| Filtros | Sin cambios | RF-39 |
| Accesibilidad | El `TextField` usa "Buscar en tus notas" como etiqueta (VoiceOver lee también su valor). El botón de borrar lleva la etiqueta "Borrar búsqueda". Los textos nuevos usan estilos de Dynamic Type | RF-40, RF-41, RF-45 |

### Propuestas para lo que la spec deja abierto

| Tema | Propuesta |
|---|---|
| Aspecto del mensaje sin resultados | Igual que el estado vacío: texto centrado, `.body` en gris secundario, sin icono. Si el texto buscado es muy largo, se muestra completo en varias líneas |
| Texto buscado sin palabras con VoiceOver | No se anuncia nada: sin búsqueda no hay número de resultados que dar |
| Escribir con el aviso de "Deshacer" visible | El aviso no se oculta: la spec 003 solo lo oculta al tocar una tarjeta, "Nueva nota" o al pasar a segundo plano |

## Pasos

Cada paso termina con el agente `test-writer` (pruebas), el agente `test-runner` (todo en verde) y un commit.

### Paso 0 — Rama
- Ya creada: `feat/004-search-notes` desde `main` (con el PR #3 fusionado). La spec y el plan se commitean al aprobar las tareas (`docs: add spec 004 and plan`).

### Paso 1 — Domain (`feat(domain)`)
- `NoteSearch` (`public enum`) con `words(in:)`, `matches(_:query:)` y `filter(_:query:)`, más la normalización (`internal`).
- Pruebas: mayúsculas y "Ñ"/"ñ"; tildes y diéresis; "ano" ≠ "año"; parte de palabra; varias palabras en cualquier orden y repartidas entre título y contenido; texto de tareas completadas y pendientes; categoría y color no coinciden; espacios exteriores y repetidos; solo espacios ⇒ todas; signos, números y emojis; nota sin título o sin contenido; orden conservado; una palabra que solo existiría uniendo título y contenido no coincide.

### Paso 2 — Presentation (`feat(presentation)`)
- `NoteListState`: `searchText`, `results` y los derivados descritos arriba.
- `NoteListIntent`: `.searchTextChanged(String)`, `.clearSearchTapped`.
- `NoteListEffect.announce(NoteListAnnouncement)` y `NoteListAnnouncement` (`.results(Int)`, `.noMatches(String)`).
- `NoteListViewModel`: recalcula `results`, vacía la búsqueda si se queda sin notas y gestiona la espera de 1 s del anuncio.
- `NoteListScreen`: `TextField` con botón de borrar, cabecera con resultados, vista sin resultados, `visibleNotes` en la cuadrícula y `.scrollDismissesKeyboard`. Identificadores nuevos en `NoteListAccessibilityID`: `searchClearButton`, `noResults` (`searchField` pasa al `TextField`).
- `NoteListRoute`: `@SceneStorage` y publicación del anuncio.
- `NoteListStrings`: `results(_:)`, `noMatches(_:)`.
- Textos nuevos en `Localizable.xcstrings`: "%lld resultados" (plural), "No hay notas que coincidan con «%@»", "Borrar búsqueda".
- `#Preview`: buscando con resultados, sin resultados (claro y oscuro), buscador deshabilitado cargando con texto, y texto grande buscando.
- Pruebas del ViewModel con `ManualClock`: filtrar al escribir y al borrar caracteres; solo espacios; borrar con `.clearSearchTapped`; recalcular al llegar notas nuevas (edición, alta, borrado y "Deshacer"); conservar el texto al abrir una nota; vaciar la búsqueda al quedarse sin notas; texto recibido mientras carga o con error y aplicado al cargar; anuncio tras 1 s sin cambios y no antes; cambios seguidos reinician la espera; `.noMatches` sin resultados; sin anuncio con el texto vacío; re-suscripción a `effects()`. Pruebas del estado: `isSearching`, `visibleNotes`, `isSearchEnabled` y `hasNoResults`. Pruebas de `NoteListStrings.results`.

### Paso 3 — Pruebas de UI (`test(app)`)
`NoteSearchUITests` en `NotesAppUITests`, con las notas de ejemplo:
- Escribir "reunion" ⇒ solo "Reunión de equipo" y "1 resultado".
- Escribir en mayúsculas y con otras palabras en otro orden ⇒ mismos resultados.
- Buscar el texto de una tarea de "La compra" ⇒ aparece "La compra".
- Texto sin coincidencias ⇒ mensaje con el texto y "0 resultados"; no aparece el estado vacío.
- Botón de borrar ⇒ vuelven las seis notas y el contador habitual.
- Abrir un resultado y volver ⇒ el texto y los resultados siguen.
- Editar un resultado para que deje de coincidir ⇒ al volver ya no aparece.
- Eliminar un resultado y tocar "Deshacer" ⇒ vuelve a los resultados.
- Desplazar con el teclado abierto ⇒ el teclado se oculta y el texto sigue.
- Con `-UITestingLoadFailure` ⇒ buscador deshabilitado.

### Paso 4 — Cierre
- `test-runner` con todo en verde y `architecture-reviewer` sin violaciones.
- Demo manual en iPhone (claro y oscuro, VoiceOver, texto grande) según los criterios de finalización, incluido RF-30 y RF-31 (ver Riesgos).
- Actualizar `MEMORY.md` y abrir el PR con `/create-pr`.

## Trazabilidad RF → prueba

| RF | Dónde se prueba |
|---|---|
| RF-1 a RF-4 | Unitaria de `NoteSearch` y del ViewModel + UI |
| RF-5 a RF-13 | Unitaria de `NoteSearch` + UI (tildes, mayúsculas, tareas) |
| RF-14 | Unitaria de `NoteSearch` (orden conservado) |
| RF-15 a RF-17 | Unitaria de `NoteListStrings` y del estado + UI |
| RF-18, RF-19 | Unitaria del estado (`hasNoResults`) + preview + UI |
| RF-20 a RF-22 | Unitaria del ViewModel + UI |
| RF-23, RF-24 | UI (desplazar) + demo manual (tecla "Buscar") |
| RF-25 a RF-29 | Unitaria del ViewModel + UI |
| RF-30, RF-31 | Demo manual (ver Riesgos) |
| RF-32 a RF-38 | Unitaria del ViewModel y del estado (`isSearchEnabled`) + preview + UI con `-UITestingLoadFailure` |
| RF-39 | Preview + UI (los filtros no cambian) |
| RF-40 a RF-44 | Unitaria del ViewModel con `ManualClock` (anuncios) + demo manual con VoiceOver |
| RF-45 | Preview de texto grande + demo manual |

## Riesgos y pendientes
- **RF-30 y RF-31 sin prueba automática:** XCUITest no puede simular que el sistema cierre la app en segundo plano. Demo manual: buscar, pasar a segundo plano y detener la app desde Xcode (equivale a un cierre del sistema), volver a abrirla ⇒ el texto sigue. Luego cerrarla desde el selector de apps ⇒ se abre sin búsqueda.
- **`SceneStorage` en pruebas de UI:** si al relanzar la app en una prueba se restaurara un texto de la anterior, la siguiente prueba empezaría con búsqueda. Se comprueba en el paso 3; si pasa, el `-UITesting` no restaura el texto.
- **Rapidez con 1 000 notas:** no se mide (criterio de finalización). Filtrar en memoria y guardar `results` en el estado lo respaldan.
- **Pruebas de UI con teclado:** escribir con `typeText` y comprobar el teclado puede ser lento o inestable en paralelo. Se agrupan comprobaciones en un `app.snapshot()`, como en las pruebas de la spec 003.
- **iPad:** sigue sin haber simulador; la demo en iPad queda pendiente.
