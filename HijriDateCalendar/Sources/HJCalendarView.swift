import SwiftUI

/// One day of the grid. Everything it needs arrives as value types, so a change to any of
/// them actually redraws the cell.
struct HJDayCellData: Equatable {
    let jdn: Int
    let primary: String
    let secondary: String
    let secondaryIsMonthStart: Bool
    let isToday: Bool
    let hasObservance: Bool
    let hasPersonal: Bool
    let fastKind: Int
    let isFriday: Bool
}

private struct HJSelectedDay: Identifiable {
    let id: Int
    var jdn: Int { id }
}

struct HJCalendarView: View {

    @EnvironmentObject private var store: HJStore

    /// 0 = the grid follows Hijri months, 1 = it follows Gregorian months.
    @State private var gridMode: Int = -1
    @State private var anchorJDN: Int = HJCalendar.todayJDN()
    @State private var selected: HJSelectedDay? = nil
    @State private var showYearJump = false
    @State private var yearDraft: Int = 0

    private var format: HJFormatter { store.formatter }
    private var todayJDN: Int { store.todayJDN }
    private var hijriLed: Bool { resolvedMode == 0 }
    private var resolvedMode: Int { gridMode < 0 ? store.primaryCalendar : gridMode }

    private static let minAnchor = HJCalendar.minJDN + 40
    private static let maxAnchor = HJCalendar.maxJDN - 40

    var body: some View {
        HJScreen(title: "Calendar", subtitle: monthSubtitle) {
            HJSegmented(options: ["Hijri months", "Gregorian months"],
                        selection: Binding(get: { resolvedMode },
                                           set: { gridMode = $0 }))

            navigatorCard
            gridCard
            legendCard
            HJEstimateNote()
                .padding(.horizontal, 2)
        }
        .sheet(item: $selected) { day in
            HJDayDetailView(jdn: day.jdn, onClose: { selected = nil })
                .environmentObject(store)
        }
        .onAppear {
            if yearDraft == 0 { yearDraft = currentDisplayYear }
        }
    }

    // MARK: Month frame

    private var anchorHijri: HJHijriDate { store.hijri(forJDN: anchorJDN) }
    private var anchorCivil: HJCivilDate { HJCalendar.civil(fromJDN: anchorJDN) }

    private var monthLength: Int {
        hijriLed
            ? HJCalendar.hijriMonthLength(year: anchorHijri.year, month: anchorHijri.month)
            : HJCalendar.civilMonthLength(year: anchorCivil.year, month: anchorCivil.month)
    }

    private var firstOfMonthJDN: Int {
        hijriLed
            ? store.jdn(forHijri: HJHijriDate(year: anchorHijri.year, month: anchorHijri.month, day: 1))
            : HJCalendar.jdn(fromCivil: HJCivilDate(year: anchorCivil.year, month: anchorCivil.month, day: 1))
    }

    private var monthTitle: String {
        hijriLed ? format.hijriMonthYear(anchorHijri) : format.civilMonthYear(anchorCivil)
    }

    private var monthSubtitle: String {
        let first = firstOfMonthJDN
        let last = first + max(0, monthLength - 1)
        if hijriLed {
            let a = HJCalendar.civil(fromJDN: first)
            let b = HJCalendar.civil(fromJDN: last)
            if a.month == b.month && a.year == b.year {
                return "\(HJNames.civilMonth(a.month)) \(a.year)"
            }
            if a.year == b.year {
                return "\(HJNames.civilMonth(a.month)) \u{2013} \(HJNames.civilMonth(b.month)) \(b.year)"
            }
            return "\(HJNames.civilMonth(a.month)) \(a.year) \u{2013} \(HJNames.civilMonth(b.month)) \(b.year)"
        } else {
            let a = store.hijri(forJDN: first)
            let b = store.hijri(forJDN: last)
            if a.month == b.month && a.year == b.year {
                return "\(format.hijriMonthName(a.month)) \(a.year) AH"
            }
            if a.year == b.year {
                return "\(format.hijriMonthName(a.month)) \u{2013} \(format.hijriMonthName(b.month)) \(b.year) AH"
            }
            return "\(format.hijriMonthName(a.month)) \(a.year) \u{2013} \(format.hijriMonthName(b.month)) \(b.year) AH"
        }
    }

    private var currentDisplayYear: Int {
        hijriLed ? anchorHijri.year : anchorCivil.year
    }

    // MARK: Navigator

