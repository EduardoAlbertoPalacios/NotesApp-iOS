import Common
import Domain
import Foundation
import Testing
@testable import Data

struct NoteMappersTests {
    @Test("given note with text and task blocks when mapped to entity and back then is unchanged")
    func roundTripWithTextAndTasks() throws {
        let note = Note.fixture(
            title: "Compras",
            blocks: [
                .text("Para el fin de semana"),
                .task(NoteTask(text: "Leche", isDone: true)),
                .task(NoteTask(text: "Pan", isDone: false)),
                .text(""),
            ],
            color: .lavender,
            isPinned: true,
            sequence: 7
        )

        let mapped = try note.toEntity().toDomain()

        #expect(mapped == note)
    }

    @Test("given note without blocks when mapped to entity and back then is unchanged")
    func roundTripWithoutBlocks() throws {
        let note = Note.fixture(blocks: [])

        let mapped = try note.toEntity().toDomain()

        #expect(mapped == note)
    }

    @Test("given entity when updated from another note with same id then maps to that note")
    func updateFromNote() throws {
        let original = Note.fixture(title: "Antes", blocks: [.text("Viejo")], color: .aqua)
        let entity = try original.toEntity()
        let changed = Note.fixture(
            id: original.id,
            title: "Después",
            blocks: [.task(NoteTask(text: "Hecha", isDone: true))],
            color: .peach,
            isPinned: true,
            updatedAt: Date.fixture.addingTimeInterval(3_600),
            sequence: 3
        )

        try entity.update(from: changed)

        #expect(try entity.toDomain() == changed)
    }

    @Test("given entity with unknown color raw value when mapped to domain then throws corrupted data")
    func unknownColorThrows() throws {
        let entity = try Note.fixture().toEntity()
        entity.colorRawValue = "magenta"

        #expect(throws: AppError.corruptedData) {
            try entity.toDomain()
        }
    }

    @Test("given entity with unreadable blocks data when mapped to domain then throws corrupted data")
    func unreadableBlocksThrows() throws {
        let entity = try Note.fixture().toEntity()
        entity.blocksData = Data("esto no es JSON".utf8)

        #expect(throws: AppError.corruptedData) {
            try entity.toDomain()
        }
    }
}

struct NoteBlocksCoderTests {
    @Test("given text and task blocks when encoded and decoded then are unchanged")
    func roundTrip() throws {
        let blocks: [NoteBlock] = [
            .text("Idea"),
            .task(NoteTask(text: "Completada", isDone: true)),
            .task(NoteTask(text: "Pendiente", isDone: false)),
        ]

        let decoded = try NoteBlocksCoder.decode(NoteBlocksCoder.encode(blocks))

        #expect(decoded == blocks)
    }

    @Test("given unreadable data when decoding then throws corrupted data")
    func unreadableDataThrows() {
        let data = Data(#"[{"kind":"image","text":"x"}]"#.utf8)

        #expect(throws: AppError.corruptedData) {
            try NoteBlocksCoder.decode(data)
        }
    }
}
