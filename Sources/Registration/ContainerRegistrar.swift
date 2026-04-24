import Foundation

enum ContainerRegistrar {

    static func register(nameLower: String, filePath: String) throws {
        var lines = try String(contentsOfFile: filePath, encoding: .utf8).components(separatedBy: "\n")

        // Insert tile builder after last TileBuilder promised() line
        if let lastTile = lines.lastIndex(where: { $0.contains("TileBuilder") && $0.contains("promised()") }) {
            lines.insert("    public var \(nameLower)TileBuilder: Factory<MicroUITileBuilder?> { promised() }", at: lastTile + 1)
        }

        // Insert screen builder after last ScreenBuilder promised() line
        if let lastScreen = lines.lastIndex(where: { $0.contains("ScreenBuilder") && $0.contains("promised()") }) {
            lines.insert("    public var \(nameLower)ScreenBuilder: Factory<MicroUIScreenBuilder?> { promised() }", at: lastScreen + 1)
        }

        // Insert navigation coordinator after last scope(.shared) + }
        if let lastScope = lines.lastIndex(where: { $0.contains("scope(.shared)") }) {
            let insertAt = lastScope + 2  // after the closing "    }"
            let navBlock = [
                "",
                "    public var \(nameLower)NavigationCoordinator: Factory<OwlsNavigationCoordinator> {",
                "        self { OwlsNavigationCoordinator() }.scope(.shared)",
                "    }",
            ]
            for (j, line) in navBlock.enumerated() {
                lines.insert(line, at: insertAt + j)
            }
        }

        try lines.joined(separator: "\n").write(toFile: filePath, atomically: true, encoding: .utf8)
    }

    // MARK: - Remove

    static func remove(nameLower: String, filePath: String) throws {
        var lines = try String(contentsOfFile: filePath, encoding: .utf8).components(separatedBy: "\n")

        // Remove tile builder line
        lines.removeAll { $0.contains("\(nameLower)TileBuilder") }

        // Remove screen builder line
        lines.removeAll { $0.contains("\(nameLower)ScreenBuilder") }

        // Remove navigation coordinator block (4 lines: blank, var, self {}, })
        if let navLine = lines.firstIndex(where: { $0.contains("\(nameLower)NavigationCoordinator") }) {
            // Check for blank line before
            let start = (navLine > 0 && lines[navLine - 1].trimmingCharacters(in: .whitespaces).isEmpty) ? navLine - 1 : navLine
            // The block is: var line, self {} line, closing }
            let end = min(start + 3, lines.count - 1)
            lines.removeSubrange(start...end)
        }

        try lines.joined(separator: "\n").write(toFile: filePath, atomically: true, encoding: .utf8)
    }
}
