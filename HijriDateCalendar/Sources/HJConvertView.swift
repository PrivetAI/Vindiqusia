import SwiftUI

struct HJConvertView: View {

    @EnvironmentObject private var store: HJStore

    @State private var mode: Int = 0
    /// Convert tab: 0 = enter a Hijri date, 1 = enter a Gregorian date.
    @State private var direction: Int = 0
    @State private var convertJDN: Int = HJCalendar.todayJDN()

    /// Age tab.
    @State private var ageCalendar: Int = 0
    @State private var birthJDN: Int = HJCalendar.todayJDN() - 8000

    /// Difference tab.
    @State private var diffCalendar: Int = 0
    @State private var diffEditing: Int = 0
    @State private var diffFromJDN: Int = HJCalendar.todayJDN()
    @State private var diffToJDN: Int = HJCalendar.todayJDN() + 100

    private var format: HJFormatter { store.formatter }
    private var todayJDN: Int { store.todayJDN }

    private static let civilFloor = 623
    private static let civilCeiling = 3400

    var body: some View {
        HJScreen(title: "Convert", subtitle: "Both directions, an age in Hijri years, and the gap between two dates") {
            HJSegmented(options: ["Convert", "Age", "Difference"], selection: $mode)
            switch mode {
            case 1: ageSection
            case 2: differenceSection
            default: convertSection
            }
            HJEstimateNote()
                .padding(.horizontal, 2)
        }
    }

    // MARK: Bindings

    private func clamped(_ jdn: Int) -> Int { HJCalendar.clampJDN(jdn) }

    private func hijriBinding(_ source: Binding<Int>) -> Binding<HJHijriDate> {
        Binding(get: { store.hijri(forJDN: source.wrappedValue) },
                set: { source.wrappedValue = clamped(store.jdn(forHijri: HJCalendar.clampHijri($0))) })
    }

    private func civilBinding(_ source: Binding<Int>) -> Binding<HJCivilDate> {
        Binding(get: { HJCalendar.civil(fromJDN: source.wrappedValue) },
                set: { source.wrappedValue = clamped(HJCalendar.jdn(fromCivil: HJCalendar.clampCivil($0))) })
    }

    // MARK: Convert

    private var convertSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HJSegmented(options: ["Hijri \u{2192} Gregorian", "Gregorian \u{2192} Hijri"],
                        selection: $direction)

            HJCard {
                HJCaption(text: direction == 0 ? "Enter a Hijri date" : "Enter a Gregorian date",
                          color: direction == 0 ? HJTheme.gold : HJTheme.indigo)
                if direction == 0 {
                    HJHijriDatePicker(value: hijriBinding($convertJDN),
                                      markedSpelling: store.markedSpelling,
                                      onSetToday: { convertJDN = todayJDN })
                } else {
                    HJCivilDatePicker(value: civilBinding($convertJDN),
                                      lowerYear: HJConvertView.civilFloor,
                                      upperYear: HJConvertView.civilCeiling,
                                      onSetToday: { convertJDN = todayJDN })
                }
            }

