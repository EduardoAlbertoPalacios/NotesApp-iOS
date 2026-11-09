import Common
import Data
import Domain
import Foundation

/// Composition root: el único lugar donde se crean repositorios y casos de uso.
struct AppContainer {
    let observeNotes: ObserveNotesUseCase
    let seedSampleNotes: SeedSampleNotesUseCase

    /// Argumentos de lanzamiento que usan las pruebas de UI.
    enum LaunchArgument {
        /// Almacén en memoria y ajustes vacíos: siempre se siembran las notas de ejemplo.
        static let uiTesting = "-UITesting"
        /// Fuerza el error de carga (spec 001, RF-35 a RF-39).
        static let uiTestingLoadFailure = "-UITestingLoadFailure"
    }

    private static let uiTestingDefaultsSuite = "eduardoAlberto.NotesApp.UITesting"

    static func make(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppContainer {
        let isUITesting = arguments.contains(LaunchArgument.uiTesting)

        let noteRepository: any NoteRepository
        if arguments.contains(LaunchArgument.uiTestingLoadFailure) {
            noteRepository = DataAssembly.makeUnavailableNoteRepository()
        } else {
            do {
                let container = try DataAssembly.makeModelContainer(inMemory: isUITesting)
                noteRepository = DataAssembly.makeNoteRepository(container: container)
            } catch {
                // Sin almacenamiento la pantalla muestra el error de carga y "Reintentar" (RF-35).
                noteRepository = DataAssembly.makeUnavailableNoteRepository()
            }
        }

        let settingsRepository = DataAssembly.makeSettingsRepository(defaults: defaults(isUITesting: isUITesting))

        return AppContainer(
            observeNotes: ObserveNotesUseCase(repository: noteRepository),
            seedSampleNotes: SeedSampleNotesUseCase(
                notes: noteRepository,
                settings: settingsRepository,
                dateProvider: SystemDateProvider()
            )
        )
    }

    private static func defaults(isUITesting: Bool) -> UserDefaults {
        guard isUITesting, let defaults = UserDefaults(suiteName: uiTestingDefaultsSuite) else {
            return .standard
        }
        defaults.removePersistentDomain(forName: uiTestingDefaultsSuite)
        return defaults
    }
}
