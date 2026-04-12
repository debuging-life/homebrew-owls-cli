import ArgumentParser

struct OwlsCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create-microui",
        abstract: "MicroUI module management CLI.",
        version: "2.1.0",
        subcommands: [CreateCommand.self, RemoveCommand.self],
        defaultSubcommand: CreateCommand.self
    )
}

OwlsCLI.main()
