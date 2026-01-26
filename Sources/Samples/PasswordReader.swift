/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if !os(Windows)

import ArgumentParser
import SystemPackage

struct PasswordReader: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Securely read a password with echo disabled"
  )

  @Option(name: .shortAndLong, help: "Prompt to display")
  var prompt: String = "Password:"

  func run() throws {
    // Only works if stdin is a terminal
    guard let terminal = TerminalDescriptor(.standardInput) else {
      complain("Error: stdin is not a terminal")
      throw ExitCode.failure
    }

    // Display prompt (without newline)
    print(prompt, terminator: " ")

    // Read password with echo disabled
    let password = try terminal.withAttributes({ attrs in
      attrs.localFlags.remove(.echo)
    }) {
      readLine() ?? ""
    }

    // Print newline since echo was disabled
    print()

    // Display result (in real app, you'd validate/use the password)
    if password.isEmpty {
      print("No password entered")
    } else {
      print("Password read successfully (\(password.count) characters)")

      // Show it's actually hidden
      print("Password was: \(String(repeating: "*", count: password.count))")
    }
  }
}

#endif
