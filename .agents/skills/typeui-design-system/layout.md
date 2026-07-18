# Layout & Spacing

## Spacing Rhythm

Base unit: **8px**. All spacing values should be multiples of 8px.

| Context | Value |
|---|---|
| Section vertical padding | 96px |
| Section header → content | 48px or 64px |
| Heading → paragraph | 16px |
| Container horizontal padding | 24px |
| Flex/grid row gap | 16px |
| Card grid gap | 24px |
| Wide component grid gap | 32px |
| Column layout gap | 48px |

## Container

Standard section container: max-width 1152px, centered, 24px horizontal padding.

Every major section wraps content in this container.

## Content Composition Order

Inside each section, follow this order:
1. Heading (`h1`–`h3`)
2. Leading paragraph
3. Normal paragraph(s)
4. Lists, CTA links, or component grids

## Section Pattern

Each section has:
- 96px vertical padding
- A background color (alternate between neutral-primary-soft and neutral-secondary-soft)
- A centered container (max-width 1152px, 24px horizontal padding)
- A section header area with 48px bottom margin
- Section content below

## Motion & Animation

- Prefer CSS-native: `transition`, `animation`, `@keyframes`. Use Motion library only when CSS cannot achieve the behavior.
- Prioritize high-impact orchestrated moments over scattered micro-interactions. A single well-sequenced page-load animation using staggered `animation-delay` delivers more perceived quality than many isolated effects.
- Reserve scroll-triggered and hover transitions for moments that reinforce hierarchy or reward attention.
- Leverage CSS `perspective` and `transform: rotate3d()` for subtle 3D depth and parallax effects that reinforce the VR-gallery aesthetic.

## Backgrounds & Visual Depth

- Default to layered, atmospheric backgrounds with depth and translucency rather than flat solid fills.
- Apply contextual glassmorphism treatments — frosted-glass panels with `backdrop-filter: blur()`, translucent overlays, subtle gradient meshes, layered transparencies, perspective depth, and soft luminous borders — that align with the 3D VR-gallery aesthetic.
- Every decorative element must serve a compositional purpose (depth, separation, or emphasis). No purely ornamental effects competing with content.
- Glass panels should use semi-transparent backgrounds (e.g., `rgba(255,255,255,0.05)` in dark mode) with subtle border highlights and backdrop blur.

## Must

- All sections: consistent 96px vertical padding
- All containers: max-width 1152px, centered, 24px horizontal padding
- Section headers: 48px or 64px bottom margin
- Consistent vertical rhythm, no crowded sections
- Layouts readable and properly spaced on both desktop and mobile
