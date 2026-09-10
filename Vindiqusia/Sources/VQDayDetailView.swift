import SwiftUI

/// The sheet a tap on a grid cell opens. Everything the app knows about one day.
struct VQDayDetailView: View {

    @EnvironmentObject private var store: VQStore
    let jdn: Int
    var onClose: () -> Void

    private var format: VQFormatter { store.formatter }
    private var hijri: VQHijriDate { store.hijri(forJDN: jdn) }
    private var civil: VQCivilDate { VQCalendar.civil(fromJDN: jdn) }
    private var weekday: Int { VQCalendar.weekdayIndex(jdn: jdn) }
    private var delta: Int { jdn - store.todayJDN }
    private var observances: [VQObservance] { VQObservances.touching(hijri) }
    private var fasting: VQDayFasting { VQFasting.status(forJDN: jdn, store: store) }

    private var personal: [VQPersonalDate] {
        store.personalDates.filter { entry in
            let resolved = store.resolvedAnchor(entry.anchor, inYear: hijri.year)
            return resolved.month == hijri.month && resolved.day == hijri.day
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            VQTheme.paper.edgesIgnoringSafeArea(.all)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 13) {
                    headerRow
                    datesCard
                    if !observances.isEmpty { observanceCard }
                    if !personal.isEmpty { personalCard }
                    fastingCard
                    numbersCard
                    VQEstimateNote()
                        .padding(.horizontal, 2)
                }
                .padding(.horizontal, VQLayout.screenInset)
                .padding(.top, 16)
                .padding(.bottom, 32)
                .frame(maxWidth: VQLayout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(format.weekdayName(weekday))
                    .font(VQTheme.display(22))
                    .foregroundColor(VQTheme.ink)
                Text(VQFormatter.relativeDays(delta))
                    .font(VQTheme.body(12.5))
                    .foregroundColor(delta == 0 ? VQTheme.gold : VQTheme.inkSoft)
            }
            Spacer(minLength: 6)
            Button(action: onClose) {
                VQGlyph(shape: VQCrossShape(), size: 14, color: VQTheme.inkSoft, lineWidth: 1.8)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(VQTheme.cardAlt))
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var datesCard: some View {
        VQCard {
            VStack(alignment: .leading, spacing: 3) {
                VQCaption(text: "Hijri", color: VQTheme.gold)
                Text(format.hijriLong(hijri))
                    .font(VQTheme.display(19))
                    .foregroundColor(VQTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VQDivider()
            VStack(alignment: .leading, spacing: 3) {
                VQCaption(text: "Gregorian", color: VQTheme.indigo)
                Text(format.civilLong(civil))
                    .font(VQTheme.display(19))
                    .foregroundColor(VQTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VQDivider()
            VQFactRow(key: "Weekday, English", value: VQNames.weekday(weekday, arabic: false))
            VQFactRow(key: "Weekday, transliterated", value: VQNames.weekday(weekday, arabic: true))
        }
    }

    private var observanceCard: some View {
        VQCard {
            VQCaption(text: observances.count == 1 ? "Observance" : "Observances")
            VStack(alignment: .leading, spacing: 12) {
                ForEach(observances) { entry in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .center, spacing: 8) {
                            VQGlyph(shape: VQStarShape(points: 8, innerRatio: 0.44), size: 11,
                                    color: entry.timing.tint, filled: true)
                            Text(entry.name)
                                .font(VQTheme.body(14, .semibold))
                                .foregroundColor(VQTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        HStack(spacing: 6) {
                            VQChip(text: entry.dateNote, tint: VQTheme.inkSoft)
                            VQChip(text: entry.timing.label, tint: entry.timing.tint)
                        }
                        Text(entry.summary)
                            .font(VQTheme.body(12))
                            .foregroundColor(VQTheme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if entry.id != observances.last?.id { VQDivider() }
                }
            }
        }
    }

    private var personalCard: some View {
        VQCard(tint: VQTheme.indigoSoft.opacity(0.45), border: VQTheme.indigo.opacity(0.3)) {
            VQCaption(text: "Your dates", color: VQTheme.indigo)
            VStack(alignment: .leading, spacing: 9) {
                ForEach(personal) { entry in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.title)
                            .font(VQTheme.body(14, .semibold))
                            .foregroundColor(VQTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(yearsLine(for: entry))
                            .font(VQTheme.body(11.5))
                            .foregroundColor(VQTheme.inkSoft)
                        if !entry.note.isEmpty {
                            Text(entry.note)
                                .font(VQTheme.body(11.5))
                                .foregroundColor(VQTheme.inkFaint)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func yearsLine(for entry: VQPersonalDate) -> String {
        let years = hijri.year - entry.originYear
        if years <= 0 { return entry.kindName + "  \u{00B7}  first year" }
        if entry.kind == 1 { return "\(years) Hijri year\(years == 1 ? "" : "s") old" }
        return "\(VQFormatter.ordinal(years)) Hijri anniversary"
    }

    private var fastingCard: some View {
        VQCard(tint: fasting.kind == .notPermitted ? VQTheme.claySoft.opacity(0.45) : VQTheme.card,
               border: fasting.kind == .notPermitted ? VQTheme.clay.opacity(0.35) : VQTheme.rule) {
            HStack {
                VQCaption(text: "Fasting")
                Spacer(minLength: 6)
                VQChip(text: fasting.kind.label, tint: fasting.kind.tint)
            }
            if fasting.notes.isEmpty {
                Text("Nothing prescribed for this day.")
                    .font(VQTheme.body(12))
                    .foregroundColor(VQTheme.inkSoft)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(fasting.notes) { note in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(note.label)
                                .font(VQTheme.body(12.5, .semibold))
                                .foregroundColor(note.kind.tint)
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

    private var numbersCard: some View {
        VQCard {
            VQCaption(text: "The numbers")
            VQFactRow(key: "Day of the Hijri month",
                      value: "\(hijri.day) of \(VQCalendar.hijriMonthLength(year: hijri.year, month: hijri.month))")
            VQDivider()
            VQFactRow(key: "Day of the Hijri year",
                      value: "\(VQCalendar.hijriDayOfYear(hijri)) of \(VQCalendar.hijriYearLength(hijri.year))")
            VQDivider()
            VQFactRow(key: "Day of the Gregorian year",
                      value: "\(VQCalendar.civilDayOfYear(civil)) of \(VQCalendar.civilYearLength(civil.year))")
            VQDivider()
            VQFactRow(key: "Julian Day Number", value: "\(jdn)", mono: true)
            VQDivider()
            VQFactRow(key: "From today",
                      value: delta == 0 ? "0 days" : "\(delta > 0 ? "+" : "")\(delta) days",
                      valueColor: delta == 0 ? VQTheme.gold : VQTheme.ink,
                      mono: true)
            if store.adjustment != 0 {
                VQDivider()
                VQFactRow(key: "Your shift", value: store.adjustmentLabel, valueColor: VQTheme.gold)
            }
        }
    }
}
