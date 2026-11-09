---
name: write-tests
description: Escribe y ejecuta pruebas unitarias para un tipo existente de la app de notas iOS (caso de uso, ViewModel, repositorio, mapper o NoteLocalDataSource de SwiftData) con Swift Testing, siguiendo las convenciones del proyecto. Úsala cuando se pida agregar, completar o arreglar pruebas de un tipo o módulo.
---

# write-tests

Escribe las pruebas de un tipo existente, las ejecuta y las deja pasando.

> Las pruebas de UI (XCUITest en `NotesAppUITests`) y los `#Preview` por estado se crean con la skill `new-feature`; esta cubre pruebas unitarias y de persistencia.

## Antes de escribir

1. Lee `CLAUDE.md` y `MEMORY.md`. Si algo de esta skill contradice `CLAUDE.md`, manda `CLAUDE.md`.
2. Lee **completo** el tipo bajo prueba y sus dependencias directas.
3. Busca pruebas existentes del mismo target e imita su estilo.
4. Busca en `Support/` del target de pruebas los fakes y fixtures ya creados (`FakeNoteRepository`, `Note.fixture(...)`) antes de crear nuevos.
5. Lista los comportamientos a cubrir **antes** de escribir código (ver "Qué cubrir").

## Dónde va cada prueba

| Tipo bajo prueba | Target de pruebas | Herramientas |
|---|---|---|
| Caso de uso | `DomainTests` | Swift Testing, fake del repositorio |
| ViewModel | `PresentationTests` | Swift Testing, suite `@MainActor`, casos de uso reales + repositorio fake |
| Repositorio | `DataTests` | Swift Testing, `ModelContainer` en memoria |
| Mapper | `DataTests` | Swift Testing puro |
| `NoteLocalDataSource` (`@ModelActor`) | `DataTests` | `ModelContainer` en memoria vía `DataAssembly` |
| Migraciones (`NotesMigrationPlan`) | `DataTests` | Almacén en archivo temporal (ver plantilla) |

La prueba va en la carpeta de feature equivalente a la del tipo, con el nombre `XxxTests`. Usa `@testable import <Módulo>` para acceder a lo `internal`.

## Convenciones

- **Swift Testing** (`import Testing`, `@Test`, `#expect`, `#require`). XCTest solo en `NotesAppUITests`.
- **Nombres:** frase en el display name y función en camelCase: `@Test("given X when Y then Z") func xWhenY()`.
- **Estructura** Given / When / Then separada por líneas en blanco, sin comentarios que la anuncien.
- **Una razón para fallar** por prueba. Varias `#expect` están bien si verifican el mismo comportamiento.
- **Solo fakes escritos a mano.** No hay librerías de mocking; no agregues ninguna.
- **Concurrencia:** pruebas `async`. Nada de `Task.sleep`, `DispatchQueue`, `Task.detached` ni esperas por tiempo. Si el código depende del tiempo, inyecta un `Clock` o proveedor de fecha y usa uno fake.
- **Streams que no terminan:** léelos con un iterador (`var it = stream.makeAsyncIterator(); await it.next()`) o con `prefix(n)`. Nunca un `for await` sin límite ni `reduce` sobre ellos. Marca esas suites con `.timeLimit(.minutes(1))` para que un cuelgue falle en vez de bloquear.
- **Errores:** las APIs usan typed throws; comprueba el caso concreto: `#expect(throws: SaveNoteError.emptyTitle) { try await ... }`. Cubre también que una cancelación no se convierte en error de dominio (`.claude/rules/manejo-de-errores.md`).
- **Datos de prueba:** fixtures con valores por defecto en `Support/Fixtures.swift` (`Note.fixture(title: "Compras")`), no objetos repetidos en cada prueba.
- **Sujeto bajo prueba:** créalo con una función `makeXxx()` dentro de la suite. Swift Testing crea una instancia nueva de la suite por prueba, así que no hay estado compartido entre pruebas.

## Qué cubrir

| Tipo | Casos mínimos |
|---|---|
| **Caso de uso** | Camino feliz; cada regla de validación; error del repositorio |
| **ViewModel** | Estado inicial; cada `Intent` vía `await handle(_:)` (estado resultante y efectos); carga; error; `effects()` sigue funcionando tras volver a suscribirse |
| **Repositorio** | Mapeo entidad ↔ dominio en lectura y escritura; traducción de errores de SwiftData a `AppError`; nueva emisión del stream tras guardar |
| **Mapper** | Ida y vuelta (`Note` → entidad → `Note`); campos opcionales en `nil` |
| **`NoteLocalDataSource`** | Insertar, leer, actualizar, borrar; orden de las consultas |
| **Migración** | Datos creados con el esquema anterior siguen legibles con el nuevo |

