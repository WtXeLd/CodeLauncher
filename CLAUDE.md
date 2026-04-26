# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
make build          # swift build
make run            # swift run
make test           # swift test
make package VERSION=X.X.X  # build universal DMG via scripts/package.sh
```

For a release build targeting both architectures:
```bash
swift build -c release --arch arm64 --arch x86_64
```

## Architecture

CodeLauncher is a macOS menu bar app (Swift 6 / SwiftUI, macOS 14+) that provides a global hotkey-triggered floating panel for quickly opening recent projects in code editors.

**Startup flow:** `CodeLauncherApp` (SwiftUI entry) → `AppDelegate` sets activation policy to `.accessory` (no Dock icon) and registers a system-wide hotkey via `HotkeyManager` using the Carbon Event API.

**Hotkey → panel:** `HotkeyManager` listens for the global shortcut (default ⌘⇧S) and calls `QuickLaunchWindowController.toggle()`, which creates/shows a floating `NSPanel` (600×420, `NSVisualEffectView` frosted glass) positioned at the center of the active screen.

**Data layer:** `VSCodeReader` reads recent projects from the SQLite database at `~/Library/Application Support/Code/User/globalStorage/state.vscdb` (or the Cursor equivalent). The `history.recentlyOpenedPathsList` key stores a JSON blob with the project list. `EditorApp` detects installed editors (VSCode, Cursor, Zed, JetBrains IDEs) by checking known bundle IDs; the user's preference is persisted via `EditorPreference`.

**State:** `LaunchViewModel` is an `@Observable` class that holds the project list, search text, and selection index. It is owned by `QuickLaunchWindowController` and passed into the SwiftUI view hierarchy.

**UI:** `QuickLaunchView` renders a search bar + filtered project list + footer. Keyboard shortcuts: ↑↓ navigate, ↵ opens, ⌘1–5 open by index, Shift+↵ reveals in Finder, Esc dismisses. `SettingsView` covers launch-at-login, editor picker, and hotkey recording (`ShortcutRecorder`).

**Packaging:** `scripts/package.sh` builds a universal binary, ad-hoc code-signs the `.app` bundle, and wraps it in a DMG using `create-dmg`. The GitHub Actions workflow (`.github/workflows/release.yml`) triggers on git tags and uploads the DMG as a release asset.

To cut a release:
```bash
git tag v1.2.3
git push origin v1.2.3
```
This triggers the CI workflow which runs `make package VERSION=1.2.3 ARCH=<arm64|x86_64>` for both architectures and attaches both DMGs to the GitHub release.
