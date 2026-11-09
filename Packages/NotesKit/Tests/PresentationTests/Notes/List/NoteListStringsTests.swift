import Testing
@testable import Presentation

struct NoteListStringsTests {
    @Test("given six notes when building counter then uses plural")
    func counterPlural() {
        #expect(NoteListStrings.counter(6) == "6 notas · un espacio para tus ideas")
    }

    @Test("given one note when building counter then uses singular")
    func counterSingular() {
        #expect(NoteListStrings.counter(1) == "1 nota · un espacio para tus ideas")
    }
}
