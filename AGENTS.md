# Repository instructions

## Code signing

- Every distributable `Twitch.app` build must be signed with a stable Apple Development or Developer ID Application identity. Never produce, install, or distribute an unsigned or ad-hoc-signed app bundle.
- Build app bundles only with `./scripts/build-app.sh`. It defaults to `Developer ID Application: Bradley Searle (VD7DMST4GD)`; only set `TWITCH_SIGNING_IDENTITY` when deliberately selecting another identity belonging to team `VD7DMST4GD`.
- Every app bundle must use signing team `VD7DMST4GD` and bundle identifier `net.fuzzyhead.twitch`. Changing either invalidates macOS privacy permissions, including Accessibility access.
- Do not replace `/Applications/Twitch.app` with a build that has a different designated requirement.
- After packaging, verify the signature with `codesign --verify --deep --strict --verbose=2 dist/Twitch.app` and inspect it with `codesign -dvvv --requirements - dist/Twitch.app`. The result must not contain `Signature=adhoc` or `TeamIdentifier=not set`.

## Verification

- Run `swift test` after source changes.
- Run `zsh -n scripts/build-app.sh` after changing the packaging script.
- When a valid signing identity is available, run the signed packaging command and its signature checks before reporting a distributable build as complete.
