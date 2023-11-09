## Branch Name: **Name-OS-Distro-OriginDevice**

### NeoVim-WSL-Ubuntu-22.04.02-SurfacePro9
#### Dependencies
- gcc
- python3.10
- pip
- cmake
- unzip
- ripgrep
- luarocks
- nvm/npm
- packer.nvim
#### Quick Install for WSL2
##### Install Requirements
```bash 
$ sudo apt install gcc python3.10 python3-pip unzip ripgrep luarocks\
  && pip install cmake\
  && curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash\
  && nvm install node\
  && git clone --depth 1 https://github.com/wbthomason/packer.nvim\
  ~/.local/share/nvim/site/pack/packer/start/packer.nvim
```
##### Install Neovim
```bash
$ git clone https://github.com/neovim/neovim\
  && cd neovim && make CMAKE_BUILD_TYPE=RelWithDebInfo\
  && sudo make install
```
##### Install config
If `.config/` already exists, rename it, clone this repo and then merge the old contents back into the new directory
```bash
$ git clone https://github.com/ahumayde/.config\
  && cd .config/ && git checkout NeoVim-WSL-Ubuntu-22.04.02-SurfacePro9
```
#### Shared Clipboard
Enter this into Command Prompt as Administrator
```batch
$ mkdir C:\win32yank & 
  curl -LJO https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x86.zip &
  tar -xvf win32yank-x86.zip &
  move win32yank.exe C:\win32yank -y &
  setx PATH "%PATH%;C:\win32yank" &
  del win32yank.exe win32yank-x86.zip
```
#### Package Info
```bash
$ apt show <package>|grep Description: -A10
```
