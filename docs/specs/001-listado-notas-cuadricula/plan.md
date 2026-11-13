# Plan 001 — Listado de notas en cuadrícula

Implementa la [spec 001](spec.md) (aprobada el 2026-11-09). Sigue `CLAUDE.md` y `.claude/rules/`. Toca todos los módulos.

## Decisiones técnicas

| Tema | Decisión | Por qué |
|---|---|---|
| Contenido de la nota | `Note.blocks: [NoteBlock]`, con `NoteBlock` = `.text(String)` \| `.task(NoteTask)` | Cubre texto, viñetas y listas de tareas (RF-14, RF-16) en una sola estructura, que el editor futuro podrá mezclar |
| Color | `enum NoteColor` en `Domain` con los colores del diseño; el valor visual vive en `Presentation` | `Domain` no conoce `SwiftUI` |
| Orden | Regla pura `NoteOrdering` en `Domain`: fijadas primero, después `updatedAt` descendente y, a igual fecha, `sequence` ascendente (orden de creación) | RF-10 a RF-12. `sequence` resuelve el empate de las notas de ejemplo sin falsear su fecha (RF-26) |
| "Primera apertura" | Indicador `hasSeededSampleNotes` en `SettingsRepository` (`UserDefaults`), no "base vacía" | RF-27: si en el futuro el usuario borra todas sus notas, las de ejemplo no deben reaparecer |
| Contenido de ejemplo | `SampleNotes` en `Domain`, con textos en español escritos en el código | Son datos que se guardan una vez, no textos de interfaz. **Excepción explícita** a la regla de String Catalogs |
| Lectura observable | `NoteRepository.observeNotes() -> AsyncStream<Result<[Note], AppError>>` | `AsyncThrowingStream` no admite un tipo de error concreto. Así el fallo de carga (RF-35) llega tipado sin romper la regla de typed throws |
| Persistencia de bloques | `NoteEntity.blocksData: Data`, con `[NoteBlock]` codificado en JSON por el mapper | Evita guardar enums con valores asociados directamente en SwiftData, que es frágil |
| Fecha visible | `NoteDateFormatter` en `Presentation`, con `now`, `Calendar` y `Locale` inyectados | Lógica de presentación probable con reloj fijo (RF-20 a RF-24). `Date.FormatStyle` respeta el formato de 12/24 h del dispositivo (RF-21) |
| Cuadrícula | `Layout` propio `AlternatingColumnsLayout(columns:)`: el elemento *i* va a la columna *i mod n* y cada columna apila sin huecos | RF-8 y RF-9. `LazyVGrid` alinea por filas y deja huecos con alturas distintas |
| Número de columnas | Función pura `gridColumnCount(horizontalSizeClass:isLandscape:)`: compacto → 2; regular vertical → 3; regular horizontal → 4 | RF-4 a RF-7. Split View estrecho cae en tamaño compacto |
| Controles sin función | Se dibujan como vistas estáticas, no como `Button` vacíos | RF-31: no hacen nada y VoiceOver no los anuncia como botones que no funcionan |
| Efectos MVI | `NoteListEffect` y `effects()` no se crean en esta iteración | No hay navegación ni mensajes de un solo uso. **Excepción explícita** a la tabla MVI de `CLAUDE.md`; se agregan con la primera spec que navegue |
| Tipografía | Estilos de texto del sistema (`.largeTitle`, `.headline`, `.body`, `.caption`) con Dynamic Type | RF-43. Si el Figma usa otra fuente, se acepta la diferencia (ver Riesgos) |
| Modo de pruebas de UI | `-UITesting`: `ModelContainer` en memoria y `UserDefaults` de una suite propia y vacía, para que siempre se siembren las notas de ejemplo. `-UITestingLoadFailure`: el repositorio falla al cargar | Permite probar RF-25 y RF-35 a RF-39 de punta a punta |

## Pasos

Cada paso termina con el agente `test-writer` (pruebas), el agente `test-runner` (todo en verde) y un commit.

