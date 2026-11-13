import Testing

/// Cede el actor principal hasta que `condition` se cumpla, para esperar tareas sin dormir.
/// Registra un fallo si no se cumple tras muchas cesiones.
@MainActor
func waitUntil(
    _ condition: () -> Bool,
    sourceLocation: SourceLocation = #_sourceLocation
) async {
    for _ in 0..<100_000 {
        if condition() { return }
        await Task.yield()
    }
    Issue.record("La condición no se cumplió", sourceLocation: sourceLocation)
}

/// Cede el actor principal varias veces para dar ocasión a tareas que no deberían hacer nada.
@MainActor
func yieldMany(_ times: Int = 1_000) async {
    for _ in 0..<times {
        await Task.yield()
    }
}
