#!/usr/bin/env bash
# ============================================================
# OpenCode Pro Bootstrap — replica tu setup en cualquier PC
# ============================================================
# Usage:
#   ./bootstrap.sh                          # interactive: selecciona componentes
#   ./bootstrap.sh --all                    # instala TODO sin preguntar
#   ./bootstrap.sh --no-hyprland --no-vpn   # skip específicos
#   GITHUB_TOKEN=xxx OVPN_PATH=/path/file.ovpn ./bootstrap.sh
# ============================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}✅${NC} $1"; }
warn() { echo -e "${YELLOW}⚠️${NC}  $1"; }
fail() { echo -e "${RED}❌${NC} $1"; exit 1; }
info() { echo -e "${CYAN}📦${NC} $1"; }
ask()  { echo -e "${YELLOW}🔑${NC} $1"; }

# ─── Parse flags ───────────────────────────────────────────
INSTALL_HYPRLAND=true
INSTALL_OPENVPN=true
INSTALL_MERIDIAN=true
INSTALL_ENGRAM=true
INSTALL_FISH=true
INSTALL_OPENCODE=true
ALL_MODE=false

for arg in "$@"; do
    case "$arg" in
        --all)           ALL_MODE=true ;;
        --no-hyprland)   INSTALL_HYPRLAND=false ;;
        --no-vpn)        INSTALL_OPENVPN=false ;;
        --no-meridian)   INSTALL_MERIDIAN=false ;;
        --no-engram)     INSTALL_ENGRAM=false ;;
        --no-fish)       INSTALL_FISH=false ;;
        --no-opencode)   INSTALL_OPENCODE=false ;;
        -h|--help)
            echo "Usage: $0 [flags]"
            echo "  --all            Install everything without asking"
            echo "  --no-hyprland    Skip Hyprland"
            echo "  --no-vpn         Skip OpenVPN3"
            echo "  --no-meridian    Skip Meridian"
            echo "  --no-engram      Skip Engram"
            echo "  --no-fish        Skip Fish shell"
            echo "  --no-opencode    Skip OpenCode"
            echo ""
            echo "  Env vars: GITHUB_TOKEN, OVPN_PATH"
            exit 0
            ;;
    esac
done

# ─── Interactive component selection ───────────────────────
if [ "$ALL_MODE" = false ]; then
    echo ""
    echo "============================================"
    echo "  OpenCode Pro Bootstrap"
    echo "============================================"
    echo ""
    echo "Select components to install (default: ALL):"
    echo ""
    
    read -rp "  Fish shell?            [Y/n] " REPLY; [[ "$REPLY" =~ ^[Nn] ]] && INSTALL_FISH=false
    read -rp "  OpenCode?              [Y/n] " REPLY; [[ "$REPLY" =~ ^[Nn] ]] && INSTALL_OPENCODE=false
    read -rp "  Meridian (Claude proxy)? [Y/n] " REPLY; [[ "$REPLY" =~ ^[Nn] ]] && INSTALL_MERIDIAN=false
    read -rp "  Engram (memory)?       [Y/n] " REPLY; [[ "$REPLY" =~ ^[Nn] ]] && INSTALL_ENGRAM=false
    read -rp "  Hyprland (tiling WM)?  [Y/n] " REPLY; [[ "$REPLY" =~ ^[Nn] ]] && INSTALL_HYPRLAND=false
    read -rp "  OpenVPN3?              [Y/n] " REPLY; [[ "$REPLY" =~ ^[Nn] ]] && INSTALL_OPENVPN=false
    echo ""
else
    echo ""
    echo "============================================"
    echo "  OpenCode Pro Bootstrap (--all mode)"
    echo "============================================"
    echo ""
fi

# ─── Sudo cache (one password prompt for everything) ─────
if command -v sudo &>/dev/null; then
    ask "Enter sudo password (cached for the session):"
    sudo -v
    # Keep sudo alive in background
    (while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null) &
fi

# ─── Detect OS ──────────────────────────────────────────
OS="$(uname -s)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES="$SCRIPT_DIR"

if [ ! -f "$DOTFILES/opencode/AGENTS.md" ]; then
    fail "Run from dotfiles repo root. Expected opencode/AGENTS.md"
fi

# ─── Helper: dnf install if missing ─────────────────────
dnf_install() {
    local pkg="$1"
    if rpm -q "$pkg" &>/dev/null; then
        log "$pkg already installed"
        return 0
    fi
    info "Installing $pkg..."
    sudo dnf install -y "$pkg" && log "$pkg installed" || warn "Failed to install $pkg"
}

# ============================================================
# STEPS
# ============================================================

# ─── 1. Fish Shell ─────────────────────────────────────
if [ "$INSTALL_FISH" = true ]; then
    info "Step 1: Fish shell"
    if [ "$OS" = "Linux" ]; then
        dnf_install fish || true
    elif command -v brew &>/dev/null; then
        brew list fish &>/dev/null || brew install fish
    fi
    command -v fish &>/dev/null && log "Fish ready" || warn "Fish not installed"
