import Foundation

/// A gap expressed the way a calendar counts it, rather than in raw days.
struct HJSpan: Equatable {
    var years: Int
    var months: Int
    var days: Int

    var isZero: Bool { years == 0 && months == 0 && days == 0 }

    /// "46 years, 3 months, 24 days" — with the empty parts dropped.
    var phrase: String {
        if isZero { return "0 days" }
        var parts: [String] = []
        if years != 0 { parts.append(HJFormatter.plural(years, "year", "years")) }
        if months != 0 { parts.append(HJFormatter.plural(months, "month", "months")) }
        if days != 0 { parts.append(HJFormatter.plural(days, "day", "days")) }
        return parts.joined(separator: ", ")
    }

    /// "46y 3m 24d" for tight rows.
    var compact: String {
        "\(years)y \(months)m \(days)d"
    }
}

/// Calendar-aware differences.
///
/// Counting whole months by subtracting fields and then borrowing a month's length is the
/// obvious way to do this, and it is wrong: from 31 January to 1 March the borrowed month
/// is February, which is shorter than the day being carried, and the day count comes out
/// negative. Instead the whole months are found by advancing the start date until one more
/// month would overshoot, and the remainder is then a plain difference of day numbers. That
/// makes every component non-negative and makes the answer reconstruct exactly.
enum HJSpanMath {

    // MARK: Hijri

    /// The start date advanced by whole months, with the day pulled back into a shorter
    /// month where it has to be.
    private static func hijriAdvanced(_ start: HJHijriDate, byMonths months: Int) -> Int {
        var year = start.year + months / 12
        var month = start.month + months % 12
        if month > 12 { month -= 12; year += 1 }
        year = max(HJCalendar.minHijriYear, min(HJCalendar.maxHijriYear, year))
        let length = HJCalendar.hijriMonthLength(year: year, month: month)
        return HJCalendar.jdn(fromHijri: HJHijriDate(year: year,
                                                     month: month,
                                                     day: min(start.day, length)))
    }

    static func hijriSpan(from start: HJHijriDate, to end: HJHijriDate) -> HJSpan {
        let startJDN = HJCalendar.jdn(fromHijri: start)
        let endJDN = HJCalendar.jdn(fromHijri: end)
        guard endJDN > startJDN else { return HJSpan(years: 0, months: 0, days: 0) }

        let cap = (HJCalendar.maxHijriYear - HJCalendar.minHijriYear + 2) * 12
        var months = max(0, min(cap, (end.year - start.year) * 12 + (end.month - start.month)))
        while months > 0 && hijriAdvanced(start, byMonths: months) > endJDN { months -= 1 }
        while months < cap && hijriAdvanced(start, byMonths: months + 1) <= endJDN { months += 1 }

        return HJSpan(years: months / 12,
                      months: months % 12,
                      days: endJDN - hijriAdvanced(start, byMonths: months))
    }

    // MARK: Gregorian

    private static func civilAdvanced(_ start: HJCivilDate, byMonths months: Int) -> Int {
        var year = start.year + months / 12
        var month = start.month + months % 12
        if month > 12 { month -= 12; year += 1 }
        year = max(HJCalendar.minCivilYear, min(HJCalendar.maxCivilYear, year))
        let length = HJCalendar.civilMonthLength(year: year, month: month)
        return HJCalendar.jdn(fromCivil: HJCivilDate(year: year,
                                                     month: month,
                                                     day: min(start.day, length)))
    }

    static func civilSpan(from start: HJCivilDate, to end: HJCivilDate) -> HJSpan {
        let startJDN = HJCalendar.jdn(fromCivil: start)
        let endJDN = HJCalendar.jdn(fromCivil: end)
        guard endJDN > startJDN else { return HJSpan(years: 0, months: 0, days: 0) }

        let cap = (HJCalendar.maxCivilYear - HJCalendar.minCivilYear + 2) * 12
        var months = max(0, min(cap, (end.year - start.year) * 12 + (end.month - start.month)))
        while months > 0 && civilAdvanced(start, byMonths: months) > endJDN { months -= 1 }
        while months < cap && civilAdvanced(start, byMonths: months + 1) <= endJDN { months += 1 }

        return HJSpan(years: months / 12,
                      months: months % 12,
                      days: endJDN - civilAdvanced(start, byMonths: months))
    }

    // MARK: Weeks

    /// Whole weeks plus the remainder.
    static func weeksAndDays(_ totalDays: Int) -> String {
        let magnitude = abs(totalDays)
        let weeks = magnitude / 7
        let rest = magnitude % 7
        if weeks == 0 { return HJFormatter.plural(rest, "day", "days") }
        if rest == 0 { return HJFormatter.plural(weeks, "week", "weeks") }
        return HJFormatter.plural(weeks, "week", "weeks") + ", " + HJFormatter.plural(rest, "day", "days")
    }
}
