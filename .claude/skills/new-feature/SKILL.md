---
name: new-feature
description: Crea el andamiaje completo de una pantalla o feature nueva en la app de notas iOS (State, Intent, Effect, ViewModel, Route, Screen, caso de uso, navegación, previews y pruebas) siguiendo Clean Architecture + MVI con SwiftUI. Úsala cuando se pida crear una pantalla, feature o flujo nuevo.
---

# new-feature

Genera una feature nueva de punta a punta respetando la arquitectura definida en `CLAUDE.md`.

## Antes de escribir código

1. Lee `CLAUDE.md` y `MEMORY.md` en la raíz del repo. Si algo de esta skill contradice `CLAUDE.md`, manda `CLAUDE.md`.
2. Lee `Packages/NotesKit/Package.swift` para conocer los targets y sus dependencias reales. No inventes módulos ni dependencias. Si el paquete aún no existe, detente y avisa: crearlo es un paso aparte.
3. Revisa una feature existente en `Presentation` (si la hay) e imita su estilo, nombres y estructura de carpetas.
4. Define con el usuario, si no quedó claro en la petición:
    - **Nombre de la feature** en PascalCase (ej. `NoteList`, `NoteDetail`) y su carpeta (ej. `Notes/List`).
    - **Qué muestra** la pantalla y **qué acciones** tiene el usuario.
    - Si necesita **datos nuevos** (modelo, método de repositorio, cambio en un `@Model`) o reutiliza los existentes.

Si la feature requiere cambiar un `@Model` de SwiftData, detente y avisa: ese cambio requiere un nuevo `VersionedSchema` + `MigrationStage` y se hace aparte, no dentro de esta skill.

## Archivos a crear

Sustituye `Xxx` por el nombre de la feature y `Feature/Path` por su carpeta.

```text
Packages/NotesKit/
  Sources/Domain/<Feature>/VerboSustantivoUseCase.swift
  Sources/Presentation/Feature/Path/
    XxxState.swift
    XxxIntent.swift
    XxxEffect.swift
    XxxViewModel.swift
    XxxRoute.swift
    XxxScreen.swift          # incluye los #Preview
    XxxAccessibilityID.swift
  Sources/Presentation/Resources/Localizable.xcstrings   # agrega las claves nuevas
  Tests/DomainTests/<Feature>/VerboSustantivoUseCaseTests.swift
  Tests/PresentationTests/Feature/Path/XxxViewModelTests.swift
NotesApp/                       # solo registro: AppContainer + destino de navegación
NotesAppUITests/XxxUITests.swift
```

Solo toca `Data` si hace falta un método nuevo de repositorio o de `NoteLocalDataSource`.

## Pasos

### 1. Domain

- Si hace falta, agrega el método al protocolo del repositorio (`AsyncStream<T>` para lecturas observables, `async throws` para escrituras).
- Crea un caso de uso por acción, `public` con `init` `public`:

```swift
public struct GetNotesUseCase: Sendable {
    private let repository: any NoteRepository

    public init(repository: any NoteRepository) {
        self.repository = repository
    }

    public func callAsFunction() -> AsyncStream<[Note]> {
        repository.observeNotes()
    }
}
```

- Las validaciones de negocio (título vacío, etc.) viven en el caso de uso, no en el ViewModel, y se lanzan con typed throws (`async throws(SaveNoteError)`), según `.claude/rules/manejo-de-errores.md`.
- `Domain` solo importa `Foundation` y `Common`.

### 2. Data (solo si aplica)

- Agrega la consulta en `NoteLocalDataSource` (`@ModelActor`) y la implementación en `NoteRepositoryImpl` (`internal`).
- Mapea con `toDomain()` / `update(from:)`. Ningún `@Model` sale de `Data`.
- Traduce los errores de SwiftData a `AppError`.

### 3. Presentation: contrato MVI

```swift
// XxxState.swift
struct NoteListState: Equatable, Sendable {
    var isLoading = true
    var notes: [Note] = []
    var error: NoteListError?
}

// XxxIntent.swift
enum NoteListIntent: Equatable, Sendable {
    case noteTapped(Note.ID)
    case deleteTapped(Note.ID)
    case addTapped
}

// XxxEffect.swift
enum NoteListEffect: Equatable, Sendable {
    case navigateToDetail(Note.ID?)
    case showMessage(NoteListMessage)
}

enum NoteListMessage: Equatable, Sendable {
    case noteNotFound
    case deleteFailed
}
```