fi

# ─── 2. OpenCode ────────────────────────────────────────
if [ "$INSTALL_OPENCODE" = true ]; then
    info "Step 2: OpenCode"
    if command -v opencode &>/dev/null; then
        log "OpenCode $(opencode --version 2>/dev/null || echo '?') installed"
    else
        info "Installing OpenCode..."
        curl -fsSL https://opencode.ai/install | bash
        log "OpenCode installed"
    fi
fi

# ─── 3. Meridian ────────────────────────────────────────
if [ "$INSTALL_MERIDIAN" = true ]; then
    info "Step 3: Meridian — Claude Pro proxy"
    if command -v meridian &>/dev/null; then
        log "Meridian installed"
    else
        info "Installing Meridian..."
        npm install -g @rynfar/meridian 2>/dev/null || warn "Meridian npm install failed"
    fi
fi

# ─── 4. Engram ──────────────────────────────────────────
if [ "$INSTALL_ENGRAM" = true ]; then
    info "Step 4: Engram (persistent memory)"
    if command -v engram &>/dev/null; then
        log "Engram installed ($(engram version 2>/dev/null || echo '?'))"
    else
        info "Installing Engram..."
        curl -fsSL https://engram.ai/install | bash 2>/dev/null || warn "Engram install failed"
    fi
fi

# ─── 5. Config files (always copied, no sudo needed) ────
info "Step 5: Config files"

# Fish
mkdir -p ~/.config/fish
cp "$DOTFILES/fish/config.fish" ~/.config/fish/config.fish 2>/dev/null || true
log "Fish config → ~/.config/fish/"

# OpenCode
mkdir -p ~/.config/opencode/{skills,prompts,commands,plugins,acp,themes}
cp -r "$DOTFILES/opencode/skills/"* ~/.config/opencode/skills/ 2>/dev/null || true
cp -r "$DOTFILES/opencode/prompts/"* ~/.config/opencode/prompts/ 2>/dev/null || true
cp -r "$DOTFILES/opencode/commands/"* ~/.config/opencode/commands/ 2>/dev/null || true
cp -r "$DOTFILES/opencode/themes/"* ~/.config/opencode/themes/ 2>/dev/null || true
cp "$DOTFILES/opencode/plugins/"*.ts ~/.config/opencode/plugins/ 2>/dev/null || true
cp "$DOTFILES/opencode/AGENTS.md" ~/.config/opencode/ 2>/dev/null || true
cp "$DOTFILES/opencode/tui.json" ~/.config/opencode/ 2>/dev/null || true
cp "$DOTFILES/opencode/package.json" ~/.config/opencode/ 2>/dev/null || true
cp "$DOTFILES/opencode/bun.lock" ~/.config/opencode/ 2>/dev/null || true
cp "$DOTFILES/opencode/acp/avante-nvim.lua" ~/.config/opencode/acp/ 2>/dev/null || true
log "OpenCode config → ~/.config/opencode/"

# opencode.json template
cp "$DOTFILES/opencode/opencode.json.template" ~/.config/opencode/opencode.json 2>/dev/null || true
sed -i "s|__HOME__|$HOME|g" ~/.config/opencode/opencode.json 2>/dev/null || true
ENGRAM_BIN=$(command -v engram 2>/dev/null || echo "/home/linuxbrew/.linuxbrew/bin/engram")
sed -i "s|/home/linuxbrew/.linuxbrew/bin/engram|$ENGRAM_BIN|g" ~/.config/opencode/opencode.json 2>/dev/null || true
log "opencode.json from template"

# Systemd user services
if [ "$OS" = "Linux" ]; then
    mkdir -p ~/.config/systemd/user
    cp "$DOTFILES/systemd/opencode-server.service" ~/.config/systemd/user/ 2>/dev/null || true
    cp "$DOTFILES/systemd/meridian.service" ~/.config/systemd/user/ 2>/dev/null || true
    log "Systemd services → ~/.config/systemd/user/"
fi

# Zed
mkdir -p ~/.config/zed
cp "$DOTFILES/zed/settings.json" ~/.config/zed/settings.json 2>/dev/null || true
log "Zed config → ~/.config/zed/"

# ─── 6. Git credential helper ──────────────────────────
info "Step 6: Git credential helper"
mkdir -p ~/.local/bin
cp "$DOTFILES/bin/git-credential-github-token" ~/.local/bin/ 2>/dev/null || true
chmod +x ~/.local/bin/git-credential-github-token 2>/dev/null || true
git config --global credential.helper "$HOME/.local/bin/git-credential-github-token" 2>/dev/null || true

if [ -z "${GITHUB_TOKEN:-}" ]; then
    ask "GitHub Personal Access Token (or enter to skip):"
    read -rs TOKEN
