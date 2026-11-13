import Foundation
import Testing
@testable import Presentation

struct NoteDateFormatterTests {
    private let calendar = Calendar.fixtureUTC

    private func makeFormatter(hourCycle: Locale.HourCycle = .zeroToTwentyThree) -> NoteDateFormatter {
        NoteDateFormatter(calendar: calendar, locale: .spanish(hourCycle: hourCycle))
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, _ second: Int = 0) throws -> Date {
        try #require(calendar.fixtureDate(year, month, day, hour, minute, second))
    }

    @Test("given edit today with 24-hour clock when formatting then shows Hoy and the time")
    func todayIn24Hours() throws {
        let now = try date(2026, 11, 9, 18, 0)

        let text = makeFormatter(hourCycle: .zeroToTwentyThree).string(for: try date(2026, 11, 9, 9, 38), now: now)

        #expect(text == "Hoy, 9:38")
    }

    @Test("given afternoon edit today with 24-hour clock when formatting then shows the hour past 12")
    func todayAfternoonIn24Hours() throws {
        let now = try date(2026, 11, 9, 23, 0)

        let text = makeFormatter(hourCycle: .zeroToTwentyThree).string(for: try date(2026, 11, 9, 21, 38), now: now)

        #expect(text == "Hoy, 21:38")
    }

    @Test("given afternoon edit today with 12-hour clock when formatting then shows Hoy and the 12-hour time")
    func todayIn12Hours() throws {
        let now = try date(2026, 11, 9, 23, 0)

        let text = makeFormatter(hourCycle: .oneToTwelve).string(for: try date(2026, 11, 9, 21, 38), now: now)

        // Foundation separa "p. m." con U+202F (espacio fino de no separación): se ve como un espacio
        // y evita que el sufijo se parta en dos líneas. La spec no fija los espacios; se acepta su formato.
        #expect(text == "Hoy, 9:38\u{202F}p.\u{202F}m.")
    }

    @Test("given edit yesterday when formatting then shows Ayer")
    func yesterday() throws {
        let now = try date(2026, 11, 9, 10, 0)

        let text = makeFormatter().string(for: try date(2026, 11, 8, 9, 38), now: now)

        #expect(text == "Ayer")
    }

    @Test("given edit earlier this year when formatting then shows day and abbreviated month")
    func earlierThisYear() throws {
        let now = try date(2026, 11, 9, 10, 0)

        let text = makeFormatter().string(for: try date(2026, 10, 4, 12, 0), now: now)

        #expect(text == "4 oct")
    }

    @Test("given edit two days ago when formatting then shows the date, not Ayer")
    func twoDaysAgo() throws {
        let now = try date(2026, 11, 9, 0, 30)

        let text = makeFormatter().string(for: try date(2026, 11, 7, 23, 59), now: now)

        #expect(text == "7 nov")
    }

    @Test("given edit in a previous year when formatting then shows day, abbreviated month and year")
    func previousYear() throws {
        let now = try date(2026, 11, 9, 10, 0)

        let text = makeFormatter().string(for: try date(2025, 10, 4, 12, 0), now: now)

        #expect(text == "4 oct 2025")
    }

    @Test("given edit on December 31 and now January 1 when formatting then shows Ayer")
    func yesterdayAcrossYearBoundary() throws {
        let now = try date(2027, 1, 1, 8, 0)

        let text = makeFormatter().string(for: try date(2026, 12, 31, 22, 0), now: now)

        #expect(text == "Ayer")
    }

    @Test("given edit at 23:59 when now is just before midnight then shows Hoy")
    func justBeforeMidnight() throws {
        let edited = try date(2026, 11, 9, 23, 59)

        let text = makeFormatter().string(for: edited, now: try date(2026, 11, 9, 23, 59, 59))

        #expect(text == "Hoy, 23:59")
    }

    @Test("given edit at 23:59 when now is just after midnight then shows Ayer")
    func justAfterMidnight() throws {
        let edited = try date(2026, 11, 9, 23, 59)

        let text = makeFormatter().string(for: edited, now: try date(2026, 11, 10, 0, 0, 1))

        #expect(text == "Ayer")
    }

    @Test(
        "given device locale with an hour cycle when building app locale then keeps that hour cycle in Spanish",
        arguments: [Locale.HourCycle.zeroToTwentyThree, .oneToTwelve]
    )
    func appLocaleKeepsDeviceHourCycle(hourCycle: Locale.HourCycle) {
        var device = Locale.Components(identifier: "en_US")
        device.hourCycle = hourCycle

        let locale = NoteDateFormatter.appLocale(device: Locale(components: device))

        #expect(locale.hourCycle == hourCycle)
        #expect(locale.language.languageCode == .spanish)
    }
}
