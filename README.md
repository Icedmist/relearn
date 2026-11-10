<p align="center">
  <img src="assets/brand/logo_horizontal.svg" alt="ReLearn — Recycle to Learn" width="360">
</p>

<h1 align="center">ReLearn</h1>
<p align="center"><strong>Waste in. School supplies out.</strong></p>

<p align="center">
  <a href="#status"><img alt="Status" src="https://img.shields.io/badge/status-stage%200%20scaffold-2E9E5B"></a>
  <a href="#stack"><img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B"></a>
  <a href="#stack"><img alt="Supabase" src="https://img.shields.io/badge/Backend-Supabase-3ECF8E"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-blue"></a>
</p>

---

ReLearn turns recyclable waste into school supplies. Pupils and teachers bring
paper, bottles, cans and sachets to school. A field collector scans their printed
QR card, the server credits points at the configured rates, and the points are
redeemed on the spot for pencils and exercise books. Programme staff get a live
dashboard of schools, beneficiaries, materials, points and rewards.

**One printed card is the whole identity.** No app, no login and no data plan for
the pupil. The collector's Android phone does the work; Postgres keeps the truth.

> **Status:** Stage 0 — a fully clickable Flutter scaffold with demo data, the
> complete screen map, brand system, Supabase schema and product documentation.
> Supabase, camera scanning, PDF cards and the offline queue land in Stages 1–3.

---

## Table of contents

