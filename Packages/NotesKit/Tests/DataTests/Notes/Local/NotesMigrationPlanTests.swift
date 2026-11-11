import Common
import Domain
import Foundation
import SwiftData
import Testing
@testable import Data

/// Una migración no se puede probar en memoria: cada prueba abre el mismo almacén dos veces
/// en un archivo único del directorio temporal y lo borra al terminar.
@Suite(.timeLimit(.minutes(1)))
struct NotesMigrationPlanTests {
    private let storeURL = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).store")

    private var storeFiles: [URL] {
        ["", "-shm", "-wal"].map { URL(filePath: storeURL.path(percentEncoded: false) + $0) }
    }

    private func removeStoreFiles() {
        for file in storeFiles {
            // Limpieza de la prueba: si el archivo no llegó a crearse no hay nada que borrar.
            try? FileManager.default.removeItem(at: file)
        }
    }

    private func saveWithV1(_ notes: [Note]) throws {
        let v1 = try ModelContainer(
            for: Schema(versionedSchema: NotesSchemaV1.self),
            configurations: ModelConfiguration(url: storeURL)
        )
        let context = ModelContext(v1)
        for note in notes {
            context.insert(
                NotesSchemaV1.NoteEntity(
                    id: note.id,
                    title: note.title,
                    blocksData: try NoteBlocksCoder.encode(note.blocks),
                    colorRawValue: note.color.rawValue,
                    isPinned: note.isPinned,
                    updatedAt: note.updatedAt,
                    sequence: note.sequence
                )
            )
        }
        try context.save()
    }

    private func openWithV2() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(versionedSchema: NotesSchemaV2.self),
            migrationPlan: NotesMigrationPlan.self,
            configurations: ModelConfiguration(url: storeURL)
        )
    }

    private var v1Notes: [Note] {
        [
            Note.fixture(
                title: "Compras",
                blocks: [.text("Para el sábado"), .task(NoteTask(text: "Leche", isDone: true))],
                color: .mint,
                isPinned: true,
                updatedAt: Date.fixture,
                sequence: 0
            ),
            Note.fixture(
                title: "Ideas",
                blocks: [.text("Viaje")],
                color: .lavender,
                isPinned: false,
                updatedAt: Date.fixture.addingTimeInterval(-86_400),
                sequence: 1
            ),
        ]
    }

    @Test("given notes saved with schema V1 when opened with V2 and migration plan then keeps them uncategorized")
    func migratesV1ToV2KeepingNotes() async throws {
        defer { removeStoreFiles() }
        let notes = v1Notes
        try saveWithV1(notes)

        let v2 = try openWithV2()
        let migrated = try await NoteLocalDataSource(modelContainer: v2).fetchAll()

        #expect(Set(migrated) == Set(notes))
        #expect(migrated.allSatisfy { $0.category == nil })
    }

    @Test("given notes saved with schema V1 when migrated to V2 then stored category raw value is nil")
    func migratedEntitiesHaveNilCategoryRawValue() throws {
        defer { removeStoreFiles() }
        try saveWithV1(v1Notes)

        let v2 = try openWithV2()
        let entities = try ModelContext(v2).fetch(FetchDescriptor<NotesSchemaV2.NoteEntity>())

        #expect(entities.count == 2)
        #expect(entities.allSatisfy { $0.categoryRawValue == nil })
    }

    @Test("given a store migrated from V1 when saving a category on a migrated note then reads it back")
    func migratedNoteAcceptsCategory() async throws {
        defer { removeStoreFiles() }
        let notes = v1Notes
        try saveWithV1(notes)
        let dataSource = NoteLocalDataSource(modelContainer: try openWithV2())
        var edited = notes[0]
        edited.category = .work

        try await dataSource.save([edited])

        #expect(Set(try await dataSource.fetchAll()) == [edited, notes[1]])
    }
}