else
    TOKEN="$GITHUB_TOKEN"
    log "GITHUB_TOKEN from environment"
fi
if [ -n "${TOKEN:-}" ]; then
    mkdir -p ~/.config/fish/conf.d
    echo "# Auto-generated by OpenCode bootstrap" > ~/.config/fish/conf.d/github-token.fish
    echo "set -x GITHUB_TOKEN $TOKEN" >> ~/.config/fish/conf.d/github-token.fish
    log "GITHUB_TOKEN saved"
fi

# ─── 7. Plugin dependencies ─────────────────────────────
info "Step 7: Plugin dependencies"
if command -v bun &>/dev/null; then
    (cd ~/.config/opencode && bun install --silent 2>/dev/null && log "Dependencies installed") || warn "bun install failed"
else
    warn "Bun not found — plugins may not work: curl -fsSL https://bun.sh/install | bash"
fi

# ─── 8. Systemd services ─────────────────────────────────
info "Step 8: Systemd services"
if [ "$OS" = "Linux" ]; then
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable --now meridian.service 2>/dev/null && log "Meridian enabled" || warn "Meridian service failed"
    systemctl --user enable --now opencode-server.service 2>/dev/null && log "OpenCode server enabled" || warn "OpenCode service failed"
fi

# ─── 9. Hyprland ────────────────────────────────────────
if [ "$INSTALL_HYPRLAND" = true ] && [ "$OS" = "Linux" ]; then
    info "Step 9: Hyprland (tiling Wayland compositor)"
    
    HYPR_PKGS="hyprland hypridle hyprlock hyprcursor hyprutils hyprpicker hyprsunset hyprpolkitagent xdg-desktop-portal-hyprland hyprland-uwsm"
    HYPR_TOOLS="swww waybar wallust kitty rofi-wayland"
    
    for pkg in $HYPR_PKGS $HYPR_TOOLS; do
        dnf_install "$pkg" || true
    done
    
    # Copy config
    if [ -d "$DOTFILES/hypr" ]; then
        mkdir -p ~/.config/hypr
        cp -r "$DOTFILES/hypr/"* ~/.config/hypr/
        mkdir -p ~/.config/hypr/wallpaper_effects
        log "Hyprland config → ~/.config/hypr/"
        warn "Edit ~/.config/hypr/monitors.conf for your display"
    fi
fi

# ─── 10. OpenVPN3 ───────────────────────────────────────
if [ "$INSTALL_OPENVPN" = true ] && [ "$OS" = "Linux" ]; then
    info "Step 10: OpenVPN 3 setup"
    VPN_CONFIG_NAME="dotfiles-vpn"
    
    if ! command -v openvpn3 &>/dev/null; then
        warn "OpenVPN3 not installed — skipping"
    else
        OVPN_PATH="${OVPN_PATH:-}"
        if [ -z "$OVPN_PATH" ]; then
            ask "Path to .ovpn profile (or enter to skip):"
            read -r OVPN_PATH
        else
            log "OVPN_PATH from environment"
        fi
        
        if [ -n "$OVPN_PATH" ] && [ -f "$OVPN_PATH" ]; then
            openvpn3 config-remove --config "$VPN_CONFIG_NAME" --force 2>/dev/null || true
            sudo systemctl stop "openvpn3-session@${VPN_CONFIG_NAME}.service" 2>/dev/null || true
            sudo systemctl disable "openvpn3-session@${VPN_CONFIG_NAME}.service" 2>/dev/null || true
            
            openvpn3 config-import --config "$OVPN_PATH" --name "$VPN_CONFIG_NAME" --persistent
            openvpn3 config-acl --config "$VPN_CONFIG_NAME" --grant root --transfer-owner-session true --lock-down true
            openvpn3 config-manage --config "$VPN_CONFIG_NAME" --dns-scope tunnel
            sudo systemctl enable --now "openvpn3-session@${VPN_CONFIG_NAME}.service"
            log "VPN auto-connect enabled (starts at boot)"
        elif [ -n "$OVPN_PATH" ]; then
            warn "File not found: $OVPN_PATH"
        else
            warn "Skipping VPN setup"
        fi
    fi
fi

# ─── API Keys reminder ──────────────────────────────────
echo ""
echo "============================================"
echo "  ⚠️  MANUAL STEPS"
echo "============================================"
echo ""
ask "1. Stitch API Key → edit ~/.config/opencode/opencode.json"
echo "   Search: YOUR_STITCH_API_KEY"
echo ""
ask "2. Supabase → edit ~/.config/opencode/opencode.json"
echo "   Search: YOUR_SUPABASE_PROJECT_REF"
echo ""
ask "3. Model API keys → run 'opencode' and /connect"
echo ""
echo "============================================"
echo "  🎉 BOOTSTRAP COMPLETE"
echo "============================================"
echo ""
echo "  Restart shell: exec fish"
echo ""
