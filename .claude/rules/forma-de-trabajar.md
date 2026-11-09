## Forma de trabajar
- Antes de escribir código para una tarea que toque más de un módulo (`NotesApp`, `Presentation`, `Domain`, `Data`, `Common`), propón un plan breve y espera mi aprobación.
- Haz solo lo que se pidió: no refactorices, renombres ni reformatees código ajeno a la tarea. Si ves algo mejorable, menciónalo al final.
- Si una tarea es ambigua o hay más de una forma razonable de resolverla, pregunta antes de elegir.
- Nunca des una tarea por terminada si el proyecto no compila o hay pruebas fallando; si no pudiste verificar algo, dilo explícitamente.

## Pruebas con agentes
- No escribas las pruebas directamente: delega en el agente `test-writer` (`.claude/agents/test-writer.md`).
- **`test-writer`** escribe las pruebas de cada tipo o pantalla nueva o modificada:
  - **Unitarias** con Swift Testing: casos de uso, ViewModels, repositorios, mappers, `NoteLocalDataSource` y migraciones de SwiftData.
  - **De UI** con XCUITest en `NotesAppUITests`: los flujos de cada `XxxScreen`, lanzando la app con `-UITesting`.
- Los `#Preview` por estado de cada `XxxScreen` no son pruebas: los escribe quien implementa la pantalla.
- No uses el agente `android-unit-test-writer` en este repo: es para Kotlin/Android.
