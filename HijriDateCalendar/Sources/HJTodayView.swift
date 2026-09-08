import SwiftUI

struct HJTodayView: View {

    @EnvironmentObject private var store: HJStore
    var onOpenLibrary: () -> Void

    @State private var now = Date()
    /// Half-minute tick, so the clock line is honest without redrawing constantly. Static
    /// on purpose: a `Timer.publish` stored per instance would make a fresh timer on every
    /// re-render of the view struct.
    private static let clockTick = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var todayJDN: Int { store.todayJDN }
    private var hijri: HJHijriDate { store.hijri(forJDN: todayJDN) }
    private var civil: HJCivilDate { HJCalendar.civil(fromJDN: todayJDN) }
    private var weekday: Int { HJCalendar.weekdayIndex(jdn: todayJDN) }
    private var format: HJFormatter { store.formatter }

    private var monthLength: Int {
        HJCalendar.hijriMonthLength(year: hijri.year, month: hijri.month)
    }
    private var dayOfHijriYear: Int { HJCalendar.hijriDayOfYear(hijri) }
    private var hijriYearLength: Int { HJCalendar.hijriYearLength(hijri.year) }
    private var daysLeftInYear: Int { max(0, hijriYearLength - dayOfHijriYear) }
    private var fasting: HJDayFasting { HJFasting.status(forJDN: todayJDN, store: store) }
    private var upcoming: [(observance: HJObservance, jdn: Int)] {
        HJObservances.upcoming(fromJDN: todayJDN, store: store, limit: 8)
    }
    private var personalSoon: [(entry: HJPersonalDate, jdn: Int)] {
        store.personalDates
            .map { (entry: $0, jdn: store.nextOccurrenceJDN(of: $0, fromJDN: todayJDN)) }
            .sorted { $0.jdn < $1.jdn }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        HJScreen(title: "Today",
                 subtitle: format.weekdayName(weekday) + "  \u{00B7}  " + HJNames.weekday(weekday, arabic: !store.arabicWeekdays)) {
            headlineCard
            monthProgressCard
            fastingCard
            if !personalSoon.isEmpty { personalCard }
            countdownCard
            HJEstimateNote()
                .padding(.horizontal, 2)
                .padding(.top, 2)
        }
        // Redraw when the app comes back after midnight.
        .id(store.dayTick)
        .onReceive(HJTodayView.clockTick) { stamp in now = stamp }
    }

    // MARK: Headline

    private var headlineCard: some View {
        HJCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 3) {
                        HJCaption(text: store.hijriLeads ? "Hijri" : "Gregorian", color: HJTheme.gold)
                        Text(primaryBig)
                            .font(HJTheme.display(HJLayout.isNarrow ? 25 : 29))
                            .foregroundColor(HJTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(primarySmall)
                            .font(HJTheme.body(12.5))
                            .foregroundColor(HJTheme.inkSoft)
                    }
                    Spacer(minLength: 6)
                    HJGlyph(shape: HJCrescentShape(thinness: 0.44), size: 42,
                            color: HJTheme.gold.opacity(0.85), filled: true)
                        .padding(.top, 4)
                }

                HJDivider()

