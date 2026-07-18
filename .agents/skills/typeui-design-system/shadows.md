# Shadows

| Token | CSS value |
|---|---|
| shadow-2xs | `0 1px 2px rgb(0 0 0 / 0.04)` |
| shadow-xs | `0 1px 3px 0 rgb(0 0 0 / 0.05), 0 1px 2px -1px rgb(0 0 0 / 0.03)` |
| shadow-sm | `0 2px 6px -1px rgb(0 0 0 / 0.07), 0 1px 3px -1px rgb(0 0 0 / 0.05)` |
| shadow-md | `0 6px 16px -4px rgb(0 0 0 / 0.08), 0 2px 6px -2px rgb(0 0 0 / 0.05)` |
| shadow-lg | `0 12px 28px -6px rgb(0 0 0 / 0.1), 0 4px 12px -4px rgb(0 0 0 / 0.06)` |
| shadow-xl | `0 24px 48px -10px rgb(0 0 0 / 0.14), 0 8px 20px -8px rgb(0 0 0 / 0.08)` |
| shadow-2xl | `0 32px 64px -16px rgb(0 0 0 / 0.22)` |

## Component Mapping

| Component type | Token |
|---|---|
| Subtle separators, tiny UI details | shadow-2xs or shadow-xs |
| Inputs, buttons, small controls, lightweight cards | shadow-xs or shadow-sm |
| Standard cards, popovers, dropdowns | shadow-md |
| Prominent cards, sticky surfaces, glass panels | shadow-lg |
| Modals, high-priority overlays, glassmorphism panels | shadow-xl |
| Hero overlays, top-level emphasis (sparingly) | shadow-2xl |

## Rules

- Use only these tokens — no custom box-shadow values
- Keep elevation steps intentional; avoid jumping multiple levels
- Components in the same family share the same baseline elevation
- Hover/focus on interactive elevated elements: step up by one level
- Never stack multiple shadow tokens on one element
- Never use shadow-xl/shadow-2xl for dense list items or body containers
