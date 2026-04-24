import Foundation

// MARK: - GitHub Auth Checker
//
// Public repo — no auth required. This file is kept as a no-op
// for backward compatibility with the CreateCommand.

enum GitHubAuthChecker {
    static func verify(repo: String?) throws {
        // Public repo — no verification needed
    }
}
