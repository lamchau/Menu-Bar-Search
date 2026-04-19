import Foundation

public struct CacheControl: CustomStringConvertible {
  public let appBundleId: String
  public let control: MenuItemCache

  public var description: String {
    return "app:\(appBundleId) created:\(control.created) timeout:\(control.timeout)"
  }

  public init(appBundleId: String, control: MenuItemCache) {
    self.appBundleId = appBundleId
    self.control = control
  }
}

enum CacheType: String {
  case cache
  case menus
}

public enum Cache {
  static func getURL(_ app: String, _ type: CacheType) -> URL {
    let base =
      app
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: ":", with: "_")
    return URL(fileURLWithPath: Alfred.cache(path: "\(base).\(type.rawValue)"))
  }

  public static func save(app: String, items: [MenuItem], lifetime: Double) {
    var control = MenuItemCache()
    control.created = Date().timeIntervalSince1970
    control.timeout = control.created + lifetime
    let list = MenuItemList(items: items)
    save(control, getURL(app, .cache))
    save(list, getURL(app, .menus))
  }

  static func save<T: Encodable>(_ value: T, _ url: URL) {
    guard let data = try? JSONEncoder().encode(value) else { return }
    do {
      try data.write(to: url)
    } catch {}
  }

  public static func load(app: String, settingsModifiedInterval: Double? = nil) -> [MenuItem]? {
    let controlURL = getURL(app, .cache)
    guard let controlData = try? Data(contentsOf: controlURL),
      var control = try? JSONDecoder().decode(MenuItemCache.self, from: controlData)
    else { return nil }

    if let interval = settingsModifiedInterval, control.created <= interval {
      return nil
    }

    let dt = Date().timeIntervalSince1970 - control.timeout
    if dt >= 1 {
      return nil
    }

    let url = getURL(app, .menus)
    guard let data = try? Data(contentsOf: url),
      let list = try? JSONDecoder().decode(MenuItemList.self, from: data)
    else { return nil }

    // slide the timeout window forward on each access
    control.timeout += 3
    save(control, controlURL)

    return list.items
  }

  public static func invalidate(app: String) {
    try? FileManager.default.removeItem(at: getURL(app, .cache))
  }

  public static func getCachedMenuControls() -> [CacheControl] {
    var controls = [CacheControl]()
    let fm = FileManager.default
    let cachePath = Alfred.cache()
    guard let files = try? fm.contentsOfDirectory(atPath: cachePath) else {
      return controls
    }
    for file in files where file.hasSuffix(".cache") {
      let bundleID = String(file.dropLast(6))
      guard let controlData = try? Data(contentsOf: getURL(bundleID, .cache)) else {
        continue
      }
      guard let control = try? JSONDecoder().decode(MenuItemCache.self, from: controlData) else {
        continue
      }
      controls.append(
        .init(
          appBundleId: bundleID,
          control: control
        ))
    }
    return controls
  }
}
