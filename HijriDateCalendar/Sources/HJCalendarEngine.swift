import Foundation

// MARK: - Dates

/// A day in the arithmetic Islamic calendar. `year` is an AH year, `month` 1...12,
/// `day` 1...30.
struct HJHijriDate: Equatable, Hashable, Codable {
    var year: Int
    var month: Int
    var day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// Tolerant decode so a future field addition can never wipe a saved value.
    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        year = try box.decodeIfPresent(Int.self, forKey: .year) ?? 1447
        month = try box.decodeIfPresent(Int.self, forKey: .month) ?? 1
        day = try box.decodeIfPresent(Int.self, forKey: .day) ?? 1
    }
}

/// A day in the proleptic Gregorian calendar.
struct HJCivilDate: Equatable, Hashable, Codable {
    var year: Int
    var month: Int
    var day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        year = try box.decodeIfPresent(Int.self, forKey: .year) ?? 2026
        month = try box.decodeIfPresent(Int.self, forKey: .month) ?? 1
        day = try box.decodeIfPresent(Int.self, forKey: .day) ?? 1
    }
}

// MARK: - Engine

/// The arithmetic ("tabular") Islamic calendar, worked entirely in integers.
///
/// **Cycle.** Thirty years, of which years 2, 5, 7, 10, 13, 16, 18, 21, 24, 26 and 29 carry
/// an extra day — the eleven-leap-year set sometimes labelled type IIa, and the same set the
/// widely used Kuwaiti algorithm implements. Odd months run 30 days and even months 29, so an
/// ordinary year is 354 days and a leap year 355, its extra day added to Dhu al-Hijjah.
///
/// **Epoch.** 1 Muharram 1 AH is taken as Friday 16 July 622 CE in the Julian calendar, which
/// is Julian Day Number 1948440 — the civil (Friday) epoch rather than the astronomical
/// (Thursday) one, so the arithmetic weekday of 1 Muharram 1 comes out as Friday.
///
/// **What it is not.** The real Islamic month begins when the new crescent is actually sighted
/// locally, which no arithmetic can predict. Everything here is an estimate; the whole app
/// says so, and the user can shift it by up to two days.
enum HJCalendar {

    /// Julian Day Number of 1 Muharram 1 AH (civil epoch).
    static let hijriEpochJDN = 1948440

    /// Days in one full 30-year cycle: 30 * 354 + 11.
    static let cycleDays = 10631

    /// The leap years inside a 30-year cycle.
    static let leapYearsInCycle = [2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29]

    /// Hijri years the app will work with. Well outside anything a user will need, and far
    /// enough from the epoch that the arithmetic never has to touch year zero.
    static let minHijriYear = 1
    static let maxHijriYear = 3000

    /// Gregorian years the app will work with — the civil span of the Hijri range above.
    static let minCivilYear = 622
    static let maxCivilYear = 3600

    // MARK: Integer helpers

    /// Floor division. Swift's `/` truncates toward zero, which breaks every calendar
    /// formula the moment a value goes negative.
    static func floorDiv(_ a: Int, _ b: Int) -> Int {
        let q = a / b
        return (a % b != 0 && ((a < 0) != (b < 0))) ? q - 1 : q
    }

    /// Non-negative modulo.
    static func floorMod(_ a: Int, _ b: Int) -> Int {
        let r = a % b
        return r < 0 ? r + b : r
    }

    // MARK: Hijri structure

    /// A Hijri year carries a 355th day when `(11y + 14) mod 30 < 11`, which reproduces the
    /// leap set exactly.
    static func isLeapHijriYear(_ year: Int) -> Bool {
        floorMod(11 * year + 14, 30) < 11
    }

    /// 30 for odd months, 29 for even ones, and 30 for Dhu al-Hijjah in a leap year.
    static func hijriMonthLength(year: Int, month: Int) -> Int {
        let m = max(1, min(12, month))
        if m == 12 { return isLeapHijriYear(year) ? 30 : 29 }
        return m % 2 == 1 ? 30 : 29
    }

