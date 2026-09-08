import SwiftUI

struct HJObservancesView: View {

    @EnvironmentObject private var store: HJStore
    @Environment(\.presentationMode) private var presentation

    /// -1 = everything, otherwise a group's raw value.
    @State private var filter: Int = -1
    @State private var expanded: String? = nil

    private var format: HJFormatter { store.formatter }
    private var todayJDN: Int { store.todayJDN }
    private var todayHijri: HJHijriDate { store.hijri(forJDN: todayJDN) }

    private var visible: [HJObservance] {
        let list = filter < 0 ? HJObservances.all : HJObservances.byGroup(HJObservanceGroup(rawValue: filter) ?? .landmark)
        return list.sorted { a, b in
            let ka = a.isDated ? a.month * 100 + a.day : 1300
            let kb = b.isDated ? b.month * 100 + b.day : 1300
            if ka != kb { return ka < kb }
            return a.name < b.name
        }
    }

    var body: some View {
        HJDetailScreen(title: "Observances",
                       subtitle: "\(HJObservances.all.count) entries. Tap one to read it.",
                       onBack: { presentation.wrappedValue.dismiss() }) {
            filterRow

            HJCard(tint: HJTheme.goldWash.opacity(0.5), border: HJTheme.gold.opacity(0.3)) {
                Text("Gregorian dates below are estimates for the Hijri year \(todayHijri.year) AH, worked out from the tabular calendar. The announced date where you live can differ by a day.")
                    .font(HJTheme.body(11.5))
                    .foregroundColor(HJTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if visible.isEmpty {
                HJCard {
                    HJEmptyState(headline: "Nothing in this group",
                                 message: "Choose another filter above.")
                }
            } else {
                ForEach(visible) { entry in
                    entryCard(entry)
                }
            }
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                filterPill(title: "All", value: -1)
                ForEach(HJObservanceGroup.allCases, id: \.rawValue) { group in
                    filterPill(title: group.title, value: group.rawValue)
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 1)
        }
    }

    private func filterPill(title: String, value: Int) -> some View {
        Button(action: { filter = value; expanded = nil }) {
            Text(title)
                .font(HJTheme.body(12, filter == value ? .semibold : .regular))
                .foregroundColor(filter == value ? HJTheme.card : HJTheme.inkSoft)
                .lineLimit(1)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Capsule().fill(filter == value ? HJTheme.ink : HJTheme.cardAlt))
                .overlay(Capsule().stroke(filter == value ? Color.clear : HJTheme.rule, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func entryCard(_ entry: HJObservance) -> some View {
        let isOpen = expanded == entry.id
        let resolved = resolvedDates(entry)
        return Button(action: {
            expanded = isOpen ? nil : entry.id
        }) {
            HJCard {
                HStack(alignment: .top, spacing: 10) {
                    HJGlyph(shape: HJStarShape(points: 8, innerRatio: 0.44), size: 12,
                            color: entry.timing.tint, filled: true)
                        .padding(.top, 3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.name)
                            .font(HJTheme.body(14.5, .semibold))
                            .foregroundColor(HJTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(entry.dateNote)
                            .font(HJTheme.body(11.5))
                            .foregroundColor(HJTheme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        if let line = resolved.thisYear {
                            Text(line)
                                .font(HJTheme.body(11.5, .medium))
                                .foregroundColor(HJTheme.indigo)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    HJGlyph(shape: HJChevronShape(direction: isOpen ? 2 : 3), size: 11,
                            color: HJTheme.inkFaint, lineWidth: 1.7)
                        .padding(.top, 4)
                }

                if isOpen {
                    HJDivider()
                    Text(entry.summary)
                        .font(HJTheme.body(12.5))
                        .foregroundColor(HJTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        HJChip(text: entry.timing.label, tint: entry.timing.tint)
                        if entry.fasting != .none {
                            HJChip(text: entry.fasting.label, tint: entry.fasting.tint)
                        }
                    }
                    Text(entry.timing.note)
                        .font(HJTheme.body(11))
                        .foregroundColor(HJTheme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)

                    if let next = resolved.countdown {
                        HJDivider()
                        HJFactRow(key: "Next occurrence", value: next)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    /// The estimate for the current Hijri year, and the countdown to the next one.
    private func resolvedDates(_ entry: HJObservance) -> (thisYear: String?, countdown: String?) {
        guard entry.isDated else { return (nil, nil) }
        let month = max(1, min(12, entry.month))
        let lengthThisYear = HJCalendar.hijriMonthLength(year: todayHijri.year, month: month)
        let startThisYear = store.jdn(forHijri: HJHijriDate(year: todayHijri.year,
                                                            month: month,
                                                            day: min(entry.day, lengthThisYear)))
        let civilStart = HJCalendar.civil(fromJDN: startThisYear)
        var line = "\(todayHijri.year) AH: " + format.civilShort(civilStart)
        if entry.span > 1 {
            let endJDN = startThisYear + entry.span - 1
            line += " \u{2013} " + format.civilShort(HJCalendar.civil(fromJDN: endJDN))
        }

        var nextJDN = startThisYear
        if nextJDN < todayJDN {
            let nextYear = min(HJCalendar.maxHijriYear, todayHijri.year + 1)
            let lengthNext = HJCalendar.hijriMonthLength(year: nextYear, month: month)
            nextJDN = store.jdn(forHijri: HJHijriDate(year: nextYear,
                                                      month: month,
                                                      day: min(entry.day, lengthNext)))
        }
        let delta = nextJDN - todayJDN
        let countdown = format.civilShort(HJCalendar.civil(fromJDN: nextJDN))
            + "  \u{00B7}  " + HJFormatter.relativeDays(delta)
        return (line, countdown)
    }
}
