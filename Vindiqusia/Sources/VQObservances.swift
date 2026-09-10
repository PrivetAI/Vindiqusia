import SwiftUI

// MARK: - Model

/// How firmly the day is pinned down.
enum VQTiming: Int {
    /// A fixed day of a Hijri month. The Hijri date does not move; only the Gregorian
    /// estimate beside it does.
    case fixedHijri = 0
    /// The day is announced from a local sighting, so it commonly lands a day either side
    /// of any calculation.
    case sightingLed = 1
    /// Comes round every month or every week, with no single date in the year.
    case recurring = 2

    var label: String {
        switch self {
        case .fixedHijri: return "Fixed Hijri date"
        case .sightingLed: return "Set by sighting"
        case .recurring: return "Recurring"
        }
    }

    var note: String {
        switch self {
        case .fixedHijri:
            return "The Hijri date is fixed. The Gregorian date shown is an estimate and can differ by a day from the announced date where you are."
        case .sightingLed:
            return "The day is announced when the new crescent is sighted locally, so it may fall a day before or after the estimate shown."
        case .recurring:
            return "This comes round on a cycle rather than on one day of the year."
        }
    }

    var tint: Color {
        switch self {
        case .fixedHijri: return VQTheme.indigo
        case .sightingLed: return VQTheme.gold
        case .recurring: return VQTheme.verdant
        }
    }
}

/// What fasting looks like on the day, kept deliberately plain.
enum VQFastingStance: Int {
    case none = 0
    case voluntary = 1
    case obligatory = 2
    case notPermitted = 3
    case discouraged = 4

    var label: String {
        switch self {
        case .none: return ""
        case .voluntary: return "Voluntary fast"
        case .obligatory: return "Obligatory fast"
        case .notPermitted: return "Fasting not permitted"
        case .discouraged: return "Fasting discouraged"
        }
    }

    var tint: Color {
        switch self {
        case .notPermitted, .discouraged: return VQTheme.clay
        case .obligatory: return VQTheme.ink
        case .voluntary: return VQTheme.verdant
        case .none: return VQTheme.inkFaint
        }
    }
}

enum VQObservanceGroup: Int, CaseIterable {
    case landmark = 0
    case ramadan = 1
    case hajj = 2
    case fasting = 3
    case restricted = 4
    case sacredMonths = 5

    var title: String {
        switch self {
        case .landmark: return "Days of the year"
        case .ramadan: return "Ramadan"
        case .hajj: return "Dhu al-Hijjah"
        case .fasting: return "Fasting days"
        case .restricted: return "Not fasting days"
        case .sacredMonths: return "Sacred months"
        }
    }
}

struct VQObservance: Identifiable {
    let id: String
    let name: String
    /// Hijri month, or 0 when the entry recurs.
    let month: Int
    /// First Hijri day, or 0 when the entry covers a whole month.
    let day: Int
    /// Days the entry runs for.
    let span: Int
    let timing: VQTiming
    let group: VQObservanceGroup
    let fasting: VQFastingStance
    /// How the date reads in words, for entries a single day cannot describe.
    let dateNote: String
    /// Written for this app.
    let summary: String
    /// Marked in the month grid.
    let marksGrid: Bool

    init(_ id: String,
         _ name: String,
         month: Int,
         day: Int,
         span: Int = 1,
         timing: VQTiming,
         group: VQObservanceGroup,
         fasting: VQFastingStance = .none,
         dateNote: String,
         summary: String,
         marksGrid: Bool = true) {
        self.id = id
        self.name = name
        self.month = month
        self.day = day
        self.span = span
        self.timing = timing
        self.group = group
        self.fasting = fasting
        self.dateNote = dateNote
        self.summary = summary
        self.marksGrid = marksGrid
    }

    /// True when the entry occupies one identifiable stretch of the Hijri year.
    var isDated: Bool { month >= 1 && month <= 12 && day >= 1 }
}

// MARK: - The library

enum VQObservances {

