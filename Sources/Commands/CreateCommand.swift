import Foundation
import ArgumentParser

struct CreateCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Scaffold a new MicroUI module and register it in the project.",
        discussion: """
        Creates a complete MicroUI module with Data, Domain, UI layers,
        API routes, localization, tests, and auto-registers it in DI,
        bootstrap, and the Xcode project.

        Do NOT include "MicroUI" in the name — it is appended automatically.
        """
    )

    // MARK: - Arguments

    @Argument(help: "Feature name (e.g., Transfers, BillPay). MicroUI is appended automatically.")
    var name: String

    @Flag(name: .long, help: "Preview changes without writing any files.")
    var dryRun = false

    @Flag(name: .long, help: "Skip generating the Example/ sandbox app.")
    var noSandbox = false

    // MARK: - Validation

    func validate() throws {
        let pattern = "^[A-Z][a-zA-Z0-9]*$"
        guard name.range(of: pattern, options: .regularExpression) != nil else {
            throw ValidationError("Feature name must start with uppercase and contain only letters/digits. Got: \(name)")
        }
    }

    // MARK: - Run

    func run() throws {
        let module = "\(name)MicroUI"
        let nameLower = name.lowercased()

        // Resolve project root (walk up from CWD looking for .xcodeproj)
        let projectRoot = try resolveProjectRoot()

        let containerFile = "\(projectRoot)/Packages/MicroUICore/Sources/MicroUICore/DI/Container+Common.swift"
        let bootstrapFile = "\(projectRoot)/micruiachitecture/MicroUIBootstrap.swift"
        let pbxprojFile = "\(projectRoot)/micruiachitecture.xcodeproj/project.pbxproj"
        let pkgDir = "\(projectRoot)/Packages/\(module)"

        // Pre-flight checks
        try preflight(pkgDir: pkgDir, nameLower: nameLower, module: module,
                      containerFile: containerFile, bootstrapFile: bootstrapFile)

        Console.header("Creating MicroUI module: \(Console.cyan)\(module)\(Console.reset)")

        // Interactive prompts
        let gitName = (try? Shell.run("git config user.name")) ?? "Developer"
        let gitEmail = (try? Shell.run("git config user.email")) ?? "dev@example.com"

        let authorName = Console.prompt("Author name", defaultValue: gitName)
        let authorEmail = Console.prompt("Author email", defaultValue: gitEmail)
        let icon = Console.prompt("SF Symbol icon", defaultValue: "square.grid.2x2")
        let tileDesc = Console.prompt("Tile description", defaultValue: "View \(name)")

        let context = Templates.Context(
            name: name,
            authorName: authorName,
            authorEmail: authorEmail,
            icon: icon,
            tileDesc: tileDesc
        )

        print()

        // Dry run
        if dryRun {
            printDryRun(context, containerFile: containerFile, bootstrapFile: bootstrapFile)
            return
        }

        // Step 1: Scaffold
        Console.step(1, of: 4, "Scaffolding module files...")
        let scaffolder = ModuleScaffolder(projectRoot: projectRoot, context: context, includeSandbox: !noSandbox)
        try scaffolder.scaffold()

        // Step 2: Container
        Console.step(2, of: 4, "Registering DI slots in Container+Common.swift...")
        try ContainerRegistrar.register(nameLower: nameLower, filePath: containerFile)

        // Step 3: Bootstrap
        Console.step(3, of: 4, "Adding import + config to MicroUIBootstrap.swift...")
        try BootstrapRegistrar.register(module: module, filePath: bootstrapFile)

        // Step 4: Xcode project
        Console.step(4, of: 4, "Updating Xcode project.pbxproj...")
        try XcodeProjectRegistrar.register(module: module, filePath: pbxprojFile)

        Console.done(module)
    }

    // MARK: - Project Root

    private func resolveProjectRoot() throws -> String {
        var dir = FileManager.default.currentDirectoryPath

        for _ in 0..<10 {
            let xcodeproj = try? FileManager.default.contentsOfDirectory(atPath: dir)
                .first(where: { $0.hasSuffix(".xcodeproj") })

            if xcodeproj != nil { return dir }

            let parent = (dir as NSString).deletingLastPathComponent
            if parent == dir { break }
            dir = parent
        }

        throw CleanExit.message("Could not find .xcodeproj in current directory or parents.")
    }

    // MARK: - Pre-flight

    private func preflight(pkgDir: String, nameLower: String, module: String,
                           containerFile: String, bootstrapFile: String) throws {
        var errors: [String] = []

        if FileManager.default.fileExists(atPath: pkgDir) {
            errors.append("Directory \(pkgDir) already exists")
        }
        if !FileManager.default.fileExists(atPath: containerFile) {
            errors.append("Container+Common.swift not found")
        }
        if !FileManager.default.fileExists(atPath: bootstrapFile) {
            errors.append("MicroUIBootstrap.swift not found")
        }

        if FileManager.default.fileExists(atPath: containerFile),
           let content = try? String(contentsOfFile: containerFile, encoding: .utf8),
           content.contains("\(nameLower)TileBuilder") {
            errors.append("DI slots for '\(nameLower)' already exist")
        }

        if FileManager.default.fileExists(atPath: bootstrapFile),
           let content = try? String(contentsOfFile: bootstrapFile, encoding: .utf8),
           content.contains("import \(module)") {
            errors.append("\(module) already imported in bootstrap")
        }

        if !errors.isEmpty {
            print("\n  \(Console.red)Pre-flight checks failed:\(Console.reset)")
            errors.forEach { Console.error($0) }
            print()
            throw ExitCode.failure
        }
    }

    // MARK: - Dry Run

    private func printDryRun(_ c: Templates.Context, containerFile: String, bootstrapFile: String) {
        print("""
          \(Console.yellow)[DRY RUN]\(Console.reset) Would perform the following:

          \(Console.cyan)1.\(Console.reset) Create Packages/\(c.module)/
             └── 16 files (Package.swift, Builder/, Data/, Domain/, Localization/, ViewModels/, UI/, Tests/)

          \(Console.cyan)2.\(Console.reset) Update Container+Common.swift:
             + public var \(c.nameLower)TileBuilder
             + public var \(c.nameLower)ScreenBuilder
             + public var \(c.nameLower)NavigationCoordinator

          \(Console.cyan)3.\(Console.reset) Update MicroUIBootstrap.swift:
             + import \(c.module)
             + \(c.module)Config()

          \(Console.cyan)4.\(Console.reset) Update project.pbxproj:
             + XCLocalSwiftPackageReference
             + XCSwiftPackageProductDependency
             + PBXBuildFile + Framework link

        """)
    }
}