    static func hijriYearLength(_ year: Int) -> Int {
        isLeapHijriYear(year) ? 355 : 354
    }

    /// Days elapsed in the year before the first of `month`. Integer form of
    /// `ceil(29.5 * (month - 1))`.
    static func hijriDaysBeforeMonth(_ month: Int) -> Int {
        let m = max(1, min(13, month))
        return (295 * (m - 1) + 9) / 10
    }

    /// Days elapsed since the epoch day before 1 Muharram of `year`.
    static func hijriDaysBeforeYear(_ year: Int) -> Int {
        (year - 1) * 354 + floorDiv(3 + 11 * year, 30)
    }

    /// 1-based day of the Hijri year.
    static func hijriDayOfYear(_ date: HJHijriDate) -> Int {
        hijriDaysBeforeMonth(date.month) + date.day
    }

    // MARK: Hijri <-> JDN

    static func jdn(fromHijri date: HJHijriDate) -> Int {
        hijriEpochJDN + hijriDaysBeforeYear(date.year) + hijriDaysBeforeMonth(date.month) + date.day - 1
    }

    static func hijri(fromJDN jdn: Int) -> HJHijriDate {
        let elapsed = jdn - hijriEpochJDN

        // Start from the mean year length, then walk the estimate onto the true year. The
        // correction is never more than a step or two, and it is exact for any input.
        var year = floorDiv(elapsed * 30, cycleDays) + 1
        while hijriDaysBeforeYear(year) > elapsed { year -= 1 }
        while hijriDaysBeforeYear(year + 1) <= elapsed { year += 1 }

        let dayOfYear = elapsed - hijriDaysBeforeYear(year) + 1

        var month = 1
        while month < 12 && hijriDaysBeforeMonth(month + 1) < dayOfYear { month += 1 }
        let day = dayOfYear - hijriDaysBeforeMonth(month)

        return HJHijriDate(year: year, month: month, day: day)
    }

    // MARK: Gregorian structure

    static func isLeapCivilYear(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }

    static func civilMonthLength(year: Int, month: Int) -> Int {
        switch max(1, min(12, month)) {
        case 1, 3, 5, 7, 8, 10, 12: return 31
        case 4, 6, 9, 11: return 30
        default: return isLeapCivilYear(year) ? 29 : 28
        }
    }

    static func civilYearLength(_ year: Int) -> Int {
        isLeapCivilYear(year) ? 366 : 365
    }

    /// 1-based day of the Gregorian year.
    static func civilDayOfYear(_ date: HJCivilDate) -> Int {
        var total = 0
        var m = 1
        while m < date.month {
            total += civilMonthLength(year: date.year, month: m)
            m += 1
        }
        return total + date.day
    }

    // MARK: Gregorian <-> JDN

    /// Fliegel-Van Flandern, proleptic Gregorian.
    static func jdn(fromCivil date: HJCivilDate) -> Int {
        let a = floorDiv(14 - date.month, 12)
        let y = date.year + 4800 - a
        let m = date.month + 12 * a - 3
        return date.day
            + floorDiv(153 * m + 2, 5)
            + 365 * y
            + floorDiv(y, 4)
            - floorDiv(y, 100)
            + floorDiv(y, 400)
            - 32045
    }

    static func civil(fromJDN jdn: Int) -> HJCivilDate {
        let a = jdn + 32044
        let b = floorDiv(4 * a + 3, 146097)
        let c = a - floorDiv(146097 * b, 4)
        let d = floorDiv(4 * c + 3, 1461)
        let e = c - floorDiv(1461 * d, 4)
        let m = floorDiv(5 * e + 2, 153)
        let day = e - floorDiv(153 * m + 2, 5) + 1
        let month = m + 3 - 12 * floorDiv(m, 10)
        let year = 100 * b + d - 4800 + floorDiv(m, 10)
        return HJCivilDate(year: year, month: month, day: day)
    }

    // MARK: Weekday

