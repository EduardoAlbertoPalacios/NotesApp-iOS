import Domain
import Foundation
import Testing

@testable import Presentation

struct NoteEditorStateTests {
    private let task = NoteBlock.task(NoteTask(text: "Leche"))

    @Test("given new note destination when building initial state then editor is empty and idle")
    func initialNewNote() {
        let now = Date.fixture

        let state = NoteEditorState.initial(for: .newNote, now: now)

        #expect(
            state
                == NoteEditorState(
                    title: "",
                    blocks: [.text("")],
                    category: nil,
                    isPinned: false,
                    headerDate: now,
                    saveStatus: .idle
                )
        )
        #expect(state.isDiscardDialogPresented == false)
    }

    @Test("given existing note when building initial state then shows its data, update date and saved status")
    func initialExistingNote() {
        let updatedAt = Date.fixture.addingTimeInterval(-86_400)
        let note = Note.fixture(
            title: "Compras",
            blocks: [.text("Lista")],
            category: .personal,
            isPinned: true,
            updatedAt: updatedAt
        )

        let state = NoteEditorState.initial(for: .note(note), now: .fixture)

        #expect(
            state
                == NoteEditorState(
                    title: "Compras",
                    blocks: [.text("Lista")],
                    category: .personal,
                    isPinned: true,
                    headerDate: updatedAt,
                    saveStatus: .saved
                )
        )
    }

    @Test("given existing note ending with tasks when building initial state then appends empty text block")
    func initialExistingNoteEndingWithTasks() {
        let note = Note.fixture(blocks: [.text("Intro"), task])

        let state = NoteEditorState.initial(for: .note(note), now: .fixture)

        #expect(state.blocks == [.text("Intro"), task, .text("")])
    }

    @Test("given existing note ending with text when building initial state then keeps blocks as they are")
    func initialExistingNoteEndingWithText() {
        let note = Note.fixture(blocks: [task, .text("Fin")])

        let state = NoteEditorState.initial(for: .note(note), now: .fixture)

        #expect(state.blocks == [task, .text("Fin")])
    }

    @Test("given no blocks when adding trailing text block then returns a single empty text block")
    func trailingTextBlockOnEmpty() {
        #expect(NoteEditorState.withTrailingTextBlock([]) == [.text("")])
    }

    @Test(
        "given title when checking emptiness then only an empty string counts as empty",
        arguments: [
            ("", true),
            ("Compras", false),
        ])
    func isTitleEmpty(title: String, expected: Bool) {
        var state = NoteEditorState.initial(for: .newNote, now: .fixture)

        state.title = title

        #expect(state.isTitleEmpty == expected)
    }

    @Test("given only empty text blocks when checking content then content is empty")
    func contentEmptyWithEmptyTextBlocks() {
        var state = NoteEditorState.initial(for: .newNote, now: .fixture)

        state.blocks = [.text(""), .text("")]

        #expect(state.isContentEmpty)
    }

    @Test("given written text when checking content then content is not empty")
    func contentNotEmptyWithText() {
        var state = NoteEditorState.initial(for: .newNote, now: .fixture)

        state.blocks = [.text("Hola")]

        #expect(state.isContentEmpty == false)
    }

    @Test("given a task and empty text when checking content then content is not empty")
    func contentNotEmptyWithTask() {
        var state = NoteEditorState.initial(for: .newNote, now: .fixture)

        state.blocks = [task, .text("")]

        #expect(state.isContentEmpty == false)
    }
}
