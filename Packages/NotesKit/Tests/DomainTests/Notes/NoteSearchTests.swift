import Foundation
import Testing
@testable import Domain

struct NoteSearchTests {
    // MARK: - Mayúsculas y minúsculas (RF-8)

    @Test("given lowercase title when searching uppercase then matches")
    func uppercaseQueryMatchesLowercaseText() {
        let note = Note.fixture(title: "lista de compras", blocks: [])

        #expect(NoteSearch.matches(note, query: "COMPRAS"))
    }

    @Test("given uppercase title when searching lowercase then matches")
    func lowercaseQueryMatchesUppercaseText() {
        let note = Note.fixture(title: "LISTA DE COMPRAS", blocks: [])

        #expect(NoteSearch.matches(note, query: "compras"))
    }

    @Test("given text with lowercase ñ when searching with uppercase Ñ then matches")
    func uppercaseEnyeMatchesLowercaseEnye() {
        let note = Note.fixture(title: "Metas del año", blocks: [])

        #expect(NoteSearch.matches(note, query: "AÑO"))
    }

    @Test("given text with uppercase Ñ when searching with lowercase ñ then matches")
    func lowercaseEnyeMatchesUppercaseEnye() {
        let note = Note.fixture(title: "METAS DEL AÑO", blocks: [])

        #expect(NoteSearch.matches(note, query: "año"))
    }

    // MARK: - Tildes y diéresis (RF-9)

    @Test("given text with accent when searching without accent then matches")
    func queryWithoutAccentMatchesAccentedText() {
        let note = Note.fixture(title: "Reunión del lunes", blocks: [])

        #expect(NoteSearch.matches(note, query: "reunion"))
    }

    @Test("given text with diaeresis when searching without it then matches")
    func queryWithoutDiaeresisMatchesText() {
        let note = Note.fixture(title: "Foto del pingüino", blocks: [])

        #expect(NoteSearch.matches(note, query: "pinguino"))
    }

    @Test("given text without accent when searching with accent then matches")
    func accentedQueryMatchesTextWithoutAccent() {
        let note = Note.fixture(title: "Reunion del lunes", blocks: [])

        #expect(NoteSearch.matches(note, query: "reunión"))
    }

    @Test("given text without diaeresis when searching with it then matches")
    func queryWithDiaeresisMatchesTextWithoutIt() {
        let note = Note.fixture(title: "Foto del pinguino", blocks: [])

        #expect(NoteSearch.matches(note, query: "pingüino"))
    }

    @Test("given uppercase accented text when searching lowercase without accents then matches")
    func caseAndAccentsAreIgnoredTogether() {
        let note = Note.fixture(title: "PINGÜINO EN LA REUNIÓN", blocks: [])

        #expect(NoteSearch.matches(note, query: "pinguino reunion"))
    }

    // MARK: - La ñ es distinta de la n (RF-10)

    @Test("given text with año when searching ano then does not match")
    func anoDoesNotMatchAnio() {
        let note = Note.fixture(title: "Metas del año", blocks: [])

        #expect(!NoteSearch.matches(note, query: "ano"))
    }

    @Test("given text with ano when searching año then does not match")
    func anioDoesNotMatchAno() {
        let note = Note.fixture(title: "Plano de la casa", blocks: [])

        #expect(!NoteSearch.matches(note, query: "año"))
    }

    @Test("given text with decomposed ñ when searching composed ñ then matches")
    func decomposedEnyeInTextMatchesComposedQuery() {
        let note = Note.fixture(title: "Metas del an\u{0303}o", blocks: [])

        #expect(NoteSearch.matches(note, query: "año"))
    }

    @Test("given text with composed ñ when searching decomposed ñ then matches")
    func decomposedEnyeInQueryMatchesComposedText() {
        let note = Note.fixture(title: "Metas del año", blocks: [])

        #expect(NoteSearch.matches(note, query: "an\u{0303}o"))
    }

    @Test("given text with decomposed ñ when searching ano then does not match")
    func decomposedEnyeIsNotN() {
        let note = Note.fixture(title: "Metas del an\u{0303}o", blocks: [])

        #expect(!NoteSearch.matches(note, query: "ano"))
    }

    @Test("given decomposed ñ when normalizing then equals normalized composed ñ")
    func decomposedEnyeNormalizesLikeComposed() {
        #expect(NoteSearch.words(in: "AN\u{0303}O") == NoteSearch.words(in: "año"))
    }

    // MARK: - Parte de palabra (RF-11)

    @Test("given text with reunión when searching reun then matches")
    func partialWordMatches() {
        let note = Note.fixture(title: "Reunión del lunes", blocks: [])

        #expect(NoteSearch.matches(note, query: "reun"))
    }

