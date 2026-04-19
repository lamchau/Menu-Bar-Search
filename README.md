# Menu Bar Search Alfred Workflow

Search and action macOS app menu-bar items via Alfred.

This is a maintained fork of [philocalyst/Menu-Bar-Search](https://github.com/philocalyst/Menu-Bar-Search), which itself continues [BenziAhamed/Menu-Bar-Search](https://github.com/BenziAhamed/Menu-Bar-Search).

## Setup

- Enable "Accessibility" for Alfred in
  **System Settings → Privacy & Security → Accessibility**.
- Open the workflow's Configuration in Alfred to customize:
  - **Maximum items per menu**
  - **Maximum sub-menu depth**
  - **Show disabled menu items**
  - **Include Apple menu items**
  - **Refresh cache on every new search**
- For per-app overrides, type `ms` in Alfred to open the **Settings** folder, then edit `settings.txt`.

## Usage

### Search Menu Items (`m`)

Type `m` followed by your query to list menu-bar items of the frontmost application.
Supports fuzzy matching via [fuse-swift](https://github.com/krisk/fuse-swift).

Example: `m cw` will match **Close Window** via fuzzy search

* <kbd>↩</kbd> Click the selected menu item

### Browse Folders (`ms`)

Type `ms` to open your workflow's **Settings** and **Cache** folders.

* <kbd>↩</kbd> Open folder

## Changes from upstream

This fork modernizes the codebase and fixes long-standing issues. Key differences from [philocalyst/Menu-Bar-Search](https://github.com/philocalyst/Menu-Bar-Search):

### Architecture

- **Library/CLI split** — core logic is in `MenuBarLib` (testable), CLI is a thin wrapper in `cli/`
- **App runtime detection** — detects native vs Electron apps via bundle framework inspection
- **Dispatch strategies** — menu clicks are routed through `MenuClickDispatcher` which selects the best strategy per app type:
  - **Native apps**: direct `AXPress` on the menu item (instant, no subprocess)
  - **Electron apps** (Slack, VS Code, etc.): keyboard shortcut first, then `osascript` AXPress-open-then-press
- **PID tracking** — the target app's PID is encoded in the Alfred arg so clicks go to the correct app even after Alfred takes focus

### Modernization

- **Protobuf removed** — replaced 575 lines of generated protobuf code with plain `Codable`/`Sendable` structs
- **macOS 12 minimum** — raised from 10.15 (Alfred 5 requires 12+)
- **Swift 6.1 concurrency** — all types are properly `Sendable`, `RuntimeArgs` is a value type
- **Dead code removed** — `IndexParser`, `clickMenu`, `resolveMenuPath`, unused flags, redundant guards

### Bug fixes

- **`valid` field default** — protobuf defaulted `valid` to `false` but Alfred treats missing as `true`; Codable structs default to `true`
- **Electron menu clicks** — `AXPress` fires but Electron apps silently ignore it; now uses `osascript` with AXPress-open-then-press
- **Force crash fixes** — replaced force casts on `CFNumber`/`AXUIElement` and force unwraps on `path.last!`
- **AppleScript injection** — menu item names are now escaped before interpolation into AppleScript
- **Activation spin-wait** — added 2-second timeout to prevent infinite loop

### Testing

- **48 tests** covering modifier decoding, shortcut formatting, MenuItem properties, fuzzy matching, AppleScript escaping, AppRuntime detection, Alfred JSON encoding, cache round-trip, settings parsing, and click arg format parsing

### Settings format

Settings files (`settings.txt`) now use **JSON** instead of protobuf text format. Example:

```json
{
  "appFilters": [
    {
      "app": "com.example.app",
      "showDisabledMenuItems": true,
      "showAppleMenu": false,
      "cacheDuration": 5.0,
      "disabled": false,
      "ignoreMenuPaths": [
        {"path": ["Edit", "Undo"]}
      ]
    }
  ]
}
```

## Building from source

```bash
swift build -c release
cp .build/release/menu ./menu
codesign -s - ./menu
```

Run tests:

```bash
swift test
```

## Caching

On first run the workflow builds a cache of menu items (this may take a few seconds).
Subsequent searches use the cache. The cache auto-extends on access and rebuilds when stale.
Control cache behavior in the Workflow Configuration or via your per-app `settings.txt`.

## Troubleshooting

If you see
> Assistive applications are not enabled in System Preferences

ensure Alfred is granted Accessibility in System Settings → Privacy & Security → Accessibility.

For Electron apps (Slack, VS Code), also ensure Alfred has **Automation** permission for **System Events** in System Settings → Privacy & Security → Automation.

## Lineage

```
BenziAhamed/Menu-Bar-Search (original, archived)
  └─ philocalyst/Menu-Bar-Search (continued development, fuse-swift, Alfred 5)
       └─ lamchau/Menu-Bar-Search (this fork: modernized, tested, Electron support)
```

## License

See upstream repositories for license information.
