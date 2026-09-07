import ApplicationServices
import AppKit
import Combine
import ServiceManagement
import TwitchCore

@MainActor
final class SessionController: ObservableObject {
    enum Session: Equatable {
        case indefinitely
        case until(Date)
    }

    @Published private(set) var session: Session?
    @Published private(set) var now = Date()
    @Published private(set) var statusMessage: String?
    @Published private(set) var launchAtLoginEnabled: Bool
    @Published var twitchEnabled: Bool {
        didSet {
            UserDefaults.standard.set(twitchEnabled, forKey: Self.twitchDefaultsKey)
            if twitchEnabled {
                requestAccessibilityPermissionIfNeeded()
            } else {
                hasRequestedAccessibilityPermission = false
                stopTwitching()
            }
        }
    }

    private static let twitchDefaultsKey = "twitchEnabled"
    private static let idleThreshold: TimeInterval = 5 * 60
    private static let twitchDuration: TimeInterval = 5

    private var keepAwakeActivity: NSObjectProtocol?
    private var heartbeat: Timer?
    private var twitchTask: Task<Void, Never>?
    private var twitchStartPoint: CGPoint?
    private var hasRequestedAccessibilityPermission = false

    init() {
        twitchEnabled = UserDefaults.standard.bool(forKey: Self.twitchDefaultsKey)
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled

        heartbeat = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    var isActive: Bool {
        session != nil
    }

    var sessionSummary: String {
        guard let session else { return "Not active" }

        switch session {
        case .indefinitely:
            return "Active indefinitely"
        case .until(let endDate):
            let endTime = Self.timeFormatter.string(from: endDate)
            let remaining = max(0, endDate.timeIntervalSince(now))
            return "Active until \(endTime) · \(Self.durationString(remaining)) remaining"
        }
    }

    func startIndefinitely() {
        start(.indefinitely)
    }

    func start(untilHour hour: Int) {
        guard let endDate = SessionSchedule.nextOccurrence(ofHour: hour, after: Date()) else {
            statusMessage = "Could not calculate that end time."
            return
        }
        start(.until(endDate))
    }

    func stopSession() {
        session = nil
        stopTwitching()

        if let keepAwakeActivity {
            ProcessInfo.processInfo.endActivity(keepAwakeActivity)
            self.keepAwakeActivity = nil
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
            statusMessage = nil
        } catch {
            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
            statusMessage = "Start at login could not be changed: \(error.localizedDescription)"
        }
    }

    private func start(_ newSession: Session) {
        if keepAwakeActivity == nil {
            keepAwakeActivity = ProcessInfo.processInfo.beginActivity(
                options: [.idleSystemSleepDisabled, .idleDisplaySleepDisabled, .userInitiated],
                reason: "Twitch keep-awake session"
            )
        }

        now = Date()
        session = newSession
        statusMessage = nil
    }

    private func tick() {
        now = Date()

        if case .until(let endDate) = session, now >= endDate {
            stopSession()
            return
        }

        guard session != nil, twitchEnabled, twitchTask == nil else { return }

        let idleSeconds = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: CGEventType(rawValue: UInt32.max)!
        )
        if idleSeconds >= Self.idleThreshold {
            startTwitching()
        }
    }

    private func requestAccessibilityPermissionIfNeeded() {
        guard !AXIsProcessTrusted() else {
            hasRequestedAccessibilityPermission = false
            statusMessage = nil
            return
        }

        guard !hasRequestedAccessibilityPermission else {
            statusMessage = "Allow Twitch in Privacy & Security → Accessibility to move the pointer."
            return
        }

        hasRequestedAccessibilityPermission = true
        AXIsProcessTrustedWithOptions([
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary)
        statusMessage = "Allow Twitch in Privacy & Security → Accessibility to move the pointer."
    }

    private func startTwitching() {
        guard AXIsProcessTrusted() else {
            requestAccessibilityPermissionIfNeeded()
            return
        }
        guard let startingPoint = CGEvent(source: nil)?.location else { return }

        twitchStartPoint = startingPoint
        statusMessage = "Twitching…"

        twitchTask = Task { [weak self] in
            guard let self else { return }
            let frameCount = Int(Self.twitchDuration * 20)

            for frame in 0..<frameCount {
                guard !Task.isCancelled, self.session != nil, self.twitchEnabled else { break }

                let angle = Double(frame) / 8.0
                let radius = 4.0
                let point = CGPoint(
                    x: startingPoint.x + cos(angle) * radius,
                    y: startingPoint.y + sin(angle) * radius
                )
                self.postMouseMove(to: point)
                try? await Task.sleep(nanoseconds: 50_000_000)
            }

            self.postMouseMove(to: startingPoint)
            self.twitchStartPoint = nil
            self.twitchTask = nil
            if self.statusMessage == "Twitching…" {
                self.statusMessage = nil
            }
        }
    }

    private func stopTwitching() {
        twitchTask?.cancel()
        twitchTask = nil
        if let twitchStartPoint {
            postMouseMove(to: twitchStartPoint)
            self.twitchStartPoint = nil
        }
        if statusMessage == "Twitching…" {
            statusMessage = nil
        }
    }

    private func postMouseMove(to point: CGPoint) {
        let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        )
        event?.post(tap: .cghidEventTap)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static func durationString(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(ceil(interval / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0, minutes > 0 { return "\(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(minutes)m"
    }
}
