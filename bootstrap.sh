#!/usr/bin/env bash
# ============================================================
# OpenCode Pro Bootstrap — replica tu setup en cualquier PC
# ============================================================
# Usage:
#   ./bootstrap.sh                    # select components, then install
#   ./bootstrap.sh --all              # install everything
#   ./bootstrap.sh --no-hyprland      # skip specific components
#   GITHUB_TOKEN=xxx OVPN_PATH=/path  # pass secrets via env
# ============================================================
set -euo pipefail

# ─── Color support ─────────────────────────────────────
if [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; BOLD=''; DIM=''; NC=''
fi

info()    { echo -e "${BLUE}[ ... ]${NC} $*"; }
success() { echo -e "${GREEN}[  ok ]${NC} $*"; }
warn()    { echo -e "${YELLOW}[ warn]${NC} $*"; }
error()   { echo -e "${RED}[error]${NC} $*" >&2; }
step()    { echo -e "\n${CYAN}${BOLD}==>${NC} ${BOLD}$*${NC}"; }

# ─── Parse flags ───────────────────────────────────────
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
            echo "  --all            Install everything"
            echo "  --no-hyprland    Skip Hyprland"
            echo "  --no-vpn         Skip OpenVPN3"
            echo "  --no-meridian    Skip Meridian"
            echo "  --no-engram      Skip Engram"
            echo "  --no-fish        Skip Fish shell"
            echo "  --no-opencode    Skip OpenCode"
            echo "  Env: GITHUB_TOKEN, OVPN_PATH"
            exit 0
            ;;
    esac
done

# ─── Banner ────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}"
echo "  ████████╗ ██████╗ ███╗   ███╗     ██╗ ██████╗ ██████╗ "
echo "  ╚══██╔══╝██╔═══██╗████╗ ████║     ██║██╔═══██╗██╔══██╗"
echo "     ██║   ██║   ██║██╔████╔██║     ██║██║   ██║██║  ██║"
echo "     ██║   ██║   ██║██║╚██╔╝██║██   ██║██║   ██║██║  ██║"
echo "     ██║   ╚██████╔╝██║ ╚═╝ ██║╚█████╔╝╚██████╔╝██████╔╝"
echo "     ╚═╝    ╚═════╝ ╚═╝     ╚═╝ ╚════╝  ╚═════╝ ╚═════╝ "
echo -e "${NC}"
echo -e "  ${DIM}Bootstrap your development environment${NC}"
echo ""

# ─── Component selection ──────────────────────────────
if [ "$ALL_MODE" = false ]; then
    echo -e "  ${BOLD}Components${NC} ${DIM}(all enabled, enter numbers to skip)${NC}"
    echo ""
    echo -e "    ${GREEN}[1]${NC} Fish shell"
    echo -e "    ${GREEN}[2]${NC} OpenCode"
    echo -e "    ${GREEN}[3]${NC} Meridian ${DIM}(Claude proxy)${NC}"
    echo -e "    ${GREEN}[4]${NC} Engram ${DIM}(persistent memory)${NC}"
    echo -e "    ${GREEN}[5]${NC} Hyprland ${DIM}(tiling WM)${NC}"
    echo -e "    ${GREEN}[6]${NC} OpenVPN3"
    echo ""
    echo -e "  ${DIM}Example: '3 6' skips Meridian + VPN${NC}"
    echo -e "  ${DIM}Press Enter to install all${NC}"
    echo ""
    read -rp "  ${BOLD}→${NC} " DESELECT

    for num in $DESELECT; do
        case "$num" in
            1) INSTALL_FISH=false ;;
            2) INSTALL_OPENCODE=false ;;
            3) INSTALL_MERIDIAN=false ;;
            4) INSTALL_ENGRAM=false ;;
            5) INSTALL_HYPRLAND=false ;;
            6) INSTALL_OPENVPN=false ;;
        esac
    done
    echo ""
else
    echo -e "  ${DIM}--all mode: installing everything${NC}"
    echo ""
fi

# ─── Sudo cache ────────────────────────────────────────
if command -v sudo &>/dev/null; then
    echo -e "${YELLOW}Enter sudo password (cached for this session):${NC}"
    sudo -v
    (while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null) &
    echo ""
fi

# ─── Platform ──────────────────────────────────────────
OS="$(uname -s)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES="$SCRIPT_DIR"

if [ ! -f "$DOTFILES/opencode/AGENTS.md" ]; then
    error "Run from dotfiles repo root (missing opencode/AGENTS.md)"
    exit 1
fi

success "dotfiles found at ${DOTFILES}"

# ─── Helper ────────────────────────────────────────────
dnf_install() {
    local pkg="$1"
    if rpm -q "$pkg" &>/dev/null; then
        info "${pkg} already installed"
        return 0
    fi
    info "installing ${pkg}..."
    if sudo dnf install -y "$pkg" &>/dev/null; then
        success "${pkg}"
    else
        warn "failed to install ${pkg}"
    fi
}