- `State` siempre con valores por defecto, para construirlo fácil en previews y pruebas.
- Los intents se nombran por lo que **hizo el usuario** (`addTapped`), no por lo que debe pasar (`navigateToAdd`).
- Los mensajes son `enum`s, no strings: la vista los traduce a texto localizado. Así los efectos siguen siendo `Equatable` y comprobables.

### 4. Presentation: ViewModel

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

    /// Un stream nuevo por suscripción: un AsyncStream se cierra para siempre
    /// cuando se cancela el `.task` que lo consume.
    func effects() -> AsyncStream<NoteListEffect> {
        effectContinuation?.finish()
        let (stream, continuation) = AsyncStream.makeStream(of: NoteListEffect.self)
        effectContinuation = continuation
        return stream
    }

    /// Punto de entrada de la vista.
    func send(_ intent: NoteListIntent) {
        Task { await handle(intent) }
    }

    /// Lógica real; las pruebas la llaman con `await` para ser deterministas.
    func handle(_ intent: NoteListIntent) async {
        switch intent {
        case .noteTapped(let id):
            emit(.navigateToDetail(id))
        case .deleteTapped(let id):
            await delete(id)
        case .addTapped:
            emit(.navigateToDetail(nil))
        }
    }

    /// Se lanza desde `.task` en la Route; se cancela con la vista.
    func observeNotes() async {
        for await notes in getNotes() {
            state.isLoading = false
            state.notes = notes
        }
    }

    private func delete(_ id: Note.ID) async {
        do {
            try await deleteNote(id: id)   // throws(DeleteNoteError)
        } catch .notFound {
            emit(.showMessage(.noteNotFound))
        } catch .storage {
            emit(.showMessage(.deleteFailed))
        }
    }

    private func emit(_ effect: NoteListEffect) {
        effectContinuation?.yield(effect)
    }
}
```

- Solo depende de casos de uso (y de las reglas puras de `Domain` permitidas en `CLAUDE.md`).
- El `switch` de `handle` debe ser exhaustivo, sin `default`.
- Los argumentos de navegación (ej. el `id` de la nota) llegan por el `init` del ViewModel, desde la Route.
- Nada de `DispatchQueue` ni `Task.detached`.

### 5. Presentation: Route y Screen

La Route es lo único `public` de la feature: `NotesApp` la construye con los casos de uso y las lambdas de navegación. El ViewModel queda `internal`.

```swift
public struct NoteListRoute: View {
    @State private var viewModel: NoteListViewModel
    @State private var message: NoteListMessage?
    private let onNavigateToDetail: (Note.ID?) -> Void

    public init(
        getNotes: GetNotesUseCase,
        deleteNote: DeleteNoteUseCase,
        onNavigateToDetail: @escaping (Note.ID?) -> Void
    ) {
        _viewModel = State(initialValue: NoteListViewModel(getNotes: getNotes, deleteNote: deleteNote))
        self.onNavigateToDetail = onNavigateToDetail
    }

    public var body: some View {
        NoteListScreen(state: viewModel.state, onIntent: { viewModel.send($0) })
            .task { await viewModel.observeNotes() }
            .task {
                for await effect in viewModel.effects() {
                    switch effect {
                    case .navigateToDetail(let id): onNavigateToDetail(id)
                    case .showMessage(let value): message = value
                    }
                }
            }
            .alert(item: $message) { ... }   // traduce NoteListMessage a String(localized:bundle: .module)
    }
}

struct NoteListScreen: View {
    let state: NoteListState
    let onIntent: (NoteListIntent) -> Void

    var body: some View {
        // List / ContentUnavailableView / ProgressView. Sin ViewModel, sin lógica de negocio.
    }
}
```

- `Screen` no conoce el ViewModel ni la navegación.
- Cubre los estados: cargando, vacío, con contenido y error.
- Agrega `.accessibilityIdentifier(...)` a los elementos interactivos, con constantes en `public enum XxxAccessibilityID`.
- Textos en `Localizable.xcstrings` del target `Presentation`, usando `bundle: .module`.
- Agrega un `#Preview` por estado relevante:

```swift
#Preview("Cargando") { NoteListScreen(state: NoteListState(), onIntent: { _ in }) }
#Preview("Vacío") { NoteListScreen(state: NoteListState(isLoading: false), onIntent: { _ in }) }
#Preview("Con notas") { NoteListScreen(state: NoteListState(isLoading: false, notes: .preview), onIntent: { _ in }) }
```

