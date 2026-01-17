# Windows Dotfile Configs Installation Guide

## Requirements 

- **PowerShell (any version)** 
  PowerShell 7 (`pwsh`) is recommended for best compatibility.
  If PowerShell 7 is not detected, the script will try to install it automatically. 
- **Administrator privileges** 
  The script will warn you if elevation is missing. 

## Installation

Run the following command in an **elevated PowerShell session** (Run as Administrator):

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; irm "https://raw.githubusercontent.com/ahumayde/dotfiles/refs/heads/termux/samsung-galaxy-s24%2B/scripts/setup_configs.ps1" | iex
```

## What the Script Does

This setup script automates the full configuration of a Windows development environment. It performs the following tasks:

- **Installs required tools using Winget**  
  Ensures PowerShell 7, Git, Neovim, PowerToys, AutoHotkey, Windhawk, Oh My Posh, Node.js (LTS), Python 3.14, Ripgrep, and Zig are installed.  
  Missing packages are installed automatically, and existing ones are skipped.

- **Configures development tooling**  
  - Upgrades Python’s pip and installs `pynvim`  
  - Adds important binary paths (Git, Neovim) to the user PATH if they are missing  
  - Refreshes the environment PATH after installation

- **Sets up your dotfiles**  

  - Clones this dotfiles repository if it isn’t already present in your `$HOME` directory
  - Ensures the `$HOME/.config` directory exists  
  - Syncs all files and folders from your dotfiles into the Windows config directory
  - For each existing config, lets you choose to **Skip**, **Backup & Replace**, or **Delete & Replace**

- **Installs Nerd Fonts support**  
  - Downloads the Nerd Font installer script into your `$HOME/.config/scripts` directory  
  - Adds a convenient `install-nerdfonts` function to your PowerShell profile for easy font installation later

- **Prepares directories for future tooling**  
  Ensures `$HOME/.config/scripts` exists and is ready for custom scripts added to PATH.

This script is designed to give you a fully configured, reproducible Windows development environment with minimal manual steps.
- 

## Winget Install

- Microsoft.Powershell
- Git.Git
- Neovim.Neovim
- Microsoft.PowerToys
- AutoHotkey.Autohotkey
- RamenSoftware.Windhawk
- JanDeDobbeleer.OhMyPosh
- etc...

## Add useful bin directories to global environment path (e.g. C:\Program Files\Git\bin)

## Clone Dotfiles repo -> ~/.config

## Install Nerd Fonts

## Set up Symbolic links for other app settings/configs (e.g. vscode)
