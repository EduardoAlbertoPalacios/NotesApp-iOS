import Foundation

/// Orden de la lista de notas (spec 001, RF-10 a RF-12).
public enum NoteOrdering {
    /// Fijadas primero; dentro de cada grupo, la última editada primero;
    /// a igual fecha, la creada antes primero.
    public static func sorted(_ notes: [Note]) -> [Note] {
        notes.sorted(by: precedes)
    }

    public static func precedes(_ lhs: Note, _ rhs: Note) -> Bool {
        if lhs.isPinned != rhs.isPinned {
            return lhs.isPinned
        }
        if lhs.updatedAt != rhs.updatedAt {
            return lhs.updatedAt > rhs.updatedAt
        }
        return lhs.sequence < rhs.sequence
    }
}
