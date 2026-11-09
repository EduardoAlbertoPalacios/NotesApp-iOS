import Foundation
import Testing
@testable import Domain

struct SampleNotesTests {
    private let notes = SampleNotes.make(now: .fixture)

    @Test("given a date when making sample notes then returns six notes in Figma order")
    func sixNotesInFigmaOrder() {
        #expect(notes.map(\.title) == [
            "Reunión de equipo",
            "La compra",
            "Ideas sueltas",
            "Escapada",
            "Para leer",
            "Una buena idea",
        ])
    }

    @Test("given sample notes when inspecting team meeting then it is the only pinned note and is aqua")
    func teamMeetingIsOnlyPinnedAndAqua() throws {
        let meeting = try #require(notes.first { $0.title == "Reunión de equipo" })

        #expect(meeting.isPinned)
        #expect(meeting.color == .aqua)
        #expect(notes.filter(\.isPinned).map(\.title) == ["Reunión de equipo"])
    }

    @Test("given sample notes when inspecting shopping list then has four tasks with only bread done")
    func shoppingListHasFourTasksWithBreadDone() throws {
        let shopping = try #require(notes.first { $0.title == "La compra" })
        let tasks = shopping.blocks.compactMap { block -> NoteTask? in
            guard case .task(let task) = block else { return nil }
            return task
        }

        #expect(shopping.blocks.count == 4)
        #expect(tasks.count == 4)
        #expect(tasks.filter(\.isDone).map(\.text) == ["Pan integral"])
    }

    @Test("given a date when making sample notes then every note has that date as last edit")
    func allNotesUseGivenDate() {
        #expect(notes.allSatisfy { $0.updatedAt == .fixture })
    }

    @Test("given sample notes when inspecting sequence then goes from zero to five in order")
    func sequenceGoesFromZeroToFive() {
        #expect(notes.map(\.sequence) == Array(0...5))
    }

    @Test("given sample notes when inspecting ids then all are distinct")
    func idsAreDistinct() {
        #expect(Set(notes.map(\.id)).count == notes.count)
    }
}
