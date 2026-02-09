# OpenCode Guide Registry (VARIANTS)

This registry lists the available guide bundles in this directory. Repos should reference the
local paths listed here from their `AGENTS.md` and/or `opencode.json` `instructions`.

Default recommendation: start with `tigerstyle-strict-full.md` only, then add language and library
guides as needed.

---

## TigerStyle (Language-agnostic)

- TigerStyle — Strict / Full
  - Path: `tigerstyle-strict-full.md`
  - Scope: Base rules (language-agnostic)
- TigerStyle — Pragmatic / Full
  - Path: `tigerstyle-pragmatic-full.md`
  - Scope: Base rules (language-agnostic)
- TigerStyle — Strict / Compact
  - Path: `tigerstyle-strict-compact.md`
  - Scope: Base rules (summary)
- TigerStyle — Pragmatic / Compact
  - Path: `tigerstyle-pragmatic-compact.md`
  - Scope: Base rules (summary)

---

## UIStyle (Language-agnostic)

- UIStyle — Strict / Full
  - Path: `ui/uistyle-strict-full.md`
  - Scope: Cross-platform UI rulebook (comprehensive)
- UIStyle — Strict / Compact
  - Path: `ui/uistyle-strict-compact.md`
  - Scope: Cross-platform UI rulebook (summary)

---

## CSSStyle (Language-agnostic)

- CSSStyle — Pragmatic / Full
  - Path: `css/cssstyle-pragmatic-full.md`
  - Scope: Cross-platform CSS implementation playbook (comprehensive)
- CSSStyle — Pragmatic / Compact
  - Path: `css/cssstyle-pragmatic-compact.md`
  - Scope: Cross-platform CSS implementation playbook (summary)

---

## Programming Languages

- TypeScript TigerStyle (Strict/Pragmatic, Full/Compact)
  - Paths: `typescript/tigerstyle-ts-*.md`
- React TigerStyle (Strict/Pragmatic, Full/Compact)
  - Paths: `react/tigerstyle-react-*.md`
- Swift TigerStyle (Strict/Pragmatic, Full/Compact)
  - Paths: `swift/tigerstyle-swift-*.md`
- C TigerStyle (Strict/Pragmatic, Full/Compact)
  - Paths: `c/tigerstyle-c-*.md`
- C++ TigerStyle (Strict/Pragmatic, Full/Compact)
  - Paths: `cpp/tigerstyle-cpp-*.md`
- Rust TigerStyle (Strict/Pragmatic, Full/Compact)
  - Paths: `rust/tigerstyle-rs-*.md`
- Go TigerStyle (Strict/Pragmatic, Full/Compact)
  - Paths: `go/tigerstyle-go-*.md`
- Python TigerStyle (Strict/Pragmatic, Full/Compact)
  - Paths: `python/tigerstyle-py-*.md`
- Zig TigerStyle (Strict/Pragmatic, Full/Compact)
  - Paths: `zig/tigerstyle-zig-*.md`

---

## Frameworks and Libraries

- React Best Practices (Unified)
  - Path: `react/react-best-practices-unified.md`
- TanStack Query Best Practices
  - Path: `tanstack-query/tanstack-query-best-practices.md`

---

## Usage

- Per-repo `AGENTS.md` should list the local paths of the guides it wants.
- Use `opencode.json` `instructions` to load `AGENTS.md`.
- Load CSSStyle when you want implementation-level CSS defaults and patterns.
- If CSSStyle guidance conflicts with UIStyle heuristics, UIStyle takes precedence.
