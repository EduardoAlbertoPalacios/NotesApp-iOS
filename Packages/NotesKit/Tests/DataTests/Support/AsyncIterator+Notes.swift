import Common
import Domain

extension AsyncStream<Result<[Note], AppError>>.Iterator {
    /// Avanza hasta la primera emisión cuyas notas, sin importar el orden, son `expected`.
    ///
    /// `NoteRepositoryImpl` vuelve a consultar con cualquier `ModelContext.didSave` del proceso,
    /// así que otras pruebas que guardan en paralelo en otros contenedores pueden provocar
    /// emisiones intermedias con el contenido sin cambios. Si el valor esperado nunca llega,
    /// la prueba falla por el `.timeLimit` de la suite. Devuelve `nil` si el stream termina antes.
    mutating func next(matching expected: Set<Note>) async -> Set<Note>? {
        while let result = await next() {
            if case .success(let notes) = result, Set(notes) == expected {
                return Set(notes)
            }
        }
        return nil
    }
}
