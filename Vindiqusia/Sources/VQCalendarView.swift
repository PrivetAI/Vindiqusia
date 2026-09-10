import SwiftUI

/// One day of the grid. Everything it needs arrives as value types, so a change to any of
/// them actually redraws the cell.
struct VQDayCellData: Equatable {
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

private struct VQSelectedDay: Identifiable {
    let id: Int
    var jdn: Int { id }
}

struct VQCalendarView: View {

    @EnvironmentObject private var store: VQStore

    /// 0 = the grid follows Hijri months, 1 = it follows Gregorian months.
    @State private var gridMode: Int = -1
    @State private var anchorJDN: Int = VQCalendar.todayJDN()
    @State private var selected: VQSelectedDay? = nil
    @State private var showYearJump = false
    @State private var yearDraft: Int = 0

    private var format: VQFormatter { store.formatter }
    private var todayJDN: Int { store.todayJDN }
    private var hijriLed: Bool { resolvedMode == 0 }
    private var resolvedMode: Int { gridMode < 0 ? store.primaryCalendar : gridMode }

    private static let minAnchor = VQCalendar.minJDN + 40
    private static let maxAnchor = VQCalendar.maxJDN - 40

    var body: some View {
        VQScreen(title: "Calendar", subtitle: monthSubtitle) {
            VQSegmented(options: ["Hijri months", "Gregorian months"],
                        selection: Binding(get: { resolvedMode },
                                           set: { gridMode = $0 }))

            navigatorCard
            gridCard
            legendCard
            VQEstimateNote()
                .padding(.horizontal, 2)
        }
        .sheet(item: $selected) { day in
            VQDayDetailView(jdn: day.jdn, onClose: { selected = nil })
                .environmentObject(store)
        }
        .onAppear {
            if yearDraft == 0 { yearDraft = currentDisplayYear }
        }
    }

    // MARK: Month frame

    private var anchorHijri: VQHijriDate { store.hijri(forJDN: anchorJDN) }
    private var anchorCivil: VQCivilDate { VQCalendar.civil(fromJDN: anchorJDN) }

    private var monthLength: Int {
        hijriLed
            ? VQCalendar.hijriMonthLength(year: anchorHijri.year, month: anchorHijri.month)
            : VQCalendar.civilMonthLength(year: anchorCivil.year, month: anchorCivil.month)
    }

    private var firstOfMonthJDN: Int {
        hijriLed
            ? store.jdn(forHijri: VQHijriDate(year: anchorHijri.year, month: anchorHijri.month, day: 1))
            : VQCalendar.jdn(fromCivil: VQCivilDate(year: anchorCivil.year, month: anchorCivil.month, day: 1))
    }

    private var monthTitle: String {
        hijriLed ? format.hijriMonthYear(anchorHijri) : format.civilMonthYear(anchorCivil)
    }

