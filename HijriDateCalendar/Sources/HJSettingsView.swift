import SwiftUI

struct HJSettingsView: View {

    @EnvironmentObject private var store: HJStore

    @State private var showPrivacy = false
    @State private var confirmingReset = false

    private var format: HJFormatter { store.formatter }
    private var todayJDN: Int { store.todayJDN }

    var body: some View {
        HJScreen(title: "Settings", subtitle: "How the calendar is calculated and how it reads") {
            adjustmentCard
            displayCard
            calculationCard
            privacyCard
            resetCard
            aboutCard
        }
        // One sheet only: iOS 15 honours the last `.sheet` on a view and silently drops
        // any earlier one. The reset confirmation is inline for the same reason.
        .sheet(isPresented: $showPrivacy) {
            HJWebSheet(address: "https://example.com",
                       title: "Privacy Policy",
                       onClose: { showPrivacy = false })
        }
    }

    // MARK: Adjustment

    private var adjustmentCard: some View {
        HJCard {
            HJCaption(text: "Hijri date shift", color: HJTheme.gold)
            Text("The month begins on a local sighting, which no calculation can predict. If the announced date where you are runs ahead of or behind this calendar, shift it here and every screen follows.")
                .font(HJTheme.body(12))
                .foregroundColor(HJTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 5) {
                ForEach([-2, -1, 0, 1, 2], id: \.self) { value in
                    Button(action: { if store.adjustment != value { store.adjustment = value } }) {
                        VStack(spacing: 2) {
                            Text(value == 0 ? "0" : (value > 0 ? "+\(value)" : "\(value)"))
                                .font(HJTheme.figure(16, .semibold))
                                .foregroundColor(store.adjustment == value ? HJTheme.card : HJTheme.ink)
                            Text(previewDay(for: value))
                                .font(HJTheme.body(9))
                                .foregroundColor(store.adjustment == value
                                                 ? HJTheme.card.opacity(0.85) : HJTheme.inkFaint)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 9)
                            .fill(store.adjustment == value ? HJTheme.gold : HJTheme.cardAlt))
                        .overlay(RoundedRectangle(cornerRadius: 9)
                            .stroke(store.adjustment == value ? Color.clear : HJTheme.rule, lineWidth: 1))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            HJDivider()
            HJFactRow(key: "Today becomes", value: format.hijriLong(store.hijri(forJDN: todayJDN)),
                      valueColor: HJTheme.gold)
            Text("A shift of \(store.adjustmentLabel.lowercased()) is applied to every date in the app, in both directions of conversion.")
                .font(HJTheme.body(11))
                .foregroundColor(HJTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func previewDay(for shift: Int) -> String {
        let hijri = HJCalendar.hijri(fromJDN: todayJDN + shift)
        return "\(hijri.day) \(HJNames.hijriMonthShort(hijri.month))"
    }

    // MARK: Display

    private var displayCard: some View {
        HJCard {
            HJCaption(text: "Display")

            VStack(alignment: .leading, spacing: 5) {
                Text("Month-name spelling")
                    .font(HJTheme.body(13, .medium))
                    .foregroundColor(HJTheme.ink)
                HJChoiceRow(options: ["Plain \u{2014} Ramadan", "Marked \u{2014} Rama\u{1E0D}\u{101}n"],
                            selection: store.markedSpelling ? 1 : 0) { index in
                    store.markedSpelling = index == 1
                }
                Text("Both are transliterations of the same Arabic name. The marked form uses the macrons and dots used in scholarly writing.")
                    .font(HJTheme.body(10.5))
                    .foregroundColor(HJTheme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HJDivider()

            VStack(alignment: .leading, spacing: 5) {
                Text("Weekday names")
                    .font(HJTheme.body(13, .medium))
                    .foregroundColor(HJTheme.ink)
                HJChoiceRow(options: ["English \u{2014} Friday", "Transliterated \u{2014} al-Jumu\u{2BF}ah"],
                            selection: store.arabicWeekdays ? 1 : 0) { index in
                    store.arabicWeekdays = index == 1
                }
                Text("Both namings are shown together in the day sheet whichever you pick.")
                    .font(HJTheme.body(10.5))
                    .foregroundColor(HJTheme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HJDivider()

            VStack(alignment: .leading, spacing: 5) {
                Text("Week starts on")
                    .font(HJTheme.body(13, .medium))
                    .foregroundColor(HJTheme.ink)
                HJChoiceRow(options: ["Sunday", "Monday", "Saturday"],
                            selection: store.weekStart) { store.weekStart = $0 }
                Text("Sets the first column of the month grid.")
                    .font(HJTheme.body(10.5))
                    .foregroundColor(HJTheme.inkFaint)
            }

            HJDivider()

            VStack(alignment: .leading, spacing: 5) {
                Text("Leading calendar")
                    .font(HJTheme.body(13, .medium))
                    .foregroundColor(HJTheme.ink)
                HJChoiceRow(options: ["Hijri", "Gregorian"],
                            selection: store.primaryCalendar) { store.primaryCalendar = $0 }
                Text("Decides which date is shown large on the Today screen, and which calendar the month grid opens on.")
                    .font(HJTheme.body(10.5))
                    .foregroundColor(HJTheme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HJDivider()

            HJSwitchRow(label: "24-hour clock",
                        detail: "Now reads \(HJClock.text(twentyFourHour: store.twentyFourHour))",
                        isOn: store.twentyFourHour) {
                store.twentyFourHour.toggle()
            }
        }
    }

    // MARK: Calculation

    private var calculationCard: some View {
        HJCard(tint: HJTheme.cardAlt) {
            HJCaption(text: "How the dates are worked out")
            Text("This app uses the arithmetic, or tabular, Islamic calendar. Months run thirty and twenty-nine days in alternation, so an ordinary year is 354 days. Eleven years in every thirty carry a 355th day, added to Dhu al-Hijjah: years 2, 5, 7, 10, 13, 16, 18, 21, 24, 26 and 29 of the cycle.")
                .font(HJTheme.body(12))
                .foregroundColor(HJTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Text("The count starts from 1 Muharram 1 AH, taken as Friday 16 July 622 in the Julian calendar. Everything in the app is derived from that one anchor.")
                .font(HJTheme.body(12))
                .foregroundColor(HJTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            HJDivider()
            HJFactRow(key: "Epoch, Julian Day Number", value: "\(HJCalendar.hijriEpochJDN)", mono: true)
            HJDivider()
            HJFactRow(key: "Cycle length", value: "\(HJCalendar.cycleDays) days over 30 years", mono: true)
            HJDivider()
            HJFactRow(key: "Range supported",
                      value: "\(HJCalendar.minHijriYear)\u{2013}\(HJCalendar.maxHijriYear) AH")
            HJDivider()
            Text("An announced date is decided by a local sighting of the new crescent, and can fall a day either side of any calculation. Nothing here should be treated as a confirmed date for Ramadan, either Eid, or any other observance.")
                .font(HJTheme.body(12, .medium))
                .foregroundColor(HJTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Privacy

    private var privacyCard: some View {
        HJCard {
            HJCaption(text: "Privacy")
            Text("The app keeps everything on this device. There are no accounts, no tracking and no reminders of any kind.")
                .font(HJTheme.body(12))
                .foregroundColor(HJTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: { showPrivacy = true }) {
                HStack(spacing: 10) {
                    HJGlyph(shape: HJBookGlyphShape(), size: 16, color: HJTheme.indigo, lineWidth: 1.4)
                    Text("Privacy Policy")
                        .font(HJTheme.body(13.5, .semibold))
                        .foregroundColor(HJTheme.ink)
                    Spacer(minLength: 6)
                    HJGlyph(shape: HJChevronShape(direction: 0), size: 11,
                            color: HJTheme.inkFaint, lineWidth: 1.7)
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 12)
                .background(RoundedRectangle(cornerRadius: 10).fill(HJTheme.cardAlt))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(HJTheme.rule, lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: Reset

    private var resetCard: some View {
        HJCard(tint: confirmingReset ? HJTheme.claySoft.opacity(0.4) : HJTheme.card,
               border: confirmingReset ? HJTheme.clay.opacity(0.35) : HJTheme.rule) {
            HJCaption(text: "Reset", color: HJTheme.clay)
            if confirmingReset {
                Text("This clears every setting and deletes all \(store.personalDates.count) saved date\(store.personalDates.count == 1 ? "" : "s"). It cannot be undone.")
                    .font(HJTheme.body(12.5, .medium))
                    .foregroundColor(HJTheme.clay)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Button(action: {
                        store.resetEverything()
                        confirmingReset = false
                    }) {
                        Text("Reset everything")
                            .font(HJTheme.body(13, .semibold))
                            .foregroundColor(HJTheme.card)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(RoundedRectangle(cornerRadius: 9).fill(HJTheme.clay))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: { confirmingReset = false }) {
                        Text("Cancel")
                            .font(HJTheme.body(13, .medium))
                            .foregroundColor(HJTheme.ink)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(RoundedRectangle(cornerRadius: 9).fill(HJTheme.cardAlt))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer(minLength: 0)
                }
            } else {
                Text("Puts the shift back to zero, restores the display defaults and removes every saved date.")
                    .font(HJTheme.body(12))
                    .foregroundColor(HJTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: { confirmingReset = true }) {
                    Text("Reset the app")
                        .font(HJTheme.body(13, .medium))
                        .foregroundColor(HJTheme.clay)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(RoundedRectangle(cornerRadius: 9).fill(HJTheme.claySoft.opacity(0.5)))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: About

    private var aboutCard: some View {
        HJCard {
            HJCaption(text: "About")
            HJFactRow(key: "Saved dates", value: "\(store.personalDates.count)")
            HJDivider()
            HJFactRow(key: "Observances", value: "\(HJObservances.all.count)")
            HJDivider()
            HJFactRow(key: "History entries", value: "\(HJHistoryLibrary.events.count)")
            HJDivider()
            HJFactRow(key: "Works offline", value: "Yes")
            HJDivider()
            Text("Hijri Date Calendar keeps no account and asks for no permissions. It is a reference, not an authority: where a mosque or a local committee has announced a date, that is the date.")
                .font(HJTheme.body(11.5))
                .foregroundColor(HJTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// The one place a clock time is formatted, so the 12/24-hour preference has a single
/// point of truth.
enum HJClock {
    static func text(twentyFourHour: Bool, date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = twentyFourHour ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }
}
