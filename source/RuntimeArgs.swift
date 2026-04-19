import Foundation

public struct RuntimeArgs: Sendable {
  public var query: String = ""
  public var pid: Int32 = -1
  public var reorderAppleMenuToLast: Bool = true
  public var learning: Bool = false
  public var shortcut: String = ""
  public var menuPath: [String] = []
  public var pathIndices: String = ""
  public var cachingEnabled: Bool = false
  public var cacheTimeout: Double = 0.0
  public var options: MenuGetterOptions = MenuGetterOptions()

  public init() {}
}
