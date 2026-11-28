# Tareas 004 — Buscar notas

Desglose del [plan 004](plan.md) (aprobado el 2026-11-27). Cada tarea es una unidad pequeña y verificable; se hacen en orden salvo las marcadas **[P]**, que pueden ir en paralelo con la anterior.

- **Responsable:** *yo* (agente principal), *test-writer* (pruebas, según `.claude/rules/forma-de-trabajar.md`), *test-runner*, *architecture-reviewer* o *tú*.
- **Hecho cuando:** criterio que se comprueba antes de marcarla. Si no se indica, basta con que el paquete compile.

## Decisiones tomadas

| Id | Pregunta | Decisión (2026-11-27) | Afecta |
|---|---|---|---|
| D-1 | Dónde se filtra | En memoria, sobre las notas que ya emite `ObserveNotesUseCase`, con reglas puras en `NoteSearch` (`Domain`) | T-01 a T-03, T-07 |
| D-2 | Cómo se compara | Letra a letra: la "ñ" se conserva y el resto se pliega sin mayúsculas ni tildes; cada palabra buscada debe aparecer en título + texto + tareas, unidos con saltos de línea | T-02 |
| D-3 | Restaurar tras un cierre del sistema | `@SceneStorage` en `NoteListRoute` | T-12 |
| D-4 | Anuncio de VoiceOver | Espera de 1 s con el `Clock` inyectado y efecto `.announce`; no se anuncia nada sin búsqueda | T-07, T-12 |
| D-5 | Mensaje sin resultados | Texto centrado con el estilo del estado vacío, sin icono, completo aunque sea largo | T-10 |
| D-6 | Aviso de "Deshacer" mientras se escribe | No se oculta: solo lo ocultan las acciones de la spec 003 | T-07 |

---

## Paso 0 — Preparación

