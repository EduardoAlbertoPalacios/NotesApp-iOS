import Domain
import Foundation

/// Textos visibles de cada categoría (spec 002, RF-14).
extension NoteCategory {
    var title: String {
        switch self {
        case .work: String(localized: "Trabajo", bundle: .module)
        case .personal: String(localized: "Personal", bundle: .module)
        }
    }

    var summary: String {
        switch self {
        case .work: String(localized: "Proyectos, reuniones y tareas", bundle: .module)
        case .personal: String(localized: "Recordatorios y vida diaria", bundle: .module)
        }
    }
}
