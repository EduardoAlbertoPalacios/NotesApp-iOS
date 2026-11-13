import Common
import Foundation

struct FixedDateProvider: DateProvider {
    let date: Date

    init(_ date: Date = .fixture) {
        self.date = date
    }

    func now() -> Date {
        date
    }
}
