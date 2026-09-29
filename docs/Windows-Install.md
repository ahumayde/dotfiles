# Windows Dotfiles Configuration Guide

## Requirements

* **PowerShell 7 (`pwsh`)**: Required. If the scripts are started from Windows PowerShell 5.x, they print an error asking you to install/open `pwsh` and exit. (This check runs *before* any elevation prompt.)
* **Administrator Privileges**: Required to install system-level packages, deploy to `ProgramData`, and modify environment paths. If run without administrator rights, the script automatically requests elevation via a UAC prompt and re-launches itself with the same flags. **`-DryRun` never elevates**, because it changes nothing.
* **Winget**: Ships with Windows 11 as *App Installer*. `01-dependencies.ps1` stops with an error if it is missing.

## Installation

Because this setup utilises a modular architecture, the most reliable installation method is to clone the repository to your home directory and execute the master installer locally.

```powershell
# 0. (Only if Git isn't installed yet)
winget install --id Git.Git -e

# 1. Clone the repository to your home directory
git clone -b windows-11/pc https://github.com/ahumayde/dotfiles.git "$HOME\.dotfiles"

# 2. Navigate to the setup directory
cd "$HOME\.dotfiles\setup"

# 3. Execute the master installation script (elevates itself if needed)
.\install.ps1
```

*Note: The branch you clone should match `$DotfilesBranch` in `setup/utils.ps1`, because `03-bootstrap.ps1` pulls that branch on later runs.*

### Flags

| Flag | Effect |
| --- | --- |
| `-DryRun` | Prints what *would* be installed, downloaded, copied, linked or removed. Nothing is modified, no prompts are shown, and no elevation is requested. |
| `-All` | Non-interactive mode. Installs every missing package without asking, **backs up** (never deletes) conflicting config files, downloads/runs the Nerd Font installer, and extracts the PowerToys backup. |

Both flags are passed down to every module, including across the UAC elevation.

## Architecture

The repository is strictly divided to separate execution logic from daily-use configurations and utilities:

* **`setup/`**: Contains the master `install.ps1`, `uninstall.ps1`, the shared `utils.ps1`, and all modular deployment scripts. These should only be run when provisioning or rolling back a system. Inside these scripts, `$SetupDir` always refers to this folder.
* **`scripts/`**: Contains your daily-use utility scripts, plus helper scripts fetched during setup such as `Invoke-NerdFontInstaller.ps1`. This folder (`$ScriptsDir`) is added to your `PATH`, so keeping the installation scripts out of it avoids cluttering autocomplete. *(Consider adding `scripts/Invoke-NerdFontInstaller.ps1` to `.gitignore`, as it is downloaded rather than authored.)*
* **`config/`**: Contains the actual application configurations (Windows Terminal, VSCode, PowerShell profile, Windhawk, AutoHotkey, Neovim) and the PowerToys settings backup (`config/powertoys/*.ptb`).

### Shared settings (`setup/utils.ps1`)

`utils.ps1` is dot-sourced by every script and holds the shared constants (repository URL and branch, `$ScriptsDir`, `$ConfigDir`, the winget package list, the `PATH` entries) and helper functions. Edit the package list or `PATH` entries here and both the installer and uninstaller pick up the change.

> **Developer note:** `utils.ps1` must never contain a `param()` block. Dot-sourcing a script with `param()` resets same-named variables in the caller, which silently turned `-DryRun` and `-All` back off.

## Modular Execution Flow

The `install.ps1` master orchestrator runs the following modules sequentially, and aborts if a critical step (dependencies, `PATH`, repository bootstrap) fails. You can also run any module individually, for example `.\04-config.ps1 -DryRun`.

### 1. Dependencies (`01-dependencies.ps1`)

* **Winget Packages**: Installs Git, Neovim, Microsoft PowerToys, AutoHotkey, Windhawk, Oh My Posh, Node.js (LTS), Python 3.14, and Zig. Installed packages are detected via winget's exit code and skipped. Without `-All` you are asked before each install, and any install failures are reported at the end.
* **Development Tooling**: After refreshing the session `PATH` (so a freshly installed Python is found), upgrades `pip` and installs the `pynvim` provider for Neovim.

### 2. Environment Paths (`02-paths.ps1`)