    @Test("given text with reunión when searching middle of word then matches")
    func middleOfWordMatches() {
        let note = Note.fixture(title: "Reunión del lunes", blocks: [])

        #expect(NoteSearch.matches(note, query: "union"))
    }

    // MARK: - Varias palabras (RF-12)

    @Test("given title with all words when searching in another order then matches")
    func wordsMatchInAnyOrder() {
        let note = Note.fixture(title: "Comprar leche y pan", blocks: [])

        #expect(NoteSearch.matches(note, query: "pan leche"))
    }

    @Test("given words split between title and content when searching both then matches")
    func wordsMatchAcrossTitleAndContent() {
        let note = Note.fixture(title: "Viaje", blocks: [.text("Reservar hotel en Lima")])

        #expect(NoteSearch.matches(note, query: "hotel viaje"))
    }

    @Test("given note missing one of the words when searching then does not match")
    func missingWordDoesNotMatch() {
        let note = Note.fixture(title: "Viaje", blocks: [.text("Reservar hotel en Lima")])

        #expect(!NoteSearch.matches(note, query: "viaje vuelo"))
    }

    // MARK: - Tareas como contenido (RF-6)

    @Test("given pending task with word when searching then matches")
    func pendingTaskTextMatches() {
        let note = Note.fixture(title: "Pendientes", blocks: [.task(NoteTask(text: "Llamar al dentista"))])

        #expect(NoteSearch.matches(note, query: "dentista"))
    }

    @Test("given completed task with word when searching then matches")
    func completedTaskTextMatches() {
        let note = Note.fixture(
            title: "Pendientes",
            blocks: [.task(NoteTask(text: "Pagar la luz", isDone: true))]
        )

        #expect(NoteSearch.matches(note, query: "luz"))
    }

    @Test("given words split between text block and tasks when searching then matches")
    func wordsMatchAcrossTextAndTasks() {
        let note = Note.fixture(
            title: "Semana",
            blocks: [
                .text("Organizar mudanza"),
                .task(NoteTask(text: "Cajas", isDone: true)),
                .task(NoteTask(text: "Cinta")),
            ]
        )

        #expect(NoteSearch.matches(note, query: "mudanza cajas cinta"))
    }

    // MARK: - Categoría, color y fecha no cuentan (RF-7)

    @Test("given work category without the word in text when searching Trabajo then does not match")
    func categoryNameDoesNotMatch() {
        let note = Note.fixture(title: "Informe", blocks: [.text("Enviar el lunes")], category: .work)

        #expect(!NoteSearch.matches(note, query: "Trabajo"))
        #expect(!NoteSearch.matches(note, query: "work"))
    }

    @Test("given personal category without the word in text when searching Personal then does not match")
    func personalCategoryNameDoesNotMatch() {
        let note = Note.fixture(title: "Gimnasio", blocks: [.text("Martes y jueves")], category: .personal)

        #expect(!NoteSearch.matches(note, query: "personal"))
    }

    @Test("given yellow note without the word in text when searching color name then does not match")
    func colorNameDoesNotMatch() {
        let note = Note.fixture(title: "Ideas", blocks: [.text("Para el blog")], color: .yellow)

        #expect(!NoteSearch.matches(note, query: "amarillo"))
        #expect(!NoteSearch.matches(note, query: "yellow"))
    }

    @Test("given note edited in 2026 without the year in text when searching year then does not match")
    func dateDoesNotMatch() {
        let note = Note.fixture(title: "Ideas", blocks: [.text("Para el blog")], updatedAt: .fixture)

        #expect(!NoteSearch.matches(note, query: "2026"))
    }

    // MARK: - Espacios (RF-4, RF-13)

    @Test("given query with outer and repeated spaces when extracting words then ignores them")
    func wordsIgnoreOuterAndRepeatedSpaces() {
        #expect(NoteSearch.words(in: "   leche    pan  ") == ["leche", "pan"])
    }

    @Test("given query with tabs and newlines when extracting words then ignores them")
    func wordsIgnoreOtherWhitespace() {
        #expect(NoteSearch.words(in: "\tleche\n pan ") == ["leche", "pan"])
    }

    @Test("given empty query when extracting words then returns no words")
    func emptyQueryHasNoWords() {
        #expect(NoteSearch.words(in: "").isEmpty)
    }

    @Test("given blank query when extracting words then returns no words")
    func blankQueryHasNoWords() {
        #expect(NoteSearch.words(in: "    ").isEmpty)
    }

    @Test("given query with outer and repeated spaces when matching then behaves like trimmed query")
    func spacesAreIgnoredWhenMatching() {
        let note = Note.fixture(title: "Comprar leche y pan", blocks: [])

        #expect(NoteSearch.matches(note, query: "   leche    pan  "))
    }

