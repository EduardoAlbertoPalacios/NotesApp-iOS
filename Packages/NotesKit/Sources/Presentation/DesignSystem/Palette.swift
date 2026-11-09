import Domain
import SwiftUI

/// Colores del diseño (Figma "Inicio · Mis notas", claro y oscuro), definidos en `Colors.xcassets`.
enum Palette {
    static let background = Color("Background", bundle: .module)
    static let surface = Color("Surface", bundle: .module)
    static let textPrimary = Color("TextPrimary", bundle: .module)
    static let textSecondary = Color("TextSecondary", bundle: .module)
    /// Texto sobre una tarjeta de color; igual en claro y oscuro.
    static let onCard = Color("OnCard", bundle: .module)
    static let onCardSecondary = Color("OnCardSecondary", bundle: .module)
    static let accent = Color("NoteAqua", bundle: .module)
}

extension NoteColor {
    var fill: Color {
        switch self {
        case .aqua: Color("NoteAqua", bundle: .module)
        case .pink: Color("NotePink", bundle: .module)
        case .yellow: Color("NoteYellow", bundle: .module)
        case .lavender: Color("NoteLavender", bundle: .module)
        case .mint: Color("NoteMint", bundle: .module)
        case .peach: Color("NotePeach", bundle: .module)
        }
    }
}
