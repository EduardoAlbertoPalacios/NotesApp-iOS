import Common
import Domain
import Foundation
import SwiftData

final class NoteRepositoryImpl: NoteRepository {
    private let dataSource: NoteLocalDataSource

    init(dataSource: NoteLocalDataSource) {
        self.dataSource = dataSource
    }

    /// Emite el resultado actual y vuelve a consultar en cada `ModelContext.didSave`.
    func observeNotes() -> AsyncStream<Result<[Note], AppError>> {
        let dataSource = dataSource
        return AsyncStream { continuation in
            let task = Task {
                // Se suscribe antes de la primera lectura para no perder un guardado intermedio.
                let saves = NotificationCenter.default.notifications(named: ModelContext.didSave)
                continuation.yield(await Self.read(dataSource))
                for await _ in saves {
                    continuation.yield(await Self.read(dataSource))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func save(_ notes: [Note]) async throws(AppError) {
        try await dataSource.save(notes)
    }

    func delete(id: UUID) async throws(AppError) {
        try await dataSource.delete(id: id)
    }

    func nextSequence() async throws(AppError) -> Int {
        try await dataSource.nextSequence()
    }

    private static func read(_ dataSource: NoteLocalDataSource) async -> Result<[Note], AppError> {
        do {
            return .success(try await dataSource.fetchAll())
        } catch {
            return .failure(error)
        }
    }
}

/// Repositorio para cuando el almacenamiento no se puede abrir: toda lectura y escritura falla.
final class UnavailableNoteRepository: NoteRepository {
    func observeNotes() -> AsyncStream<Result<[Note], AppError>> {
        AsyncStream { continuation in
            continuation.yield(.failure(.storageUnavailable))
            continuation.finish()
        }
    }

    func save(_ notes: [Note]) async throws(AppError) {
        throw .storageUnavailable
    }

    func delete(id: UUID) async throws(AppError) {
        throw .storageUnavailable
    }

    func nextSequence() async throws(AppError) -> Int {
        throw .storageUnavailable
    }
}
