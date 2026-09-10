import SwiftUI

/// What the editor sheet is working on. Identifiable so one `.sheet(item:)` covers both
/// adding and editing — iOS 15 honours only the last `.sheet` on a view, so the screen
/// has exactly one.
struct VQDateDraft: Identifiable {
    let id: String
    var isNew: Bool
    var title: String
    var note: String
    var anchor: VQHijriDate
    var kind: Int
}

struct VQPersonalDatesView: View {

    @EnvironmentObject private var store: VQStore
    @Environment(\.presentationMode) private var presentation

    @State private var draft: VQDateDraft? = nil
    @State private var pendingDelete: String? = nil

    private var format: VQFormatter { store.formatter }
    private var todayJDN: Int { store.todayJDN }

    private var rows: [(entry: VQPersonalDate, jdn: Int)] {
        store.personalDates
            .map { (entry: $0, jdn: store.nextOccurrenceJDN(of: $0, fromJDN: todayJDN)) }
            .sorted { $0.jdn < $1.jdn }
    }

    var body: some View {
        VQDetailScreen(title: "My dates",
                       subtitle: "Anchored to the Hijri calendar, so each one drifts through the Gregorian year",
                       onBack: { presentation.wrappedValue.dismiss() }) {
            addButton

            if store.personalDates.isEmpty {
                VQCard {
                    VQEmptyState(headline: "Nothing saved yet",
                                 message: "Save an anniversary, a birth or any other date you want to keep by the Hijri calendar. Each one shows its next Gregorian occurrence and a countdown.")
                }
            } else {
                ForEach(rows.indices, id: \.self) { index in
                    entryCard(rows[index].entry, occurrence: rows[index].jdn)
                }
            }

            VQCard(tint: VQTheme.cardAlt) {
                VQCaption(text: "How these work")
                Text("A date saved here is stored as a Hijri day and month. Because a Hijri year runs about eleven days shorter than a solar one, the Gregorian day it lands on moves earlier each year, and works its way round the whole calendar in roughly thirty-three years.")
                    .font(VQTheme.body(12))
                    .foregroundColor(VQTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text("An anchor on the thirtieth of Dhu al-Hijjah has no home in an ordinary year. In those years it is shown on the twenty-ninth rather than rolling into Muharram.")
                    .font(VQTheme.body(12))
                    .foregroundColor(VQTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VQEstimateNote()
                .padding(.horizontal, 2)
        }
        .sheet(item: $draft) { current in
            VQDateEditorView(draft: current,
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
            draft = VQDateDraft(id: UUID().uuidString,
                                isNew: true,
                                title: "",
                                note: "",
                                anchor: today,
                                kind: 0)
        }) {
            HStack(spacing: 9) {
                VQGlyph(shape: VQPlusShape(), size: 14, color: VQTheme.card, lineWidth: 2)
                Text("Add a date")
                    .font(VQTheme.body(14, .semibold))
                    .foregroundColor(VQTheme.card)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 11).fill(VQTheme.ink))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func entryCard(_ entry: VQPersonalDate, occurrence: Int) -> some View {
        let delta = occurrence - todayJDN
        let occurrenceHijri = store.hijri(forJDN: occurrence)
        let years = max(0, occurrenceHijri.year - entry.originYear)
        let confirming = pendingDelete == entry.id
        return VQCard {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.title)
                        .font(VQTheme.body(15, .semibold))
                        .foregroundColor(VQTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        VQChip(text: entry.kindName, tint: VQTheme.indigo)
                        VQChip(text: format.hijriDayMonth(entry.anchor), tint: VQTheme.gold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(delta == 0 ? "Today" : "\(delta)")
                        .font(VQTheme.figure(delta == 0 ? 13 : 19, .semibold))
                        .foregroundColor(delta == 0 ? VQTheme.gold : VQTheme.ink)
                    if delta != 0 {
                        Text(delta == 1 ? "day" : "days")
                            .font(VQTheme.body(9.5))
                            .foregroundColor(VQTheme.inkFaint)
                    }
                }
            }

            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(VQTheme.body(12))
                    .foregroundColor(VQTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VQDivider()
            VQFactRow(key: "Next occurrence",
                      value: format.civilLong(VQCalendar.civil(fromJDN: occurrence)))
            VQFactRow(key: "That is",
                      value: format.hijriLong(occurrenceHijri))
            VQFactRow(key: entry.kind == 1 ? "Turning" : "Marking",
                      value: entry.kind == 1
                        ? "\(years) Hijri year\(years == 1 ? "" : "s")"
                        : (years == 0 ? "The first year" : "\(VQFormatter.ordinal(years)) Hijri anniversary"))
            VQFactRow(key: "First recorded", value: "\(entry.originYear) AH")

            VQDivider()

            if confirming {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Delete \"\(entry.title)\"? This cannot be undone.")
                        .font(VQTheme.body(12, .medium))
                        .foregroundColor(VQTheme.clay)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        Button(action: {
                            store.deletePersonalDate(id: entry.id)
                            pendingDelete = nil
                        }) {
                            Text("Delete")
                                .font(VQTheme.body(12.5, .semibold))
                                .foregroundColor(VQTheme.card)
                                .padding(.vertical, 9)
                                .padding(.horizontal, 16)
                                .background(RoundedRectangle(cornerRadius: 9).fill(VQTheme.clay))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        Button(action: { pendingDelete = nil }) {
                            Text("Keep")
                                .font(VQTheme.body(12.5, .medium))
                                .foregroundColor(VQTheme.ink)
                                .padding(.vertical, 9)
                                .padding(.horizontal, 16)
                                .background(RoundedRectangle(cornerRadius: 9).fill(VQTheme.cardAlt))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer(minLength: 0)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Button(action: {
                        draft = VQDateDraft(id: entry.id,
                                            isNew: false,
                                            title: entry.title,
                                            note: entry.note,
                                            anchor: VQHijriDate(year: entry.originYear,
                                                                month: entry.anchor.month,
                                                                day: entry.anchor.day),
                                            kind: entry.kind)
                    }) {
                        Text("Edit")
                            .font(VQTheme.body(12.5, .medium))
                            .foregroundColor(VQTheme.gold)
                            .padding(.vertical, 9)
                            .padding(.horizontal, 16)
                            .background(RoundedRectangle(cornerRadius: 9).fill(VQTheme.goldWash))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { pendingDelete = entry.id }) {
                        HStack(spacing: 6) {
                            VQGlyph(shape: VQTrashShape(), size: 12, color: VQTheme.clay, lineWidth: 1.4)
                            Text("Delete")
                                .font(VQTheme.body(12.5, .medium))
                                .foregroundColor(VQTheme.clay)
                        }
                        .padding(.vertical, 9)
                        .padding(.horizontal, 14)
                        .background(RoundedRectangle(cornerRadius: 9).fill(VQTheme.claySoft.opacity(0.55)))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func commit(_ saved: VQDateDraft) {
        let cleanTitle = saved.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = VQPersonalDate(id: saved.id,
                                   title: cleanTitle.isEmpty ? "Saved date" : cleanTitle,
                                   note: saved.note.trimmingCharacters(in: .whitespacesAndNewlines),
                                   anchor: VQCalendar.clampHijri(saved.anchor),
                                   originYear: VQCalendar.clampHijri(saved.anchor).year,
                                   kind: max(0, min(VQPersonalDate.kindNames.count - 1, saved.kind)))
        if saved.isNew {
            store.addPersonalDate(entry)
        } else {
            store.updatePersonalDate(entry)
        }
        pendingDelete = nil
    }
}

// MARK: - Editor

private enum VQEditorField: Hashable {
    case title
    case note
}

struct VQDateEditorView: View {

    @State private var working: VQDateDraft
    /// Only the FIRST text field in a stack takes a tap on iOS 15 unless focus is driven
    /// explicitly. Both fields carry a tap gesture that sets this.
    @FocusState private var field: VQEditorField?

    let markedSpelling: Bool
    /// The user's global shift, so the preview line matches every other screen.
    let adjustment: Int
    var onCancel: () -> Void
    var onSave: (VQDateDraft) -> Void

    init(draft: VQDateDraft,
         markedSpelling: Bool,
         adjustment: Int,
         onCancel: @escaping () -> Void,
         onSave: @escaping (VQDateDraft) -> Void) {
        _working = State(initialValue: draft)
        self.markedSpelling = markedSpelling
        self.adjustment = adjustment
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        ZStack(alignment: .top) {
            VQTheme.paper.edgesIgnoringSafeArea(.all)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 13) {
                    header

                    VQCard {
                        VQCaption(text: "Name")
                        textBox(placeholder: "What is this date?",
                                text: $working.title,
                                which: .title)

                        VQCaption(text: "Note, if you want one")
                        textBox(placeholder: "Anything you would like to remember",
                                text: $working.note,
                                which: .note)

                        VQCaption(text: "Kind")
                        VQChoiceRow(options: VQPersonalDate.kindNames,
                                    selection: working.kind) { working.kind = $0 }
                    }

                    VQCard {
                        VQCaption(text: "The Hijri date it happened on", color: VQTheme.gold)
                        Text("The day and month are what the entry recurs on. The year is recorded so the app can count the anniversaries.")
                            .font(VQTheme.body(11.5))
                            .foregroundColor(VQTheme.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                        VQHijriDatePicker(value: $working.anchor, markedSpelling: markedSpelling)
                    }

                    VQCard(tint: VQTheme.cardAlt) {
                        VQCaption(text: "Preview")
                        Text(previewLine)
                            .font(VQTheme.body(13, .semibold))
                            .foregroundColor(VQTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(previewCivil)
                            .font(VQTheme.body(12))
                            .foregroundColor(VQTheme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 9) {
                        VQPrimaryButton(label: working.isNew ? "Save date" : "Save changes",
                                        tint: VQTheme.ink) {
                            field = nil
                            onSave(working)
                        }
                    }

                    VQEstimateNote(compact: true)
                        .padding(.horizontal, 2)
                }
                .padding(.horizontal, VQLayout.screenInset)
                .padding(.top, 16)
                .padding(.bottom, 40)
                .frame(maxWidth: VQLayout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(working.isNew ? "New date" : "Edit date")
                .font(VQTheme.display(23))
                .foregroundColor(VQTheme.ink)
            Spacer(minLength: 6)
            Button(action: { field = nil; onCancel() }) {
                VQGlyph(shape: VQCrossShape(), size: 14, color: VQTheme.inkSoft, lineWidth: 1.8)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(VQTheme.cardAlt))
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func textBox(placeholder: String, text: Binding<String>, which: VQEditorField) -> some View {
        ZStack(alignment: .leading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(VQTheme.body(13))
                    .foregroundColor(VQTheme.inkFaint.opacity(0.8))
                    .padding(.horizontal, 11)
                    .allowsHitTesting(false)
            }
            TextField("", text: text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(VQTheme.body(13))
                .foregroundColor(VQTheme.ink)
                .accentColor(VQTheme.gold)
                .disableAutocorrection(false)
                .focused($field, equals: which)
                .padding(.horizontal, 11)
                .padding(.vertical, 11)
        }
        .frame(minHeight: 42)
        .background(RoundedRectangle(cornerRadius: 9).fill(VQTheme.cardAlt))
        .overlay(RoundedRectangle(cornerRadius: 9)
            .stroke(field == which ? VQTheme.gold : VQTheme.rule, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture { field = which }
    }

    private var previewLine: String {
        let format = VQFormatter(markedSpelling: markedSpelling, arabicWeekdays: false)
        return "Recurs on \(format.hijriDayMonth(working.anchor)), first recorded in \(working.anchor.year) AH"
    }

    private var previewCivil: String {
        let jdn = VQCalendar.jdn(fromHijri: VQCalendar.clampHijri(working.anchor)) - adjustment
        let civil = VQCalendar.civil(fromJDN: jdn)
        let format = VQFormatter(markedSpelling: markedSpelling, arabicWeekdays: false)
        return "That Hijri date fell on \(format.civilLong(civil)) by the tabular calendar."
    }
}
