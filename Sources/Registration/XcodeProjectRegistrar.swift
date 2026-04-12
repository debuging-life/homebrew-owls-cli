import Foundation

enum XcodeProjectRegistrar {

    static func register(module: String, filePath: String) throws {
        let buildUUID = UUIDGenerator.generate(seed: "\(module)_build")
        let pkgRefUUID = UUIDGenerator.generate(seed: "\(module)_pkgref")
        let prodDepUUID = UUIDGenerator.generate(seed: "\(module)_proddep")

        var lines = try String(contentsOfFile: filePath, encoding: .utf8).components(separatedBy: "\n")

        // Collect insertions as (lineIndex, [linesToInsert])
        var inserts: [(Int, [String])] = []

        for (i, line) in lines.enumerated() {
            // 1. PBXBuildFile — before end marker
            if line.contains("/* End PBXBuildFile section */") {
                inserts.append((i, [
                    "\t\t\(buildUUID) /* \(module) in Frameworks */ = {isa = PBXBuildFile; productRef = \(prodDepUUID) /* \(module) */; };"
                ]))
            }

            // 5. XCLocalSwiftPackageReference — before end marker
            if line.contains("/* End XCLocalSwiftPackageReference section */") {
                inserts.append((i, [
                    "\t\t\(pkgRefUUID) /* XCLocalSwiftPackageReference \"Packages/\(module)\" */ = {",
                    "\t\t\tisa = XCLocalSwiftPackageReference;",
                    "\t\t\trelativePath = Packages/\(module);",
                    "\t\t};",
                ]))
            }

            // 6. XCSwiftPackageProductDependency — before end marker
            if line.contains("/* End XCSwiftPackageProductDependency section */") {
                inserts.append((i, [
                    "\t\t\(prodDepUUID) /* \(module) */ = {",
                    "\t\t\tisa = XCSwiftPackageProductDependency;",
                    "\t\t\tproductName = \(module);",
                    "\t\t};",
                ]))
            }
        }

        // 2. Framework files — after last "in Frameworks" line
        if let lastFW = lines.lastIndex(where: { $0.contains("in Frameworks */") }) {
            inserts.append((lastFW + 1, [
                "\t\t\t\t\(buildUUID) /* \(module) in Frameworks */,"
            ]))
        }

        // 3. packageProductDependencies — before ); of that array
        if let ppdStart = lines.firstIndex(where: { $0.contains("packageProductDependencies") && $0.contains("=") }) {
            let searchFrom = ppdStart
            if let ppdClose = lines[searchFrom...].firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == ");" }) {
                inserts.append((ppdClose, [
                    "\t\t\t\t\(prodDepUUID) /* \(module) */,"
                ]))
            }
        }

        // 4. packageReferences — before ); of that array
        if let prStart = lines.firstIndex(where: { $0.contains("packageReferences") && $0.contains("=") }) {
            let searchFrom = prStart
            if let prClose = lines[searchFrom...].firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == ");" }) {
                inserts.append((prClose, [
                    "\t\t\t\t\(pkgRefUUID) /* XCLocalSwiftPackageReference \"Packages/\(module)\" */,"
                ]))
            }
        }

        // Apply from bottom to top
        for (lineIdx, newLines) in inserts.sorted(by: { $0.0 > $1.0 }) {
            for newLine in newLines.reversed() {
                lines.insert(newLine, at: lineIdx)
            }
        }

        try lines.joined(separator: "\n").write(toFile: filePath, atomically: true, encoding: .utf8)
    }

    // MARK: - Remove

    static func remove(module: String, filePath: String) throws {
        var lines = try String(contentsOfFile: filePath, encoding: .utf8).components(separatedBy: "\n")

        // Remove all lines containing the module name
        lines.removeAll { line in
            line.contains("/* \(module) in Frameworks */") ||
            line.contains("/* \(module) */,") ||
            line.contains("/* \(module) */;") ||
            line.contains("/* \(module) */ = {") ||
            line.contains("Packages/\(module)\"") ||
            line.contains("Packages/\(module);") ||
            line.contains("productName = \(module);")
        }

        // Clean up any XCLocalSwiftPackageReference block remnants
        // Look for orphaned isa/};  lines by checking for empty blocks
        var cleaned: [String] = []
        var i = 0
        while i < lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)

            // Skip orphaned "isa = XCLocalSwiftPackageReference;" or "isa = XCSwiftPackageProductDependency;"
            // These would be left after removing the header and relativePath/productName lines
            if trimmed == "isa = XCLocalSwiftPackageReference;" || trimmed == "isa = XCSwiftPackageProductDependency;" {
                // Check if previous line is a block opener we already removed
                // and next line is "};" — skip both
                if i + 1 < lines.count && lines[i + 1].trimmingCharacters(in: .whitespaces) == "};" {
                    i += 2 // skip isa line and closing };
                    continue
                }
            }

            cleaned.append(lines[i])
            i += 1
        }

        try cleaned.joined(separator: "\n").write(toFile: filePath, atomically: true, encoding: .utf8)
    }
}
