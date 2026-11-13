import Common
import Foundation

/// Notas guardadas, ya ordenadas para la lista (spec 001, RF-10 a RF-12).
public struct ObserveNotesUseCase: Sendable {
    private let repository: any NoteRepository

    public init(repository: any NoteRepository) {
        self.repository = repository
    }

    public func callAsFunction() -> AsyncStream<Result<[Note], AppError>> {
        let upstream = repository.observeNotes()
        return AsyncStream { continuation in
            let task = Task {
                for await result in upstream {
                    continuation.yield(result.map(NoteOrdering.sorted))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
