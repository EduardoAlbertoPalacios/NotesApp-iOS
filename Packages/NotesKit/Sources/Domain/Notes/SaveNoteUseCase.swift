import Common
import Foundation

/// Guarda lo escrito en el editor aplicando las reglas de la spec 002 (RF-28 y RF-32 a RF-37).
public struct SaveNoteUseCase: Sendable {
    /// Color de toda nota nueva (decisión D-1 del plan 002).
    static let newNoteColor = NoteColor.aqua

    private let repository: any NoteRepository
    private let dateProvider: any DateProvider

    public init(repository: any NoteRepository, dateProvider: any DateProvider) {
        self.repository = repository
        self.dateProvider = dateProvider
    }

    /// - Parameters:
    ///   - draft: lo que hay en el editor.
    ///   - lastSaved: la última versión guardada de esa nota, o `nil` si nunca se guardó.
    public func callAsFunction(_ draft: NoteDraft, lastSaved: Note?) async throws(AppError) -> NoteSaveResult {
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        // Los bloques de texto en blanco no son contenido (por ejemplo, la línea vacía
        // que el editor añade al final para poder escribir).
        let blocks = draft.blocks.filter { !$0.isBlankText }

        if title.isEmpty && blocks.isEmpty {
            // Nueva y ya guardada ⇒ se elimina (RF-33). Nueva sin guardar ⇒ no se crea (RF-32).
            // Existente ⇒ se conserva su última versión guardada (RF-36 y RF-37).
            guard draft.isNew, let lastSaved else { return .skipped }
            try await repository.delete(id: lastSaved.id)
            return .deleted
        }

        if let lastSaved,
            lastSaved.title == title,
            lastSaved.blocks == blocks,
            lastSaved.category == draft.category,
            lastSaved.isPinned == draft.isPinned
        {
            // Sin cambios: no se toca la fecha de última edición (RF-28).
            return .skipped
        }

        let sequence: Int
        if let lastSaved {
            sequence = lastSaved.sequence
        } else {
            sequence = try await repository.nextSequence()
        }

        // Un título vacío se guarda vacío; la interfaz lo muestra como "Sin título" (RF-34).
        let note = Note(
            id: draft.id,
            title: title,
            blocks: blocks,
            color: lastSaved?.color ?? Self.newNoteColor,
            category: draft.category,
            isPinned: draft.isPinned,
            updatedAt: dateProvider.now(),
            sequence: sequence
        )
        try await repository.save([note])
        return .saved(note)
    }
}

extension NoteBlock {
    fileprivate var isBlankText: Bool {
        guard case .text(let text) = self else { return false }
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