### Paso 0 — Infraestructura (`chore`)
1. Crear `Packages/NotesKit/Package.swift` (`swift-tools-version` 6.2, `platforms: [.iOS("27.0")]`) con los targets `Common`, `Domain`, `Data`, `Presentation` y `DomainTests`, `PresentationTests`, `DataTests`, con las dependencias declaradas según `CLAUDE.md`. `Presentation` lleva `resources: [.process("Resources")]`.
2. **Tú, en Xcode:**
   - Agregar el paquete local al proyecto (*File → Add Package Dependencies… → Add Local…*) y enlazar `Presentation`, `Data` y `Domain` al target `NotesApp`.
   - Crear el target `NotesAppUITests` (*File → New → Target… → UI Testing Bundle*).
   
   Prefiero no editar `project.pbxproj` a mano para esto.
3. Confirmar el nombre del esquema del paquete y la sintaxis de `-only-testing` para Swift Testing, y actualizar `CLAUDE.md` y `MEMORY.md`.
4. Crear un simulador de iPad para la demo final (`xcrun simctl create`).

### Paso 1 — Common y Domain (`feat(domain)`)
- `Common`: `AppError` (`.storageUnavailable`, `.corruptedData`) y el protocolo `DateProvider`.
- `Domain`:
  - Modelos: `Note` (`id`, `title`, `blocks`, `color`, `isPinned`, `updatedAt`, `sequence`), `NoteBlock`, `NoteTask` y `NoteColor`.
  - Protocolos: `NoteRepository` (`observeNotes()`, `save(_:) async throws(AppError)`) y `SettingsRepository` (`hasSeededSampleNotes`, `markSampleNotesSeeded()`).
  - Reglas puras: `NoteOrdering` y `SampleNotes.make(now:)`, que crea las seis notas del Figma con `sequence` 0…5.
  - Casos de uso:
    - `ObserveNotesUseCase`: devuelve las notas ya ordenadas.
    - `SeedSampleNotesUseCase`: si no se sembró, guarda las notas de ejemplo y marca el indicador; lanza `throws(AppError)`.
- Pruebas: orden (fijadas, fecha, empate por `sequence`), siembra única, siembra que falla y no marca el indicador, y contenido de las notas de ejemplo.

### Paso 2 — Data (`feat(data)`)
- `NotesSchemaV1` con `NoteEntity` (`@Attribute(.unique) id`, `title`, `blocksData`, `colorRawValue`, `isPinned`, `updatedAt`, `sequence`) y `NotesMigrationPlan` con V1 y sin etapas.
- `NoteLocalDataSource` (`@ModelActor`): `fetchAll()` e `insert(_:)`.
- `NoteRepositoryImpl`: emite el resultado actual y vuelve a consultar con `ModelContext.didSave`; traduce los errores a `AppError`.
- `SettingsRepositoryImpl` sobre `UserDefaults`, con las claves en `enum SettingsKey`.
- Mappers: `NoteEntity.toDomain()`, `Note.toEntity()` y codificación de `blocksData`.
- `DataAssembly`: `makeModelContainer(inMemory:)`, `makeNoteRepository(container:)` y `makeSettingsRepository(defaults:)`.
- Pruebas: mapper de ida y vuelta (texto y tareas), data source en memoria, repositorio que vuelve a emitir tras guardar, error de datos corruptos que llega como `AppError`, y ajustes con una suite de `UserDefaults` aislada.

### Paso 3 — Presentation (`feat(presentation)`)
Carpeta `Notes/List`:
- `NoteListState`: `isLoading`, `notes`, `loadError`. El contador se deriva de `notes.count`.
- `NoteListIntent`: `.retryTapped`.
- `NoteListViewModel`:
  - `start() async` siembra (si hace falta) y observa.
  - `handle(.retryTapped)` vuelve a ejecutar `start()`.
  - Un `CancellationError` no se muestra como error.
- `NoteListRoute` (`public`): crea el ViewModel y lanza `.task { await viewModel.start() }`.
- `NoteListScreen`, `NoteCardView`, `AlternatingColumnsLayout`, `gridColumnCount`, `NoteDateFormatter` y `NoteListAccessibilityID`.
- Recursos:
  - Colores de las tarjetas y del fondo como Color Sets con variante clara y oscura, sacados del Figma.
  - Iconos con SF Symbols: `gearshape`, `magnifyingglass`, `pin.fill`, `arrow.up.arrow.down`, `plus`, `checkmark.square`, `square`.
  - `Localizable.xcstrings`: el contador con variaciones de plural (RF-2 y RF-3), los textos de la pantalla, "Hoy, %@", "Ayer", el error, "Reintentar" y las etiquetas de accesibilidad ("Fijada", "Completada", "Pendiente").
