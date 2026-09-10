import SwiftUI

// MARK: - Screen scaffold

/// Every screen in the app is built on this. It owns the paper background, the title
/// block, the scroll, and — as the LAST sibling in the stack — an opaque strip over the
/// status bar area, so scrolled content can never draw across the clock and battery.
struct VQScreen<Content: View>: View {
    var title: String
    var subtitle: String?
    var trailing: AnyView?
    var showsOrnament: Bool = true
    /// Room for the tab bar plus a little air. The tab bar is a layout sibling rather than
    /// a floating overlay, so this is breathing room and not clearance.
    var bottomPadding: CGFloat = 28
    @ViewBuilder var content: () -> Content

    init(title: String,
         subtitle: String? = nil,
         trailing: AnyView? = nil,
         showsOrnament: Bool = true,
         bottomPadding: CGFloat = 28,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.showsOrnament = showsOrnament
        self.bottomPadding = bottomPadding
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .top) {
            VQTheme.paper.edgesIgnoringSafeArea(.all)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    content()
                }
                .padding(.horizontal, VQLayout.screenInset)
                .padding(.top, 4)
                .padding(.bottom, bottomPadding)
                .frame(maxWidth: VQLayout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }

            // LAST sibling: the opaque status strip.
            VStack(spacing: 0) {
                VQTheme.paper.frame(height: VQLayout.statusStripHeight)
                Spacer(minLength: 0)
            }
            .edgesIgnoringSafeArea(.top)
            .allowsHitTesting(false)
        }
        .navigationBarHidden(true)
        .navigationBarTitle("", displayMode: .inline)
    }

    private var header: some View {
        ZStack(alignment: .leading) {
            if showsOrnament {
                VQBandOrnamentShape(cells: 9)
                    .stroke(VQTheme.gold.opacity(0.16), lineWidth: 1)
                    .frame(height: 54)
                    .frame(maxWidth: .infinity)
                    .mask(
                        LinearGradient(colors: [Color.black.opacity(0.85), Color.black.opacity(0.0)],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .allowsHitTesting(false)
            }
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(VQTheme.display(VQLayout.isNarrow ? 25 : 28))
                        .foregroundColor(VQTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(VQTheme.body(12.5))
                            .foregroundColor(VQTheme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 4)
                if let trailing = trailing {
                    trailing
                }
            }
            .padding(.vertical, 8)
        }
    }
}

/// A pushed screen — same furniture, plus a back control, since no navigation bar is ever
/// shown anywhere in the app.
struct VQDetailScreen<Content: View>: View {
    var title: String
    var subtitle: String?
    var onBack: () -> Void
    var bottomPadding: CGFloat = 30
    @ViewBuilder var content: () -> Content

    init(title: String,
         subtitle: String? = nil,
         bottomPadding: CGFloat = 30,
         onBack: @escaping () -> Void,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.bottomPadding = bottomPadding
        self.onBack = onBack
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .top) {
            VQTheme.paper.edgesIgnoringSafeArea(.all)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center, spacing: 10) {
                        Button(action: onBack) {
                            HStack(spacing: 5) {
                                VQGlyph(shape: VQChevronShape(direction: 1), size: 13,
                                        color: VQTheme.gold, lineWidth: 1.9)
                                Text("Back")
                                    .font(VQTheme.body(13, .medium))
                                    .foregroundColor(VQTheme.gold)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(VQTheme.goldWash)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(VQTheme.display(VQLayout.isNarrow ? 23 : 26))
                            .foregroundColor(VQTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if let subtitle = subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(VQTheme.body(12.5))
                                .foregroundColor(VQTheme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    content()
                }
                .padding(.horizontal, VQLayout.screenInset)
                .padding(.bottom, bottomPadding)
                .frame(maxWidth: VQLayout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }

            VStack(spacing: 0) {
                VQTheme.paper.frame(height: VQLayout.statusStripHeight)
                Spacer(minLength: 0)
            }
            .edgesIgnoringSafeArea(.top)
            .allowsHitTesting(false)
        }
        .navigationBarHidden(true)
        .navigationBarTitle("", displayMode: .inline)
    }
}

// MARK: - Card

struct VQCard<Content: View>: View {
    var padding: CGFloat = VQLayout.cardInset
    var tint: Color = VQTheme.card
    var border: Color = VQTheme.rule
    @ViewBuilder var content: () -> Content

    init(padding: CGFloat = VQLayout.cardInset,
         tint: Color = VQTheme.card,
         border: Color = VQTheme.rule,
         @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.tint = tint
        self.border = border
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: VQLayout.corner)
                .fill(tint)
        )
        .overlay(
            RoundedRectangle(cornerRadius: VQLayout.corner)
                .stroke(border, lineWidth: 1)
        )
    }
}

/// A small caption above a block of content.
struct VQCaption: View {
    var text: String
    var color: Color = VQTheme.inkFaint

    var body: some View {
        Text(text.uppercased())
            .font(VQTheme.body(10.5, .semibold))
            .tracking(1.1)
            .foregroundColor(color)
    }
}

// MARK: - The standing accuracy note

/// The quiet reminder that every computed Hijri date is an estimate. It appears on every
/// screen that shows one. Deliberately small and grey — a note, not a nag.
struct VQEstimateNote: View {
    var text: String = "Dates are calculated from the tabular Islamic calendar. Your local moon sighting decides the real day."
    var compact: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VQGlyph(shape: VQCrescentShape(thinness: 0.55), size: compact ? 11 : 13,
                    color: VQTheme.gold.opacity(0.75), filled: true)
                .padding(.top, 1)
            Text(text)
                .font(VQTheme.body(compact ? 10.5 : 11.5))
                .foregroundColor(VQTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Segmented control

struct VQSegmented: View {
    var options: [String]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options.indices, id: \.self) { index in
                Button(action: {
                    if selection != index { selection = index }
                }) {
                    Text(options[index])
                        .font(VQTheme.body(12.5, selection == index ? .semibold : .regular))
                        .foregroundColor(selection == index ? VQTheme.card : VQTheme.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selection == index ? VQTheme.ink : Color.clear)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 11).fill(VQTheme.cardAlt)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11).stroke(VQTheme.rule, lineWidth: 1)
        )
    }
}

