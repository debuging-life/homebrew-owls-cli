# OwlsCLI (`owls-microui`)

Compiled Swift CLI for scaffolding and removing MicroUI modules in a Swift Package Manager–based iOS project.

> Distributed as a Homebrew binary. Source code never exposed to end users.

## Install

```bash
brew install debuging-life/owls-cli/owls-microui
```

That's it. Public repo, no auth needed.

**Requirements:** macOS 13+

## Usage

```bash
owls-microui create Transfers              # scaffold + auto-register + Example app
owls-microui create Transfers --no-sandbox # skip Example/ sandbox app
owls-microui remove Transfers              # clean removal (asks for confirmation)
owls-microui create --dry-run BillPay      # preview without writing
owls-microui remove --dry-run BillPay      # preview without deleting
owls-microui --help
```

Run from anywhere inside a MicroUI project — the CLI walks up to find `.xcodeproj`.

## Update

```bash
brew upgrade owls-microui
```

If `brew upgrade` says "already installed" but a newer version exists, your local tap cache is stale:

```bash
(cd "$(brew --repository debuging-life/owls-cli)" && git pull) && brew upgrade owls-microui
```

To make this automatic forever:
```bash
echo 'export HOMEBREW_AUTO_UPDATE_SECS=0' >> ~/.zshrc
source ~/.zshrc
```

## Uninstall

```bash
brew uninstall owls-microui
brew untap debuging-life/owls-cli
```

---

## What `create` does

Running `owls-microui create Transfers` does **9 things automatically** — zero manual setup.

### 1. Scaffolds full module structure

```
Packages/TransfersMicroUI/
├── Package.swift                              ← resources include Mocks/JSON
├── Sources/TransfersMicroUI/
│   ├── Builder/
│   │   ├── TransfersMicroUIConfig.swift       ← registers tile + screen + mocks + deeplink
│   │   ├── TransfersMicroUIRouter.swift        ← typed OwlsRouter enum
│   │   ├── TransfersMicroUITileBuilder.swift   ← embeddable widget
│   │   ├── TransfersMicroUIScreenBuilder.swift ← full screen
│   │   └── TransfersMicroUIDeepLinkHandler.swift
│   ├── Data/
│   │   ├── TransfersAPI.swift                 ← OwlsAPIRoute enum
│   │   ├── TransfersMicroUIDataSource.swift   ← live + mock impls
│   │   └── TransfersMicroUIServiceDispatcher.swift
│   ├── Domain/
│   │   ├── Models/TransfersItem.swift
│   │   └── TransfersMicroUIRepository.swift
│   ├── Localization/
│   │   └── TransfersLocalizedString.swift     ← English keys
│   ├── Mocks/
│   │   ├── TransfersMicroUIMockProvider.swift ← uses route: TransfersAPI.list
│   │   └── JSON/
│   │       ├── transfersSuccess.json
│   │       ├── transfersEmpty.json
│   │       └── transfersFailure.json
│   ├── ViewModels/
│   │   └── TransfersMicroUIViewModel.swift
│   └── UI/
│       ├── Screens/
│       │   ├── TransfersMicroUIView.swift     ← list (with sheet + fullscreen)
│       │   ├── TransfersDetailView.swift      ← push destination
│       │   └── TransfersCreateSheet.swift     ← .sheet form
│       └── Views/
│           └── TransfersTileView.swift        ← reusable widget
├── Example/                                   ← NEW: standalone sandbox app
│   ├── TransfersExampleApp.xcodeproj          ← open this to run module alone
│   └── TransfersExampleApp/
│       ├── TransfersExampleApp.swift          ← @main entry
│       ├── ExampleBootstrap.swift             ← stubs + mock setup
│       └── Assets.xcassets/
└── Tests/TransfersMicroUITests/
    └── TransfersMicroUIViewModelTests.swift   ← 3 starter tests
```

### 2. Generates `TransfersAPI` route enum

```swift
enum TransfersAPI: OwlsAPIRoute {
    case list
    case detail(id: String)
    case create(TransfersCreateRequest)
    case update(id: String, TransfersUpdateRequest)
    case delete(id: String)

    var path: String { "/v1/transfers" }
    var method: HTTPMethod { ... }
    var body: Data? { ... }
}
```

### 3. Generates `TransfersMockProvider` + 3 sample JSON files

References the API route enum (single source of truth):

