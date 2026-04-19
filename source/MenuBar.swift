//
//  MenuBar.swift
//
//
//  Created by Benzi  on 20/12/2022.
//

import Cocoa
import Foundation

public class MenuBar {
  public var menuBar: AXUIElement?
  public let initState: AXError

  public init(for app: NSRunningApplication) {
    let axApp = AXUIElementCreateApplication(app.processIdentifier)
    var menuBarValue: CFTypeRef?
    self.initState = AXUIElementCopyAttributeValue(
      axApp, kAXMenuBarAttribute as CFString, &menuBarValue)
    if self.initState == .success, let value = menuBarValue {
      self.menuBar = unsafeDowncast(value as AnyObject, to: AXUIElement.self)
    }
  }

  public func load(_ options: MenuGetterOptions) async -> [MenuItem] {
    guard let menuBar = self.menuBar else {
      return []
    }
    return await MenuGetter().load(menuBar: menuBar, options: options)
  }

}