### 6. Navegación y ensamblado

- Agrega el destino a la ruta de navegación de `Presentation` (ej. `case noteDetail(id: Note.ID?)` en el `enum` `Hashable` de rutas).
- En `NotesApp`, registra el destino en el `.navigationDestination(for:)` del `NavigationStack` raíz y construye `XxxRoute` con los casos de uso que salen de `AppContainer`.
- La navegación se pasa como lambdas que modifican el `path` en la raíz; el `path` no entra a `Route` ni a `Screen`.

### 7. Pruebas

No las escribas tú: delega en el agente `test-writer` (ver `.claude/rules/forma-de-trabajar.md`), pasándole la lista de tipos creados o modificados. Los ejemplos de abajo son la referencia de lo que debe producir.

Swift Testing (`import Testing`) con fakes escritos a mano en `Support/` de cada target de pruebas.

**Caso de uso** (`DomainTests`):

```swift
@Test("given notes in repository when invoked then emits them")
func getNotesEmitsRepositoryNotes() async throws {
    let repository = FakeNoteRepository(notes: [.sample])
    let useCase = GetNotesUseCase(repository: repository)

    let first = await useCase().first(where: { _ in true })

    #expect(first == [.sample])
}
```

**ViewModel** (`PresentationTests`, `@MainActor`, `@testable import Presentation`):

```swift
@MainActor
struct NoteListViewModelTests {
    @Test("given note tapped when intent handled then emits navigate effect")
    func noteTappedEmitsNavigation() async throws {
        let viewModel = makeViewModel()
        var effects = viewModel.effects().makeAsyncIterator()

        await viewModel.handle(.noteTapped(Note.sample.id))

        #expect(await effects.next() == .navigateToDetail(Note.sample.id))
    }

    @Test("given finite notes stream when observing then updates state")
    func observeNotesUpdatesState() async {
        let viewModel = makeViewModel(notes: [.sample])   // el fake emite una vez y termina

        await viewModel.observeNotes()

        #expect(viewModel.state == NoteListState(isLoading: false, notes: [.sample]))
    }
}
```

Cubre: estado inicial, cada intent, el camino de error y que `effects()` siga funcionando tras volver a suscribirse.

**UI** (`NotesAppUITests`, XCUITest sobre la app con datos semilla):

```swift
@MainActor
final class NoteListUITests: XCTestCase {
    func testGivenSeededNotesWhenLaunchedThenShowsTitles() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Nota semilla"].waitForExistence(timeout: 5))
    }
}
```

Los estados aislados de `Screen` se cubren con los `#Preview`; XCUITest cubre el flujo real.

### 8. Verificación

Ejecuta y corrige hasta que pase (comandos de `CLAUDE.md`):

```bash
cd Packages/NotesKit
xcodebuild -scheme NotesKit-Package -destination 'platform=iOS Simulator,name=iPhone Duo' \
  test -only-testing:DomainTests -only-testing:PresentationTests
cd ../..
xcodebuild -project NotesApp.xcodeproj -scheme NotesApp \
  -destination 'platform=iOS Simulator,name=iPhone Duo' build
swift format lint --recursive Packages NotesApp
```

Agrega `-only-testing:DataTests` si tocaste `Data`. Corre `NotesAppUITests` si el target existe; si no, dilo en el resumen.

## Checklist final

- [ ] `Domain` sin imports de `SwiftUI`, `SwiftData` ni `UIKit`
- [ ] ViewModel `@MainActor @Observable`, depende solo de casos de uso
- [ ] `effects()` crea un stream por suscripción
- [ ] `Screen` sin estado, con `#Preview` por estado y `accessibilityIdentifier`
- [ ] Sin strings sin localizar en el código
- [ ] Sin `!`, `try!` ni `as!`
- [ ] Destino registrado en el `NavigationStack` raíz y Route construida desde `AppContainer`
- [ ] Pruebas de caso de uso, ViewModel y UI escritas y pasando
- [ ] Sin dependencias ni targets nuevos

## Al terminar

Resume en pocas líneas: archivos creados por módulo, pruebas ejecutadas y su resultado, y lo pendiente (por ejemplo, pruebas de UI sin ejecutar). Actualiza `MEMORY.md` si tomaste alguna decisión nueva. Propón el mensaje de commit: `feat(presentation): add <feature> screen`.
