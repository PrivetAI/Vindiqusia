import SwiftUI
import Combine

// MARK: - A date the user saved

/// A personal date anchored to the **Hijri** calendar: the day it falls on drifts through
/// the Gregorian year, which is exactly the point.
struct VQPersonalDate: Identifiable, Equatable, Codable {
    var id: String
    var title: String
    var note: String
    /// Which Hijri day the entry recurs on.
    var anchor: VQHijriDate
    /// The Hijri year it first happened, so the app can count how many have passed.
    var originYear: Int
    /// 0 anniversary, 1 birth, 2 other.
    var kind: Int

    init(id: String = UUID().uuidString,
         title: String,
         note: String = "",
         anchor: VQHijriDate,
         originYear: Int,
         kind: Int = 0) {
        self.id = id
        self.title = title
        self.note = note
        self.anchor = anchor
        self.originYear = originYear
        self.kind = kind
    }

    /// Every field decoded with a default, from day one. Adding a field later must never
    /// throw away the saved list.
    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        id = try box.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        title = try box.decodeIfPresent(String.self, forKey: .title) ?? "Saved date"
        note = try box.decodeIfPresent(String.self, forKey: .note) ?? ""
        anchor = try box.decodeIfPresent(VQHijriDate.self, forKey: .anchor)
            ?? VQHijriDate(year: 1447, month: 1, day: 1)
        originYear = try box.decodeIfPresent(Int.self, forKey: .originYear) ?? anchor.year
        kind = try box.decodeIfPresent(Int.self, forKey: .kind) ?? 0
    }

    static let kindNames = ["Anniversary", "Birth", "Other"]

    var kindName: String {
        VQPersonalDate.kindNames[max(0, min(VQPersonalDate.kindNames.count - 1, kind))]
    }
}

// MARK: - The saved file

/// One JSON blob in `UserDefaults`. Decoding is tolerant field by field, so a later
/// version can add anything without erasing what is already there.
struct VQSaveFile: Codable {
    var adjustment: Int
    var markedSpelling: Bool
    var arabicWeekdays: Bool
    /// 0 = Sunday, 1 = Monday, 2 = Saturday.
    var weekStart: Int
    /// 0 = Hijri leads, 1 = Gregorian leads.
    var primaryCalendar: Int
    var twentyFourHour: Bool
    var personalDates: [VQPersonalDate]

    init(adjustment: Int = 0,
         markedSpelling: Bool = false,
         arabicWeekdays: Bool = false,
         weekStart: Int = 0,
         primaryCalendar: Int = 0,
         twentyFourHour: Bool = false,
         personalDates: [VQPersonalDate] = []) {
        self.adjustment = adjustment
        self.markedSpelling = markedSpelling
        self.arabicWeekdays = arabicWeekdays
        self.weekStart = weekStart
        self.primaryCalendar = primaryCalendar
        self.twentyFourHour = twentyFourHour
        self.personalDates = personalDates
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        adjustment = try box.decodeIfPresent(Int.self, forKey: .adjustment) ?? 0
        markedSpelling = try box.decodeIfPresent(Bool.self, forKey: .markedSpelling) ?? false
        arabicWeekdays = try box.decodeIfPresent(Bool.self, forKey: .arabicWeekdays) ?? false
        weekStart = try box.decodeIfPresent(Int.self, forKey: .weekStart) ?? 0
        primaryCalendar = try box.decodeIfPresent(Int.self, forKey: .primaryCalendar) ?? 0
        twentyFourHour = try box.decodeIfPresent(Bool.self, forKey: .twentyFourHour) ?? false
        personalDates = try box.decodeIfPresent([VQPersonalDate].self, forKey: .personalDates) ?? []
    }
}

// MARK: - Store

final class VQStore: ObservableObject {

    private static let fileKey = "vindiqusia.calendar.save.v1"

    /// Shift applied to every computed Hijri date, in days. Negative moves the Hijri date
    /// back, positive moves it forward.
    @Published var adjustment: Int = 0 { didSet { clampAndSave() } }
    @Published var markedSpelling: Bool = false { didSet { save() } }
    @Published var arabicWeekdays: Bool = false { didSet { save() } }
    @Published var weekStart: Int = 0 { didSet { clampAndSave() } }
    @Published var primaryCalendar: Int = 0 { didSet { clampAndSave() } }
    @Published var twentyFourHour: Bool = false { didSet { save() } }
    @Published private(set) var personalDates: [VQPersonalDate] = []

    /// Bumped on every scene activation so the "today" reading is refreshed when the app
    /// comes back after midnight.
    @Published private(set) var dayTick: Int = 0

    private var loading = true

    init() {
        load()
        loading = false
    }

    // MARK: Derived

    var formatter: VQFormatter {
        VQFormatter(markedSpelling: markedSpelling, arabicWeekdays: arabicWeekdays)
    }

    var hijriLeads: Bool { primaryCalendar == 0 }

    /// Index of the first column of a week: 0 Sunday, 1 Monday, 6 Saturday.
    var firstWeekdayIndex: Int {
        switch weekStart {
        case 1: return 1
        case 2: return 6
        default: return 0
        }
    }

    var weekStartName: String {
        switch weekStart {
        case 1: return "Monday"
        case 2: return "Saturday"
        default: return "Sunday"
        }
    }

    var todayJDN: Int { VQCalendar.todayJDN() }

