import SwiftUI

struct VQFastingView: View {

    @EnvironmentObject private var store: VQStore
    @Environment(\.presentationMode) private var presentation

    /// Offset in Hijri months from the current one.
    @State private var monthOffset: Int = 0

    private var format: VQFormatter { store.formatter }
    private var todayJDN: Int { store.todayJDN }
    private var todayHijri: VQHijriDate { store.hijri(forJDN: todayJDN) }

    private var shown: (year: Int, month: Int) {
        var year = todayHijri.year
        var month = todayHijri.month + monthOffset
        while month > 12 { month -= 12; year += 1 }
        while month < 1 { month += 12; year -= 1 }
        year = max(VQCalendar.minHijriYear, min(VQCalendar.maxHijriYear, year))
        return (year, month)
    }

    private var days: [VQDayFasting] {
        VQFasting.month(year: shown.year, month: shown.month, store: store)
    }

    private var restricted: [VQDayFasting] {
        VQFasting.restrictedDays(year: shown.year, store: store)
    }

    var body: some View {
        VQDetailScreen(title: "Fasting days",
                       subtitle: "What the calendar marks, month by month",
                       onBack: { presentation.wrappedValue.dismiss() }) {
            navigator
            monthCard
            restrictedCard
            referenceCard
            VQEstimateNote()
                .padding(.horizontal, 2)
        }
    }

