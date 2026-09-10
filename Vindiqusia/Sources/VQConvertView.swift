import SwiftUI

struct VQConvertView: View {

    @EnvironmentObject private var store: VQStore

    @State private var mode: Int = 0
    /// Convert tab: 0 = enter a Hijri date, 1 = enter a Gregorian date.
    @State private var direction: Int = 0
    @State private var convertJDN: Int = VQCalendar.todayJDN()

    /// Age tab.
    @State private var ageCalendar: Int = 0
    @State private var birthJDN: Int = VQCalendar.todayJDN() - 8000

    /// Difference tab.
    @State private var diffCalendar: Int = 0
    @State private var diffEditing: Int = 0
    @State private var diffFromJDN: Int = VQCalendar.todayJDN()
    @State private var diffToJDN: Int = VQCalendar.todayJDN() + 100

    private var format: VQFormatter { store.formatter }
    private var todayJDN: Int { store.todayJDN }

    private static let civilFloor = 623
    private static let civilCeiling = 3400

    var body: some View {
        VQScreen(title: "Convert", subtitle: "Both directions, an age in Hijri years, and the gap between two dates") {
            VQSegmented(options: ["Convert", "Age", "Difference"], selection: $mode)
            switch mode {
            case 1: ageSection
            case 2: differenceSection
            default: convertSection
            }
            VQEstimateNote()
                .padding(.horizontal, 2)
        }
    }

    // MARK: Bindings

    private func clamped(_ jdn: Int) -> Int { VQCalendar.clampJDN(jdn) }

    private func hijriBinding(_ source: Binding<Int>) -> Binding<VQHijriDate> {
        Binding(get: { store.hijri(forJDN: source.wrappedValue) },
                set: { source.wrappedValue = clamped(store.jdn(forHijri: VQCalendar.clampHijri($0))) })
    }

    private func civilBinding(_ source: Binding<Int>) -> Binding<VQCivilDate> {
        Binding(get: { VQCalendar.civil(fromJDN: source.wrappedValue) },
                set: { source.wrappedValue = clamped(VQCalendar.jdn(fromCivil: VQCalendar.clampCivil($0))) })
    }

    // MARK: Convert

    private var convertSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VQSegmented(options: ["Hijri \u{2192} Gregorian", "Gregorian \u{2192} Hijri"],
                        selection: $direction)

            VQCard {
                VQCaption(text: direction == 0 ? "Enter a Hijri date" : "Enter a Gregorian date",
                          color: direction == 0 ? VQTheme.gold : VQTheme.indigo)
                if direction == 0 {
                    VQHijriDatePicker(value: hijriBinding($convertJDN),
                                      markedSpelling: store.markedSpelling,
                                      onSetToday: { convertJDN = todayJDN })
                } else {
                    VQCivilDatePicker(value: civilBinding($convertJDN),
                                      lowerYear: VQConvertView.civilFloor,
                                      upperYear: VQConvertView.civilCeiling,
                                      onSetToday: { convertJDN = todayJDN })
                }
            }

