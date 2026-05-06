# OpenCode Pro Dotfiles

Mi configuración completa de OpenCode "modo pro" — orquestador multi-modelo, SDD pipeline, memoria persistente, 21 skills, LSP, server mode, ACP.

## Quick Start (máquina nueva)

```bash
git clone https://github.com/TU_USER/dotfiles-opencode.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
exec fish
```

## Qué incluye

| Componente | Archivos |
|---|---|
| **Orquestador SDD** | 3 orquestadores (deepseek, chatgpt, claude) × 10 fases = 30 sub-agentes |
| **Skills** | 21 skills: SDD phases, branch-pr, chained-pr, cognitive-doc, go-testing, judgment-day, etc. |
| **Prompts** | 10 SDD prompt files (apply, archive, design, explore, init, onboard, propose, spec, tasks, verify) |
| **Commands** | 9 custom slash commands (/sdd-new, /sdd-ff, /sdd-explore, etc.) |
| **Plugins** | Background Agents (async delegation) + Engram (persistent memory) |
| **LSP** | Auto-detect: TypeScript, Go, Rust, Python, Kotlin, Java, ESLint, Oxlint |
| **Formatters** | Prettier (TS), gofmt (Go), ruff (Python), ktlint (Kotlin) |
| **Server** | Systemd user service on port 4096 |
| **ACP** | Configs for Zed and Neovim/Avante |
| **Shell** | Fish config with env vars and aliases |

## Requisitos

- OpenCode (`curl -fsSL https://opencode.ai/install | bash`)
- Fish shell (`apt install fish` / `brew install fish`)
- Bun (`curl -fsSL https://bun.sh/install | bash`)
- Engram opcional (`curl -fsSL https://engram.ai/install | bash`) — para memoria persistente

## Secrets (setup manual)

Después del bootstrap, edita `~/.config/opencode/opencode.json`:

1. `YOUR_STITCH_API_KEY` → Google AI Studio API key
2. `YOUR_SUPABASE_PROJECT_REF` → tu project ref de Supabase
3. Model API keys → ejecuta `opencode` y usa `/connect`

## Actualizar desde el repo

```bash
cd ~/dotfiles
git pull
./bootstrap.sh
```
