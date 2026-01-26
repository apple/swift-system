/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import ArgumentParser

struct SystemSamples: ParsableCommand {

  @available(System 99, *)
  static var configuration = CommandConfiguration(
    commandName: "system-samples",
    abstract: "A collection of little programs exercising some System features.",
    subcommands: [
      Resolve.self,
      ReverseResolve.self,
      Connect.self,
      Listen.self,
    ])
}

disableBuffering()
SystemSamples.main()
