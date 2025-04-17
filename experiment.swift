import Foundation

let N = 512

enum _ExecMode: String, Sendable {
  case run
  case testDeepType = "--test-deep-type"
  case testDecoding = "--test-decoding"
  case testEncoding = "--test-encoding"
}

print("~~~~~~~~~~ INFO ~~~~~~~~~~")

let execName = CommandLine.arguments[0]
print("Executable Name: \(execName)")

let curDirURL = URL.currentDirectory()
print("Current Directory: \(curDirURL)")

let execURL = URL(fileURLWithFileSystemRepresentation: execName, isDirectory: false, relativeTo: curDirURL)
print("Executable Path: \(execURL.path)")

let mode = ({ () -> _ExecMode in
  if CommandLine.arguments.count > 1 {
    guard let mode = _ExecMode(rawValue: CommandLine.arguments[1]) else {
      fatalError("Unexpected mode: \(CommandLine.arguments[1])")
    }
    return mode
  }
  return .run
})()
print("Mode: \(mode.rawValue)")

print("~~~~~~~~~~~~~~~~~~~~~~~~~~") // End of INFO
print("")


public struct Thing: Codable, Equatable {
  public var nestedArray: [Thing]

  public init(_ nestedArray: [Thing] = []) {
    self.nestedArray = nestedArray
  }

  public var depth: Int {
    var depth = 0
    var current: Thing = self
    while let next = current.nestedArray.first {
      depth += 1
      current = next
    }
    return depth
  }
}

func generateJSON(depth: Int) -> Data {
  let head = #"{"nestedArray":["#
  let tail = #"]}"#
  var json = ""
  for _ in 0...depth {
    json = head + json + tail
  }
  return Data(json.utf8)
}

func testDeepType() {
  print("----- Testing Deep Type -----")

  var theThing = Thing()
  for depth in 0..<N {
    print("Depth \(depth): " + (theThing.depth == depth ? " ✅" : " ❌"))
    theThing = Thing([theThing])
  }
}

func testDecoding() {
  print("----- Testing Decoding -----")

  let decoder = JSONDecoder()
  for depth in 0..<N {
    let json = generateJSON(depth: depth)
    print("- Depth \(depth)")
    do {
      let decoded = try decoder.decode(Thing.self, from: json)
      if decoded.depth == depth {
        print("  * ✅ Decoding Succeeded.")
      } else {
        print("  * ❌ Decoding Error: Unmatched decoded object.")
      }
    } catch {
      print("  * ❌ Decoding Error: \(error)")
      break
    }
  }
}

func testEncoding() {
  print("----- Testing Encoding -----")

  let encoder = JSONEncoder()
  var theThing = Thing()
  for depth in 0..<N {
    let expectedJSON = generateJSON(depth: depth)
    print("- Depth \(depth)")
    do {
      let encoded = try encoder.encode(theThing)
      if encoded == expectedJSON {
        print("  * ✅ Encoding Succeeded.")
      } else {
        print("  * ❌ Encoding Error: Unmatched encoded data.")
      }
    } catch {
      print("  * ❌ Encoding Error: \(error)")
      break
    }
    theThing = Thing([theThing])
  }
}

func run() async throws {
  let modes: [_ExecMode] = [.testDeepType, .testDecoding, .testEncoding]
  let results = try await withThrowingTaskGroup(of: (mode: _ExecMode, result: (exitCode: Int32, stdout: String, stderr: String)).self) { group in
    for mode in modes {
      group.addTask {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()
        process.executableURL = execURL
        process.arguments = [mode.rawValue]
        process.standardOutput = stdout
        process.standardError = stderr
        try process.run()
        process.waitUntilExit()
        let status = process.terminationStatus
        let stdoutString = try stdout.fileHandleForReading.readToEnd().flatMap({ String(data: $0, encoding: .utf8) }) ?? ""
        let stderrString = try stderr.fileHandleForReading.readToEnd().flatMap({ String(data: $0, encoding: .utf8) }) ?? ""
        return (mode, (status, stdoutString, stderrString))
      }
    }
    return try await group.reduce(into: [:]) { $0[$1.mode] = $1.result }
  }

  for mode in modes {
    if let result = results[mode] {
      print("========== \(mode.rawValue) ==========")
      print("Exit Code: \(result.exitCode)\n")
      print("[Standard Output]\n\(result.stdout)\n")
      print("[Standard Error]\n\(result.stderr)\n")
    }
  }
}

switch mode {
case .run:
  try await run()
case .testDeepType:
  testDeepType()
case .testDecoding:
  testDecoding()
case .testEncoding:
  testEncoding()
}
