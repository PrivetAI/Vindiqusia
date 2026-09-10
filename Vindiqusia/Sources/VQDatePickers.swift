import SwiftUI

// The system `DatePicker` is not used anywhere in this app. These two controls are built
// from buttons and shapes: a year stepper, a grid of months, and a grid of days.

// MARK: - Shared pieces

private struct VQYearStepper: View {
    var label: String
    var year: Int
    var lower: Int
    var upper: Int
    var suffix: String
    var onSet: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VQCaption(text: label)
            HStack(spacing: 5) {
                step("\u{2212}10", enabled: year - 10 >= lower) { onSet(clamp(year - 10)) }
                step("\u{2212}1", enabled: year - 1 >= lower) { onSet(clamp(year - 1)) }
                VStack(spacing: 0) {
                    Text(verbatim: "\(year)")
                        .font(VQTheme.figure(19, .semibold))
                        .foregroundColor(VQTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(suffix)
                        .font(VQTheme.body(9.5))
                        .foregroundColor(VQTheme.inkFaint)
                }
                .frame(maxWidth: .infinity)
                step("+1", enabled: year + 1 <= upper) { onSet(clamp(year + 1)) }
                step("+10", enabled: year + 10 <= upper) { onSet(clamp(year + 10)) }
            }
        }
    }

    private func clamp(_ value: Int) -> Int { max(lower, min(upper, value)) }

    private func step(_ text: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { if enabled { action() } }) {
            Text(text)
                .font(VQTheme.body(12, .semibold))
                .foregroundColor(enabled ? VQTheme.ink : VQTheme.inkFaint.opacity(0.45))
                .frame(width: 42, height: 34)
                .background(RoundedRectangle(cornerRadius: 8).fill(VQTheme.cardAlt))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(VQTheme.rule, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct VQPillGrid: View {
    var labels: [String]
    var columns: Int
    var selectedIndex: Int
    var onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: 5) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 5) {
                    ForEach(rows[rowIndex], id: \.self) { index in
                        Button(action: { onSelect(index) }) {
                            Text(labels[index])
                                .font(VQTheme.body(12, selectedIndex == index ? .semibold : .regular))
                                .foregroundColor(selectedIndex == index ? VQTheme.card : VQTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedIndex == index ? VQTheme.ink : VQTheme.cardAlt))
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedIndex == index ? Color.clear : VQTheme.rule,
                                            lineWidth: 1))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    if rows[rowIndex].count < columns {
                        ForEach(Array(0..<(columns - rows[rowIndex].count)), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity).frame(height: 1)
                        }
                    }
                }
            }
        }
    }

    private var rows: [[Int]] {
        var out: [[Int]] = []
        var current: [Int] = []
        for index in labels.indices {
            current.append(index)
            if current.count == columns { out.append(current); current = [] }
        }
        if !current.isEmpty { out.append(current) }
        return out
    }
}

private struct VQDayGrid: View {
    var length: Int
    var selectedDay: Int
    var accent: Color
    var onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: 4) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 4) {
                    ForEach(rows[rowIndex], id: \.self) { day in
                        Button(action: { onSelect(day) }) {
                            Text("\(day)")
                                .font(VQTheme.figure(13, selectedDay == day ? .bold : .regular))
                                .foregroundColor(selectedDay == day ? VQTheme.card : VQTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .background(RoundedRectangle(cornerRadius: 7)
                                    .fill(selectedDay == day ? accent : VQTheme.cardAlt))
                                .overlay(RoundedRectangle(cornerRadius: 7)
                                    .stroke(selectedDay == day ? Color.clear : VQTheme.rule,
                                            lineWidth: 1))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    if rows[rowIndex].count < 7 {
                        ForEach(Array(0..<(7 - rows[rowIndex].count)), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity).frame(height: 32)
                        }
                    }
                }
            }
        }
    }

    private var rows: [[Int]] {
        var out: [[Int]] = []
        var current: [Int] = []
        guard length > 0 else { return out }
        for day in 1...length {
            current.append(day)
            if current.count == 7 { out.append(current); current = [] }
        }
        if !current.isEmpty { out.append(current) }
        return out
    }
}

