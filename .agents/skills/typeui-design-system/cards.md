# Cards

> Dependencies: `colors.md`, `radius.md`, `shadows.md`, `typography.md`

## Core Specs

- **Background:** translucent — `rgba(255,255,255,0.06)` in dark mode, `rgba(255,255,255,0.65)` in light mode
- **Backdrop filter:** `blur(16px) saturate(1.4)`
- **Border:** 1px, `rgba(255,255,255,0.10)` in dark mode, `rgba(255,255,255,0.50)` in light mode
- **Radius:** 16px (base)
- **Shadow:** shadow-md
- **Perspective:** Cards should be rendered inside a CSS `perspective()` context when used in grid layouts to enable subtle 3D tilt and depth effects on hover

## Card Heading

- Desktop: 20px, medium weight, heading color
- Mobile: 16px, medium weight, heading color
- Never skip heading levels — the page hierarchy must logically arrive at the card heading level.

## States

### Static Card (no interactivity)
- Background: translucent (see Core Specs)
- Backdrop filter: `blur(16px) saturate(1.4)`
- Border: 1px, translucent white (see Core Specs)
- Radius: 16px
- Shadow: shadow-md
- No hover styles. Non-interactive cards must NOT have hover background changes.

### Interactive Card (clickable)
- Same base styles as static card
- Hover: increase background opacity slightly — `rgba(255,255,255,0.10)` dark / `rgba(255,255,255,0.80)` light
- Hover: shadow-lg elevation step-up
- Hover: subtle `transform: translateY(-2px)` lift or 3D tilt via `rotateX`/`rotateY` when inside a perspective container
- Transition: all properties, 300ms ease-out
- Cursor: pointer

## Rules

- Background: translucent glass — never use opaque solid fills for cards
- Backdrop filter: `blur(16px) saturate(1.4)` — always present
- Border: 1px, translucent white — reinforces the frosted-glass edge
- Radius: 16px
- Shadow: shadow-md (step up to shadow-lg on hover for interactive cards)
- Interactive hover: increased opacity + elevation lift
- Non-interactive: no hover styles
- When cards are placed in a grid, wrap the grid in a `perspective: 1000px` container to enable 3D depth
