import SwiftUI

/// The reference hub. One push deep, never two — every destination has its own Back
/// control, since no navigation bar is shown anywhere in the app.
struct VQLibraryView: View {

    @EnvironmentObject private var store: VQStore

    private var todayHijri: VQHijriDate { store.hijri(forJDN: store.todayJDN) }

    var body: some View {
        VQScreen(title: "Library", subtitle: "Observances, the months, the history and the fasting calendar") {
            NavigationLink(destination: VQObservancesView().environmentObject(store)) {
                VQNavRow(icon: VQGlyph(shape: VQStarShape(points: 8, innerRatio: 0.44), size: 17,
                                       color: VQTheme.gold, filled: true),
                         title: "Observances",
                         detail: "\(VQObservances.all.count) entries across the Hijri year",
                         accent: VQTheme.gold)
            }
            .buttonStyle(PlainButtonStyle())

            NavigationLink(destination: VQMonthsView().environmentObject(store)) {
                VQNavRow(icon: VQGlyph(shape: VQCrescentShape(thinness: 0.45), size: 17,
                                       color: VQTheme.indigo, filled: true),
                         title: "The twelve months",
                         detail: "What each name means and where it sits in the year",
                         accent: VQTheme.indigo)
            }
            .buttonStyle(PlainButtonStyle())

            NavigationLink(destination: VQHistoryView().environmentObject(store)) {
                VQNavRow(icon: VQGlyph(shape: VQBookGlyphShape(), size: 18,
                                       color: VQTheme.ink, lineWidth: 1.4),
                         title: "Islamic history",
                         detail: "\(VQHistoryLibrary.events.count) dated events, in AH and CE",
                         accent: VQTheme.ink)
            }
            .buttonStyle(PlainButtonStyle())

            NavigationLink(destination: VQFastingView().environmentObject(store)) {
                VQNavRow(icon: VQGlyph(shape: VQLozengeShape(), size: 15,
                                       color: VQTheme.verdant, filled: true),
                         title: "Fasting days",
                         detail: "This month's fasting days, and the days fasting is not permitted",
                         accent: VQTheme.verdant)
            }
            .buttonStyle(PlainButtonStyle())

            NavigationLink(destination: VQPersonalDatesView().environmentObject(store)) {
                VQNavRow(icon: VQGlyph(shape: VQCalendarPageShape(rows: 2, columns: 3), size: 18,
                                       color: VQTheme.clay, lineWidth: 1.3),
                         title: "My dates",
                         detail: store.personalDates.isEmpty
                            ? "Save a date anchored to the Hijri calendar"
                            : "\(store.personalDates.count) saved",
                         accent: VQTheme.clay)
            }
            .buttonStyle(PlainButtonStyle())

            VQCard(tint: VQTheme.cardAlt) {
                VQCaption(text: "Where these dates come from")
                Text("Every Hijri date in this app is produced by the tabular calendar: a thirty-year cycle in which eleven years carry a 355th day, with months of thirty and twenty-nine days in alternation. It is arithmetic, and it agrees with an announced sighting most of the time but not always.")
                    .font(VQTheme.body(12))
                    .foregroundColor(VQTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Today is \(store.formatter.hijriLong(todayHijri)) by that reckoning\(store.adjustment == 0 ? "" : ", with your shift of \(store.adjustmentLabel) applied").")
                    .font(VQTheme.body(12))
                    .foregroundColor(VQTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VQEstimateNote()
                .padding(.horizontal, 2)
        }
    }
}
