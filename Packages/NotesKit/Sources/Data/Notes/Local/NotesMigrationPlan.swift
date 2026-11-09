import SwiftData

enum NotesMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [NotesSchemaV1.self] }

    static var stages: [MigrationStage] { [] }
}
