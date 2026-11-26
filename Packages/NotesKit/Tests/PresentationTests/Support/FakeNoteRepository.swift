import Common
import Domain
import Foundation
import Synchronization

final class FakeNoteRepository: NoteRepository {
    /// Escritura terminada en el repositorio, para comprobar el orden entre guardar y borrar.
    enum Operation: Equatable {
        case save([UUID])
        case delete(UUID)
    }

    private struct State {
        var notes: [Note]
        var readFailure: AppError?
        var saveFailure: AppError?
        var deleteFailure: AppError?
        var sequenceFailure: AppError?
        var fixedNextSequence: Int?
        var deletedIDs: [UUID] = []
        var nextSequenceCallCount = 0
        var saveCallCount = 0
        var operations: [Operation] = []
        var isHoldingSaves = false
        var heldSaves: [CheckedContinuation<Void, Never>] = []
        var scriptedReads: [Result<[Note], AppError>]?
        var finishesStreams: Bool
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
    /// - `scriptedReads`: cada stream nuevo emite estos resultados en orden en lugar del actual.
    /// - `finishesStreams`: el stream termina tras emitir, para que `await viewModel.start()` regrese.
    init(
        notes: [Note] = [],
        readFailure: AppError? = nil,
        saveFailure: AppError? = nil,
        deleteFailure: AppError? = nil,
        sequenceFailure: AppError? = nil,
        nextSequence: Int? = nil,
        scriptedReads: [Result<[Note], AppError>]? = nil,
        finishesStreams: Bool = false
    ) {
        state = Mutex(State(
            notes: notes,
            readFailure: readFailure,
            saveFailure: saveFailure,
            deleteFailure: deleteFailure,
            sequenceFailure: sequenceFailure,
            fixedNextSequence: nextSequence,
            scriptedReads: scriptedReads,
            finishesStreams: finishesStreams
        ))
    }

    /// Cada `id` pasado a `delete(id:)` que terminó bien, en orden.
    var deletedIDs: [UUID] {
        state.withLock { $0.deletedIDs }
    }

    /// Notas guardadas ahora mismo, en orden de guardado.
    var notes: [Note] {
        state.withLock { $0.notes }
    }

    /// Veces que se llamó a `save(_:)`, haya fallado o no.
    var saveCallCount: Int {
        state.withLock { $0.saveCallCount }
    }

    /// Veces que se llamó a `nextSequence()`, haya fallado o no.
    var nextSequenceCallCount: Int {
        state.withLock { $0.nextSequenceCallCount }
    }

    /// Escrituras (`save` / `delete`) que terminaron bien, en orden.
    var operations: [Operation] {
        state.withLock { $0.operations }
    }

    /// Llamadas a `save(_:)` suspendidas por `holdSaves()`.
    var heldSaveCount: Int {
        state.withLock { $0.heldSaves.count }
    }

    /// A partir de ahora cada `save(_:)` queda suspendido (guardado "en curso") hasta `releaseSaves()`.
    func holdSaves() {
        state.withLock { $0.isHoldingSaves = true }
    }

    /// Deja de suspender y reanuda los `save(_:)` retenidos.
    func releaseSaves() {
        let held = state.withLock { state in
            state.isHoldingSaves = false
            defer { state.heldSaves = [] }
            return state.heldSaves
        }
        held.forEach { $0.resume() }
    }

    func failDeletes(with error: AppError?) {
        state.withLock { $0.deleteFailure = error }
    }

    func failNextSequence(with error: AppError?) {
        state.withLock { $0.sequenceFailure = error }
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

    func delete(id: UUID) async throws(AppError) {
        try state.withLock { (state) throws(AppError) in
            if let failure = state.deleteFailure { throw failure }
            state.notes.removeAll { $0.id == id }
            state.deletedIDs.append(id)
            state.operations.append(.delete(id))
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
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let holds = state.withLock { state in
                if state.isHoldingSaves { state.heldSaves.append(continuation) }
                return state.isHoldingSaves
            }
            if !holds { continuation.resume() }
        }
        try state.withLock { (state) throws(AppError) in
            state.saveCallCount += 1
            if let failure = state.saveFailure { throw failure }
            for note in notes {
                state.notes.removeAll { $0.id == note.id }
                state.notes.append(note)
            }
            state.operations.append(.save(notes.map(\.id)))
            let result = state.currentResult
            state.continuations.values.forEach { $0.yield(result) }
        }
    }
}
