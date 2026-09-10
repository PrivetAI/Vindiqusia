import SwiftUI

struct VQMonthsView: View {

    @EnvironmentObject private var store: VQStore
    @Environment(\.presentationMode) private var presentation

    @State private var month: Int = 0

    private var format: VQFormatter { store.formatter }
    private var todayHijri: VQHijriDate { store.hijri(forJDN: store.todayJDN) }
    private var selected: Int { month == 0 ? todayHijri.month : month }
    private var page: VQMonthPage { VQMonthLibrary.page(selected) }

    var body: some View {
        VQDetailScreen(title: "The twelve months",
                       subtitle: "One page per month of the Hijri year",
                       onBack: { presentation.wrappedValue.dismiss() }) {
            selectorRow
            headerCard
            meaningCard
            occasionsCard
            VQEstimateNote()
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
                                    .font(VQTheme.figure(12, .semibold))
                                    .foregroundColor(selected == number ? VQTheme.card : VQTheme.inkFaint)
                                Text(VQNames.hijriMonthShort(number))
                                    .font(VQTheme.body(11, selected == number ? .semibold : .regular))
                                    .foregroundColor(selected == number ? VQTheme.card : VQTheme.ink)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 7)
                            .padding(.horizontal, 11)
                            .background(RoundedRectangle(cornerRadius: 9)
                                .fill(selected == number ? VQTheme.ink : VQTheme.cardAlt))
                            .overlay(RoundedRectangle(cornerRadius: 9)
                                .stroke(selected == number ? Color.clear : VQTheme.rule, lineWidth: 1))
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
                Text("\(VQFormatter.ordinal(selected)) month of twelve")
                    .font(VQTheme.body(11.5))
                    .foregroundColor(VQTheme.inkFaint)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                stepButton(direction: 0) { month = selected == 12 ? 1 : selected + 1 }
            }
        }
    }

    private func stepButton(direction: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VQGlyph(shape: VQChevronShape(direction: direction), size: 12,
                    color: VQTheme.ink, lineWidth: 1.9)
                .frame(width: 36, height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(VQTheme.cardAlt))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var headerCard: some View {
        VQCard {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(format.hijriMonthName(selected))
                        .font(VQTheme.display(24))
                        .foregroundColor(VQTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(page.epithet)
                        .font(VQTheme.body(12.5))
                        .foregroundColor(VQTheme.gold)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 6)
                VQGlyph(shape: VQCrescentShape(thinness: 0.42), size: 34,
                        color: page.isSacred ? VQTheme.gold : VQTheme.indigo.opacity(0.7),
                        filled: true)
            }
            HStack(spacing: 6) {
                VQChip(text: page.isSacred ? "Sacred month" : "Ordinary month",
                       tint: page.isSacred ? VQTheme.gold : VQTheme.inkSoft)
                VQChip(text: selected == 12 ? "29 or 30 days" : "\(page.ordinaryLength) days",
                       tint: VQTheme.indigo)
            }
            Text(page.sacredLine)
                .font(VQTheme.body(11.5))
                .foregroundColor(VQTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
            VQDivider()
            VQFactRow(key: "Also written", value: VQNames.hijriMonth(selected, marked: !store.markedSpelling))
            VQDivider()
            VQFactRow(key: "This year's estimate", value: thisYearSpan)
        }
    }

    private var thisYearSpan: String {
        let year = todayHijri.year
        let length = VQCalendar.hijriMonthLength(year: year, month: selected)
        let first = store.jdn(forHijri: VQHijriDate(year: year, month: selected, day: 1))
        let last = first + length - 1
        let a = VQCalendar.civil(fromJDN: first)
        let b = VQCalendar.civil(fromJDN: last)
        return format.civilShort(a) + " \u{2013} " + format.civilShort(b)
    }

    private var meaningCard: some View {
        VQCard {
            VQCaption(text: "What the name means")
            Text(page.meaning)
                .font(VQTheme.body(13))
                .foregroundColor(VQTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            VQDivider()
            VQCaption(text: "Where it sits in the year")
            Text(page.position)
                .font(VQTheme.body(13))
                .foregroundColor(VQTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            VQDivider()
            VQCaption(text: "What it carries")
            Text(page.associations)
                .font(VQTheme.body(13))
                .foregroundColor(VQTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var monthObservances: [VQObservance] {
        VQObservances.all
            .filter { $0.month == selected }
            .sorted { ($0.day, $0.name) < ($1.day, $1.name) }
    }

    private var occasionsCard: some View {
        VQCard {
            VQCaption(text: "In this month")
            if monthObservances.isEmpty {
                Text("No dated observance falls in this month. The regular voluntary fasts still apply: Mondays and Thursdays, and the white days on the thirteenth to fifteenth.")
                    .font(VQTheme.body(12.5))
                    .foregroundColor(VQTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 0) {
                    ForEach(monthObservances.indices, id: \.self) { index in
                        let entry = monthObservances[index]
                        HStack(alignment: .top, spacing: 9) {
                            VQGlyph(shape: VQStarShape(points: 8, innerRatio: 0.44), size: 10,
                                    color: entry.timing.tint, filled: true)
                                .padding(.top, 3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.name)
                                    .font(VQTheme.body(13, .semibold))
                                    .foregroundColor(VQTheme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(entry.dateNote)
                                    .font(VQTheme.body(11))
                                    .foregroundColor(VQTheme.inkFaint)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 7)
                        if index < monthObservances.count - 1 { VQDivider() }
                    }
                }
            }
        }
    }
}
