import SwiftUI

struct HJFastingView: View {

    @EnvironmentObject private var store: HJStore
    @Environment(\.presentationMode) private var presentation

    /// Offset in Hijri months from the current one.
    @State private var monthOffset: Int = 0

    private var format: HJFormatter { store.formatter }
    private var todayJDN: Int { store.todayJDN }
    private var todayHijri: HJHijriDate { store.hijri(forJDN: todayJDN) }

    private var shown: (year: Int, month: Int) {
        var year = todayHijri.year
        var month = todayHijri.month + monthOffset
        while month > 12 { month -= 12; year += 1 }
        while month < 1 { month += 12; year -= 1 }
        year = max(HJCalendar.minHijriYear, min(HJCalendar.maxHijriYear, year))
        return (year, month)
    }

    private var days: [HJDayFasting] {
        HJFasting.month(year: shown.year, month: shown.month, store: store)
    }

    private var restricted: [HJDayFasting] {
        HJFasting.restrictedDays(year: shown.year, store: store)
    }

    var body: some View {
        HJDetailScreen(title: "Fasting days",
                       subtitle: "What the calendar marks, month by month",
                       onBack: { presentation.wrappedValue.dismiss() }) {
            navigator
            monthCard
            restrictedCard
            referenceCard
            HJEstimateNote()
                .padding(.horizontal, 2)
        }
    }