    /// The Hijri reading of a civil day, with the user's shift applied.
    func hijri(forJDN jdn: Int) -> VQHijriDate {
        VQCalendar.hijri(fromJDN: jdn + adjustment)
    }

    /// The civil day a Hijri date lands on, with the shift undone — the exact inverse of
    /// `hijri(forJDN:)`.
    func jdn(forHijri date: VQHijriDate) -> Int {
        VQCalendar.jdn(fromHijri: date) - adjustment
    }

    func civil(forJDN jdn: Int) -> VQCivilDate {
        VQCalendar.civil(fromJDN: jdn)
    }

    func weekdayIndex(forJDN jdn: Int) -> Int {
        VQCalendar.weekdayIndex(jdn: jdn)
    }

    var todayHijri: VQHijriDate { hijri(forJDN: todayJDN) }

    var adjustmentLabel: String {
        if adjustment == 0 { return "No shift" }
        return adjustment > 0 ? "+\(adjustment) day\(adjustment == 1 ? "" : "s")" : "\(adjustment) day\(adjustment == -1 ? "" : "s")"
    }

    // MARK: Personal dates

    func addPersonalDate(_ entry: VQPersonalDate) {
        var list = personalDates
        list.append(entry)
        personalDates = sorted(list)
        save()
    }

    func updatePersonalDate(_ entry: VQPersonalDate) {
        var list = personalDates
        if let index = list.firstIndex(where: { $0.id == entry.id }) {
            list[index] = entry
        } else {
            list.append(entry)
        }
        personalDates = sorted(list)
        save()
    }

    func deletePersonalDate(id: String) {
        personalDates = personalDates.filter { $0.id != id }
        save()
    }

    private func sorted(_ list: [VQPersonalDate]) -> [VQPersonalDate] {
        list.sorted { a, b in
            let ka = a.anchor.month * 100 + a.anchor.day
            let kb = b.anchor.month * 100 + b.anchor.day
            if ka != kb { return ka < kb }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
    }

    /// The next Gregorian day this entry falls on, at or after `fromJDN`.
    func nextOccurrenceJDN(of entry: VQPersonalDate, fromJDN: Int) -> Int {
        let todayHijri = hijri(forJDN: fromJDN)
        var year = todayHijri.year
        for _ in 0...2 {
            let candidate = resolvedAnchor(entry.anchor, inYear: year)
            let jdn = self.jdn(forHijri: candidate)
            if jdn >= fromJDN { return jdn }
            year += 1
        }
        return self.jdn(forHijri: resolvedAnchor(entry.anchor, inYear: year))
    }

    /// A 30 Dhu al-Hijjah anchor has no home in a common year. Pull it back to the last
    /// day the month actually has rather than silently rolling into the next month.
    func resolvedAnchor(_ anchor: VQHijriDate, inYear year: Int) -> VQHijriDate {
        let safeYear = max(VQCalendar.minHijriYear, min(VQCalendar.maxHijriYear, year))
        let month = max(1, min(12, anchor.month))
        let length = VQCalendar.hijriMonthLength(year: safeYear, month: month)
        return VQHijriDate(year: safeYear, month: month, day: min(anchor.day, length))
    }

    // MARK: Lifecycle

    func noteSceneActive() {
        dayTick &+= 1
    }

    func resetEverything() {
        loading = true
        adjustment = 0
        markedSpelling = false
        arabicWeekdays = false
        weekStart = 0
        primaryCalendar = 0
        twentyFourHour = false
        personalDates = []
        loading = false
        save()
    }

    // MARK: Persistence

    private func clampAndSave() {
        guard !loading else { return }
        let boundedAdjustment = max(-2, min(2, adjustment))
        if boundedAdjustment != adjustment { adjustment = boundedAdjustment; return }
        let boundedWeek = max(0, min(2, weekStart))
        if boundedWeek != weekStart { weekStart = boundedWeek; return }
        let boundedPrimary = max(0, min(1, primaryCalendar))
        if boundedPrimary != primaryCalendar { primaryCalendar = boundedPrimary; return }
        save()
    }

    func save() {
        guard !loading else { return }
        let file = VQSaveFile(adjustment: adjustment,
                              markedSpelling: markedSpelling,
                              arabicWeekdays: arabicWeekdays,
                              weekStart: weekStart,
                              primaryCalendar: primaryCalendar,
                              twentyFourHour: twentyFourHour,
                              personalDates: personalDates)
        guard let data = try? JSONEncoder().encode(file) else { return }
        UserDefaults.standard.set(data, forKey: VQStore.fileKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: VQStore.fileKey),
              let file = try? JSONDecoder().decode(VQSaveFile.self, from: data) else { return }
        adjustment = max(-2, min(2, file.adjustment))
        markedSpelling = file.markedSpelling
        arabicWeekdays = file.arabicWeekdays
        weekStart = max(0, min(2, file.weekStart))
        primaryCalendar = max(0, min(1, file.primaryCalendar))
        twentyFourHour = file.twentyFourHour
        personalDates = sorted(file.personalDates.map { entry in
            var fixed = entry
            fixed.anchor = VQCalendar.clampHijri(entry.anchor)
            fixed.originYear = max(VQCalendar.minHijriYear,
                                   min(VQCalendar.maxHijriYear, entry.originYear))
            fixed.kind = max(0, min(VQPersonalDate.kindNames.count - 1, entry.kind))
            if fixed.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                fixed.title = "Saved date"
            }
            return fixed
        })
    }
}
