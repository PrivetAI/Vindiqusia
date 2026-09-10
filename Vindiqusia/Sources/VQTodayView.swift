import SwiftUI

struct VQTodayView: View {

    @EnvironmentObject private var store: VQStore

    @State private var now = Date()
    /// Half-minute tick, so the clock line is honest without redrawing constantly. Static
    /// on purpose: a `Timer.publish` stored per instance would make a fresh timer on every
    /// re-render of the view struct.
    private static let clockTick = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var todayJDN: Int { store.todayJDN }
    private var hijri: VQHijriDate { store.hijri(forJDN: todayJDN) }
    private var civil: VQCivilDate { VQCalendar.civil(fromJDN: todayJDN) }
    private var weekday: Int { VQCalendar.weekdayIndex(jdn: todayJDN) }
    private var format: VQFormatter { store.formatter }

    private var monthLength: Int {
        VQCalendar.hijriMonthLength(year: hijri.year, month: hijri.month)
    }
    private var dayOfHijriYear: Int { VQCalendar.hijriDayOfYear(hijri) }
    private var hijriYearLength: Int { VQCalendar.hijriYearLength(hijri.year) }
    private var daysLeftInYear: Int { max(0, hijriYearLength - dayOfHijriYear) }
    private var fasting: VQDayFasting { VQFasting.status(forJDN: todayJDN, store: store) }
    private var upcoming: [(observance: VQObservance, jdn: Int)] {
        VQObservances.upcoming(fromJDN: todayJDN, store: store, limit: 8)
    }
    private var personalSoon: [(entry: VQPersonalDate, jdn: Int)] {
        store.personalDates
            .map { (entry: $0, jdn: store.nextOccurrenceJDN(of: $0, fromJDN: todayJDN)) }
            .sorted { $0.jdn < $1.jdn }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        VQScreen(title: "Today",
                 subtitle: format.weekdayName(weekday) + "  \u{00B7}  " + VQNames.weekday(weekday, arabic: !store.arabicWeekdays)) {
            headlineCard
            monthProgressCard
            fastingCard
            if !personalSoon.isEmpty { personalCard }
            countdownCard
            VQEstimateNote()
                .padding(.horizontal, 2)
                .padding(.top, 2)
        }
        // Redraw when the app comes back after midnight.
        .id(store.dayTick)
        .onReceive(VQTodayView.clockTick) { stamp in now = stamp }
    }

    // MARK: Headline

    private var headlineCard: some View {
        VQCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 3) {
                        VQCaption(text: store.hijriLeads ? "Hijri" : "Gregorian", color: VQTheme.gold)
                        Text(primaryBig)
                            .font(VQTheme.display(VQLayout.isNarrow ? 25 : 29))
                            .foregroundColor(VQTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(primarySmall)
                            .font(VQTheme.body(12.5))
                            .foregroundColor(VQTheme.inkSoft)
                    }
                    Spacer(minLength: 6)
                    VQGlyph(shape: VQCrescentShape(thinness: 0.44), size: 42,
                            color: VQTheme.gold.opacity(0.85), filled: true)
                        .padding(.top, 4)
                }

                VQDivider()

