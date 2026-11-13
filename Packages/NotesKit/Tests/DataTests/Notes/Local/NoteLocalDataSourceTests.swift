import Common
import Domain
import Foundation
import SwiftData
import Testing
@testable import Data

@Suite(.timeLimit(.minutes(1)))
struct NoteLocalDataSourceTests {
    private func makeSut() throws -> NoteLocalDataSource {
        NoteLocalDataSource(modelContainer: try DataAssembly.makeModelContainer(inMemory: true))
    }

    @Test("given empty store when fetching all then returns no notes")
    func emptyStore() async throws {
        let dataSource = try makeSut()

        let notes = try await dataSource.fetchAll()

        #expect(notes.isEmpty)
    }

    @Test("given saved note when fetching all then returns it")
    func saveThenFetch() async throws {
        let dataSource = try makeSut()
        let note = Note.fixture(blocks: [.text("Hola"), .task(NoteTask(text: "Tarea", isDone: true))])

        try await dataSource.save([note])

        #expect(try await dataSource.fetchAll() == [note])
    }

    @Test("given saved note when saving another with same id then replaces it instead of duplicating")
    func saveSameIdReplaces() async throws {
        let dataSource = try makeSut()
        let original = Note.fixture(title: "Original")
        try await dataSource.save([original])
        let edited = Note.fixture(id: original.id, title: "Editada", color: .mint, isPinned: true, sequence: 1)

        try await dataSource.save([edited])

        #expect(try await dataSource.fetchAll() == [edited])
    }

    @Test("given several notes when saved in one call then all are stored")
    func saveSeveralInOneCall() async throws {
        let dataSource = try makeSut()
        let notes = [
            Note.fixture(title: "Uno", sequence: 0),
            Note.fixture(title: "Dos", color: .pink, sequence: 1),
            Note.fixture(title: "Tres", blocks: [.task(NoteTask(text: "Pendiente"))], sequence: 2),
        ]

        try await dataSource.save(notes)

        #expect(Set(try await dataSource.fetchAll()) == Set(notes))
    }

    @Test("given saved notes with and without category when fetching all then keeps each category")
    func saveKeepsCategory() async throws {
        let dataSource = try makeSut()
        let notes = [
            Note.fixture(title: "Trabajo", category: .work, sequence: 0),
            Note.fixture(title: "Personal", category: .personal, sequence: 1),
            Note.fixture(title: "Sin categoría", category: nil, sequence: 2),
        ]

        try await dataSource.save(notes)

        #expect(Set(try await dataSource.fetchAll()) == Set(notes))
    }

    @Test("given several notes when deleting one by id then only that note is removed")
    func deleteRemovesOnlyThatNote() async throws {
        let dataSource = try makeSut()
        let kept = [Note.fixture(title: "Uno", sequence: 0), Note.fixture(title: "Tres", sequence: 2)]
        let deleted = Note.fixture(title: "Dos", sequence: 1)
        try await dataSource.save(kept + [deleted])

        try await dataSource.delete(id: deleted.id)

        #expect(Set(try await dataSource.fetchAll()) == Set(kept))
    }

    @Test("given stored notes when deleting an unknown id then does not fail nor remove anything")
    func deleteUnknownIdIsNoOp() async throws {
        let dataSource = try makeSut()
        let notes = [Note.fixture(title: "Uno", sequence: 0), Note.fixture(title: "Dos", sequence: 1)]
        try await dataSource.save(notes)

        try await dataSource.delete(id: UUID())

        #expect(Set(try await dataSource.fetchAll()) == Set(notes))
    }

    @Test("given empty store when asking next sequence then returns zero")
    func nextSequenceEmptyIsZero() async throws {
        let dataSource = try makeSut()

        let next = try await dataSource.nextSequence()

        #expect(next == 0)
    }

    @Test("given notes saved out of sequence order when asking next sequence then returns highest plus one")
    func nextSequenceIsMaxPlusOne() async throws {
        let dataSource = try makeSut()
        try await dataSource.save([Note.fixture(sequence: 3)])
        try await dataSource.save([Note.fixture(sequence: 9)])
        try await dataSource.save([Note.fixture(sequence: 1)])

        let next = try await dataSource.nextSequence()

        #expect(next == 10)
    }
}
