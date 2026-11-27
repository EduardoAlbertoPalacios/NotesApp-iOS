import Common
import Foundation

/// Recupera una nota eliminada con "Deshacer" (spec 003, RF-16 a RF-19).
public struct RestoreNoteUseCase: Sendable {
    private let repository: any NoteRepository

    public init(repository: any NoteRepository) {
        self.repository = repository
    }

    /// Vuelve a guardar la copia de `DeleteNoteUseCase` tal cual, con su fecha y su orden.
    public func callAsFunction(_ note: Note) async throws(AppError) {
        try await repository.save([note])
    }
}
