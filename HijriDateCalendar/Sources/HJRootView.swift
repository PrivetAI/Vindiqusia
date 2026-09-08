import SwiftUI

/// The shell. A custom tab bar built from buttons and a switch — `TabView` renders only
/// `Image` plus `Text` in a `.tabItem`, so hand-drawn glyphs would simply vanish.
struct HJRootView: View {

    @EnvironmentObject private var store: HJStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var tab: Int = 0

    var body: some View {
        ZStack {
            HJTheme.paper.edgesIgnoringSafeArea(.all)

            // The bar is a layout sibling below the content, never a floating overlay, so
            // it can never cover the last rows of a scroll view.
            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case 0:
                        NavigationView { HJTodayView(onOpenLibrary: { tab = 3 }) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 1:
                        NavigationView { HJCalendarView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView { HJConvertView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 3:
                        NavigationView { HJLibraryView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        NavigationView { HJSettingsView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                tabBar
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                // Refresh the "today" reading — the app may have been warm across midnight.
                store.noteSceneActive()
            } else {
                // Only on the way out. `.inactive` fires in both directions, so anything
                // that must happen exactly once on leaving belongs behind this test.
                store.save()
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Today", AnyView(HJGlyph(shape: HJTodayGlyphShape(), size: 22,
                                                  color: tint(0), lineWidth: 1.5)))
            tabButton(1, "Calendar", AnyView(HJGlyph(shape: HJGridGlyphShape(), size: 22,
                                                     color: tint(1), lineWidth: 1.4)))
            tabButton(2, "Convert", AnyView(HJGlyph(shape: HJSwapGlyphShape(), size: 22,
                                                    color: tint(2), lineWidth: 1.5)))
            tabButton(3, "Library", AnyView(HJGlyph(shape: HJBookGlyphShape(), size: 22,
                                                    color: tint(3), lineWidth: 1.5)))
            tabButton(4, "Settings", AnyView(HJGlyph(shape: HJDialGlyphShape(), size: 22,
                                                     color: tint(4), lineWidth: 1.4)))
        }
        .padding(.top, 7)
        .padding(.bottom, 3)
        .background(
            VStack(spacing: 0) {
                Rectangle().fill(HJTheme.rule).frame(height: 1)
                HJTheme.card
            }
            .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tint(_ index: Int) -> Color {
        tab == index ? HJTheme.gold : HJTheme.inkFaint.opacity(0.8)
    }

    private func tabButton(_ index: Int, _ label: String, _ glyph: AnyView) -> some View {
        Button(action: { if tab != index { tab = index } }) {
            VStack(spacing: 3) {
                glyph
                Text(label)
                    .font(HJTheme.body(9.5, tab == index ? .semibold : .regular))
                    .foregroundColor(tab == index ? HJTheme.gold : HJTheme.inkFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
