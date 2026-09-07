# Twitch

Twitch is a lightweight macOS menu bar app that keeps the display and computer awake for a chosen period. Optionally, it can make a small pointer movement after five minutes of inactivity and then return the pointer to its original position.

## Features

- Keep the Mac awake indefinitely or until a selected hour.
- Prevent both idle system sleep and idle display sleep during an active session.
- Show the current session and remaining time from the menu bar.
- Optionally move the pointer for five seconds after five minutes without input.
- Optionally register the app to start at login.
- Run entirely on the Mac without accounts, analytics, or network services.

## Requirements

- macOS 26 or later
- Xcode 26 or the matching Xcode Command Line Tools
- Swift 6

## Build and run

Clone the repository, install an Apple Development or Developer ID Application certificate in your keychain, then package the release build as a macOS app:

```sh
git clone https://github.com/mrfuzzyhead/twitch.git
cd twitch
./scripts/build-app.sh
open dist/Twitch.app
```

The script builds the Swift package, generates the app icon variants, creates `dist/Twitch.app`, and signs it with `Developer ID Application: Bradley Searle (VD7DMST4GD)`. It rejects unsigned, ad-hoc, and differently teamed builds because macOS cannot preserve Accessibility permission across versions without a stable code identity. To find available identities, run:

```sh
security find-identity -v -p codesigning
```

Set `TWITCH_SIGNING_IDENTITY` only when selecting another valid identity from team `VD7DMST4GD`.

Move `Twitch.app` to `/Applications` before enabling **Start at login** so macOS can rely on a stable app location.

## Usage

1. Open Twitch and select its bolt icon in the menu bar.
2. Under **Start session**, choose **Indefinitely** or an hour under **Until**.
3. Optionally enable **Twitch** to move the pointer after five minutes of inactivity.
4. Choose **Stop session** when the Mac no longer needs to stay awake.

An **Until** time that has already started today is interpreted as that time tomorrow. Quitting the app also ends the active keep-awake session.

## Permissions and privacy

The optional pointer movement requires macOS Accessibility permission. If prompted, allow Twitch under **System Settings → Privacy & Security → Accessibility**. Keeping the Mac awake does not require this permission.

Twitch does not make network requests or collect usage data. It stores only the local on/off preference for pointer movement in `UserDefaults`. The start-at-login preference is managed by macOS.

## Development

This project is a Swift Package Manager workspace with a SwiftUI menu bar executable and a small testable core module:

```text
.
├── Package.swift
├── Resources/               # Source app icon
├── Sources/
│   ├── Twitch/              # SwiftUI app and session controller
│   └── TwitchCore/          # Session scheduling logic
├── Support/                 # macOS app bundle metadata
├── Tests/TwitchCoreTests/   # Unit tests
└── scripts/build-app.sh     # Release packaging script
```

Common commands:

| Command | Purpose |
| --- | --- |
| `swift test` | Run the scheduling unit tests |
| `swift build -c release` | Compile without creating a runnable app bundle |
| `./scripts/build-app.sh` | Create and sign `dist/Twitch.app` with team `VD7DMST4GD` |

Always run Twitch from the signed app bundle. Running the SwiftPM executable directly does not provide the stable code identity needed for persistent macOS privacy permissions.

The app uses `ProcessInfo.beginActivity` to prevent idle sleep, Core Graphics to detect inactivity and post pointer movement, and `SMAppService` for login-item registration.

## Troubleshooting

- **The pointer does not move:** confirm that **Twitch** is enabled in the menu and that the app has Accessibility permission.
- **Start at login fails:** move the packaged app to `/Applications`, reopen it from there, and try again.
- **The build reports no signing identity:** install the Developer ID Application certificate for team `VD7DMST4GD` and its private key in the login keychain.
- **Accessibility permission is requested after an update:** confirm the replacement app was signed with the same identity and still uses the `net.fuzzyhead.twitch` bundle identifier, then remove and re-add Twitch under **Privacy & Security → Accessibility** if an older ad-hoc build was previously authorized.
