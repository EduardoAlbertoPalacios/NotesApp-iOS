import Common
import Domain
import Foundation
import SwiftData

/// Punto único de ensamblado de `Data`, usado por `AppContainer`.
public enum DataAssembly {
    public static func makeModelContainer(inMemory: Bool = false) throws(AppError) -> ModelContainer {
        do {
            return try ModelContainer(
                for: Schema(versionedSchema: NotesSchemaV2.self),
                migrationPlan: NotesMigrationPlan.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory)
            )
        } catch {
            // Límite con SwiftData: el init lanza `any Error`; se traduce a AppError.
            throw .storageUnavailable
        }
    }

    public static func makeNoteRepository(container: ModelContainer) -> any NoteRepository {
        NoteRepositoryImpl(dataSource: NoteLocalDataSource(modelContainer: container))
    }

    /// Para cuando `makeModelContainer` falla, o para forzar el error de carga en pruebas de UI.
    public static func makeUnavailableNoteRepository() -> any NoteRepository {
        UnavailableNoteRepository()
    }

    public static func makeSettingsRepository(defaults: UserDefaults) -> any SettingsRepository {
        SettingsRepositoryImpl(defaults: defaults)
    }
}
