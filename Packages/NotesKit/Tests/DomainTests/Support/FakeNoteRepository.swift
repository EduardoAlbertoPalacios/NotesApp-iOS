import Common
import Domain
import Foundation
import Synchronization

final class FakeNoteRepository: NoteRepository {
    private struct State {
        var notes: [Note]
        var readFailure: AppError?
        var saveFailure: AppError?
        var savedBatches: [[Note]] = []
        var continuations: [UUID: AsyncStream<Result<[Note], AppError>>.Continuation] = [:]

        var currentResult: Result<[Note], AppError> {
            if let readFailure { return .failure(readFailure) }
            return .success(notes)
        }
    }

    private let state: Mutex<State>

    /// `readFailure` hace que cada stream nuevo emita `.failure` en lugar de las notas.
    /// `saveFailure` hace que `save(_:)` lance ese error sin guardar nada.
    init(notes: [Note] = [], readFailure: AppError? = nil, saveFailure: AppError? = nil) {
        state = Mutex(State(notes: notes, readFailure: readFailure, saveFailure: saveFailure))
    }

    /// Cada llamada a `save(_:)` que terminó bien, en orden.
    var savedBatches: [[Note]] {
        state.withLock { $0.savedBatches }
    }

    func observeNotes() -> AsyncStream<Result<[Note], AppError>> {
        let (stream, continuation) = AsyncStream.makeStream(of: Result<[Note], AppError>.self)
        let id = UUID()
        state.withLock { state in
            continuation.yield(state.currentResult)
            state.continuations[id] = continuation
        }
        continuation.onTermination = { [weak self] _ in
            self?.state.withLock { $0.continuations[id] = nil }
        }
        return stream
    }

    func save(_ notes: [Note]) async throws(AppError) {
        try state.withLock { (state) throws(AppError) in
            if let failure = state.saveFailure { throw failure }
            for note in notes {
                state.notes.removeAll { $0.id == note.id }
                state.notes.append(note)
            }
            state.savedBatches.append(notes)
            let result = state.currentResult
            state.continuations.values.forEach { $0.yield(result) }
        }
    }

    /// Simula un fallo de lectura posterior: lo emite a los streams abiertos.
    func emitReadFailure(_ error: AppError) {
        state.withLock { state in
            state.continuations.values.forEach { $0.yield(.failure(error)) }
        }
    }
}

