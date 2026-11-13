import Foundation
import Testing
@testable import Domain

struct NoteOrderingTests {
    private let older = Date.fixture
    private let newer = Date.fixture.addingTimeInterval(60)

    @Test("given no notes when sorting then returns empty list")
    func emptyListStaysEmpty() {
        #expect(NoteOrdering.sorted([]).isEmpty)
    }

    @Test("given older pinned note and newer unpinned note when sorting then pinned goes first")
    func pinnedGoesBeforeUnpinned() {
        let unpinned = Note.fixture(title: "Suelta", isPinned: false, updatedAt: newer)
        let pinned = Note.fixture(title: "Fijada", isPinned: true, updatedAt: older)

        let sorted = NoteOrdering.sorted([unpinned, pinned])

        #expect(sorted == [pinned, unpinned])
    }

    @Test("given several pinned notes when sorting then they go by last edit descending")
    func pinnedSortedByUpdatedAtDescending() {
        let oldPinned = Note.fixture(title: "Fijada antigua", isPinned: true, updatedAt: older, sequence: 0)
        let newPinned = Note.fixture(title: "Fijada reciente", isPinned: true, updatedAt: newer, sequence: 1)

        let sorted = NoteOrdering.sorted([oldPinned, newPinned])

        #expect(sorted == [newPinned, oldPinned])
    }

    @Test("given several unpinned notes when sorting then they go by last edit descending")
    func unpinnedSortedByUpdatedAtDescending() {
        let oldNote = Note.fixture(title: "Antigua", updatedAt: older, sequence: 0)
        let newNote = Note.fixture(title: "Reciente", updatedAt: newer, sequence: 1)

        let sorted = NoteOrdering.sorted([oldNote, newNote])

        #expect(sorted == [newNote, oldNote])
    }

    @Test("given notes with same last edit when sorting then lower sequence goes first")
    func sameDateSortedBySequenceAscending() {
        let second = Note.fixture(title: "Segunda", updatedAt: older, sequence: 1)
        let third = Note.fixture(title: "Tercera", updatedAt: older, sequence: 2)
        let first = Note.fixture(title: "Primera", updatedAt: older, sequence: 0)

        let sorted = NoteOrdering.sorted([third, first, second])

        #expect(sorted == [first, second, third])
    }

    @Test("given newer note with higher sequence when sorting then date wins over sequence")
    func dateTakesPrecedenceOverSequence() {
        let created = Note.fixture(title: "Creada antes", updatedAt: older, sequence: 0)
        let edited = Note.fixture(title: "Editada después", updatedAt: newer, sequence: 5)

        let sorted = NoteOrdering.sorted([created, edited])

        #expect(sorted == [edited, created])
    }

    @Test("given mixed notes when sorting then pinned group by date, then unpinned group by date and sequence")
    func mixedNotesFollowAllRules() {
        let pinnedOld = Note.fixture(title: "F1", isPinned: true, updatedAt: older, sequence: 0)
        let pinnedNew = Note.fixture(title: "F2", isPinned: true, updatedAt: newer, sequence: 1)
        let unpinnedNew = Note.fixture(title: "S1", updatedAt: newer, sequence: 2)
        let unpinnedOldA = Note.fixture(title: "S2", updatedAt: older, sequence: 3)
        let unpinnedOldB = Note.fixture(title: "S3", updatedAt: older, sequence: 4)

        let sorted = NoteOrdering.sorted([unpinnedOldB, pinnedOld, unpinnedOldA, unpinnedNew, pinnedNew])

        #expect(sorted == [pinnedNew, pinnedOld, unpinnedNew, unpinnedOldA, unpinnedOldB])
    }

    @Test("given shuffled sample notes with same date when sorting then follows Figma order")
    func sampleNotesSortedInFigmaOrder() {
        let samples = SampleNotes.make(now: .fixture)

        let sorted = NoteOrdering.sorted(samples.reversed())

        #expect(sorted == samples)
    }
}