No pruebes código generado por macros (`@Model`, `@Observable`), propiedades triviales ni el framework.

## Plantillas

### Fake de repositorio

Vive en `Support/` del target que lo usa. Usa `Mutex` (módulo `Synchronization`) para ser `Sendable` sin `@unchecked`.

```swift
import Synchronization
import Domain
import Common

final class FakeNoteRepository: NoteRepository {
    private struct State {
        var notes: [Note]
        var failure: AppError?
        var finishesStreams: Bool
        var continuations: [UUID: AsyncStream<[Note]>.Continuation] = [:]
    }

    private let state: Mutex<State>

    /// `finishesStreams: true` emite el valor actual y termina: útil para que
    /// `await viewModel.observeNotes()` regrese en pruebas de ViewModel.
    init(notes: [Note] = [], failure: AppError? = nil, finishesStreams: Bool = false) {
        state = Mutex(State(notes: notes, failure: failure, finishesStreams: finishesStreams))
    }

    func fail(with error: AppError?) {
        state.withLock { $0.failure = error }
    }

    func observeNotes() -> AsyncStream<[Note]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [Note].self)
        let id = UUID()
        state.withLock { state in
            continuation.yield(state.notes)
            if state.finishesStreams {
                continuation.finish()
            } else {
                state.continuations[id] = continuation
            }
        }
        continuation.onTermination = { [weak self] _ in
            self?.state.withLock { $0.continuations[id] = nil }
        }
        return stream
    }

    func save(_ note: Note) async throws(AppError) {
        try state.withLock { (state) throws(AppError) in
            if let failure = state.failure { throw failure }
            state.notes.removeAll { $0.id == note.id }
            state.notes.append(note)
            state.continuations.values.forEach { $0.yield(state.notes) }
        }
    }

    func delete(id: Note.ID) async throws(AppError) {
        try state.withLock { (state) throws(AppError) in
            if let failure = state.failure { throw failure }
            state.notes.removeAll { $0.id == id }
            state.continuations.values.forEach { $0.yield(state.notes) }
        }
    }
}
```

Ajusta los métodos al protocolo real de `NoteRepository`; no agregues métodos que el protocolo no tenga.

### Fixtures

```swift
extension Note {
    static func fixture(
        id: Note.ID = UUID(),
        title: String = "Título",
        body: String = "Contenido"
    ) -> Note {
        Note(id: id, title: title, body: body)   // usa el init real de Note
    }
}
```

### Caso de uso

```swift
import Testing
@testable import Domain

struct SaveNoteUseCaseTests {
    private func makeSut(repository: FakeNoteRepository = FakeNoteRepository()) -> SaveNoteUseCase {
        SaveNoteUseCase(repository: repository)
    }

    @Test("given blank title when saving then throws validation error")
    func blankTitleThrows() async {
        let saveNote = makeSut()

        await #expect(throws: SaveNoteError.emptyTitle) {
            try await saveNote(.fixture(title: "  "))
        }
    }

    @Test("given valid note when saving then repository contains it")
    func validNoteIsStored() async throws {
        let repository = FakeNoteRepository()
        let note = Note.fixture(title: "Compras")

        try await makeSut(repository: repository)(note)

        var notes = repository.observeNotes().makeAsyncIterator()
        #expect(await notes.next() == [note])
    }
}
```

### ViewModel

No hace falta un equivalente a `MainDispatcherRule`: marca la suite con `@MainActor` y llama a `handle(_:)` con `await`, que termina cuando termina el intent.

```swift
import Testing
@testable import Presentation
import Domain

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct NoteListViewModelTests {
    private func makeViewModel(repository: FakeNoteRepository = FakeNoteRepository()) -> NoteListViewModel {
        NoteListViewModel(
            getNotes: GetNotesUseCase(repository: repository),
            deleteNote: DeleteNoteUseCase(repository: repository)
        )
    }

    @Test("given notes in repository when observing then state shows them")
    func observeNotesUpdatesState() async {
        let note = Note.fixture()
        let viewModel = makeViewModel(repository: FakeNoteRepository(notes: [note], finishesStreams: true))

        await viewModel.observeNotes()

        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.notes == [note])
    }

    @Test("given note tapped when intent handled then emits navigate effect")
    func noteTappedEmitsNavigation() async {
        let viewModel = makeViewModel()
        let id = Note.ID()
        var effects = viewModel.effects().makeAsyncIterator()

        await viewModel.handle(.noteTapped(id))

        #expect(await effects.next() == .navigateToDetail(id))
    }

    @Test("given resubscribed effects when intent handled then new stream receives effect")
    func effectsSurviveResubscription() async {
        let viewModel = makeViewModel()
        _ = viewModel.effects()
        var effects = viewModel.effects().makeAsyncIterator()

        await viewModel.handle(.addTapped)

        #expect(await effects.next() == .navigateToDetail(nil))
    }
}
```

