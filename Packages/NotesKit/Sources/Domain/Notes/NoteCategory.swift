import Foundation

/// Categoría de una nota. Es opcional: una nota puede no tener ninguna (spec 002, RF-2 y RF-19).
/// El texto visible de cada caso vive en `Presentation`.
public enum NoteCategory: String, CaseIterable, Sendable {
    case work
    case personal
}
