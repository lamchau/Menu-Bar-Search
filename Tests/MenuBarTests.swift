import Cocoa
import Foundation
import Testing

@testable import MenuBarLib

// MARK: - Modifier decoding

@Suite struct ModifierDecodingTests {
  @Test func decodesCommandOnly() {
    // 0x08 bit clear = command present
    let result = decode(modifiers: 0)
    #expect(result == "⌘")
  }

  @Test func decodesShiftCommand() {
    let result = decode(modifiers: 0x01)
    #expect(result == "⇧⌘")
  }

  @Test func decodesOptionCommand() {
    let result = decode(modifiers: 0x02)
    #expect(result == "⌥⌘")
  }

  @Test func decodesControlCommand() {
    let result = decode(modifiers: 0x04)
    #expect(result == "⌃⌘")
  }

  @Test func decodesAllModifiers() {
    let result = decode(modifiers: 0x07)
    #expect(result == "⌃⌥⇧⌘")
  }

  @Test func decodesFnKey() {
    let result = decode(modifiers: 0x18)
    #expect(result == "fn")
  }

  @Test func decodesNoCommand() {
    // 0x08 bit set = command absent
    let result = decode(modifiers: 0x08)
    #expect(result == "")
  }
}

// MARK: - Shortcut formatting

@Suite struct ShortcutTests {
  @Test func formatsCharacterShortcut() {
    let result = getShortcut("N", 0x01, 0)
    #expect(result == "⇧⌘N")
  }

  @Test func formatsVirtualKeyShortcut() {
    let result = getShortcut(nil, 0, 0x24)
    #expect(result == "⌘↩")
  }

  @Test func returnsEmptyForNoShortcut() {
    let result = getShortcut(nil, 0, 0)
    #expect(result == "")
  }

  @Test func handlesDeleteCharacter() {
    // 0x7f is the delete character
    let deleteChar = String(UnicodeScalar(0x7f)!)
    let result = getShortcut(deleteChar, 0, 0)
    #expect(result == "⌘⌦")
  }
}

// MARK: - MenuItem computed properties

@Suite struct MenuItemPropertyTests {
  @Test func titleReturnsLastPathComponent() {
    var item = MenuItem()
    item.path = ["File", "New", "Document"]
    #expect(item.title == "Document")
  }

  @Test func titleReturnsEmptyForEmptyPath() {
    let item = MenuItem()
    #expect(item.title == "")
  }

  @Test func subtitleJoinsParentPath() {
    var item = MenuItem()
    item.path = ["File", "Export", "PDF"]
    #expect(item.subtitle == "File > Export")
  }

  @Test func uidJoinsFullPath() {
    var item = MenuItem()
    item.path = ["File", "New"]
    #expect(item.uid == "File>New")
  }

  @Test func appleMenuItemDetectsApple() {
    var item = MenuItem()
    item.path = ["Apple", "About This Mac"]
    #expect(item.appleMenuItem == true)
  }

  @Test func appleMenuItemFalseForOther() {
    var item = MenuItem()
    item.path = ["File", "New"]
    #expect(item.appleMenuItem == false)
  }

  @Test func appleMenuItemFalseForEmptyPath() {
    let item = MenuItem()
    #expect(item.appleMenuItem == false)
  }

  @Test func argReturnsPathIndices() {
    var item = MenuItem()
    item.pathIndices = "2,3,1"
    #expect(item.arg == "2,3,1")
  }
}

// MARK: - Fuzzy matching

@Suite struct FuzzyMatchTests {
  @Test func exactMatchScoresHigh() {
    let result = "Close Window".fastMatch("Close Window")
    #expect(result.matched == true)
    #expect(result.score > 7000)
  }

  @Test func fuzzyMatchWorks() {
    let result = "Close Window".fastMatch("cw")
    #expect(result.matched == true)
    #expect(result.score > 0)
  }

  @Test func noMatchReturnsFalse() {
    let result = "Close Window".fastMatch("xyz")
    #expect(result.matched == false)
    #expect(result.score == 0)
  }

  @Test func emptyQueryMatchesEverything() {
    let result = "anything".fastMatch("")
    #expect(result.matched == true)
    #expect(result.score == 8192)
  }
}

// MARK: - AppleScript escaping

@Suite struct AppleScriptEscapeTests {
  @Test func escapesDoubleQuotes() {
    let result = escapeAppleScript("say \"hello\"")
    #expect(result == "say \\\"hello\\\"")
  }

