import SwiftData

enum NotesMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [NotesSchemaV1.self, NotesSchemaV2.self] }

    static var stages: [MigrationStage] { [migrateV1toV2] }

    /// V2 solo añade `categoryRawValue` opcional: las notas existentes quedan sin categoría.
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: NotesSchemaV1.self,
        toVersion: NotesSchemaV2.self
    )
}
