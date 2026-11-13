# Changelog

All notable changes to ReLearn are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned
- Stage 2: camera scanning, offline queue, sync status.
- Stage 3: PDF card export and printable batches.

## [0.4.2] — 2026-11-13

### Fixed
- Beneficiary registration no longer fails with
  `function gen_random_bytes(integer) does not exist`. `next_public_id()` now
  derives its random suffix from the core `gen_random_uuid()`, which is
  available on every Supabase Postgres project.
- Camera QR scanning works on Android. The scanner reads the public ID from the
  card QR, opens the matching beneficiary immediately, and includes torch,
  camera switching and manual ID fallback.
- Signed-in users can no longer be routed into the wrong role area: admins,
  teachers and collectors each land on their own home, and stale sessions are
  rejected before navigation.

### Added
- **Teacher role.** Teachers are read-only, belong to one school and get a
  dedicated school overview. Database RPCs reject writes from teacher accounts.
- **School membership.** Every teacher and collector must belong to an active
  school. Admins choose the school when creating the account; a school-less
  account is sent to `/school-setup` after sign-in and links itself once through
  `update_my_school`.
- **School-scoped RLS.** Beneficiaries, collections, collection items,
  redemptions and the points ledger are limited to the caller's school for
  teachers and collectors. Admins keep global access.
- **Briefs & history.** Admins can generate a global or single-school brief;
  teachers and collectors get their own school. The brief is copy-ready and
  covers a week, month or all time, alongside the matching transaction history.
- Navigation entry points for briefs in the admin rail, collector app bar,
  account centre and reports.

### Changed
- Migration `0007_school_membership.sql` adds the teacher role, school
  membership, portable ID generation, school-scoped policies and read-only
  teacher guards.
- Admin user creation requires a school for teacher and collector roles.
- Collector history now describes the account's visible school history instead
  of claiming to be device-only.
- README, screen documentation and data model updated for teachers, scanning,
  school setup and briefs.
- Version `0.4.2+7`.

## [0.4.1] — 2026-11-13

### Fixed
- Card printing now generates a real A4 PDF (eight cards per sheet) and opens
  the system print/save dialog. Single cards can be printed from a beneficiary
  profile. The previous stub only showed an “not available” message.
- Finishing the onboarding guide from the login screen no longer sends the app
  to `/admin/dashboard`. The guide is public and returns to login; the role is
  resolved only after authentication.
- A restored Supabase session is now validated before navigation. If the staff
  profile is missing, inactive or the data load fails, ReLearn signs out and
  returns to login instead of opening an empty admin screen with errors.
- Admin routes check the signed-in role; collectors are sent to the collector
  home instead of rendering admin screens.

### Changed
- Removed the non-functional CSV import toggle and report export button so the
  UI only offers features that work.
- Replaced hardcoded dashboard deltas with accurate labels.
- README and screen documentation now describe the shipped behaviour, including
  the features that are still on the roadmap.

## [0.4.0] — 2026-11-13

### Added
- Account centre for every staff member: profile name, change password,
  fingerprint/face unlock toggle, guide replay and sign out.
- First-run onboarding with four guide pages and a replayable "How to use"
  flow from the login screen and Account.
- Session lock after 15 minutes of inactivity in live mode, with fingerprint or
  face unlock and password fallback. Web uses password unlock only.
- Product photo upload from the phone gallery or camera into the public
  `item-images` bucket, with preview, size validation and progress feedback.
- Deactivate and delete actions for catalogue items.
- `update_my_name` RPC (migration `0006`) so staff can rename themselves without
  changing their role.
- GitHub release workflow that builds the APK and web admin on every `v*` tag.

### Changed
- Product saves are now awaited: the form shows a spinner, reports backend
  errors inline and reloads the catalogue after success.
- Restock uses the atomic server RPC only, fixing a double stock increment.
- Removed simulated and stage-placeholder copy from the collector scan, home,
  history and admin screens. The sample-card action appears in demo mode only.
- Dashboard greeting and admin/collector account labels now use the signed-in
  profile instead of hardcoded names.

### Security
- Android uses `FlutterFragmentActivity`, `USE_BIOMETRIC`, `USE_FINGERPRINT`
  (API 28 and below) and `minSdk 23` for biometric unlock.
- Demo mode never locks and never persists security settings.

## [0.3.0] — 2026-11-12

### Added
- Marketplace-style item shop for collectors: category filters, photo/icon
  cards, points and stock at a glance, and a selected-item detail panel.
- Admin catalogue is now a marketplace preview with search, category filters,
  artwork, descriptions, points and stock on every card.
- Catalogue records gain `category` and `description` (migration `0005`); seeded
  items are backfilled across Stationery, Books, Bags, Maths, Art and Lunch.
- Add/edit item form manages name, category, description, points, stock, image
  URL and shop visibility.
- `ItemArt` widget shows uploaded photos from `item-images` and falls back to a
  category-coloured icon tile.

### Changed
- Admin item cards can restock and edit every field without leaving the screen.
- Collector shop shows only active items and filters instantly by category.

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

[Unreleased]: https://github.com/Icedmist/relearn/compare/v0.4.2...HEAD
[0.4.2]: https://github.com/Icedmist/relearn/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/Icedmist/relearn/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/Icedmist/relearn/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/Icedmist/relearn/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/Icedmist/relearn/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/Icedmist/relearn/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/Icedmist/relearn/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/Icedmist/relearn/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/Icedmist/relearn/releases/tag/v0.1.0