- Accesibilidad:
  - Cada tarjeta es un contenedor con etiqueta de título, contenido y fecha, más "Fijada" si aplica (RF-40, RF-41).
  - Cada tarea es un elemento con valor "Completada" o "Pendiente" (RF-42).
- `#Preview` en estos estados: cargando, con notas, error, iPhone, iPad vertical, iPad horizontal y texto grande.
- Pruebas: ViewModel (carga, error, reintentar, cancelación), `NoteDateFormatter` (hoy en 12/24 h, ayer, este año, años anteriores, cambio de día a medianoche), `gridColumnCount` y la asignación de columnas de `AlternatingColumnsLayout`.

### Paso 4 — App (`feat(app)`)
- `AppContainer`: construye el `ModelContainer`, los repositorios y los casos de uso, y lee `-UITesting` y `-UITestingLoadFailure`.
- `NotesAppApp`: `WindowGroup` con `NoteListRoute` dentro de un `NavigationStack`.
- Borrar `ContentView.swift` de la plantilla.

### Paso 5 — Pruebas de UI (`test(app)`)
`NoteListUITests` en `NotesAppUITests`, con estos casos:
- Las seis notas de ejemplo en orden.
- El contador.
- La chincheta en "Reunión de equipo".
- Las tareas de "La compra".
- Tocar los controles, las tarjetas y las casillas no cambia nada.
- Las notas siguen al relanzar la app (RF-28).
- Error y reintentar.
- El número de columnas en el simulador de iPad.

### Paso 6 — Cierre
- `test-runner` con todo en verde y `architecture-reviewer` sin violaciones.
- Demo manual (criterios de finalización de la spec):
  - iPhone en modo claro y oscuro.
  - iPad en vertical y horizontal.
  - VoiceOver.
  - Texto grande.
- Actualizar `MEMORY.md` y abrir el PR con `/create-pr`.

## Trazabilidad RF → prueba

| RF | Dónde se prueba |
|---|---|
| RF-1, RF-29, RF-30 | UI |
| RF-2, RF-3 | Unitaria del texto del contador + UI |
| RF-4 a RF-7 | Unitaria de `gridColumnCount` + UI en iPad |
| RF-8, RF-9 | Unitaria de la asignación de columnas del layout + preview |
| RF-10 a RF-12 | Unitaria de `NoteOrdering` + UI (orden de las notas de ejemplo) |
| RF-13 a RF-18 | Preview + UI (textos visibles) |
| RF-19 | UI (desplazamiento) |
| RF-20 a RF-24 | Unitaria de `NoteDateFormatter` |
| RF-25 a RF-27 | Unitaria de `SeedSampleNotesUseCase` + UI |
| RF-28 | Unitaria de persistencia (`DataTests`) + UI (relanzar) |
| RF-31 a RF-33 | UI |
| RF-34 | Unitaria del ViewModel + preview |
| RF-35 a RF-39 | Unitaria del ViewModel + UI con `-UITestingLoadFailure` |
| RF-40 a RF-43 | Unitaria de las etiquetas de accesibilidad + demo manual |

## Riesgos y pendientes
- **Límite del MCP de Figma (plan Starter):**
  - Ya no hay llamadas disponibles para leer colores, espaciados y tipografía exactos.
  - Opciones: esperar a que se renueve el cupo, que tú copies los valores desde Figma (Inspect), o aproximarlos a partir de las capturas.
  - Afecta al paso 3.
- **Tipografía:** si el Figma usa una fuente que no es la del sistema, habría que añadirla al paquete. El plan propone la del sistema por Dynamic Type.
- **`ModelContext.didSave`:** la observación de cambios hechos en otro contexto se valida en las pruebas del paso 2. Si no basta, el repositorio emitirá también tras sus propias escrituras.
- **El paso 0 depende de ti en Xcode**, para enlazar el paquete y crear el target de pruebas de UI.
