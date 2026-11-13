import Common
import Foundation
import Testing
@testable import Domain

@Suite(.timeLimit(.minutes(1)))
struct ObserveNotesUseCaseTests {
    private func makeSut(repository: FakeNoteRepository) -> ObserveNotesUseCase {
        ObserveNotesUseCase(repository: repository)
    }

    @Test("given unsorted notes in repository when observing then emits them sorted")
    func emitsSortedNotes() async {
        let unpinned = Note.fixture(title: "Suelta", updatedAt: Date.fixture.addingTimeInterval(60), sequence: 0)
        let pinned = Note.fixture(title: "Fijada", isPinned: true, updatedAt: .fixture, sequence: 1)
        let repository = FakeNoteRepository(notes: [unpinned, pinned])
        var results = makeSut(repository: repository)().makeAsyncIterator()

        let first = await results.next()

        #expect(first == .success([pinned, unpinned]))
    }

    @Test("given repository read failure when observing then emits the same failure")
    func propagatesFailure() async {
        let repository = FakeNoteRepository(readFailure: .corruptedData)
        var results = makeSut(repository: repository)().makeAsyncIterator()

        let first = await results.next()

        #expect(first == .failure(.corruptedData))
    }

    @Test("given an open observation when repository emits again then emits new sorted notes")
    func reEmitsWhenRepositoryEmits() async throws {
        let old = Note.fixture(title: "Antigua", updatedAt: .fixture, sequence: 0)
        let repository = FakeNoteRepository(notes: [old])
        var results = makeSut(repository: repository)().makeAsyncIterator()
        #expect(await results.next() == .success([old]))
        let new = Note.fixture(title: "Nueva", updatedAt: Date.fixture.addingTimeInterval(60), sequence: 1)

        try await repository.save([new])

        #expect(await results.next() == .success([new, old]))
    }

    @Test("given notes emitted when repository later fails then emits the failure without ending the stream")
    func failureAfterSuccessKeepsStreamOpen() async throws {
        let note = Note.fixture()
        let repository = FakeNoteRepository(notes: [note])
        var results = makeSut(repository: repository)().makeAsyncIterator()
        #expect(await results.next() == .success([note]))

        repository.emitReadFailure(.storageUnavailable)
        let failure = await results.next()
        try await repository.save([note])
        let recovered = await results.next()

        #expect(failure == .failure(.storageUnavailable))
        #expect(recovered == .success([note]))
    }
}
