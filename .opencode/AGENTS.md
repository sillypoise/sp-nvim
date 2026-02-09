# OpenCode Guides — Default

This file is a selector for the local guide bundle.

You can and should edit the repo-local `.opencode/AGENTS.md` to add guides from `VARIANTS.md`.
For example, if a repo is Go-heavy, add the Go TigerStyle guide from `go/` in the Active Guides
list.

## Active Guides

- `tigerstyle-strict-full.md`
- `ui/uistyle-strict-full.md`

## Mandatory Self-Review

Before finalizing any implementation task, re-review your own changes against all active guides.

- Treat every MUST/SHALL rule in active guides as a blocking requirement.
- Explicitly verify negative/error/boundary paths, not just happy paths.
- In your final summary, call out which guide rules most directly shaped the implementation.
- If a rule is intentionally not applied, state why and mark it as a project-level exception.

## Profile Examples

Use these examples in repo-local `.opencode/AGENTS.md`.

### Full Profile (recommended)

- `tigerstyle-strict-full.md`
- `ui/uistyle-strict-full.md`

### Frontend Full Profile

- `tigerstyle-strict-full.md`
- `ui/uistyle-strict-full.md`
- `css/cssstyle-pragmatic-full.md`

Note: If CSSStyle implementation guidance conflicts with UIStyle heuristics, UIStyle takes precedence.

### Compact Profile

- `tigerstyle-strict-compact.md`
- `ui/uistyle-strict-compact.md`

### Frontend Compact Profile

- `tigerstyle-strict-compact.md`
- `ui/uistyle-strict-compact.md`
- `css/cssstyle-pragmatic-compact.md`