    private var monthSubtitle: String {
        let first = firstOfMonthJDN
        let last = first + max(0, monthLength - 1)
        if hijriLed {
            let a = VQCalendar.civil(fromJDN: first)
            let b = VQCalendar.civil(fromJDN: last)
            if a.month == b.month && a.year == b.year {
                return "\(VQNames.civilMonth(a.month)) \(a.year)"
            }
            if a.year == b.year {
                return "\(VQNames.civilMonth(a.month)) \u{2013} \(VQNames.civilMonth(b.month)) \(b.year)"
            }
            return "\(VQNames.civilMonth(a.month)) \(a.year) \u{2013} \(VQNames.civilMonth(b.month)) \(b.year)"
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
        VQCard(padding: 10) {
            HStack(spacing: 4) {
                navButton(direction: 1, double: true) { shiftYear(-1) }
                navButton(direction: 1, double: false) { shiftMonth(-1) }

                VStack(spacing: 1) {
                    Text(monthTitle)
                        .font(VQTheme.display(16))
                        .foregroundColor(VQTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text(hijriLed ? "Hijri month" : "Gregorian month")
                        .font(VQTheme.body(10))
                        .foregroundColor(VQTheme.inkFaint)
                }
                .frame(maxWidth: .infinity)

                navButton(direction: 0, double: false) { shiftMonth(1) }
                navButton(direction: 0, double: true) { shiftYear(1) }
            }

            HStack(spacing: 8) {
                Button(action: { goToToday() }) {
                    Text("Back to today")
                        .font(VQTheme.body(12, .medium))
                        .foregroundColor(anchorIsThisMonth ? VQTheme.inkFaint : VQTheme.gold)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 11)
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(anchorIsThisMonth ? VQTheme.cardAlt : VQTheme.goldWash))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    yearDraft = currentDisplayYear
                    showYearJump.toggle()
                }) {
                    HStack(spacing: 5) {
                        Text(showYearJump ? "Close year jump" : "Jump to year")
                            .font(VQTheme.body(12, .medium))
                            .foregroundColor(VQTheme.indigo)
                        VQGlyph(shape: VQChevronShape(direction: showYearJump ? 2 : 3),
                                size: 9, color: VQTheme.indigo, lineWidth: 1.7)
                    }
                    .padding(.vertical, 7)
                    .padding(.horizontal, 11)
                    .background(RoundedRectangle(cornerRadius: 8).fill(VQTheme.indigoSoft.opacity(0.55)))
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
        let t = VQCalendar.civil(fromJDN: todayJDN)
        return t.year == anchorCivil.year && t.month == anchorCivil.month
    }

    private var yearJumpPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            VQDivider()
            HStack(spacing: 6) {
                yearStep("\u{2212}10") { yearDraft = clampDraft(yearDraft - 10) }
                yearStep("\u{2212}1") { yearDraft = clampDraft(yearDraft - 1) }
                Text(verbatim: "\(yearDraft)")
                    .font(VQTheme.figure(17, .semibold))
                    .foregroundColor(VQTheme.ink)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                yearStep("+1") { yearDraft = clampDraft(yearDraft + 1) }
                yearStep("+10") { yearDraft = clampDraft(yearDraft + 10) }
            }
            HStack(spacing: 8) {
                VQPrimaryButton(label: "Go to \(yearDraft) \(hijriLed ? "AH" : "CE")",
                                tint: VQTheme.ink) {
                    jumpToYear(yearDraft)
                    showYearJump = false
                }
            }
            Text(verbatim: hijriLed
                 ? "Hijri years \(VQCalendar.minHijriYear) to \(VQCalendar.maxHijriYear) are supported."
                 : "Gregorian years \(gregorianFloor) to \(gregorianCeiling) are supported.")
                .font(VQTheme.body(10.5))
                .foregroundColor(VQTheme.inkFaint)
        }
    }

    private var gregorianFloor: Int { VQCalendar.civil(fromJDN: VQCalendarView.minAnchor).year + 1 }
    private var gregorianCeiling: Int { VQCalendar.civil(fromJDN: VQCalendarView.maxAnchor).year - 1 }

    private func clampDraft(_ value: Int) -> Int {
        hijriLed
            ? max(VQCalendar.minHijriYear, min(VQCalendar.maxHijriYear, value))
            : max(gregorianFloor, min(gregorianCeiling, value))
    }