    /// 0 = Sunday ... 6 = Saturday. JDN 2451545 is Saturday 1 January 2000.
    static func weekdayIndex(jdn: Int) -> Int {
        floorMod(jdn + 1, 7)
    }

    // MARK: Clamping

    static func clampHijri(_ date: HJHijriDate) -> HJHijriDate {
        let year = max(minHijriYear, min(maxHijriYear, date.year))
        let month = max(1, min(12, date.month))
        let day = max(1, min(hijriMonthLength(year: year, month: month), date.day))
        return HJHijriDate(year: year, month: month, day: day)
    }

    static func clampCivil(_ date: HJCivilDate) -> HJCivilDate {
        let year = max(minCivilYear, min(maxCivilYear, date.year))
        let month = max(1, min(12, date.month))
        let day = max(1, min(civilMonthLength(year: year, month: month), date.day))
        return HJCivilDate(year: year, month: month, day: day)
    }

    /// The JDN span the app is willing to display, so no screen can ever page off the end
    /// of the arithmetic.
    static var minJDN: Int { jdn(fromHijri: HJHijriDate(year: minHijriYear, month: 1, day: 1)) }
    static var maxJDN: Int { jdn(fromHijri: HJHijriDate(year: maxHijriYear, month: 12, day: hijriMonthLength(year: maxHijriYear, month: 12))) }

    static func clampJDN(_ value: Int) -> Int {
        max(minJDN, min(maxJDN, value))
    }

    // MARK: Foundation bridge

    /// The Gregorian calendar used to read a wall-clock day out of a `Date`. Explicitly
    /// Gregorian and explicitly the device time zone — `Calendar.current` follows whatever
    /// the user picked in system settings and would hand back Hijri components on some
    /// devices.
    static func civilReference(timeZone: TimeZone = .current) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func civilDate(from date: Date, timeZone: TimeZone = .current) -> HJCivilDate {
        let parts = civilReference(timeZone: timeZone).dateComponents([.year, .month, .day], from: date)
        return HJCivilDate(year: parts.year ?? 2026, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    static func todayJDN(timeZone: TimeZone = .current, now: Date = Date()) -> Int {
        jdn(fromCivil: civilDate(from: now, timeZone: timeZone))
    }
}

// MARK: - Names

enum HJNames {

    /// Plain-ASCII transliteration.
    static let hijriMonthsPlain = [
        "Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani",
        "Jumada al-Ula", "Jumada al-Akhirah", "Rajab", "Shaban",
        "Ramadan", "Shawwal", "Dhu al-Qadah", "Dhu al-Hijjah"
    ]

    /// Scholarly transliteration with the usual macrons and dots.
    static let hijriMonthsMarked = [
        "Mu\u{1E25}arram", "\u{1E62}afar", "Rab\u{12B}\u{2BF} al-Awwal", "Rab\u{12B}\u{2BF} al-Th\u{101}n\u{12B}",
        "Jum\u{101}d\u{101} al-\u{16A}l\u{101}", "Jum\u{101}d\u{101} al-\u{100}khirah", "Rajab", "Sha\u{2BF}b\u{101}n",
        "Rama\u{1E0D}\u{101}n", "Shaww\u{101}l", "Dh\u{16B} al-Qa\u{2BF}dah", "Dh\u{16B} al-\u{1E24}ijjah"
    ]

    /// Short forms for tight grid headers.
    static let hijriMonthsShort = [
        "Muh", "Saf", "Rab I", "Rab II", "Jum I", "Jum II",
        "Raj", "Sha", "Ram", "Shw", "Qad", "Hij"
    ]

    static let civilMonths = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    static let civilMonthsShort = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]

    /// 0 = Sunday.
    static let weekdaysEnglish = [
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    ]

    static let weekdaysEnglishShort = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    /// Transliterated Arabic day names, 0 = Sunday.
    static let weekdaysArabic = [
        "al-A\u{1E25}ad", "al-Ithnayn", "al-Thul\u{101}th\u{101}\u{2BE}", "al-Arbi\u{2BF}\u{101}\u{2BE}",
        "al-Kham\u{12B}s", "al-Jumu\u{2BF}ah", "al-Sabt"
    ]

    static let weekdaysArabicShort = ["A\u{1E25}ad", "Ithn", "Thul", "Arbi", "Kham", "Jum", "Sabt"]

    static func hijriMonth(_ month: Int, marked: Bool) -> String {
        let index = max(1, min(12, month)) - 1
        return marked ? hijriMonthsMarked[index] : hijriMonthsPlain[index]
    }

    static func hijriMonthShort(_ month: Int) -> String {
        hijriMonthsShort[max(1, min(12, month)) - 1]
    }

    static func civilMonth(_ month: Int) -> String {
        civilMonths[max(1, min(12, month)) - 1]
    }

    static func civilMonthShort(_ month: Int) -> String {
        civilMonthsShort[max(1, min(12, month)) - 1]
    }

    static func weekday(_ index: Int, arabic: Bool) -> String {
        let i = HJCalendar.floorMod(index, 7)
        return arabic ? weekdaysArabic[i] : weekdaysEnglish[i]
    }

    static func weekdayShort(_ index: Int, arabic: Bool) -> String {
        let i = HJCalendar.floorMod(index, 7)
        return arabic ? weekdaysArabicShort[i] : weekdaysEnglishShort[i]
    }
}

// MARK: - Formatting

/// Everything that turns a JDN into words. Held together in one place so a spelling
/// preference change reaches every screen at once.
struct HJFormatter {