- [x] **T-00 · Rama y documentos** — *yo*
  La rama `feat/004-search-notes` ya existe desde `main` (con el PR #3 fusionado). Commit `docs: add spec 004, plan and tasks` con `spec.md`, `plan.md` y `tasks.md`.
  **Hecho cuando:** `git status` está limpio y las pruebas unitarias y de UI existentes siguen en verde.

## Paso 1 — Domain (`feat(domain)`)

- [x] **T-01 · Palabras del texto buscado** — *yo* · RF-4, RF-13 · D-1
  `public enum NoteSearch` con `static func words(in query: String) -> [String]`: normaliza (T-02) y parte por espacios en blanco, sin palabras vacías. Sin palabras ⇒ no hay búsqueda.
- [x] **T-02 · Normalización y coincidencia** — *yo* · depende de T-01 · RF-5 a RF-12 · D-2
  Normalización `internal` carácter a carácter ("ñ"/"Ñ" ⇒ "ñ"; resto con `folding(options: [.caseInsensitive, .diacriticInsensitive], locale: es)`). Texto buscable de la nota: título + bloques `.text` + texto de cada `.task`, unidos con `\n`. `static func matches(_ note: Note, query: String) -> Bool`: todas las palabras como subcadena.
- [x] **T-03 · Filtrado** — *yo* · depende de T-02 · RF-1, RF-4, RF-14
  `static func filter(_ notes: [Note], query: String) -> [Note]`: sin palabras devuelve `notes` tal cual; si no, las que coinciden en el mismo orden.
- [x] **T-04 · Pruebas de Domain** — *test-writer* · depende de T-03
  Mayúsculas y "Ñ"/"ñ"; tildes y diéresis ("reunion"/"Reunión", "pinguino"/"pingüino"); "ano" ≠ "año" y "AÑO" = "año"; parte de palabra; varias palabras en cualquier orden y repartidas entre título y contenido; tareas completadas y pendientes; categoría y color no coinciden; espacios exteriores y repetidos; solo espacios ⇒ todas; signos, números y emojis; texto muy largo; nota sin título o sin contenido; orden conservado; una palabra que solo existiría uniendo dos campos no coincide.
- [x] **T-05 · Cierre del paso 1** — *test-runner* + *yo*
  **Hecho cuando:** `DomainTests` en verde y commit `feat(domain): add NoteSearch rules`.

## Paso 2 — Presentation (`feat(presentation)`)

- [x] **T-06 · Estado, intents y efectos** — *yo* · RF-1, RF-15, RF-18, RF-21, RF-32, RF-35, RF-36, RF-42
  `NoteListState`: `searchText: String`, `results: [Note]`; derivados `isSearching`, `visibleNotes`, `isSearchEnabled` (cargado, sin error y con notas) y `hasNoResults` (busca, hay notas y sin resultados). `NoteListIntent`: `.searchTextChanged(String)`, `.clearSearchTapped`. `NoteListEffect.announce(NoteListAnnouncement)` con `NoteListAnnouncement` (`.results(Int)`, `.noMatches(String)`).
- [x] **T-07 · Búsqueda en `NoteListViewModel`** — *yo* · depende de T-03 y T-06 · RF-1 a RF-4, RF-20 a RF-22, RF-25 a RF-29, RF-33, RF-37, RF-38, RF-42 a RF-44 · D-4, D-6
  `.searchTextChanged` guarda el texto (también cargando o con error) y recalcula `results` con `NoteSearch.filter`; `.clearSearchTapped` lo vacía. Cada lista nueva del stream recalcula `results`; si llega vacía con búsqueda activa, vacía `searchText`. Cada cambio del texto reinicia una espera de 1 s con el `Clock`; al terminar, si hay búsqueda, emite `.announce(.results(n))` o `.announce(.noMatches(texto sin espacios exteriores))`. `.noteTapped` y `.newNoteTapped` no tocan la búsqueda. Una cancelación no cambia el estado.
- [x] **T-08 · Textos** [P] — *yo* · RF-15, RF-16, RF-18, RF-41
  En `Localizable.xcstrings`, solo las claves nuevas: "%lld resultados" (plural: "%lld resultado" / "%lld resultados"), "No hay notas que coincidan con «%@»", "Borrar búsqueda". `NoteListStrings.results(_:)` y `.noMatches(_:)`.
- [x] **T-09 · Buscador en `NoteListScreen`** — *yo* · depende de T-06 y T-08 · RF-1, RF-20, RF-21, RF-23, RF-32, RF-35, RF-36, RF-40, RF-41, RF-45
  `TextField` con `prompt` "Buscar en tus notas" en la cápsula del Figma, `Binding` a `state.searchText` que envía `.searchTextChanged`, `.submitLabel(.search)` y `.disabled(!state.isSearchEnabled)`. Botón `xmark.circle.fill` visible solo con texto, etiqueta "Borrar búsqueda", envía `.clearSearchTapped`. `NoteListAccessibilityID.searchField` pasa al `TextField`; nuevo `searchClearButton`.
- [x] **T-10 · Cabecera, cuadrícula y sin resultados** — *yo* · depende de T-06 y T-08 · RF-15 a RF-19, RF-24, RF-39, RF-45 · D-5
  La cabecera muestra `results(count)` mientras busca y `counter` si no. La cuadrícula usa `visibleNotes`. Con `hasNoResults`, vista centrada con `noMatches` en lugar de la cuadrícula (carga, error y estado vacío tienen prioridad). `.scrollDismissesKeyboard(.immediately)` en el `ScrollView`. Filtros sin cambios. Nuevo `NoteListAccessibilityID.noResults`.
- [x] **T-11 · Previews** [P] — *yo* · depende de T-09 y T-10
  Buscando con resultados; sin resultados en claro y oscuro; cargando con texto en el buscador deshabilitado; error con buscador deshabilitado; buscando con texto grande.
- [x] **T-12 · `NoteListRoute`** — *yo* · depende de T-07 · RF-30, RF-31, RF-42, RF-43 · D-3, D-4
  `@SceneStorage("noteList.searchText")`: al aparecer, si tiene texto, envía `.searchTextChanged`; al cambiar `state.searchText`, lo actualiza. El efecto `.announce` se traduce con `NoteListStrings` y se publica con `AccessibilityNotification.Announcement`.
- [x] **T-13 · Pruebas de Presentation** — *test-writer* · depende de T-07, T-08 y T-12
  ViewModel con `ManualClock`: filtrar al escribir y al borrar caracteres; solo espacios ⇒ todas; `.clearSearchTapped`; recalcular al llegar notas nuevas (editada que deja de coincidir, alta que coincide o no, borrado, "Deshacer"); conservar el texto tras `.noteTapped`; vaciar la búsqueda al quedarse sin notas; texto recibido cargando o con error y aplicado al cargar; anuncio a 1 s y no antes; cambios seguidos reinician la espera; `.noMatches` sin resultados; sin anuncio con texto vacío; el aviso de "Deshacer" sigue al escribir; re-suscripción a `effects()`. Estado: `isSearching`, `visibleNotes`, `isSearchEnabled`, `hasNoResults`. `NoteListStrings.results` en singular y plural, y `noMatches`.
- [x] **T-14 · Cierre del paso 2** — *test-runner* + *yo*
  **Hecho cuando:** `PresentationTests` en verde, la app compila y commit `feat(presentation): search notes in note list`.

## Paso 3 — Pruebas de UI (`test(app)`)

- [x] **T-15 · `NoteSearchUITests`** — *test-writer* · depende de T-14
  Los diez flujos del paso 3 del plan: "reunion" ⇒ solo "Reunión de equipo" y "1 resultado"; mayúsculas y palabras en otro orden; tarea de "La compra"; sin coincidencias ⇒ mensaje y "0 resultados" sin estado vacío; borrar ⇒ seis notas y contador habitual; abrir un resultado y volver; editar para que deje de coincidir; eliminar un resultado y "Deshacer"; desplazar oculta el teclado; `-UITestingLoadFailure` ⇒ buscador deshabilitado. Comprobar que `@SceneStorage` no arrastra texto entre pruebas.
- [x] **T-16 · Cierre del paso 3** — *test-runner* + *yo*
  **Hecho cuando:** `NotesAppUITests` en verde y commit `test(app): cover note search flows`.

## Paso 4 — Cierre

- [ ] **T-17 · Revisión de arquitectura** — *architecture-reviewer*
  **Hecho cuando:** responde "Sin violaciones de arquitectura" o se corrigen sus hallazgos.
- [ ] **T-18 · Demo manual** — *tú*
  iPhone en claro y oscuro: los flujos de los criterios de finalización de la spec, la tecla "Buscar", VoiceOver (anuncio tras 1 s) y texto grande. RF-30: buscar, pasar a segundo plano, detener la app desde Xcode y volver a abrirla ⇒ el texto sigue. RF-31: cerrarla desde el selector de apps ⇒ sin búsqueda. iPad pendiente mientras no haya simulador.
- [ ] **T-19 · Memoria y PR** — *yo*
  Actualizar `MEMORY.md` y abrir el PR hacia `main` con `/create-pr`.

## Cobertura de RF

| RF | Implementación | Prueba |
|---|---|---|
| RF-1 a RF-4 | T-01, T-03, T-07, T-09 | T-04, T-13, T-15 |
| RF-5 a RF-13 | T-01, T-02 | T-04, T-15 |
| RF-14 | T-03 | T-04 |
| RF-15 a RF-17 | T-08, T-10 | T-13, T-15 |
| RF-18, RF-19 | T-06, T-10 | T-13, T-15 |
| RF-20 a RF-22 | T-07, T-09 | T-13, T-15 |
| RF-23, RF-24 | T-09, T-10 | T-15, T-18 |
| RF-25 a RF-29 | T-07 | T-13, T-15 |
| RF-30, RF-31 | T-12 | T-18 (demo manual) |
| RF-32 a RF-38 | T-06, T-07, T-09 | T-13, T-15 |
| RF-39 | T-10 | T-11, T-15 |
| RF-40 a RF-44 | T-07, T-09, T-12 | T-13, T-18 |
| RF-45 | T-09, T-10 | T-11, T-18 |
