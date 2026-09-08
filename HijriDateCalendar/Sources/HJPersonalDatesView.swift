import SwiftUI

/// What the editor sheet is working on. Identifiable so one `.sheet(item:)` covers both
/// adding and editing — iOS 15 honours only the last `.sheet` on a view, so the screen
/// has exactly one.
struct HJDateDraft: Identifiable {
    let id: String
    var isNew: Bool
    var title: String
    var note: String
    var anchor: HJHijriDate
    var kind: Int
}

struct HJPersonalDatesView: View {

    @EnvironmentObject private var store: HJStore
    @Environment(\.presentationMode) private var presentation

    @State private var draft: HJDateDraft? = nil
    @State private var pendingDelete: String? = nil

    private var format: HJFormatter { store.formatter }
    private var todayJDN: Int { store.todayJDN }

    private var rows: [(entry: HJPersonalDate, jdn: Int)] {
        store.personalDates
            .map { (entry: $0, jdn: store.nextOccurrenceJDN(of: $0, fromJDN: todayJDN)) }
            .sorted { $0.jdn < $1.jdn }
    }

    var body: some View {
        HJDetailScreen(title: "My dates",
                       subtitle: "Anchored to the Hijri calendar, so each one drifts through the Gregorian year",
                       onBack: { presentation.wrappedValue.dismiss() }) {
            addButton

            if store.personalDates.isEmpty {
                HJCard {
                    HJEmptyState(headline: "Nothing saved yet",
                                 message: "Save an anniversary, a birth or any other date you want to keep by the Hijri calendar. Each one shows its next Gregorian occurrence and a countdown.")
                }
            } else {
                ForEach(rows.indices, id: \.self) { index in
                    entryCard(rows[index].entry, occurrence: rows[index].jdn)
                }
            }

            HJCard(tint: HJTheme.cardAlt) {
                HJCaption(text: "How these work")
                Text("A date saved here is stored as a Hijri day and month. Because a Hijri year runs about eleven days shorter than a solar one, the Gregorian day it lands on moves earlier each year, and works its way round the whole calendar in roughly thirty-three years.")
                    .font(HJTheme.body(12))
                    .foregroundColor(HJTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text("An anchor on the thirtieth of Dhu al-Hijjah has no home in an ordinary year. In those years it is shown on the twenty-ninth rather than rolling into Muharram.")
                    .font(HJTheme.body(12))
                    .foregroundColor(HJTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HJEstimateNote()
                .padding(.horizontal, 2)
        }
        .sheet(item: $draft) { current in
            HJDateEditorView(draft: current,
                             markedSpelling: store.markedSpelling,
                             adjustment: store.adjustment,
                             onCancel: { draft = nil },
                             onSave: { saved in
                                 commit(saved)
                                 draft = nil
                             })
        }
    }

    private var addButton: some View {
        Button(action: {
            let today = store.hijri(forJDN: todayJDN)
            draft = HJDateDraft(id: UUID().uuidString,
                                isNew: true,
                                title: "",
                                note: "",
                                anchor: today,
                                kind: 0)
        }) {
            HStack(spacing: 9) {
                HJGlyph(shape: HJPlusShape(), size: 14, color: HJTheme.card, lineWidth: 2)
                Text("Add a date")
                    .font(HJTheme.body(14, .semibold))
                    .foregroundColor(HJTheme.card)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 11).fill(HJTheme.ink))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func entryCard(_ entry: HJPersonalDate, occurrence: Int) -> some View {
        let delta = occurrence - todayJDN
        let occurrenceHijri = store.hijri(forJDN: occurrence)
        let years = max(0, occurrenceHijri.year - entry.originYear)
        let confirming = pendingDelete == entry.id
        return HJCard {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.title)
                        .font(HJTheme.body(15, .semibold))
                        .foregroundColor(HJTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        HJChip(text: entry.kindName, tint: HJTheme.indigo)
                        HJChip(text: format.hijriDayMonth(entry.anchor), tint: HJTheme.gold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(delta == 0 ? "Today" : "\(delta)")
                        .font(HJTheme.figure(delta == 0 ? 13 : 19, .semibold))
                        .foregroundColor(delta == 0 ? HJTheme.gold : HJTheme.ink)
                    if delta != 0 {
                        Text(delta == 1 ? "day" : "days")
                            .font(HJTheme.body(9.5))
                            .foregroundColor(HJTheme.inkFaint)
                    }
                }
            }

            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(HJTheme.body(12))
                    .foregroundColor(HJTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HJDivider()
            HJFactRow(key: "Next occurrence",
                      value: format.civilLong(HJCalendar.civil(fromJDN: occurrence)))
            HJFactRow(key: "That is",
                      value: format.hijriLong(occurrenceHijri))
            HJFactRow(key: entry.kind == 1 ? "Turning" : "Marking",
                      value: entry.kind == 1
                        ? "\(years) Hijri year\(years == 1 ? "" : "s")"
                        : (years == 0 ? "The first year" : "\(HJFormatter.ordinal(years)) Hijri anniversary"))
            HJFactRow(key: "First recorded", value: "\(entry.originYear) AH")

            HJDivider()

            if confirming {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Delete \"\(entry.title)\"? This cannot be undone.")
                        .font(HJTheme.body(12, .medium))
                        .foregroundColor(HJTheme.clay)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        Button(action: {
                            store.deletePersonalDate(id: entry.id)
                            pendingDelete = nil
                        }) {
                            Text("Delete")
                                .font(HJTheme.body(12.5, .semibold))
                                .foregroundColor(HJTheme.card)
                                .padding(.vertical, 9)
                                .padding(.horizontal, 16)
                                .background(RoundedRectangle(cornerRadius: 9).fill(HJTheme.clay))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        Button(action: { pendingDelete = nil }) {
                            Text("Keep")
                                .font(HJTheme.body(12.5, .medium))
                                .foregroundColor(HJTheme.ink)
                                .padding(.vertical, 9)
                                .padding(.horizontal, 16)
                                .background(RoundedRectangle(cornerRadius: 9).fill(HJTheme.cardAlt))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer(minLength: 0)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Button(action: {
                        draft = HJDateDraft(id: entry.id,
                                            isNew: false,
                                            title: entry.title,
                                            note: entry.note,
                                            anchor: HJHijriDate(year: entry.originYear,
                                                                month: entry.anchor.month,
                                                                day: entry.anchor.day),
                                            kind: entry.kind)
                    }) {
                        Text("Edit")
                            .font(HJTheme.body(12.5, .medium))
                            .foregroundColor(HJTheme.gold)
                            .padding(.vertical, 9)
                            .padding(.horizontal, 16)
                            .background(RoundedRectangle(cornerRadius: 9).fill(HJTheme.goldWash))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { pendingDelete = entry.id }) {
                        HStack(spacing: 6) {
                            HJGlyph(shape: HJTrashShape(), size: 12, color: HJTheme.clay, lineWidth: 1.4)
                            Text("Delete")
                                .font(HJTheme.body(12.5, .medium))
                                .foregroundColor(HJTheme.clay)
                        }
                        .padding(.vertical, 9)
                        .padding(.horizontal, 14)
                        .background(RoundedRectangle(cornerRadius: 9).fill(HJTheme.claySoft.opacity(0.55)))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func commit(_ saved: HJDateDraft) {
        let cleanTitle = saved.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = HJPersonalDate(id: saved.id,
                                   title: cleanTitle.isEmpty ? "Saved date" : cleanTitle,
                                   note: saved.note.trimmingCharacters(in: .whitespacesAndNewlines),
                                   anchor: HJCalendar.clampHijri(saved.anchor),
                                   originYear: HJCalendar.clampHijri(saved.anchor).year,
                                   kind: max(0, min(HJPersonalDate.kindNames.count - 1, saved.kind)))
        if saved.isNew {
            store.addPersonalDate(entry)
        } else {
            store.updatePersonalDate(entry)
        }
        pendingDelete = nil
    }
}

// MARK: - Editor

private enum HJEditorField: Hashable {
    case title
    case note
}

struct HJDateEditorView: View {

    @State private var working: HJDateDraft
    /// Only the FIRST text field in a stack takes a tap on iOS 15 unless focus is driven
    /// explicitly. Both fields carry a tap gesture that sets this.
    @FocusState private var field: HJEditorField?

    let markedSpelling: Bool
    /// The user's global shift, so the preview line matches every other screen.
    let adjustment: Int
    var onCancel: () -> Void
    var onSave: (HJDateDraft) -> Void

    init(draft: HJDateDraft,
         markedSpelling: Bool,
         adjustment: Int,
         onCancel: @escaping () -> Void,
         onSave: @escaping (HJDateDraft) -> Void) {
        _working = State(initialValue: draft)
        self.markedSpelling = markedSpelling
        self.adjustment = adjustment
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        ZStack(alignment: .top) {
            HJTheme.paper.edgesIgnoringSafeArea(.all)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 13) {
                    header

                    HJCard {
                        HJCaption(text: "Name")
                        textBox(placeholder: "What is this date?",
                                text: $working.title,
                                which: .title)

                        HJCaption(text: "Note, if you want one")
                        textBox(placeholder: "Anything you would like to remember",
                                text: $working.note,
                                which: .note)

                        HJCaption(text: "Kind")
                        HJChoiceRow(options: HJPersonalDate.kindNames,
                                    selection: working.kind) { working.kind = $0 }
                    }

                    HJCard {
                        HJCaption(text: "The Hijri date it happened on", color: HJTheme.gold)
                        Text("The day and month are what the entry recurs on. The year is recorded so the app can count the anniversaries.")
                            .font(HJTheme.body(11.5))
                            .foregroundColor(HJTheme.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                        HJHijriDatePicker(value: $working.anchor, markedSpelling: markedSpelling)
                    }

                    HJCard(tint: HJTheme.cardAlt) {
                        HJCaption(text: "Preview")
                        Text(previewLine)
                            .font(HJTheme.body(13, .semibold))
                            .foregroundColor(HJTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(previewCivil)
                            .font(HJTheme.body(12))
                            .foregroundColor(HJTheme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 9) {
                        HJPrimaryButton(label: working.isNew ? "Save date" : "Save changes",
                                        tint: HJTheme.ink) {
                            field = nil
                            onSave(working)
                        }
                    }

                    HJEstimateNote(compact: true)
                        .padding(.horizontal, 2)
                }
                .padding(.horizontal, HJLayout.screenInset)
                .padding(.top, 16)
                .padding(.bottom, 40)
                .frame(maxWidth: HJLayout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(working.isNew ? "New date" : "Edit date")
                .font(HJTheme.display(23))
                .foregroundColor(HJTheme.ink)
            Spacer(minLength: 6)
            Button(action: { field = nil; onCancel() }) {
                HJGlyph(shape: HJCrossShape(), size: 14, color: HJTheme.inkSoft, lineWidth: 1.8)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(HJTheme.cardAlt))
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func textBox(placeholder: String, text: Binding<String>, which: HJEditorField) -> some View {
        ZStack(alignment: .leading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(HJTheme.body(13))
                    .foregroundColor(HJTheme.inkFaint.opacity(0.8))
                    .padding(.horizontal, 11)
                    .allowsHitTesting(false)
            }
            TextField("", text: text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(HJTheme.body(13))
                .foregroundColor(HJTheme.ink)
                .accentColor(HJTheme.gold)
                .disableAutocorrection(false)
                .focused($field, equals: which)
                .padding(.horizontal, 11)
                .padding(.vertical, 11)
        }
        .frame(minHeight: 42)
        .background(RoundedRectangle(cornerRadius: 9).fill(HJTheme.cardAlt))
        .overlay(RoundedRectangle(cornerRadius: 9)
            .stroke(field == which ? HJTheme.gold : HJTheme.rule, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture { field = which }
    }

    private var previewLine: String {
        let format = HJFormatter(markedSpelling: markedSpelling, arabicWeekdays: false)
        return "Recurs on \(format.hijriDayMonth(working.anchor)), first recorded in \(working.anchor.year) AH"
    }

    private var previewCivil: String {
        let jdn = HJCalendar.jdn(fromHijri: HJCalendar.clampHijri(working.anchor)) - adjustment
        let civil = HJCalendar.civil(fromJDN: jdn)
        let format = HJFormatter(markedSpelling: markedSpelling, arabicWeekdays: false)
        return "That Hijri date fell on \(format.civilLong(civil)) by the tabular calendar."
    }
}