    private func yearStep(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(VQTheme.body(12, .semibold))
                .foregroundColor(VQTheme.ink)
                .frame(width: 44, height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(VQTheme.cardAlt))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(VQTheme.rule, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func navButton(direction: Int, double: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if double {
                    VQGlyph(shape: VQDoubleChevronShape(direction: direction), size: 15,
                            color: VQTheme.inkSoft, lineWidth: 1.7)
                } else {
                    VQGlyph(shape: VQChevronShape(direction: direction), size: 13,
                            color: VQTheme.ink, lineWidth: 2)
                }
            }
            .frame(width: 36, height: 36)
            .background(RoundedRectangle(cornerRadius: 9).fill(VQTheme.cardAlt))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: Grid

    private var weekdayColumns: [Int] {
        (0..<7).map { VQCalendar.floorMod(store.firstWeekdayIndex + $0, 7) }
    }

    private var cells: [VQDayCellData?] {
        let first = firstOfMonthJDN
        let leading = VQCalendar.floorMod(VQCalendar.weekdayIndex(jdn: first) - store.firstWeekdayIndex, 7)
        var out: [VQDayCellData?] = Array(repeating: nil, count: leading)
        guard monthLength > 0 else { return out }
        for offset in 0..<monthLength {
            let jdn = first + offset
            let hijri = store.hijri(forJDN: jdn)
            let civil = VQCalendar.civil(fromJDN: jdn)
            let primary = hijriLed ? "\(hijri.day)" : "\(civil.day)"
            let otherIsMonthStart = hijriLed ? (civil.day == 1) : (hijri.day == 1)
            let secondary: String
            if hijriLed {
                secondary = otherIsMonthStart
                    ? "1 " + VQNames.civilMonthShort(civil.month)
                    : "\(civil.day)"
            } else {
                secondary = otherIsMonthStart
                    ? "1 " + VQNames.hijriMonthShort(hijri.month)
                    : "\(hijri.day)"
            }
            let observance = !VQObservances.marking(hijri).isEmpty
            let personal = store.personalDates.contains { entry in
                let resolved = store.resolvedAnchor(entry.anchor, inYear: hijri.year)
                return resolved.month == hijri.month && resolved.day == hijri.day
            }
            let fasting = VQFasting.status(forJDN: jdn, store: store)
            out.append(VQDayCellData(jdn: jdn,
                                     primary: primary,
                                     secondary: secondary,
                                     secondaryIsMonthStart: otherIsMonthStart,
                                     isToday: jdn == todayJDN,
                                     hasObservance: observance,
                                     hasPersonal: personal,
                                     fastKind: fasting.kind.rawValue,
                                     isFriday: VQCalendar.weekdayIndex(jdn: jdn) == 5))
        }
        // Pad the final row so the grid keeps a rectangular shape.
        while out.count % 7 != 0 { out.append(nil) }
        return out
    }

    private var cellHeight: CGFloat { VQLayout.isNarrow ? 48 : 54 }

    private var gridCard: some View {
        VQCard(padding: 8) {
            HStack(spacing: 2) {
                ForEach(weekdayColumns, id: \.self) { index in
                    Text(format.weekdayShortName(index))
                        .font(VQTheme.body(10, .semibold))
                        .foregroundColor(index == 5 ? VQTheme.gold : VQTheme.inkFaint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 2)

            Rectangle().fill(VQTheme.ruleSoft).frame(height: 1)

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

    private var rows: [[VQDayCellData?]] {
        let flat = cells
        var out: [[VQDayCellData?]] = []
        var index = 0
        while index < flat.count {
            let end = min(index + 7, flat.count)
            out.append(Array(flat[index..<end]))
            index = end
        }
        return out
    }

    private func dayCell(_ cell: VQDayCellData) -> some View {
        Button(action: { selected = VQSelectedDay(id: cell.jdn) }) {
            VStack(spacing: 0) {
                Text(cell.primary)
                    .font(VQTheme.figure(cell.isToday ? 17 : 16, cell.isToday ? .bold : .medium))
                    .foregroundColor(cell.isToday ? VQTheme.gold : VQTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(cell.secondary)
                    .font(VQTheme.body(cell.secondaryIsMonthStart ? 8.5 : 9.5,
                                       cell.secondaryIsMonthStart ? .semibold : .regular))
                    .foregroundColor(cell.secondaryIsMonthStart ? VQTheme.indigo : VQTheme.inkFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.top, 1)
                HStack(spacing: 2) {
                    if cell.hasObservance {
                        VQStarShape(points: 8, innerRatio: 0.42)
                            .fill(VQTheme.gold)
                            .frame(width: 6, height: 6)
                    }
                    if cell.fastKind == VQFastKind.notPermitted.rawValue {
                        VQLozengeShape().fill(VQTheme.clay).frame(width: 5, height: 5)
                    } else if cell.fastKind == VQFastKind.obligatory.rawValue
                                || cell.fastKind == VQFastKind.voluntary.rawValue {
                        VQLozengeShape().fill(VQTheme.verdant).frame(width: 5, height: 5)
                    }
                    if cell.hasPersonal {
                        Circle().fill(VQTheme.indigo).frame(width: 5, height: 5)
                    }
                }
                .frame(height: 7)
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: cellHeight)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(cell.isToday ? VQTheme.goldWash
                          : (cell.isFriday ? VQTheme.cardAlt.opacity(0.7) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(cell.isToday ? VQTheme.gold : Color.clear, lineWidth: 1.4)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: Legend

    private var legendCard: some View {
        VQCard {
            VQCaption(text: "Reading the grid")
            VStack(alignment: .leading, spacing: 7) {
                legendRow(AnyView(Text("12").font(VQTheme.figure(14, .semibold)).foregroundColor(VQTheme.ink)),
                          hijriLed ? "Large number: the Hijri day" : "Large number: the Gregorian day")
                legendRow(AnyView(Text("27").font(VQTheme.body(10)).foregroundColor(VQTheme.inkFaint)),
                          hijriLed ? "Small number: the Gregorian day" : "Small number: the Hijri day")
                legendRow(AnyView(Text("1 Ram").font(VQTheme.body(9, .semibold)).foregroundColor(VQTheme.indigo)),
                          "The second calendar's month turning over")
                legendRow(AnyView(VQStarShape(points: 8, innerRatio: 0.42).fill(VQTheme.gold).frame(width: 9, height: 9)),
                          "An observance falls on this day")
                legendRow(AnyView(VQLozengeShape().fill(VQTheme.verdant).frame(width: 8, height: 8)),
                          "A fasting day")
                legendRow(AnyView(VQLozengeShape().fill(VQTheme.clay).frame(width: 8, height: 8)),
                          "A day fasting is not permitted")
                legendRow(AnyView(Circle().fill(VQTheme.indigo).frame(width: 8, height: 8)),
                          "One of your saved dates")
            }
            Text("Tap any day for the full reading. Swipe the grid sideways to change month.")
                .font(VQTheme.body(11))
                .foregroundColor(VQTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func legendRow(_ mark: AnyView, _ text: String) -> some View {
        HStack(alignment: .center, spacing: 9) {
            mark.frame(width: 34, alignment: .center)
            Text(text)
                .font(VQTheme.body(11.5))
                .foregroundColor(VQTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: Movement

    private func setAnchor(_ jdn: Int) {
        anchorJDN = max(VQCalendarView.minAnchor, min(VQCalendarView.maxAnchor, jdn))
    }

    private func shiftMonth(_ delta: Int) {
        if hijriLed {
            var year = anchorHijri.year
            var month = anchorHijri.month + delta
            while month > 12 { month -= 12; year += 1 }
            while month < 1 { month += 12; year -= 1 }
            year = max(VQCalendar.minHijriYear, min(VQCalendar.maxHijriYear, year))
            setAnchor(store.jdn(forHijri: VQHijriDate(year: year, month: month, day: 1)))
        } else {
            var year = anchorCivil.year
            var month = anchorCivil.month + delta
            while month > 12 { month -= 12; year += 1 }
            while month < 1 { month += 12; year -= 1 }
            setAnchor(VQCalendar.jdn(fromCivil: VQCivilDate(year: year, month: month, day: 1)))
        }
    }

    private func shiftYear(_ delta: Int) {
        if hijriLed {
            let year = max(VQCalendar.minHijriYear,
                           min(VQCalendar.maxHijriYear, anchorHijri.year + delta))
            setAnchor(store.jdn(forHijri: VQHijriDate(year: year, month: anchorHijri.month, day: 1)))
        } else {
            let year = anchorCivil.year + delta
            setAnchor(VQCalendar.jdn(fromCivil: VQCivilDate(year: year, month: anchorCivil.month, day: 1)))
        }
    }

    private func jumpToYear(_ year: Int) {
        let bounded = clampDraft(year)
        if hijriLed {
            setAnchor(store.jdn(forHijri: VQHijriDate(year: bounded, month: anchorHijri.month, day: 1)))
        } else {
            setAnchor(VQCalendar.jdn(fromCivil: VQCivilDate(year: bounded, month: anchorCivil.month, day: 1)))
        }
    }

    private func goToToday() {
        setAnchor(todayJDN)
    }
}
