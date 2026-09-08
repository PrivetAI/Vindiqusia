import SwiftUI

/// The sheet a tap on a grid cell opens. Everything the app knows about one day.
struct HJDayDetailView: View {

    @EnvironmentObject private var store: HJStore
    let jdn: Int
    var onClose: () -> Void

    private var format: HJFormatter { store.formatter }
    private var hijri: HJHijriDate { store.hijri(forJDN: jdn) }
    private var civil: HJCivilDate { HJCalendar.civil(fromJDN: jdn) }
    private var weekday: Int { HJCalendar.weekdayIndex(jdn: jdn) }
    private var delta: Int { jdn - store.todayJDN }
    private var observances: [HJObservance] { HJObservances.touching(hijri) }
    private var fasting: HJDayFasting { HJFasting.status(forJDN: jdn, store: store) }

    private var personal: [HJPersonalDate] {
        store.personalDates.filter { entry in
            let resolved = store.resolvedAnchor(entry.anchor, inYear: hijri.year)
            return resolved.month == hijri.month && resolved.day == hijri.day
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            HJTheme.paper.edgesIgnoringSafeArea(.all)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 13) {
                    headerRow
                    datesCard
                    if !observances.isEmpty { observanceCard }
                    if !personal.isEmpty { personalCard }
                    fastingCard
                    numbersCard
                    HJEstimateNote()
                        .padding(.horizontal, 2)
                }
                .padding(.horizontal, HJLayout.screenInset)
                .padding(.top, 16)
                .padding(.bottom, 32)
                .frame(maxWidth: HJLayout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(format.weekdayName(weekday))
                    .font(HJTheme.display(22))
                    .foregroundColor(HJTheme.ink)
                Text(HJFormatter.relativeDays(delta))
                    .font(HJTheme.body(12.5))
                    .foregroundColor(delta == 0 ? HJTheme.gold : HJTheme.inkSoft)
            }
            Spacer(minLength: 6)
            Button(action: onClose) {
                HJGlyph(shape: HJCrossShape(), size: 14, color: HJTheme.inkSoft, lineWidth: 1.8)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(HJTheme.cardAlt))
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var datesCard: some View {
        HJCard {
            VStack(alignment: .leading, spacing: 3) {
                HJCaption(text: "Hijri", color: HJTheme.gold)
                Text(format.hijriLong(hijri))
                    .font(HJTheme.display(19))
                    .foregroundColor(HJTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HJDivider()
            VStack(alignment: .leading, spacing: 3) {
                HJCaption(text: "Gregorian", color: HJTheme.indigo)
                Text(format.civilLong(civil))
                    .font(HJTheme.display(19))
                    .foregroundColor(HJTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HJDivider()
            HJFactRow(key: "Weekday, English", value: HJNames.weekday(weekday, arabic: false))
            HJFactRow(key: "Weekday, transliterated", value: HJNames.weekday(weekday, arabic: true))
        }
    }

    private var observanceCard: some View {
        HJCard {
            HJCaption(text: observances.count == 1 ? "Observance" : "Observances")
            VStack(alignment: .leading, spacing: 12) {
                ForEach(observances) { entry in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .center, spacing: 8) {
                            HJGlyph(shape: HJStarShape(points: 8, innerRatio: 0.44), size: 11,
                                    color: entry.timing.tint, filled: true)
                            Text(entry.name)
                                .font(HJTheme.body(14, .semibold))
                                .foregroundColor(HJTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        HStack(spacing: 6) {
                            HJChip(text: entry.dateNote, tint: HJTheme.inkSoft)
                            HJChip(text: entry.timing.label, tint: entry.timing.tint)
                        }
                        Text(entry.summary)
                            .font(HJTheme.body(12))
                            .foregroundColor(HJTheme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if entry.id != observances.last?.id { HJDivider() }
                }
            }
        }
    }

    private var personalCard: some View {
        HJCard(tint: HJTheme.indigoSoft.opacity(0.45), border: HJTheme.indigo.opacity(0.3)) {
            HJCaption(text: "Your dates", color: HJTheme.indigo)
            VStack(alignment: .leading, spacing: 9) {
                ForEach(personal) { entry in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.title)
                            .font(HJTheme.body(14, .semibold))
                            .foregroundColor(HJTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(yearsLine(for: entry))
                            .font(HJTheme.body(11.5))
                            .foregroundColor(HJTheme.inkSoft)
                        if !entry.note.isEmpty {
                            Text(entry.note)
                                .font(HJTheme.body(11.5))
                                .foregroundColor(HJTheme.inkFaint)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func yearsLine(for entry: HJPersonalDate) -> String {
        let years = hijri.year - entry.originYear
        if years <= 0 { return entry.kindName + "  \u{00B7}  first year" }
        if entry.kind == 1 { return "\(years) Hijri year\(years == 1 ? "" : "s") old" }
        return "\(HJFormatter.ordinal(years)) Hijri anniversary"
    }

    private var fastingCard: some View {
        HJCard(tint: fasting.kind == .notPermitted ? HJTheme.claySoft.opacity(0.45) : HJTheme.card,
               border: fasting.kind == .notPermitted ? HJTheme.clay.opacity(0.35) : HJTheme.rule) {
            HStack {
                HJCaption(text: "Fasting")
                Spacer(minLength: 6)
                HJChip(text: fasting.kind.label, tint: fasting.kind.tint)
            }
            if fasting.notes.isEmpty {
                Text("Nothing prescribed for this day.")
                    .font(HJTheme.body(12))
                    .foregroundColor(HJTheme.inkSoft)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(fasting.notes) { note in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(note.label)
                                .font(HJTheme.body(12.5, .semibold))
                                .foregroundColor(note.kind.tint)
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

    private var numbersCard: some View {
        HJCard {
            HJCaption(text: "The numbers")
            HJFactRow(key: "Day of the Hijri month",
                      value: "\(hijri.day) of \(HJCalendar.hijriMonthLength(year: hijri.year, month: hijri.month))")
            HJDivider()
            HJFactRow(key: "Day of the Hijri year",
                      value: "\(HJCalendar.hijriDayOfYear(hijri)) of \(HJCalendar.hijriYearLength(hijri.year))")
            HJDivider()
            HJFactRow(key: "Day of the Gregorian year",
                      value: "\(HJCalendar.civilDayOfYear(civil)) of \(HJCalendar.civilYearLength(civil.year))")
            HJDivider()
            HJFactRow(key: "Julian Day Number", value: "\(jdn)", mono: true)
            HJDivider()
            HJFactRow(key: "From today",
                      value: delta == 0 ? "0 days" : "\(delta > 0 ? "+" : "")\(delta) days",
                      valueColor: delta == 0 ? HJTheme.gold : HJTheme.ink,
                      mono: true)
            if store.adjustment != 0 {
                HJDivider()
                HJFactRow(key: "Your shift", value: store.adjustmentLabel, valueColor: HJTheme.gold)
            }
        }
    }
}
