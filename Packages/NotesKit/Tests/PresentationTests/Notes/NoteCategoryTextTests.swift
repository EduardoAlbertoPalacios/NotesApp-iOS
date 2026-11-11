import Domain
import Testing

@testable import Presentation

struct NoteCategoryTextTests {
    @Test("given work category when reading texts then shows work title and summary")
    func workTexts() {
        #expect(NoteCategory.work.title == "Trabajo")
        #expect(NoteCategory.work.summary == "Proyectos, reuniones y tareas")
    }

    @Test("given personal category when reading texts then shows personal title and summary")
    func personalTexts() {
        #expect(NoteCategory.personal.title == "Personal")
        #expect(NoteCategory.personal.summary == "Recordatorios y vida diaria")
    }
}
