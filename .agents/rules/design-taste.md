# Design Taste & Anti-Slop Rules

PruneIt adopts the **Framed Sheet / Precision Developer Workbench** aesthetic. We reject AI slop: no generic centered landing hero patterns, no 7-color rainbow cards, no heavy blurred drop shadows, and no decorative animations without utility.

## 1. Color Budget (3–5% Max)
- 95% of the visual space is monochromatic architectural slate/zinc (`AppColors.background`, `AppColors.cardBackground`, `AppColors.borderHairline`).
- The 5% color budget is reserved strictly for meaningful data states and the Spruce brand accent:
  - Spruce Primary: `AppColors.accentPrune` (`#1B6C80` light / `#2EA3BE` dark)
  - Spruce Subtle Fill: `AppColors.accentPruneSubtle`
  - Spruce Border: `AppColors.accentPruneBorder`
- Never apply random rainbow colors across categories.

## 2. Hairlines & Elevation
- Use crisp 1px hairline borders (`AppColors.borderHairline`) instead of drop shadows.
- Cards sit flat on `AppColors.cardBackground` with `.clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))`.
- Interactive elements provide subtle hover feedback via tint or border highlight.

## 3. Typography & Numerals
- **No raw `.system(size:)`**: Always use `AppStyle.Typography` tokens (`pageTitle`, `sectionTitle`, `rowTitle`, `caption`, `micro`).
- **Tabular Monospaced Numbers**: Every byte count, item count, percentage, and timestamp MUST have `.monospacedDigit()`.
- Directory paths must be formatted with monospace styling and enclosed in subtle badge chips where appropriate.
