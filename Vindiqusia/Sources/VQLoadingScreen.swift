import SwiftUI

/// The splash. It is shown while the launch check runs, and again over the panel until the
/// page paints — the same screen in both places, so the handoff has no visible seam.
///
/// The ground is deliberately dark even though the app itself is paper-light: the branch
/// presenting this runs in the dark colour scheme, which draws the clock and battery
/// white, and white glyphs need something dark behind them.
struct VQLoadingScreen: View {

    @State private var breathe = false

    /// The app's ink, deepened until it works as a ground rather than as text.
    private let ground = Color(red: 0.055, green: 0.098, blue: 0.180)   // #0E1A2E

    var body: some View {
        ZStack {
            ground.edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                ZStack {
                    VQCalendarPageShape(rows: 3, columns: 4)
                        .stroke(VQTheme.gold.opacity(0.30),
                                style: StrokeStyle(lineWidth: 1.3, lineJoin: .round))
                        .frame(width: 96, height: 96)

                    // The crescent sits where a new month would be announced: off the
                    // top-right corner of the page.
                    VQCrescentShape(thinness: 0.52)
                        .fill(VQTheme.goldSoft)
                        .frame(width: 32, height: 32)
                        .offset(x: 40, y: -42)
                        .opacity(breathe ? 1.0 : 0.45)
                }
                .scaleEffect(breathe ? 1.0 : 0.96)
                .animation(Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                           value: breathe)

                VStack(spacing: 5) {
                    Text("Vindiqusia")
                        .font(VQTheme.display(21))
                        .foregroundColor(VQTheme.paper)
                    Text("Both calendars on one page")
                        .font(VQTheme.body(12))
                        .foregroundColor(VQTheme.goldSoft.opacity(0.80))
                }
            }
            .padding(24)
        }
        .onAppear { breathe = true }
    }
}
