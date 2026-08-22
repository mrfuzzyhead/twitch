import AppKit
import SwiftUI
import TwitchCore

@main
struct TwitchApp: App {
    @StateObject private var controller = SessionController()

    var body: some Scene {
        MenuBarExtra {
            Text(controller.sessionSummary)
                .font(.headline)

            if let statusMessage = controller.statusMessage {
                Text(statusMessage)
            }

            Divider()

            Menu("Start session") {
                Button("Indefinitely") {
                    controller.startIndefinitely()
                }

                Menu("Until") {
                    ForEach(0..<24, id: \.self) { hour in
                        Button(SessionSchedule.hourLabel(for: hour)) {
                            controller.start(untilHour: hour)
                        }
                    }
                }
            }

            if controller.isActive {
                Button("Stop session") {
                    controller.stopSession()
                }
            }

            Divider()

            Toggle(
                "Twitch",
                isOn: Binding(
                    get: { controller.twitchEnabled },
                    set: { controller.twitchEnabled = $0 }
                )
            )

            Toggle(
                "Start at login",
                isOn: Binding(
                    get: { controller.launchAtLoginEnabled },
                    set: { controller.setLaunchAtLogin($0) }
                )
            )

            Divider()

            Button("Quit Twitch") {
                controller.stopSession()
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(systemName: controller.isActive ? "bolt.circle.fill" : "bolt.circle")
                .accessibilityLabel(controller.sessionSummary)
        }
        .menuBarExtraStyle(.menu)
    }
}