  @Test func escapesBackslashes() {
    let result = escapeAppleScript("path\\to\\file")
    #expect(result == "path\\\\to\\\\file")
  }

  @Test func leavesPlainStringAlone() {
    let result = escapeAppleScript("New Canvas")
    #expect(result == "New Canvas")
  }

  @Test func handlesBothQuotesAndBackslashes() {
    let result = escapeAppleScript("a\\\"b")
    #expect(result == "a\\\\\\\"b")
  }
}

// MARK: - AppRuntime detection

@Suite struct AppRuntimeTests {
  @Test func detectsElectronApp() {
    // Slack is a known Electron app
    let apps = NSWorkspace.shared.runningApplications.filter {
      $0.bundleIdentifier == "com.tinyspeck.slackmacgap"
    }
    if let slack = apps.first {
      let runtime = AppRuntime.detect(for: slack)
      #expect(runtime == .electron)
    }
  }

  @Test func detectsNativeApp() {
    let apps = NSWorkspace.shared.runningApplications.filter {
      $0.bundleIdentifier == "com.apple.finder"
    }
    if let finder = apps.first {
      let runtime = AppRuntime.detect(for: finder)
      #expect(runtime == .native)
    }
  }
}

// MARK: - Alfred JSON encoding

@Suite struct AlfredEncodingTests {
  @Test func encodesBasicItem() throws {
    var item = AlfredResultItem()
    item.title = "Test"
    item.arg = "1,2"
    let data = try JSONEncoder().encode(item)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(json["title"] as? String == "Test")
    #expect(json["arg"] as? String == "1,2")
  }

  @Test func omitsValidWhenTrue() throws {
    var item = AlfredResultItem()
    item.title = "Test"
    item.valid = true
    let data = try JSONEncoder().encode(item)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    // valid defaults to true, should be omitted
    #expect(json["valid"] == nil)
  }

  @Test func includesValidWhenFalse() throws {
    var item = AlfredResultItem()
    item.title = "Test"
    item.valid = false
    let data = try JSONEncoder().encode(item)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(json["valid"] as? Bool == false)
  }

  @Test func omitsEmptyOptionalFields() throws {
    var item = AlfredResultItem()
    item.title = "Test"
    let data = try JSONEncoder().encode(item)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(json["subtitle"] == nil)
    #expect(json["arg"] == nil)
    #expect(json["uid"] == nil)
    #expect(json["autocomplete"] == nil)
    #expect(json["icon"] == nil)
  }

  @Test func encodesIconWithTypeAndPath() throws {
    var item = AlfredResultItem()
    item.title = "Test"
    item.icon = AlfredResultItemIcon(type: "fileicon", path: "/Applications/Slack.app")
    let data = try JSONEncoder().encode(item)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    let icon = json["icon"] as! [String: String]
    #expect(icon["type"] == "fileicon")
    #expect(icon["path"] == "/Applications/Slack.app")
  }

  @Test func iconOmitsEmptyType() throws {
    let icon = AlfredResultItemIcon(type: "", path: "icon.png")
    let data = try JSONEncoder().encode(icon)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(json["type"] == nil)
    #expect(json["path"] as? String == "icon.png")
  }

  @Test func withBuilderCreatesItem() {
    let item = AlfredResultItem.with {
      $0.title = "Hello"
      $0.arg = "test"
    }
    #expect(item.title == "Hello")
    #expect(item.arg == "test")
  }

  @Test func resultListEncodesCorrectly() throws {
    var list = AlfredResultList()
    var item = AlfredResultItem()
    item.title = "Test"
    list.items.append(item)
    let data = try JSONEncoder().encode(list)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    let items = json["items"] as! [[String: Any]]
    #expect(items.count == 1)
    #expect(items[0]["title"] as? String == "Test")
  }
}

// MARK: - Cache round-trip

@Suite struct CacheTests {
  @Test func menuItemCacheRoundTrips() throws {
    var cache = MenuItemCache()
    cache.timeout = 1234.5
    cache.created = 1000.0
    let data = try JSONEncoder().encode(cache)
    let decoded = try JSONDecoder().decode(MenuItemCache.self, from: data)
    #expect(decoded.timeout == 1234.5)
    #expect(decoded.created == 1000.0)
  }

