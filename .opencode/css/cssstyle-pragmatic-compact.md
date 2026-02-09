# CSSStyle Playbook - Pragmatic / Compact

## Purpose and Precedence

Practical CSS defaults for implementation speed and consistency.

- Follow these patterns unless project constraints require otherwise.
- If this guide conflicts with `ui/uistyle-*`, **UIStyle wins**.

---

## Default CSS Patterns

### 1) Start with tokens in `:root`

- Define fluid type and spacing tokens with `clamp()`.
- Keep shared constants (radius, stroke, focus ring) centralized.
- Use `rem`-based scales to respect zoom and user settings.

```css
:root {
  --step-0: clamp(1rem, 0.96rem + 0.25vw, 1.125rem);
  --space-s: clamp(1rem, 0.9rem + 0.5vw, 1.25rem);
  --space-m: clamp(1.5rem, 1.3rem + 0.9vw, 2rem);
  --radius-m: 0.6rem;
  --stroke: max(1px, 0.08rem);
}
```

### 2) Prefer fluid scaling before breakpoints

- Use fluid type and spacing first.
- Add media/container queries only when fluid behavior is not enough.
- Keep readable measure for long text (`max-inline-size: 60-70ch`).

### 3) Establish calm global defaults

- Set `box-sizing: border-box` globally.
- Style unclassed elements globally (`ul:not([class])`, etc.).
- Keep classed component styling local.
- Use relative units where text scaling should influence layout.

```css
form > * + * { margin-block-start: var(--space-s); }
img, svg, video { max-inline-size: 100%; block-size: auto; }
```

### 4) Keep interaction and forms accessible by default

- Always style `:focus-visible` clearly.
- Use native form behavior first and inherit fonts.
- Use `accent-color` before fully custom controls.
- Set `:target` `scroll-margin` to prevent anchor clipping.

```css
:focus-visible {
  outline: 2px solid currentColor;
  outline-offset: 0.18em;
}
```

### 5) Use composition patterns for layout

- Build page and section layout with composition primitives.
- Configure with local CSS variables in context.
- Keep components mostly layout-agnostic.

```css
.flow > * + * { margin-block-start: var(--flow-space, var(--space-m)); }
.wrapper { inline-size: min(100% - var(--space-m), 72rem); margin-inline: auto; }
.cluster { display: flex; flex-wrap: wrap; gap: var(--cluster-gap, var(--space-xs)); }
```

### 6) Make components token-driven and finite

- Define component-local variables for colors, radii, spacing.
- Build small variant sets with data attributes.
- Avoid deep selector nesting and specificity escalation.

```css
.button { --button-bg: CanvasText; --button-fg: Canvas; }
.button[data-variant='ghost'] { --button-bg: transparent; --button-fg: CanvasText; }
```

### 7) Model state semantically

- Prefer semantic hooks: `data-state`, `aria-*`, `[disabled]`.
- Use `:has()` where parent visuals depend on child state.

```css
.field:has(input:invalid) { --field-border: oklch(55% 0.2 25); }
```

### 8) Use modern CSS with fallback in critical paths

- Modern baseline is allowed (`:has`, container queries, `text-wrap`).
- Provide fallbacks where feature loss would harm core use.
- Enhancement should improve quality, not gate access.

```css
.title { overflow-wrap: anywhere; }
@supports (text-wrap: balance) {
  .title { overflow-wrap: normal; text-wrap: balance; }
}
```

---

## Avoid These Defaults

- Pixel-locked scale systems for general UI.
- Breakpoint-heavy choreography for simple responsive needs.
- Components that hard-code page-level layout assumptions.
- Utility sprawl and high-specificity selector stacks.
