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

    // MARK: - Búsqueda (spec 004)

    @Test("given zero results when building results text then uses plural")
    func resultsZero() {
        #expect(NoteListStrings.results(0) == "0 resultados")
    }

    @Test("given one result when building results text then uses singular")
    func resultsSingular() {
        #expect(NoteListStrings.results(1) == "1 resultado")
    }

    @Test("given three results when building results text then uses plural")
    func resultsPlural() {
        #expect(NoteListStrings.results(3) == "3 resultados")
    }

    @Test("given search text with outer spaces when building no matches text then quotes it trimmed")
    func noMatchesTrimsText() {
        #expect(NoteListStrings.noMatches("  hola ") == "No hay notas que coincidan con «hola»")
    }

    @Test("given results announcement when building its text then is the results count")
    func announcementOfResults() {
        #expect(NoteListStrings.announcement(.results(3)) == "3 resultados")
        #expect(NoteListStrings.announcement(.results(1)) == "1 resultado")
    }

    @Test("given no matches announcement when building its text then is the no matches message")
    func announcementOfNoMatches() {
        #expect(NoteListStrings.announcement(.noMatches("hola")) == "No hay notas que coincidan con «hola»")
    }
}