# ============================================================
# 1. Fish Shell
# ============================================================
if [ "$INSTALL_FISH" = true ]; then
    step "Fish shell"
    if [ "$OS" = "Linux" ]; then
        dnf_install fish
    elif command -v brew &>/dev/null; then
        brew list fish &>/dev/null || brew install fish
    fi
    command -v fish &>/dev/null && success "Fish ready"
fi

# ============================================================
# 2. OpenCode
# ============================================================
if [ "$INSTALL_OPENCODE" = true ]; then
    step "OpenCode"
    if command -v opencode &>/dev/null; then
        success "OpenCode $(opencode --version 2>/dev/null || echo '') installed"
    else
        info "downloading OpenCode..."
        curl -fsSL https://opencode.ai/install | bash
        success "OpenCode installed"
    fi
fi

# ============================================================
# 3. Meridian
# ============================================================
if [ "$INSTALL_MERIDIAN" = true ]; then
    step "Meridian — Claude Pro proxy"
    if command -v meridian &>/dev/null; then
        success "Meridian installed"
    else
        info "installing via npm..."
        npm install -g @rynfar/meridian 2>/dev/null || warn "npm install failed"
        command -v meridian &>/dev/null && success "Meridian installed"
    fi
fi

# ============================================================
# 4. Engram
# ============================================================
if [ "$INSTALL_ENGRAM" = true ]; then
    step "Engram — persistent memory"
    if command -v engram &>/dev/null; then
        success "Engram $(engram version 2>/dev/null || echo '') installed"
    else
        info "downloading Engram..."
        curl -fsSL https://engram.ai/install | bash 2>/dev/null || warn "install failed"
        command -v engram &>/dev/null && success "Engram installed"
    fi
fi

# ============================================================
# 5. Config files
# ============================================================
step "Config files"

# Fish
mkdir -p ~/.config/fish
cp "$DOTFILES/fish/config.fish" ~/.config/fish/config.fish 2>/dev/null || true
success "~/.config/fish/"

# OpenCode
mkdir -p ~/.config/opencode/{skills,prompts,commands,plugins,acp,themes}
cp -r "$DOTFILES/opencode/skills/"*    ~/.config/opencode/skills/    2>/dev/null || true
cp -r "$DOTFILES/opencode/prompts/"*   ~/.config/opencode/prompts/   2>/dev/null || true
cp -r "$DOTFILES/opencode/commands/"*  ~/.config/opencode/commands/  2>/dev/null || true
cp -r "$DOTFILES/opencode/themes/"*    ~/.config/opencode/themes/    2>/dev/null || true
cp "$DOTFILES/opencode/plugins/"*.ts   ~/.config/opencode/plugins/   2>/dev/null || true
cp "$DOTFILES/opencode/AGENTS.md"      ~/.config/opencode/           2>/dev/null || true
cp "$DOTFILES/opencode/tui.json"       ~/.config/opencode/           2>/dev/null || true
cp "$DOTFILES/opencode/package.json"   ~/.config/opencode/           2>/dev/null || true
cp "$DOTFILES/opencode/bun.lock"       ~/.config/opencode/           2>/dev/null || true
cp "$DOTFILES/opencode/acp/avante-nvim.lua" ~/.config/opencode/acp/  2>/dev/null || true
success "~/.config/opencode/"

# opencode.json template
cp "$DOTFILES/opencode/opencode.json.template" ~/.config/opencode/opencode.json 2>/dev/null || true
sed -i "s|__HOME__|$HOME|g" ~/.config/opencode/opencode.json 2>/dev/null || true
ENGRAM_BIN=$(command -v engram 2>/dev/null || echo "/home/linuxbrew/.linuxbrew/bin/engram")
sed -i "s|/home/linuxbrew/.linuxbrew/bin/engram|$ENGRAM_BIN|g" ~/.config/opencode/opencode.json 2>/dev/null || true
success "opencode.json from template"

# Systemd user services
if [ "$OS" = "Linux" ]; then
    mkdir -p ~/.config/systemd/user
    cp "$DOTFILES/systemd/opencode-server.service" ~/.config/systemd/user/ 2>/dev/null || true
    cp "$DOTFILES/systemd/meridian.service"        ~/.config/systemd/user/ 2>/dev/null || true
    success "systemd user services"
fi

# Zed
mkdir -p ~/.config/zed
cp "$DOTFILES/zed/settings.json" ~/.config/zed/settings.json 2>/dev/null || true
success "~/.config/zed/"

# Hyprland config (always copy if present)
if [ -d "$DOTFILES/hypr" ]; then
    mkdir -p ~/.config/hypr
    cp -r "$DOTFILES/hypr/"* ~/.config/hypr/
    mkdir -p ~/.config/hypr/wallpaper_effects
    success "~/.config/hypr/"
fi

# ============================================================
# 6. Git credential helper
# ============================================================
step "Git credential helper"
mkdir -p ~/.local/bin
cp "$DOTFILES/bin/git-credential-github-token" ~/.local/bin/ 2>/dev/null || true
chmod +x ~/.local/bin/git-credential-github-token 2>/dev/null || true
git config --global credential.helper "$HOME/.local/bin/git-credential-github-token" 2>/dev/null || true
success "credential helper"

