set fish_greeting

# Add local bin directories to PATH
fish_add_path $HOME/.npm-global/bin
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.pub-cache/bin
zoxide init fish | source
fzf --fish | source
starship init fish | source
set -gx EDITOR nvim
set -gx VISUAL "flatpak run dev.zed.Zed --wait"
fish_add_path /usr/sbin

# Basic navigation with eza
alias ll="eza -l --icons --group-directories-first"
alias lla="eza -la --icons --group-directories-first"
alias lt="eza -l --icons --tree --group-directories-first"
alias lta="eza -la --icons --tree --group-directories-first"

# Quick navigation
alias ..="cd .."
alias ...="cd ../.."
alias .3="cd ../../.."
alias .4="cd ../../../.."
alias .5="cd ../../../../.."

# Docker/Podman
alias d="docker"
alias p="podman"
alias docker="podman"
alias docker-compose="podman-compose"
alias update="topgrade"

# Common shortcuts
alias e="exit"
alias v="nvim"
alias o="opencode"
alias y="yazi"
alias free="free -h"
alias df="df -h"
alias lg="lazygit"
alias zed="flatpak run dev.zed.Zed --wait"
alias zen="flatpak run app.zen_browser.zen"

# sync from /etc/skel
alias skel="rsync -av /etc/skel/.config $HOME/.config"
