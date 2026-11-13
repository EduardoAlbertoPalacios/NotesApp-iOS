import Common
import Domain
import Foundation
import Synchronization

final class FakeNoteRepository: NoteRepository {
    private struct State {
        var notes: [Note]
        var readFailure: AppError?
        var saveFailure: AppError?
        var deleteFailure: AppError?
        var sequenceFailure: AppError?
        var fixedNextSequence: Int?
        var deletedIDs: [UUID] = []
        var nextSequenceCallCount = 0
        var savedBatches: [[Note]] = []
        var continuations: [UUID: AsyncStream<Result<[Note], AppError>>.Continuation] = [:]

        /// El mayor `sequence` guardado más uno, o 0 si no hay notas (como el repositorio real).
        var derivedNextSequence: Int {
            (notes.map(\.sequence).max() ?? -1) + 1
        }

        var currentResult: Result<[Note], AppError> {
            if let readFailure { return .failure(readFailure) }
            return .success(notes)
        }
    }

    private let state: Mutex<State>

    /// - `readFailure`: cada stream nuevo emite `.failure` en lugar de las notas.
    /// - `saveFailure`: `save(_:)` lanza ese error sin guardar nada.
    /// - `deleteFailure`: `delete(id:)` lanza ese error sin borrar nada.
    /// - `sequenceFailure`: `nextSequence()` lanza ese error.
    /// - `nextSequence`: valor fijo para `nextSequence()`; si es `nil`, se deriva de las notas guardadas.
    init(
        notes: [Note] = [],
        readFailure: AppError? = nil,
        saveFailure: AppError? = nil,
        deleteFailure: AppError? = nil,
        sequenceFailure: AppError? = nil,
        nextSequence: Int? = nil
    ) {
        state = Mutex(State(
            notes: notes,
            readFailure: readFailure,
            saveFailure: saveFailure,
            deleteFailure: deleteFailure,
            sequenceFailure: sequenceFailure,
            fixedNextSequence: nextSequence
        ))
    }

    /// Cada llamada a `save(_:)` que terminó bien, en orden.
    var savedBatches: [[Note]] {
        state.withLock { $0.savedBatches }
    }

    /// Cada `id` pasado a `delete(id:)` que terminó bien, en orden.
    var deletedIDs: [UUID] {
        state.withLock { $0.deletedIDs }
    }

    /// Veces que se llamó a `nextSequence()`, haya fallado o no.
    var nextSequenceCallCount: Int {
        state.withLock { $0.nextSequenceCallCount }
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

    func delete(id: UUID) async throws(AppError) {
        try state.withLock { (state) throws(AppError) in
            if let failure = state.deleteFailure { throw failure }
            state.notes.removeAll { $0.id == id }
            state.deletedIDs.append(id)
            let result = state.currentResult
            state.continuations.values.forEach { $0.yield(result) }
        }
    }

    func nextSequence() async throws(AppError) -> Int {
        try state.withLock { (state) throws(AppError) -> Int in
            state.nextSequenceCallCount += 1
            if let failure = state.sequenceFailure { throw failure }
            return state.fixedNextSequence ?? state.derivedNextSequence
        }
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

