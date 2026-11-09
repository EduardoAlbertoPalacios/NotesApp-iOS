import Common
import Domain
import Foundation
import SwiftData
import Testing
@testable import Data

@Suite(.timeLimit(.minutes(1)))
struct NoteRepositoryImplTests {
    private func makeContainer() throws -> ModelContainer {
        try DataAssembly.makeModelContainer(inMemory: true)
    }

    @Test("given stored notes when observing then first emission is the current content")
    func firstEmissionIsCurrentContent() async throws {
        let container = try makeContainer()
        let notes = [Note.fixture(title: "Uno", sequence: 0), Note.fixture(title: "Dos", sequence: 1)]
        try await DataAssembly.makeNoteRepository(container: container).save(notes)
        let repository = DataAssembly.makeNoteRepository(container: container)
        var results = repository.observeNotes().makeAsyncIterator()

        let first = try #require(await results.next())

        #expect(Set(try first.get()) == Set(notes))
    }

    @Test("given an open observation when saving a note then emits again with the new note")
    func reEmitsAfterSave() async throws {
        let existing = Note.fixture(title: "Existente", sequence: 0)
        let repository = DataAssembly.makeNoteRepository(container: try makeContainer())
        try await repository.save([existing])
        var results = repository.observeNotes().makeAsyncIterator()
        #expect(await results.next() == .success([existing]))
        let new = Note.fixture(title: "Nueva", sequence: 1)

        try await repository.save([new])

        #expect(await results.next(matching: [existing, new]) == [existing, new])
    }

    @Test("given corrupted entity in store when observing then emits corrupted data failure")
    func corruptedEntityEmitsFailure() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let entity = try Note.fixture().toEntity()
        entity.colorRawValue = "magenta"
        context.insert(entity)
        try context.save()
        var results = DataAssembly.makeNoteRepository(container: container).observeNotes().makeAsyncIterator()

        let first = await results.next()

        #expect(first == .failure(.corruptedData))
    }

    @Test("given notes saved by one repository when a second repository opens the same container then shows them")
    func notesPersistAcrossRepositories() async throws {
        let container = try makeContainer()
        let notes = [
            Note.fixture(title: "Fijada", isPinned: true, sequence: 0),
            Note.fixture(title: "Tareas", blocks: [.task(NoteTask(text: "Hecha", isDone: true))], sequence: 1),
        ]
        try await DataAssembly.makeNoteRepository(container: container).save(notes)

        var results = DataAssembly.makeNoteRepository(container: container).observeNotes().makeAsyncIterator()
        let first = try #require(await results.next())

        #expect(Set(try first.get()) == Set(notes))
    }
}

@Suite(.timeLimit(.minutes(1)))
struct UnavailableNoteRepositoryTests {
    @Test("given unavailable storage when observing then emits storage unavailable failure")
    func observeEmitsFailure() async {
        var results = DataAssembly.makeUnavailableNoteRepository().observeNotes().makeAsyncIterator()

        let first = await results.next()

        #expect(first == .failure(.storageUnavailable))
    }

    @Test("given unavailable storage when saving then throws storage unavailable")
    func saveThrows() async {
        let repository = DataAssembly.makeUnavailableNoteRepository()

        await #expect(throws: AppError.storageUnavailable) {
            try await repository.save([.fixture()])
        }
    }
}
