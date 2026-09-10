import SwiftUI

/// The shell. A custom tab bar built from buttons and a switch — `TabView` renders only
/// `Image` plus `Text` in a `.tabItem`, so hand-drawn glyphs would simply vanish.
struct VQRootView: View {

    @EnvironmentObject private var store: VQStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var tab: Int = 0

    var body: some View {
        ZStack {
            VQTheme.paper.edgesIgnoringSafeArea(.all)

            // The bar is a layout sibling below the content, never a floating overlay, so
            // it can never cover the last rows of a scroll view.
            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case 0:
                        NavigationView { VQTodayView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 1:
                        NavigationView { VQCalendarView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView { VQConvertView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 3:
                        NavigationView { VQLibraryView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        NavigationView { VQSettingsView() }
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
            tabButton(0, "Today", AnyView(VQGlyph(shape: VQTodayGlyphShape(), size: 22,
                                                  color: tint(0), lineWidth: 1.5)))
            tabButton(1, "Calendar", AnyView(VQGlyph(shape: VQGridGlyphShape(), size: 22,
                                                     color: tint(1), lineWidth: 1.4)))
            tabButton(2, "Convert", AnyView(VQGlyph(shape: VQSwapGlyphShape(), size: 22,
                                                    color: tint(2), lineWidth: 1.5)))
            tabButton(3, "Library", AnyView(VQGlyph(shape: VQBookGlyphShape(), size: 22,
                                                    color: tint(3), lineWidth: 1.5)))
            tabButton(4, "Settings", AnyView(VQGlyph(shape: VQDialGlyphShape(), size: 22,
                                                     color: tint(4), lineWidth: 1.4)))
        }
        .padding(.top, 7)
        .padding(.bottom, 3)
        .background(
            VStack(spacing: 0) {
                Rectangle().fill(VQTheme.rule).frame(height: 1)
                VQTheme.card
            }
            .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tint(_ index: Int) -> Color {
        tab == index ? VQTheme.gold : VQTheme.inkFaint.opacity(0.8)
    }

    private func tabButton(_ index: Int, _ label: String, _ glyph: AnyView) -> some View {
        Button(action: { if tab != index { tab = index } }) {
            VStack(spacing: 3) {
                glyph
                Text(label)
                    .font(VQTheme.body(9.5, tab == index ? .semibold : .regular))
                    .foregroundColor(tab == index ? VQTheme.gold : VQTheme.inkFaint)
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