if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo ""
    echo -e "  ${YELLOW}GitHub Personal Access Token${NC} ${DIM}(or Enter to skip)${NC}"
    read -rsp "  → " TOKEN
    echo ""
else
    TOKEN="$GITHUB_TOKEN"
    info "GITHUB_TOKEN from environment"
fi
if [ -n "${TOKEN:-}" ]; then
    mkdir -p ~/.config/fish/conf.d
    echo "# Auto-generated by OpenCode bootstrap" > ~/.config/fish/conf.d/github-token.fish
    echo "set -x GITHUB_TOKEN $TOKEN" >> ~/.config/fish/conf.d/github-token.fish
    success "GITHUB_TOKEN saved"
fi

# ============================================================
# 7. Plugin dependencies
# ============================================================
step "Plugin dependencies"
if command -v bun &>/dev/null; then
    (cd ~/.config/opencode && bun install --silent 2>/dev/null) && success "bun install" || warn "bun install failed"
else
    warn "Bun not found — plugins may not work"
    echo -e "  ${DIM}Install: curl -fsSL https://bun.sh/install | bash${NC}"
fi

# ============================================================
# 8. Systemd services
# ============================================================
if [ "$OS" = "Linux" ]; then
    step "Systemd services"
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable --now meridian.service 2>/dev/null      && success "Meridian enabled"      || warn "Meridian service failed"
    systemctl --user enable --now opencode-server.service 2>/dev/null && success "OpenCode server enabled" || warn "OpenCode service failed"
fi

# ============================================================
# 9. Hyprland
# ============================================================
if [ "$INSTALL_HYPRLAND" = true ] && [ "$OS" = "Linux" ]; then
    step "Hyprland — tiling compositor"

    HYPR_PKGS="hyprland hypridle hyprlock hyprcursor hyprutils hyprpicker hyprsunset hyprpolkitagent xdg-desktop-portal-hyprland hyprland-uwsm"
    HYPR_TOOLS="swww waybar wallust kitty rofi-wayland"

    for pkg in $HYPR_PKGS $HYPR_TOOLS; do
        dnf_install "$pkg"
    done

    [ -d ~/.config/hypr ] && success "Hyprland configured"
    warn "Edit ~/.config/hypr/monitors.conf for your display"
fi

# ============================================================
# 10. OpenVPN3
# ============================================================
if [ "$INSTALL_OPENVPN" = true ] && [ "$OS" = "Linux" ]; then
    step "OpenVPN 3"
    VPN_CONFIG_NAME="dotfiles-vpn"

    if ! command -v openvpn3 &>/dev/null; then
        warn "OpenVPN3 not installed — skipping"
    else
        OVPN_PATH="${OVPN_PATH:-}"
        if [ -z "$OVPN_PATH" ]; then
            echo -e "  ${YELLOW}Path to .ovpn profile${NC} ${DIM}(or Enter to skip)${NC}"
            read -r OVPN_PATH
        else
            info "OVPN_PATH from environment"
        fi

        if [ -n "$OVPN_PATH" ] && [ -f "$OVPN_PATH" ]; then
            openvpn3 config-remove --config "$VPN_CONFIG_NAME" --force 2>/dev/null || true
            sudo systemctl stop "openvpn3-session@${VPN_CONFIG_NAME}.service"  2>/dev/null || true
            sudo systemctl disable "openvpn3-session@${VPN_CONFIG_NAME}.service" 2>/dev/null || true

            openvpn3 config-import --config "$OVPN_PATH" --name "$VPN_CONFIG_NAME" --persistent
            openvpn3 config-acl --config "$VPN_CONFIG_NAME" --grant root --transfer-owner-session true --lock-down true
            openvpn3 config-manage --config "$VPN_CONFIG_NAME" --dns-scope tunnel
            sudo systemctl enable --now "openvpn3-session@${VPN_CONFIG_NAME}.service"
            success "VPN auto-connect enabled"
        elif [ -n "$OVPN_PATH" ]; then
            error "File not found: $OVPN_PATH"
        fi
    fi
fi

# ============================================================
# Done
# ============================================================
echo ""
echo -e "${GREEN}${BOLD}"
echo "  ___                   _      _  "
echo " / _ \ _   _  ___ _ __ | |_   / \ "
echo "| | | | | | |/ _ \ '_ \| __| / _ \\"
echo "| |_| | |_| |  __/ | | | |_ / ___ \\"
echo " \___/ \__,_|\___|_| |_|\__/_/   \_\\"
echo -e "${NC}"
echo ""
echo -e "  ${BOLD}${GREEN}Bootstrap complete!${NC}"
echo ""
echo -e "  ${BOLD}Next:${NC}"
echo -e "  ${DIM}1.${NC} Restart shell: ${BOLD}exec fish${NC}"
echo -e "  ${DIM}2.${NC} Edit API keys in ${DIM}~/.config/opencode/opencode.json${NC}"
echo -e "  ${DIM}3.${NC} Run ${BOLD}opencode${NC} and ${DIM}/connect${NC} to configure LLM providers"
echo ""
