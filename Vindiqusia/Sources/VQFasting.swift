import SwiftUI

enum VQFastKind: Int, Comparable {
    case none = 0
    case advisory = 1
    case voluntary = 2
    case obligatory = 3
    case notPermitted = 4

    static func < (lhs: VQFastKind, rhs: VQFastKind) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .none: return "Ordinary day"
        case .advisory: return "Worth knowing"
        case .voluntary: return "Voluntary fast"
        case .obligatory: return "Obligatory fast"
        case .notPermitted: return "Fasting not permitted"
        }
    }

    var tint: Color {
        switch self {
        case .none: return VQTheme.inkFaint
        case .advisory: return VQTheme.indigo
        case .voluntary: return VQTheme.verdant
        case .obligatory: return VQTheme.ink
        case .notPermitted: return VQTheme.clay
        }
    }
}

struct VQFastNote: Identifiable {
    let id: String
    let label: String
    let kind: VQFastKind
    let detail: String
}

struct VQDayFasting {
    let jdn: Int
    let hijri: VQHijriDate
    let weekday: Int
    let notes: [VQFastNote]

    var kind: VQFastKind {
        notes.map { $0.kind }.max() ?? .none
    }

    /// The line the Today card and the day sheet lead with.
    var headline: String {
        if let strongest = notes.max(by: { $0.kind < $1.kind }) { return strongest.label }
        return "No fast is prescribed today"
    }
}

/// Works out what the fasting calendar says about a given day, and about a whole month.
enum VQFasting {

