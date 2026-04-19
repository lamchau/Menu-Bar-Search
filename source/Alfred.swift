import Foundation

public class Alfred {
  public static func preparePaths() {
    let fm = FileManager.default
    try? fm.createDirectory(atPath: data(), withIntermediateDirectories: false, attributes: nil)
    try? fm.createDirectory(
      atPath: cache(), withIntermediateDirectories: false, attributes: nil)
  }

  public static func data(path: String? = nil) -> String {
    return folder(type: "data", path: path)
  }

  public static func cache(path: String? = nil) -> String {
    return folder(type: "cache", path: path)
  }

  public static func folder(type: String, path: String? = nil) -> String {
    let base = ProcessInfo.processInfo.environment["alfred_workflow_\(type)"] ?? "."
    guard let path = path else { return base }
    return "\(base)/\(path)"
  }

  public static func env(_ name: String) -> String? {
    return ProcessInfo.processInfo.environment[name]
  }

  public var results = AlfredResultList()

  public init() {}

  public func add(_ item: AlfredResultItem) {
    results.items.append(item)
  }

  public var resultsJson: String {
    let encoder = JSONEncoder()
    guard let data = try? encoder.encode(results) else {
      return "{\"items\":[]}"
    }
    return String(data: data, encoding: .utf8) ?? "{\"items\":[]}"
  }

  public static func quit(_ title: String, subtitle: String? = nil, icon: String? = nil) -> Never {
    let a = Alfred()
    a.add(
      .with {
        $0.title = title
        $0.subtitle = subtitle ?? ""
        $0.icon = AlfredResultItemIcon(type: "", path: icon ?? "icon.png")
      })
    print(a.resultsJson)
    exit(0)
  }
}
