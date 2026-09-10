import SwiftUI
import UIKit

/// A fixed, literal palette. Nothing here is derived from the system's light/dark
/// setting, so the app renders identically whatever the device is set to.
enum VQTheme {

    // Ink — text and structure
    static let ink       = Color(red: 0.071, green: 0.126, blue: 0.227)   // #12203A
    static let inkSoft   = Color(red: 0.227, green: 0.290, blue: 0.400)
    static let inkFaint  = Color(red: 0.463, green: 0.502, blue: 0.573)

    // Paper — surfaces
    static let paper     = Color(red: 0.949, green: 0.914, blue: 0.847)   // #F2E9D8
    static let card      = Color(red: 0.992, green: 0.976, blue: 0.941)   // #FDF9F0
    static let cardAlt   = Color(red: 0.969, green: 0.937, blue: 0.878)
    static let rule      = Color(red: 0.878, green: 0.827, blue: 0.722)
    static let ruleSoft  = Color(red: 0.914, green: 0.878, blue: 0.796)

    // Brass — the accent
    static let gold      = Color(red: 0.722, green: 0.525, blue: 0.184)   // #B8862F
    static let goldSoft  = Color(red: 0.894, green: 0.780, blue: 0.494)
    static let goldWash  = Color(red: 0.976, green: 0.937, blue: 0.831)

    // Verdant — observances, fasting, anything affirmative
    static let verdant     = Color(red: 0.180, green: 0.380, blue: 0.322)  // #2E6152
    static let verdantSoft = Color(red: 0.812, green: 0.878, blue: 0.839)
    static let verdantWash = Color(red: 0.918, green: 0.949, blue: 0.929)

    // Clay — days fasting is not permitted, destructive actions
    static let clay      = Color(red: 0.659, green: 0.337, blue: 0.247)    // #A8563F
    static let claySoft  = Color(red: 0.941, green: 0.863, blue: 0.827)

    // Indigo — the secondary calendar, so the two systems never read the same
    static let indigo     = Color(red: 0.286, green: 0.302, blue: 0.541)
    static let indigoSoft = Color(red: 0.851, green: 0.855, blue: 0.918)

    static let shadow    = Color(red: 0.071, green: 0.126, blue: 0.227).opacity(0.07)

    // MARK: - Type

    static func display(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        Font.system(size: size, weight: weight, design: .serif)
    }

    static func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .default)
    }

    static func figure(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        Font.system(size: size, weight: weight, design: .rounded)
    }

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .monospaced)
    }
}

/// Everything that depends on the device rather than the design. Values come from the
/// live window where there is one, never from an assumed device shape.
enum VQLayout {

    private static var activeWindow: UIWindow? {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            if let window = windowScene.windows.first(where: { $0.isKeyWindow })
                ?? windowScene.windows.first {
                return window
            }
        }
        return nil
    }

    /// True on the 375-point class of device, where a title set at the larger size wraps.
    /// Nothing in the app is sized from the screen width — every row is laid out with
    /// `maxWidth: .infinity` inside a scroll view that already respects the safe area — so
    /// this is the only place the device shape is consulted for layout.
    static var isNarrow: Bool { UIScreen.main.bounds.width <= 380 }

    /// Height of the band behind the clock and battery. Screens paint an opaque strip
    /// there so scrolled content can never pass under the status bar. In landscape the
    /// real inset is zero and the strip has to vanish with it, so the window's own value
    /// is taken as given.
    static var statusStripHeight: CGFloat {
        if let window = activeWindow { return max(0, window.safeAreaInsets.top) }
        return UIScreen.main.bounds.height >= UIScreen.main.bounds.width ? 44 : 0
    }

    static let screenInset: CGFloat = 16
    static let cardInset: CGFloat = 14
    static let corner: CGFloat = 14

    /// Reading measure, so an iPad or a landscape iPhone never stretches a paragraph the
    /// whole way across.
    static let maxContentWidth: CGFloat = 640
}
