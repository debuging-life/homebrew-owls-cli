# OwlsCLI

MicroUI module management CLI — scaffold and remove modules with a single command.

## Install

```bash
brew tap debuging-life/owls-cli https://github.com/debuging-life/homebrew-owls-cli.git
brew install owls-microui
```

**Requirements:** macOS 13+

## Usage

```bash
owls-microui create Transfers         # scaffold + auto-register
owls-microui remove Transfers         # clean removal
owls-microui create --dry-run BillPay # preview only
owls-microui remove --dry-run BillPay # preview only
owls-microui --help
```

## Update

```bash
brew upgrade owls-microui
```

## Uninstall

```bash
brew uninstall owls-microui
brew untap debuging-life/owls-cli
```

## What `create` does

1. Scaffolds `Packages/{Name}MicroUI/` with 16 files:
   - Builder/ (Config, Router, TileBuilder, ScreenBuilder, DeepLinkHandler)
   - Data/ (API routes, DataSource, ServiceDispatcher)
   - Domain/ (Models, Repository)
   - Localization/ (English keys)
   - ViewModels/
   - UI/ (Screens, Views, CreateSheet)
   - Tests/

2. Auto-registers in Container+Common.swift (DI slots)
3. Auto-registers in MicroUIBootstrap.swift (import + config)
4. Auto-updates project.pbxproj (package reference + framework link)

## What `remove` does

1. Removes DI slots from Container+Common.swift
2. Removes import + config from MicroUIBootstrap.swift
3. Removes all references from project.pbxproj
4. Deletes the module directory

## Development

```bash
swift build              # debug build
swift build -c release   # release build
swift run owls-microui --help
```

## Release

```bash
git tag v2.4.0
git push origin v2.4.0
# CI builds binary → creates Release → updates Formula SHA
```