    private var navigator: some View {
        VQCard(padding: 10) {
            HStack(spacing: 6) {
                stepButton(direction: 1) { if monthOffset > -240 { monthOffset -= 1 } }
                VStack(spacing: 1) {
                    Text(verbatim: "\(format.hijriMonthName(shown.month)) \(shown.year) AH")
                        .font(VQTheme.display(16))
                        .foregroundColor(VQTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text(gregorianSpan)
                        .font(VQTheme.body(10.5))
                        .foregroundColor(VQTheme.inkFaint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                stepButton(direction: 0) { if monthOffset < 240 { monthOffset += 1 } }
            }
            if monthOffset != 0 {
                Button(action: { monthOffset = 0 }) {
                    Text("Back to this month")
                        .font(VQTheme.body(12, .medium))
                        .foregroundColor(VQTheme.gold)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 11)
                        .background(RoundedRectangle(cornerRadius: 8).fill(VQTheme.goldWash))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var gregorianSpan: String {
        let length = VQCalendar.hijriMonthLength(year: shown.year, month: shown.month)
        let first = store.jdn(forHijri: VQHijriDate(year: shown.year, month: shown.month, day: 1))
        let last = first + length - 1
        return format.civilShort(VQCalendar.civil(fromJDN: first))
            + " \u{2013} " + format.civilShort(VQCalendar.civil(fromJDN: last))
    }

    private func stepButton(direction: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VQGlyph(shape: VQChevronShape(direction: direction), size: 13,
                    color: VQTheme.ink, lineWidth: 2)
                .frame(width: 38, height: 36)
                .background(RoundedRectangle(cornerRadius: 9).fill(VQTheme.cardAlt))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var monthCard: some View {
        VQCard {
            HStack {
                VQCaption(text: "This month")
                Spacer(minLength: 6)
                Text("\(days.count) marked day\(days.count == 1 ? "" : "s")")
                    .font(VQTheme.body(11))
                    .foregroundColor(VQTheme.inkFaint)
            }
            if days.isEmpty {
                VQEmptyState(headline: "Nothing marked",
                             message: "No day in this month carries a fasting note.")
            } else {
                VStack(spacing: 0) {
                    ForEach(days.indices, id: \.self) { index in
                        dayRow(days[index])
                        if index < days.count - 1 { VQDivider() }
                    }
                }
            }
        }
    }

    private func dayRow(_ day: VQDayFasting) -> some View {
        let civil = VQCalendar.civil(fromJDN: day.jdn)
        let isToday = day.jdn == todayJDN
        return HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 1) {
                Text("\(day.hijri.day)")
                    .font(VQTheme.figure(16, .semibold))
                    .foregroundColor(isToday ? VQTheme.gold : VQTheme.ink)
                Text(format.weekdayShortName(day.weekday))
                    .font(VQTheme.body(9))
                    .foregroundColor(VQTheme.inkFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 40)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 7)
                .fill(isToday ? VQTheme.goldWash : Color.clear))

            VStack(alignment: .leading, spacing: 3) {
                Text(day.headline)
                    .font(VQTheme.body(13, .semibold))
                    .foregroundColor(day.kind.tint)
                    .fixedSize(horizontal: false, vertical: true)
                Text(format.civilShort(civil))
                    .font(VQTheme.body(11))
                    .foregroundColor(VQTheme.inkFaint)
                if day.notes.count > 1 {
                    Text(day.notes.dropFirst().map { $0.label }.joined(separator: "  \u{00B7}  "))
                        .font(VQTheme.body(10.5))
                        .foregroundColor(VQTheme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VQChip(text: day.kind == .notPermitted ? "Not permitted" : shortKind(day.kind),
                   tint: day.kind.tint)
        }
        .padding(.vertical, 8)
    }

    private func shortKind(_ kind: VQFastKind) -> String {
        switch kind {
        case .obligatory: return "Obligatory"
        case .voluntary: return "Voluntary"
        case .advisory: return "Note"
        case .notPermitted: return "Not permitted"
        case .none: return "\u{2014}"
        }
    }

    private var restrictedCard: some View {
        VQCard(tint: VQTheme.claySoft.opacity(0.35), border: VQTheme.clay.opacity(0.3)) {
            VQCaption(text: "Not permitted, in \(shown.year) AH", color: VQTheme.clay)
            VStack(spacing: 0) {
                ForEach(restricted.indices, id: \.self) { index in
                    let day = restricted[index]
                    HStack(alignment: .top, spacing: 10) {
                        VQGlyph(shape: VQCrossShape(), size: 10, color: VQTheme.clay, lineWidth: 1.8)
                            .padding(.top, 3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(day.headline)
                                .font(VQTheme.body(13, .semibold))
                                .foregroundColor(VQTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(format.hijriDayMonth(day.hijri) + "  \u{00B7}  "
                                 + format.civilShort(VQCalendar.civil(fromJDN: day.jdn)))
                                .font(VQTheme.body(11))
                                .foregroundColor(VQTheme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 6)
                    if index < restricted.count - 1 { VQDivider() }
                }
            }
            Text("These five days are the only ones in the year on which fasting is not permitted. The narrow exception recognised for the days of Tashriq is for a pilgrim who owes a sacrifice and cannot obtain one.")
                .font(VQTheme.body(11))
                .foregroundColor(VQTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var referenceCard: some View {
        VQCard {
            VQCaption(text: "The recurring fasts")
            VStack(alignment: .leading, spacing: 10) {
                reference("Mondays and Thursdays",
                          "Twice a week, all year, except on the days fasting is not permitted.")
                VQDivider()
                reference("The white days",
                          "The thirteenth, fourteenth and fifteenth of every Hijri month, named for the bright nights around the full moon.")
                VQDivider()
                reference("Ashura and the day before",
                          "The ninth and tenth of Muharram, kept together so that the tenth is not fasted alone.")
                VQDivider()
                reference("The Day of Arafah",
                          "The ninth of Dhu al-Hijjah, for those not on pilgrimage. Pilgrims standing at Arafah do not fast.")
                VQDivider()
                reference("The six of Shawwal",
                          "Any six days of Shawwal after Eid al-Fitr, together or spread through the month.")
                VQDivider()
                reference("The first nine of Dhu al-Hijjah",
                          "Any of the first nine days of the last month, ending before Eid al-Adha.")
            }
        }
    }

    private func reference(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                VQGlyph(shape: VQLozengeShape(), size: 8, color: VQTheme.verdant, filled: true)
                Text(title)
                    .font(VQTheme.body(13, .semibold))
                    .foregroundColor(VQTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(body)
                .font(VQTheme.body(11.5))
                .foregroundColor(VQTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 16)
        }
    }
}
