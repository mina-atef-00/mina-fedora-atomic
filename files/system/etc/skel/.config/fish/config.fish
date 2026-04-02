set fish_greeting
fish_config theme choose "Catppuccin Mocha"

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
alias d="podman"
alias p="podman"
alias docker="podman"
alias docker-compose="podman-compose"

# Common shortcuts
alias e="exit"
alias v="nvim"
alias o="opencode"
alias oweb="opencode web --port 4096 --mdns"
alias y="yazi"
alias free="free -h"
alias df="df -h"
alias lg="lazygit"
alias zed="flatpak run dev.zed.Zed --wait"
alias zd="flatpak run dev.zed.Zed --wait"
alias zen="flatpak run app.zen_browser.zen"
alias fp="flatpak"
alias fpr="flatpak run"
alias update="topgrade"
alias cz="chezmoi"
alias cza="chezmoi apply"
alias czi="chezmoi init --apply https://github.com/mina-atef-00/dotfiles.git"
alias vkstop="systemctl --user stop vibe-kanban.service"
function vk
    if systemctl --user is-active vibe-kanban.service >/dev/null 2>&1
        echo "already running"
        systemctl --user status vibe-kanban.service
    else
        systemctl --user start vibe-kanban.service
    end
end

# sync from /etc/skel
alias skel="rsync -av /etc/skel/.config $HOME/.config"

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv fish)"
