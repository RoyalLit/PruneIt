# PruneIt — Gemini / Antigravity Agent Configuration (GEMINI.md)

This project uses the unified agent guidelines documented in **AGENTS.md**.

### Quick Navigation
- **Agent Guidelines & Philosophy**: See [AGENTS.md](AGENTS.md)
- **Engineering & Design Rules**: See [RULES.md](RULES.md)
- **Roadmap & Active Tasks**: See [TASKS.md](TASKS.md)
- **Design Tokens**: See [docs/design-system.md](docs/design-system.md)
- **Taste Skill Frontend Directives**: See [docs/taste-skill.md](docs/taste-skill.md)
- **Architecture Walkthrough**: See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

### Key Agent Rules
1. **Deletion Safety**: Never modify `PruneIt/Services/FileDeleter.swift` or `PruneIt/Services/DeletionSafetyPolicy.swift`.
2. **Design Tokens**: Always use `AppStyle.Typography` and `AppColors`. Raw `.system(size:)` is rejected by `node scripts/lint-design-tokens.mjs`.
3. **Numbers**: All numbers, sizes, and counts must use `.monospacedDigit()`.
4. **Current Focus**: See [TASKS.md](TASKS.md) -> Phase 2 (Detail Screens Redesign).
