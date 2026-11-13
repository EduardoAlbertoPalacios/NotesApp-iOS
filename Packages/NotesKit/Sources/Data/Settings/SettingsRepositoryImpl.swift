import Domain
import Foundation

/// Única fuente de claves de `UserDefaults`.
enum SettingsKey: String {
    case hasSeededSampleNotes
}

final class SettingsRepositoryImpl: SettingsRepository {
    // `UserDefaults` no se marca `Sendable` en el SDK, pero Apple documenta que es seguro
    // usarlo desde varios hilos; por eso se excluye de la comprobación de aislamiento.
    nonisolated(unsafe) private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    var hasSeededSampleNotes: Bool {
        defaults.bool(forKey: SettingsKey.hasSeededSampleNotes.rawValue)
    }

    func markSampleNotesSeeded() {
        defaults.set(true, forKey: SettingsKey.hasSeededSampleNotes.rawValue)
    }
}
