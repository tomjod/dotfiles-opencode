# ============================================
# Fish Shell Pro Configuration
# ============================================

# --- Editor ---
set -x EDITOR vim
set -x VISUAL vim

# --- History ---
set -g fish_history_limit 50000

# --- Greeting ---
set fish_greeting

# --- OpenCode Pro ---
set -x OPENCODE_ENABLE_EXA 1
set -x OPENCODE_EXPERIMENTAL_LSP_TOOL true

# --- Git via GITHUB_TOKEN (see bootstrap.sh for setup) ---
# Token is set in ~/.config/fish/conf.d/github-token.fish (local, not in repo)

# --- Editor ---
set -x EDITOR "code --wait"

# --- PATH ---
fish_add_path ~/.local/bin

# ============================================
# Aliases & Abbreviations
# ============================================

# Kitty SSH Kitten
alias s='kitten ssh'
alias icat='kitten icat'
alias d='kitten diff'

# Tmux
alias tm='tmux'
alias tma='tmux attach'
alias tms='tmux new-session -s'
alias tml='tmux list-sessions'

# Listing
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Grep
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git abbreviations (expansion inline)
abbr -a g git
abbr -a ga 'git add'
abbr -a gc 'git commit'
abbr -a gp 'git push'
abbr -a gl 'git pull'
abbr -a gs 'git status'
abbr -a gd 'git diff'
abbr -a gco 'git checkout'
abbr -a gb 'git branch'

# OpenCode Pro aliases
abbr -a oc 'opencode'
abbr -a ocs 'opencode serve --port 4096'
abbr -a oca 'opencode acp'
abbr -a ocs-start 'systemctl --user start opencode-server'
abbr -a ocs-stop 'systemctl --user stop opencode-server'
abbr -a ocs-status 'systemctl --user status opencode-server'
abbr -a ocs-logs 'journalctl --user -u opencode-server -f'

# Navigation abbreviations
abbr -a .. 'cd ..'
abbr -a ... 'cd ../..'
abbr -a .... 'cd ../../..'

# ============================================
# Prompt (Starship if available, else minimal)
# ============================================
if type -q starship
    starship init fish | source
else
    # Minimal custom prompt with kitty integration
    function fish_prompt
        set -l last_status $status
        set -l cwd (prompt_pwd)
        set -l user_color brgreen
        set -l host_color brcyan
        set -l cwd_color brblue

        if test $last_status -ne 0
            set user_color brred
        end

        printf '\n%s@%s %s%s%s \n> ' \
            (set_color $user_color) \
            (set_color $host_color)(hostname -s)(set_color normal) \
            (set_color $cwd_color) $cwd (set_color normal)
    end
end

# ============================================
# Kitty Shell Integration
# ============================================
if test "$TERM" = "xterm-kitty"
    # Enable cursor shape change in vim mode
    set -g fish_vi_cursor

    # Mark prompt for kitty
    if type -q __ksi
        __ksi
    end
end

# ============================================
# Tmux auto-attach (optional)
# Uncomment to auto-attach to tmux when opening a terminal
# ============================================
# if status is-interactive
#     and not set -q TMUX
#     and test "$TERM_PROGRAM" != "vscode"
#     tmux attach-session -t default; or tmux new-session -s default
# end

# ============================================
# FZF key bindings (if fzf is installed)
# ============================================
if type -q fzf
    fzf --fish | source 2>/dev/null
end

# ============================================
# Direnv (if installed)
# ============================================
if type -q direnv
    direnv hook fish | source
end

# ============================================
# Zoxide (if installed)
# ============================================
if type -q zoxide
    zoxide init fish | source
end
