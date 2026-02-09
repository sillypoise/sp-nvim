# UIStyle Rulebook — Strict / Full

## Preamble

### Purpose

This document is a strict, platform-agnostic UI rulebook distilled from high-signal usability guidance.
It is designed for `AGENTS.md`, review checklists, and design/implementation prompts.
Every rule is written as an enforceable statement.

### Design Goal Priority

When goals conflict, apply this order:

1. **Accessibility & Comprehension** — everyone can perceive and operate core flows.
2. **Trust & Safety** — consent, privacy, and predictable system behavior.
3. **Task Efficiency** — low friction to complete meaningful work.
4. **Consistency & Maintainability** — coherent patterns that scale.

### Keyword Definitions (RFC 2119)

- **MUST / SHALL** — absolute requirement; violations are defects.
- **MUST NOT / SHALL NOT** — absolute prohibition; violations are defects.
- **SHOULD** — strong recommendation; deviations require clear rationale.

### How to Use This Document

- Reference rules by ID (for example: `UXR-A11Y-002`) in reviews and PR comments.
- The compact variant keeps the same IDs and ordering for cross-reference.
- All rules are platform-agnostic; adapt examples to your stack.

---

## Core Interaction Principles (CORE)

### UXR-CORE-001 — Establish visual hierarchy around primary tasks.

Each view MUST make the primary task and primary action visually dominant over secondary content.

Rationale: People should not need to search for the main action.

Example: The primary call to action is visually stronger and appears near the task content.

### UXR-CORE-002 — Keep equivalent actions behaviorally consistent.

Equivalent actions MUST behave the same way across screens and states.

Rationale: Behavioral consistency reduces relearning cost and error rate.

Example: "Save" always commits edits and returns the same success signal.

### UXR-CORE-003 — Follow established platform conventions by default.

Patterns SHOULD follow host-platform conventions unless measurable usability gains justify divergence.

Rationale: Familiar patterns reduce onboarding burden.

Example: Use standard navigation and menu placement before inventing custom patterns.

### UXR-CORE-004 — Keep secondary detail out of critical paths.

Secondary or decorative content MUST NOT block or delay core task completion.

Rationale: Priority inversion creates friction in common workflows.

Example: Optional education appears after, not before, required completion steps.

---

## Accessibility & Multimodal Access (A11Y)

### UXR-A11Y-001 — Never encode critical meaning in one sensory channel.

Critical information MUST NOT rely on color alone, audio alone, or motion alone.

Rationale: Single-channel signaling excludes users and fails in constrained contexts.

Example: Errors use text + icon + color, not red color only.

### UXR-A11Y-002 — Preserve legibility under user text scaling.

Text and essential icons MUST remain legible and functional at user-scaled text sizes.

Rationale: Large-text support is a baseline accessibility requirement.

Example: Layout reflows without clipping when text size increases.

### UXR-A11Y-003 — Enforce minimum target size and spacing.

Interactive controls MUST meet a documented minimum target size and minimum spacing token.

Rationale: Small crowded controls increase accidental activation.

Example: Design tokens define min target and adjacent gap for all interactive elements.

### UXR-A11Y-004 — Keep core flows operable with assistive input.

Core flows MUST be operable by keyboard and assistive technologies with meaningful labels and focus order.

Rationale: Input modality must not gate critical tasks.

Example: Every actionable element has an accessible name and deterministic focus sequence.

---

## Inclusion & Localization (INCL)

### UXR-INCL-001 — Use plain, inclusive language.

User-facing copy MUST use plain, inclusive language and MUST NOT include exclusionary idioms.

Rationale: Plain language broadens comprehension and translation quality.

Example: Replace colloquial phrases with direct wording.

### UXR-INCL-002 — Prefer gender-neutral generic phrasing.

Generic references to people SHOULD be gender-neutral unless a domain requirement dictates otherwise.

Rationale: Neutral phrasing avoids unnecessary exclusion and localization complexity.

Example: Use "they" or role nouns rather than gendered defaults.

### UXR-INCL-003 — Design for localization expansion and locale formatting.

Layouts MUST tolerate text expansion and MUST use locale-aware formats for date, time, number, and currency.

Rationale: Hardcoded assumptions break global usability.

Example: Labels can grow without truncating actions.

