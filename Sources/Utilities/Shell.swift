import Foundation

enum Shell {
    @discardableResult
    static func run(_ command: String) throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if process.terminationStatus != 0 {
            throw ShellError.failed(code: process.terminationStatus, output: output)
        }

        return output
    }
}

enum ShellError: LocalizedError {
    case failed(code: Int32, output: String)

    var errorDescription: String? {
        switch self {
        case .failed(let code, let output):
            "Command failed (exit \(code)): \(output)"
        }
    }
}