// MARK: - Buttons

struct VQPrimaryButton: View {
    var label: String
    var tint: Color = VQTheme.ink
    var textColor: Color = VQTheme.card
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(VQTheme.body(14, .semibold))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 11).fill(tint))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VQQuietButton: View {
    var label: String
    var tint: Color = VQTheme.gold
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(VQTheme.body(13, .medium))
                .foregroundColor(tint)
                .padding(.vertical, 9)
                .padding(.horizontal, 13)
                .background(RoundedRectangle(cornerRadius: 9).fill(tint.opacity(0.10)))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// A row that pushes somewhere. The whole row is the tap target.
struct VQNavRow<Icon: View>: View {
    var icon: Icon
    var title: String
    var detail: String?
    var accent: Color = VQTheme.gold

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accent.opacity(0.12))
                    .frame(width: 38, height: 38)
                icon
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(VQTheme.body(14.5, .semibold))
                    .foregroundColor(VQTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail = detail, !detail.isEmpty {
                    Text(detail)
                        .font(VQTheme.body(11.5))
                        .foregroundColor(VQTheme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VQGlyph(shape: VQChevronShape(direction: 0), size: 12,
                    color: VQTheme.inkFaint, lineWidth: 1.7)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: VQLayout.corner).fill(VQTheme.card))
        .overlay(RoundedRectangle(cornerRadius: VQLayout.corner).stroke(VQTheme.rule, lineWidth: 1))
        .contentShape(Rectangle())
    }
}

// MARK: - Key / value

struct VQFactRow: View {
    var key: String
    var value: String
    var valueColor: Color = VQTheme.ink
    var mono: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(key)
                .font(VQTheme.body(12.5))
                .foregroundColor(VQTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Text(value)
                .font(mono ? VQTheme.mono(12.5, .medium) : VQTheme.body(13, .semibold))
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 5)
    }
}

struct VQDivider: View {
    var body: some View {
        Rectangle().fill(VQTheme.ruleSoft).frame(height: 1)
    }
}

// MARK: - Chips and badges

struct VQChip: View {
    var text: String
    var tint: Color = VQTheme.gold

    var body: some View {
        Text(text)
            .font(VQTheme.body(10.5, .semibold))
            .foregroundColor(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(tint.opacity(0.13)))
            .overlay(Capsule().stroke(tint.opacity(0.28), lineWidth: 1))
            .lineLimit(1)
    }
}

// MARK: - Empty state

struct VQEmptyState: View {
    var headline: String
    var message: String

