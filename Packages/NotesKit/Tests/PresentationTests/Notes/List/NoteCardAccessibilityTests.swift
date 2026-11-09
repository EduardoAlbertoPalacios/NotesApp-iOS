import Domain
import Testing
@testable import Presentation

struct NoteCardAccessibilityTests {
    @Test("given pinned note with tasks when building label then reads title, Fijada, each task status and date")
    func pinnedNoteWithTasks() {
        let note = Note.fixture(
            title: "La compra",
            blocks: [
                .task(NoteTask(text: "Tomates")),
                .task(NoteTask(text: "Pan integral", isDone: true)),
            ],
            isPinned: true
        )

        let label = NoteCardAccessibility.label(for: note, dateText: "Hoy, 9:38")

        #expect(label == "La compra. Fijada. Tomates, pendiente. Pan integral, completada. Hoy, 9:38")
    }

    @Test("given unpinned text note when building label then reads title, text and date without Fijada")
    func unpinnedTextNote() {
        let note = Note.fixture(title: "Ideas sueltas", blocks: [.text("Un café y una libreta.")], isPinned: false)

        let label = NoteCardAccessibility.label(for: note, dateText: "Ayer")

        #expect(label == "Ideas sueltas. Un café y una libreta.. Ayer")
        #expect(!label.contains("Fijada"))
    }
}
