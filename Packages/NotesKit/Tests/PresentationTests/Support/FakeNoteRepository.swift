import Common
import Domain
import Foundation
import Synchronization

final class FakeNoteRepository: NoteRepository {
    private struct State {
        var notes: [Note]
        var readFailure: AppError?
        var saveFailure: AppError?
        var scriptedReads: [Result<[Note], AppError>]?
        var finishesStreams: Bool
        var continuations: [UUID: AsyncStream<Result<[Note], AppError>>.Continuation] = [:]

        var currentResult: Result<[Note], AppError> {
            if let readFailure { return .failure(readFailure) }
            return .success(notes)
        }
    }

    private let state: Mutex<State>

    /// - `readFailure`: cada stream nuevo emite `.failure` en lugar de las notas.
    /// - `saveFailure`: `save(_:)` lanza ese error sin guardar nada.
    /// - `scriptedReads`: cada stream nuevo emite estos resultados en orden en lugar del actual.
    /// - `finishesStreams`: el stream termina tras emitir, para que `await viewModel.start()` regrese.
    init(
        notes: [Note] = [],
        readFailure: AppError? = nil,
        saveFailure: AppError? = nil,
        scriptedReads: [Result<[Note], AppError>]? = nil,
        finishesStreams: Bool = false
    ) {
        state = Mutex(State(
            notes: notes,
            readFailure: readFailure,
            saveFailure: saveFailure,
            scriptedReads: scriptedReads,
            finishesStreams: finishesStreams
        ))
    }

    func failReads(with error: AppError?) {
        state.withLock { $0.readFailure = error }
    }

    func failSaves(with error: AppError?) {
        state.withLock { $0.saveFailure = error }
    }

    func observeNotes() -> AsyncStream<Result<[Note], AppError>> {
        let (stream, continuation) = AsyncStream.makeStream(of: Result<[Note], AppError>.self)
        let id = UUID()
        state.withLock { state in
            for result in state.scriptedReads ?? [state.currentResult] {
                continuation.yield(result)
            }
            if state.finishesStreams {
                continuation.finish()
            } else {
                state.continuations[id] = continuation
            }
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
            let result = state.currentResult
            state.continuations.values.forEach { $0.yield(result) }
        }
    }
}
