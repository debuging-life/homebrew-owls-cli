import Foundation

enum BootstrapRegistrar {

    static func register(module: String, filePath: String) throws {
        var lines = try String(contentsOfFile: filePath, encoding: .utf8).components(separatedBy: "\n")

        // Add import after last import line
        if let lastImport = lines.lastIndex(where: { $0.hasPrefix("import ") }) {
            lines.insert("import \(module)", at: lastImport + 1)
        }

        // Find the ] that closes the modules array
        if let bracketClose = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "]" }) {
            // Add trailing comma to current last entry if missing
            let prevLine = bracketClose - 1
            if prevLine >= 0, !lines[prevLine].trimmingCharacters(in: .whitespaces).hasSuffix(",") {
                lines[prevLine] = lines[prevLine] + ","
            }
            // Insert new config before ]
            lines.insert("        \(module)Config()", at: bracketClose)
        }

        try lines.joined(separator: "\n").write(toFile: filePath, atomically: true, encoding: .utf8)
    }

    // MARK: - Remove

    static func remove(module: String, filePath: String) throws {
        var lines = try String(contentsOfFile: filePath, encoding: .utf8).components(separatedBy: "\n")

        // Remove import line
        lines.removeAll { $0.trimmingCharacters(in: .whitespaces) == "import \(module)" }

        // Remove config line
        lines.removeAll { $0.contains("\(module)Config()") }

        // Fix trailing comma on new last entry if needed
        if let bracketClose = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "]" }) {
            let prevLine = bracketClose - 1
            if prevLine >= 0 {
                // Remove trailing comma from new last entry
                let trimmed = lines[prevLine].trimmingCharacters(in: .whitespaces)
                if trimmed.hasSuffix(",") && trimmed.contains("Config()") {
                    lines[prevLine] = String(lines[prevLine].dropLast())
                }
            }
        }

        try lines.joined(separator: "\n").write(toFile: filePath, atomically: true, encoding: .utf8)
    }
}