                VStack(alignment: .leading, spacing: 3) {
                    VQCaption(text: store.hijriLeads ? "Gregorian" : "Hijri",
                              color: VQTheme.indigo)
                    Text(secondaryBig)
                        .font(VQTheme.display(VQLayout.isNarrow ? 18 : 20))
                        .foregroundColor(VQTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VQDivider()

                HStack(alignment: .center, spacing: 8) {
                    Text(VQClock.text(twentyFourHour: store.twentyFourHour, date: now))
                        .font(VQTheme.mono(13, .medium))
                        .foregroundColor(VQTheme.ink)
                    Text("The Hijri day turns at sunset, so this evening already belongs to \(format.hijriDayMonth(store.hijri(forJDN: todayJDN + 1))).")
                        .font(VQTheme.body(10.5))
                        .foregroundColor(VQTheme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if store.adjustment != 0 {
                    VQChip(text: "Shift applied: " + store.adjustmentLabel, tint: VQTheme.gold)
                }
            }
        }
    }

    private var primaryBig: String {
        store.hijriLeads ? format.hijriDayMonth(hijri) : "\(civil.day) \(VQNames.civilMonth(civil.month))"
    }

    private var primarySmall: String {
        store.hijriLeads ? "\(hijri.year) AH" : "\(civil.year) CE"
    }

    private var secondaryBig: String {
        store.hijriLeads ? format.civilLong(civil) : format.hijriLong(hijri)
    }

    // MARK: Month progress

    private var monthProgressCard: some View {
        VQCard {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    VQMonthDial(total: monthLength, elapsed: hijri.day, size: 68)
                    VStack(spacing: 0) {
                        Text("\(hijri.day)")
                            .font(VQTheme.figure(20, .semibold))
                            .foregroundColor(VQTheme.ink)
                        Text("of \(monthLength)")
                            .font(VQTheme.body(9.5))
                            .foregroundColor(VQTheme.inkFaint)
                    }
                }
                .frame(width: 68, height: 68)

                VStack(alignment: .leading, spacing: 7) {
                    Text(format.hijriMonthYear(hijri))
                        .font(VQTheme.display(16))
                        .foregroundColor(VQTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    VQProgressBar(fraction: Double(hijri.day) / Double(max(1, monthLength)))
                    Text("\(max(0, monthLength - hijri.day)) day\(monthLength - hijri.day == 1 ? "" : "s") left in the month  \u{00B7}  \(monthLength)-day month")
                        .font(VQTheme.body(11))
                        .foregroundColor(VQTheme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VQDivider()

            HStack(spacing: 0) {
                yearStat("Day of the year", "\(dayOfHijriYear)")
                Rectangle().fill(VQTheme.ruleSoft).frame(width: 1, height: 30)
                yearStat("Days left", "\(daysLeftInYear)")
                Rectangle().fill(VQTheme.ruleSoft).frame(width: 1, height: 30)
                yearStat("Year length", "\(hijriYearLength)")
            }

            Text(verbatim: VQCalendar.isLeapHijriYear(hijri.year)
                 ? "\(hijri.year) AH is a leap year in the tabular calendar, so Dhu al-Hijjah runs to thirty days."
                 : "\(hijri.year) AH is an ordinary year in the tabular calendar, so Dhu al-Hijjah runs to twenty-nine days.")
                .font(VQTheme.body(11))
                .foregroundColor(VQTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func yearStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(VQTheme.figure(17, .semibold))
                .foregroundColor(VQTheme.ink)
            Text(label)
                .font(VQTheme.body(10))
                .foregroundColor(VQTheme.inkFaint)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Fasting

    private var fastingCard: some View {
        VQCard(tint: fasting.kind == .notPermitted ? VQTheme.claySoft.opacity(0.5) : VQTheme.card,
               border: fasting.kind == .notPermitted ? VQTheme.clay.opacity(0.35) : VQTheme.rule) {
            HStack(alignment: .center, spacing: 10) {
                VQCaption(text: "Fasting today", color: VQTheme.inkFaint)
                Spacer(minLength: 6)
                VQChip(text: fasting.kind.label, tint: fasting.kind.tint)
            }
            if fasting.notes.isEmpty {
                Text("No fast is prescribed today. The regular voluntary days are Mondays, Thursdays and the thirteenth to fifteenth of each Hijri month.")
                    .font(VQTheme.body(12.5))
                    .foregroundColor(VQTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(fasting.notes) { note in
                        HStack(alignment: .top, spacing: 8) {
                            VQGlyph(shape: VQLozengeShape(), size: 8,
                                    color: note.kind.tint, filled: true)
                                .padding(.top, 4)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(note.label)
                                    .font(VQTheme.body(12.5, .semibold))
                                    .foregroundColor(VQTheme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(note.detail)
                                    .font(VQTheme.body(11.5))
                                    .foregroundColor(VQTheme.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Personal dates

    private var personalCard: some View {
        VQCard {
            HStack {
                VQCaption(text: "Your dates")
                Spacer(minLength: 6)
                // Straight to the dates list, not to the Library hub one level above it.
                NavigationLink(destination: VQPersonalDatesView().environmentObject(store)) {
                    HStack(spacing: 4) {
                        Text("All")
                            .font(VQTheme.body(11.5, .medium))
                            .foregroundColor(VQTheme.gold)
                        VQGlyph(shape: VQChevronShape(direction: 0), size: 9,
                                color: VQTheme.gold, lineWidth: 1.7)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            VStack(spacing: 0) {
                ForEach(personalSoon.indices, id: \.self) { index in
                    let item = personalSoon[index]
                    let delta = item.jdn - todayJDN
                    HStack(alignment: .center, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.entry.title)
                                .font(VQTheme.body(13, .semibold))
                                .foregroundColor(VQTheme.ink)
                                .lineLimit(1)
                            Text(format.civilShort(VQCalendar.civil(fromJDN: item.jdn))
                                 + "  \u{00B7}  " + format.hijriDayMonth(store.hijri(forJDN: item.jdn)))
                                .font(VQTheme.body(11))
                                .foregroundColor(VQTheme.inkFaint)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        Spacer(minLength: 6)
                        Text(VQFormatter.relativeDays(delta))
                            .font(VQTheme.body(11.5, .semibold))
                            .foregroundColor(delta == 0 ? VQTheme.gold : VQTheme.verdant)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 7)
                    if index < personalSoon.count - 1 { VQDivider() }
                }
            }
        }
    }

    // MARK: Countdowns

    private var countdownCard: some View {
        VQCard {
            VQCaption(text: "Next observances")
            if upcoming.isEmpty {
                VQEmptyState(headline: "Nothing scheduled",
                             message: "No dated observance could be resolved for this year.")
            } else {
                VStack(spacing: 0) {
                    ForEach(upcoming.indices, id: \.self) { index in
                        let item = upcoming[index]
                        countdownRow(item.observance, item.jdn)
                        if index < upcoming.count - 1 { VQDivider() }
                    }
                }
            }
            Text("Countdowns follow the calculated calendar. An announced sighting can move any of them by a day.")
                .font(VQTheme.body(10.5))
                .foregroundColor(VQTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func countdownRow(_ entry: VQObservance, _ jdn: Int) -> some View {
        let delta = jdn - todayJDN
        let hijriDate = store.hijri(forJDN: jdn)
        return HStack(alignment: .center, spacing: 10) {
            VQGlyph(shape: VQStarShape(points: 8, innerRatio: 0.44), size: 11,
                    color: entry.timing.tint, filled: true)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(VQTheme.body(13, .semibold))
                    .foregroundColor(VQTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(format.hijriDayMonth(hijriDate) + " \u{00B7} "
                     + format.civilShort(VQCalendar.civil(fromJDN: jdn)))
                    .font(VQTheme.body(11))
                    .foregroundColor(VQTheme.inkFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 1) {
                Text(delta == 0 ? "Today" : "\(delta)")
                    .font(VQTheme.figure(delta == 0 ? 12 : 16, .semibold))
                    .foregroundColor(delta == 0 ? VQTheme.gold : VQTheme.ink)
                if delta != 0 {
                    Text(delta == 1 ? "day" : "days")
                        .font(VQTheme.body(9.5))
                        .foregroundColor(VQTheme.inkFaint)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