  @Test func menuItemListRoundTrips() throws {
    var item = MenuItem()
    item.path = ["File", "New"]
    item.pathIndices = "2,0"
    item.shortcut = "⌘N"
    item.searchPath = ["file", "new"]
    let list = MenuItemList(items: [item])
    let data = try JSONEncoder().encode(list)
    let decoded = try JSONDecoder().decode(MenuItemList.self, from: data)
    #expect(decoded.items.count == 1)
    #expect(decoded.items[0].path == ["File", "New"])
    #expect(decoded.items[0].pathIndices == "2,0")
    #expect(decoded.items[0].shortcut == "⌘N")
  }
}

// MARK: - Settings parsing

@Suite struct SettingsTests {
  @Test func parsesSettingsJSON() throws {
    let json = """
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
      """
    let data = Data(json.utf8)
    let settings = try JSONDecoder().decode(Settings.self, from: data)
    #expect(settings.appFilters.count == 1)
    #expect(settings.appFilters[0].app == "com.example.app")
    #expect(settings.appFilters[0].showDisabledMenuItems == true)
    #expect(settings.appFilters[0].cacheDuration == 5.0)
    #expect(settings.appFilters[0].ignoreMenuPaths.count == 1)
    #expect(settings.appFilters[0].ignoreMenuPaths[0].path == ["Edit", "Undo"])
  }

  @Test func parsesEmptySettings() throws {
    let json = """
      {"appFilters": []}
      """
    let data = Data(json.utf8)
    let settings = try JSONDecoder().decode(Settings.self, from: data)
    #expect(settings.appFilters.isEmpty)
  }
}

// MARK: - Click arg format

@Suite struct ClickArgParsingTests {
  @Test func parsesFullFormat() {
    let arg = "12345:⇧⌘N:2,2:File→New Canvas"
    let parts = arg.split(separator: ":", maxSplits: 3, omittingEmptySubsequences: false)
    #expect(parts.count == 4)
    #expect(Int32(parts[0]) == 12345)
    #expect(String(parts[1]) == "⇧⌘N")
    #expect(String(parts[2]) == "2,2")
    let menuPath = String(parts[3]).split(separator: "→").map(String.init)
    #expect(menuPath == ["File", "New Canvas"])
  }

  @Test func parsesNoShortcutFormat() {
    let arg = "12345::2,1:File→New Channel"
    let parts = arg.split(separator: ":", maxSplits: 3, omittingEmptySubsequences: false)
    #expect(parts.count == 4)
    #expect(Int32(parts[0]) == 12345)
    #expect(String(parts[1]) == "")
    #expect(String(parts[2]) == "2,1")
    let menuPath = String(parts[3]).split(separator: "→").map(String.init)
    #expect(menuPath == ["File", "New Channel"])
  }

  @Test func parsesDeepMenuPath() {
    let arg = "999::2,4,11:File→Workspace→Create New Workspace"
    let parts = arg.split(separator: ":", maxSplits: 3, omittingEmptySubsequences: false)
    let menuPath = String(parts[3]).split(separator: "→").map(String.init)
    #expect(menuPath == ["File", "Workspace", "Create New Workspace"])
  }
}

// MARK: - MenuGetterOptions

@Suite struct MenuGetterOptionsTests {
  @Test func defaultValues() {
    let options = MenuGetterOptions()
    #expect(options.maxDepth == 10)
    #expect(options.maxChildren == 20)
    #expect(options.specificMenuRoot == nil)
    #expect(options.dumpInfo == false)
    #expect(options.recache == false)
  }

  @Test func canIgnorePathReturnsTrueForMatch() {
    var options = MenuGetterOptions()
    var filter = AppFilter()
    filter.ignoreMenuPaths = [MenuPath(path: ["Edit", "Undo"])]
    options.appFilter = filter
    #expect(options.canIgnorePath(path: ["Edit", "Undo"]) == true)
  }

  @Test func canIgnorePathReturnsFalseForNoMatch() {
    var options = MenuGetterOptions()
    var filter = AppFilter()
    filter.ignoreMenuPaths = [MenuPath(path: ["Edit", "Undo"])]
    options.appFilter = filter
    #expect(options.canIgnorePath(path: ["File", "New"]) == false)
  }
}

// MARK: - RuntimeArgs

@Suite struct RuntimeArgsTests {
  @Test func defaultValues() {
    let args = RuntimeArgs()
    #expect(args.query == "")
    #expect(args.pid == -1)
    #expect(args.reorderAppleMenuToLast == true)
    #expect(args.learning == false)
    #expect(args.shortcut == "")
    #expect(args.menuPath.isEmpty)
    #expect(args.pathIndices == "")
    #expect(args.cachingEnabled == false)
    #expect(args.cacheTimeout == 0.0)
  }
}