    static func status(forJDN jdn: Int, store: VQStore) -> VQDayFasting {
        let hijri = store.hijri(forJDN: jdn)
        let weekday = VQCalendar.weekdayIndex(jdn: jdn)
        var notes: [VQFastNote] = []

        // --- obligatory
        if hijri.month == 9 {
            notes.append(VQFastNote(id: "ramadan",
                                    label: "Ramadan",
                                    kind: .obligatory,
                                    detail: "Day \(hijri.day) of the obligatory fast, for adults who are able. Those exempt make the days up later or, where they cannot, feed someone in place of each day."))
        }

        // --- not permitted
        if hijri.month == 10 && hijri.day == 1 {
            notes.append(VQFastNote(id: "eidfitr",
                                    label: "Eid al-Fitr",
                                    kind: .notPermitted,
                                    detail: "Fasting is not permitted on the day of Eid al-Fitr, including for anyone making up missed Ramadan days."))
        }
        if hijri.month == 12 && hijri.day == 10 {
            notes.append(VQFastNote(id: "eidadha",
                                    label: "Eid al-Adha",
                                    kind: .notPermitted,
                                    detail: "Fasting is not permitted on the day of sacrifice."))
        }
        if hijri.month == 12 && hijri.day >= 11 && hijri.day <= 13 {
            notes.append(VQFastNote(id: "tashriq",
                                    label: "Day of Tashriq",
                                    kind: .notPermitted,
                                    detail: "One of the three days after Eid al-Adha. Fasting them is not permitted, with a narrow exception for a pilgrim who owes a sacrifice and cannot obtain one."))
        }

        // --- voluntary, by Hijri date
        if hijri.month == 1 && hijri.day == 9 {
            notes.append(VQFastNote(id: "tasua",
                                    label: "The Day of Tasu'a",
                                    kind: .voluntary,
                                    detail: "The ninth of Muharram, kept with Ashura so that the fast is not confined to the tenth alone."))
        }
        if hijri.month == 1 && hijri.day == 10 {
            notes.append(VQFastNote(id: "ashura",
                                    label: "The Day of Ashura",
                                    kind: .voluntary,
                                    detail: "The tenth of Muharram. One of the oldest voluntary fasts in the calendar."))
        }
        if hijri.month == 12 && hijri.day >= 1 && hijri.day <= 9 {
            notes.append(VQFastNote(id: "firstten",
                                    label: "The first ten days of Dhu al-Hijjah",
                                    kind: .voluntary,
                                    detail: "Day \(hijri.day) of the ten. Fasting any of the first nine is common; the tenth is Eid and is not fasted."))
        }
        if hijri.month == 12 && hijri.day == 9 {
            notes.append(VQFastNote(id: "arafah",
                                    label: "The Day of Arafah",
                                    kind: .voluntary,
                                    detail: "Fasted by those not on pilgrimage. Pilgrims standing at Arafah do not fast it."))
        }
        if hijri.month == 10 && hijri.day >= 2 {
            notes.append(VQFastNote(id: "shawwal6",
                                    label: "Eligible for the six of Shawwal",
                                    kind: .voluntary,
                                    detail: "Six voluntary fasts may be kept on any days of Shawwal after Eid, together or spread through the month."))
        }
        if hijri.day >= 13 && hijri.day <= 15 {
            let blocked = hijri.month == 12 && hijri.day == 13
            notes.append(VQFastNote(id: "whiteday",
                                    label: blocked ? "White day, but a Day of Tashriq" : "White day",
                                    kind: blocked ? .advisory : .voluntary,
                                    detail: blocked
                                        ? "The thirteenth of Dhu al-Hijjah is both a white day and the last Day of Tashriq. The restriction takes precedence, so those keeping the white days fast only the fourteenth and fifteenth this month."
                                        : "One of the three days around the full moon, the thirteenth to the fifteenth of every Hijri month."))
        }
        if hijri.month == 8 && hijri.day <= 28 {
            notes.append(VQFastNote(id: "shaban",
                                    label: "Sha'ban",
                                    kind: .advisory,
                                    detail: "Voluntary fasting is described as especially frequent in Sha'ban. Many stop a day or two before the month ends so that it is not run into Ramadan."))
        }
        if hijri.month == 8 && hijri.day == 30 {
            notes.append(VQFastNote(id: "doubt",
                                    label: "The Day of Doubt",
                                    kind: .advisory,
                                    detail: "The thirtieth of Sha'ban, when the month's end has not been resolved by a sighting. Fasting it as though Ramadan had begun is discouraged."))
        }

        // --- voluntary, by weekday
        if weekday == 1 || weekday == 4 {
            notes.append(VQFastNote(id: "monthu",
                                    label: weekday == 1 ? "Monday" : "Thursday",
                                    kind: .voluntary,
                                    detail: "The regular twice-weekly voluntary fast, kept through the year except on the days fasting is not permitted."))
        }

        // --- advisory, by weekday, only when nothing else already covers the day
        let hasOtherVoluntary = notes.contains { $0.kind == .voluntary }
        if weekday == 5 && !hasOtherVoluntary {
            notes.append(VQFastNote(id: "friday",
                                    label: "Friday on its own",
                                    kind: .advisory,
                                    detail: "Singling Friday out for a fast is discouraged. Joining it to Thursday or Saturday removes the objection, as does a fast that simply lands on it."))
        }
        if weekday == 6 && !hasOtherVoluntary {
            notes.append(VQFastNote(id: "saturday",
                                    label: "Saturday on its own",
                                    kind: .advisory,
                                    detail: "Some scholars extend the same reasoning to Saturday, on a report whose strength is itself debated. Joining it to Friday or Sunday settles the question in practice."))
        }

        // The restriction always outranks the encouragement; keep the strongest note first.
        let ordered = notes.sorted { a, b in
            if a.kind != b.kind { return a.kind > b.kind }
            return a.label < b.label
        }
        return VQDayFasting(jdn: jdn, hijri: hijri, weekday: weekday, notes: ordered)
    }

    /// Every day of one Hijri month that is actually a fasting day, or on which fasting is
    /// not permitted. Advisory-only days — "Sha'ban", "Friday on its own" — are left out
    /// here, or a month list would be nothing but footnotes; they still appear on the
    /// day's own sheet.
    static func month(year: Int, month: Int, store: VQStore) -> [VQDayFasting] {
        let length = VQCalendar.hijriMonthLength(year: year, month: month)
        var out: [VQDayFasting] = []
        guard length > 0 else { return out }
        for day in 1...length {
            let jdn = store.jdn(forHijri: VQHijriDate(year: year, month: month, day: day))
            let status = status(forJDN: jdn, store: store)
            if status.kind >= .voluntary { out.append(status) }
        }
        return out
    }

    /// The days of a Hijri year on which fasting is not permitted.
    static func restrictedDays(year: Int, store: VQStore) -> [VQDayFasting] {
        var out: [VQDayFasting] = []
        let candidates: [(Int, Int)] = [(10, 1), (12, 10), (12, 11), (12, 12), (12, 13)]
        for (month, day) in candidates {
            let jdn = store.jdn(forHijri: VQHijriDate(year: year, month: month, day: day))
            out.append(status(forJDN: jdn, store: store))
        }
        return out
    }
}
