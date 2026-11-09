import Foundation

/// Errores de infraestructura compartidos entre módulos.
/// Los repositorios traducen los errores de SwiftData a estos casos.
public enum AppError: Error, Equatable, Sendable {
    /// El almacenamiento no está disponible o no se pudo leer/escribir.
    case storageUnavailable
    /// Los datos guardados existen pero no se pueden interpretar.
    case corruptedData
}