// MARK: - Hijri picker

struct VQHijriDatePicker: View {

    @Binding var value: VQHijriDate
    var markedSpelling: Bool
    var onSetToday: (() -> Void)? = nil

    private var monthLength: Int {
        VQCalendar.hijriMonthLength(year: value.year, month: value.month)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VQYearStepper(label: "Hijri year",
                          year: value.year,
                          lower: VQCalendar.minHijriYear,
                          upper: VQCalendar.maxHijriYear,
                          suffix: "AH") { newYear in
                apply(year: newYear, month: value.month, day: value.day)
            }

            VStack(alignment: .leading, spacing: 6) {
                VQCaption(text: "Month")
                VQPillGrid(labels: (1...12).map { VQNames.hijriMonth($0, marked: markedSpelling) },
                           columns: 2,
                           selectedIndex: value.month - 1) { index in
                    apply(year: value.year, month: index + 1, day: value.day)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VQCaption(text: "Day")
                    Spacer(minLength: 6)
                    Text("\(monthLength)-day month")
                        .font(VQTheme.body(10))
                        .foregroundColor(VQTheme.inkFaint)
                }
                VQDayGrid(length: monthLength,
                          selectedDay: value.day,
                          accent: VQTheme.gold) { day in
                    apply(year: value.year, month: value.month, day: day)
                }
            }

            if let onSetToday = onSetToday {
                VQQuietButton(label: "Set to today", tint: VQTheme.gold, action: onSetToday)
            }
        }
    }

    private func apply(year: Int, month: Int, day: Int) {
        let boundedYear = max(VQCalendar.minHijriYear, min(VQCalendar.maxHijriYear, year))
        let boundedMonth = max(1, min(12, month))
        let length = VQCalendar.hijriMonthLength(year: boundedYear, month: boundedMonth)
        value = VQHijriDate(year: boundedYear,
                            month: boundedMonth,
                            day: max(1, min(length, day)))
    }
}

// MARK: - Gregorian picker

struct VQCivilDatePicker: View {

    @Binding var value: VQCivilDate
    var lowerYear: Int = 700
    var upperYear: Int = 3400
    var onSetToday: (() -> Void)? = nil

    private var monthLength: Int {
        VQCalendar.civilMonthLength(year: value.year, month: value.month)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VQYearStepper(label: "Gregorian year",
                          year: value.year,
                          lower: lowerYear,
                          upper: upperYear,
                          suffix: "CE") { newYear in
                apply(year: newYear, month: value.month, day: value.day)
            }

            VStack(alignment: .leading, spacing: 6) {
                VQCaption(text: "Month")
                VQPillGrid(labels: VQNames.civilMonths,
                           columns: 3,
                           selectedIndex: value.month - 1) { index in
                    apply(year: value.year, month: index + 1, day: value.day)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VQCaption(text: "Day")
                    Spacer(minLength: 6)
                    Text("\(monthLength)-day month")
                        .font(VQTheme.body(10))
                        .foregroundColor(VQTheme.inkFaint)
                }
                VQDayGrid(length: monthLength,
                          selectedDay: value.day,
                          accent: VQTheme.indigo) { day in
                    apply(year: value.year, month: value.month, day: day)
                }
            }

            if let onSetToday = onSetToday {
                VQQuietButton(label: "Set to today", tint: VQTheme.indigo, action: onSetToday)
            }
        }
    }

    private func apply(year: Int, month: Int, day: Int) {
        let boundedYear = max(lowerYear, min(upperYear, year))
        let boundedMonth = max(1, min(12, month))
        let length = VQCalendar.civilMonthLength(year: boundedYear, month: boundedMonth)
        value = VQCivilDate(year: boundedYear,
                            month: boundedMonth,
                            day: max(1, min(length, day)))
    }
}