### UXR-INCL-004 — Avoid culture-specific assumptions in core workflows.

Core workflows MUST NOT require culture-specific references or prior domain context to succeed.

Rationale: Hidden assumptions silently exclude users.

Example: Security prompts avoid culturally narrow knowledge questions.

---

## Privacy, Permissions & Data Trust (PRIV)

### UXR-PRIV-001 — Request only data needed for the current feature.

Data requests MUST be scoped to the minimum needed to complete the immediate user task.

Rationale: Data minimization improves trust and reduces risk.

Example: Ask for location only when user invokes a location-dependent action.

### UXR-PRIV-002 — Trigger permission requests at point of need.

Permission prompts MUST occur at point of need unless the permission is essential at first launch.

Rationale: Contextual prompts have higher comprehension and lower denial surprise.

Example: Camera permission appears when user taps "Scan", not on app start.

### UXR-PRIV-003 — Explain consent requests in concrete language.

Permission rationale text MUST state what is accessed, why it is needed, and user benefit in plain language.

Rationale: Vague consent copy erodes trust.

Example: "Use microphone to record voice notes" instead of "Microphone needed."

### UXR-PRIV-004 — Prohibit manipulative consent design.

Consent flows MUST NOT use deceptive visual hierarchy, imitation system prompts, or incentives to force acceptance.

Rationale: Manipulation invalidates meaningful consent.

Example: Pre-prompt uses one neutral "Continue" action that opens the system prompt.

---

## Writing & UI Messaging (WRIT)

### UXR-WRIT-001 — Use explicit action labels.

Action labels MUST be specific and action-oriented.

Rationale: Explicit labels improve prediction of outcomes.

Example: "Delete file" is clearer than "OK".

### UXR-WRIT-002 — Keep copy concise and purposeful.

Copy SHOULD remove nonessential words, especially in constrained surfaces.

Rationale: Brevity improves scan speed and comprehension.

Example: Keep confirmation text to one short sentence when possible.

### UXR-WRIT-003 — Make errors actionable.

Error messages MUST explain what failed and MUST provide a concrete recovery step.

Rationale: Non-actionable errors trap users.

Example: "Password must be at least 12 characters" with an inline fix hint.

### UXR-WRIT-004 — Make empty states productive.

Empty states MUST communicate the state and provide at least one clear next step.

Rationale: Empty views should teach, not dead-end.

Example: "No projects yet" + "Create project" action.

---

## Layout, Adaptivity & Directionality (LAY)

### UXR-LAY-001 — Group related items and separate unrelated ones.

Related controls/content MUST be visually grouped, and unrelated items MUST be visually separated.

Rationale: Grouping reduces search and interpretation cost.

Example: Form fields and helper text are grouped; destructive actions are separated.

### UXR-LAY-002 — Adapt without losing capability.

Layouts MUST adapt to viewport, orientation, and window-size changes without removing core capability.

Rationale: Responsive behavior must preserve task completion.

Example: Dense multicolumn view collapses progressively while keeping key actions reachable.

### UXR-LAY-003 — Respect safe and reserved interface regions.

Content and controls MUST respect safe areas and system-reserved regions.

Rationale: Occluded actions are effectively unavailable.

Example: Floating action bars avoid overlap with system gestures and overlays.

### UXR-LAY-004 — Mirror directional UI in RTL contexts.

Directional layout and navigation controls MUST mirror in right-to-left contexts; logos and universal symbols MUST NOT be mirrored.

Rationale: Directionality conveys reading and navigation flow.

Example: Back/forward controls flip in RTL; brand marks do not.

---

## Visual Semantics (VIS)

### UXR-VIS-001 — Meet contrast baseline in all supported themes.

Text and critical iconography MUST satisfy the project's documented contrast baseline across all supported themes.

Rationale: Contrast failures are readability failures.

Example: Same status text remains legible in both light and dark appearances.

### UXR-VIS-002 — Keep color meaning stable.

Semantic meanings mapped to color MUST remain consistent across screens and states.

Rationale: Reused color with conflicting meaning causes decision errors.

Example: Warning color is never reused to indicate success.

### UXR-VIS-003 — Provide non-color state cues.

Color MUST NOT be the sole indicator of state, status, or selection.

Rationale: Color-only cues fail for many users and environments.

Example: Selected items use shape/icon/label change in addition to color.

