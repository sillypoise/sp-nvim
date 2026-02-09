# CSSStyle Playbook - Pragmatic / Full

## Purpose

This guide captures practical CSS defaults for day-to-day project work.
Use it to implement consistent, resilient UI quickly.

This is an implementation playbook, not a design policy spec.

## Scope and Precedence

- Default behavior: follow these patterns unless project constraints require otherwise.
- If this guide conflicts with `ui/uistyle-*`, **UIStyle wins**.
- Use this guide to implement UIStyle outcomes with concrete CSS patterns.

## Working Baseline

- Assume modern browser support by default.
- You MAY use modern features like `:has()`, container queries, `text-wrap`, and fluid `clamp()` scales.
- For each modern feature in a critical path, provide a reasonable fallback.
- Prefer progressive enhancement over hard polyfill dependency where possible.

---

## 1) Token-First Foundations

Define core design tokens in `:root` before writing components.

```css
:root {
  /* Type scale */
  --step--1: clamp(0.85rem, 0.83rem + 0.15vw, 0.95rem);
  --step-0: clamp(1rem, 0.96rem + 0.25vw, 1.125rem);
  --step-1: clamp(1.2rem, 1.08rem + 0.6vw, 1.5rem);
  --step-2: clamp(1.45rem, 1.2rem + 1.2vw, 2rem);

  /* Space scale */
  --space-2xs: clamp(0.5rem, 0.45rem + 0.2vw, 0.625rem);
  --space-xs: clamp(0.75rem, 0.65rem + 0.4vw, 1rem);
  --space-s: clamp(1rem, 0.9rem + 0.5vw, 1.25rem);
  --space-m: clamp(1.5rem, 1.3rem + 0.9vw, 2rem);
  --space-l: clamp(2rem, 1.7rem + 1.3vw, 3rem);
  --space-s-l: clamp(1rem, 0.75rem + 1.2vw, 2.25rem);

  /* Shared constants */
  --radius-s: 0.35rem;
  --radius-m: 0.6rem;
  --stroke: max(1px, 0.08rem);
  --focus-ring: 0 0 0 max(2px, 0.14rem);
}
```

Pattern rules:

- Keep token names semantic and reusable.
- Use `rem` in scales to respect zoom and user font settings.
- Keep one source of truth for spacing, typography, radii, and strokes.

---

## 2) Fluid Typography and Space by Default

- Default to fluid type and spacing with `clamp()`.
- Add breakpoints only when fluid behavior cannot meet layout needs.
- Constrain long-form text with readable measure (`ch`-based width).

```css
.prose {
  max-inline-size: 65ch;
  font-size: var(--step-0);
  line-height: 1.6;
}

h1,
h2,
h3 {
  text-wrap: balance;
  line-height: 1.1;
}
```

---

## 3) Global Element Defaults

Create calm global defaults that reduce per-component repetition.

```css
*,
*::before,
*::after {
  box-sizing: border-box;
}

body {
  margin: 0;
  font-size: var(--step-0);
  line-height: 1.5;
  font-size-adjust: from-font;
}

img,
svg,
video {
  display: block;
  max-inline-size: 100%;
  block-size: auto;
}

iframe {
  inline-size: 100%;
  aspect-ratio: 16 / 9;
  border: 0;
}

ul:not([class]),
ol:not([class]) {
  padding-inline-start: 1.2em;
}

form > * + * {
  margin-block-start: var(--space-s);
}
```

Pattern rules:

- Style unclassed elements globally; style classed elements locally.
- Use relative units (`em`, `lh`, `ch`) when behavior should scale with text.
- Keep global rules low-specificity and easy to override.

---

## 4) Accessible Interaction Defaults

```css
/* Prefer visible keyboard focus only when relevant */
:focus {
  outline: none;
}

:focus-visible {
  outline: 2px solid currentColor;
  outline-offset: 0.18em;
  box-shadow: var(--focus-ring);
}

/* Native control theming before full custom widgets */
input,
textarea,
select,
button {
  font: inherit;
}

input,
textarea,
select {
  accent-color: currentColor;
}

/* Anchor jump compensation */
:target {
  scroll-margin-block-start: var(--space-l);
}
```

