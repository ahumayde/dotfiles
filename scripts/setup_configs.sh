#!/bin/bash

# Variable Declarations.
dotfiles_dir="$(dirname $(dirname "$0"))"

termux_dir="$HOME/.termux"
nvim_dir="$HOME/.config/nvim"
fonts_dir="$HOME/.local/share/fonts"
terminal_dir="$HOME/dotfiles/terminal"
active_font_dir="$terminal_dir" # default

github="https://github.com"
nvm_url="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"
nerdfonts="$github/ryanoasis/nerd-fonts/releases/download/v3.4.0"
neovim_repo="$github/neovim/neovim.git"
lazyvim_repo="https://github.com/LazyVim/starter "
neovim_version_req="0.11.2"

linux_pkgs="cmake curl gcc gettext luarocks make ninja-build python3.10 python3-pip ripgrep unzip"
termux_pkgs="wget clang lua51 luarocks make neovim ripgrep"

font_zips=("CascadiaCode.zip" "FiraCode.zip" "JetBrainsMono.zip")
font_files=("CaskaydiaCoveNerdFont-Regular.ttf" "FiraCodeNerdFont-Regular.ttf" "JetBrainsMonoNerdFont-Regular.ttf")

# Default Debian Linux.
update_cmd="sudo apt update && sudo apt upgrade"
install_cmd="sudo apt install"
install_opts="-y"
install_pkgs="$linux_pkgs"


# Function Declarations.
install_packages() {
	echo "Installing Packages..."

	# echo "Update CMD: $update_cmd"
	# echo "Install CMD: $install_cmd"
	# echo "Install Opts: $install_opts"
	# echo "Install Pkgs: $install_pkgs"

	# read -r -p "Are these correct? [Y/n]" choice
	# case "$choice" in
	# 	[Yy]) echo "Continuing..." ;;
	# 	* ) exit 1                 ;;
	# esac

	$update_cmd

	if $install_cmd $install_opts $install_pkgs; then
	    echo "Core packages installed successfully"
	else 
	    echo "FATAL ERROR: Core package installation failled."
	    exit 1
	fi
}

install_nerdfonts() {
    echo "Installing Nerd Fonts..."
 
	# echo "Active Font Dir: $active_font_dir"

	# read -r -p "Is this correct? [Y/n]" choice
	# case "$choice" in
	# 	[Yy] ) echo "Continueing..." ;;
	# 	* ) exit 1                   ;;
	# esac

    mkdir -p "$active_font_dir"
 
    for i in "${!font_zips[@]}"; do
        if [[ -f "$active_font_dir/font.ttf" ]]; then
            echo "A Font is Already Active!"
            echo "Would you like to install or replace it with ${font_files[i]}"
            read -r -p "[S]kip, [I]nstall, [B]ackup & Replace, [R]eplace (NO backup!) ? [S/I/B/R] " choice
 
            case "$choice" in	
        	[Ii] ) 
        	    wget -P "$fonts_dir" "$nerdfonts/${font_zips[i]}"
        	    unzip "$fonts_dir/${font_zips[i]}" -d "$fonts_dir/${font_zips[i]%.zip}"
        	    rm -rf "$fonts_dir/${font_zips[i]}" ;;
        	[Rr] )
        	    wget -P "$fonts_dir" "$nerdfonts/${font_zips[i]}"
        	    unzip "$fonts_dir/${font_zips[i]}" -d "$fonts_dir/${font_zips[i]%.zip}"
        	    rm -rf "$fonts_dir/${font_zips[i]}"
        	    cp "$fonts_dir/${font_files[i]}" "$active_font_dir/font.ttf" ;;
        	[Bb] ) 
        	    wget -P "$fonts_dir" "$nerdfonts/${font_zips[i]}"
        	    unzip "$fonts_dir/${font_zips[i]}" -d "$fonts_dir/${font_zips[i]%.zip}"
        	    rm -rf "$fonts_dir/${font_zips[i]}"
        	    mv "$active_font_dir/font.ttf" "$active_font_dir/fonts/font.bak.$(date +%Y%m%d%H%M%S)" 
        	    cp "$fonts_dir/${font_files[i]}" "$active_font_dir/font.ttf" ;;
        	* )
        	    echo "-> Skipping font installation." ;;
            esac
        else
            wget -P "$fonts_dir" "$nerdfonts/${font_zips[i]}"
	        unzip "$fonts_dir/${font_zips[i]}" -d "$fonts_dir/${font_zips[i]%.zip}"
            rm -rf "$fonts_dir/${font_zips[i]}"
            mv "$fonts_dir/${font_files[i]}" "$active_font_dir/font.ttf"
        fi
    done
}