Usa casos de uso reales con repositorio fake cuando sean simples; así la prueba no se rompe al refactorizar el interior.

### Mapper

```swift
@Test("given note when mapped to entity and back then is unchanged")
func roundTrip() {
    let note = Note.fixture()

    #expect(note.toEntity().toDomain() == note)
}
```

Compara en el lado de dominio: las clases `@Model` no son `Equatable` por valor.

### NoteLocalDataSource (SwiftData en memoria)

```swift
import Testing
import SwiftData
@testable import Data

@Suite(.timeLimit(.minutes(1)))
struct NoteLocalDataSourceTests {
    private func makeSut() throws -> NoteLocalDataSource {
        let container = try DataAssembly.makeModelContainer(inMemory: true)
        return NoteLocalDataSource(modelContainer: container)
    }

    @Test("given inserted note when fetching all then returns it")
    func insertThenFetch() async throws {
        let dataSource = try makeSut()
        let note = Note.fixture()

        try await dataSource.upsert(note)

        #expect(try await dataSource.fetchAll() == [note])
    }
}
```

Las entidades `@Model` no son `Sendable`: no las saques del actor para hacer aserciones; compara los valores que devuelve el data source.

### Migración

Una migración no se puede probar en memoria: hace falta abrir el mismo almacén dos veces. Usa un archivo en el directorio temporal, único por prueba, y bórralo al final (esto solo aplica a pruebas).

```swift
@Test("given data saved with V1 when opened with V2 then note is readable")
func migratesV1ToV2() throws {
    let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).store")
    defer { try? FileManager.default.removeItem(at: url) }

    do {
        let v1 = try ModelContainer(
            for: Schema(versionedSchema: NotesSchemaV1.self),
            configurations: ModelConfiguration(url: url)
        )
        let context = ModelContext(v1)
        context.insert(NotesSchemaV1.NoteEntity(/* valores V1 */))
        try context.save()
    }

    let v2 = try ModelContainer(
        for: Schema(versionedSchema: NotesSchemaV2.self),
        migrationPlan: NotesMigrationPlan.self,
        configurations: ModelConfiguration(url: url)
    )
    let notes = try ModelContext(v2).fetch(FetchDescriptor<NotesSchemaV2.NoteEntity>())

    #expect(notes.count == 1)
}
```

## Ejecutar

Desde `Packages/NotesKit` (comandos de `CLAUDE.md`; el esquema `NotesKit-Package` está por confirmar en `MEMORY.md`):

```bash
xcodebuild -scheme NotesKit-Package -destination 'platform=iOS Simulator,name=iPhone Duo' \
  test -only-testing:DomainTests/SaveNoteUseCaseTests
xcodebuild -scheme NotesKit-Package -destination 'platform=iOS Simulator,name=iPhone Duo' \
  test -only-testing:PresentationTests/NoteListViewModelTests
xcodebuild -scheme NotesKit-Package -destination 'platform=iOS Simulator,name=iPhone Duo' \
  test -only-testing:DataTests
```

Ejecuta primero solo la suite nueva y al final todo el target de pruebas del módulo.

## Cuando una prueba falla

1. Lee el mensaje completo antes de cambiar nada.
2. Decide si el error está en la **prueba** o en el **código de producción**.
3. Si es un bug de producción, **no ajustes la prueba para que pase**: detente, explica el bug y pregunta si se corrige.
4. Nunca borres, desactives (`.disabled`), envuelvas en `withKnownIssue` ni debilites una aserción para poner la prueba en verde.

## Restricciones

- ❌ No cambies código de producción salvo lo mínimo para hacerlo testeable (por ejemplo, inyectar un `Clock`), y avísalo.
- ❌ No agregues paquetes de pruebas nuevos sin consultarlo.
- ❌ No uses esperas por tiempo real (`Task.sleep`, `DispatchQueue.asyncAfter`) en pruebas.
- ❌ No crees targets nuevos: los helpers van en `Support/` del target de pruebas existente.

## Al terminar

Resume: suites de prueba creadas, casos cubiertos, comando ejecutado y resultado, y lo que quedó sin cubrir o sin ejecutar. Actualiza `MEMORY.md` si descubriste algo que evitar. Propón el commit: `test(<módulo>): cover <Tipo>`.
