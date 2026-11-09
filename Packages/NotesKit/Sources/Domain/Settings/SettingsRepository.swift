import Foundation

/// Ajustes que afectan reglas de negocio.
public protocol SettingsRepository: Sendable {
    /// `true` cuando las notas de ejemplo ya se guardaron alguna vez.
    var hasSeededSampleNotes: Bool { get }

    func markSampleNotesSeeded()
}
