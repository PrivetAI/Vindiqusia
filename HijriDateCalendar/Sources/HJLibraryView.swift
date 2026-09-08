import SwiftUI

/// The reference hub. One push deep, never two — every destination has its own Back
/// control, since no navigation bar is shown anywhere in the app.
struct HJLibraryView: View {

    @EnvironmentObject private var store: HJStore

    private var todayHijri: HJHijriDate { store.hijri(forJDN: store.todayJDN) }

    var body: some View {
        HJScreen(title: "Library", subtitle: "Observances, the months, the history and the fasting calendar") {
            NavigationLink(destination: HJObservancesView().environmentObject(store)) {
                HJNavRow(icon: HJGlyph(shape: HJStarShape(points: 8, innerRatio: 0.44), size: 17,
                                       color: HJTheme.gold, filled: true),
                         title: "Observances",
                         detail: "\(HJObservances.all.count) entries across the Hijri year",
                         accent: HJTheme.gold)
            }
            .buttonStyle(PlainButtonStyle())

            NavigationLink(destination: HJMonthsView().environmentObject(store)) {
                HJNavRow(icon: HJGlyph(shape: HJCrescentShape(thinness: 0.45), size: 17,
                                       color: HJTheme.indigo, filled: true),
                         title: "The twelve months",
                         detail: "What each name means and where it sits in the year",
                         accent: HJTheme.indigo)
            }
            .buttonStyle(PlainButtonStyle())

            NavigationLink(destination: HJHistoryView().environmentObject(store)) {
                HJNavRow(icon: HJGlyph(shape: HJBookGlyphShape(), size: 18,
                                       color: HJTheme.ink, lineWidth: 1.4),
                         title: "Islamic history",
                         detail: "\(HJHistoryLibrary.events.count) dated events, in AH and CE",
                         accent: HJTheme.ink)
            }
            .buttonStyle(PlainButtonStyle())

            NavigationLink(destination: HJFastingView().environmentObject(store)) {
                HJNavRow(icon: HJGlyph(shape: HJLozengeShape(), size: 15,
                                       color: HJTheme.verdant, filled: true),
                         title: "Fasting days",
                         detail: "This month's fasting days, and the days fasting is not permitted",
                         accent: HJTheme.verdant)
            }
            .buttonStyle(PlainButtonStyle())

            NavigationLink(destination: HJPersonalDatesView().environmentObject(store)) {
                HJNavRow(icon: HJGlyph(shape: HJCalendarPageShape(rows: 2, columns: 3), size: 18,
                                       color: HJTheme.clay, lineWidth: 1.3),
                         title: "My dates",
                         detail: store.personalDates.isEmpty
                            ? "Save a date anchored to the Hijri calendar"
                            : "\(store.personalDates.count) saved",
                         accent: HJTheme.clay)
            }
            .buttonStyle(PlainButtonStyle())

            HJCard(tint: HJTheme.cardAlt) {
                HJCaption(text: "Where these dates come from")
                Text("Every Hijri date in this app is produced by the tabular calendar: a thirty-year cycle in which eleven years carry a 355th day, with months of thirty and twenty-nine days in alternation. It is arithmetic, and it agrees with an announced sighting most of the time but not always.")
                    .font(HJTheme.body(12))
                    .foregroundColor(HJTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Today is \(store.formatter.hijriLong(todayHijri)) by that reckoning\(store.adjustment == 0 ? "" : ", with your shift of \(store.adjustmentLabel) applied").")
                    .font(HJTheme.body(12))
                    .foregroundColor(HJTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HJEstimateNote()
                .padding(.horizontal, 2)
        }
    }
}
