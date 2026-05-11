# Model Profile Resolution — OpenCode Go (DeepSeek + Kimi + GLM)

Resolve model profile once at the start of orchestration, then use it for all Task spawns.

## Resolution Pattern

```bash
MODEL_PROFILE=$(cat .planning/config.json 2>/dev/null | grep -o '"model_profile"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"' || echo "balanced")
```

Default: `balanced` if not set or config missing.

## CRITICAL: Use FULL model IDs, never tier names

OpenCode Go does NOT recognize `opus`/`sonnet`/`haiku` as model names. You MUST pass full provider/model IDs like `opencode-go/deepseek-v4-pro`.

NEVER pass `"inherit"` as model — it causes OpenCode to use the parent's model, losing the per-agent optimization.

## Lookup Table

@/home/mv/.config/opencode/get-shit-done/references/model-profiles.md

Look up the agent in the `balanced` column. Pass the model parameter to Task calls using the FULL ID from the table:

```
Task(
  prompt="...",
  subagent_type="gsd-planner",
  model="opencode-go/deepseek-v4-pro"     # ← FULL ID, never "opus"
)
Task(
  prompt="...",
  subagent_type="gsd-codebase-mapper",
  model="opencode-go/deepseek-v4-flash"    # ← FULL ID, never "haiku"
)
```

## Usage

1. Resolve once at orchestration start
2. Look up each agent in the table for the active profile
3. Pass the EXACT model ID from the table to each Task call
4. NEVER substitute "inherit" or tier names — use the full ID from the table