    private var navigatorCard: some View {
        HJCard(padding: 10) {
            HStack(spacing: 4) {
                navButton(direction: 1, double: true) { shiftYear(-1) }
                navButton(direction: 1, double: false) { shiftMonth(-1) }

                VStack(spacing: 1) {
                    Text(monthTitle)
                        .font(HJTheme.display(16))
                        .foregroundColor(HJTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text(hijriLed ? "Hijri month" : "Gregorian month")
                        .font(HJTheme.body(10))
                        .foregroundColor(HJTheme.inkFaint)
                }
                .frame(maxWidth: .infinity)

                navButton(direction: 0, double: false) { shiftMonth(1) }
                navButton(direction: 0, double: true) { shiftYear(1) }
            }

            HStack(spacing: 8) {
                Button(action: { goToToday() }) {
                    Text("Back to today")
                        .font(HJTheme.body(12, .medium))
                        .foregroundColor(anchorIsThisMonth ? HJTheme.inkFaint : HJTheme.gold)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 11)
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(anchorIsThisMonth ? HJTheme.cardAlt : HJTheme.goldWash))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    yearDraft = currentDisplayYear
                    showYearJump.toggle()
                }) {
                    HStack(spacing: 5) {
                        Text(showYearJump ? "Close year jump" : "Jump to year")
                            .font(HJTheme.body(12, .medium))
                            .foregroundColor(HJTheme.indigo)
                        HJGlyph(shape: HJChevronShape(direction: showYearJump ? 2 : 3),
                                size: 9, color: HJTheme.indigo, lineWidth: 1.7)
                    }
                    .padding(.vertical, 7)
                    .padding(.horizontal, 11)
                    .background(RoundedRectangle(cornerRadius: 8).fill(HJTheme.indigoSoft.opacity(0.55)))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                Spacer(minLength: 0)
            }

            if showYearJump {
                yearJumpPanel
            }
        }
    }

    private var anchorIsThisMonth: Bool {
        if hijriLed {
            let t = store.hijri(forJDN: todayJDN)
            return t.year == anchorHijri.year && t.month == anchorHijri.month
        }
        let t = HJCalendar.civil(fromJDN: todayJDN)
        return t.year == anchorCivil.year && t.month == anchorCivil.month
    }

    private var yearJumpPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HJDivider()
            HStack(spacing: 6) {
                yearStep("\u{2212}10") { yearDraft = clampDraft(yearDraft - 10) }
                yearStep("\u{2212}1") { yearDraft = clampDraft(yearDraft - 1) }
                Text("\(yearDraft)")
                    .font(HJTheme.figure(17, .semibold))
                    .foregroundColor(HJTheme.ink)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                yearStep("+1") { yearDraft = clampDraft(yearDraft + 1) }
                yearStep("+10") { yearDraft = clampDraft(yearDraft + 10) }
            }
            HStack(spacing: 8) {
                HJPrimaryButton(label: "Go to \(yearDraft) \(hijriLed ? "AH" : "CE")",
                                tint: HJTheme.ink) {
                    jumpToYear(yearDraft)
                    showYearJump = false
                }
            }
            Text(hijriLed
                 ? "Hijri years \(HJCalendar.minHijriYear) to \(HJCalendar.maxHijriYear) are supported."
                 : "Gregorian years \(gregorianFloor) to \(gregorianCeiling) are supported.")
                .font(HJTheme.body(10.5))
                .foregroundColor(HJTheme.inkFaint)
        }
    }

    private var gregorianFloor: Int { HJCalendar.civil(fromJDN: HJCalendarView.minAnchor).year + 1 }
    private var gregorianCeiling: Int { HJCalendar.civil(fromJDN: HJCalendarView.maxAnchor).year - 1 }

    private func clampDraft(_ value: Int) -> Int {
        hijriLed
            ? max(HJCalendar.minHijriYear, min(HJCalendar.maxHijriYear, value))
            : max(gregorianFloor, min(gregorianCeiling, value))
    }

    private func yearStep(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(HJTheme.body(12, .semibold))
                .foregroundColor(HJTheme.ink)
                .frame(width: 44, height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(HJTheme.cardAlt))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(HJTheme.rule, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func navButton(direction: Int, double: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if double {
                    HJGlyph(shape: HJDoubleChevronShape(direction: direction), size: 15,
                            color: HJTheme.inkSoft, lineWidth: 1.7)
                } else {
                    HJGlyph(shape: HJChevronShape(direction: direction), size: 13,
                            color: HJTheme.ink, lineWidth: 2)
                }
            }
            .frame(width: 36, height: 36)
            .background(RoundedRectangle(cornerRadius: 9).fill(HJTheme.cardAlt))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: Grid

    private var weekdayColumns: [Int] {
        (0..<7).map { HJCalendar.floorMod(store.firstWeekdayIndex + $0, 7) }
    }

    private var cells: [HJDayCellData?] {
        let first = firstOfMonthJDN
        let leading = HJCalendar.floorMod(HJCalendar.weekdayIndex(jdn: first) - store.firstWeekdayIndex, 7)
        var out: [HJDayCellData?] = Array(repeating: nil, count: leading)
        guard monthLength > 0 else { return out }
        for offset in 0..<monthLength {
            let jdn = first + offset
            let hijri = store.hijri(forJDN: jdn)
            let civil = HJCalendar.civil(fromJDN: jdn)
            let primary = hijriLed ? "\(hijri.day)" : "\(civil.day)"
            let otherIsMonthStart = hijriLed ? (civil.day == 1) : (hijri.day == 1)
            let secondary: String
            if hijriLed {
                secondary = otherIsMonthStart
                    ? "1 " + HJNames.civilMonthShort(civil.month)
                    : "\(civil.day)"
            } else {
                secondary = otherIsMonthStart
                    ? "1 " + HJNames.hijriMonthShort(hijri.month)
                    : "\(hijri.day)"
            }
            let observance = !HJObservances.marking(hijri).isEmpty
            let personal = store.personalDates.contains { entry in
                let resolved = store.resolvedAnchor(entry.anchor, inYear: hijri.year)
                return resolved.month == hijri.month && resolved.day == hijri.day
            }
            let fasting = HJFasting.status(forJDN: jdn, store: store)
            out.append(HJDayCellData(jdn: jdn,
                                     primary: primary,
                                     secondary: secondary,
                                     secondaryIsMonthStart: otherIsMonthStart,
                                     isToday: jdn == todayJDN,
                                     hasObservance: observance,
                                     hasPersonal: personal,
                                     fastKind: fasting.kind.rawValue,
                                     isFriday: HJCalendar.weekdayIndex(jdn: jdn) == 5))
        }
        // Pad the final row so the grid keeps a rectangular shape.
        while out.count % 7 != 0 { out.append(nil) }
        return out
    }

    private var cellHeight: CGFloat { HJLayout.isNarrow ? 48 : 54 }

    private var gridCard: some View {
        HJCard(padding: 8) {
            HStack(spacing: 2) {
                ForEach(weekdayColumns, id: \.self) { index in
                    Text(format.weekdayShortName(index))
                        .font(HJTheme.body(10, .semibold))
                        .foregroundColor(index == 5 ? HJTheme.gold : HJTheme.inkFaint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 2)

            Rectangle().fill(HJTheme.ruleSoft).frame(height: 1)

            VStack(spacing: 2) {
                ForEach(rows.indices, id: \.self) { rowIndex in
                    HStack(spacing: 2) {
                        ForEach(rows[rowIndex].indices, id: \.self) { columnIndex in
                            if let cell = rows[rowIndex][columnIndex] {
                                dayCell(cell)
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: cellHeight)
                            }
                        }
                    }
                }
            }
            .padding(.top, 2)
            // Horizontal swipe changes the month. The check keeps a vertical drag with the
            // scroll view, where it belongs.
            .gesture(
                DragGesture(minimumDistance: 22)
                    .onEnded { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        guard abs(dx) > 44, abs(dx) > abs(dy) * 1.5 else { return }
                        shiftMonth(dx < 0 ? 1 : -1)
                    }
            )
        }
    }

    private var rows: [[HJDayCellData?]] {
        let flat = cells
        var out: [[HJDayCellData?]] = []
        var index = 0
        while index < flat.count {
            let end = min(index + 7, flat.count)
            out.append(Array(flat[index..<end]))
            index = end
        }
        return out
    }

    private func dayCell(_ cell: HJDayCellData) -> some View {
        Button(action: { selected = HJSelectedDay(id: cell.jdn) }) {
            VStack(spacing: 0) {
                Text(cell.primary)
                    .font(HJTheme.figure(cell.isToday ? 17 : 16, cell.isToday ? .bold : .medium))
                    .foregroundColor(cell.isToday ? HJTheme.gold : HJTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(cell.secondary)
                    .font(HJTheme.body(cell.secondaryIsMonthStart ? 8.5 : 9.5,
                                       cell.secondaryIsMonthStart ? .semibold : .regular))
                    .foregroundColor(cell.secondaryIsMonthStart ? HJTheme.indigo : HJTheme.inkFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.top, 1)
                HStack(spacing: 2) {
                    if cell.hasObservance {
                        HJStarShape(points: 8, innerRatio: 0.42)
                            .fill(HJTheme.gold)
                            .frame(width: 6, height: 6)
                    }
                    if cell.fastKind == HJFastKind.notPermitted.rawValue {
                        HJLozengeShape().fill(HJTheme.clay).frame(width: 5, height: 5)
                    } else if cell.fastKind == HJFastKind.obligatory.rawValue
                                || cell.fastKind == HJFastKind.voluntary.rawValue {
                        HJLozengeShape().fill(HJTheme.verdant).frame(width: 5, height: 5)
                    }
                    if cell.hasPersonal {
                        Circle().fill(HJTheme.indigo).frame(width: 5, height: 5)
                    }
                }
                .frame(height: 7)
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: cellHeight)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(cell.isToday ? HJTheme.goldWash
                          : (cell.isFriday ? HJTheme.cardAlt.opacity(0.7) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(cell.isToday ? HJTheme.gold : Color.clear, lineWidth: 1.4)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: Legend

    private var legendCard: some View {
        HJCard {
            HJCaption(text: "Reading the grid")
            VStack(alignment: .leading, spacing: 7) {
                legendRow(AnyView(Text("12").font(HJTheme.figure(14, .semibold)).foregroundColor(HJTheme.ink)),
                          hijriLed ? "Large number: the Hijri day" : "Large number: the Gregorian day")
                legendRow(AnyView(Text("27").font(HJTheme.body(10)).foregroundColor(HJTheme.inkFaint)),
                          hijriLed ? "Small number: the Gregorian day" : "Small number: the Hijri day")
                legendRow(AnyView(Text("1 Ram").font(HJTheme.body(9, .semibold)).foregroundColor(HJTheme.indigo)),
                          "The second calendar's month turning over")
                legendRow(AnyView(HJStarShape(points: 8, innerRatio: 0.42).fill(HJTheme.gold).frame(width: 9, height: 9)),
                          "An observance falls on this day")
                legendRow(AnyView(HJLozengeShape().fill(HJTheme.verdant).frame(width: 8, height: 8)),
                          "A fasting day")
                legendRow(AnyView(HJLozengeShape().fill(HJTheme.clay).frame(width: 8, height: 8)),
                          "A day fasting is not permitted")
                legendRow(AnyView(Circle().fill(HJTheme.indigo).frame(width: 8, height: 8)),
                          "One of your saved dates")
            }
            Text("Tap any day for the full reading. Swipe the grid sideways to change month.")
                .font(HJTheme.body(11))
                .foregroundColor(HJTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func legendRow(_ mark: AnyView, _ text: String) -> some View {
        HStack(alignment: .center, spacing: 9) {
            mark.frame(width: 34, alignment: .center)
            Text(text)
                .font(HJTheme.body(11.5))
                .foregroundColor(HJTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: Movement

    private func setAnchor(_ jdn: Int) {
        anchorJDN = max(HJCalendarView.minAnchor, min(HJCalendarView.maxAnchor, jdn))
    }

    private func shiftMonth(_ delta: Int) {
        if hijriLed {
            var year = anchorHijri.year
            var month = anchorHijri.month + delta
            while month > 12 { month -= 12; year += 1 }
            while month < 1 { month += 12; year -= 1 }
            year = max(HJCalendar.minHijriYear, min(HJCalendar.maxHijriYear, year))
            setAnchor(store.jdn(forHijri: HJHijriDate(year: year, month: month, day: 1)))
        } else {
            var year = anchorCivil.year
            var month = anchorCivil.month + delta
            while month > 12 { month -= 12; year += 1 }
            while month < 1 { month += 12; year -= 1 }
            setAnchor(HJCalendar.jdn(fromCivil: HJCivilDate(year: year, month: month, day: 1)))
        }
    }

    private func shiftYear(_ delta: Int) {
        if hijriLed {
            let year = max(HJCalendar.minHijriYear,
                           min(HJCalendar.maxHijriYear, anchorHijri.year + delta))
            setAnchor(store.jdn(forHijri: HJHijriDate(year: year, month: anchorHijri.month, day: 1)))
        } else {
            let year = anchorCivil.year + delta
            setAnchor(HJCalendar.jdn(fromCivil: HJCivilDate(year: year, month: anchorCivil.month, day: 1)))
        }
    }

    private func jumpToYear(_ year: Int) {
        let bounded = clampDraft(year)
        if hijriLed {
            setAnchor(store.jdn(forHijri: HJHijriDate(year: bounded, month: anchorHijri.month, day: 1)))
        } else {
            setAnchor(HJCalendar.jdn(fromCivil: HJCivilDate(year: bounded, month: anchorCivil.month, day: 1)))
        }
    }

    private func goToToday() {
        setAnchor(todayJDN)
    }
}
