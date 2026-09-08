import SwiftUI
import WebKit

/// The in-app browser used for one thing only: opening the privacy policy from Settings.
/// It is presented as a sheet with its own header, so the user always has a way out and
/// never lands on a chrome-less error page.
struct HJWebSheet: View {

    let address: String
    let title: String
    var onClose: () -> Void

    @State private var isLoading = true
    @State private var failed = false

    var body: some View {
        VStack(spacing: 0) {
            header

            ZStack {
                HJTheme.paper

                if failed {
                    VStack(spacing: 12) {
                        HJEmptyState(headline: "The page could not be loaded",
                                     message: "Check the connection and try again. Everything else in the app works offline.")
                        HJQuietButton(label: "Try again", tint: HJTheme.gold) {
                            failed = false
                            isLoading = true
                            reloadToken += 1
                        }
                    }
                    .padding(.horizontal, HJLayout.screenInset)
                } else {
                    HJWebContent(address: address,
                                 reloadToken: reloadToken,
                                 onFirstPaint: { isLoading = false },
                                 onFailure: { isLoading = false; failed = true })

                    if isLoading {
                        VStack(spacing: 10) {
                            HJGlyph(shape: HJCrescentShape(thinness: 0.5), size: 30,
                                    color: HJTheme.gold, filled: true)
                            Text("Loading\u{2026}")
                                .font(HJTheme.body(12))
                                .foregroundColor(HJTheme.inkFaint)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(HJTheme.paper)
                    }
                }
            }
        }
        .background(HJTheme.paper.edgesIgnoringSafeArea(.all))
    }

    @State private var reloadToken = 0

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(title)
                .font(HJTheme.display(17))
                .foregroundColor(HJTheme.ink)
                .lineLimit(1)
            Spacer(minLength: 6)
            Button(action: onClose) {
                HJGlyph(shape: HJCrossShape(), size: 13, color: HJTheme.inkSoft, lineWidth: 1.8)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(HJTheme.cardAlt))
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, HJLayout.screenInset)
        .padding(.vertical, 12)
        .background(
            VStack(spacing: 0) {
                HJTheme.card
                Rectangle().fill(HJTheme.rule).frame(height: 1)
            }
        )
    }
}

/// A plain `WKWebView` wrapper. No persistence beyond WebKit's own defaults, and no
/// reload on a SwiftUI re-render — only an explicit change of `reloadToken` reloads.
private struct HJWebContent: UIViewRepresentable {

    let address: String
    let reloadToken: Int
    var onFirstPaint: () -> Void
    var onFailure: () -> Void

    final class Coordinator: NSObject, WKNavigationDelegate {
        var onFirstPaint: (() -> Void)?
        var onFailure: (() -> Void)?
        var loadedToken = -1

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            onFirstPaint?()
        }

        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            let ns = error as NSError
            // A cancelled load is what an ordinary redirect looks like from here.
            if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled { return }
            onFailure?()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onFailure?()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let settings = WKWebViewConfiguration()
        settings.allowsInlineMediaPlayback = true

        let panel = WKWebView(frame: .zero, configuration: settings)
        context.coordinator.onFirstPaint = onFirstPaint
        context.coordinator.onFailure = onFailure
        panel.navigationDelegate = context.coordinator
        panel.allowsBackForwardNavigationGestures = true
        panel.scrollView.contentInsetAdjustmentBehavior = .always
        panel.isOpaque = true
        panel.backgroundColor = .white
        panel.scrollView.backgroundColor = .white
        // The app runs in the light scheme; pin the page to match so a system dark setting
        // never reaches the site as prefers-color-scheme: dark.
        panel.overrideUserInterfaceStyle = .light

        if let url = URL(string: address) {
            context.coordinator.loadedToken = reloadToken
            panel.load(URLRequest(url: url))
        }
        return panel
    }

    /// Never reloads on an ordinary re-render — that would restart the page every time
    /// SwiftUI rebuilds the view. Only an explicit retry moves the token.
    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.onFirstPaint = onFirstPaint
        context.coordinator.onFailure = onFailure
        guard context.coordinator.loadedToken != reloadToken else { return }
        context.coordinator.loadedToken = reloadToken
        if let url = URL(string: address) {
            uiView.load(URLRequest(url: url))
        }
    }
}