### UXR-VIS-004 — Preserve hierarchy under scale and density changes.

Typography and spacing SHOULD preserve information hierarchy when text size or density changes.

Rationale: Hierarchy collapse increases cognitive load.

Example: Headings remain visually distinct after dynamic scaling.

---

## Motion, Feedback & Progress (MOT)

### UXR-MOT-001 — Use motion only when it communicates value.

Motion MUST serve a functional purpose (feedback, transition, orientation) and MUST NOT be purely ornamental in default flows.

Rationale: Decorative motion adds cost without improving outcomes.

Example: Transition animation clarifies source and destination context.

### UXR-MOT-002 — Keep frequent interactions fast.

Animations on high-frequency interactions SHOULD be brief and low-latency.

Rationale: Repeated delays compound into significant friction.

Example: Toggle feedback is immediate and subtle.

### UXR-MOT-003 — Respect reduced-motion preferences.

Nonessential motion MUST be reduced or removed when users enable reduced-motion preferences.

Rationale: Motion sensitivity is a first-order accessibility concern.

Example: Replace animated zoom with crossfade in reduced-motion mode.

### UXR-MOT-004 — Show progress for non-instant operations.

Operations that are not near-instant MUST show progress; determinate progress SHOULD be used when duration is estimable.

Rationale: Status visibility lowers abandonment and repeat actions.

Example: Upload shows total percent when known, spinner when unknown.

---

## Input, Forms & Validation (INP)

### UXR-INP-001 — Minimize required input.

Forms MUST request only required information, and SHOULD prefill known values when accuracy is high.

Rationale: Input burden is a primary conversion blocker.

Example: Country defaults from locale but remains editable.

### UXR-INP-002 — Prefer constrained input over free text.

When valid options are enumerable, selection controls SHOULD be used instead of unconstrained text entry.

Rationale: Constrained input reduces invalid states.

Example: State/province chosen from a list, not typed arbitrarily.

### UXR-INP-003 — Validate early and close to the field.

Validation errors MUST appear near the affected field as soon as context allows.

Rationale: Delayed or distant errors increase correction cost.

Example: Email format warning appears inline after focus leaves field.

### UXR-INP-004 — Protect sensitive entry.

Sensitive inputs MUST use secure entry handling and MUST NOT prepopulate secret values.

Rationale: Secret leakage risk outweighs convenience.

Example: Password fields mask values and never autofill from plain text.

---

## Navigation, Search, Onboarding & Modality (NAV)

### UXR-NAV-001 — Keep primary navigation stable and discoverable.

Primary navigation MUST remain discoverable and structurally stable across major sections.

Rationale: Navigation instability breaks spatial memory.

Example: Core sections remain in consistent order and placement.

### UXR-NAV-002 — Scope search clearly.

If search is core to task completion, search entry MUST be easy to discover and its scope MUST be explicit.

Rationale: Hidden or ambiguous search causes false negatives.

Example: Placeholder and filter chips show where results come from.

### UXR-NAV-003 — Keep onboarding optional by default.

Onboarding SHOULD be skippable unless required for safe or legally required setup.

Rationale: Forced tutorials penalize returning and expert users.

Example: "Skip" is visible, with contextual tips available later.

### UXR-NAV-004 — Use modality sparingly and safely.

Modal surfaces MUST include an obvious dismiss path and MUST NOT stack competing modal layers.

Rationale: Modal stacking traps users and obscures context.

Example: Only one blocking dialog at a time, with explicit close action.

---

## Appendix A — Rule Index

- CORE: `UXR-CORE-001` to `UXR-CORE-004`
- A11Y: `UXR-A11Y-001` to `UXR-A11Y-004`
- INCL: `UXR-INCL-001` to `UXR-INCL-004`
- PRIV: `UXR-PRIV-001` to `UXR-PRIV-004`
- WRIT: `UXR-WRIT-001` to `UXR-WRIT-004`
- LAY: `UXR-LAY-001` to `UXR-LAY-004`
- VIS: `UXR-VIS-001` to `UXR-VIS-004`
- MOT: `UXR-MOT-001` to `UXR-MOT-004`
- INP: `UXR-INP-001` to `UXR-INP-004`
- NAV: `UXR-NAV-001` to `UXR-NAV-004`
