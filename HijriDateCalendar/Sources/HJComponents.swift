import SwiftUI

// MARK: - Screen scaffold

/// Every screen in the app is built on this. It owns the paper background, the title
/// block, the scroll, and — as the LAST sibling in the stack — an opaque strip over the
/// status bar area, so scrolled content can never draw across the clock and battery.
struct HJScreen<Content: View>: View {
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
            HJTheme.paper.edgesIgnoringSafeArea(.all)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    content()
                }
                .padding(.horizontal, HJLayout.screenInset)
                .padding(.top, 4)
                .padding(.bottom, bottomPadding)
                .frame(maxWidth: HJLayout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }

            // LAST sibling: the opaque status strip.
            VStack(spacing: 0) {
                HJTheme.paper.frame(height: HJLayout.statusStripHeight)
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
                HJBandOrnamentShape(cells: 9)
                    .stroke(HJTheme.gold.opacity(0.16), lineWidth: 1)
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
                        .font(HJTheme.display(HJLayout.isNarrow ? 25 : 28))
                        .foregroundColor(HJTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(HJTheme.body(12.5))
                            .foregroundColor(HJTheme.inkSoft)
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
struct HJDetailScreen<Content: View>: View {
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
            HJTheme.paper.edgesIgnoringSafeArea(.all)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center, spacing: 10) {
                        Button(action: onBack) {
                            HStack(spacing: 5) {
                                HJGlyph(shape: HJChevronShape(direction: 1), size: 13,
                                        color: HJTheme.gold, lineWidth: 1.9)
                                Text("Back")
                                    .font(HJTheme.body(13, .medium))
                                    .foregroundColor(HJTheme.gold)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(HJTheme.goldWash)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(HJTheme.display(HJLayout.isNarrow ? 23 : 26))
                            .foregroundColor(HJTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if let subtitle = subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(HJTheme.body(12.5))
                                .foregroundColor(HJTheme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    content()
                }
                .padding(.horizontal, HJLayout.screenInset)
                .padding(.bottom, bottomPadding)
                .frame(maxWidth: HJLayout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }

            VStack(spacing: 0) {
                HJTheme.paper.frame(height: HJLayout.statusStripHeight)
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

struct HJCard<Content: View>: View {
    var padding: CGFloat = HJLayout.cardInset
    var tint: Color = HJTheme.card
    var border: Color = HJTheme.rule
    @ViewBuilder var content: () -> Content

    init(padding: CGFloat = HJLayout.cardInset,
         tint: Color = HJTheme.card,
         border: Color = HJTheme.rule,
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
            RoundedRectangle(cornerRadius: HJLayout.corner)
                .fill(tint)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HJLayout.corner)
                .stroke(border, lineWidth: 1)
        )
    }
}

/// A small caption above a block of content.
struct HJCaption: View {
    var text: String
    var color: Color = HJTheme.inkFaint

    var body: some View {
        Text(text.uppercased())
            .font(HJTheme.body(10.5, .semibold))
            .tracking(1.1)
            .foregroundColor(color)
    }
}

// MARK: - The standing accuracy note

/// The quiet reminder that every computed Hijri date is an estimate. It appears on every
/// screen that shows one. Deliberately small and grey — a note, not a nag.
struct HJEstimateNote: View {
    var text: String = "Dates are calculated from the tabular Islamic calendar. Your local moon sighting decides the real day."
    var compact: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            HJGlyph(shape: HJCrescentShape(thinness: 0.55), size: compact ? 11 : 13,
                    color: HJTheme.gold.opacity(0.75), filled: true)
                .padding(.top, 1)
            Text(text)
                .font(HJTheme.body(compact ? 10.5 : 11.5))
                .foregroundColor(HJTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Segmented control

struct HJSegmented: View {
    var options: [String]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options.indices, id: \.self) { index in
                Button(action: {
                    if selection != index { selection = index }
                }) {
                    Text(options[index])
                        .font(HJTheme.body(12.5, selection == index ? .semibold : .regular))
                        .foregroundColor(selection == index ? HJTheme.card : HJTheme.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selection == index ? HJTheme.ink : Color.clear)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 11).fill(HJTheme.cardAlt)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11).stroke(HJTheme.rule, lineWidth: 1)
        )
    }
}

// MARK: - Buttons

struct HJPrimaryButton: View {
    var label: String
    var tint: Color = HJTheme.ink
    var textColor: Color = HJTheme.card
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(HJTheme.body(14, .semibold))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 11).fill(tint))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HJQuietButton: View {
    var label: String
    var tint: Color = HJTheme.gold
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(HJTheme.body(13, .medium))
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
struct HJNavRow<Icon: View>: View {
    var icon: Icon
    var title: String
    var detail: String?
    var accent: Color = HJTheme.gold

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
                    .font(HJTheme.body(14.5, .semibold))
                    .foregroundColor(HJTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail = detail, !detail.isEmpty {
                    Text(detail)
                        .font(HJTheme.body(11.5))
                        .foregroundColor(HJTheme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HJGlyph(shape: HJChevronShape(direction: 0), size: 12,
                    color: HJTheme.inkFaint, lineWidth: 1.7)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: HJLayout.corner).fill(HJTheme.card))
        .overlay(RoundedRectangle(cornerRadius: HJLayout.corner).stroke(HJTheme.rule, lineWidth: 1))
        .contentShape(Rectangle())
    }
}

// MARK: - Key / value

struct HJFactRow: View {
    var key: String
    var value: String
    var valueColor: Color = HJTheme.ink
    var mono: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(key)
                .font(HJTheme.body(12.5))
                .foregroundColor(HJTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Text(value)
                .font(mono ? HJTheme.mono(12.5, .medium) : HJTheme.body(13, .semibold))
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 5)
    }
}

struct HJDivider: View {
    var body: some View {
        Rectangle().fill(HJTheme.ruleSoft).frame(height: 1)
    }
}

// MARK: - Chips and badges

struct HJChip: View {
    var text: String
    var tint: Color = HJTheme.gold

    var body: some View {
        Text(text)
            .font(HJTheme.body(10.5, .semibold))
            .foregroundColor(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(tint.opacity(0.13)))
            .overlay(Capsule().stroke(tint.opacity(0.28), lineWidth: 1))
            .lineLimit(1)
    }
}

// MARK: - Empty state

struct HJEmptyState: View {
    var headline: String
    var message: String

    var body: some View {
        VStack(spacing: 10) {
            HJGlyph(shape: HJCrescentShape(thinness: 0.5), size: 34,
                    color: HJTheme.gold.opacity(0.4), filled: true)
            Text(headline)
                .font(HJTheme.display(16))
                .foregroundColor(HJTheme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(HJTheme.body(12.5))
                .foregroundColor(HJTheme.inkFaint)
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
struct HJStepper: View {
    var label: String
    var value: Int
    var range: ClosedRange<Int>
    var display: String
    var onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(HJTheme.body(13))
                .foregroundColor(HJTheme.inkSoft)
            Spacer(minLength: 8)
            HStack(spacing: 0) {
                stepButton(shape: AnyView(HJGlyph(shape: HJMinusShape(), size: 13,
                                                  color: value > range.lowerBound ? HJTheme.ink : HJTheme.inkFaint.opacity(0.5),
                                                  lineWidth: 2)),
                           enabled: value > range.lowerBound) {
                    onChange(max(range.lowerBound, value - 1))
                }
                Text(display)
                    .font(HJTheme.figure(14, .semibold))
                    .foregroundColor(HJTheme.ink)
                    .frame(minWidth: 62)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                stepButton(shape: AnyView(HJGlyph(shape: HJPlusShape(), size: 13,
                                                  color: value < range.upperBound ? HJTheme.ink : HJTheme.inkFaint.opacity(0.5),
                                                  lineWidth: 2)),
                           enabled: value < range.upperBound) {
                    onChange(min(range.upperBound, value + 1))
                }
            }
            .background(RoundedRectangle(cornerRadius: 9).fill(HJTheme.cardAlt))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(HJTheme.rule, lineWidth: 1))
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
struct HJSwitchRow: View {
    var label: String
    var detail: String?
    var isOn: Bool
    var onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(HJTheme.body(13.5, .medium))
                        .foregroundColor(HJTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let detail = detail, !detail.isEmpty {
                        Text(detail)
                            .font(HJTheme.body(11))
                            .foregroundColor(HJTheme.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? HJTheme.verdant : HJTheme.rule)
                        .frame(width: 44, height: 26)
                    Circle()
                        .fill(HJTheme.card)
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
struct HJChoiceRow: View {
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
                                .font(HJTheme.body(12, selection == index ? .semibold : .regular))
                                .foregroundColor(selection == index ? HJTheme.card : HJTheme.inkSoft)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 9)
                                    .fill(selection == index ? HJTheme.ink : HJTheme.cardAlt))
                                .overlay(RoundedRectangle(cornerRadius: 9)
                                    .stroke(selection == index ? Color.clear : HJTheme.rule, lineWidth: 1))
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
struct HJProgressBar: View {
    var fraction: Double
    var tint: Color = HJTheme.gold
    var track: Color = HJTheme.cardAlt
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
struct HJMonthDial: View {
    var total: Int
    var elapsed: Int
    var size: CGFloat
    var tint: Color = HJTheme.gold
    var track: Color = HJTheme.rule

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
