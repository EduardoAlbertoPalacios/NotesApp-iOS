import Foundation

enum NoteListStrings {
    /// "6 notas · un espacio para tus ideas" / "1 nota · …" (spec 001, RF-2 y RF-3).
    static func counter(_ count: Int) -> String {
        String(localized: "\(count) notas · un espacio para tus ideas", bundle: .module)
    }

    /// "1 resultado" / "3 resultados" / "0 resultados" (spec 004, RF-15, RF-16).
    static func results(_ count: Int) -> String {
        String(localized: "\(count) resultados", bundle: .module)
    }

    /// "No hay notas que coincidan con «texto»" (spec 004, RF-18), con el texto sin espacios exteriores.
    static func noMatches(_ searchText: String) -> String {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(localized: "No hay notas que coincidan con «\(text)»", bundle: .module)
    }

    /// Texto que se anuncia a VoiceOver al terminar de escribir (spec 004, RF-42, RF-43).
    static func announcement(_ announcement: NoteListAnnouncement) -> String {
        switch announcement {
        case .results(let count): results(count)
        case .noMatches(let text): noMatches(text)
        }
    }
}
