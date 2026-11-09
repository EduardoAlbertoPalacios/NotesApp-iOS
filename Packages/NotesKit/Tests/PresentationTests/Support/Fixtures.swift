import Domain
import Foundation

extension Date {
    /// 2026-11-09 10:00:00 UTC.
    static let fixture = Date(timeIntervalSince1970: 1_794_218_400)
}

extension Note {
    static func fixture(
        id: UUID = UUID(),
        title: String = "Título",
        blocks: [NoteBlock] = [.text("Contenido")],
        color: NoteColor = .yellow,
        isPinned: Bool = false,
        updatedAt: Date = .fixture,
        sequence: Int = 0
    ) -> Note {
        Note(
            id: id,
            title: title,
            blocks: blocks,
            color: color,
            isPinned: isPinned,
            updatedAt: updatedAt,
            sequence: sequence
        )
    }
}

extension Calendar {
    /// Gregoriano en UTC: las pruebas no dependen de la zona del simulador.
    static let fixtureUTC: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    func fixtureDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, _ second: Int = 0) -> Date? {
        date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second))
    }
}

extension Locale {
    /// Español con el ciclo de horas indicado, como el que arma `NoteDateFormatter.appLocale(device:)`.
    static func spanish(hourCycle: Locale.HourCycle) -> Locale {
        var components = Locale.Components(identifier: "es")
        components.hourCycle = hourCycle
        return Locale(components: components)
    }
}