    @Test("given blank query when filtering then returns all notes unchanged")
    func blankQueryReturnsAllNotes() {
        let notes = [
            Note.fixture(title: "Uno", sequence: 0),
            Note.fixture(title: "Dos", sequence: 1),
            Note.fixture(title: "Tres", sequence: 2),
        ]

        #expect(NoteSearch.filter(notes, query: "   ") == notes)
    }

    @Test("given empty query when filtering then returns all notes unchanged")
    func emptyQueryReturnsAllNotes() {
        let notes = [Note.fixture(title: "Uno"), Note.fixture(title: "Dos")]

        #expect(NoteSearch.filter(notes, query: "") == notes)
    }

    // MARK: - Signos, números y emojis

    @Test("given text with symbols when searching symbols then matches")
    func symbolsAreSearchedAsIs() {
        let note = Note.fixture(title: "Curso de C++", blocks: [.text("Costo: $100 (50% dto.)")])

        #expect(NoteSearch.matches(note, query: "c++"))
        #expect(NoteSearch.matches(note, query: "$100"))
        #expect(NoteSearch.matches(note, query: "50%"))
    }

    @Test("given text with numbers when searching number then matches")
    func numbersAreSearchedAsIs() {
        let note = Note.fixture(title: "Teléfono", blocks: [.text("555-1234")])

        #expect(NoteSearch.matches(note, query: "1234"))
    }

    @Test("given text with emojis when searching emoji then matches")
    func emojisAreSearchedAsIs() {
        let note = Note.fixture(title: "Fiesta 🎉", blocks: [.text("Me encanta ❤️ y 👍🏽")])

        #expect(NoteSearch.matches(note, query: "🎉"))
        #expect(NoteSearch.matches(note, query: "❤️"))
        #expect(NoteSearch.matches(note, query: "👍🏽"))
    }

    @Test("given text without the symbol when searching symbol then does not match")
    func absentSymbolDoesNotMatch() {
        let note = Note.fixture(title: "Fiesta", blocks: [.text("Sábado")])

        #expect(!NoteSearch.matches(note, query: "🎉"))
        #expect(!NoteSearch.matches(note, query: "#"))
    }

    // MARK: - Texto muy largo

    @Test("given a long paragraph not present in any note when filtering then returns no notes")
    func longQueryDoesNotMatch() {
        let paragraph = String(
            repeating: "Este es un párrafo muy largo que nadie escribió en ninguna nota, con muchas palabras. ",
            count: 20
        )
        let notes = [
            Note.fixture(title: "Reunión", blocks: [.text("Hablar del presupuesto")]),
            Note.fixture(title: "Compras", blocks: [.task(NoteTask(text: "Leche"))]),
        ]

        #expect(NoteSearch.filter(notes, query: paragraph).isEmpty)
    }

    // MARK: - Campos vacíos (RF-5)

    @Test("given note without title but with content when searching content then matches")
    func noteWithoutTitleMatchesByContent() {
        let note = Note.fixture(title: "", blocks: [.text("Recordar regar las plantas")])

        #expect(NoteSearch.matches(note, query: "plantas"))
    }

    @Test("given note with title and no blocks when searching title then matches")
    func noteWithoutBlocksMatchesByTitle() {
        let note = Note.fixture(title: "Plantas", blocks: [])

        #expect(NoteSearch.matches(note, query: "plantas"))
    }

    // MARK: - Límite entre campos

    @Test("given word only formed by joining title end and content start when searching then does not match")
    func wordAcrossTitleAndContentBoundaryDoesNotMatch() {
        let note = Note.fixture(title: "abc", blocks: [.text("def")])

        #expect(!NoteSearch.matches(note, query: "cd"))
    }

    @Test("given word only formed by joining two blocks when searching then does not match")
    func wordAcrossBlocksBoundaryDoesNotMatch() {
        let note = Note.fixture(title: "Nota", blocks: [.text("abc"), .task(NoteTask(text: "def"))])

        #expect(!NoteSearch.matches(note, query: "cd"))
    }

    // MARK: - Filtrado y orden (RF-1, RF-14)

    @Test("given several notes when filtering then returns only matches in input order")
    func filterKeepsInputOrder() {
        let third = Note.fixture(title: "Reunión de equipo", sequence: 2)
        let other = Note.fixture(title: "Compras", sequence: 1)
        let first = Note.fixture(title: "Notas", blocks: [.text("Preparar la reunion")], sequence: 0)
        let second = Note.fixture(title: "Pendientes", blocks: [.task(NoteTask(text: "Agendar REUNIÓN"))], sequence: 3)

        let result = NoteSearch.filter([third, other, first, second], query: "reunion")

        #expect(result == [third, first, second])
    }

    @Test("given no note matching when filtering then returns empty list")
    func filterWithoutMatchesReturnsEmpty() {
        let notes = [Note.fixture(title: "Uno"), Note.fixture(title: "Dos")]

        #expect(NoteSearch.filter(notes, query: "tres").isEmpty)
    }
}
