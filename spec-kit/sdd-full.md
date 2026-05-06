---
description: Initialize a project with BOTH Spec-Kit and Gentle AI SDD
handoffs:
  - label: Create Constitution
    agent: speckit.constitution
    prompt: Create project principles
  - label: Start SDD Change
    agent: sdd-new
    prompt: Start a new SDD change
---

## Full SDD Initialization

This command bootstraps a project with the best of BOTH worlds:

1. **Spec-Kit** (GitHub) → `.specify/` directory, constitution, `/speckit.*` commands
2. **Gentle AI SDD** → 10-phase pipeline, `/sdd-*` commands, Engram memory

### Workflow

```bash
# 1. Bootstrap Spec-Kit structure
specify init . --integration opencode --integration claude

# 2. Create project constitution (Spec-Kit)
/speckit.constitution $ARGUMENTS

# 3. Bootstrap SDD context (Gentle AI)
/sdd-init
```

### When to use what

| Phase | Use | Why |
|-------|-----|-----|
| Constitution & principles | `/speckit.constitution` | Spec-Kit has better templates |
| Feature specification | `/speckit.specify` | Natural language → spec |
| Technical plan | `/speckit.plan` | Tech stack + architecture |
| Task breakdown | `/speckit.tasks` OR `/sdd-tasks` | Spec-Kit for simple, SDD for complex |
| Implementation | `/sdd-apply` | Gentle AI has sub-agent delegation |
| Verification | `/sdd-verify` | Spec-Kit doesn't have this |
| Archive | `/sdd-archive` | Spec-Kit doesn't have this |
| GitHub Issues | `/speckit.taskstoissues` | Native GitHub integration |
| Code review | `/speckit.analyze` | Cross-artifact analysis |
