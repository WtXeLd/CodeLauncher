# CodeLauncher

A lightweight macOS menu bar app that lets you instantly open recent VSCode (or Cursor) projects from anywhere with a global hotkey.

<img width="646" height="466" alt="截屏2026-04-26 17 30 46" src="https://github.com/user-attachments/assets/9a6117f8-4736-47cb-9242-b3a231c6fdff" />

## Features

- **Global hotkey** — Press `⌘⇧S` from any app to bring up the launcher panel
- **Fuzzy search** — Type to filter projects by name or path
- **Keyboard navigation** — `↑↓` to move, `↵` to open, `⇧↵` to reveal in Finder, `esc` to dismiss
- **Quick open** — `⌘1` – `⌘5` to open the first 5 projects directly
- **Frosted glass UI** — Native macOS panel with vibrancy effect
- **Cursor support** — Automatically detects VSCode or Cursor, whichever is installed
- **Launch at login** — Optional, configurable in Settings
- **Custom hotkey** — Rebind the global shortcut in Settings

## Requirements

- macOS 14 (Sonoma) or later
- VSCode or Cursor installed

## Installation

Download the latest DMG from [Releases](https://github.com/WtXeLd/CodeLauncher/releases), open it, and drag CodeLauncher to your Applications folder.

> **First launch:** macOS may block the app because it is not notarized. Right-click (or Control-click) the app icon and choose **Open**, then click **Open** in the dialog. You only need to do this once.
>
> Alternatively, remove the quarantine attribute from Terminal:
> ```bash
> xattr -dr com.apple.quarantine /Applications/CodeLauncher.app
> ```

On first launch, grant **Accessibility** permission when prompted — this is required for the global hotkey to work system-wide.

## Build from source

```bash
git clone https://github.com/WtXeLd/CodeLauncher.git
cd CodeLauncher
swift build
swift run
```

To build a release DMG:

```bash
make package VERSION=1.0.0
```

## How it works

CodeLauncher reads VSCode's recent projects from its SQLite state database at:

```
~/Library/Application Support/Code/User/globalStorage/state.vscdb
```

No background polling or file watching — the list is refreshed each time you open the panel.

## Keyboard shortcuts

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate list |
| `↵` | Open in VSCode |
| `⇧↵` | Reveal in Finder |
| `⌘1` – `⌘5` | Open project at position 1–5 |
| `esc` | Dismiss panel |

## License

MIT
