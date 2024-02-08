# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

color_prompt=yes
yellow='\[\e[93m\]'
green='\[\e[38;5;47m\]'
blue='\[\e[94m\]'
pink='\[\e[95m\]'
sky='\[\e[38;5;117m\]'
turquoise='\[\e[38;5;87m\]'
at_symb='\[\e[97m\]@'
colon='\[\e[97m\]:'
offgreen='\[\e[38;5;49m\]'
text='\[\e[38;5;49m\]'

if [ "$color_prompt" = yes ]; then
    # PS1='${debian_chroot:+($debian_chroot)}\[\e[1;38;5;46m\]Hana\[\e[1;93m\]:Is\[\e[1;94m\]:Actually\[\e[1;05;93m\]:Smart\[\e[1;94m\]$( _dir_chomp "$(pwd)" 20)\[\e[1;05;93m\]$ \[\e[25;95m\]'
    PS1='${debian_chroot:+($debian_chroot)}'$green'Vim'$colon$blue'User'$colon$yellow'\u'$at_symb$blue'\W'$yellow'$ '$text
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ls='ls --group-directories-first --color=auto -X'
alias ll='ls --group-directories-first --color=auto -alXF'
alias la='ls --group-directories-first --color=auto -AX'
alias l='ls --group-directories-first --color=auto -CFX'

# DSD Aliases
alias eclipse='~/intelFPGA_lite/20.1/nios2eds/bin/eclipse-nios2'
alias quartus='~/intelFPGA_lite/20.1/quartus/bin/quartus'
alias nios2_shell='~/intelFPGA_lite/20.1/nios2eds/nios2_command_shell.sh'

export QSYS_ROOTDIR="/home/e2/intelFPGA_lite/20.1/quartus/sopc_builder/bin"
export QUARTUS_ROOTDIR_OVERRIDE=/home/e2/intelFPGA_lite/20.1/quartus
export MODELSIM_ROOTDIR=/home/e2/intelFPGA_lite/20.1/modelsim_ase
export PATH="$PATH:$QUARTUS_ROOTDIR/bin:$QSYS_ROOTDIR:$MODELSIM_ROOTDIR/bin"


# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
   . /etc/bash_completion
fi

# alias git='git_color'
gitp() {
    command git "$@" | awk '{print "\033[38;5;93m" $0 "\033[0m"}'
}

LS_COLORS=$LS_COLORS:'no=1;38;5;35:fi=1;97:ln=1;38;5;93:tw=1;34:pi=40;33:ex=1;93
:or=40;31;01:mi=01:ow=34;38;5;57;01:*.tar=01;91:*.tgz=01;31:*.zip=1;31:*.sh=1;92
:*.deb=1;31:*.rar=1;31:*.jpg=1;35:*.jpeg=1;35:*.gif=1;35:*.png=01;35:*.svg=01;35
:*.svgz=1;35:*.mov=1;35:*.mpeg=1;35:*.webm=1;35:*.mp4=1;35:*.mp3=1;35*.wav=01;36
:*.py=38;5;226:*.cpp=38;5;93'

for h in $(find . -type f -name ".*"); do
    hf="${h##*/}"
    LS_COLORS="$LS_COLORS*$hf=1;30:";
done

# for h in $(find . -type d -name ".*"); do
#     hf="${h##*/}"
#     LS_COLORS="$LS_COLORS*di=$h=35";
#     echo "$hf/"
# done

export LS_COLORS

export NVM_DIR="/home/headzy/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

