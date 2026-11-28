import Foundation

/// Reglas de la búsqueda de "Mis notas" (spec 004, RF-1 a RF-14).
public enum NoteSearch {
    private static let locale = Locale(identifier: "es")

    /// Palabras normalizadas del texto buscado, sin espacios exteriores ni repetidos (RF-13).
    /// Sin palabras (vacío o solo espacios) no hay búsqueda (RF-4).
    public static func words(in query: String) -> [String] {
        normalized(query)
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
    }

    /// Una nota coincide si cada palabra buscada aparece, aunque sea como parte de una palabra,
    /// en su título, en su texto o en el texto de sus tareas (RF-5, RF-6, RF-11, RF-12).
    public static func matches(_ note: Note, query: String) -> Bool {
        matches(note, words: words(in: query))
    }

    /// Las notas que coinciden, en el mismo orden en que llegan (RF-14). Sin palabras, todas (RF-4).
    public static func filter(_ notes: [Note], query: String) -> [Note] {
        let words = words(in: query)
        guard !words.isEmpty else { return notes }
        return notes.filter { matches($0, words: words) }
    }

    private static func matches(_ note: Note, words: [String]) -> Bool {
        guard !words.isEmpty else { return true }
        let text = normalized(searchableText(of: note))
        return words.allSatisfy { text.contains($0) }
    }

    /// Título, texto y tareas (completadas o no). Categoría, color y fecha no cuentan (RF-7).
    /// El salto de línea evita que una palabra coincida uniendo el final de un campo con el siguiente.
    private static func searchableText(of note: Note) -> String {
        let blocks = note.blocks.map { block in
            switch block {
            case .text(let text): text
            case .task(let task): task.text
            }
        }
        return ([note.title] + blocks).joined(separator: "\n")
    }

    /// Sin mayúsculas ni tildes ni diéresis (RF-8, RF-9), pero con la "ñ" distinta de la "n" (RF-10):
    /// plegar la cadena entera convertiría "ñ" en "n", así que se pliega lo que hay entre cada "ñ".
    static func normalized(_ text: String) -> String {
        text.lowercased(with: locale)
            .split(separator: "ñ", omittingEmptySubsequences: false)
            .map { $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: locale) }
            .joined(separator: "ñ")
    }
}
