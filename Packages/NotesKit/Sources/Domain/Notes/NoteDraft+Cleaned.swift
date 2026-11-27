import Foundation

extension NoteDraft {
    /// Título sin espacios ni saltos de línea exteriores.
    var cleanedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Bloques sin los de texto en blanco: no son contenido (por ejemplo, la línea vacía
    /// que el editor añade al final para poder escribir).
    var cleanedBlocks: [NoteBlock] {
        blocks.filter { !$0.isBlankText }
    }

    /// Sin título ni contenido una vez limpio: lo que las specs 002 y 003 tratan como nota vacía.
    var isEmptyWhenCleaned: Bool {
        cleanedTitle.isEmpty && cleanedBlocks.isEmpty
    }
}

extension NoteBlock {
    fileprivate var isBlankText: Bool {
        guard case .text(let text) = self else { return false }
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
