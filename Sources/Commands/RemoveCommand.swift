import Foundation
import ArgumentParser

struct RemoveCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove a MicroUI module and unregister it from the project.",
        discussion: """
        Removes the module directory, DI slots, bootstrap registration,
        and Xcode project references. Requires confirmation.

        Do NOT include "MicroUI" in the name — it is appended automatically.
        """
    )

    // MARK: - Arguments

    @Argument(help: "Feature name to remove (e.g., Transfers). MicroUI is appended automatically.")
    var name: String

    @Flag(name: .long, help: "Preview what would be removed without deleting anything.")
    var dryRun = false

    @Flag(name: .long, help: "Skip confirmation prompt.")
    var force = false

    // MARK: - Run

    func run() throws {
        let module = "\(name)MicroUI"
        let nameLower = name.lowercased()

        let projectRoot = try resolveProjectRoot()

        let containerFile = "\(projectRoot)/Packages/MicroUICore/Sources/MicroUICore/DI/Container+Common.swift"
        let bootstrapFile = "\(projectRoot)/micruiachitecture/MicroUIBootstrap.swift"
        let pbxprojFile = "\(projectRoot)/micruiachitecture.xcodeproj/project.pbxproj"
        let pkgDir = "\(projectRoot)/Packages/\(module)"

        // Check module exists
        guard FileManager.default.fileExists(atPath: pkgDir) else {
            Console.error("Module \(module) not found at \(pkgDir)")
            throw ExitCode.failure
        }

        // Count files
        let fileCount = countFiles(in: pkgDir)

        // Show what will be removed
        Console.header("Removing MicroUI module: \(Console.red)\(module)\(Console.reset)")

        print("""
          \(Console.yellow)⚠️  This will remove:\(Console.reset)
            \(Console.red)-\(Console.reset) Packages/\(module)/ (\(fileCount) files)
            \(Console.red)-\(Console.reset) DI slots: \(nameLower)TileBuilder, \(nameLower)ScreenBuilder, \(nameLower)NavigationCoordinator
            \(Console.red)-\(Console.reset) Import + config in MicroUIBootstrap.swift
            \(Console.red)-\(Console.reset) Package reference in project.pbxproj

        """)

        if dryRun {
            print("  \(Console.yellow)[DRY RUN]\(Console.reset) No files were modified.\n")
            return
        }

        // Confirmation
        if !force {
            print("  Type \"\(Console.bold)\(module)\(Console.reset)\" to confirm: ", terminator: "")
            guard let input = readLine(), input == module else {
                print("\n  \(Console.dim)Cancelled.\(Console.reset)\n")
                return
            }
            print()
        }

        // Step 1: Unregister from Container
        Console.step(1, of: 4, "Removing DI slots from Container+Common.swift...")
        try ContainerRegistrar.remove(nameLower: nameLower, filePath: containerFile)

        // Step 2: Unregister from Bootstrap
        Console.step(2, of: 4, "Removing import + config from MicroUIBootstrap.swift...")
        try BootstrapRegistrar.remove(module: module, filePath: bootstrapFile)

        // Step 3: Unregister from Xcode project
        Console.step(3, of: 4, "Removing references from project.pbxproj...")
        try XcodeProjectRegistrar.remove(module: module, filePath: pbxprojFile)

        // Step 4: Delete directory
        Console.step(4, of: 4, "Deleting Packages/\(module)/...")
        try FileManager.default.removeItem(atPath: pkgDir)

        print("""

          \(Console.green)✅ \(module) has been completely removed.\(Console.reset)

          \(Console.bold)Open Xcode and build (⌘B) to verify.\(Console.reset)

        """)
    }

    // MARK: - Helpers

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

    private func countFiles(in path: String) -> Int {
        let enumerator = FileManager.default.enumerator(atPath: path)
        var count = 0
        while let file = enumerator?.nextObject() as? String {
            if !file.hasPrefix(".") { count += 1 }
        }
        return count
    }
}
