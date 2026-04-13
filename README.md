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
    │  5. Grant developer GitHub access       │
    │────────────────────────────────────►    │
    │                                         │
    │                     brew tap + install   │
    │                     → Downloads binary   │
    │                     → No source exposed  │
```

## Security — 3 Layers

```
Layer 1: SSH Key (brew tap)
  ❌ No SSH access → can't clone repo → blocked

Layer 2: GitHub Token (brew install)  
  ❌ No token → can't download binary from API → blocked

Layer 3: Compiled Binary
  ❌ Binary only → source code never exposed
```

| | With GitHub Access | Without GitHub Access |
|---|---|---|
| `brew tap` | ✅ Clones formula | ❌ Git clone fails |
| `brew install` | ✅ Downloads binary | ❌ API 401 unauthorized |
| Source code | ❌ Never visible | ❌ Never visible |

## Install (Developers)

### Prerequisites

```bash
# 1. Install GitHub CLI
brew install gh

# 2. Authenticate (must have access to debuging-life org)
gh auth login

# 3. Add token to shell (one time)
echo 'export HOMEBREW_GITHUB_API_TOKEN=$(gh auth token)' >> ~/.zshrc
source ~/.zshrc
```

### Install

```bash
brew tap debuging-life/owls-cli git@github-pardipbhatti8791:debuging-life/homebrew-owls-cli.git
brew install owls-microui
```

### Update

```bash
brew upgrade owls-microui
```

### Uninstall

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

## Admin Guide

### Grant a developer access

1. Add them as collaborator to `debuging-life/homebrew-owls-cli` on GitHub
2. Give **Read** access (they can download releases, not see source)
3. Share the install commands above

### Release a new version

```bash
git tag v2.3.0
git push origin v2.3.0
# CI: build binary → create Release → update Formula SHA
```

Developers update with `brew upgrade owls-microui`.

### Revoke access

Remove the developer from the repo collaborators. Their next `brew upgrade` will fail — existing installed binary still works locally but they won't get updates.

## Development (Admin only)

```bash
swift build              # debug build
swift build -c release   # release build
swift run owls-microui --help
```