    var markedSpelling: Bool
    var arabicWeekdays: Bool

    func hijriMonthName(_ month: Int) -> String {
        HJNames.hijriMonth(month, marked: markedSpelling)
    }

    func weekdayName(_ index: Int) -> String {
        HJNames.weekday(index, arabic: arabicWeekdays)
    }

    func weekdayShortName(_ index: Int) -> String {
        HJNames.weekdayShort(index, arabic: arabicWeekdays)
    }

    /// "12 Ramadan 1447 AH"
    func hijriLong(_ date: HJHijriDate) -> String {
        "\(date.day) \(hijriMonthName(date.month)) \(date.year) AH"
    }

    /// "12 Ramadan"
    func hijriDayMonth(_ date: HJHijriDate) -> String {
        "\(date.day) \(hijriMonthName(date.month))"
    }

    /// "Ramadan 1447 AH"
    func hijriMonthYear(_ date: HJHijriDate) -> String {
        "\(hijriMonthName(date.month)) \(date.year) AH"
    }

    /// "12 March 2026 CE"
    func civilLong(_ date: HJCivilDate) -> String {
        "\(date.day) \(HJNames.civilMonth(date.month)) \(date.year) CE"
    }

    /// "12 Mar 2026"
    func civilShort(_ date: HJCivilDate) -> String {
        "\(date.day) \(HJNames.civilMonthShort(date.month)) \(date.year)"
    }

    /// "March 2026"
    func civilMonthYear(_ date: HJCivilDate) -> String {
        "\(HJNames.civilMonth(date.month)) \(date.year)"
    }

    static func ordinal(_ value: Int) -> String {
        let n = abs(value)
        let suffix: String
        switch (n % 100, n % 10) {
        case (11, _), (12, _), (13, _): suffix = "th"
        case (_, 1): suffix = "st"
        case (_, 2): suffix = "nd"
        case (_, 3): suffix = "rd"
        default: suffix = "th"
        }
        return "\(value)\(suffix)"
    }

    /// "in 12 days" / "today" / "9 days ago"
    static func relativeDays(_ delta: Int) -> String {
        if delta == 0 { return "Today" }
        if delta == 1 { return "Tomorrow" }
        if delta == -1 { return "Yesterday" }
        if delta > 0 { return "In \(delta) days" }
        return "\(-delta) days ago"
    }

    static func plural(_ count: Int, _ singular: String, _ plural: String) -> String {
        "\(count) \(count == 1 ? singular : plural)"
    }
}
