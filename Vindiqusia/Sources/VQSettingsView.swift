import SwiftUI

struct VQSettingsView: View {

    @EnvironmentObject private var store: VQStore

    @State private var showPrivacy = false
    @State private var confirmingReset = false

    private var format: VQFormatter { store.formatter }
    private var todayJDN: Int { store.todayJDN }

    var body: some View {
        VQScreen(title: "Settings", subtitle: "How the calendar is calculated and how it reads") {
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
            VQWebSheet(address: VQLinks.sourceLink,
                       title: "Privacy Policy",
                       onClose: { showPrivacy = false })
        }
    }

    // MARK: Adjustment

    private var adjustmentCard: some View {
        VQCard {
            VQCaption(text: "Hijri date shift", color: VQTheme.gold)
            Text("The month begins on a local sighting, which no calculation can predict. If the announced date where you are runs ahead of or behind this calendar, shift it here and every screen follows.")
                .font(VQTheme.body(12))
                .foregroundColor(VQTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 5) {
                ForEach([-2, -1, 0, 1, 2], id: \.self) { value in
                    Button(action: { if store.adjustment != value { store.adjustment = value } }) {
                        VStack(spacing: 2) {
                            Text(value == 0 ? "0" : (value > 0 ? "+\(value)" : "\(value)"))
                                .font(VQTheme.figure(16, .semibold))
                                .foregroundColor(store.adjustment == value ? VQTheme.card : VQTheme.ink)
                            Text(previewDay(for: value))
                                .font(VQTheme.body(9))
                                .foregroundColor(store.adjustment == value
                                                 ? VQTheme.card.opacity(0.85) : VQTheme.inkFaint)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 9)
                            .fill(store.adjustment == value ? VQTheme.gold : VQTheme.cardAlt))
                        .overlay(RoundedRectangle(cornerRadius: 9)
                            .stroke(store.adjustment == value ? Color.clear : VQTheme.rule, lineWidth: 1))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            VQDivider()
            VQFactRow(key: "Today becomes", value: format.hijriLong(store.hijri(forJDN: todayJDN)),
                      valueColor: VQTheme.gold)
            Text(store.adjustment == 0
                 ? "No shift is applied: every date is shown exactly as the tabular calendar gives it."
                 : "A shift of \(store.adjustmentLabel.lowercased()) is applied to every date in the app, in both directions of conversion.")
                .font(VQTheme.body(11))
                .foregroundColor(VQTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func previewDay(for shift: Int) -> String {
        let hijri = VQCalendar.hijri(fromJDN: todayJDN + shift)
        return "\(hijri.day) \(VQNames.hijriMonthShort(hijri.month))"
    }

    // MARK: Display

    private var displayCard: some View {
        VQCard {
            VQCaption(text: "Display")

            VStack(alignment: .leading, spacing: 5) {
                Text("Month-name spelling")
                    .font(VQTheme.body(13, .medium))
                    .foregroundColor(VQTheme.ink)
                VQChoiceRow(options: ["Plain \u{2014} Ramadan", "Marked \u{2014} Rama\u{1E0D}\u{101}n"],
                            selection: store.markedSpelling ? 1 : 0) { index in
                    store.markedSpelling = index == 1
                }
                Text("Both are transliterations of the same Arabic name. The marked form uses the macrons and dots used in scholarly writing.")
                    .font(VQTheme.body(10.5))
                    .foregroundColor(VQTheme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VQDivider()

            VStack(alignment: .leading, spacing: 5) {
                Text("Weekday names")
                    .font(VQTheme.body(13, .medium))
                    .foregroundColor(VQTheme.ink)
                VQChoiceRow(options: ["English \u{2014} Friday", "Transliterated \u{2014} al-Jumu\u{2BF}ah"],
                            selection: store.arabicWeekdays ? 1 : 0) { index in
                    store.arabicWeekdays = index == 1
                }
                Text("Both namings are shown together in the day sheet whichever you pick.")
                    .font(VQTheme.body(10.5))
                    .foregroundColor(VQTheme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VQDivider()

            VStack(alignment: .leading, spacing: 5) {
                Text("Week starts on")
                    .font(VQTheme.body(13, .medium))
                    .foregroundColor(VQTheme.ink)
                VQChoiceRow(options: ["Sunday", "Monday", "Saturday"],
                            selection: store.weekStart) { store.weekStart = $0 }
                Text("Sets the first column of the month grid.")
                    .font(VQTheme.body(10.5))
                    .foregroundColor(VQTheme.inkFaint)
            }

            VQDivider()

            VStack(alignment: .leading, spacing: 5) {
                Text("Leading calendar")
                    .font(VQTheme.body(13, .medium))
                    .foregroundColor(VQTheme.ink)
                VQChoiceRow(options: ["Hijri", "Gregorian"],
                            selection: store.primaryCalendar) { store.primaryCalendar = $0 }
                Text("Decides which date is shown large on the Today screen, and which calendar the month grid opens on.")
                    .font(VQTheme.body(10.5))
                    .foregroundColor(VQTheme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VQDivider()

            VQSwitchRow(label: "24-hour clock",
                        detail: "Now reads \(VQClock.text(twentyFourHour: store.twentyFourHour))",
                        isOn: store.twentyFourHour) {
                store.twentyFourHour.toggle()
            }
        }
    }

    // MARK: Calculation

    private var calculationCard: some View {
        VQCard(tint: VQTheme.cardAlt) {
            VQCaption(text: "How the dates are worked out")
            Text("This app uses the arithmetic, or tabular, Islamic calendar. Months run thirty and twenty-nine days in alternation, so an ordinary year is 354 days. Eleven years in every thirty carry a 355th day, added to Dhu al-Hijjah: years 2, 5, 7, 10, 13, 16, 18, 21, 24, 26 and 29 of the cycle.")
                .font(VQTheme.body(12))
                .foregroundColor(VQTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Text("The count starts from 1 Muharram 1 AH, taken as Friday 16 July 622 in the Julian calendar. Everything in the app is derived from that one anchor.")
                .font(VQTheme.body(12))
                .foregroundColor(VQTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            VQDivider()
            VQFactRow(key: "Epoch, Julian Day Number", value: "\(VQCalendar.hijriEpochJDN)", mono: true)
            VQDivider()
            VQFactRow(key: "Cycle length", value: "\(VQCalendar.cycleDays) days over 30 years", mono: true)
            VQDivider()
            VQFactRow(key: "Range supported",
                      value: "\(VQCalendar.minHijriYear)\u{2013}\(VQCalendar.maxHijriYear) AH")
            VQDivider()
            Text("An announced date is decided by a local sighting of the new crescent, and can fall a day either side of any calculation. Nothing here should be treated as a confirmed date for Ramadan, either Eid, or any other observance.")
                .font(VQTheme.body(12, .medium))
                .foregroundColor(VQTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Privacy

    private var privacyCard: some View {
        VQCard {
            VQCaption(text: "Privacy")
            Text("The app keeps everything on this device. There are no accounts, no tracking and no reminders of any kind.")
                .font(VQTheme.body(12))
                .foregroundColor(VQTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: { showPrivacy = true }) {
                HStack(spacing: 10) {
                    VQGlyph(shape: VQBookGlyphShape(), size: 16, color: VQTheme.indigo, lineWidth: 1.4)
                    Text("Privacy Policy")
                        .font(VQTheme.body(13.5, .semibold))
                        .foregroundColor(VQTheme.ink)
                    Spacer(minLength: 6)
                    VQGlyph(shape: VQChevronShape(direction: 0), size: 11,
                            color: VQTheme.inkFaint, lineWidth: 1.7)
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 12)
                .background(RoundedRectangle(cornerRadius: 10).fill(VQTheme.cardAlt))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(VQTheme.rule, lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: Reset

    private var resetCard: some View {
        VQCard(tint: confirmingReset ? VQTheme.claySoft.opacity(0.4) : VQTheme.card,
               border: confirmingReset ? VQTheme.clay.opacity(0.35) : VQTheme.rule) {
            VQCaption(text: "Reset", color: VQTheme.clay)
            if confirmingReset {
                Text("This clears every setting and deletes all \(store.personalDates.count) saved date\(store.personalDates.count == 1 ? "" : "s"). It cannot be undone.")
                    .font(VQTheme.body(12.5, .medium))
                    .foregroundColor(VQTheme.clay)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Button(action: {
                        store.resetEverything()
                        confirmingReset = false
                    }) {
                        Text("Reset everything")
                            .font(VQTheme.body(13, .semibold))
                            .foregroundColor(VQTheme.card)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(RoundedRectangle(cornerRadius: 9).fill(VQTheme.clay))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: { confirmingReset = false }) {
                        Text("Cancel")
                            .font(VQTheme.body(13, .medium))
                            .foregroundColor(VQTheme.ink)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(RoundedRectangle(cornerRadius: 9).fill(VQTheme.cardAlt))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer(minLength: 0)
                }
            } else {
                Text("Puts the shift back to zero, restores the display defaults and removes every saved date.")
                    .font(VQTheme.body(12))
                    .foregroundColor(VQTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: { confirmingReset = true }) {
                    Text("Reset the app")
                        .font(VQTheme.body(13, .medium))
                        .foregroundColor(VQTheme.clay)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(RoundedRectangle(cornerRadius: 9).fill(VQTheme.claySoft.opacity(0.5)))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: About

    private var aboutCard: some View {
        VQCard {
            VQCaption(text: "About")
            VQFactRow(key: "Saved dates", value: "\(store.personalDates.count)")
            VQDivider()
            VQFactRow(key: "Observances", value: "\(VQObservances.all.count)")
            VQDivider()
            VQFactRow(key: "History entries", value: "\(VQHistoryLibrary.events.count)")
            VQDivider()
            VQFactRow(key: "Works offline", value: "Yes")
            VQDivider()
            Text("Vindiqusia keeps no account and asks for no permissions. It is a reference, not an authority: where a mosque or a local committee has announced a date, that is the date.")
                .font(VQTheme.body(11.5))
                .foregroundColor(VQTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// The one place a clock time is formatted, so the 12/24-hour preference has a single
/// point of truth.
enum VQClock {
    static func text(twentyFourHour: Bool, date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = twentyFourHour ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }
}
