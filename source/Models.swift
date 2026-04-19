import Foundation

// MARK: - Builder helper

extension AlfredResultItem {
  public static func with(_ configure: (inout AlfredResultItem) -> Void) -> AlfredResultItem {
    var item = AlfredResultItem()
    configure(&item)
    return item
  }
}

// MARK: - Menu item types

public struct MenuItem: Codable, Sendable {
  public var pathIndices: String = ""
  public var shortcut: String = ""
  public var path: [String] = []
  public var searchPath: [String] = []

  public init() {}
}

public struct MenuItemList: Codable, Sendable {
  public var items: [MenuItem] = []

  public init(items: [MenuItem] = []) {
    self.items = items
  }
}

public struct MenuItemCache: Codable, Sendable {
  public var timeout: Double = 0
  public var created: Double = 0

  public init() {}
}

// MARK: - Alfred JSON output types

public struct AlfredResultList: Codable, Sendable {
  public var items: [AlfredResultItem] = []

  public init() {}
}

public struct AlfredResultItem: Codable, Sendable {
  public var title: String = ""
  public var subtitle: String = ""
  public var arg: String = ""
  public var uid: String = ""
  public var autocomplete: String = ""
  // alfred treats missing `valid` as true, so default to true
  public var valid: Bool = true
  public var icon: AlfredResultItemIcon?

  public init() {}

  enum CodingKeys: String, CodingKey {
    case title
    case subtitle
    case arg
    case uid
    case autocomplete
    case valid
    case icon
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(title, forKey: .title)
    if !subtitle.isEmpty {
      try container.encode(subtitle, forKey: .subtitle)
    }
    if !arg.isEmpty {
      try container.encode(arg, forKey: .arg)
    }
    if !uid.isEmpty {
      try container.encode(uid, forKey: .uid)
    }
    if !autocomplete.isEmpty {
      try container.encode(autocomplete, forKey: .autocomplete)
    }
    // only encode valid when false (alfred defaults missing to true)
    if !valid {
      try container.encode(valid, forKey: .valid)
    }
    if let icon = icon {
      try container.encode(icon, forKey: .icon)
    }
  }
}

public struct AlfredResultItemIcon: Codable, Sendable {
  public var type: String = ""
  public var path: String = ""

  public init(type: String = "", path: String = "") {
    self.type = type
    self.path = path
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    if !type.isEmpty {
      try container.encode(type, forKey: .type)
    }
    try container.encode(path, forKey: .path)
  }
}

// MARK: - Settings types

public struct Settings: Codable, Sendable {
  public var appFilters: [AppFilter] = []

  public init() {}
}

public struct AppFilter: Codable, Sendable {
  public var app: String = ""
  public var ignoreMenuPaths: [MenuPath] = []
  public var showDisabledMenuItems: Bool = false
  public var showAppleMenu: Bool = false
  public var cacheDuration: Double = 0
  public var disabled: Bool = false

  public init() {}
}

public struct MenuPath: Codable, Sendable {
  public var path: [String] = []

  public init() {}
  public init(path: [String]) { self.path = path }
}
