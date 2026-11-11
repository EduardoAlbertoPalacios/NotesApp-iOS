import Domain
import Foundation

struct NoteEditorState: Equatable, Sendable {
    var title: String
    /// Contenido editable: los bloques `.text` se editan, los `.task` solo se muestran.
    var blocks: [NoteBlock]
    var category: NoteCategory?
    var isPinned: Bool
    /// Fecha de la cabecera: la última edición guardada o, si la nota nunca se guardó, la apertura del editor.
    var headerDate: Date
    var saveStatus: NoteEditorSaveStatus
    var isDiscardDialogPresented = false

    /// Muestra el texto de ayuda "Título" (RF-8).
    var isTitleEmpty: Bool { title.isEmpty }

    /// Muestra el texto de ayuda "Escribir nota…" (RF-9): no hay tareas ni texto escrito.
    var isContentEmpty: Bool {
        blocks.allSatisfy { block in
            guard case .text(let text) = block else { return false }
            return text.isEmpty
        }
    }
}

enum NoteEditorSaveStatus: Equatable, Sendable {
    /// Nada que indicar: hay cambios pendientes o la nota aún no se ha guardado.
    case idle
    /// Todos los cambios están guardados (RF-24).
    case saved
    /// El último intento de guardar falló (RF-38 a RF-41).
    case failed
}

extension NoteEditorState {
    /// Estado inicial del editor para un destino. `now` es la fecha de cabecera de una nota nueva.
    static func initial(for destination: NotesDestination, now: Date) -> NoteEditorState {
        switch destination {
        case .newNote:
            return NoteEditorState(
                title: "",
                blocks: [.text("")],
                category: nil,
                isPinned: false,
                headerDate: now,
                saveStatus: .idle
            )
        case .note(let note):
            return NoteEditorState(
                title: note.title,
                blocks: withTrailingTextBlock(note.blocks),
                category: note.category,
                isPinned: note.isPinned,
                headerDate: note.updatedAt,
                saveStatus: .saved
            )
        }
    }

    /// Añade un bloque de texto vacío al final si el último no es de texto, para que siempre
    /// se pueda escribir (por ejemplo, después de una lista de tareas). `SaveNoteUseCase` lo descarta si sigue vacío.
    static func withTrailingTextBlock(_ blocks: [NoteBlock]) -> [NoteBlock] {
        guard case .text = blocks.last else { return blocks + [.text("")] }
        return blocks
    }
}
