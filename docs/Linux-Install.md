# Linux Dotfile Configs Installation Guide

## Install

#### Clone this Repo & Run the Installation Script

##### Ensure Git is Installed

```bash
sudo apt update && sudo apt install git
sudo apt install git
```

You may want to replace `sudo apt` with the correct package manager for your linux distrobution

##### Clone the Repo into your Home Directory

```bash
git clone https://github.com/ahumayde/dotfiles ~
```

##### Run the Installation Script

```bash
~/dotfiles/scripts/setup_configs.sh
```

You may want to remove the `dotfiles/` directory after successfully running the script and copying the contents to `~/.config`

#### Shared Clipboard (WSL ONLY)

Enter this into Command Prompt as Administrator

```bash
mkdir C:\win32yank & 
curl -LJO https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x86.zip &
tar -xvf win32yank-x86.zip &
move win32yank.exe C:\win32yank -y &
setx PATH "%PATH%;C:\win32yank" &
del win32yank.exe win32yank-x86.zip
```

#### Quick Install for WSL2 (Deprecated)

##### Install Requirements

```bash
sudo apt update && sudo apt upgrade
sudo apt-get install gcc python3.10 python3-pip luarocks ninja-build gettext cmake unzip curl ripgrep
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
nvm install node
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
       ~/.local/share/nvim/site/pack/packer/start/packer.nvim
```

##### Install Neovim

```bash
git clone https://github.com/neovim/neovim\
cd neovim && make CMAKE_BUILD_TYPE=RelWithDebInfo\
sudo make install
```

#### Package Info (useful)

```bash
apt show <package> | grep Description: -A10
```
