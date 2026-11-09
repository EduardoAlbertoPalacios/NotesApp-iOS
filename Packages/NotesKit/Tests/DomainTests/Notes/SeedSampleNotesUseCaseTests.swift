import Common
import Foundation
import Testing
@testable import Domain

struct SeedSampleNotesUseCaseTests {
    private func makeSut(
        notes: FakeNoteRepository = FakeNoteRepository(),
        settings: FakeSettingsRepository = FakeSettingsRepository(),
        date: Date = .fixture
    ) -> SeedSampleNotesUseCase {
        SeedSampleNotesUseCase(notes: notes, settings: settings, dateProvider: FixedDateProvider(date))
    }

    private var sampleTitles: [String] {
        SampleNotes.make(now: .fixture).map(\.title)
    }

    @Test("given never seeded when seeding then saves the six sample notes in one batch")
    func savesSampleNotesOnce() async throws {
        let notes = FakeNoteRepository()

        try await makeSut(notes: notes)()

        #expect(notes.savedBatches.map { $0.map(\.title) } == [sampleTitles])
    }

    @Test("given never seeded when seeding succeeds then marks sample notes as seeded")
    func marksSeededAfterSaving() async throws {
        let settings = FakeSettingsRepository()

        try await makeSut(settings: settings)()

        #expect(settings.hasSeededSampleNotes)
    }

    @Test("given injected date when seeding then every sample note uses it as last edit")
    func usesDateProvider() async throws {
        let notes = FakeNoteRepository()
        let date = Date.fixture.addingTimeInterval(3_600)

        try await makeSut(notes: notes, date: date)()

        let saved = try #require(notes.savedBatches.first)
        #expect(saved.allSatisfy { $0.updatedAt == date })
    }

    @Test("given already seeded when seeding then saves nothing")
    func alreadySeededSavesNothing() async throws {
        let notes = FakeNoteRepository()
        let settings = FakeSettingsRepository(hasSeededSampleNotes: true)

        try await makeSut(notes: notes, settings: settings)()

        #expect(notes.savedBatches.isEmpty)
    }

    @Test("given seeding ran once when seeding again then does not save the samples twice")
    func secondSeedSavesNothing() async throws {
        let notes = FakeNoteRepository()
        let seed = makeSut(notes: notes, settings: FakeSettingsRepository())

        try await seed()
        try await seed()

        #expect(notes.savedBatches.count == 1)
    }

    @Test("given save fails when seeding then throws the repository error")
    func saveFailureThrows() async {
        let notes = FakeNoteRepository(saveFailure: .storageUnavailable)

        await #expect(throws: AppError.storageUnavailable) {
            try await makeSut(notes: notes)()
        }
    }

    @Test("given save fails when seeding then does not mark sample notes as seeded")
    func saveFailureDoesNotMarkSeeded() async {
        let notes = FakeNoteRepository(saveFailure: .storageUnavailable)
        let settings = FakeSettingsRepository()

        await #expect(throws: AppError.storageUnavailable) {
            try await makeSut(notes: notes, settings: settings)()
        }

        #expect(settings.hasSeededSampleNotes == false)
    }
}