- [Why ReLearn](#why-relearn)
- [Product at a glance](#product-at-a-glance)
- [Screens](#screens)
- [Demo walkthrough](#demo-walkthrough)
- [Stack](#stack)
- [Repository layout](#repository-layout)
- [Getting started](#getting-started)
- [Supabase setup](#supabase-setup)
- [Architecture and rules](#architecture-and-rules)
- [Data model](#data-model)
- [Documentation](#documentation)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Why ReLearn

Schools generate recyclable waste every day, but there is no simple, trustworthy
way to convert it into learning materials for the children who collect it.
Existing recycling schemes pay cash or require smartphones and accounts that
pupils do not have.

ReLearn's insight is that a **printed QR card is the cheapest reliable identity a
child can carry**: no app, no login, no data plan, no cost per scan. The QR holds
only a public ID. Points and personal data stay in the database, protected by
Row Level Security.

### Product principles

1. **Card, not account.** Beneficiaries never log in.
2. **Server is the source of truth.** Points are computed server-side; the app
   only previews.
3. **Never lose a point.** Append-only ledger, idempotency keys, no deletes.
4. **Works on a cheap phone, on a bad network.** Offline queue with sync status.
5. **Low cost by design.** No paid QR service, no SMS, no per-scan fees.
6. **Safeguard children's data.** Collect the minimum; guardian phone is optional.

---

## Product at a glance

| | Admin (Flutter Web) | Collector (Android) | Beneficiary |
|---|---|---|---|
| Who | Programme staff | Field agents | Pupils and teachers |
| Access | Full programme | Scan, collect, redeem | Printed QR card only |
| Device | Browser | Low-to-mid-range Android | None |

**Core loop:** register school → register beneficiary → generate ID + QR → print
card → scan card → record materials → points credited → redeem reward → dashboard.

**Success test:** the full loop can be demonstrated end to end and run in a real
school without developer help.

### What works in this scaffold

- Admin dashboard with KPI cards, a 7-day chart, top materials and activity feed.
- School management, beneficiary registration, QR preview, card print preview.
- Materials and rates, rewards and stock, reports, user management.
- Collector home, simulated scan, search, beneficiary card, collection entry
  with a live points preview, redemption with balance and stock checks, history.
- A working in-memory store: recording a collection really credits points;
  redeeming really deducts points and stock for the session.
- Brand system: logo, palette, typography and app icons.
- Complete Supabase schema with RLS, atomic RPCs and an append-only ledger.

### Not built yet (by design)

- Real authentication and Supabase persistence.
- Camera scanning (`mobile_scanner`), PDF export (`pdf`/`printing`), CSV import.
- Drift offline queue and sync worker.
- Live dashboard queries and CSV reports.

See the [roadmap](#roadmap) and [`docs/PRD.md`](docs/PRD.md).

---

## Screens

### Admin — Flutter Web

| # | Screen | Route |
|---|---|---|
| 1 | Login | `/login` |
| 2 | Dashboard | `/admin/dashboard` |
| 3 | Schools | `/admin/schools` |
| 4 | Beneficiaries | `/admin/beneficiaries` |
| 5 | Register beneficiary (single + CSV) | `/admin/beneficiaries/new` |
| 6 | Beneficiary profile | `/admin/beneficiaries/:id` |
| 7 | Print cards | `/admin/print` |
| 8 | Materials & points | `/admin/materials` |
| 9 | Rewards & stock | `/admin/rewards` |
| 10 | Reports | `/admin/reports` |
| 11 | Users | `/admin/users` |

### Collector — Android

| # | Screen | Route |
|---|---|---|
| 1 | Login | `/login` |
| 2 | Home | `/collector/home` |
| 3 | Scan | `/collector/scan` |
| 4 | Search | `/collector/search` |
| 5 | Beneficiary card | `/collector/beneficiary/:id` |
| 6 | Record collection | `/collector/beneficiary/:id/collect` |
| 7 | Redeem | `/collector/beneficiary/:id/redeem` |
| 8 | Success | `/collector/success` |
| 9 | History | `/collector/history` |

Full content, actions and states: [`docs/SCREENS.md`](docs/SCREENS.md).

---

## Demo walkthrough

1. `flutter run -d chrome`
2. On the login screen choose **Admin demo**.
3. Open **Beneficiaries → Amina Yusuf** to see the QR, balance and ledger.
4. Switch to the collector app (QR icon in the top bar, or **Collector demo**).
5. Tap **Scan a QR card → Simulate a successful scan**.
6. Tap **Record collection**, adjust the material quantities and confirm.
7. See the success screen with the new balance.
8. Redeem an **Exercise book** and watch points and stock drop.
9. Return to the admin dashboard and see the new activity.

All numbers are demo-only and reset when the app restarts.

---

## Stack

| Layer | Choice |
|---|---|
| UI | Flutter 3.x (Android + Web, one codebase) |
| State | Riverpod |
| Routing | go_router |
| Local storage / offline | Drift (SQLite) + sync queue — Stage 2 |
| Backend | Supabase (Postgres, Auth, RLS, RPC) |
| QR scan | mobile_scanner — Stage 2 |
| QR generate | qr_flutter |
| PDF cards | pdf + printing — Stage 1 |
| Charts | Custom Flutter bars in Stage 0; fl_chart in Stage 4 |
| Hosting | Vercel (web) + Play internal track (Android) |
| Fallback backend | Fastify + Drizzle + Postgres on DigitalOcean |

Rationale: [`docs/STACK.md`](docs/STACK.md).

---

## Repository layout

```
relearn/
├── docs/                    PRD, screens, stack, design, data model
├── supabase/
│   ├── migrations/          schema, RLS, RPCs, triggers
│   └── seed.sql             starting catalogue and demo school
├── assets/brand/            logo SVGs + PNG app icon
├── lib/
│   ├── core/                config, router, theme, shared widgets
│   ├── data/                models, demo store
│   └── features/
│       ├── auth/
│       ├── admin/
│       └── collector/
├── test/
├── android/  web/
└── pubspec.yaml
```

---

## Getting started

### Prerequisites

- Flutter stable 3.35+ (tested on 3.47.9 / Dart 3.13)
- Android SDK for the collector build
- Chrome for the web admin
- Optional: Supabase CLI and Docker for the backend

### Run the demo

```bash
git clone https://github.com/Icedmist/relearn.git
cd relearn
flutter pub get
flutter run -d chrome        # admin + collector in the browser
# or
flutter run -d <android-id>  # collector app
```

No credentials are needed: the app runs in demo mode with seeded data.

### Checks

```bash
flutter analyze
flutter test
flutter build web --release
```

---

## Supabase setup

1. Create a project at [supabase.com](https://supabase.com).
2. Apply the schema and seed:

```bash
supabase link --project-ref <ref>
supabase db push
psql "$DATABASE_URL" -f supabase/seed.sql
```

3. Create the first admin user, then promote the profile:

```sql
update public.profiles set role = 'admin' where id = '<auth-user-id>';
```

4. Run the app with credentials:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key> \
  --dart-define=DEMO_MODE=false
```

The **anon key is safe to ship** because RLS enforces access. Never put the
**service-role key** in the app. See [`.env.example`](.env.example).

### Build and deploy

```bash
# Web admin
flutter build web --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...

# Android
flutter build appbundle --release
```

Vercel: build command `flutter build web`, output `build/web`, add a rewrite to
`index.html` for client-side routes.

---

## Architecture and rules

```
Screens → Riverpod → repositories ──► Supabase (online)
                              └─────► Drift + sync queue (offline)
```

Rules the implementation must keep:

1. Screens never call Supabase directly.
2. Points are never calculated in the UI for storage. The client preview is a
   pure function; the server recalculates.
3. Every write has a client-generated idempotency key.
4. `points_ledger` is append-only; corrections are `void`/`adjust` entries.
5. Redemption checks balance **and** stock inside one transaction.
6. Rates are snapshotted on each collection line.
7. Disallowed materials are rejected by the server, not just hidden.
8. RLS enforces roles; route guards are UX only.

---

## Data model

```
schools 1──* beneficiaries 1──* collections 1──* collection_items
profiles(collector) 1──* collections        materials 1──* collection_items
beneficiaries 1──* redemptions *──1 rewards
beneficiaries 1──* points_ledger            balance = Σ ledger.points
```

| Table | Purpose |
|---|---|
| `schools` | Programme schools |
| `profiles` | Staff users (admin / collector) |
| `beneficiaries` | Pupils and teachers with a public ID |
| `materials` | Accepted materials, units and rates |
| `collections` / `collection_items` | Collection header and rate-snapshotted lines |
| `rewards` / `redemptions` | Catalogue, stock and redemptions |
| `points_ledger` | Append-only earn / redeem / adjust / void entries |
| `beneficiary_balances` | Derived balance view |

Full detail: [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) and
[`supabase/migrations/0001_init.sql`](supabase/migrations/0001_init.sql).

---

## Documentation

| Document | What it covers |
|---|---|
| [`docs/PRD.md`](docs/PRD.md) | Problem, goals, users, requirements, acceptance criteria, risks |
| [`docs/SCREENS.md`](docs/SCREENS.md) | Every screen, route, action and UI state |
| [`docs/STACK.md`](docs/STACK.md) | Stack decisions, architecture, offline sync, deployment, costs |
| [`docs/DESIGN.md`](docs/DESIGN.md) | Name, logo concept, palette, typography, UI tokens |
| [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) | Schema, relationships, ID format, integrity rules |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Issue → branch → PR → squash merge agent workflow |
| [`CHANGELOG.md`](CHANGELOG.md) | Release history |

---

## Roadmap

| Stage | Scope | Review point |
|---|---|---|
| **0 · Scaffold** ✅ | Design system, routes, demo store, all screens, schema, docs | Click through the full demo |
| **1 · Registration** | Supabase auth, schools, beneficiaries, IDs, QR, printable PDF cards | Print and scan a sample card |
| **2 · Collection** | Collector login, camera scan, search, entry, history, offline queue | Record a collection on a real phone |
| **3 · Points & rewards** | Server points engine, balances, catalogue, atomic redemption | Redeem an exercise book end to end |
| **4 · Reporting** | Live dashboard, filters, CSV reports | Full demo in a school |

Post-MVP: beneficiary balance lookup, leaderboards, SMS/WhatsApp, iOS,
multi-language, recycler buyer integration, impact reporting.

---

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md). The short version:

1. Open or pick an issue.
2. Branch from `main`: `feat/…`, `fix/…`, `docs/…`, `chore/…`.
3. Commit with Conventional Commits.
4. Open a PR that links the issue (`Closes #12`).
5. Wait for CI (`analyze`, `test`, `build web`).
6. **Squash merge** and delete the branch.

---

## License

MIT — see [`LICENSE`](LICENSE).

<p align="center"><sub>ReLearn · Recycle to Learn · Built for schools in Gombe, Nigeria.</sub></p>
