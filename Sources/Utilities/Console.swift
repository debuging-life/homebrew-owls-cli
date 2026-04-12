import Foundation

enum Console {

    // MARK: - Colors

    static let green = "\u{001B}[0;32m"
    static let yellow = "\u{001B}[1;33m"
    static let cyan = "\u{001B}[0;36m"
    static let red = "\u{001B}[0;31m"
    static let bold = "\u{001B}[1m"
    static let dim = "\u{001B}[2m"
    static let reset = "\u{001B}[0m"

    // MARK: - Output

    static func step(_ number: Int, of total: Int, _ message: String) {
        print("  \(cyan)[\(number)/\(total)]\(reset) \(message)")
    }

    static func success(_ message: String) {
        print("  \(green)✅ \(message)\(reset)")
    }

    static func error(_ message: String) {
        print("  \(red)✗\(reset) \(message)")
    }

    static func info(_ message: String) {
        print("  \(dim)\(message)\(reset)")
    }

    static func header(_ message: String) {
        print("\n  \(bold)\(message)\(reset)\n")
    }

    static func done(_ module: String) {
        print("""

          \(green)✅ \(module) created and fully integrated!\(reset)

          \(dim)What was done:\(reset)
            \(green)+\(reset) Scaffolded Packages/\(module)/
            \(green)+\(reset) Added DI slots to Container+Common.swift
            \(green)+\(reset) Registered in MicroUIBootstrap.swift
            \(green)+\(reset) Added package reference to Xcode project

          \(bold)Just open Xcode and build (⌘B).\(reset)

        """)
    }

    // MARK: - Prompt

    static func prompt(_ label: String, defaultValue: String) -> String {
        print("  \(yellow)\(label)\(reset) (default: \(defaultValue)): ", terminator: "")
        guard let input = readLine(), !input.isEmpty else { return defaultValue }
        return input
    }
}