* Adds any missing directories to your global User `PATH`: `C:\Program Files\Git\bin`, `C:\Program Files\Git\usr\bin`, `C:\Program Files\Neovim\bin`, and `$HOME\.dotfiles\scripts`.
* Entries are matched exactly (case-insensitive, ignoring trailing slashes), and the `PATH` is written back without expanding any `%VARIABLES%` you already had in it.

### 3. Repository Bootstrap (`03-bootstrap.ps1`)

* If the repository is missing, it clones the specified branch directly to `$HOME\.dotfiles`. A failed clone stops the installer before any configs are deployed.
* If the repository already exists, it runs a fast-forward-only `git pull` for that branch (using `git -C`, so your working directory is untouched). A failed pull, for example due to local changes, is reported and the existing checkout is used.
* If `$HOME\.dotfiles` exists but is not a Git repository, it stops with an error rather than touching it.

### 4. Configuration Deployment (`04-config.ps1`)

**Nerd Fonts**: After asking (skipped in `-DryRun`/`-All`), downloads `Invoke-NerdFontInstaller.ps1` into `scripts/` if it isn't there and runs it with `-Scope AllUsers`. Nothing is downloaded if you decline.

**Config files**: Distributes your dotfiles across the Windows filesystem using methods tailored to how each application saves data:

* **Symbolic Links (Resilient)**: Used for the PowerShell Profile (resolved from your real Documents folder, so a OneDrive-redirected Documents folder works). Changes made in the system reflect immediately in the repository. A Neovim link (`$env:LOCALAPPDATA\nvim`) is defined in `04-config.ps1` but commented out; uncomment it to enable.
* **Direct Copies (Atomic-Save Safe)**: Used for Windows Terminal, VSCode and Windhawk. Because these applications overwrite files entirely when saving settings via their GUIs (which destroys symlinks), direct copies are used. *(Note: Remember to copy these back to the repository before committing changes.)*
* **Windhawk**: The contents of `config/windhawk/mods` are merged into `%ProgramData%\Windhawk\Engine\Mods`, and `userprofile.json` is copied alongside. The Windhawk service is stopped for the copy and always restarted afterwards, even if the copy fails.
* **Shortcuts**: Creates a `.lnk` shortcut in the Windows `Startup` folder pointing to your compiled `startup_ahk.exe`, ensuring your AutoHotkey routines launch on boot without needing the script to be manually re-copied after recompilation.

**Conflict handling**: Targets that already match are reported as *Already up to date* and left alone. Otherwise you are prompted to **Skip**, **Backup & Replace** (renames the existing file to `<name>.bak.<timestamp>`), or **Delete & Replace**. With `-All`, conflicts are always backed up. Missing sources are reported and skipped.

**PowerToys**: PowerToys stores its settings across many JSON files (one folder per module), so a single `settings.json` copy isn't enough. Instead, keep a backup in `config/powertoys/` (create it in PowerToys under *Settings → General → Backup & restore → Backup*; the result is a `.ptb` file, which is a zip archive). Keep only one `.ptb` there; if several are present, the newest is used. You are asked how to apply it:

* **Skip**: Leaves PowerToys alone (default).
* **Manual restore**: Copies the `.ptb` into `Documents\PowerToys\Backup`; you then click *Restore* in PowerToys. If you have set a custom backup location in PowerToys, restore from that folder instead.
* **Extract now**: Stops PowerToys and extracts the backup into `%LOCALAPPDATA%\Microsoft\PowerToys`. Identical files are left alone, and any file that would be overwritten is first copied to `PowerToys.dotfiles-backup.<timestamp>`. Restart PowerToys afterwards. Archives without any `.json` files are rejected.

## Safe Rollback (Uninstallation)

If you need to revert the changes made to your system, run the uninstallation script (it also supports `-DryRun`):

```powershell
.\setup\uninstall.ps1
```

This script performs a clean rollback by:

1. After asking, removing the generated symlinks, copied configuration files (PowerShell profile, Windows Terminal, VSCode) and the startup shortcut, and restoring the most recent `.bak` backup of each if one exists.
2. Scrubbing the injected binary paths (Git, Neovim, `scripts/`) from your User `PATH`, matching exact entries only.
3. Explicitly prompting you before uninstalling any Winget packages to prevent accidental removal of previously existing software.
4. Explicitly prompting you before deleting the `~/.dotfiles` repository to prevent the loss of uncommitted changes.

Deliberately **not** touched: PowerToys settings (restored from a multi-file backup, so there is no single file to remove), Windhawk mods/settings, and any fonts installed by the Nerd Font installer.
