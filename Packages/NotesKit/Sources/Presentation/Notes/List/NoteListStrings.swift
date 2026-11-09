import Foundation

enum NoteListStrings {
    /// "6 notas · un espacio para tus ideas" / "1 nota · …" (spec 001, RF-2 y RF-3).
    static func counter(_ count: Int) -> String {
        String(localized: "\(count) notas · un espacio para tus ideas", bundle: .module)
    }
}
