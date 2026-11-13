import Foundation

/// Fecha de última edición de una tarjeta (spec 001, RF-20 a RF-24).
struct NoteDateFormatter: Sendable {
    var calendar: Calendar
    var locale: Locale

    /// Textos en español, con el formato de 12/24 h que tenga configurado el dispositivo (RF-21).
    static func appLocale(device: Locale = .autoupdatingCurrent) -> Locale {
        var components = Locale.Components(identifier: "es")
        components.hourCycle = device.hourCycle
        return Locale(components: components)
    }

    init(calendar: Calendar = .autoupdatingCurrent, locale: Locale = NoteDateFormatter.appLocale()) {
        self.calendar = calendar
        self.locale = locale
    }

    func string(for date: Date, now: Date) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            let time = date.formatted(style(date: .omitted, time: .shortened))
            return String(localized: "Hoy, \(time)", bundle: .module)
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return String(localized: "Ayer", bundle: .module)
        }
        let dayMonth = style().day().month(.abbreviated)
        if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
            return date.formatted(dayMonth)
        }
        return date.formatted(dayMonth.year())
    }

    private func style(
        date: Date.FormatStyle.DateStyle? = nil,
        time: Date.FormatStyle.TimeStyle? = nil
    ) -> Date.FormatStyle {
        Date.FormatStyle(date: date, time: time, locale: locale, calendar: calendar, timeZone: calendar.timeZone)
    }
}
