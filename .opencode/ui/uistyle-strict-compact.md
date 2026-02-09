# UIStyle Rulebook — Strict / Compact

## Preamble

This is the compact variant of the strict UIStyle rulebook.
Rule IDs are stable and match `ui/uistyle-strict-full.md`.

**Design goal priority:** Accessibility & Comprehension > Trust & Safety > Task Efficiency > Consistency & Maintainability.

**Keywords:** MUST / MUST NOT = absolute requirement. SHOULD = strong recommendation.

---

## Core Interaction Principles (CORE)

**UXR-CORE-001** — Each view MUST make the primary task and primary action visually dominant.
Rationale: People should not need to search for the main action.

**UXR-CORE-002** — Equivalent actions MUST behave the same way across screens and states.
Rationale: Consistency reduces relearning and mistakes.

**UXR-CORE-004** — Secondary or decorative content MUST NOT block core task completion.
Rationale: Priority inversion creates workflow friction.

---

## Accessibility & Multimodal Access (A11Y)

**UXR-A11Y-001** — Critical information MUST NOT rely on one sensory channel.
Rationale: Single-channel signaling excludes users.

**UXR-A11Y-002** — Text and essential icons MUST remain legible at user-scaled sizes.
Rationale: Large-text support is baseline accessibility.

**UXR-A11Y-003** — Interactive controls MUST meet documented minimum target size and spacing.
Rationale: Small crowded controls increase mis-taps.

**UXR-A11Y-004** — Core flows MUST be operable by keyboard and assistive technologies.
Rationale: Input modality must not gate critical tasks.

---

## Inclusion & Localization (INCL)

**UXR-INCL-001** — User-facing copy MUST use plain, inclusive language and MUST NOT use exclusionary idioms.
Rationale: Plain language broadens comprehension and localization quality.

**UXR-INCL-002** — Generic references to people SHOULD be gender-neutral unless domain-required.
Rationale: Neutral phrasing avoids unnecessary exclusion.

**UXR-INCL-003** — Layouts MUST tolerate text expansion and MUST use locale-aware formatting.
Rationale: Hardcoded assumptions fail globally.

**UXR-INCL-004** — Core workflows MUST NOT depend on culture-specific assumptions.
Rationale: Hidden assumptions silently exclude users.

---

## Privacy, Permissions & Data Trust (PRIV)

**UXR-PRIV-001** — Data requests MUST be limited to what is needed for the immediate task.
Rationale: Data minimization improves trust and lowers risk.

**UXR-PRIV-002** — Permission prompts MUST occur at point of need unless essential at first launch.
Rationale: Contextual prompts are clearer and less disruptive.

**UXR-PRIV-003** — Permission rationale MUST clearly state what is accessed, why, and user benefit.
Rationale: Concrete consent copy supports informed decisions.

**UXR-PRIV-004** — Consent flows MUST NOT use deceptive hierarchy, imitation prompts, or incentives.
Rationale: Manipulative consent is invalid consent.

---

## Writing & UI Messaging (WRIT)

**UXR-WRIT-001** — Action labels MUST be specific and action-oriented.
Rationale: Explicit labels improve outcome predictability.

**UXR-WRIT-002** — Copy SHOULD remove nonessential words.
Rationale: Brevity improves scan speed.

**UXR-WRIT-003** — Error messages MUST explain failure and provide a recovery step.
Rationale: Non-actionable errors trap users.

**UXR-WRIT-004** — Empty states MUST provide at least one clear next step.
Rationale: Empty views should teach, not dead-end.

---

## Layout, Adaptivity & Directionality (LAY)

**UXR-LAY-001** — Related items MUST be grouped; unrelated items MUST be separated.
Rationale: Grouping reduces search and interpretation cost.

**UXR-LAY-002** — Layouts MUST adapt to size/orientation/window changes without losing core capability.
Rationale: Responsive behavior must preserve task completion.

**UXR-LAY-003** — Content and controls MUST respect safe areas and system-reserved regions.
Rationale: Occluded actions are unavailable actions.

**UXR-LAY-004** — Directional UI MUST mirror in RTL; logos/universal symbols MUST NOT be mirrored.
Rationale: Preserve reading flow without breaking identity semantics.

---

## Visual Semantics (VIS)

**UXR-VIS-001** — Text and critical icons MUST meet documented contrast baseline in supported themes.
Rationale: Contrast failure is readability failure.

**UXR-VIS-002** — Semantic color meanings MUST stay consistent across screens and states.
Rationale: Conflicting color semantics cause decision errors.

**UXR-VIS-003** — Color MUST NOT be the sole indicator of state or status.
Rationale: Color-only cues are not robust.

---

## Motion, Feedback & Progress (MOT)

**UXR-MOT-001** — Motion MUST serve functional purpose and MUST NOT be default ornamental noise.
Rationale: Decorative motion adds cost without value.

**UXR-MOT-002** — High-frequency interactions SHOULD use brief, low-latency animation.
Rationale: Repeated delay compounds friction.

**UXR-MOT-003** — Nonessential motion MUST be reduced/removed when reduced-motion is enabled.
Rationale: Motion sensitivity is an accessibility concern.

**UXR-MOT-004** — Non-instant operations MUST show progress; determinate progress SHOULD be used when duration is estimable.
Rationale: Status visibility reduces abandonment.

---

## Input, Forms & Validation (INP)

**UXR-INP-001** — Forms MUST request only required information and SHOULD prefill accurate known values.
Rationale: Input burden blocks completion.

**UXR-INP-002** — Enumerated choices SHOULD use selection controls over free text.
Rationale: Constrained input prevents invalid states.

**UXR-INP-003** — Validation errors MUST appear near the affected field as early as context allows.
Rationale: Early local feedback lowers correction cost.

**UXR-INP-004** — Sensitive inputs MUST use secure entry and MUST NOT prepopulate secrets.
Rationale: Secret leakage risk outweighs convenience.

---

## Navigation, Search, Onboarding & Modality (NAV)

**UXR-NAV-001** — Primary navigation MUST remain discoverable and structurally stable.
Rationale: Stability preserves orientation and spatial memory.

**UXR-NAV-002** — Core search entry MUST be discoverable and its scope MUST be explicit.
Rationale: Ambiguous search causes false negatives.

**UXR-NAV-003** — Onboarding SHOULD be skippable unless required for safety or legal setup.
Rationale: Forced walkthroughs penalize returning users.

**UXR-NAV-004** — Modal surfaces MUST provide clear dismissal and MUST NOT stack competing modal layers.
Rationale: Modal stacking traps users and hides context.