```swift
public struct TransfersMicroUIMockProvider: OwlsMockProvider {
    public func mockItems() -> [OwlsMockItem] {
        let listRoute = TransfersAPI.list  // ← endpoint + method extracted automatically

        return [
            OwlsMockItem(
                id: "transfers.list.success",
                name: "Transfers — Success (3 items)",
                route: listRoute,
                jsonFilename: "transfersSuccess.json",
                bundle: .module,
                category: .success
            ),
            // ... empty + failure
        ]
    }
}
```

These mocks appear automatically in the **Debug Drawer** (floating 🐛 button in DEBUG builds).

### 4. Generates `TransfersLocalizedString` with English keys

```swift
enum TransfersStrings {
    static var screenTitle: String {
        owlsLocalized("transfers.title", comment: "Transfers")
    }
    // ... loadingMessage, retryButton, emptyTitle, errorTitle, etc.
}
```

### 5. Generates test target with starter tests

```swift
@Suite("TransfersMicroUI ViewModel Tests")
struct TransfersMicroUIViewModelTests {
    struct StubRepository: TransfersRepository { ... }

    @Test("Load items successfully") func loadItems() async { ... }
    @Test("Load items failure shows error") func loadItemsFailure() async { ... }
    @Test("Delete item removes from list") func deleteItem() async { ... }
}
```

### 6. Adds DI slots to `Container+Common.swift`

```swift
public var transfersTileBuilder: Factory<MicroUITileBuilder?> { promised() }
public var transfersScreenBuilder: Factory<MicroUIScreenBuilder?> { promised() }
public var transfersNavigationCoordinator: Factory<OwlsNavigationCoordinator> {
    self { OwlsNavigationCoordinator() }.scope(.shared)
}
```

### 7. Adds import + config to `MicroUIBootstrap.swift`

```swift
import TransfersMicroUI

private static let modules: [MicroUIRegistration] = [
    // ... existing modules
    TransfersMicroUIConfig(),
]
```

### 8. Updates Xcode `project.pbxproj`

- `XCLocalSwiftPackageReference` for the new local package
- `XCSwiftPackageProductDependency`
- `PBXBuildFile` + framework link

After running, just **open Xcode and build** — the new module shows up registered, mockable in the Debug Drawer, and ready to develop.

---

## What `remove` does

Running `owls-microui remove Transfers`:

1. Removes DI slots from `Container+Common.swift`
2. Removes `import TransfersMicroUI` + `TransfersMicroUIConfig()` from bootstrap
3. Removes all references from `project.pbxproj`
4. Deletes the `Packages/TransfersMicroUI/` directory

**Safety:** asks you to type the module name to confirm.

```bash
owls-microui remove Transfers --force      # skip confirmation
owls-microui remove Transfers --dry-run    # preview only
```

---

## Mock Data System

Every module generated with the CLI is **immediately mockable** via the Debug Drawer in the host app.

### How it works

```
Frontend dev runs `owls-microui create Transfers`
    ↓
Module gets 3 sample JSONs out of the box (success/empty/failure)
    ↓
App boots → mock provider auto-registered (DEBUG only)
    ↓
Floating 🐛 button appears bottom-right
    ↓
Tap → Debug Drawer opens → toggle "Transfers Success"
    ↓
TransfersService.fetchTransfers() called
    ↓
OwlsBaseService detects mock → returns JSON instead of network
    ↓
UI shows mock data immediately — no backend needed
```

### Adding more mocks to a module

1. Drop a JSON file in `Packages/TransfersMicroUI/Sources/TransfersMicroUI/Mocks/JSON/`
2. Append an `OwlsMockItem` in `TransfersMicroUIMockProvider.swift`:

```swift
OwlsMockItem(
    id: "transfers.list.500items",
    name: "Transfers — 500 items (load test)",
    module: moduleName,
    route: TransfersAPI.list,
    jsonFilename: "transfersHuge.json",
    bundle: .module,
    category: .edgeCase
)
```

3. Done — appears in Debug Drawer next launch.

### Categories (color-coded badges)

- `.success` → green
- `.empty` → blue
- `.failure` → red
- `.edgeCase` → orange

---

## Example Sandbox Apps

