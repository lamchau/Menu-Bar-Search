# Changelog

All notable changes to this project are documented in this changelog.
This project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [3.0.0] - 2026-04-19

Fork: [lamchau/Menu-Bar-Search](https://github.com/lamchau/Menu-Bar-Search)

> **Note:** v2.0 was used by [BenziAhamed](https://github.com/BenziAhamed/Menu-Bar-Search)
> in 2023 for the notarized release. This fork skips to v3.0.0 to avoid confusion.

### Added
- App runtime detection (native vs Electron) with per-runtime dispatch strategies
- Electron app support: keyboard shortcut dispatch and osascript AXPress-open-then-press
- PID tracking in Alfred arg to prevent wrong-app clicks after focus change
- AppleScript string escaping to prevent injection via menu item names
- 2-second timeout on app activation spin-wait
- 48 unit tests covering core logic
- Library/CLI target split for testability (`MenuBarLib` + `menu`)

### Changed
- Search keyword default from `mu` to `m`
- macOS deployment target from 10.15 to 12 (matches Alfred 5 requirement)
- Replaced protobuf with plain `Codable`/`Sendable` structs (-575 lines)
- Settings file format from protobuf text to JSON
- Cache serialization from protobuf binary to JSON
- `RuntimeArgs` from mutable class to `Sendable` struct
- Force casts on `CFNumber`/`AXUIElement` to `unsafeDowncast`
- Force unwraps `path.last!`/`path[0]` to safe access

### Fixed
- `valid` field defaulted to `false` (protobuf); now defaults to `true` (Alfred convention)
- Electron apps (Slack, VS Code) silently ignoring `AXPress` on menu items
- Infinite spin-wait when target app fails to activate
- Dead cache expiry branch (condition was always true)

### Removed
- `swift-protobuf` dependency and generated code (`MenuItem.pb.swift`)
- Dead code: `IndexParser`, `resolveMenuPath`, `clickMenu`, `MenuBar.click`
- Unused `--async` CLI flag, dead `#if swift` and `#available` guards
- Duplicate `AXUIElementCreateApplication` call, `halfWidthSpace` variable
- Scaffold test that asserted `"Hello, world!\n"`

### Breaking Changes
- **Search keyword**: default changed from `mu` to `m` — update your muscle memory or reconfigure in Alfred
- **macOS 12 minimum**: drops support for macOS 10.15–11 (Alfred 5 already requires 12+)
- **Settings file format**: `settings.txt` now uses JSON instead of protobuf text format — existing settings files must be converted
- **Cache format**: switched from protobuf binary to JSON — cached data will be rebuilt automatically on first run
- **`--async` flag removed**: no longer accepted as a CLI argument

## [1.3.1] – 2025-05-13

### Added
- Support customisable search and settings keywords via `SEARCH_KEYWORD` and
  `SETTINGS_KEYWORD` workflow variables.
- A single universal binary

### Changed
- Update workflow icon to avoid visual conflicts with earlier versions.
- Improve asset images with a refreshed color scheme.

### Removed
- Remove redundant second‐example screenshot from the README.

### Fixed
- Fix asset image paths in the README to point to the `Assets` directory.

## [1.3.0] – 2025-05-13

### Added
- Integrate Fuse.swift v1.4.0 for fuzzy matching (`fastMatch` now powered by Fuse).  
- Standardize all code under a top-level `source/` directory.  
- Include Alfred workflow metadata and assets:  
  - Icons (`apple-icon.png`, `icon.png`, `icon.settings.png`, `icon.error.png`)  
  - `info.plist` with workflow configuration  
  - Sample `settings.txt` for per-app overrides  

### Changed
- Revamped README: updated title, description, setup instructions, usage examples and contribution links.  
- Restructured repository:  
  - Moved `Package.swift`, `Package.resolved` and `.gitignore` to project root  
  - Eliminated old nested `source/` tree in favor of a single `source/` folder  
- Replaced bespoke fuzzy-matching algorithm with Fuse-based implementation for better accuracy and maintainability.  

## [1.2.2] – 2025-05-12

### Added
- Add `@retroactive @unchecked Sendable` conformance for `AXUIElement` to silence Swift concurrency warnings.

### Changed
- Optimize menu-bar retrieval in `MenuGetter.load` by pre-filtering top-level bar items before spawning tasks, reserving result capacity, and reducing per-item overhead.
- Change CLI `--pid` option and `RuntimeArgs.pid` from `Int` to `Int32` to match process identifier types.

### Removed
- Remove internal `loadAsync` property from `RuntimeArgs` and its CLI assignment, deprecating the `--async` flag integration.

## [1.2.1] – 2025-04-19

### Added
- New CLI entrypoint `@main struct Menu: AsyncParsableCommand` powered by  
  [swift-argument-parser], replacing custom `RuntimeArgs.parse()`.  
- Async/await actor-based `MenuGetter` using `withTaskGroup` for  
  concurrent menu traversal and safe aggregation.  
- Conformance of `AXUIElement` and `MenuGetterOptions` to `@unchecked Sendable`.  
- Comprehensive set of flags and options:  
  `--query`, `--pid`, `--max-depth`, `--max-children`,  
  `--reorder-apple-menu`, `--learning`, `--click`, `--async`,  
  `--cache`, `--show-disabled`, `--show-apple-menu`, `--recache`,  
  `--dump`, `--show-folders`, and `--only`.  
- Require macOS 10.15+ in the package manifest for Swift concurrency support.  
- Bump Swift Protobuf to v1.29.0 and add swift-argument-parser v1.5.0;  
  update `swift-tools-version` to 6.1.  
- Rename `main.swift` → `MenuSearch.swift` and refactor entry in code.  
- Switch Protobuf cache logic from `serializedData()` to `serializedBytes()`.

### Changed
- Refactor all GCD-based queues/`DispatchGroup` to modern Swift concurrency.  
- Default `learning` mode is now off (`false`) instead of on.  
- Simplify cache timeout logic by sliding window forward on near-expiry.  
- Clean up `IndexParser` and code formatting for consistency.

### Removed
- Delete legacy `MenuItem.proto` and all commented-out AX attribute debug helpers.  
- Strip dead code in `RuntimeArgs.swift` and remove redundant manual `main()` calls.

### Fixed
- Preserve all passed-in arguments when invoking the new CLI (no more accidental  
  overwrite).

---

[Unreleased]: https://github.com/lamchau/Menu-Bar-Search/compare/v3.0.0...HEAD
[3.0.0]: https://github.com/lamchau/Menu-Bar-Search/compare/v1.3.1...v3.0.0
[1.3.1]: https://github.com/philocalyst/Menu-Bar-Search/compare/v1.2.2...v1.3.1
[1.3.0]: https://github.com/philocalyst/Menu-Bar-Search/compare/v1.2.2...v1.3.0  
[1.2.2]:    https://github.com/philocalyst/Menu-Bar-Search/compare/v1.2.1...v1.2.2  
[1.2.1]: https://github.com/your-org/menu/compare/...v1.2.1  
