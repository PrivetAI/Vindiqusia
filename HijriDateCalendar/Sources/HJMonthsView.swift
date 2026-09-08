import SwiftUI

struct HJMonthsView: View {

    @EnvironmentObject private var store: HJStore
    @Environment(\.presentationMode) private var presentation

    @State private var month: Int = 0

    private var format: HJFormatter { store.formatter }
    private var todayHijri: HJHijriDate { store.hijri(forJDN: store.todayJDN) }
    private var selected: Int { month == 0 ? todayHijri.month : month }
    private var page: HJMonthPage { HJMonthLibrary.page(selected) }

    var body: some View {
        HJDetailScreen(title: "The twelve months",
                       subtitle: "One page per month of the Hijri year",
                       onBack: { presentation.wrappedValue.dismiss() }) {
            selectorRow
            headerCard
            meaningCard
            occasionsCard
            HJEstimateNote()
                .padding(.horizontal, 2)
        }
    }

    private var selectorRow: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(1...12, id: \.self) { number in
                        Button(action: { month = number }) {
                            VStack(spacing: 1) {
                                Text("\(number)")
                                    .font(HJTheme.figure(12, .semibold))
                                    .foregroundColor(selected == number ? HJTheme.card : HJTheme.inkFaint)
                                Text(HJNames.hijriMonthShort(number))
                                    .font(HJTheme.body(11, selected == number ? .semibold : .regular))
                                    .foregroundColor(selected == number ? HJTheme.card : HJTheme.ink)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 7)
                            .padding(.horizontal, 11)
                            .background(RoundedRectangle(cornerRadius: 9)
                                .fill(selected == number ? HJTheme.ink : HJTheme.cardAlt))
                            .overlay(RoundedRectangle(cornerRadius: 9)
                                .stroke(selected == number ? Color.clear : HJTheme.rule, lineWidth: 1))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 1)
            }

            HStack(spacing: 8) {
                stepButton(direction: 1) { month = selected == 1 ? 12 : selected - 1 }
                Text("\(HJFormatter.ordinal(selected)) month of twelve")
                    .font(HJTheme.body(11.5))
                    .foregroundColor(HJTheme.inkFaint)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                stepButton(direction: 0) { month = selected == 12 ? 1 : selected + 1 }
            }
        }
    }

    private func stepButton(direction: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HJGlyph(shape: HJChevronShape(direction: direction), size: 12,
                    color: HJTheme.ink, lineWidth: 1.9)
                .frame(width: 36, height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(HJTheme.cardAlt))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var headerCard: some View {
        HJCard {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(format.hijriMonthName(selected))
                        .font(HJTheme.display(24))
                        .foregroundColor(HJTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(page.epithet)
                        .font(HJTheme.body(12.5))
                        .foregroundColor(HJTheme.gold)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 6)
                HJGlyph(shape: HJCrescentShape(thinness: 0.42), size: 34,
                        color: page.isSacred ? HJTheme.gold : HJTheme.indigo.opacity(0.7),
                        filled: true)
            }
            HStack(spacing: 6) {
                HJChip(text: page.isSacred ? "Sacred month" : "Ordinary month",
                       tint: page.isSacred ? HJTheme.gold : HJTheme.inkSoft)
                HJChip(text: selected == 12 ? "29 or 30 days" : "\(page.ordinaryLength) days",
                       tint: HJTheme.indigo)
            }
            Text(page.sacredLine)
                .font(HJTheme.body(11.5))
                .foregroundColor(HJTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
            HJDivider()
            HJFactRow(key: "Also written", value: HJNames.hijriMonth(selected, marked: !store.markedSpelling))
            HJDivider()
            HJFactRow(key: "This year's estimate", value: thisYearSpan)
        }
    }

    private var thisYearSpan: String {
        let year = todayHijri.year
        let length = HJCalendar.hijriMonthLength(year: year, month: selected)
        let first = store.jdn(forHijri: HJHijriDate(year: year, month: selected, day: 1))
        let last = first + length - 1
        let a = HJCalendar.civil(fromJDN: first)
        let b = HJCalendar.civil(fromJDN: last)
        return format.civilShort(a) + " \u{2013} " + format.civilShort(b)
    }

    private var meaningCard: some View {
        HJCard {
            HJCaption(text: "What the name means")
            Text(page.meaning)
                .font(HJTheme.body(13))
                .foregroundColor(HJTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            HJDivider()
            HJCaption(text: "Where it sits in the year")
            Text(page.position)
                .font(HJTheme.body(13))
                .foregroundColor(HJTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            HJDivider()
            HJCaption(text: "What it carries")
            Text(page.associations)
                .font(HJTheme.body(13))
                .foregroundColor(HJTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var monthObservances: [HJObservance] {
        HJObservances.all
            .filter { $0.month == selected }
            .sorted { ($0.day, $0.name) < ($1.day, $1.name) }
    }

    private var occasionsCard: some View {
        HJCard {
            HJCaption(text: "In this month")
            if monthObservances.isEmpty {
                Text("No dated observance falls in this month. The regular voluntary fasts still apply: Mondays and Thursdays, and the white days on the thirteenth to fifteenth.")
                    .font(HJTheme.body(12.5))
                    .foregroundColor(HJTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 0) {
                    ForEach(monthObservances.indices, id: \.self) { index in
                        let entry = monthObservances[index]
                        HStack(alignment: .top, spacing: 9) {
                            HJGlyph(shape: HJStarShape(points: 8, innerRatio: 0.44), size: 10,
                                    color: entry.timing.tint, filled: true)
                                .padding(.top, 3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.name)
                                    .font(HJTheme.body(13, .semibold))
                                    .foregroundColor(HJTheme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(entry.dateNote)
                                    .font(HJTheme.body(11))
                                    .foregroundColor(HJTheme.inkFaint)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 7)
                        if index < monthObservances.count - 1 { HJDivider() }
                    }
                }
            }
        }
    }
}
