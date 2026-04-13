# OwlsCLI

MicroUI module management CLI — scaffold and remove modules with a single command.

> **Private repo.** Developers get the compiled binary via Homebrew — source code is never exposed.

## How It Works

```
Admin (you)                              Developers (team)
    │                                         │
    │  1. Push code to private repo           │
    │  2. git tag v2.2.0                      │
    │  3. GitHub Actions builds binary        │
    │  4. Auto-updates Homebrew Formula       │
    │                                         │
    │                                         │
    │                     brew tap debuging-life/owls-cli
    │                     brew install owls-microui
    │                                         │
    │                     → Downloads binary   │
    │                     → No source exposed  │
```

## Install (Developers)

```bash
brew tap debuging-life/owls-cli
brew install owls-microui
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

## Usage

```bash
owls-microui create Transfers         # scaffold + auto-register
owls-microui remove Transfers         # clean removal
owls-microui create --dry-run BillPay # preview only
owls-microui remove --dry-run BillPay # preview only
owls-microui --help
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

## Setup (Admin — one time)

### 1. Release

```bash
git tag v2.2.0
git push origin v2.2.0
# CI builds binary → creates Release → updates Homebrew Formula
```

## Development (Admin only)

```bash
swift build              # debug build
swift build -c release   # release build
swift run owls-microui --help
```
