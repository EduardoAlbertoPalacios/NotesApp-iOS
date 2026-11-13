import Common
import Domain
import Foundation

extension NoteEntity {
    func toDomain() throws(AppError) -> Note {
        guard let color = NoteColor(rawValue: colorRawValue) else {
            throw .corruptedData
        }
        return Note(
            id: id,
            title: title,
            blocks: try NoteBlocksCoder.decode(blocksData),
            color: color,
            category: try Self.category(from: categoryRawValue),
            isPinned: isPinned,
            updatedAt: updatedAt,
            sequence: sequence
        )
    }

    func update(from note: Note) throws(AppError) {
        title = note.title
        blocksData = try NoteBlocksCoder.encode(note.blocks)
        colorRawValue = note.color.rawValue
        categoryRawValue = note.category?.rawValue
        isPinned = note.isPinned
        updatedAt = note.updatedAt
        sequence = note.sequence
    }

    /// `nil` guardado ⇒ sin categoría. Un valor que no corresponde a ninguna categoría ⇒ datos corruptos.
    private static func category(from rawValue: String?) throws(AppError) -> NoteCategory? {
        guard let rawValue else { return nil }
        guard let category = NoteCategory(rawValue: rawValue) else {
            throw .corruptedData
        }
        return category
    }
}

extension Note {
    func toEntity() throws(AppError) -> NoteEntity {
        NoteEntity(
            id: id,
            title: title,
            blocksData: try NoteBlocksCoder.encode(blocks),
            colorRawValue: color.rawValue,
            categoryRawValue: category?.rawValue,
            isPinned: isPinned,
            updatedAt: updatedAt,
            sequence: sequence
        )
    }
}
