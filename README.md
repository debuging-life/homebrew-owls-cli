# OwlsCLI

MicroUI module management CLI — scaffold and remove modules with a single command.

## Install

```bash
# One-line install (private repo — requires gh CLI)
gh repo clone debuging-life/owls-cli /tmp/owls-cli -- --depth 1 && bash /tmp/owls-cli/install.sh && rm -rf /tmp/owls-cli
```

**Requirements:**
- macOS 13+
- GitHub CLI (`brew install gh`)
- Authenticated (`gh auth login`)
- Access to this repo (private)

The installer:
1. Verifies GitHub authentication
2. Checks repo access
3. Downloads the pre-built binary (or builds from source)
4. Installs to `~/.owls/bin/`
5. Adds to PATH

## Usage

```bash
# Create a new module
owls-microui create Transfers

# Remove a module
owls-microui remove Transfers

# Preview without changes
owls-microui create --dry-run BillPay
owls-microui remove --dry-run BillPay

# With GitHub auth gate
owls-microui create --repo yourorg/repo Transfers

# Help
owls-microui --help
owls-microui create --help
owls-microui remove --help
```

## What `create` does

1. Scaffolds `Packages/{Name}MicroUI/` with 16 files:
   - Builder/ (Config, Router, TileBuilder, ScreenBuilder)
   - Data/ (API routes, DataSource, ServiceDispatcher)
   - Domain/ (Models, Repository)
   - Localization/ (English keys)
   - ViewModels/
   - UI/ (Screens, Views)
   - Tests/

2. Auto-registers in Container+Common.swift (DI slots)
3. Auto-registers in MicroUIBootstrap.swift (import + config)
4. Auto-updates project.pbxproj (package reference + framework link)

## What `remove` does

1. Removes DI slots from Container+Common.swift
2. Removes import + config from MicroUIBootstrap.swift
3. Removes all references from project.pbxproj
4. Deletes the module directory

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/debuging-life/owls-cli/main/uninstall.sh | bash
```

## Release

Tag a version to trigger the CI build:

```bash
git tag v2.1.0
git push origin v2.1.0
```

GitHub Actions builds the binary and attaches it to the release.

## Development

```bash
swift build          # debug build
swift build -c release  # release build
swift run owls-microui --help
```
