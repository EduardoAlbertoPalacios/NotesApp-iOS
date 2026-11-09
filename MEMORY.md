# MEMORY.md — Estado del proyecto

> Registro breve (máx. ~50 líneas) del estado y las decisiones. Las reglas permanentes van en `CLAUDE.md`.
> No confundir con la memoria automática de Claude Code (`~/.claude/projects/.../memory/`).

_Última actualización: 2026-11-09_

## Estado actual

- El repo sigue siendo la plantilla de Xcode: `NotesApp/NotesAppApp.swift` + `ContentView.swift`. Compila en el simulador `iPhone Duo`.
- `CLAUDE.md` define la arquitectura objetivo (Clean Architecture + MVI, paquete local `NotesKit` con `Presentation`, `Domain`, `Data`, `Common`).
- **Spec 001 aprobada (2026-11-09):** `docs/specs/001-listado-notas-cuadricula/spec.md`, pantalla "Mis notas" en cuadrícula (Figma `JyeMmyDAEO1Y52QnwKwgGH`, marcos "Inicio · Mis notas"). Siguiente paso: plan de implementación.
- **Plan 001 aprobado; paso 0 en curso:** `Packages/NotesKit` creado (targets y pruebas con placeholders, compila). Falta enlazarlo en Xcode y crear `NotesAppUITests`.
- **Pendiente de crear:** `docs/constitution.md`.

## Decisiones

- **El documento se ajusta al proyecto, no al revés:** iOS 27.0 como mínimo y Swift 5 + `MainActor` por defecto en el target de la app. Los targets de `NotesKit` usan el modo Swift 6 estricto que trae `swift-tools-version` 6.x.
  _Por qué:_ es la configuración que ya tenía el `.xcodeproj`; se evita migrar el target de la app.
- **Efectos MVI con `func effects()`, que crea un stream nuevo por suscripción**, en lugar de un `let effects` creado en el `init`.
  _Por qué:_ un `AsyncStream` se cierra para siempre cuando se cancela el `.task` que lo consume (por ejemplo al hacer push de otra pantalla), y después ya no llegan efectos.
- **Pruebas del paquete con `xcodebuild test` en simulador**, no con `swift test`.
  _Por qué:_ los targets son iOS 27 y `swift test` compila para macOS.
- **Helpers y fakes de pruebas en `Support/` dentro de cada target de pruebas**, no en `Common`.
- **Errores esperables con typed throws** (`async throws(SaveNoteError)`), no con `Result`.
  _Por qué:_ en Swift el tipo de error queda en la firma y el compilador obliga a manejarlo; encaja con "escrituras `async throws`" ya documentado.
- **Persistencia solo con SwiftData.** La skill `room-migration` (Android) está desactivada en `.claude/settings.json`.

## Errores a evitar

- No usar Room ni guías de Android para migraciones; usar `VersionedSchema` + `MigrationStage`.
- No apuntar a simuladores que no existen (`iPhone 16`/`iPhone 17`); el disponible es `iPhone Duo`.
- El runtime iOS 27.1 solo admite `iPhone Duo`: `simctl create` de un iPad falla con "Incompatible device". La demo y las pruebas de UI en iPad de la spec 001 no se pueden ejecutar por ahora.
- No editar `project.pbxproj` para agregar archivos (*synchronized groups*).
- `-only-testing` de una sola prueba de Swift Testing lleva paréntesis: `'DomainTests/<Suite>/<funcion>()'`. Sin ellos `xcodebuild` ejecuta 0 pruebas y aun así dice `** TEST SUCCEEDED **`.
- `Date.FormatStyle` en `es` con 12 h separa "p. m." con U+202F (espacio fino de no separación), no con espacios normales: en pruebas compara con `\u{202F}`. Se acepta tal cual, sin normalizar.