Pattern rules:

- Always provide a clear `:focus-visible` treatment.
- Use native control behavior first; custom control chrome is an enhancement.
- Keep touch target size and spacing consistent with your project baseline.

---

## 5) Composition Patterns Before Components

Build layout with compositional primitives, then place components inside.

### Flow (vertical rhythm)

```css
.flow > * + * {
  margin-block-start: var(--flow-space, var(--space-m));
}
```

### Wrapper (content width + page gutter)

```css
.wrapper {
  inline-size: min(100% - var(--space-m), var(--wrapper-max, 72rem));
  margin-inline: auto;
}
```

### Cluster (inline groups that wrap)

```css
.cluster {
  display: flex;
  flex-wrap: wrap;
  gap: var(--cluster-gap, var(--space-xs));
  align-items: center;
}
```

### Grid with local config

```css
.auto-grid {
  --grid-min: 16rem;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, var(--grid-min)), 1fr));
  gap: var(--grid-gap, var(--space-m));
}
```

Pattern rules:

- Use composition classes for layout concerns.
- Configure compositions through custom properties in context.
- Avoid baking layout behavior deeply into component selectors.

---

## 6) Component Pattern Defaults

Components should be small, token-driven, and variant-friendly.

```css
.button {
  --button-bg: CanvasText;
  --button-fg: Canvas;
  --button-radius: var(--radius-m);
  --button-pad-y: 0.55em;
  --button-pad-x: 1em;

  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.45em;
  padding: var(--button-pad-y) var(--button-pad-x);
  border: var(--stroke) solid transparent;
  border-radius: var(--button-radius);
  background: var(--button-bg);
  color: var(--button-fg);
  text-decoration: none;
}

.button[data-variant='ghost'] {
  --button-bg: transparent;
  --button-fg: CanvasText;
  border-color: currentColor;
}
```

Pattern rules:

- Start with one default variant and a small, finite variant set.
- Use local component variables for variant overrides.
- Avoid long selector chains and high specificity.

---

## 7) State and Exceptions

- Use semantic state hooks (`data-state`, `aria-*`, `[disabled]`) for finite states.
- Use `:has()` when parent styling should react to child state.
- Keep exception patterns explicit and rare.

```css
.field:has(input:invalid) {
  --field-border: oklch(55% 0.2 25);
}

.card[data-state='featured'] {
  --card-accent: oklch(70% 0.13 85);
}
```

---

## 8) Progressive Enhancement Policy

Use this order when shipping CSS features:

1. Base experience works without advanced feature.
2. Enhanced layer improves quality, not basic access.
3. Feature checks are local and minimal.

```css
.title {
  overflow-wrap: anywhere;
}

@supports (text-wrap: balance) {
  .title {
    overflow-wrap: normal;
    text-wrap: balance;
  }
}
```

---

## 9) Query Strategy

- Prefer fluid scaling first.
- Use container queries for component-local adaptation.
- Use media queries for global layout shifts and major interaction changes.
- Do not introduce queries where composition and fluid tokens already solve the problem.

```css
@container (min-width: 40rem) {
  .card-list {
    --grid-min: 18rem;
  }
}

@media (min-width: 64rem) {
  .site-nav {
    --cluster-gap: var(--space-s);
  }
}
```

---

## 10) Anti-Patterns to Avoid

- Pixel-locked typography or spacing for general UI.
- Large breakpoint trees for simple scale changes.
- Component CSS that hard-codes page layout assumptions.
- Utility sprawl that replaces semantic structure.
- Deep selector nesting and escalating specificity wars.
- Styling by DOM order assumptions when semantic state hooks are available.

---

## Quick PR Checklist

- Are tokens used instead of ad hoc magic numbers?
- Does fluid type/space solve most scaling before breakpoints?
- Are global defaults calm and low-specificity?
- Is keyboard focus visible and consistent?
- Are layout concerns in composition patterns, not component internals?
- Are variants/state handled via local variables and semantic hooks?
- Is modern CSS paired with sensible fallback on critical paths?