                VStack(alignment: .leading, spacing: 3) {
                    HJCaption(text: store.hijriLeads ? "Gregorian" : "Hijri",
                              color: HJTheme.indigo)
                    Text(secondaryBig)
                        .font(HJTheme.display(HJLayout.isNarrow ? 18 : 20))
                        .foregroundColor(HJTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HJDivider()

                HStack(alignment: .center, spacing: 8) {
                    Text(HJClock.text(twentyFourHour: store.twentyFourHour, date: now))
                        .font(HJTheme.mono(13, .medium))
                        .foregroundColor(HJTheme.ink)
                    Text("The Hijri day turns at sunset, so this evening already belongs to \(format.hijriDayMonth(store.hijri(forJDN: todayJDN + 1))).")
                        .font(HJTheme.body(10.5))
                        .foregroundColor(HJTheme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if store.adjustment != 0 {
                    HJChip(text: "Shift applied: " + store.adjustmentLabel, tint: HJTheme.gold)
                }
            }
        }
    }

    private var primaryBig: String {
        store.hijriLeads ? format.hijriDayMonth(hijri) : "\(civil.day) \(HJNames.civilMonth(civil.month))"
    }

    private var primarySmall: String {
        store.hijriLeads ? "\(hijri.year) AH" : "\(civil.year) CE"
    }

    private var secondaryBig: String {
        store.hijriLeads ? format.civilLong(civil) : format.hijriLong(hijri)
    }

    // MARK: Month progress

    private var monthProgressCard: some View {
        HJCard {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    HJMonthDial(total: monthLength, elapsed: hijri.day, size: 68)
                    VStack(spacing: 0) {
                        Text("\(hijri.day)")
                            .font(HJTheme.figure(20, .semibold))
                            .foregroundColor(HJTheme.ink)
                        Text("of \(monthLength)")
                            .font(HJTheme.body(9.5))
                            .foregroundColor(HJTheme.inkFaint)
                    }
                }
                .frame(width: 68, height: 68)

                VStack(alignment: .leading, spacing: 7) {
                    Text(format.hijriMonthYear(hijri))
                        .font(HJTheme.display(16))
                        .foregroundColor(HJTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    HJProgressBar(fraction: Double(hijri.day) / Double(max(1, monthLength)))
                    Text("\(max(0, monthLength - hijri.day)) day\(monthLength - hijri.day == 1 ? "" : "s") left in the month  \u{00B7}  \(monthLength)-day month")
                        .font(HJTheme.body(11))
                        .foregroundColor(HJTheme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HJDivider()

            HStack(spacing: 0) {
                yearStat("Day of the year", "\(dayOfHijriYear)")
                Rectangle().fill(HJTheme.ruleSoft).frame(width: 1, height: 30)
                yearStat("Days left", "\(daysLeftInYear)")
                Rectangle().fill(HJTheme.ruleSoft).frame(width: 1, height: 30)
                yearStat("Year length", "\(hijriYearLength)")
            }

            Text(HJCalendar.isLeapHijriYear(hijri.year)
                 ? "\(hijri.year) AH is a leap year in the tabular calendar, so Dhu al-Hijjah runs to thirty days."
                 : "\(hijri.year) AH is an ordinary year in the tabular calendar, so Dhu al-Hijjah runs to twenty-nine days.")
                .font(HJTheme.body(11))
                .foregroundColor(HJTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func yearStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(HJTheme.figure(17, .semibold))
                .foregroundColor(HJTheme.ink)
            Text(label)
                .font(HJTheme.body(10))
                .foregroundColor(HJTheme.inkFaint)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Fasting

    private var fastingCard: some View {
        HJCard(tint: fasting.kind == .notPermitted ? HJTheme.claySoft.opacity(0.5) : HJTheme.card,
               border: fasting.kind == .notPermitted ? HJTheme.clay.opacity(0.35) : HJTheme.rule) {
            HStack(alignment: .center, spacing: 10) {
                HJCaption(text: "Fasting today", color: HJTheme.inkFaint)
                Spacer(minLength: 6)
                HJChip(text: fasting.kind.label, tint: fasting.kind.tint)
            }
            if fasting.notes.isEmpty {
                Text("No fast is prescribed today. The regular voluntary days are Mondays, Thursdays and the thirteenth to fifteenth of each Hijri month.")
                    .font(HJTheme.body(12.5))
                    .foregroundColor(HJTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(fasting.notes) { note in
                        HStack(alignment: .top, spacing: 8) {
                            HJGlyph(shape: HJLozengeShape(), size: 8,
                                    color: note.kind.tint, filled: true)
                                .padding(.top, 4)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(note.label)
                                    .font(HJTheme.body(12.5, .semibold))
                                    .foregroundColor(HJTheme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(note.detail)
                                    .font(HJTheme.body(11.5))
                                    .foregroundColor(HJTheme.inkSoft)
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
        HJCard {
            HStack {
                HJCaption(text: "Your dates")
                Spacer(minLength: 6)
                Button(action: onOpenLibrary) {
                    HStack(spacing: 4) {
                        Text("All")
                            .font(HJTheme.body(11.5, .medium))
                            .foregroundColor(HJTheme.gold)
                        HJGlyph(shape: HJChevronShape(direction: 0), size: 9,
                                color: HJTheme.gold, lineWidth: 1.7)
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
                                .font(HJTheme.body(13, .semibold))
                                .foregroundColor(HJTheme.ink)
                                .lineLimit(1)
                            Text(format.civilShort(HJCalendar.civil(fromJDN: item.jdn))
                                 + "  \u{00B7}  " + format.hijriDayMonth(store.hijri(forJDN: item.jdn)))
                                .font(HJTheme.body(11))
                                .foregroundColor(HJTheme.inkFaint)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        Spacer(minLength: 6)
                        Text(HJFormatter.relativeDays(delta))
                            .font(HJTheme.body(11.5, .semibold))
                            .foregroundColor(delta == 0 ? HJTheme.gold : HJTheme.verdant)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 7)
                    if index < personalSoon.count - 1 { HJDivider() }
                }
            }
        }
    }

    // MARK: Countdowns

    private var countdownCard: some View {
        HJCard {
            HJCaption(text: "Next observances")
            if upcoming.isEmpty {
                HJEmptyState(headline: "Nothing scheduled",
                             message: "No dated observance could be resolved for this year.")
            } else {
                VStack(spacing: 0) {
                    ForEach(upcoming.indices, id: \.self) { index in
                        let item = upcoming[index]
                        countdownRow(item.observance, item.jdn)
                        if index < upcoming.count - 1 { HJDivider() }
                    }
                }
            }
            Text("Countdowns follow the calculated calendar. An announced sighting can move any of them by a day.")
                .font(HJTheme.body(10.5))
                .foregroundColor(HJTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func countdownRow(_ entry: HJObservance, _ jdn: Int) -> some View {
        let delta = jdn - todayJDN
        let hijriDate = store.hijri(forJDN: jdn)
        return HStack(alignment: .center, spacing: 10) {
            HJGlyph(shape: HJStarShape(points: 8, innerRatio: 0.44), size: 11,
                    color: entry.timing.tint, filled: true)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(HJTheme.body(13, .semibold))
                    .foregroundColor(HJTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(format.hijriDayMonth(hijriDate) + " \u{00B7} "
                     + format.civilShort(HJCalendar.civil(fromJDN: jdn)))
                    .font(HJTheme.body(11))
                    .foregroundColor(HJTheme.inkFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 1) {
                Text(delta == 0 ? "Today" : "\(delta)")
                    .font(HJTheme.figure(delta == 0 ? 12 : 16, .semibold))
                    .foregroundColor(delta == 0 ? HJTheme.gold : HJTheme.ink)
                if delta != 0 {
                    Text(delta == 1 ? "day" : "days")
                        .font(HJTheme.body(9.5))
                        .foregroundColor(HJTheme.inkFaint)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