    private var navigator: some View {
        HJCard(padding: 10) {
            HStack(spacing: 6) {
                stepButton(direction: 1) { if monthOffset > -240 { monthOffset -= 1 } }
                VStack(spacing: 1) {
                    Text("\(format.hijriMonthName(shown.month)) \(shown.year) AH")
                        .font(HJTheme.display(16))
                        .foregroundColor(HJTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text(gregorianSpan)
                        .font(HJTheme.body(10.5))
                        .foregroundColor(HJTheme.inkFaint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                stepButton(direction: 0) { if monthOffset < 240 { monthOffset += 1 } }
            }
            if monthOffset != 0 {
                Button(action: { monthOffset = 0 }) {
                    Text("Back to this month")
                        .font(HJTheme.body(12, .medium))
                        .foregroundColor(HJTheme.gold)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 11)
                        .background(RoundedRectangle(cornerRadius: 8).fill(HJTheme.goldWash))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var gregorianSpan: String {
        let length = HJCalendar.hijriMonthLength(year: shown.year, month: shown.month)
        let first = store.jdn(forHijri: HJHijriDate(year: shown.year, month: shown.month, day: 1))
        let last = first + length - 1
        return format.civilShort(HJCalendar.civil(fromJDN: first))
            + " \u{2013} " + format.civilShort(HJCalendar.civil(fromJDN: last))
    }

    private func stepButton(direction: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HJGlyph(shape: HJChevronShape(direction: direction), size: 13,
                    color: HJTheme.ink, lineWidth: 2)
                .frame(width: 38, height: 36)
                .background(RoundedRectangle(cornerRadius: 9).fill(HJTheme.cardAlt))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var monthCard: some View {
        HJCard {
            HStack {
                HJCaption(text: "This month")
                Spacer(minLength: 6)
                Text("\(days.count) marked day\(days.count == 1 ? "" : "s")")
                    .font(HJTheme.body(11))
                    .foregroundColor(HJTheme.inkFaint)
            }
            if days.isEmpty {
                HJEmptyState(headline: "Nothing marked",
                             message: "No day in this month carries a fasting note.")
            } else {
                VStack(spacing: 0) {
                    ForEach(days.indices, id: \.self) { index in
                        dayRow(days[index])
                        if index < days.count - 1 { HJDivider() }
                    }
                }
            }
        }
    }

    private func dayRow(_ day: HJDayFasting) -> some View {
        let civil = HJCalendar.civil(fromJDN: day.jdn)
        let isToday = day.jdn == todayJDN
        return HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 1) {
                Text("\(day.hijri.day)")
                    .font(HJTheme.figure(16, .semibold))
                    .foregroundColor(isToday ? HJTheme.gold : HJTheme.ink)
                Text(format.weekdayShortName(day.weekday))
                    .font(HJTheme.body(9))
                    .foregroundColor(HJTheme.inkFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 40)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 7)
                .fill(isToday ? HJTheme.goldWash : Color.clear))

            VStack(alignment: .leading, spacing: 3) {
                Text(day.headline)
                    .font(HJTheme.body(13, .semibold))
                    .foregroundColor(day.kind.tint)
                    .fixedSize(horizontal: false, vertical: true)
                Text(format.civilShort(civil))
                    .font(HJTheme.body(11))
                    .foregroundColor(HJTheme.inkFaint)
                if day.notes.count > 1 {
                    Text(day.notes.dropFirst().map { $0.label }.joined(separator: "  \u{00B7}  "))
                        .font(HJTheme.body(10.5))
                        .foregroundColor(HJTheme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HJChip(text: day.kind == .notPermitted ? "Not permitted" : shortKind(day.kind),
                   tint: day.kind.tint)
        }
        .padding(.vertical, 8)
    }

    private func shortKind(_ kind: HJFastKind) -> String {
        switch kind {
        case .obligatory: return "Obligatory"
        case .voluntary: return "Voluntary"
        case .advisory: return "Note"
        case .notPermitted: return "Not permitted"
        case .none: return "\u{2014}"
        }
    }

    private var restrictedCard: some View {
        HJCard(tint: HJTheme.claySoft.opacity(0.35), border: HJTheme.clay.opacity(0.3)) {
            HJCaption(text: "Not permitted, in \(shown.year) AH", color: HJTheme.clay)
            VStack(spacing: 0) {
                ForEach(restricted.indices, id: \.self) { index in
                    let day = restricted[index]
                    HStack(alignment: .top, spacing: 10) {
                        HJGlyph(shape: HJCrossShape(), size: 10, color: HJTheme.clay, lineWidth: 1.8)
                            .padding(.top, 3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(day.headline)
                                .font(HJTheme.body(13, .semibold))
                                .foregroundColor(HJTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(format.hijriDayMonth(day.hijri) + "  \u{00B7}  "
                                 + format.civilShort(HJCalendar.civil(fromJDN: day.jdn)))
                                .font(HJTheme.body(11))
                                .foregroundColor(HJTheme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 6)
                    if index < restricted.count - 1 { HJDivider() }
                }
            }
            Text("These five days are the only ones in the year on which fasting is not permitted. The narrow exception recognised for the days of Tashriq is for a pilgrim who owes a sacrifice and cannot obtain one.")
                .font(HJTheme.body(11))
                .foregroundColor(HJTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var referenceCard: some View {
        HJCard {
            HJCaption(text: "The recurring fasts")
            VStack(alignment: .leading, spacing: 10) {
                reference("Mondays and Thursdays",
                          "Twice a week, all year, except on the days fasting is not permitted.")
                HJDivider()
                reference("The white days",
                          "The thirteenth, fourteenth and fifteenth of every Hijri month, named for the bright nights around the full moon.")
                HJDivider()
                reference("Ashura and the day before",
                          "The ninth and tenth of Muharram, kept together so that the tenth is not fasted alone.")
                HJDivider()
                reference("The Day of Arafah",
                          "The ninth of Dhu al-Hijjah, for those not on pilgrimage. Pilgrims standing at Arafah do not fast.")
                HJDivider()
                reference("The six of Shawwal",
                          "Any six days of Shawwal after Eid al-Fitr, together or spread through the month.")
                HJDivider()
                reference("The first nine of Dhu al-Hijjah",
                          "Any of the first nine days of the last month, ending before Eid al-Adha.")
            }
        }
    }

    private func reference(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                HJGlyph(shape: HJLozengeShape(), size: 8, color: HJTheme.verdant, filled: true)
                Text(title)
                    .font(HJTheme.body(13, .semibold))
                    .foregroundColor(HJTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(body)
                .font(HJTheme.body(11.5))
                .foregroundColor(HJTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 16)
        }
    }
}
