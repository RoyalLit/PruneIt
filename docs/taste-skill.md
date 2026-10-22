# Taste Skill (`design-taste-frontend`)

[Taste Skill](https://github.com/Leonxlnx/taste-skill) by [Leonxlnx](https://github.com/Leonxlnx) is an Agent Skill that provides art direction, aesthetic standards, and real-browser inspection for web pages and UI screens to prevent generic or templated "AI-made" slop.

---

## 1. Overview & Philosophy

Models tasked with UI or web page generation often converge toward generic averages: centered multi-line headers, floating icon cards, weak gradients, and decorative borders that lack intention.

Taste Skill enforces four core principles:

1. **Decisions Over Category Defaults**: `scripts/draw.mjs` selects researched design directions distilled from over 240 award-winning websites (Awwwards, One Page Love).
2. **Subject-Driven Concepts**: Ideas are derived directly from the character and utility of the software rather than decorative fillers.
3. **Strict No-Slop Guardrails**: Evaluated via a headless or local Chromium browser using `scripts/inspect.mjs`.
4. **Visual Loop & Verification**: Takes multi-breakpoint viewport captures (desktop, tablet, mobile) and applies structured design critique.

---

## 2. Installation & Directory Mapping

The skill is installed locally within the workspace and globally across agent environments:

| Scope | Location |
|---|---|
| **Workspace Skill** | `.agents/skills/design-taste-frontend/` |
| **Global Agent Skills** | `~/.agents/skills/design-taste-frontend/` |
| **Antigravity Customizations** | `~/.gemini/config/skills/design-taste-frontend/` |
| **Claude Code Skills** | `~/.claude/skills/design-taste-frontend/` |

---

## 3. Skill Components & Scripts

Inside `.agents/skills/design-taste-frontend/`:

- **`SKILL.md`**: Main operational prompt and decision matrix for agents.
- **`scripts/draw.mjs`**: Deals palettes, typography scales, hero layouts, and section compositions from curated libraries.
- **`scripts/inspect.mjs`**: Audits a running web page in Chromium against design rules (contrast, line lengths, spacing, ornaments).
- **`library/`**: Distilled patterns for marketing pages, landing pages, and application screens (dashboards, settings, toolbars).
- **`references/`**: Design tokens, typographic pairings, and color palettes.

---

## 4. Usage in PruneIt

When designing web landing pages, documentation sites, promotional assets, or application views for PruneIt:

1. **Run Art Direction**:
   ```bash
   node .agents/skills/design-taste-frontend/scripts/draw.mjs --topic "macOS cleaner app"
   ```
2. **Audit Web UI with Inspector**:
   ```bash
   node .agents/skills/design-taste-frontend/scripts/inspect.mjs http://localhost:3000
   ```
3. **Apply with PruneIt Design System**:
   Combine Taste Skill's layout and content decisions with PruneIt's native design tokens in [`docs/design-system.md`](design-system.md) (e.g. warm graphite neutrals, continuous squircle radii, and pill button styles).
