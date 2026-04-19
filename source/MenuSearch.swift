// main.swift - renders menu bar items as Alfred results
// (c) Benzi Ahamed, 2017
// The aim of this workflow is to provide the *fastest* possible
// ux for searching and actioning menu bar items of the app specified
// in Alfred using Swift

import Cocoa
import Foundation

@MainActor
public struct MenuSearch {
  public static func run(with initialArgs: RuntimeArgs) async {
    var args = initialArgs
    // Prepare Alfred workflow directories
    Alfred.preparePaths()

    // Determine target application
    let targetApp: NSRunningApplication? =
      args.pid == -1
      ? NSWorkspace.shared.menuBarOwningApplication
      : NSRunningApplication(processIdentifier: args.pid)

    guard let app = targetApp else {
      Alfred.quit("Unable to get app info")
    }

    // Paths and identifiers for icons & display
    let appPath =
      app.bundleURL?.path
      ?? app.executableURL?.path
      ?? "icon.png"
    let appLocalizedName = app.localizedName ?? "no-name"
    let appBundleId = app.bundleIdentifier ?? "no-id"
    let appDisplayName = "\(appLocalizedName) (\(appBundleId))"

    // Create menu bar accessor
    let menuBar = MenuBar(for: app)
    switch menuBar.initState {
    case .success:
      break
    case .apiDisabled:
      Alfred.quit(
        "Assistive applications are not enabled in System Preferences.",
        subtitle: "Is accessibility enabled for Alfred?")
    case .noValue:
      Alfred.quit(
        "No menu bar",
        subtitle: "\(appDisplayName) does not have a native menu bar")
    default:
      Alfred.quit(
        "Could not get menu bar",
        subtitle: "An error occurred: \(menuBar.initState.rawValue)")
    }

    // Handle a click request and exit
    if !args.menuPath.isEmpty {
      MenuClickDispatcher.click(
        app: app,
        appName: appLocalizedName,
        shortcut: args.shortcut,
        menuPath: args.menuPath,
        pathIndices: args.pathIndices,
        menuBar: menuBar.menuBar
      )
      Cache.invalidate(app: appBundleId)
      exit(0)
    }

    // Invalidate cache if requested on empty query
    if args.options.recache, args.query.isEmpty {
      Cache.invalidate(app: appBundleId)
    }

    // Load optional settings file to override filters/cache
    var settingsModifiedInterval: Double?
    let fm = FileManager.default
    let settingsPath = Alfred.data(path: "settings.txt")
    if fm.fileExists(atPath: settingsPath) {
      if let attrs = try? fm.attributesOfItem(atPath: settingsPath),
        let mod = attrs[.modificationDate] as? Date,
        let text = try? String(contentsOfFile: settingsPath)
      {
        settingsModifiedInterval = mod.timeIntervalSince1970
        do {
          let settingsData = Data(text.utf8)
          let settings = try JSONDecoder().decode(Settings.self, from: settingsData)
          if let idx = settings.appFilters.firstIndex(
            where: { $0.app == appBundleId })
          {
            let appOverride = settings.appFilters[idx]
            if appOverride.disabled {
              Alfred.quit(
                "Menu search disabled!",
                subtitle: "\(appDisplayName)",
                icon: "icon.error.png")
            }
            args.options.appFilter = appOverride
            if appOverride.cacheDuration > 0 {
              args.cacheTimeout = appOverride.cacheDuration
              args.cachingEnabled = true
            } else {
              args.cachingEnabled = false
            }
          }
        } catch let e as DecodingError {
          Alfred.quit("\(e)", subtitle: "Settings Error")
        } catch {
          Alfred.quit("Invalid settings file", subtitle: settingsPath)
        }
      } else {
        Alfred.quit("Invalid settings file", subtitle: settingsPath)
      }
    }

    // Load or compute the menu items
    let menuItems: [MenuItem]
    let a = Alfred()
    let pidStr = "\(app.processIdentifier)"
    if args.cachingEnabled,
      let cached = Cache.load(
        app: appBundleId,
        settingsModifiedInterval: settingsModifiedInterval)
    {
      menuItems = cached
    } else {
      menuItems = await menuBar.load(args.options)
      if args.cachingEnabled {
        Cache.save(
          app: appBundleId,
          items: menuItems,
          lifetime: args.cacheTimeout)
      }
    }

    // A MainActor-isolated render function
    @MainActor func render(_ menu: MenuItem) {
      let isApple = menu.appleMenuItem
      a.add(
        .with {
          $0.uid =
            args.learning
            ? "\(appBundleId)>\(menu.uid)"
            : ""
          $0.title =
            menu.shortcut.isEmpty
            ? menu.title
            : "\(menu.title) - \(menu.shortcut)"
          $0.subtitle = menu.subtitle
          $0.arg = "\(pidStr):\(menu.shortcut):\(menu.pathIndices):\(menu.path.joined(separator: "→"))"
          $0.icon = AlfredResultItemIcon(
            type: isApple ? "" : "fileicon",
            path: isApple ? "apple-icon.png" : appPath
          )
        })
    }

    // Filter, sort, and render
    if !args.query.isEmpty {
      let term = args.query
      menuItems
        .map { menu -> (MenuItem, (matched: Bool, score: Int)) in
          var level = menu.path.count - 1
          let menuText =
            menu.searchPath[level]
            + " "
            + menu.shortcut.lowercased()
          var search = menuText.fastMatch(term)
          if !search.matched {
            level -= 1
            var adjust = 2
            while level >= 0 {
              search = menu.searchPath[level].fastMatch(term)
              if search.matched {
                search.score =
                  search.score > 0
                  ? search.score / adjust
                  : search.score * adjust
                break
              }
              level -= 1
              adjust *= 2
            }
          }
          return (menu, search)
        }
        .filter { $0.1.matched }
        .sorted { $0.1.score > $1.1.score }
        .forEach { render($0.0) }

    } else if args.options.appFilter.showAppleMenu,
      args.reorderAppleMenuToLast,
      !menuItems.isEmpty
    {
      // Move Apple menu items to the end
      let end = menuItems.endIndex
      if let i = menuItems.firstIndex(where: { $0.appleMenuItem }) {
        var j = i + 1
        while j < end, menuItems[j].appleMenuItem {
          j += 1
        }
        if i > 0 {
          menuItems[0..<i].forEach { render($0) }
        }
        if j < end {
          menuItems[j..<end].forEach { render($0) }
        }
        menuItems[i..<j].forEach { render($0) }
      } else {
        menuItems.forEach { render($0) }
      }

    } else {
      menuItems.forEach { render($0) }
    }

    // If nothing matched, show a placeholder
    if a.results.items.isEmpty {
      a.add(
        AlfredResultItem.with {
          $0.title = "No menu items"
          $0.icon = AlfredResultItemIcon(path: "icon.error.png")
        })
    }

    // Output JSON to Alfred
    print(a.resultsJson)
  }
}
