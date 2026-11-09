import Foundation

/// Una nota del usuario.
public struct Note: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var blocks: [NoteBlock]
    public var color: NoteColor
    public var isPinned: Bool
    public var updatedAt: Date
    /// Orden de creación; desempata notas con la misma `updatedAt` (la creada antes va primero).
    public var sequence: Int

    public init(
        id: UUID = UUID(),
        title: String,
        blocks: [NoteBlock],
        color: NoteColor,
        isPinned: Bool = false,
        updatedAt: Date,
        sequence: Int
    ) {
        self.id = id
        self.title = title
        self.blocks = blocks
        self.color = color
        self.isPinned = isPinned
        self.updatedAt = updatedAt
        self.sequence = sequence
    }
}

/// Un fragmento del contenido de una nota.
public enum NoteBlock: Hashable, Sendable {
    case text(String)
    case task(NoteTask)
}

/// Una tarea de una lista de tareas.
public struct NoteTask: Hashable, Sendable {
    public var text: String
    public var isDone: Bool

    public init(text: String, isDone: Bool = false) {
        self.text = text
        self.isDone = isDone
    }
}

/// Colores de nota del diseño. El valor visual de cada uno vive en `Presentation`.
public enum NoteColor: String, CaseIterable, Sendable {
    case aqua
    case pink
    case yellow
    case lavender
    case mint
    case peach
}
