import Foundation

/// Las seis notas de ejemplo del diseño (spec 001, RF-25 y RF-26).
///
/// Son datos que se guardan una sola vez, no textos de interfaz: por eso van en español
/// en el código y no en el String Catalog (decisión del plan 001).
public enum SampleNotes {
    /// Todas comparten `updatedAt = now`; `sequence` (0…5) conserva el orden del Figma.
    public static func make(now: Date) -> [Note] {
        [
            Note(
                title: "Reunión de equipo",
                blocks: [.text("Nuevo lanzamiento:\n• Inicio más sencillo\n• Textos claros\n• Prototipo el viernes")],
                color: .aqua,
                isPinned: true,
                updatedAt: now,
                sequence: 0
            ),
            Note(
                title: "La compra",
                blocks: [
                    .task(NoteTask(text: "Tomates")),
                    .task(NoteTask(text: "Leche de avena")),
                    .task(NoteTask(text: "Pan integral", isDone: true)),
                    .task(NoteTask(text: "Café")),
                ],
                color: .pink,
                updatedAt: now,
                sequence: 1
            ),
            Note(
                title: "Ideas sueltas",
                blocks: [.text("Un café, una libreta y tiempo para crear.")],
                color: .yellow,
                updatedAt: now,
                sequence: 2
            ),
            Note(
                title: "Escapada",
                blocks: [.text("La sierra nos espera.\n\nLlevar la cámara y desconectar.")],
                color: .lavender,
                updatedAt: now,
                sequence: 3
            ),
            Note(
                title: "Para leer",
                blocks: [.text("Hábitos atómicos")],
                color: .mint,
                updatedAt: now,
                sequence: 4
            ),
            Note(
                title: "Una buena idea",
                blocks: [.text("Hacer más de lo que me hace bien.")],
                color: .peach,
                updatedAt: now,
                sequence: 5
            ),
        ]
    }
}
