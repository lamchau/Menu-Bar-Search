import ApplicationServices
import Cocoa
import Foundation

// MARK: - App runtime detection

public enum AppRuntime {
  case native
  case electron

  public static func detect(for app: NSRunningApplication) -> AppRuntime {
    guard let bundleURL = app.bundleURL else { return .native }
    let electronPath = bundleURL.appendingPathComponent(
      "Contents/Frameworks/Electron Framework.framework"
    ).path
    if FileManager.default.fileExists(atPath: electronPath) {
      return .electron
    }
    return .native
  }
}

// MARK: - Menu click dispatch

public enum MenuClickDispatcher {
  /// clicks a menu item using the best strategy for the app type
  public static func click(
    app: NSRunningApplication,
    appName: String,
    shortcut: String,
    menuPath: [String],
    pathIndices: String,
    menuBar: AXUIElement?
  ) {
    // activate if needed
    if !app.isActive {
      app.activate()
      var waited = 0
      while !app.isActive, waited < 200 {
        usleep(10_000)
        waited += 1
      }
    }

    let runtime = AppRuntime.detect(for: app)
    switch runtime {
    case .native:
      clickNative(
        shortcut: shortcut,
        pathIndices: pathIndices,
        menuBar: menuBar
      )
    case .electron:
      clickElectron(
        appName: appName,
        shortcut: shortcut,
        menuPath: menuPath
      )
    }
  }

  // MARK: - Native apps

  /// native apps respond to direct AXPress on menu items (fast, no visual flash)
  private static func clickNative(
    shortcut: String,
    pathIndices: String,
    menuBar: AXUIElement?
  ) {
    guard let menuBar = menuBar else { return }
    let indices = parseIndices(pathIndices)
    guard !indices.isEmpty else { return }
    pressMenuItem(menu: menuBar, pathIndices: indices, currentIndex: 0)
  }

  /// walks the AX menu tree by index and presses the final item
  private static func pressMenuItem(
    menu element: AXUIElement,
    pathIndices: [Int],
    currentIndex: Int
  ) {
    guard
      let menuBarItems = getAttribute(element: element, name: kAXChildrenAttribute)
        as? [AXUIElement], !menuBarItems.isEmpty
    else { return }
    let itemIndex = pathIndices[currentIndex]
    guard itemIndex >= menuBarItems.startIndex, itemIndex < menuBarItems.endIndex else { return }
    let child = menuBarItems[itemIndex]
    if currentIndex == pathIndices.count - 1 {
      AXUIElementPerformAction(child, kAXPressAction as CFString)
      return
    }
    guard
      let submenu = getAttribute(element: child, name: kAXChildrenAttribute) as? [AXUIElement],
      !submenu.isEmpty
    else { return }
    pressMenuItem(menu: submenu[0], pathIndices: pathIndices, currentIndex: currentIndex + 1)
  }

  private static func parseIndices(_ text: String) -> [Int] {
    text.split(separator: ",").compactMap { Int($0) }
  }

  // MARK: - Electron apps

  /// electron apps ignore direct AXPress — use keyboard shortcut or
  /// open-then-press via osascript
  private static func clickElectron(
    appName: String,
    shortcut: String,
    menuPath: [String]
  ) {
    // try keyboard shortcut first (most reliable for electron)
    if !shortcut.isEmpty,
      sendShortcutViaSystemEvents(appName: appName, shortcut: shortcut)
    {
      return
    }
    // fall back to AXPress-open-then-press via osascript
    clickMenuViaSystemEvents(appName: appName, menuPath: menuPath)
  }
}