            resultCard(for: convertJDN)
        }
    }

    private func resultCard(for jdn: Int) -> some View {
        let hijri = store.hijri(forJDN: jdn)
        let civil = VQCalendar.civil(fromJDN: jdn)
        let weekday = VQCalendar.weekdayIndex(jdn: jdn)
        let delta = jdn - todayJDN
        return VQCard(tint: VQTheme.cardAlt) {
            VQCaption(text: "Result")
            VStack(alignment: .leading, spacing: 3) {
                Text(direction == 0 ? format.civilLong(civil) : format.hijriLong(hijri))
                    .font(VQTheme.display(21))
                    .foregroundColor(VQTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(direction == 0 ? format.hijriLong(hijri) : format.civilLong(civil))
                    .font(VQTheme.body(13))
                    .foregroundColor(VQTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VQDivider()
            VQFactRow(key: "Weekday", value: VQNames.weekday(weekday, arabic: false))
            VQDivider()
            VQFactRow(key: "Weekday, transliterated", value: VQNames.weekday(weekday, arabic: true))
            VQDivider()
            VQFactRow(key: "Day of the Hijri year",
                      value: "\(VQCalendar.hijriDayOfYear(hijri)) of \(VQCalendar.hijriYearLength(hijri.year))")
            VQDivider()
            VQFactRow(key: "Day of the Gregorian year",
                      value: "\(VQCalendar.civilDayOfYear(civil)) of \(VQCalendar.civilYearLength(civil.year))")
            VQDivider()
            VQFactRow(key: "Julian Day Number", value: "\(jdn)", mono: true)
            VQDivider()
            VQFactRow(key: "From today",
                      value: delta == 0 ? "0 days" : "\(delta > 0 ? "+" : "")\(delta) days",
                      valueColor: delta == 0 ? VQTheme.gold : VQTheme.ink,
                      mono: true)
            if store.adjustment != 0 {
                VQDivider()
                VQFactRow(key: "Your shift", value: store.adjustmentLabel, valueColor: VQTheme.gold)
            }
        }
    }

    // MARK: Age

    private var ageSection: some View {
        let birth = min(birthJDN, todayJDN)
        let inFuture = birthJDN > todayJDN
        let birthHijri = store.hijri(forJDN: birth)
        let birthCivil = VQCalendar.civil(fromJDN: birth)
        let todayHijri = store.hijri(forJDN: todayJDN)
        let todayCivil = VQCalendar.civil(fromJDN: todayJDN)
        let hijriAge = VQSpanMath.hijriSpan(from: birthHijri, to: todayHijri)
        let civilAge = VQSpanMath.civilSpan(from: birthCivil, to: todayCivil)
        let totalDays = todayJDN - birth
        let nextBirthdayJDN = nextHijriAnniversary(of: birthHijri)
        let untilNext = nextBirthdayJDN - todayJDN

        return VStack(alignment: .leading, spacing: 14) {
            VQCard {
                VQCaption(text: "Enter a birth date")
                VQSegmented(options: ["By Hijri date", "By Gregorian date"], selection: $ageCalendar)
                if ageCalendar == 0 {
                    VQHijriDatePicker(value: hijriBinding($birthJDN),
                                      markedSpelling: store.markedSpelling,
                                      onSetToday: { birthJDN = todayJDN })
                } else {
                    VQCivilDatePicker(value: civilBinding($birthJDN),
                                      lowerYear: VQConvertView.civilFloor,
                                      upperYear: VQConvertView.civilCeiling,
                                      onSetToday: { birthJDN = todayJDN })
                }
            }

            if inFuture {
                VQCard(tint: VQTheme.claySoft.opacity(0.4), border: VQTheme.clay.opacity(0.3)) {
                    Text("That date is in the future.")
                        .font(VQTheme.body(13, .semibold))
                        .foregroundColor(VQTheme.clay)
                    Text("Pick a date on or before today and the age will be worked out from it.")
                        .font(VQTheme.body(12))
                        .foregroundColor(VQTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                VQCard(tint: VQTheme.cardAlt) {
                    VQCaption(text: "Age in Hijri years", color: VQTheme.gold)
                    Text(hijriAge.phrase)
                        .font(VQTheme.display(21))
                        .foregroundColor(VQTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    VQDivider()
                    VQFactRow(key: "Age in Gregorian years", value: civilAge.phrase)
                    VQDivider()
                    VQFactRow(key: "Days lived", value: "\(totalDays)", mono: true)
                    VQDivider()
                    VQFactRow(key: "Born on a", value: VQNames.weekday(VQCalendar.weekdayIndex(jdn: birth), arabic: false))
                    VQDivider()
                    VQFactRow(key: "Born, Hijri", value: format.hijriLong(birthHijri))
                    VQDivider()
                    VQFactRow(key: "Born, Gregorian", value: format.civilLong(birthCivil))
                }

                VQCard {
                    VQCaption(text: "Hijri birthday")
                    Text(format.hijriDayMonth(birthHijri))
                        .font(VQTheme.display(19))
                        .foregroundColor(VQTheme.ink)
                    Text("It comes round every Hijri year, so it moves about eleven days earlier in the Gregorian calendar each time.")
                        .font(VQTheme.body(11.5))
                        .foregroundColor(VQTheme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                    VQDivider()
                    VQFactRow(key: "Next occurrence",
                              value: format.civilShort(VQCalendar.civil(fromJDN: nextBirthdayJDN)))
                    VQDivider()
                    VQFactRow(key: "That is",
                              value: format.hijriLong(store.hijri(forJDN: nextBirthdayJDN)))
                    VQDivider()
                    VQFactRow(key: "Countdown",
                              value: untilNext == 0 ? "Today" : VQFormatter.plural(untilNext, "day", "days"),
                              valueColor: untilNext == 0 ? VQTheme.gold : VQTheme.verdant)
                    VQDivider()
                    VQFactRow(key: "Turning",
                              value: "\(max(0, store.hijri(forJDN: nextBirthdayJDN).year - birthHijri.year)) Hijri years")
                }

                VQCard(tint: VQTheme.goldWash.opacity(0.55), border: VQTheme.gold.opacity(0.3)) {
                    Text("Why the two ages differ")
                        .font(VQTheme.body(13, .semibold))
                        .foregroundColor(VQTheme.ink)
                    Text("A Hijri year is about 354 days against the solar year's 365, so a Hijri age runs ahead of a Gregorian one by roughly one year in every thirty-three. The gap here is \(max(0, hijriAge.years - civilAge.years)) year\(max(0, hijriAge.years - civilAge.years) == 1 ? "" : "s").")
                        .font(VQTheme.body(12))
                        .foregroundColor(VQTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func nextHijriAnniversary(of birth: VQHijriDate) -> Int {
        let today = store.hijri(forJDN: todayJDN)
        var year = today.year
        for _ in 0...2 {
            let length = VQCalendar.hijriMonthLength(year: year, month: birth.month)
            let candidate = VQHijriDate(year: year, month: birth.month, day: min(birth.day, length))
            let jdn = store.jdn(forHijri: candidate)
            if jdn >= todayJDN { return jdn }
            year += 1
        }
        return store.jdn(forHijri: VQHijriDate(year: year, month: birth.month, day: 1))
    }

    // MARK: Difference

    private var differenceSection: some View {
        let low = min(diffFromJDN, diffToJDN)
        let high = max(diffFromJDN, diffToJDN)
        let totalDays = high - low
        let signedDays = diffToJDN - diffFromJDN
        let hijriSpan = VQSpanMath.hijriSpan(from: store.hijri(forJDN: low), to: store.hijri(forJDN: high))
        let civilSpan = VQSpanMath.civilSpan(from: VQCalendar.civil(fromJDN: low),
                                             to: VQCalendar.civil(fromJDN: high))

        return VStack(alignment: .leading, spacing: 14) {
            VQCard {
                VQCaption(text: "The two dates")
                VStack(spacing: 0) {
                    diffSummaryRow(label: "First", jdn: diffFromJDN, index: 0)
                    VQDivider()
                    diffSummaryRow(label: "Second", jdn: diffToJDN, index: 1)
                }
                HStack(spacing: 8) {
                    VQQuietButton(label: "First = today", tint: VQTheme.gold) {
                        diffFromJDN = todayJDN
                    }
                    VQQuietButton(label: "Second = today", tint: VQTheme.indigo) {
                        diffToJDN = todayJDN
                    }
                    Spacer(minLength: 0)
                }
            }

            VQCard {
                VQSegmented(options: ["Edit first date", "Edit second date"], selection: $diffEditing)
                VQSegmented(options: ["By Hijri date", "By Gregorian date"], selection: $diffCalendar)
                if diffCalendar == 0 {
                    VQHijriDatePicker(value: hijriBinding(diffEditing == 0 ? $diffFromJDN : $diffToJDN),
                                      markedSpelling: store.markedSpelling,
                                      onSetToday: {
                                          if diffEditing == 0 { diffFromJDN = todayJDN } else { diffToJDN = todayJDN }
                                      })
                } else {
                    VQCivilDatePicker(value: civilBinding(diffEditing == 0 ? $diffFromJDN : $diffToJDN),
                                      lowerYear: VQConvertView.civilFloor,
                                      upperYear: VQConvertView.civilCeiling,
                                      onSetToday: {
                                          if diffEditing == 0 { diffFromJDN = todayJDN } else { diffToJDN = todayJDN }
                                      })
                }
            }

            VQCard(tint: VQTheme.cardAlt) {
                VQCaption(text: "Difference")
                Text(VQFormatter.plural(totalDays, "day", "days"))
                    .font(VQTheme.display(23))
                    .foregroundColor(VQTheme.ink)
                Text(signedDays == 0
                     ? "The two dates are the same day."
                     : (signedDays > 0 ? "The second date is later." : "The second date is earlier."))
                    .font(VQTheme.body(12))
                    .foregroundColor(VQTheme.inkFaint)
                VQDivider()
                VQFactRow(key: "In weeks", value: VQSpanMath.weeksAndDays(totalDays))
                VQDivider()
                VQFactRow(key: "Counted in Hijri months", value: hijriSpan.phrase)
                VQDivider()
                VQFactRow(key: "Counted in Gregorian months", value: civilSpan.phrase)
                VQDivider()
                VQFactRow(key: "Julian Day Numbers", value: "\(low) \u{2192} \(high)", mono: true)
            }
        }
    }

    private func diffSummaryRow(label: String, jdn: Int, index: Int) -> some View {
        Button(action: { diffEditing = index }) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(VQTheme.body(10.5, .semibold))
                        .foregroundColor(diffEditing == index ? VQTheme.gold : VQTheme.inkFaint)
                    Text(format.civilLong(VQCalendar.civil(fromJDN: jdn)))
                        .font(VQTheme.body(13.5, .semibold))
                        .foregroundColor(VQTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(format.hijriLong(store.hijri(forJDN: jdn)))
                        .font(VQTheme.body(11.5))
                        .foregroundColor(VQTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 6)
                if diffEditing == index {
                    VQChip(text: "Editing", tint: VQTheme.gold)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
