---
name: "untitled-project"
description: "Untitled Project design skill for AI coding agents."
metadata:
  author: typeui.sh
  source: workspace-importer
  projectName: "Untitled Project"
  projectLogoUrl: ""
  importSource: "Manual TypeUI setup"
  primaryColorReference: "#18181b"
  surfaceColorReference: "#ffffff"
  textColorReference: "#09090b"
  typographyScale: "Inter-style sans serif, 12/14/16/20/24/32 scale, medium labels, semibold headings."
  spacingScale: "4px base grid with 8px, 12px, 16px, 24px, and 32px layout steps."
  radiusScale: "6px controls, 8px cards, 12px overlays, nested radii reduced by inner padding."
---

# Design System — Agent Instructions

This skill describes the visual design language for all UI output. Every component, layout, and page should follow the design specs in the module files below. These describe *what the design looks like* — you choose how to implement the styles.

## Style
A perspective-driven 3D interface with glassmorphism panels, immersive depth, and a VR-gallery aesthetic — dark-first, translucent surfaces, bold typography, and a futuristic browsing experience

## Hero Section / 3D Perspective Gallery Aesthetic

When creating a hero section or gallery that needs to match the "VR-gallery" or "3D Perspective" aesthetic, you MUST implement the following structure:
- **Background**: Use a heavily blurred background image (e.g., `blur(24px) brightness(0.8)`) or large decorative blurred colored orbs (like a blue background filter/glow) to create an immersive environment.
- **3D Perspective Container**: Wrap the main content in a container with `perspective: 1200px` and `transformStyle: "preserve-3d"`. Add a subtle mouse-move parallax effect (`rotateY` and `rotateX` based on cursor position).
- **Main Glass Panel**: The central UI should be a massive floating glassmorphism card (`backdrop-filter: blur(16px) saturate(1.4)`, translucent background like `rgba(255, 255, 255, 0.15)`, and `shadow-2xl`). Apply a static 3D rotation (e.g., `rotateY(-15deg) rotateX(5deg)`) to make it look like a floating VR interface.
- **Transparent Cards & Tabs**: Inside the main panel, use transparent/translucent cards for sidebar items, tabs, and active states. The active item should have a slightly more opaque glass background (`bg-white/20`) and a subtle shadow.
- **Depth (Z-Axis)**: Push inner content (like the main artwork image, bottom carousels, or floating toolbars) forward in 3D space using `translateZ()` (e.g., `translateZ(30px)`) to create actual depth between the glass panel background and the content floating inside it.
- **Floating Elements**: Include floating toolbars or navigation pills outside the main panel, also rotated in 3D space, to complete the VR interface look.

## Before Writing Any Code

1. **Read every module that applies.** For a landing page, read at minimum: `layout.md`, `typography.md`, `colors.md`, `buttons.md`, `cards.md`, `shadows.md`, `radius.md`, `borders.md`. Do NOT write JSX until you have loaded all relevant modules.

## Critical Rules

- **Brand color precedence:** When `brand.md` is available, color tokens from `brand.md` overwrite same-name tokens in `colors.md`.

- **Tokens are AGNOSTIC, NOT Tailwind classes:** The tokens defined in the `.md` files (like `neutral-primary-soft`, `heading`, `border-default`) are agnostic design system tokens, NOT literal Tailwind classes. Do not blindly use classes like `bg-neutral-primary-soft` unless you have explicitly mapped them in the CSS/Tailwind configuration. You must implement the mapping yourself.

- **Cross-reference modules.** A card containing buttons must satisfy both `cards.md` AND `buttons.md`.
- **Dark mode is automatic.** The CSS custom properties resolve differently in light/dark via `@media (prefers-color-scheme: dark)`. Never manually swap colors.
- **Every interactive element needs hover, focus, and disabled states** — defined in the relevant module.
- **Use semantic HTML:** proper heading hierarchy (`h1`→`h6`), `<button>` for actions, `<a>` for navigation, ARIA attributes where needed.
- **Glassmorphism everywhere:** The entire site uses translucent surfaces with `backdrop-filter: blur()`. Cards, panels, modals, sidebars, and overlays must have transparent/semi-transparent backgrounds with frosted-glass blur — never opaque solid fills. Wrap card grids and key sections in a CSS `perspective` container to enable 3D depth and tilt effects.

## Module Index

### Foundation (read first for any UI work)
- [brand.md](brand.md) — Brand
- [colors.md](colors.md) — Color
- [typography.md](typography.md) — Typography
- [layout.md](layout.md) — Layout
- [radius.md](radius.md) — Radius
- [shadows.md](shadows.md) — Shadow
- [borders.md](borders.md) — Borders

### Components
- [buttons.md](buttons.md) — Button
- [button-group.md](button-group.md) — Button Group
- [cards.md](cards.md) — Card
- [inputs.md](inputs.md) — Input
- [alerts.md](alerts.md) — Alert
- [badges.md](badges.md) — Badge
- [lists.md](lists.md) — List
- [avatars.md](avatars.md) — Avatar
- [icon-shapes.md](icon-shapes.md) — Icon Shape
- [accordion.md](accordion.md) — Accordion
- [dropdown.md](dropdown.md) — Dropdown
- [modals.md](modals.md) — Modal
- [tabs.md](tabs.md) — Tabs
- [tables.md](tables.md) — Table
- [pagination.md](pagination.md) — Pagination
- [sidebars.md](sidebars.md) — Sidebar
- [radios-checkboxes-toggle.md](radios-checkboxes-toggle.md) — Radio, Checkbox, Toggle
- [tooltips-popovers.md](tooltips-popovers.md) — Tooltip, Popovers
- [content.md](content.md) — Content