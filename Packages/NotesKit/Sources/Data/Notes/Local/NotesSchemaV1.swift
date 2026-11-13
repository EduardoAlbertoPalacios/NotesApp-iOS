import Foundation
import SwiftData

/// Primera versión del esquema de notas. Se conserva para migrar almacenes antiguos a V2;
/// no se modifica. Cualquier cambio en `NoteEntity` requiere un esquema nuevo y su `MigrationStage`.
enum NotesSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] { [NoteEntity.self] }

    @Model
    final class NoteEntity {
        @Attribute(.unique) var id: UUID
        var title: String
        /// `[NoteBlock]` codificado en JSON (ver `NoteBlocksCoder`).
        var blocksData: Data
        var colorRawValue: String
        var isPinned: Bool
        var updatedAt: Date
        var sequence: Int

        init(
            id: UUID,
            title: String,
            blocksData: Data,
            colorRawValue: String,
            isPinned: Bool,
            updatedAt: Date,
            sequence: Int
        ) {
            self.id = id
            self.title = title
            self.blocksData = blocksData
            self.colorRawValue = colorRawValue
            self.isPinned = isPinned
            self.updatedAt = updatedAt
            self.sequence = sequence
        }
    }
}
