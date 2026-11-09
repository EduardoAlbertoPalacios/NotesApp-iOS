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
            isPinned: isPinned,
            updatedAt: updatedAt,
            sequence: sequence
        )
    }

    func update(from note: Note) throws(AppError) {
        title = note.title
        blocksData = try NoteBlocksCoder.encode(note.blocks)
        colorRawValue = note.color.rawValue
        isPinned = note.isPinned
        updatedAt = note.updatedAt
        sequence = note.sequence
    }
}

extension Note {
    func toEntity() throws(AppError) -> NoteEntity {
        NoteEntity(
            id: id,
            title: title,
            blocksData: try NoteBlocksCoder.encode(blocks),
            colorRawValue: color.rawValue,
            isPinned: isPinned,
            updatedAt: updatedAt,
            sequence: sequence
        )
    }
}
