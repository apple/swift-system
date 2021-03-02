import ArgumentParser

internal struct SystemSamples: ParsableCommand {
  public static var configuration = CommandConfiguration(
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