    var body: some View {
        VStack(spacing: 10) {
            VQGlyph(shape: VQCrescentShape(thinness: 0.5), size: 34,
                    color: VQTheme.gold.opacity(0.4), filled: true)
            Text(headline)
                .font(VQTheme.display(16))
                .foregroundColor(VQTheme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(VQTheme.body(12.5))
                .foregroundColor(VQTheme.inkFaint)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 12)
    }
}

// MARK: - Custom stepper

/// A stepper built from two buttons and a label. The system `Stepper` is not used
/// anywhere in the app.
struct VQStepper: View {
    var label: String
    var value: Int
    var range: ClosedRange<Int>
    var display: String
    var onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(VQTheme.body(13))
                .foregroundColor(VQTheme.inkSoft)
            Spacer(minLength: 8)
            HStack(spacing: 0) {
                stepButton(shape: AnyView(VQGlyph(shape: VQMinusShape(), size: 13,
                                                  color: value > range.lowerBound ? VQTheme.ink : VQTheme.inkFaint.opacity(0.5),
                                                  lineWidth: 2)),
                           enabled: value > range.lowerBound) {
                    onChange(max(range.lowerBound, value - 1))
                }
                Text(display)
                    .font(VQTheme.figure(14, .semibold))
                    .foregroundColor(VQTheme.ink)
                    .frame(minWidth: 62)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                stepButton(shape: AnyView(VQGlyph(shape: VQPlusShape(), size: 13,
                                                  color: value < range.upperBound ? VQTheme.ink : VQTheme.inkFaint.opacity(0.5),
                                                  lineWidth: 2)),
                           enabled: value < range.upperBound) {
                    onChange(min(range.upperBound, value + 1))
                }
            }
            .background(RoundedRectangle(cornerRadius: 9).fill(VQTheme.cardAlt))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(VQTheme.rule, lineWidth: 1))
        }
    }

    private func stepButton(shape: AnyView, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { if enabled { action() } }) {
            shape
                .frame(width: 38, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// A two-state switch drawn from shapes — no system `Toggle`.
struct VQSwitchRow: View {
    var label: String
    var detail: String?
    var isOn: Bool
    var onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(VQTheme.body(13.5, .medium))
                        .foregroundColor(VQTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let detail = detail, !detail.isEmpty {
                        Text(detail)
                            .font(VQTheme.body(11))
                            .foregroundColor(VQTheme.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? VQTheme.verdant : VQTheme.rule)
                        .frame(width: 44, height: 26)
                    Circle()
                        .fill(VQTheme.card)
                        .frame(width: 20, height: 20)
                        .padding(.horizontal, 3)
                }
                .frame(width: 44, height: 26)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// A row of mutually exclusive choices, laid out as wrapping pills.
struct VQChoiceRow: View {
    var options: [String]
    var selection: Int
    var onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: 6) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    ForEach(rows[rowIndex], id: \.self) { index in
                        Button(action: { onSelect(index) }) {
                            Text(options[index])
                                .font(VQTheme.body(12, selection == index ? .semibold : .regular))
                                .foregroundColor(selection == index ? VQTheme.card : VQTheme.inkSoft)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 9)
                                    .fill(selection == index ? VQTheme.ink : VQTheme.cardAlt))
                                .overlay(RoundedRectangle(cornerRadius: 9)
                                    .stroke(selection == index ? Color.clear : VQTheme.rule, lineWidth: 1))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    if rows[rowIndex].count < perRow {
                        ForEach(Array(0..<(perRow - rows[rowIndex].count)), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity).frame(height: 1)
                        }
                    }
                }
            }
        }
    }

    private var perRow: Int { options.count > 3 ? 2 : max(1, options.count) }

    private var rows: [[Int]] {
        var out: [[Int]] = []
        var current: [Int] = []
        for index in options.indices {
            current.append(index)
            if current.count == perRow { out.append(current); current = [] }
        }
        if !current.isEmpty { out.append(current) }
        return out
    }
}

// MARK: - Progress

/// A hand-drawn progress bar. The Charts framework is iOS 16 and is not used anywhere.
struct VQProgressBar: View {
    var fraction: Double
    var tint: Color = VQTheme.gold
    var track: Color = VQTheme.cardAlt
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            let width = max(0, proxy.size.width)
            let clamped = max(0, min(1, fraction.isFinite ? fraction : 0))
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(tint).frame(width: width * CGFloat(clamped))
            }
        }
        .frame(height: height)
    }
}

/// A ring of ticks, one per day of the month, with the elapsed ones filled. Drawn with
/// `Canvas`-free geometry so it behaves identically on every deployment target.
struct VQMonthDial: View {
    var total: Int
    var elapsed: Int
    var size: CGFloat
    var tint: Color = VQTheme.gold
    var track: Color = VQTheme.rule

    var body: some View {
        ZStack {
            ForEach(Array(0..<max(1, total)), id: \.self) { index in
                Capsule()
                    .fill(index < elapsed ? tint : track.opacity(0.55))
                    .frame(width: 2, height: index < elapsed ? size * 0.11 : size * 0.075)
                    .offset(y: -size * 0.42)
                    .rotationEffect(.degrees(Double(index) / Double(max(1, total)) * 360))
            }
        }
        .frame(width: size, height: size)
    }
}
