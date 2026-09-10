import SwiftUI

struct VQHistoryView: View {

    @EnvironmentObject private var store: VQStore
    @Environment(\.presentationMode) private var presentation

    /// -1 = everything, 0 = before the Hijra, otherwise a Hijri century.
    @State private var century: Int = -1
    @State private var expanded: String? = nil

    private var visible: [VQHistoryEvent] {
        let list = century < 0
            ? VQHistoryLibrary.sortedEvents
            : VQHistoryLibrary.events(inCentury: century).sorted { $0.ahYear < $1.ahYear }
        return list
    }

    var body: some View {
        VQDetailScreen(title: "Islamic history",
                       subtitle: "\(VQHistoryLibrary.events.count) events, dated in both reckonings",
                       onBack: { presentation.wrappedValue.dismiss() }) {
            filterRow

            VQCard(tint: VQTheme.cardAlt) {
                Text("Dated in AH and CE side by side. Where the sources disagree, or where a date is a span rather than a year, the entry is marked as approximate rather than given a false precision.")
                    .font(VQTheme.body(11.5))
                    .foregroundColor(VQTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if visible.isEmpty {
                VQCard {
                    VQEmptyState(headline: "Nothing in this century",
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
                ForEach(VQHistoryLibrary.centuries, id: \.self) { value in
                    pill(title: VQHistoryLibrary.centuryLabel(value), value: value)
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 1)
        }
    }

    private func pill(title: String, value: Int) -> some View {
        Button(action: { century = value; expanded = nil }) {
            Text(title)
                .font(VQTheme.body(12, century == value ? .semibold : .regular))
                .foregroundColor(century == value ? VQTheme.card : VQTheme.inkSoft)
                .lineLimit(1)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Capsule().fill(century == value ? VQTheme.ink : VQTheme.cardAlt))
                .overlay(Capsule().stroke(century == value ? Color.clear : VQTheme.rule, lineWidth: 1))
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

    private func eventCard(_ event: VQHistoryEvent) -> some View {
        let isOpen = expanded == event.id
        return Button(action: { expanded = isOpen ? nil : event.id }) {
            VQCard {
                HStack(alignment: .top, spacing: 11) {
                    // The rail: a marker and a stub of the line running through the list.
                    VStack(spacing: 0) {
                        Circle()
                            .fill(event.approximate ? VQTheme.cardAlt : VQTheme.gold)
                            .frame(width: 9, height: 9)
                            .overlay(Circle().stroke(VQTheme.gold, lineWidth: 1.2))
                        Rectangle()
                            .fill(VQTheme.ruleSoft)
                            .frame(width: 1)
                            .frame(maxHeight: .infinity)
                    }
                    .frame(width: 10)
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(event.ahLabel)
                                .font(VQTheme.figure(12.5, .semibold))
                                .foregroundColor(VQTheme.gold)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(event.ceLabel)
                                .font(VQTheme.body(11.5))
                                .foregroundColor(VQTheme.indigo)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Spacer(minLength: 0)
                        }
                        Text(event.title)
                            .font(VQTheme.body(14, .semibold))
                            .foregroundColor(VQTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if event.approximate && !isOpen {
                            Text("Approximate")
                                .font(VQTheme.body(10.5))
                                .foregroundColor(VQTheme.inkFaint)
                        }
                        if isOpen {
                            Text(event.detail)
                                .font(VQTheme.body(12.5))
                                .foregroundColor(VQTheme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 2)
                            if event.approximate {
                                VQChip(text: "Date approximate", tint: VQTheme.clay)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VQGlyph(shape: VQChevronShape(direction: isOpen ? 2 : 3), size: 11,
                            color: VQTheme.inkFaint, lineWidth: 1.7)
                        .padding(.top, 4)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
