import Common
import Foundation
import Testing

@testable import Domain

struct RestoreNoteUseCaseTests {
    private func makeSut(repository: FakeNoteRepository = FakeNoteRepository()) -> RestoreNoteUseCase {
        RestoreNoteUseCase(repository: repository)
    }

    @Test("given deleted note copy when restoring then saves it unchanged in a single batch")
    func restoresNoteAsIs() async throws {
        let repository = FakeNoteRepository()
        let note = Note.fixture(
            title: "Compras", blocks: [.task(NoteTask(text: "Pan", isDone: true))], color: .mint,
            category: .personal, isPinned: true, updatedAt: .fixture, sequence: 9)

        try await makeSut(repository: repository)(note)

        #expect(repository.savedBatches == [[note]])
    }

    @Test("given save fails when restoring then throws the same AppError and saves nothing")
    func saveFailurePropagates() async {
        let repository = FakeNoteRepository(saveFailure: .storageUnavailable)
        var caught: AppError?

        do {
            try await makeSut(repository: repository)(.fixture())
        } catch {
            caught = error
        }

        #expect(caught == .storageUnavailable)
        #expect(repository.savedBatches.isEmpty)
    }
}
