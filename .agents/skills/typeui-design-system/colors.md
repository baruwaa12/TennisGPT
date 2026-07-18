# Color Tokens


## Background Tokens

### Neutral
| Token | Light | Dark |
|---|---|---|
| neutral-primary-soft | #FFFFFF | #0C1222 |
| neutral-primary | #FFFFFF | #060B18 |
| neutral-primary-medium | #FFFFFF | #131B2E |
| neutral-primary-strong | #FFFFFF | #1E293B |
| neutral-secondary-soft | #F8FAFC | #0C1222 |
| neutral-secondary | #F8FAFC | #060B18 |
| neutral-secondary-medium | #F8FAFC | #131B2E |
| neutral-secondary-strong | #F8FAFC | #1E293B |
| neutral-tertiary-soft | #F0F4F8 | #0C1222 |
| neutral-tertiary | #F0F4F8 | #131B2E |
| neutral-tertiary-medium | #F0F4F8 | #1E293B |
| neutral-quaternary | #E2E8F0 | #1E293B |
| quaternary-medium | #E2E8F0 | #334155 |
| gray | #CBD5E1 | #334155 |

### Brand
| Token | Light | Dark |
|---|---|---|
| brand-softer | #E8F1FF | #0A1A3D |
| brand-soft | #CCE0FF | #0D2B66 |
| brand | #0166FF | #0166FF |
| brand-medium | #99C2FF | #0D2B66 |
| brand-strong | #0052CC | #0166FF |

### Status
| Token | Light | Dark |
|---|---|---|
| success-soft | #ECFDF5 | #002C22 |
| success | #007A55 | #009966 |
| success-medium | #D0FAE5 | #004F3B |
| success-strong | #006045 | #007A55 |
| danger-soft | #FEF0F2 | #4D0218 |
| danger | #C70036 | #C70036 |
| danger-medium | #FFE4E6 | #8B0836 |
| danger-strong | #A50036 | #A50036 |
| warning-soft | #FFF7ED | #7C2D12 |
| warning | #F97316 | #F97316 |
| warning-medium | #FFEDD5 | #7C2D12 |
| warning-strong | #C2410C | #C2410C |

### Button Glint (CSS custom properties, used for the glint box-shadow effect)
| Variable | Light | Dark |
|---|---|---|
| `--color-1-400` | rgba(255,255,255,0.30) | rgba(255,255,255,0.08) |
| `--color-1-700` | rgba(0,0,0,0.08) | rgba(0,0,0,0.30) |

### Utility
| Token | Light | Dark |
|---|---|---|
| dark | #1E293B | #1E293B |
| dark-strong | #0F172A | #1E293B |
| disabled | #F0F4F8 | #131B2E |

### Accent
| Token | Value (same both modes) |
|---|---|
| purple | #8B5CF6 |
| sky | #0EA5E9 |
| teal | #14B8A6 |
| pink | #EC4899 |
| cyan | #22D3EE |
| fuchsia | #D946EF |
| indigo | #6366F1 |
| orange | #F97316 |

## Text Color Tokens

### Base
| Token | Light | Dark |
|---|---|---|
| white | #FFFFFF | #FFFFFF |
| black | #0F172A | #0F172A |
| heading | #0F172A | #F1F5F9 |
| body | #475569 | #94A3B8 |
| body-subtle | #64748B | #94A3B8 |

### Brand
| Token | Light | Dark |
|---|---|---|
| fg-brand-subtle | #99C2FF | #0D2B66 |
| fg-brand | #0166FF | #4D9AFF |
| fg-brand-strong | #0052CC | #99C2FF |

### Status
| Token | Light | Dark |
|---|---|---|
| fg-success | #047857 | #065F46 |
| fg-success-strong | #065F46 | #10B981 |
| fg-danger | #BE123C | #F43F5E |
| fg-danger-strong | #881337 | #F87171 |
| fg-warning-subtle | #EA580C | #F97316 |
| fg-warning | #7C2D12 | #FBBF24 |
| fg-disabled | #94A3B8 | #64748B |

### Informational / Accent
| Token | Light | Dark |
|---|---|---|
| fg-yellow | #FACC15 | #FACC15 |
| fg-info | #312E81 | #93C5FD |
| fg-purple | #7C3AED | #8B5CF6 |
| fg-purple-strong | #6D28D9 | #DDD6FE |
| fg-cyan | #0891B2 | #22D3EE |
| fg-indigo | #6366F1 | #6366F1 |
| fg-pink | #EC4899 | #EC4899 |
| fg-lime | #65A30D | #84CC16 |

## Border Color Tokens

| Token | Light | Dark |
|---|---|---|
| border-dark | #1E293B | #334155 |
| border-buffer | #FFFFFF | #060B18 |
| border-buffer-medium | #FFFFFF | #131B2E |
| border-buffer-strong | #FFFFFF | #1E293B |
| border-muted | #F8FAFC | #0C1222 |
| border-light-subtle | #F0F4F8 | #0C1222 |
| border-light | #F0F4F8 | #131B2E |
| border-light-medium | #F0F4F8 | #1E293B |
| border-default-subtle | #E2E8F0 | #0C1222 |
| border-default | #E2E8F0 | #131B2E |
| border-default-medium | #E2E8F0 | #1E293B |
| border-default-strong | #E2E8F0 | #334155 |
| border-success-subtle | #A7F3D0 | #064E3B |
| border-success | #047857 | #065F46 |
| border-danger-subtle | #FECDD3 | #881337 |
| border-danger | #BE123C | #BE123C |
| border-warning-subtle | #FED7AA | #7C2D12 |
| border-warning | #EA580C | #F97316 |
| border-brand-subtle | #99C2FF | #0D2B66 |
| border-brand-light | #0166FF | #0166FF |
| border-brand | #0166FF | #4D9AFF |
| border-dark-subtle | #1E293B | #1E293B |
| border-purple | #8B5CF6 | #8B5CF6 |
| border-orange | #F97316 | #F97316 |

## Semantic Usage Rules

- Page/section backgrounds: neutral-primary-soft (default), neutral-secondary-soft (alternating)
- Primary buttons: brand background
- Headings: heading text color
- Body text: body text color
- CTA links: fg-brand text color
- Default borders: border-default
- Status borders match intent: success → border-success, danger → border-danger, warning → border-warning
- Disabled: disabled background + fg-disabled text

## Prohibited

- No raw hex/rgb values in component code — always use design tokens
- No brand text color for long-form paragraphs
- No accent text tokens (fg-purple, etc.) for body copy or navigation
- No brand/accent backgrounds for large layout surfaces (pages, sections) unless it's a hero/campaign area
- No manual light/dark value swapping — let the CSS custom properties handle it
