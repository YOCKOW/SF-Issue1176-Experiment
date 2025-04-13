import Foundation

public struct Thing: Codable, Equatable {
  public var nestedArray: [Thing]

  public init(_ nestedArray: [Thing] = []) {
    self.nestedArray = nestedArray
  }

  public var jsonWithoutFoundationEncoder: String {
    return #"{"nestedArray":\#(nestedArray.isEmpty ? "[]" : "[" + nestedArray.map { $0.jsonWithoutFoundationEncoder }.joined(separator: ",") + "]")}"#
  }
}

func dive() {
  let decoder = JSONDecoder()
  let encoder = JSONEncoder()
  var theThing = Thing()
  for depth in 0..<1024 {
    var decodeStatus = false
    var encodeStatus = false

    print("- Depth: \(depth)")

    let expectedJSON = Data(theThing.jsonWithoutFoundationEncoder.utf8)
      

    DECODING: do {
      let decoded = try decoder.decode(Thing.self, from: expectedJSON)
      if decoded == theThing {
        decodeStatus = true
        print("  * ✅ Decoding Succeeded.")
      } else {
        print("  * ❌ Decoding Error: Unmatched decoded object.")
      }
    } catch {
      print("  * ❌ Decoding Error: \(error)")
    }
    
    ENCODING: do {
      let encoded = try encoder.encode(theThing)
      if encoded == expectedJSON {
        encodeStatus = true
        print("  * ✅ Encoding Succeeded.")
      } else {
        print("  * ❌ Encoding Error: Unmatched encoded data.")
      }
    } catch {
      print("  * ❌ Encoding Error: \(error)")
    }

    guard decodeStatus || encodeStatus else {
      break
    }
    theThing = Thing([theThing])
  }
}

dive()