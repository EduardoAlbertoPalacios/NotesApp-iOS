import Foundation

/// Lo que el usuario tiene escrito en el editor, guardado o no (spec 002).
public struct NoteDraft: Equatable, Sendable {
    public let id: UUID
    /// `true` si la nota se creó con "Nueva nota" en esta apertura del editor.
    /// Una nota nueva que queda vacía se elimina; una existente vacía no se guarda (RF-33 a RF-37).
    public let isNew: Bool
    public var title: String
    public var blocks: [NoteBlock]
    public var category: NoteCategory?
    public var isPinned: Bool

    public init(
        id: UUID = UUID(),
        isNew: Bool,
        title: String = "",
        blocks: [NoteBlock] = [],
        category: NoteCategory? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.isNew = isNew
        self.title = title
        self.blocks = blocks
        self.category = category
        self.isPinned = isPinned
    }

    /// Borrador para editar una nota ya guardada.
    public init(editing note: Note) {
        self.init(
            id: note.id,
            isNew: false,
            title: note.title,
            blocks: note.blocks,
            category: note.category,
            isPinned: note.isPinned
        )
    }
}

/// Qué hizo `SaveNoteUseCase` con un borrador.
public enum NoteSaveResult: Equatable, Sendable {
    /// Se guardó; contiene la versión guardada.
    case saved(Note)
    /// Era una nota nueva ya guardada que quedó vacía, y se eliminó.
    case deleted
    /// No había nada que guardar: sin cambios, o vacía.
    case skipped
}