setup_tools() {
	echo "Setting up tools..."

	# Python Pip
	if command -v pip &> /dev/null || command -v pip3 &> /dev/null; then
        echo "Installing Python utilities..."
        pip_cmd=$(command -v pip3 || command -v pip)
        $pip_cmd install --upgrade pip
        $pip_cmd install pynvim
    fi

    if [[ "$OSTYPE" != "linux-android" ]]; then
	    #    echo "OSTYPE is NOT Android"
        
	    # read -r -p "Is this correct? [Y/n]" choice

	    # case "$choice" in
	    #     [Yy] ) echo "Continuing..." ;;
	    #  * ) exit 1                  ;;
	    # esac

	    # Node Version Manager
        if ! command -v nvm &> /dev/null; then
            echo "Installing NVM (Node Version Manager)..."
            curl -o- $nvm_url | bash
            echo "NOTE: NVM installed. Please RE-OPEN your terminal or run:" echo 'export NVM_DIR="$HOME/.nvm"'
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
        fi

		# Node LTS
        if command -v nvm &> /dev/null; then
            nvm install --lts
            nvm use --lts
            echo "Node LTS installed via NVM."
        fi

		# Neovim
		if ! command -v nvim &> /dev/null; then
			echo "Installing Neovim..."

			mkdir -p "$nvim_build"
			cd "$nvim_build" || exit 1
			if ! git clone --depth 1 "$neovim_repo" nvim &> /dev/null; then 
				cd -; rm -rf "$nvim_build"
                echo "Neovim `git clone` Failed..."
                exit 1 
			fi 

			cd nvim || exit 1
			if ! make CMAKE_BUILD_TYPE=Release; then
				cd -; rm -rf "$nvim_build"; exit 1 
			fi

			if ! sudo make install; then
				cd -; rm -rf "$nvim_build"
                echo "Neovim `make install` Failed..."
                exit 1 
			fi

			cd -
			rm -rf "$nvim_build"
        fi
	fi

	# LazyVim
	if [ ! -f "$nvim/lazy-lock.json" ]; then
		echo "Installing Lazy Vim..."

		mv ~/.config/nvim{,.bak}
		mv ~/.local/share/nvim{,.bak}
		mv ~/.local/state/nvim{,.bak}
		mv ~/.cache/nvim{,.bak}

		git clone $lazyvim_repo ~/.config/nvim
		rm -rf ~/.config/nvim/.git
	fi
}

# Install Environment Dependencies

if [[ "$OSTYPE" == "linux-gnu"* ]]; then 
	echo "Running Linux GNU..."
elif [[ "$OSTYPE" == "linux-android"* ]]; then
	echo "Running Linux Android..."
	update_cmd="pkg update && pkg upgrade"
	install_cmd="pkg install"
	install_opts="-y"
	install_pkgs="$termux_pkgs"
	active_font_dir="$termux_dir"
elif [[ "$OSTYPE" == "darwin"* ]]; then
	echo "Running Mac OSX..."
elif [[ "$OSTYPE" == "cygwin" ]]; then
	echo "Running POSIX..."
elif [[ "$OSTYPE" == "msys" ]]; then
	echo "Running MSYS..."
elif [[ "$OSTYPE" == "win32" ]]; then
	echo "Running Windows..."
    pwsh $dotfiles_dir/scripts/setup_configs.ps1
    exit 1
fi

install_packages
install_nerdfonts
setup_tools


# Ensure no config overrides


# Check directories


# Check files

