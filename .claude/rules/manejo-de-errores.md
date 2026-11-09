## Manejo de errores
- Los errores esperables (validación, nota no encontrada) se modelan en `Domain` como tipos concretos (`enum XxxError: Error, Equatable, Sendable`, o `AppError` de `Common`) y se declaran con **typed throws**: `async throws(SaveNoteError)`. Nunca `throws` sin tipo en `Domain` ni en las interfaces públicas de `Data`.
- Nunca captures `any Error` de forma genérica ni dejes un `catch` vacío. Con typed throws el `catch` ya recibe el tipo concreto; maneja sus casos.
- En producción, no descartes errores con `try?` salvo que el fallo sea irrelevante y lo justifiques en un comentario. `try!` está prohibido.
- No atrapes ni conviertas `CancellationError` en un error de dominio: si una tarea se cancela, termina en silencio, sin cambiar el estado de error ni emitir efectos.
- Los repositorios traducen los errores de SwiftData a `AppError`; ningún error de SwiftData sale de `Data`.
- El ViewModel convierte los errores en estado de UI (`XxxState`) o en efectos con mensajes tipados (`enum XxxMessage`), que la vista traduce con textos de `Localizable.xcstrings`. El usuario nunca ve un mensaje técnico (`error.localizedDescription`, `String(describing: error)`).
