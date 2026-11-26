import Domain
import Foundation

/// Una eliminación hecha en el editor, que "Mis notas" ofrece deshacer (spec 003, RF-10).
/// `NotesApp` la pasa del editor a la lista; el `id` es nuevo en cada eliminación para que
/// la lista no muestre dos veces el mismo aviso.
public struct NoteDeletion: Equatable, Sendable {
    public let id: UUID
    /// Copia con la que "Deshacer" recupera la nota.
    public let note: Note

    public init(id: UUID = UUID(), note: Note) {
        self.id = id
        self.note = note
    }
}
