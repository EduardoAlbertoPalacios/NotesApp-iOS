import Domain
import Foundation
import Testing
@testable import Data

/// `final class` para borrar en `deinit` la suite de `UserDefaults` única de cada prueba.
final class SettingsRepositoryImplTests {
    private let suiteName = "SettingsRepositoryImplTests.\(UUID().uuidString)"

    deinit {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    private func makeSut() throws -> any SettingsRepository {
        DataAssembly.makeSettingsRepository(defaults: try #require(UserDefaults(suiteName: suiteName)))
    }

    @Test("given fresh defaults when reading seeded flag then is false")
    func defaultsToFalse() throws {
        let settings = try makeSut()

        #expect(settings.hasSeededSampleNotes == false)
    }

    @Test("given fresh defaults when marking sample notes seeded then flag is true")
    func markSetsTrue() throws {
        let settings = try makeSut()

        settings.markSampleNotesSeeded()

        #expect(settings.hasSeededSampleNotes)
    }

    @Test("given flag marked by one instance when a new instance uses the same suite then flag is true")
    func persistsAcrossInstances() throws {
        try makeSut().markSampleNotesSeeded()

        let settings = try makeSut()

        #expect(settings.hasSeededSampleNotes)
    }
}