Every new module gets an **Example/** folder containing a standalone iOS app that runs **just that module** — no main app, no other modules, no login. Mocks pre-enabled.

### How to use

```bash
# After creating a module
open Packages/TransfersMicroUI/Example/TransfersExampleApp.xcodeproj

# In Xcode, hit ⌘R — Transfers module launches alone
```

### What's inside the Example folder

```
Example/
├── TransfersExampleApp.xcodeproj            ← references parent SPM package via ../
└── TransfersExampleApp/
    ├── TransfersExampleApp.swift            ← @main App
    ├── ExampleBootstrap.swift               ← minimal DI + stubs + mock setup
    └── Assets.xcassets/
        ├── AccentColor.colorset/
        └── AppIcon.appiconset/
```

### How it preserves the "no module imports another" rule

The Example app is a **host** — like the main app — that imports specific modules and registers them. The module's own source code stays pure.

For cross-module DI slots the focused module uses, the Example app registers stubs via `OwlsStubBuilders` (defined in MicroUICore):

```swift
// Inside ExampleBootstrap.swift
Container.shared.profileTileBuilder.register {
    OwlsStubTileBuilder(label: "Profile Tile")  // dashed-border placeholder
}
Container.shared.authTokenProvider.register {
    OwlsStubAuthTokenProvider()  // returns dummy token, OwlsBaseService works
}
```

To swap a stub for a **real module** (integration mode):

1. Add the other module's SPM package to the Example xcodeproj
2. Uncomment its import + registration in `ExampleBootstrap.swift`

```swift
// import FeatureProfileMicroUI
// FeatureProfileMicroUIConfig().registerMicroUI()
```

### Skipping Example app generation

Use `--no-sandbox` if you don't need the standalone app:

```bash
owls-microui create Transfers --no-sandbox
```

---

## Architecture Patterns Generated

Every new module includes working examples of:

| Pattern | Where |
|---|---|
| **Push navigation** | List view → DetailView via `path.append(Router.detail(item))` |
| **Sheet presentation** | Toolbar `+` → CreateSheet via `.sheet(isPresented:)` |
| **Fullscreen presentation** | Coordinator-based presentation from dashboard |
| **Pagination** | `OwlsPaginator` for infinite scroll |
| **API routes** | Typed enum conforming to `OwlsAPIRoute` |
| **DI registration** | Tile + Screen + Navigation Coordinator slots |
| **Deep linking** | Module-specific URL handler |
| **Localization** | Server-driven translations with English fallback |
| **Mock data** | Toggleable in Debug Drawer (DEBUG only) |
| **Error handling** | Loading / empty / error states via `OwlsLoadingView`, `OwlsEmptyState` |
| **Testing** | Stub repository + 3 starter tests |
| **Sandbox** | Standalone Example xcodeproj for isolated module runs |

---

## Development (for CLI maintainers)

```bash
swift build              # debug build
swift build -c release   # release build
swift run owls-microui --help
```

### Release a new version

```bash
git tag v2.X.0
git push origin v2.X.0
```

GitHub Actions:
1. Builds binary for `darwin-arm64` + `darwin-x86_64`
2. Creates a GitHub Release with binaries
3. Updates the Formula SHA256 in this repo automatically

Users get the new version with `brew upgrade owls-microui`.

---

## Repository Structure

```
homebrew-owls-cli/
├── Package.swift                 ← SPM executable definition
├── Formula/
│   └── owls-microui.rb           ← Homebrew formula (auto-updated by CI)
├── Sources/
│   ├── main.swift                ← entry point, subcommand routing
│   ├── Commands/
│   │   ├── CreateCommand.swift   ← `create` subcommand
│   │   └── RemoveCommand.swift   ← `remove` subcommand
│   ├── Generator/
│   │   ├── ModuleScaffolder.swift ← creates dirs + writes files
│   │   └── Templates.swift       ← all source code templates
│   ├── Registration/
│   │   ├── ContainerRegistrar.swift   ← modifies Container+Common.swift
│   │   ├── BootstrapRegistrar.swift   ← modifies MicroUIBootstrap.swift
│   │   └── XcodeProjectRegistrar.swift ← modifies project.pbxproj
│   ├── Auth/
│   │   └── GitHubAuthChecker.swift    ← (no-op — repo is public)
│   └── Utilities/
│       ├── Console.swift         ← ANSI colors + readLine prompts
│       ├── Shell.swift           ← Process wrapper
│       └── UUIDGenerator.swift   ← deterministic MD5 UUIDs for pbxproj
└── .github/workflows/
    └── release.yml               ← CI: build, release, update formula
```

---

## Related Repos

- **App Architecture:** [debuging-life/loudowls-microuiarchitecture](https://github.com/debuging-life/loudowls-microuiarchitecture) — Reference HooTales app demonstrating the architecture
