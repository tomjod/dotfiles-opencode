#!/usr/bin/env bash
# ============================================================
# OpenCode Pro Bootstrap — replica tu setup en cualquier PC
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

# ─── Detect OS ──────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
    Linux)   PKG_MANAGER="apt|dnf|pacman|brew";;
    Darwin)  PKG_MANAGER="brew";;
    *)       fail "Unsupported OS: $OS (Linux or macOS expected)";;
esac

echo ""
echo "============================================"
echo "  OpenCode Pro Bootstrap"
echo "============================================"
echo ""

# ─── Check: dotfiles directory exists ───────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES="$SCRIPT_DIR"

if [ ! -f "$DOTFILES/opencode/AGENTS.md" ]; then
    fail "Run from dotfiles repo root. Expected opencode/AGENTS.md"
fi

# ─── 1. Fish Shell ─────────────────────────────────────
info "Step 1/8: Fish shell"
if command -v fish &>/dev/null; then
    log "Fish already installed"
else
    warn "Fish not found. Install it:"
    echo "    Linux: sudo apt install fish   or   sudo pacman -S fish"
    echo "    macOS: brew install fish"
    echo ""
    read -rp "Press enter after installing fish..."
fi

# ─── 2. OpenCode ────────────────────────────────────────
info "Step 2/8: OpenCode"
if command -v opencode &>/dev/null; then
    log "OpenCode $(opencode --version 2>/dev/null || echo '?') installed"
else
    warn "Installing OpenCode..."
    curl -fsSL https://opencode.ai/install | bash
    log "OpenCode installed"
fi

# ─── 3. Meridian (Claude Pro proxy) ────────────────────
info "Step 3/8: Meridian — Claude Pro proxy"
if command -v meridian &>/dev/null; then
    log "Meridian $(meridian --version 2>/dev/null || echo '?') installed"
else
    warn "Meridian not found. Install via: npm install -g @rynfar/meridian"
    read -rp "Press enter after installing..."
fi

# ─── 4. Engram ──────────────────────────────────────────
info "Step 4/8: Engram (persistent memory)"
if command -v engram &>/dev/null; then
    log "Engram installed ($(engram version 2>/dev/null || echo '?'))"
else
    warn "Engram not found."
    echo "  Install via: curl -fsSL https://engram.ai/install | bash"
    echo "  Or: brew install engram"
    echo ""
    read -rp "Press enter after installing engram (or type 'skip' to continue without it)..."
    if [ "$REPLY" = "skip" ]; then
        warn "Skipping Engram — memory persistence will be disabled"
    fi
fi

# ─── 4. Copy config files ───────────────────────────────
info "Step 5/8: Config files"

# Fish
mkdir -p ~/.config/fish
cp "$DOTFILES/fish/config.fish" ~/.config/fish/config.fish
log "Fish config → ~/.config/fish/config.fish"

# OpenCode
mkdir -p ~/.config/opencode/{skills,prompts,commands,plugins,acp,themes}
cp -r "$DOTFILES/opencode/skills/"* ~/.config/opencode/skills/
cp -r "$DOTFILES/opencode/prompts/"* ~/.config/opencode/prompts/
cp -r "$DOTFILES/opencode/commands/"* ~/.config/opencode/commands/
cp -r "$DOTFILES/opencode/themes/"* ~/.config/opencode/themes/
cp "$DOTFILES/opencode/plugins/"*.ts ~/.config/opencode/plugins/
cp "$DOTFILES/opencode/AGENTS.md" ~/.config/opencode/
cp "$DOTFILES/opencode/tui.json" ~/.config/opencode/
cp "$DOTFILES/opencode/package.json" ~/.config/opencode/ 2>/dev/null || warn "package.json not found — plugins may not work"
cp "$DOTFILES/opencode/bun.lock" ~/.config/opencode/ 2>/dev/null || true
cp "$DOTFILES/opencode/acp/avante-nvim.lua" ~/.config/opencode/acp/ 2>/dev/null || true
log "OpenCode config → ~/.config/opencode/"

# opencode.json — asks for secrets
if [ -f ~/.config/opencode/opencode.json ]; then
    warn "opencode.json already exists, skipping (backup at opencode.json.bak)"
    cp ~/.config/opencode/opencode.json ~/.config/opencode/opencode.json.bak
fi
cp "$DOTFILES/opencode/opencode.json.template" ~/.config/opencode/opencode.json
sed -i "s|__HOME__|$HOME|g" ~/.config/opencode/opencode.json

