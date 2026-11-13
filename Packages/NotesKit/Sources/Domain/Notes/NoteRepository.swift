import Common
import Foundation

public protocol NoteRepository: Sendable {
    /// Emite las notas guardadas (sin orden garantizado) y vuelve a emitir cuando cambian.
    /// Un fallo de lectura llega como `.failure` sin terminar el stream.
    /// Devuelve un stream nuevo en cada llamada.
    func observeNotes() -> AsyncStream<Result<[Note], AppError>>

    /// Guarda las notas (inserta o reemplaza por `id`) en una sola operación.
    func save(_ notes: [Note]) async throws(AppError)

    /// Borra la nota con ese `id`. No hace nada si no existe.
    func delete(id: UUID) async throws(AppError)

    /// `sequence` para una nota nueva: el mayor guardado más uno, o 0 si no hay notas.
    func nextSequence() async throws(AppError) -> Int
}
