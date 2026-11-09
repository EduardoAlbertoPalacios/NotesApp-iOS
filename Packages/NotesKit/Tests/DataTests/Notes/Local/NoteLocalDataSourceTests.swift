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
}
