# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# 📝 App de Notas (iOS)

> Este archivo define la **arquitectura** y las **convenciones** que debes seguir al trabajar en este repositorio.

> **Estado actual:** el repo aún es la plantilla de Xcode (`NotesApp/NotesAppApp.swift` + `ContentView.swift`). El paquete `Packages/NotesKit`, el target `NotesAppUITests` y `docs/constitution.md` **todavía no existen**; lo descrito abajo es la arquitectura objetivo. Al crearlos, sigue exactamente esta estructura.

## Índice

1. [Stack](#stack)
2. [Módulos](#módulos)
3. [Arquitectura](#arquitectura)
4. [Pruebas](#pruebas)
5. [Comandos](#comandos)
6. [Memoria](#memoria)
7. [Convenciones](#convenciones)

---

## Stack

| Área | Tecnología |
|---|---|
| **Lenguaje** | Swift con `async`/`await`, actores y `AsyncStream` (ver modos de concurrencia abajo) |
| **UI** | SwiftUI + `NavigationStack` (Observation con `@Observable`) |
| **Inyección de dependencias** | Manual, mediante un *composition root* (`AppContainer`) en el target de la app |
| **Persistencia** | SwiftData (notas) y `@AppStorage` / `UserDefaults` (ajustes) |
| **Build** | Xcode 27 + Swift Package Manager con un paquete local (`Packages/NotesKit/Package.swift`) |
| **Versión mínima** | iOS 27.0 (`IPHONEOS_DEPLOYMENT_TARGET`), iPhone y iPad |

### Modos de concurrencia

| Dónde | Configuración | Consecuencia |
|---|---|---|
| Target de app `NotesApp` (`.xcodeproj`) | `SWIFT_VERSION = 5.0`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES` | Todo es `@MainActor` implícitamente; lo que deba salir del hilo principal se marca `nonisolated` / `@concurrent` |
| Targets de `NotesKit` | `swift-tools-version` 6.x ⇒ modo de lenguaje Swift 6 (concurrencia estricta), aislamiento por defecto `nonisolated` | Anota `@MainActor` explícitamente (ViewModels, vistas que lo requieran) |

> **Importante:** todas las dependencias externas y sus versiones se declaran únicamente en `Packages/NotesKit/Package.swift`. El proyecto de Xcode solo depende del paquete local; no agregues paquetes directamente al `.xcodeproj`.

> El target de la app usa *file-system synchronized groups*: cualquier archivo creado bajo `NotesApp/` se incluye solo. No edites `project.pbxproj` para agregar o quitar archivos.

---

## Módulos

Los módulos son *targets* del paquete local `NotesKit`, más el target de la app en Xcode.

| Módulo | Tipo | Contenido |
|---|---|---|
| `NotesApp` | Target de app (Xcode) | `@main App`, `AppContainer` (composition root), `ModelContainer`, navegación raíz, tema |
| `Presentation` | Target SPM | Vistas SwiftUI, ViewModels, estado de UI, componentes de diseño, rutas de navegación, `Localizable.xcstrings` (`resources: [.process(...)]`) |
| `Domain` | Target SPM (solo Foundation) | Modelos, protocolos de repositorio, casos de uso |
| `Data` | Target SPM | Modelos `@Model` de SwiftData, esquemas versionados y migraciones, fuentes locales, implementaciones de repositorio, mappers, ajustes en `UserDefaults` |
| `Common` | Target SPM (solo Foundation) | Utilidades compartidas: errores (`AppError`), extensiones, helpers de concurrencia |

### Regla de dependencias

```text
NotesApp ──> Presentation ──> Domain ──> Common
   ├───────> Data ──────────> Domain
   │          └─────────────> Common
   └───────> Domain
```

- Declara en `Package.swift` **cada** módulo que importas (por ejemplo `Data` y `Presentation` → `Common` si usan `AppError`); no dependas de imports transitivos.
- **`Domain`** solo importa `Foundation` (y `Common`). Nunca `SwiftUI`, `SwiftData` ni `UIKit`.
- **`Presentation`** y **`Data`** no se conocen entre sí. `NotesApp` los une en `AppContainer`.
- **`NotesApp`** usa de `Domain` solo los modelos que necesita la raíz de la app (`ThemeMode`), nunca repositorios directamente fuera de `AppContainer`.
- **`Common`** no depende de ningún otro módulo.
- **Nunca** expongas clases `@Model` de SwiftData fuera de `Data`; se mapean a modelos de dominio.
- **No uses `@Query`** en las vistas: rompe la separación de capas. Los datos llegan por caso de uso → ViewModel.

---

## Arquitectura

**Clean Architecture** con **MVI** en la capa de presentación.

### Presentation (MVI)

Cada pantalla vive en su propia carpeta por feature (`Notes/List`, `Notes/Detail`, ...) con:

| Tipo | Responsabilidad |
|---|---|
| `XxxState` | `struct` inmutable desde fuera (`Equatable`, `Sendable`), única fuente de verdad de la pantalla |
| `XxxIntent` | `enum` con las acciones del usuario |
| `XxxEffect` | `enum` para eventos de una sola vez (navegar, mostrar alerta/toast) |
| `XxxViewModel` | `@MainActor @Observable final class`; expone `private(set) var state: XxxState` y `func effects() -> AsyncStream<XxxEffect>`; recibe intents con `send(_ intent:)` |
| `XxxRoute` | Vista que crea/posee el ViewModel (`@State`), lo conecta con `XxxScreen` y consume efectos en `.task { for await effect in viewModel.effects() { ... } }` |
| `XxxScreen` | Vista **sin estado** que recibe `state` y `onIntent: (XxxIntent) -> Void`. Es la que se previsualiza (`#Preview`) y se prueba |

Ejemplo de forma:

```swift
@MainActor @Observable
final class NoteListViewModel {
    private(set) var state = NoteListState()
    @ObservationIgnored private var effectContinuation: AsyncStream<NoteListEffect>.Continuation?

    private let getNotes: GetNotesUseCase
    private let deleteNote: DeleteNoteUseCase

    init(getNotes: GetNotesUseCase, deleteNote: DeleteNoteUseCase) {
        self.getNotes = getNotes
        self.deleteNote = deleteNote
    }

    /// Crea un stream nuevo por suscripción. Un `AsyncStream` se cierra para siempre
    /// cuando se cancela la tarea que lo consume (p. ej. el `.task` de la vista al hacer
    /// push de otra pantalla), así que nunca reutilices uno creado en el `init`.
    func effects() -> AsyncStream<NoteListEffect> {
        effectContinuation?.finish()
        let (stream, continuation) = AsyncStream.makeStream(of: NoteListEffect.self)
        effectContinuation = continuation
        return stream
    }

    func send(_ intent: NoteListIntent) { ... }

    private func emit(_ effect: NoteListEffect) {
        effectContinuation?.yield(effect)
    }
}
```

**Reglas:**

- Los efectos emitidos mientras la pantalla no está visible (sin suscriptor) se descartan. Si un resultado debe sobrevivir a eso, modélalo en `XxxState`, no como efecto.
- Los ViewModels solo dependen de **casos de uso**, nunca de repositorios ni de `ModelContext`.
  - **Excepción:** los tipos de reglas puras y sin estado de `Domain` (`NoteFormatting`, `NoteChecklist`, `NoteUndo`, como `enum` sin casos con funciones `static`) se usan directamente desde el ViewModel; todo lo que toque repositorios va por caso de uso.
- El estado se actualiza mutando la copia interna: `state.isLoading = true` o `state = state.with(...)`. Nunca desde la vista.
- Las tareas largas (observación de streams) se lanzan desde `.task` en `XxxRoute` para que se cancelen con el ciclo de vida de la vista; cada arranque pide un stream nuevo al caso de uso.
- Sin lógica de negocio en las vistas.
- Agrega `.accessibilityIdentifier(...)` a los elementos con los que interactúan las pruebas de UI.
- `@AppStorage` solo se usa en `NotesApp` y `Presentation` para ajustes puramente visuales (por ejemplo `ThemeMode` en la raíz). Los ajustes que afectan reglas de negocio pasan por `SettingsRepository`. Las claves viven en un único `enum SettingsKey` para no duplicar strings.

### Domain

- **Modelos:** `struct` de Swift puro, `Equatable`, `Hashable`, `Sendable` e `Identifiable` cuando aplique (por ejemplo `Note`).
- **Repositorios:** solo protocolos (`NoteRepository: Sendable`).
- **Casos de uso:** un `struct` por acción, con `func callAsFunction(...)`, nombrados `VerboSustantivoUseCase` (`GetNotesUseCase`, `SaveNoteUseCase`, `DeleteNoteUseCase`).
- Las lecturas observables devuelven `AsyncStream<T>` (o `AsyncThrowingStream<T, Error>`), **uno nuevo en cada llamada**; las escrituras son `async throws(<ErrorConcreto>)` (typed throws, ver `.claude/rules/manejo-de-errores.md`).
- Todo lo que otro módulo use debe ser `public` (incluido el `init`).

### Data

- `NoteEntity` (`@Model`) en la carpeta `Local`, declarado dentro de un `VersionedSchema` (`NotesSchemaV1`, `NotesSchemaV2`, ...).
- `NotesMigrationPlan: SchemaMigrationPlan` con un `MigrationStage` por cada cambio de versión.
- Acceso a SwiftData mediante `NoteLocalDataSource`, un `@ModelActor`: todo el trabajo con `ModelContext` ocurre ahí, fuera del hilo principal.
- La observación se implementa en el repositorio: emite el resultado actual y vuelve a consultar al recibir `ModelContext.didSave`, exponiéndolo como `AsyncStream`.
- `NoteRepositoryImpl` implementa el protocolo de dominio y es `internal`.
- **Mappers** como extensiones: `NoteEntity.toDomain()`, `Note.toEntity()` / `NoteEntity.update(from:)`.
- **Ensamblado:** `Data` expone un único punto `public enum DataAssembly` con factorías (`makeModelContainer(inMemory:)`, `makeNoteRepository(container:)`, `makeSettingsRepository(defaults:)`) que usa `AppContainer`.
- Cada cambio en un `@Model` requiere un nuevo `VersionedSchema` y su `MigrationStage`. Este proyecto usa **SwiftData, nunca Room** (Room es de Android); la skill `room-migration` está desactivada en `.claude/settings.json`.

> **Nota:** está prohibido borrar el almacén persistente o recrearlo para "resolver" errores de migración (ver `docs/constitution.md` cuando exista). `isStoredInMemoryOnly: true` solo se permite en pruebas y previews.

### Common

- **Concurrencia:** no uses `DispatchQueue` ni `Task.detached` en código de producción. El trabajo de persistencia va en el `@ModelActor`; la UI en `@MainActor`. Si un tipo necesita tiempo (debounce, fechas), inyecta un `Clock` o un proveedor de fecha para poder probarlo.
- **Tipo de error** compartido (`AppError`) para operaciones que pueden fallar; los repositorios traducen errores de SwiftData a `AppError`.
- `Common` es código de producción: **no** pongas aquí helpers de pruebas.

---

## Pruebas

> Todo caso de uso, ViewModel, repositorio y mapper nuevo lleva pruebas. Toda pantalla nueva lleva al menos una prueba de UI y previews con estados fijos.

### Unitarias (targets de prueba del paquete: `DomainTests`, `PresentationTests`, `DataTests`)

**Herramientas:** Swift Testing (`import Testing`, `@Test`, `#expect`, `#require`). Usa **fakes** escritos a mano (Swift no tiene mocking en tiempo de ejecución).

| Módulo | Qué se prueba |
|---|---|
| `Domain` | Casos de uso con repositorios fake |
| `Presentation` | ViewModels (`@MainActor`): estado resultante y efectos emitidos por cada intent, incluido re-suscribirse a `effects()` |
| `Data` | Mappers y repositorio con `ModelContainer` en memoria |

Nombres de prueba descriptivos en el display name:

```swift
@Test("given empty title when saving note then emits validation error")
func saveNoteWithEmptyTitle() async throws {
    // ...
}
```

Para streams, toma los primeros valores (`stream.prefix(2)` recolectado en un array) y comprueba con `#expect`. El helper de recolección y los fakes viven en una carpeta `Support/` dentro de cada target de pruebas (no en `Common` ni en un target nuevo).

### Integración y UI (`NotesAppUITests`)

| Tipo | Cómo |
|---|---|
| **Pantallas** | `#Preview` de cada `XxxScreen` con `XxxState` fijos (vacío, cargando, con datos, error) |
| **Flujos completos** | XCUITest; la app recibe el argumento de lanzamiento `-UITesting` y `AppContainer` usa un `ModelContainer` en memoria con datos semilla |
| **SwiftData** | Pruebas de `NoteLocalDataSource` con `ModelConfiguration(isStoredInMemoryOnly: true)`. Las migraciones necesitan abrir el mismo almacén dos veces (V*n* y luego V*n+1* con `NotesMigrationPlan`), así que usan un archivo único en el directorio temporal que la prueba borra al terminar (ver skill `write-tests`) |

---

## Comandos

Desde la raíz del repo. El único simulador instalado es `iPhone Duo` (`xcrun simctl list devices available` para ver otros).

```bash
# compilar la app
xcodebuild -project NotesApp.xcodeproj -scheme NotesApp \
  -destination 'platform=iOS Simulator,name=iPhone Duo' build

# pruebas unitarias del paquete (en simulador: los targets son iOS 27, `swift test` en macOS no sirve)
cd Packages/NotesKit && xcodebuild -scheme NotesKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone Duo' test

# pruebas de un módulo / de una sola prueba
xcodebuild -scheme NotesKit-Package -destination 'platform=iOS Simulator,name=iPhone Duo' \
  test -only-testing:DomainTests
xcodebuild -scheme NotesKit-Package -destination 'platform=iOS Simulator,name=iPhone Duo' \
  test -only-testing:DomainTests/SaveNoteUseCaseTests/saveNoteWithEmptyTitle

# pruebas de UI
xcodebuild -project NotesApp.xcodeproj -scheme NotesApp \
  -destination 'platform=iOS Simulator,name=iPhone Duo' test -only-testing:NotesAppUITests

# formato / lint (swift-format incluido en el toolchain)
swift format lint --recursive Packages NotesApp
```

> El nombre del esquema del paquete (`NotesKit-Package`) lo genera Xcode; confírmalo con `xcodebuild -list` dentro de `Packages/NotesKit` una vez creado.

> Antes de dar una tarea por terminada, ejecuta las pruebas unitarias de los módulos que tocaste.

---

## Memoria

`MEMORY.md` (en la raíz del repo) es el registro de estado del proyecto. Es distinto de la memoria automática de Claude Code en `~/.claude/projects/.../memory/`.

- Al empezar, lee `MEMORY.md` para conocer el estado del proyecto y las decisiones tomadas.
- Al terminar una tarea, actualízalo: estado actual, decisiones importantes (con su porqué) y errores a evitar.
- Mantenlo breve (máximo ~50 líneas): resume o elimina lo que ya no aporte.
- Si algo se convierte en una regla permanente, propón moverlo a `CLAUDE.md` en lugar de dejarlo en la memoria.
- No guardes nunca datos sensibles (claves, tokens, datos personales).

---

## Convenciones

### Código

- **Swift idiomático:** tipos por valor (`struct`, `enum`) siempre que se pueda, `enum` para estados cerrados, extensiones para mappers, `guard` para salidas tempranas.
- **Prohibido** `!` (force unwrap), `try!` y `as!` en código de producción.
- **Concurrencia:** tipos que cruzan límites de concurrencia son `Sendable`; nada de `@unchecked Sendable` sin justificarlo en un comentario.
- **Visibilidad** `internal` por defecto; `public` solo lo que otro módulo necesita; `private` para detalles de implementación.
- **Carpetas por feature** dentro de cada módulo, no por tipo de archivo.
- **Strings** visibles al usuario en String Catalogs (`Localizable.xcstrings`), usando `LocalizedStringKey` / `String(localized:bundle: .module)`; nunca literales sin localizar.

### Commits

Conventional Commits, con el módulo como scope cuando aplique:

```text
feat(data): add NoteLocalDataSource
fix(presentation): restore scroll position on note list
test(domain): cover SaveNoteUseCase validation
```

Tipos permitidos: `feat`, `fix`, `test`, `refactor`, `chore`, `docs`.

### Restricciones

- ❌ No agregues dependencias (paquetes SPM) nuevas sin consultarlo antes.
- ❌ No crees módulos ni targets nuevos más allá de los cinco listados arriba y sus targets de prueba (`DomainTests`, `PresentationTests`, `DataTests`, `NotesAppUITests`).
