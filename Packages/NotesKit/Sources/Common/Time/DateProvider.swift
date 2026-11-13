import Foundation

/// Fuente de la fecha actual; se inyecta para poder fijar el tiempo en pruebas.
public protocol DateProvider: Sendable {
    func now() -> Date
}

/// Implementación de producción: la fecha del sistema.
public struct SystemDateProvider: DateProvider {
    public init() {}

    public func now() -> Date {
        Date()
    }
}
