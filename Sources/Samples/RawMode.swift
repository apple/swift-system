/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if !os(Windows)

import ArgumentParser
import SystemPackage

struct RawMode: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Demonstrate raw mode terminal input (character-at-a-time)"
  )

  func run() throws {
    guard let terminal = TerminalDescriptor(.standardInput) else {
      complain("Error: stdin is not a terminal")
      throw ExitCode.failure
    }

    print("Raw Mode Key Reader")
    print("==================")
    print()
    print("In raw mode, characters are available immediately without")
    print("waiting for Enter. Press 'q' to quit.")
    print()
    print("Try pressing keys, arrow keys, or special keys...")
    print()

    try terminal.withRawMode {
      var buffer = [UInt8](repeating: 0, count: 16)

      while true {
        // Read a single character (or escape sequence)
        let bytesRead = try buffer.withUnsafeMutableBytes { bufferPtr in
          try FileDescriptor.standardInput.read(into: bufferPtr)
        }

        guard bytesRead > 0 else {
          continue
        }

        let bytes = Array(buffer[..<bytesRead])

        // Check for 'q' to quit
        if bytesRead == 1 && bytes[0] == UInt8(ascii: "q") {
          print("\rQuitting...")
          break
        }

        // Display what was read
        print("\rRead \(bytesRead) byte(s): ", terminator: "")

        // Show bytes in hex
        for byte in bytes {
          print(String(format: "0x%02X ", byte), terminator: "")
        }

        // Try to show as character if printable
        if bytesRead == 1 {
          // Show printable ASCII characters (space through ~)
          if bytes[0] >= 0x20 && bytes[0] <= 0x7E {
            let char = Character(UnicodeScalar(bytes[0]))
            print(" ('\(char)')", terminator: "")
          }
        }

        // Recognize common escape sequences
        if bytesRead == 3 && bytes[0] == 0x1B && bytes[1] == 0x5B {
          switch bytes[2] {
          case 0x41: print(" [UP ARROW]", terminator: "")
          case 0x42: print(" [DOWN ARROW]", terminator: "")
          case 0x43: print(" [RIGHT ARROW]", terminator: "")
          case 0x44: print(" [LEFT ARROW]", terminator: "")
          default: break
          }
        } else if bytesRead == 1 {
          switch bytes[0] {
          case 0x1B: print(" [ESC]", terminator: "")
          case 0x0D: print(" [ENTER]", terminator: "")
          case 0x7F: print(" [DELETE]", terminator: "")
          case 0x09: print(" [TAB]", terminator: "")
          default: break
          }
        }

        // Clear to end of line and move cursor back
        print("\u{1B}[K", terminator: "")
      }
    }

    print()
    print("Terminal restored to normal mode.")
  }
}

#endif
