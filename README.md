# OwlsCLI

MicroUI module management CLI — scaffold and remove modules with a single command.

> **This is a private repo.** Developers only receive the compiled binary — never the source code.

## How Distribution Works

```
Admin (you)                              Developers (your team)
    │                                         │
    │  1. Push code to this private repo      │
    │  2. Tag a release (v2.1.0)              │
    │  3. GitHub Actions builds binary        │
    │                                         │
    │  4. Share install.sh with team          │
    │     (Slack, email, internal docs)       │
    │─────────────────────────────────────►   │
    │                                         │
    │  5. Developer runs install.sh           │
    │     → gh checks they have Release       │
    │       read access (not repo access)     │
    │     → Downloads ONLY the binary         │
    │     → Installs to ~/.owls/bin/          │
    │     → No source code is exposed         │
    │                                         │
```

## Setup (Admin — one time)

### 1. Grant developers Release-only access

On GitHub: **Settings → Collaborators → Add people**

- Give developers **"Read" access** to the repo
- They can see Releases (to download binary) but NOT the source code
- OR: Make Releases public while keeping repo private (GitHub supports this via the API)

### 2. Build a release

```bash
git tag v2.1.0
git push origin v2.1.0
# GitHub Actions builds binary and attaches to Release
```

### 3. Share install.sh with your team

Copy `install.sh` and share via Slack, email, or internal wiki. The script itself contains no secrets — it just downloads the binary.

## Install (Developers)

Save the `install.sh` script your admin shared, then run:

```bash
bash install.sh
```

**Requirements:**
- macOS 13+
- GitHub CLI (`brew install gh` → `gh auth login`)
- Release read access to `debuging-life/owls-cli`

**What it does:**
1. Verifies GitHub auth via `gh`
2. Downloads the binary from GitHub Releases (NOT source)
3. Installs to `~/.owls/bin/owls-microui`
4. Adds to PATH

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

## Uninstall

```bash
rm -rf ~/.owls
# Then remove the "# OwlsCLI" and PATH line from ~/.zshrc
```

## Development (Admin only)

```bash
swift build              # debug build
swift build -c release   # release build
swift run owls-microui --help
```

## Release (Admin only)

```bash
git tag v2.2.0
git push origin v2.2.0
# GitHub Actions builds and uploads binary automatically
```
