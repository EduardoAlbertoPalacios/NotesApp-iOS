import Common
import Foundation

/// Guarda las notas de ejemplo la primera vez que se abre la app (spec 001, RF-25 a RF-27).
public struct SeedSampleNotesUseCase: Sendable {
    private let notes: any NoteRepository
    private let settings: any SettingsRepository
    private let dateProvider: any DateProvider

    public init(
        notes: any NoteRepository,
        settings: any SettingsRepository,
        dateProvider: any DateProvider
    ) {
        self.notes = notes
        self.settings = settings
        self.dateProvider = dateProvider
    }

    /// No hace nada si ya se sembró. Si guardar falla, no marca el indicador,
    /// para volver a intentarlo en la siguiente carga.
    public func callAsFunction() async throws(AppError) {
        guard !settings.hasSeededSampleNotes else { return }
        try await notes.save(SampleNotes.make(now: dateProvider.now()))
        settings.markSampleNotesSeeded()
    }
}
