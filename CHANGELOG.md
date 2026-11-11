# Changelog

All notable changes to ReLearn are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned
- Stage 1: Supabase auth and persistence, schools, beneficiaries, QR cards, PDF export.
- Stage 2: camera scanning, offline queue, sync status.
- Stage 3: server points engine and atomic redemption.
- Stage 4: live dashboard queries, filters, CSV reports.

## [0.1.2] — 2026-11-11

### Fixed
- Responsive layouts for every admin and collector screen at phone widths
  (360–390 px) and desktop widths (1280 px).
- Long labels and status pills now ellipsize instead of overflowing.
- Admin tables and filter bars wrap or scroll on narrow screens.
- Print-card preview no longer uses flex in an unbounded column.
- Collector app bar hides the demo version pill on small phones.
- Added screen smoke tests that render all 20 routes at phone and desktop sizes.

## [0.1.1] — 2026-11-11

### Added
- GitHub Actions CI: format check, analyze, tests and a release web build on
  every pull request and push to `main`.
- CI status badge in the README.

## [0.1.0] — 2026-11-10

### Added
- Flutter Stage 0 scaffold for Android and Web.
- Brand system: "The Learning Loop" logo, Leaf/Forest/Cream/Sun palette, app icons.
- Admin screens: login, dashboard, schools, beneficiaries, registration,
  beneficiary profile, print cards, materials, rewards, reports, users.
- Collector screens: home, simulated scan, search, beneficiary card, record
  collection with live points preview, redeem, success, history.
- In-memory demo store that credits points, deducts balance and decrements stock.
- Supabase schema: tables, enums, indexes, balance view, append-only ledger,
  RLS policies and atomic RPCs for collect, redeem, adjust and void.
- Seed catalogue and demo school.
- Documentation: PRD, screen specification, stack, brand, data model, README,
  contributing workflow.

[Unreleased]: https://github.com/Icedmist/relearn/compare/v0.1.2...HEAD
[0.1.2]: https://github.com/Icedmist/relearn/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/Icedmist/relearn/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/Icedmist/relearn/releases/tag/v0.1.0
