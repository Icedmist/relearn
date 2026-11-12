# Changelog

All notable changes to ReLearn are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned
- Stage 2: camera scanning, offline queue, sync status.
- Stage 3: PDF card export and printable batches.

## [0.2.1] — 2026-11-12

### Fixed
- Release Android builds now include the `INTERNET` permission, so sign-in and
  data access work outside debug builds.
- Sign-up no longer leaves an admin signed in as the newly created account; the
  original session is restored before the role is assigned.

### Added
- Admin → Users → **Add user** creates a real Supabase Auth account with a name,
  email, temporary password and role (collector or admin).
- Created accounts appear in the staff directory and can sign in immediately.

### Changed
- Removed the live/online status indicators (`LIVE DATA`, `LIVE · SUPABASE`,
  `ONLINE`) from the admin top bar, collector app bar, collector home and login.

## [0.2.0] — 2026-11-12

### Added
- Live Supabase backend: email/password auth, session restore, password reset
  and a router guard that redirects signed-out users to login.
- SQL migrations for the schema, staff directory, educational supplies
  catalogue and item-image storage; all applied to the hosted project.
- `SupabaseRepository` for loading and writing schools, beneficiaries,
  materials, rewards, ledger, collections, redemptions and staff.
- Server-side RPCs for collections, redemption, point adjustments and restock.
- Staff directory view: admins see every account, collectors see only
  themselves; self-signup always creates a collector.
- Admin Users screen with live roles, last-active time, deactivate/reactivate
  and password-reset email.
- Educational supplies catalogue with 18 rewards and point costs, from an
  eraser (15 pts) to a scientific calculator (500 pts).
- Public-read `item-images` Storage bucket (5 MB; PNG/JPEG/WebP) with
  admin-only writes and `image_url` columns on materials and rewards.
- `.env.example` and `--dart-define-from-file=.env` workflow; `.env` stays
  gitignored.

### Changed
- `DemoState`/`DemoStore` renamed to `AppState`/`AppStore`; the same snapshot
  now serves demo and live data.
- Live mode turns on automatically when Supabase credentials are present;
  `DEMO_MODE=true` forces the in-memory store.
- Admin and collector shells show live/demo status, the signed-in profile,
  a loading bar, an error banner and a working sign-out.
- Collections and redemptions are asynchronous and surface server errors.
- CI remains pinned to Flutter 3.47.9; local validation runs tests and a debug
  web build.

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

[Unreleased]: https://github.com/Icedmist/relearn/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/Icedmist/relearn/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/Icedmist/relearn/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/Icedmist/relearn/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/Icedmist/relearn/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/Icedmist/relearn/releases/tag/v0.1.0
