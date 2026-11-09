import Domain
import Synchronization

final class FakeSettingsRepository: SettingsRepository {
    private let seeded: Mutex<Bool>

    init(hasSeededSampleNotes: Bool = false) {
        seeded = Mutex(hasSeededSampleNotes)
    }

    var hasSeededSampleNotes: Bool {
        seeded.withLock { $0 }
    }

    func markSampleNotesSeeded() {
        seeded.withLock { $0 = true }
    }
}