    static let all: [VQObservance] = [

        // ------------------------------------------------------------- Muharram
        VQObservance("newyear", "Islamic New Year",
                     month: 1, day: 1,
                     timing: .sightingLed, group: .landmark,
                     dateNote: "1 Muharram",
                     summary: "The Hijri year turns on the first of Muharram, counted from the year the Prophet and his companions left Mecca for Medina. It is a marker rather than a festival: there is no prescribed rite attached to it, and practice ranges from nothing at all to a quiet reckoning of the year past. The date is announced from the sighting of the Muharram crescent, so it can fall a day either side of any calculated estimate."),

        VQObservance("tasua", "The Day of Tasu'a",
                     month: 1, day: 9,
                     timing: .sightingLed, group: .fasting,
                     fasting: .voluntary,
                     dateNote: "9 Muharram",
                     summary: "The ninth of Muharram, kept mainly as the day joined to Ashura. Many fast it together with the tenth so that the fast is not confined to a single day. It is voluntary throughout."),

        VQObservance("ashura", "The Day of Ashura",
                     month: 1, day: 10,
                     timing: .sightingLed, group: .landmark,
                     fasting: .voluntary,
                     dateNote: "10 Muharram",
                     summary: "Ashura is the tenth of Muharram and one of the oldest days of fasting in the Muslim year, kept before the Ramadan fast was made obligatory and voluntary ever since. For Shia Muslims the day carries a second and heavier weight: it is the anniversary of the killing of Husayn ibn Ali at Karbala in 61 AH, and is marked with mourning gatherings. Observance therefore looks very different from one community to another."),

        VQObservance("muharram-month", "Muharram, a sacred month",
                     month: 1, day: 0, span: 30,
                     timing: .fixedHijri, group: .sacredMonths,
                     dateNote: "The whole of Muharram",
                     summary: "Muharram opens the year and is one of the four months named as sacred, in which fighting was to be set aside. Its name comes from the same root as the word for what is forbidden. Voluntary fasting during it is long-established, without any single day being required.",
                     marksGrid: false),

        // ------------------------------------------------------------- Rabi al-Awwal
        VQObservance("mawlid", "Mawlid an-Nabi",
                     month: 3, day: 12,
                     timing: .fixedHijri, group: .landmark,
                     dateNote: "12 Rabi al-Awwal",
                     summary: "The anniversary of the Prophet's birth, observed by much of the Muslim world on the twelfth of Rabi al-Awwal; many Shia communities keep the seventeenth instead. Early sources do not settle the day, and the observance itself is a later development that some traditions welcome and others decline. Where it is kept it usually takes the form of gatherings, readings of the life story and charitable giving."),

        // ------------------------------------------------------------- Rajab
        VQObservance("rajab-month", "Rajab, a sacred month",
                     month: 7, day: 0, span: 30,
                     timing: .fixedHijri, group: .sacredMonths,
                     dateNote: "The whole of Rajab",
                     summary: "Rajab is the third of the four sacred months and the only one that stands apart from the other three. Its name carries the sense of holding something in awe. It sits two months before Ramadan and is widely treated as the start of the run-up to it.",
                     marksGrid: false),

        VQObservance("isra", "Isra and Mi'raj",
                     month: 7, day: 27,
                     timing: .fixedHijri, group: .landmark,
                     dateNote: "27 Rajab",
                     summary: "The night journey from Mecca to Jerusalem and the ascent through the heavens, during which the five daily prayers were established. It is commonly commemorated on the twenty-seventh of Rajab, though the early sources do not fix the date and other months have been proposed. The event itself is described in the Quran; the calendar date attached to it is convention rather than record."),

        // ------------------------------------------------------------- Sha'ban
        VQObservance("midshaban", "Mid-Sha'ban",
                     month: 8, day: 15,
                     timing: .fixedHijri, group: .landmark,
                     dateNote: "15 Sha'ban",
                     summary: "The night of the fifteenth of Sha'ban, kept in many places with extra prayer and with fasting the following day. The reports about it are the subject of long-standing scholarly disagreement, and practice ranges from established custom to deliberate avoidance. It falls a fortnight before Ramadan, which is part of why it reads as a threshold."),

        VQObservance("shaban-fast", "Fasting in Sha'ban",
                     month: 8, day: 0, span: 30,
                     timing: .fixedHijri, group: .fasting,
                     fasting: .voluntary,
                     dateNote: "Through Sha'ban",
                     summary: "Sha'ban is the month in which voluntary fasting is most often described as frequent, short of fasting it whole. It is treated as preparation, not obligation. Many stop a day or two before Ramadan so the two are not run together.",
                     marksGrid: false),

        // Deliberately undated: Sha'ban is always twenty-nine days in the tabular
        // calendar, so a thirtieth would resolve to a Gregorian date that does not exist.
        VQObservance("doubt", "The Day of Doubt",
                     month: 8, day: 0,
                     timing: .sightingLed, group: .restricted,
                     fasting: .discouraged,
                     dateNote: "30 Sha'ban, in the years it occurs",
                     summary: "When the Sha'ban crescent is not sighted on the twenty-ninth evening and cloud leaves the month's end unresolved, the following day is the day of doubt. Fasting it as though Ramadan had already begun is discouraged, because Ramadan is entered on a sighting and not on a guess. In the tabular calendar this app computes, Sha'ban is always twenty-nine days, so no thirtieth is ever shown here \u{2014} the day arises only where an actual sighting extends the month.",
                     marksGrid: false),

        // ------------------------------------------------------------- Ramadan
        VQObservance("ramadan-start", "The first day of Ramadan",
                     month: 9, day: 1,
                     timing: .sightingLed, group: .ramadan,
                     fasting: .obligatory,
                     dateNote: "1 Ramadan",
                     summary: "The month of the obligatory fast begins when the Ramadan crescent is sighted, or when Sha'ban has completed thirty days. Because the sighting is local, the start differs between countries and sometimes between communities in the same country by a day. No calculated calendar, this one included, can settle it in advance."),

        VQObservance("ramadan-month", "Ramadan, the month of fasting",
                     month: 9, day: 0, span: 30,
                     timing: .sightingLed, group: .ramadan,
                     fasting: .obligatory,
                     dateNote: "The whole of Ramadan",
                     summary: "Ramadan is the ninth month and the one in which the fast from dawn to sunset is obligatory for adults who are able. Alongside the fast it carries the night prayers, increased recitation and giving. Its length is twenty-nine or thirty days, settled only by the sighting that ends it.",
                     marksGrid: false),

        VQObservance("lastten", "The last ten nights",
                     month: 9, day: 21, span: 10,
                     timing: .sightingLed, group: .ramadan,
                     fasting: .obligatory,
                     dateNote: "21 Ramadan to the end of the month",
                     summary: "The closing stretch of Ramadan, singled out for intensified prayer and for the retreat known as i'tikaf. Counting is done from the end of the month rather than the beginning, which is why a twenty-nine-day Ramadan shifts which numbered nights are odd. Laylat al-Qadr is sought within this stretch."),

        VQObservance("qadr-window", "The Laylat al-Qadr window",
                     month: 9, day: 21, span: 9,
                     timing: .sightingLed, group: .ramadan,
                     dateNote: "Odd nights from 21 Ramadan",
                     summary: "The Night of Decree is described as better than a thousand months and is looked for in the odd nights of the last ten: the twenty-first, twenty-third, twenty-fifth, twenty-seventh and twenty-ninth. Its exact night is deliberately not disclosed, and the practical answer has always been to keep all of them. Anyone who tells you the date with certainty is telling you more than is known."),

        VQObservance("qadr-27", "The twenty-seventh night",
                     month: 9, day: 27,
                     timing: .sightingLed, group: .ramadan,
                     dateNote: "27 Ramadan",
                     summary: "The night most often singled out within the Laylat al-Qadr window, and the one on which the largest gatherings usually fall. The weight given to it is a matter of preference among the reports rather than a settled identification. Since the numbering depends on when the month began where you are, two places can keep different nights as the twenty-seventh."),

        VQObservance("fitr-zakat", "Zakat al-Fitr",
                     month: 9, day: 29, span: 2,
                     timing: .sightingLed, group: .ramadan,
                     dateNote: "Before the Eid al-Fitr prayer",
                     summary: "A measure of staple food, or its value, given on behalf of every member of a household before the Eid prayer. Its purpose is to make sure the poor are not left out of the festival. Timing matters more than amount: given after the prayer it counts as ordinary charity rather than as Zakat al-Fitr.",
                     marksGrid: false),

        // ------------------------------------------------------------- Shawwal
        VQObservance("eid-fitr", "Eid al-Fitr",
                     month: 10, day: 1,
                     timing: .sightingLed, group: .landmark,
                     fasting: .notPermitted,
                     dateNote: "1 Shawwal",
                     summary: "The festival that ends Ramadan, kept with a morning prayer in congregation and with visiting through the day. It begins when the Shawwal crescent is sighted, which is why the announcement can come late on the last evening of Ramadan. Fasting on this day is not permitted."),

        VQObservance("shawwal-six", "The six days of Shawwal",
                     month: 10, day: 2, span: 29,
                     timing: .sightingLed, group: .fasting,
                     fasting: .voluntary,
                     dateNote: "Any six days after Eid al-Fitr",
                     summary: "Six voluntary fasts kept anywhere in Shawwal after the day of Eid, together or spread out. The reward described for them, joined to the month of Ramadan, is the reason they are so widely kept. They cannot include the day of Eid itself.",
                     marksGrid: false),

        // ------------------------------------------------------------- Dhu al-Qadah
        VQObservance("qadah-month", "Dhu al-Qadah, a sacred month",
                     month: 11, day: 0, span: 30,
                     timing: .fixedHijri, group: .sacredMonths,
                     dateNote: "The whole of Dhu al-Qadah",
                     summary: "The eleventh month and the first of the three consecutive sacred months. Its name means the one of sitting: the month in which fighting stopped so that travel to the pilgrimage would be safe. It is the quiet month immediately before the Hajj season.",
                     marksGrid: false),

        // ------------------------------------------------------------- Dhu al-Hijjah
        VQObservance("hijjah-month", "Dhu al-Hijjah, a sacred month",
                     month: 12, day: 0, span: 30,
                     timing: .fixedHijri, group: .sacredMonths,
                     dateNote: "The whole of Dhu al-Hijjah",
                     summary: "The last month of the year, sacred, and the one the Hajj is named for. It holds the pilgrimage rites, the Day of Arafah, Eid al-Adha and the days of Tashriq. In a leap year of this calendar it is the month that receives the extra day.",
                     marksGrid: false),

        VQObservance("first-ten", "The first ten days of Dhu al-Hijjah",
                     month: 12, day: 1, span: 10,
                     timing: .sightingLed, group: .hajj,
                     fasting: .voluntary,
                     dateNote: "1 to 10 Dhu al-Hijjah",
                     summary: "Ten days described as the best days of the year for good deeds, whether or not one is on pilgrimage. Fasting some or all of the first nine is common; the tenth is the day of Eid and is not fasted. Those intending to sacrifice often refrain from cutting hair or nails once the month begins."),

        VQObservance("tarwiyah", "The Day of Tarwiyah",
                     month: 12, day: 8,
                     timing: .sightingLed, group: .hajj,
                     fasting: .voluntary,
                     dateNote: "8 Dhu al-Hijjah",
                     summary: "The eighth of Dhu al-Hijjah, when pilgrims move out to Mina and the Hajj proper begins. The name refers to the watering done in preparation for the days ahead. For those not on pilgrimage it is an ordinary voluntary fasting day."),

        VQObservance("arafah", "The Day of Arafah",
                     month: 12, day: 9,
                     timing: .sightingLed, group: .hajj,
                     fasting: .voluntary,
                     dateNote: "9 Dhu al-Hijjah",
                     summary: "The central day of the Hajj, spent by pilgrims standing on the plain of Arafah until sunset; missing it means the pilgrimage is not completed. Those not on pilgrimage commonly fast it, with a well-known expiation described for the fast. Pilgrims at Arafah do not fast, so that they can keep the standing."),

        VQObservance("eid-adha", "Eid al-Adha",
                     month: 12, day: 10,
                     timing: .sightingLed, group: .landmark,
                     fasting: .notPermitted,
                     dateNote: "10 Dhu al-Hijjah",
                     summary: "The festival of sacrifice, kept with a morning prayer and with the slaughter of an animal whose meat is shared with family, neighbours and the poor. It falls the day after Arafah and runs into the days of Tashriq that follow. Fasting on this day is not permitted."),

        VQObservance("tashriq", "The Days of Tashriq",
                     month: 12, day: 11, span: 3,
                     timing: .sightingLed, group: .landmark,
                     fasting: .notPermitted,
                     dateNote: "11 to 13 Dhu al-Hijjah",
                     summary: "The three days after Eid al-Adha, during which the sacrifice may still be offered and pilgrims complete the stoning at Mina. They are days of eating and remembrance, and fasting them is not permitted; the one narrow exception recognised is for a pilgrim who owes a sacrifice and cannot find one. The name refers to meat laid out to dry."),

        VQObservance("hajj-season", "The days of Hajj",
                     month: 12, day: 8, span: 6,
                     timing: .sightingLed, group: .hajj,
                     dateNote: "8 to 13 Dhu al-Hijjah",
                     summary: "The six days across which the pilgrimage rites are performed, from the move to Mina through Arafah, Muzdalifah, the sacrifice and the stoning. The Hajj is obligatory once in a lifetime for those with the means and the ability. Its dates cannot be moved: it is the one pilgrimage fixed to a place in the calendar.",
                     marksGrid: false),

        // ------------------------------------------------------------- Recurring
        VQObservance("white-days", "The white days",
                     month: 0, day: 0, span: 3,
                     timing: .recurring, group: .fasting,
                     fasting: .voluntary,
                     dateNote: "13, 14 and 15 of every Hijri month",
                     summary: "Three days in the middle of every Hijri month, named for the nights around the full moon when the sky stays light. Fasting them is the most commonly kept regular voluntary fast after Mondays and Thursdays, and it works out at roughly three days a month through the year. In Dhu al-Hijjah the thirteenth falls inside the days of Tashriq, so those who keep them shift or drop that one.",
                     marksGrid: false),

        VQObservance("mon-thu", "Mondays and Thursdays",
                     month: 0, day: 0,
                     timing: .recurring, group: .fasting,
                     fasting: .voluntary,
                     dateNote: "Every Monday and Thursday",
                     summary: "The most frequent of the regular voluntary fasts, kept twice a week through the year. They are dropped on the two Eids and the days of Tashriq, when fasting is not permitted. Because they follow the week rather than the month, they land on different Hijri dates each time.",
                     marksGrid: false),

        VQObservance("jumuah", "Jumu'ah, the Friday gathering",
                     month: 0, day: 0,
                     timing: .recurring, group: .landmark,
                     dateNote: "Every Friday",
                     summary: "The congregational prayer that replaces the midday prayer on Friday, preceded by a sermon. It is the weekly fixed point of the calendar and is obligatory for adult men who are able to attend. The Islamic day begins at sunset, so the Friday night that carries its own weight is the evening before.",
                     marksGrid: false),

        VQObservance("ayyam-bid-note", "The white days in Dhu al-Hijjah",
                     month: 12, day: 13, span: 1,
                     timing: .sightingLed, group: .restricted,
                     fasting: .notPermitted,
                     dateNote: "13 Dhu al-Hijjah",
                     summary: "The one month where the white days and the restricted days overlap: the thirteenth of Dhu al-Hijjah is the last of the days of Tashriq, on which fasting is not permitted. Those keeping the white days through the year therefore fast only the fourteenth and fifteenth this month. It is the clearest case of a restriction taking precedence over a voluntary practice.",
                     marksGrid: false),

        // ------------------------------------------------------------- Restricted
        VQObservance("no-fast-fitr", "Fasting is not permitted on Eid al-Fitr",
                     month: 10, day: 1,
                     timing: .sightingLed, group: .restricted,
                     fasting: .notPermitted,
                     dateNote: "1 Shawwal",
                     summary: "The day of Eid al-Fitr is a day of eating, and fasting it is not permitted even for someone making up missed days. The point is plain enough: the month of fasting has ended, and marking it by fasting would contradict the day. Missed Ramadan days are made up before or after it, not on it.",
                     marksGrid: false),

        VQObservance("no-fast-adha", "Fasting is not permitted on Eid al-Adha",
                     month: 12, day: 10,
                     timing: .sightingLed, group: .restricted,
                     fasting: .notPermitted,
                     dateNote: "10 Dhu al-Hijjah",
                     summary: "As with Eid al-Fitr, the day of sacrifice is not fasted. It follows immediately on the Day of Arafah, which many do fast, so the change from one day to the next is deliberate. Anyone keeping a run of voluntary fasts breaks it here.",
                     marksGrid: false),

        VQObservance("no-fast-tashriq", "Fasting is not permitted on the Days of Tashriq",
                     month: 12, day: 11, span: 3,
                     timing: .sightingLed, group: .restricted,
                     fasting: .notPermitted,
                     dateNote: "11 to 13 Dhu al-Hijjah",
                     summary: "The three days after Eid al-Adha are held in the same category as the Eid itself. The recognised exception is narrow: a pilgrim performing tamattu' or qiran who cannot obtain the required sacrifice. Outside that case the days are kept as days of eating and remembrance.",
                     marksGrid: false),

        VQObservance("no-fast-friday", "Singling out Friday for a fast",
                     month: 0, day: 0,
                     timing: .recurring, group: .restricted,
                     fasting: .discouraged,
                     dateNote: "Friday on its own",
                     summary: "Fasting Friday by itself is discouraged, on the ground that the day already has its own observance in the congregational prayer. Joining it to Thursday or Saturday removes the objection, and so does a fast that simply happens to land on it, such as the white days. The restriction is about singling the day out, not about the day itself.",
                     marksGrid: false),

        VQObservance("no-fast-saturday", "Singling out Saturday for a fast",
                     month: 0, day: 0,
                     timing: .recurring, group: .restricted,
                     fasting: .discouraged,
                     dateNote: "Saturday on its own",
                     summary: "Some scholars extend the same reasoning to Saturday, on the strength of a report that is itself debated. Others read the report narrowly or set it aside. As with Friday, joining the day to the one before or after settles the question in practice.",
                     marksGrid: false),

        VQObservance("no-fast-perpetual", "Fasting every day without a break",
                     month: 0, day: 0,
                     timing: .recurring, group: .restricted,
                     fasting: .discouraged,
                     dateNote: "Continuously, all year",
                     summary: "An unbroken fast kept year-round is discouraged, and in any case cannot be done, since the two Eids and the days of Tashriq are excluded. The pattern held up as the best is alternate days, which is more than most keep. The consistent theme is moderation rather than accumulation."),

        // ------------------------------------------------------------- Sacred months
        VQObservance("four-sacred", "The four sacred months",
                     month: 0, day: 0,
                     timing: .recurring, group: .sacredMonths,
                     dateNote: "Dhu al-Qadah, Dhu al-Hijjah, Muharram, Rajab",
                     summary: "Four of the twelve months are named as sacred: three in sequence at the turn of the year, and Rajab standing alone. Fighting was to be suspended in them, which made the pilgrimage and the trade around it possible. Their order in the year is fixed, and the abolition of the old intercalated month is what keeps it that way.",
                     marksGrid: false),

        VQObservance("no-intercalation", "Why the months drift",
                     month: 0, day: 0,
                     timing: .recurring, group: .sacredMonths,
                     dateNote: "Every year",
                     summary: "The Hijri year is twelve lunar months and about 354 days, so it runs roughly eleven days short of the solar year. Pre-Islamic Arabia patched the gap with an extra month; the Quran ended that practice, and the months have moved through the seasons ever since. Ramadan therefore works its way round the whole solar year in about thirty-three years.",
                     marksGrid: false)
    ]