            resultCard(for: convertJDN)
        }
    }

    private func resultCard(for jdn: Int) -> some View {
        let hijri = store.hijri(forJDN: jdn)
        let civil = HJCalendar.civil(fromJDN: jdn)
        let weekday = HJCalendar.weekdayIndex(jdn: jdn)
        let delta = jdn - todayJDN
        return HJCard(tint: HJTheme.cardAlt) {
            HJCaption(text: "Result")
            VStack(alignment: .leading, spacing: 3) {
                Text(direction == 0 ? format.civilLong(civil) : format.hijriLong(hijri))
                    .font(HJTheme.display(21))
                    .foregroundColor(HJTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(direction == 0 ? format.hijriLong(hijri) : format.civilLong(civil))
                    .font(HJTheme.body(13))
                    .foregroundColor(HJTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HJDivider()
            HJFactRow(key: "Weekday", value: HJNames.weekday(weekday, arabic: false))
            HJDivider()
            HJFactRow(key: "Weekday, transliterated", value: HJNames.weekday(weekday, arabic: true))
            HJDivider()
            HJFactRow(key: "Day of the Hijri year",
                      value: "\(HJCalendar.hijriDayOfYear(hijri)) of \(HJCalendar.hijriYearLength(hijri.year))")
            HJDivider()
            HJFactRow(key: "Day of the Gregorian year",
                      value: "\(HJCalendar.civilDayOfYear(civil)) of \(HJCalendar.civilYearLength(civil.year))")
            HJDivider()
            HJFactRow(key: "Julian Day Number", value: "\(jdn)", mono: true)
            HJDivider()
            HJFactRow(key: "From today",
                      value: delta == 0 ? "0 days" : "\(delta > 0 ? "+" : "")\(delta) days",
                      valueColor: delta == 0 ? HJTheme.gold : HJTheme.ink,
                      mono: true)
            if store.adjustment != 0 {
                HJDivider()
                HJFactRow(key: "Your shift", value: store.adjustmentLabel, valueColor: HJTheme.gold)
            }
        }
    }

    // MARK: Age

    private var ageSection: some View {
        let birth = min(birthJDN, todayJDN)
        let inFuture = birthJDN > todayJDN
        let birthHijri = store.hijri(forJDN: birth)
        let birthCivil = HJCalendar.civil(fromJDN: birth)
        let todayHijri = store.hijri(forJDN: todayJDN)
        let todayCivil = HJCalendar.civil(fromJDN: todayJDN)
        let hijriAge = HJSpanMath.hijriSpan(from: birthHijri, to: todayHijri)
        let civilAge = HJSpanMath.civilSpan(from: birthCivil, to: todayCivil)
        let totalDays = todayJDN - birth
        let nextBirthdayJDN = nextHijriAnniversary(of: birthHijri)
        let untilNext = nextBirthdayJDN - todayJDN

        return VStack(alignment: .leading, spacing: 14) {
            HJCard {
                HJCaption(text: "Enter a birth date")
                HJSegmented(options: ["By Hijri date", "By Gregorian date"], selection: $ageCalendar)
                if ageCalendar == 0 {
                    HJHijriDatePicker(value: hijriBinding($birthJDN),
                                      markedSpelling: store.markedSpelling,
                                      onSetToday: { birthJDN = todayJDN })
                } else {
                    HJCivilDatePicker(value: civilBinding($birthJDN),
                                      lowerYear: HJConvertView.civilFloor,
                                      upperYear: HJConvertView.civilCeiling,
                                      onSetToday: { birthJDN = todayJDN })
                }
            }

            if inFuture {
                HJCard(tint: HJTheme.claySoft.opacity(0.4), border: HJTheme.clay.opacity(0.3)) {
                    Text("That date is in the future.")
                        .font(HJTheme.body(13, .semibold))
                        .foregroundColor(HJTheme.clay)
                    Text("Pick a date on or before today and the age will be worked out from it.")
                        .font(HJTheme.body(12))
                        .foregroundColor(HJTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                HJCard(tint: HJTheme.cardAlt) {
                    HJCaption(text: "Age in Hijri years", color: HJTheme.gold)
                    Text(hijriAge.phrase)
                        .font(HJTheme.display(21))
                        .foregroundColor(HJTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    HJDivider()
                    HJFactRow(key: "Age in Gregorian years", value: civilAge.phrase)
                    HJDivider()
                    HJFactRow(key: "Days lived", value: "\(totalDays)", mono: true)
                    HJDivider()
                    HJFactRow(key: "Born on a", value: HJNames.weekday(HJCalendar.weekdayIndex(jdn: birth), arabic: false))
                    HJDivider()
                    HJFactRow(key: "Born, Hijri", value: format.hijriLong(birthHijri))
                    HJDivider()
                    HJFactRow(key: "Born, Gregorian", value: format.civilLong(birthCivil))
                }

                HJCard {
                    HJCaption(text: "Hijri birthday")
                    Text(format.hijriDayMonth(birthHijri))
                        .font(HJTheme.display(19))
                        .foregroundColor(HJTheme.ink)
                    Text("It comes round every Hijri year, so it moves about eleven days earlier in the Gregorian calendar each time.")
                        .font(HJTheme.body(11.5))
                        .foregroundColor(HJTheme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                    HJDivider()
                    HJFactRow(key: "Next occurrence",
                              value: format.civilShort(HJCalendar.civil(fromJDN: nextBirthdayJDN)))
                    HJDivider()
                    HJFactRow(key: "That is",
                              value: format.hijriLong(store.hijri(forJDN: nextBirthdayJDN)))
                    HJDivider()
                    HJFactRow(key: "Countdown",
                              value: untilNext == 0 ? "Today" : HJFormatter.plural(untilNext, "day", "days"),
                              valueColor: untilNext == 0 ? HJTheme.gold : HJTheme.verdant)
                    HJDivider()
                    HJFactRow(key: "Turning",
                              value: "\(max(0, store.hijri(forJDN: nextBirthdayJDN).year - birthHijri.year)) Hijri years")
                }

                HJCard(tint: HJTheme.goldWash.opacity(0.55), border: HJTheme.gold.opacity(0.3)) {
                    Text("Why the two ages differ")
                        .font(HJTheme.body(13, .semibold))
                        .foregroundColor(HJTheme.ink)
                    Text("A Hijri year is about 354 days against the solar year's 365, so a Hijri age runs ahead of a Gregorian one by roughly one year in every thirty-three. The gap here is \(max(0, hijriAge.years - civilAge.years)) year\(max(0, hijriAge.years - civilAge.years) == 1 ? "" : "s").")
                        .font(HJTheme.body(12))
                        .foregroundColor(HJTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func nextHijriAnniversary(of birth: HJHijriDate) -> Int {
        let today = store.hijri(forJDN: todayJDN)
        var year = today.year
        for _ in 0...2 {
            let length = HJCalendar.hijriMonthLength(year: year, month: birth.month)
            let candidate = HJHijriDate(year: year, month: birth.month, day: min(birth.day, length))
            let jdn = store.jdn(forHijri: candidate)
            if jdn >= todayJDN { return jdn }
            year += 1
        }
        return store.jdn(forHijri: HJHijriDate(year: year, month: birth.month, day: 1))
    }

    // MARK: Difference

    private var differenceSection: some View {
        let low = min(diffFromJDN, diffToJDN)
        let high = max(diffFromJDN, diffToJDN)
        let totalDays = high - low
        let signedDays = diffToJDN - diffFromJDN
        let hijriSpan = HJSpanMath.hijriSpan(from: store.hijri(forJDN: low), to: store.hijri(forJDN: high))
        let civilSpan = HJSpanMath.civilSpan(from: HJCalendar.civil(fromJDN: low),
                                             to: HJCalendar.civil(fromJDN: high))

        return VStack(alignment: .leading, spacing: 14) {
            HJCard {
                HJCaption(text: "The two dates")
                VStack(spacing: 0) {
                    diffSummaryRow(label: "First", jdn: diffFromJDN, index: 0)
                    HJDivider()
                    diffSummaryRow(label: "Second", jdn: diffToJDN, index: 1)
                }
                HStack(spacing: 8) {
                    HJQuietButton(label: "First = today", tint: HJTheme.gold) {
                        diffFromJDN = todayJDN
                    }
                    HJQuietButton(label: "Second = today", tint: HJTheme.indigo) {
                        diffToJDN = todayJDN
                    }
                    Spacer(minLength: 0)
                }
            }

            HJCard {
                HJSegmented(options: ["Edit first date", "Edit second date"], selection: $diffEditing)
                HJSegmented(options: ["By Hijri date", "By Gregorian date"], selection: $diffCalendar)
                if diffCalendar == 0 {
                    HJHijriDatePicker(value: hijriBinding(diffEditing == 0 ? $diffFromJDN : $diffToJDN),
                                      markedSpelling: store.markedSpelling,
                                      onSetToday: {
                                          if diffEditing == 0 { diffFromJDN = todayJDN } else { diffToJDN = todayJDN }
                                      })
                } else {
                    HJCivilDatePicker(value: civilBinding(diffEditing == 0 ? $diffFromJDN : $diffToJDN),
                                      lowerYear: HJConvertView.civilFloor,
                                      upperYear: HJConvertView.civilCeiling,
                                      onSetToday: {
                                          if diffEditing == 0 { diffFromJDN = todayJDN } else { diffToJDN = todayJDN }
                                      })
                }
            }

            HJCard(tint: HJTheme.cardAlt) {
                HJCaption(text: "Difference")
                Text(HJFormatter.plural(totalDays, "day", "days"))
                    .font(HJTheme.display(23))
                    .foregroundColor(HJTheme.ink)
                Text(signedDays == 0
                     ? "The two dates are the same day."
                     : (signedDays > 0 ? "The second date is later." : "The second date is earlier."))
                    .font(HJTheme.body(12))
                    .foregroundColor(HJTheme.inkFaint)
                HJDivider()
                HJFactRow(key: "In weeks", value: HJSpanMath.weeksAndDays(totalDays))
                HJDivider()
                HJFactRow(key: "Counted in Hijri months", value: hijriSpan.phrase)
                HJDivider()
                HJFactRow(key: "Counted in Gregorian months", value: civilSpan.phrase)
                HJDivider()
                HJFactRow(key: "Julian Day Numbers", value: "\(low) \u{2192} \(high)", mono: true)
            }
        }
    }

    private func diffSummaryRow(label: String, jdn: Int, index: Int) -> some View {
        Button(action: { diffEditing = index }) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(HJTheme.body(10.5, .semibold))
                        .foregroundColor(diffEditing == index ? HJTheme.gold : HJTheme.inkFaint)
                    Text(format.civilLong(HJCalendar.civil(fromJDN: jdn)))
                        .font(HJTheme.body(13.5, .semibold))
                        .foregroundColor(HJTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(format.hijriLong(store.hijri(forJDN: jdn)))
                        .font(HJTheme.body(11.5))
                        .foregroundColor(HJTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 6)
                if diffEditing == index {
                    HJChip(text: "Editing", tint: HJTheme.gold)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
