import Foundation
import SwiftData

/// Segunda versión del esquema de notas: añade la categoría opcional (spec 002).
/// Desde V1 se migra con una etapa ligera; las notas existentes quedan sin categoría.
enum NotesSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    static var models: [any PersistentModel.Type] { [NoteEntity.self] }

    @Model
    final class NoteEntity {
        @Attribute(.unique) var id: UUID
        var title: String
        /// `[NoteBlock]` codificado en JSON (ver `NoteBlocksCoder`).
        var blocksData: Data
        var colorRawValue: String
        /// `NoteCategory.rawValue`, o `nil` si la nota no tiene categoría.
        var categoryRawValue: String?
        var isPinned: Bool
        var updatedAt: Date
        var sequence: Int

        init(
            id: UUID,
            title: String,
            blocksData: Data,
            colorRawValue: String,
            categoryRawValue: String?,
            isPinned: Bool,
            updatedAt: Date,
            sequence: Int
        ) {
            self.id = id
            self.title = title
            self.blocksData = blocksData
            self.colorRawValue = colorRawValue
            self.categoryRawValue = categoryRawValue
            self.isPinned = isPinned
            self.updatedAt = updatedAt
            self.sequence = sequence
        }
    }
}

/// Versión vigente de la entidad. Cada esquema nuevo mueve este alias a su versión.
typealias NoteEntity = NotesSchemaV2.NoteEntity
