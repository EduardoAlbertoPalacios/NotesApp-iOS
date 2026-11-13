import Domain

/// Pantallas a las que se navega desde "Mis notas" (spec 002). `NotesApp` las mantiene
/// en el `path` de su `NavigationStack` y crea la vista de cada una.
public enum NotesDestination: Hashable, Sendable {
    /// Editor de una nota nueva, desde "Nueva nota".
    case newNote
    /// Editor de una nota existente, desde su tarjeta.
    case note(Note)
}
