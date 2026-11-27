import Common
import Foundation

/// Qué hizo `DeleteNoteUseCase` con la nota abierta en el editor.
public enum NoteDeletionResult: Equatable, Sendable {
    /// Se eliminó; contiene la copia con la que "Deshacer" la recupera (spec 003, RF-17 y RF-18).
    case deleted(Note)
    /// Era una nota nueva vacía: se descarta sin aviso (spec 003, RF-9).
    case discarded
}

/// Elimina la nota abierta en el editor (spec 003, RF-4, RF-7 a RF-9, RF-17 y RF-18).
public struct DeleteNoteUseCase: Sendable {
    private let repository: any NoteRepository
    private let dateProvider: any DateProvider

    public init(repository: any NoteRepository, dateProvider: any DateProvider) {
        self.repository = repository
        self.dateProvider = dateProvider
    }

    /// - Parameters:
    ///   - draft: lo que hay en el editor, guardado o no.
    ///   - lastSaved: la última versión guardada de esa nota, o `nil` si nunca se guardó.
    public func callAsFunction(_ draft: NoteDraft, lastSaved: Note?) async throws(AppError) -> NoteDeletionResult {
        if draft.isEmptyWhenCleaned {
            if draft.isNew {
                // Nota nueva vacía: se descarta, como al volver sin escribir (RF-9).
                if let lastSaved {
                    try await repository.delete(id: lastSaved.id)
                }
                return .discarded
            }
            // Una nota existente vaciada nunca se guarda vacía (spec 002, RF-36):
            // "Deshacer" recupera su última versión guardada (decisión D-2 del plan 003).
            guard let lastSaved else { return .discarded }
            try await repository.delete(id: lastSaved.id)
            return .deleted(lastSaved)
        }

        guard let lastSaved else {
            // Nunca se guardó: no hay nada que borrar. La copia toma los valores
            // que tendría en su primer guardado.
            let copy = Note(
                id: draft.id,
                title: draft.cleanedTitle,
                blocks: draft.cleanedBlocks,
                color: SaveNoteUseCase.newNoteColor,
                category: draft.category,
                isPinned: draft.isPinned,
                updatedAt: dateProvider.now(),
                sequence: try await repository.nextSequence()
            )
            return .deleted(copy)
        }

        // Copia con lo escrito, incluidos los cambios sin guardar (RF-17), y con la fecha,
        // el color y el orden guardados para volver a la misma posición (RF-18, RF-19).
        let copy = Note(
            id: lastSaved.id,
            title: draft.cleanedTitle,
            blocks: draft.cleanedBlocks,
            color: lastSaved.color,
            category: draft.category,
            isPinned: draft.isPinned,
            updatedAt: lastSaved.updatedAt,
            sequence: lastSaved.sequence
        )
        try await repository.delete(id: lastSaved.id)
        return .deleted(copy)
    }
}