# Auto-detect engram binary path (prefer PATH, fallback to known locations)
ENGRAM_BIN=$(command -v engram 2>/dev/null || echo "/home/linuxbrew/.linuxbrew/bin/engram")
sed -i "s|/home/linuxbrew/.linuxbrew/bin/engram|$ENGRAM_BIN|g" ~/.config/opencode/opencode.json

log "opencode.json from template (secrets need manual setup — see below)"

# Systemd (Linux only)
if [ "$OS" = "Linux" ]; then
    mkdir -p ~/.config/systemd/user
    cp "$DOTFILES/systemd/opencode-server.service" ~/.config/systemd/user/
    cp "$DOTFILES/systemd/meridian.service" ~/.config/systemd/user/
    log "Systemd services → ~/.config/systemd/user/"
fi

# Zed
mkdir -p ~/.config/zed
cp "$DOTFILES/zed/settings.json" ~/.config/zed/settings.json
log "Zed ACP config → ~/.config/zed/settings.json"

# ─── 5. Git credential helper ──────────────────────────
info "Step 6/8: Git credential helper (GITHUB_TOKEN)"
mkdir -p ~/.local/bin
cp "$DOTFILES/bin/git-credential-github-token" ~/.local/bin/
chmod +x ~/.local/bin/git-credential-github-token
git config --global credential.helper "$HOME/.local/bin/git-credential-github-token"

# GITHUB_TOKEN setup for fish
ask "Enter your GitHub Personal Access Token (or press enter to skip):"
read -rs TOKEN
if [ -n "$TOKEN" ]; then
    mkdir -p ~/.config/fish/conf.d
    echo "# Auto-generated by OpenCode bootstrap" > ~/.config/fish/conf.d/github-token.fish
    echo "set -x GITHUB_TOKEN $TOKEN" >> ~/.config/fish/conf.d/github-token.fish
    log "GITHUB_TOKEN saved for fish (~/.config/fish/conf.d/github-token.fish)"
else
    warn "Skipping GITHUB_TOKEN — git push will prompt for credentials"
fi
echo ""

# ─── 6. Install plugin dependencies ─────────────────────
info "Step 7/8: Plugin dependencies (bun install)"
if command -v bun &>/dev/null; then
    (cd ~/.config/opencode && bun install --silent 2>/dev/null && log "Dependencies installed") || warn "bun install failed — plugins may not work"
else
    warn "Bun not found. Install it: curl -fsSL https://bun.sh/install | bash"
    warn "Then run: cd ~/.config/opencode && bun install"
fi

# ─── 8. Systemd services ─────────────────────────────────
if [ "$OS" = "Linux" ]; then
    systemctl --user daemon-reload 2>/dev/null
    systemctl --user enable meridian.service 2>/dev/null && \
        systemctl --user start meridian.service 2>/dev/null && \
        log "Meridian (Claude proxy) enabled and started" || \
        warn "Meridian systemd setup failed"
    systemctl --user enable opencode-server.service 2>/dev/null && \
        systemctl --user start opencode-server.service 2>/dev/null && \
        log "OpenCode server enabled and started" || \
        warn "OpenCode systemd setup failed"
else
    warn "Systemd not available — use 'ocs-start' manually"
fi

# ─── 9. API Keys reminder ───────────────────────────────
echo ""
echo "============================================"
echo "  ⚠️  MANUAL STEPS REQUIRED"
echo "============================================"
echo ""
ask "1. Stitch API Key (UI design generation)"
echo "   Edit ~/.config/opencode/opencode.json"
echo "   Search for: YOUR_STITCH_API_KEY"
echo "   Replace with your Google AI Studio key"
echo ""
ask "2. Supabase project (database)"
echo "   Edit ~/.config/opencode/opencode.json"
echo "   Search for: YOUR_SUPABASE_PROJECT_REF"
echo "   Replace with your project ref (or disable supabase MCP)"
echo ""
ask "3. Model API keys (OpenAI / Anthropic / DeepSeek)"
echo "   Run 'opencode' or '/connect' in TUI to configure providers"
echo ""
ask "4. VS Code Settings"
echo "   OpenCode extension auto-installs on first 'opencode' run"
echo "   To copy additional settings, merge from your dotfiles backup:"
echo "   ~/.config/Code/User/settings.json"
echo ""
echo "============================================"
echo "  🎉 BOOTSTRAP COMPLETE"
echo "============================================"
echo ""
echo "  Restart your shell:"
echo "    exec fish"
echo ""
echo "  Available commands (Fish):"
echo "    oc          → opencode"
echo "    ocs         → opencode serve"
echo "    oca         → opencode acp"
echo "    ocs-start   → start server service"
echo "    ocs-status  → check server status"
echo "    ocs-logs    → tail server logs"
echo ""
