# MEMORY.md — Estado del proyecto

> Registro breve (máx. ~50 líneas) del estado y las decisiones. Las reglas permanentes van en `CLAUDE.md`.
> No confundir con la memoria automática de Claude Code (`~/.claude/projects/.../memory/`).

_Última actualización: 2026-11-27_

## Estado actual

- La app muestra la pantalla "Mis notas" (spec 001). Compila y corre en el simulador `iPhone Duo`.
- `CLAUDE.md` define la arquitectura objetivo (Clean Architecture + MVI, paquete local `NotesKit` con `Presentation`, `Domain`, `Data`, `Common`).
- **Spec 001 aprobada (2026-11-09):** `docs/specs/001-listado-notas-cuadricula/spec.md`, pantalla "Mis notas" en cuadrícula (Figma `JyeMmyDAEO1Y52QnwKwgGH`, marcos "Inicio · Mis notas").
- **Specs 001 y 002 implementadas y fusionadas en `main`** (PR #1, 2026-11-13). Pendiente de la 001: decidir el orden de VoiceOver de las tarjetas (hoy sigue la posición vertical).
- **Spec 002 aprobada (2026-11-11):** `docs/specs/002-crear-editar-nota/`. Decisiones: color de nota nueva aguamarina, notas de ejemplo sin categoría.
- **Spec 003 (eliminar notas) implementada y fusionada en `main`** (PR #2, 2026-11-27): 201 pruebas unitarias + 31 de UI, `architecture-reviewer` sin violaciones y demo manual hecha. También se quitó el `catch` genérico del guardado automático del editor (spec 002). Pendiente: las pruebas de UI de "Deshacer" fallan a veces en ejecución paralela (el aviso de 5 s caduca antes del toque); propuesta: argumento de lanzamiento que alargue el aviso solo en pruebas de UI.
- **Spec 004 (buscar notas) terminada (2026-11-27)** en `feat/004-search-notes`: 293 pruebas unitarias + 41 de UI, `architecture-reviewer` sin violaciones y demo manual hecha. Basada en la spec de Android; los filtros siguen sin función. RF-30/RF-31 (restaurar la búsqueda con `@SceneStorage`) solo se comprueban a mano.
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

- Pruebas de UI con el aviso "Deshacer" (5 s): cada consulta de XCUITest tarda ~1 s; esperar el aviso nada más volver a la lista y agrupar comprobaciones en un `app.snapshot()`.
- `@SceneStorage` no se prueba con XCUITest: pasar a segundo plano y relanzar a veces restaura y a veces no (iOS no siempre guarda antes de que XCUITest termine la app).
- Un `TextField` dentro del `ScrollView` no suelta el foco con `.scrollDismissesKeyboard`: usar `@FocusState` + `.onScrollPhaseChange`. Su etiqueta tampoco llega a VoiceOver/XCUITest sin `.accessibilityLabel` explícito.
- Si las pruebas de UI se cuelgan ("unable to connect to deviceservice", "Timed out while loading Accessibility"): `xcrun simctl shutdown all`, arrancar `iPhone Duo` y ejecutar con `-parallel-testing-enabled NO`. `timeout` no existe en macOS.
- Swift 6 estricto en pruebas: no pasar un `AsyncStream.Iterator` como `inout` a un helper `async` (error de data race); llamar a `next()` en la propia prueba.
- No usar Room ni guías de Android para migraciones; usar `VersionedSchema` + `MigrationStage`.
- No apuntar a simuladores que no existen (`iPhone 16`/`iPhone 17`); el disponible es `iPhone Duo`.
- El runtime iOS 27.1 solo admite `iPhone Duo`: `simctl create` de un iPad falla con "Incompatible device". La demo y las pruebas de UI en iPad de la spec 001 no se pueden ejecutar por ahora.
- No editar `project.pbxproj` para agregar archivos (*synchronized groups*).
- El Figma MCP (plan Starter) tiene un límite de llamadas: si se agota, pedir al usuario el marco exportado como PNG.
- Lógica con espera (guardado automático): probar con `ManualClock` + `waitUntil` de `PresentationTests/Support`, nunca con esperas reales.
- Al editar `Localizable.xcstrings` con un script, insertar solo las claves nuevas: reescribir el JSON entero cambia el formato de las existentes.
- `-only-testing` de una sola prueba de Swift Testing lleva paréntesis: `'DomainTests/<Suite>/<funcion>()'`. Sin ellos `xcodebuild` ejecuta 0 pruebas y aun así dice `** TEST SUCCEEDED **`.
- `Date.FormatStyle` en `es` con 12 h separa "p. m." con U+202F (espacio fino de no separación), no con espacios normales: en pruebas compara con `\u{202F}`. Se acepta tal cual, sin normalizar.
