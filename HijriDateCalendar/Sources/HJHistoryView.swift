import SwiftUI

struct HJHistoryView: View {

    @EnvironmentObject private var store: HJStore
    @Environment(\.presentationMode) private var presentation

    /// -1 = everything, 0 = before the Hijra, otherwise a Hijri century.
    @State private var century: Int = -1
    @State private var expanded: String? = nil

    private var visible: [HJHistoryEvent] {
        let list = century < 0
            ? HJHistoryLibrary.sortedEvents
            : HJHistoryLibrary.events(inCentury: century).sorted { $0.ahYear < $1.ahYear }
        return list
    }

    var body: some View {
        HJDetailScreen(title: "Islamic history",
                       subtitle: "\(HJHistoryLibrary.events.count) events, dated in both reckonings",
                       onBack: { presentation.wrappedValue.dismiss() }) {
            filterRow

            HJCard(tint: HJTheme.cardAlt) {
                Text("Dated in AH and CE side by side. Where the sources disagree, or where a date is a span rather than a year, the entry is marked as approximate rather than given a false precision.")
                    .font(HJTheme.body(11.5))
                    .foregroundColor(HJTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if visible.isEmpty {
                HJCard {
                    HJEmptyState(headline: "Nothing in this century",
                                 message: "Choose another century above.")
                }
            } else {
                timeline
            }
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                pill(title: "All", value: -1)
                ForEach(HJHistoryLibrary.centuries, id: \.self) { value in
                    pill(title: HJHistoryLibrary.centuryLabel(value), value: value)
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 1)
        }
    }

    private func pill(title: String, value: Int) -> some View {
        Button(action: { century = value; expanded = nil }) {
            Text(title)
                .font(HJTheme.body(12, century == value ? .semibold : .regular))
                .foregroundColor(century == value ? HJTheme.card : HJTheme.inkSoft)
                .lineLimit(1)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Capsule().fill(century == value ? HJTheme.ink : HJTheme.cardAlt))
                .overlay(Capsule().stroke(century == value ? Color.clear : HJTheme.rule, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var timeline: some View {
        VStack(spacing: 8) {
            ForEach(visible) { event in
                eventCard(event)
            }
        }
    }

    private func eventCard(_ event: HJHistoryEvent) -> some View {
        let isOpen = expanded == event.id
        return Button(action: { expanded = isOpen ? nil : event.id }) {
            HJCard {
                HStack(alignment: .top, spacing: 11) {
                    // The rail: a marker and a stub of the line running through the list.
                    VStack(spacing: 0) {
                        Circle()
                            .fill(event.approximate ? HJTheme.cardAlt : HJTheme.gold)
                            .frame(width: 9, height: 9)
                            .overlay(Circle().stroke(HJTheme.gold, lineWidth: 1.2))
                        Rectangle()
                            .fill(HJTheme.ruleSoft)
                            .frame(width: 1)
                            .frame(maxHeight: .infinity)
                    }
                    .frame(width: 10)
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(event.ahLabel)
                                .font(HJTheme.figure(12.5, .semibold))
                                .foregroundColor(HJTheme.gold)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(event.ceLabel)
                                .font(HJTheme.body(11.5))
                                .foregroundColor(HJTheme.indigo)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Spacer(minLength: 0)
                        }
                        Text(event.title)
                            .font(HJTheme.body(14, .semibold))
                            .foregroundColor(HJTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if event.approximate && !isOpen {
                            Text("Approximate")
                                .font(HJTheme.body(10.5))
                                .foregroundColor(HJTheme.inkFaint)
                        }
                        if isOpen {
                            Text(event.detail)
                                .font(HJTheme.body(12.5))
                                .foregroundColor(HJTheme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 2)
                            if event.approximate {
                                HJChip(text: "Date approximate", tint: HJTheme.clay)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HJGlyph(shape: HJChevronShape(direction: isOpen ? 2 : 3), size: 11,
                            color: HJTheme.inkFaint, lineWidth: 1.7)
                        .padding(.top, 4)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
