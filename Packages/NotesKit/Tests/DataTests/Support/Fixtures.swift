import Domain
import Foundation

extension Date {
    /// 2026-11-09 10:00:00 UTC.
    static let fixture = Date(timeIntervalSince1970: 1_794_218_400)
}

extension Note {
    static func fixture(
        id: UUID = UUID(),
        title: String = "Título",
        blocks: [NoteBlock] = [.text("Contenido")],
        color: NoteColor = .yellow,
        category: NoteCategory? = nil,
        isPinned: Bool = false,
        updatedAt: Date = .fixture,
        sequence: Int = 0
    ) -> Note {
        Note(
            id: id,
            title: title,
            blocks: blocks,
            color: color,
            category: category,
            isPinned: isPinned,
            updatedAt: updatedAt,
            sequence: sequence
        )
    }
}