    // MARK: Lookup

    static func byGroup(_ group: VQObservanceGroup) -> [VQObservance] {
        all.filter { $0.group == group }
    }

    /// Entries that occupy the given Hijri day, for the grid marker and the day sheet.
    static func marking(_ date: VQHijriDate) -> [VQObservance] {
        all.filter { entry in
            guard entry.marksGrid, entry.isDated, entry.month == date.month else { return false }
            return date.day >= entry.day && date.day < entry.day + max(1, entry.span)
        }
    }

    /// Everything that touches a day, whether or not it draws a marker.
    static func touching(_ date: VQHijriDate) -> [VQObservance] {
        all.filter { entry in
            guard entry.isDated, entry.month == date.month else { return false }
            return date.day >= entry.day && date.day < entry.day + max(1, entry.span)
        }
    }

    /// The countdown list. Every dated entry is resolved to its next start, then the
    /// nearest `limit` are returned.
    static func upcoming(fromJDN: Int, store: VQStore, limit: Int) -> [(observance: VQObservance, jdn: Int)] {
        let today = store.hijri(forJDN: fromJDN)
        var out: [(VQObservance, Int)] = []
        for entry in all where entry.isDated && entry.marksGrid {
            var year = today.year
            var found: Int? = nil
            for _ in 0...1 {
                let month = max(1, min(12, entry.month))
                let length = VQCalendar.hijriMonthLength(year: year, month: month)
                let day = min(entry.day, length)
                let jdn = store.jdn(forHijri: VQHijriDate(year: year, month: month, day: day))
                if jdn >= fromJDN { found = jdn; break }
                year += 1
            }
            if let jdn = found { out.append((entry, jdn)) }
        }
        out.sort { a, b in
            if a.1 != b.1 { return a.1 < b.1 }
            return a.0.name < b.0.name
        }
        return Array(out.prefix(limit)).map { (observance: $0.0, jdn: $0.1) }
    }
}
