# Changelog

## 0.1.1 — 2026-03-24

### Fixed

- Fixed `dependabot-prs.sh` failing silently when token lacks `checks:read`
  permission — the script now falls back to fetching without `statusCheckRollup`
  and sets `checks_pass` to `null`
- Replaced N+1 API calls (`gh pr list` + `gh pr view` per PR) with a single
  `gh pr list` call for better performance
- Added `--limit 100` to handle repos with many Dependabot PRs
- `dependabot-sweep` now re-fetches PR data after each merge to detect PRs that
  became conflicting and requests rebases for them

## 0.1.0 — 2026-03-24

Initial release.

### Added

- `dependabot-fix` skill — fix the highest-priority Dependabot vulnerability alert
- `dependabot-merge` skill — merge the oldest ready Dependabot PR
- `dependabot-unblock` skill — request rebases for conflicting PRs and investigate failing checks
- `dependabot-sweep` skill — full maintenance sweep orchestrating all three skills
- `dependabot-prs.sh` helper script — fetch open Dependabot PRs with merge readiness info
- `dependabot-alerts.sh` helper script — fetch open Dependabot vulnerability alerts
