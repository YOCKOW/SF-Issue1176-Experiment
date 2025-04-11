import Foundation

public struct Thing: Encodable {
  public var nestedArray: [Thing]

  public init(_ nestedArray: [Thing] = []) {
    self.nestedArray = nestedArray
  }
}

func dive() throws {
  let encoder = JSONEncoder()
  var theThing = Thing()
  for depth in 0..<1024 {
    let encoded = String(data: try encoder.encode(theThing), encoding: .utf8)!
    print("Depth \(depth): \(encoded)')")

    theThing = Thing([theThing])
  }
}

do {
  try dive()
} catch {
  print("\n\n🛑 Error: \(error)")
}
