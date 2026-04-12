import Foundation

enum GitHubAuthChecker {

    static func verify(repo: String?) throws {
        let targetRepo = repo
            ?? ProcessInfo.processInfo.environment["OWLS_REPO"]
            ?? "debuging-life/owls-cli"

        Console.info("Verifying GitHub access...")

        // 1. Check gh CLI exists
        do {
            _ = try Shell.run("which gh")
        } catch {
            throw AuthError.ghNotInstalled
        }

        // 2. Check authenticated
        do {
            _ = try Shell.run("gh auth status 2>&1")
        } catch {
            throw AuthError.notAuthenticated
        }

        // 3. Verify repo access
        do {
            _ = try Shell.run("gh api repos/\(targetRepo) --silent 2>&1")
        } catch {
            throw AuthError.noRepoAccess(targetRepo)
        }
    }
}

// MARK: - Error

enum AuthError: LocalizedError {
    case ghNotInstalled
    case notAuthenticated
    case noRepoAccess(String)

    var errorDescription: String? {
        switch self {
        case .ghNotInstalled:
            "GitHub CLI (gh) is not installed. Install: brew install gh"
        case .notAuthenticated:
            "Not authenticated with GitHub. Run: gh auth login"
        case .noRepoAccess(let repo):
            "You don't have access to \(repo). Contact your admin."
        }
    }
}
