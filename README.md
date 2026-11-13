<p align="center">
  <img src="assets/brand/logo_horizontal.svg" alt="ReLearn — Recycle to Learn" width="360">
</p>

<h1 align="center">ReLearn</h1>
<p align="center"><strong>Waste in. School supplies out.</strong></p>

<p align="center">
  <a href="https://github.com/Icedmist/relearn/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/Icedmist/relearn/actions/workflows/ci.yml/badge.svg"></a>
  <a href="#status"><img alt="Status" src="https://img.shields.io/badge/status-v0.4.1-2E9E5B"></a>
  <a href="#stack"><img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B"></a>
  <a href="#stack"><img alt="Supabase" src="https://img.shields.io/badge/Backend-Supabase-3ECF8E"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-blue"></a>
</p>

---

ReLearn is a school recycling rewards system. Pupils and teachers bring paper,
bottles, cans and sachets to school. A staff member records what they brought
against the pupil's printed card, the server credits points at the configured
rates, and the pupil spends those points on pencils, exercise books, bags and
other school supplies.

**A pupil needs one printed card, not a phone or an account.** The card carries
a public ID and a QR code. Staff look the card up by ID (camera scanning is on
the roadmap) and all points and personal data stay in the database.

ReLearn ships as one Flutter codebase with two experiences:

- **Admin web app** — schools, beneficiaries, card printing, materials and
  rates, item shop, reports, staff accounts.
- **Android collector app** — open a pupil card, record a collection, redeem an
  item, review today's history.

> <a id="status"></a>**Status: v0.4.1.** Live Supabase authentication,
> PostgreSQL, Row Level Security, server-side points and redemption, card PDF
> printing, product photo upload and biometric session lock are working.
> Camera scanning, CSV import/export and offline sync are **not** implemented
> yet; the screens say so instead of pretending.

---

## Table of contents

- [How it works](#how-it-works)
- [What works today](#what-works-today)
- [Not implemented yet](#not-implemented-yet)
- [Screens](#screens)
- [Accounts and sessions](#accounts-and-sessions)
- [Card printing](#card-printing)
- [Demo walkthrough](#demo-walkthrough)
- [Stack](#stack)
- [Repository layout](#repository-layout)
- [Getting started](#getting-started)
- [Supabase setup](#supabase-setup)
- [Architecture and data flow](#architecture-and-data-flow)
- [Data model](#data-model)
- [Build and release](#build-and-release)
- [Documentation](#documentation)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## How it works

1. **Register the school** in the admin app.
2. **Register a pupil or teacher.** ReLearn generates a public ID such as
   `RL-0042-7K3Q` and a QR code that contains only that ID.
3. **Print the card.** Export an A4 sheet of eight cards as a PDF and print it
   on a local printer.
4. **Collect recyclables.** In the collector app, enter the ID printed under
   the QR, choose the materials and quantities, and confirm. The server
   recalculates the points and writes an append-only ledger entry.
5. **Redeem.** Open the same card, choose an item from the shop, and confirm.
   The server checks the balance and stock inside one transaction, then deducts
   points and stock.
6. **Review.** The dashboard and reports show collections, redemptions and the
   full points ledger.

Each collection line stores the rate that was active when it was recorded, so
changing a rate never rewrites history.

---

## What works today

### Admin — Flutter Web

- **Dashboard** — active beneficiaries, kilograms collected, points awarded,
  points redeemed, rewards distributed, a 7-day collections chart, top
  materials and recent activity.
- **Schools** — add a school, rename it, activate or deactivate it.
- **Beneficiaries** — search and filter, register one pupil or teacher, open a
  profile with balance, QR, ledger and collections, block or unblock a card,
  post a manual points adjustment.
- **Card printing** — filter by school and class, select cards, and generate an
  eight-per-A4-page PDF through the system print/save dialog.
- **Materials & points** — add a material, edit its rate, allow or disallow it,
  and activate or deactivate it. New rates affect new collections only.
- **Item shop** — search and filter by category; add or edit name, category,
  description, points cost, stock and visibility; upload a photo from the
  gallery or camera; restock; deactivate; delete.
- **Reports** — collections, redemptions and the points ledger, filtered by
  school, with row and points totals.
- **Users** — create staff accounts, set the role, activate or deactivate a
  staff member, and send a password-reset email.
- **Account centre** — edit your name, change your password, enable
  fingerprint/face unlock, replay the guide and sign out.

### Collector — Android

- **Home** — today's totals, current materials and quick actions.
- **Find a pupil** — enter the public ID printed under the QR code.
- **Search** — look up a beneficiary by name, ID, school or class.
- **Beneficiary card** — balance, recent ledger, collection and redemption
  actions.
- **Record collection** — choose materials, enter kilograms or piece counts,
  see a live points preview, and save through the server RPC.
- **Redeem** — browse in-stock items, check the balance, and confirm a
  redemption.
- **History** — today's collections and redemptions for the signed-in
  collector.
- **Account centre** — the same profile, security and guide tools as admin.

### Shared

- Email/password authentication through Supabase.
- Live mode reads and writes the hosted Supabase project; demo mode runs on an
  in-memory seed with no network and no persistence.
- Row Level Security on every table, with server-side points and redemption
  functions.
- First-run onboarding and a replayable “How to use ReLearn” guide.
- Live sessions lock after 15 minutes of inactivity. Unlock with fingerprint or
  face on Android, or the account password everywhere.

---

## Not implemented yet

These are shown honestly in the UI, usually with a disabled control or a short
explanation:

- **Camera QR scanning.** Collectors enter the ID manually today.
- **CSV beneficiary import.** The registration screen offers single entry only.
- **CSV report export.** Reports are on screen; export is planned.
- **Offline queue and sync.** The app requires a connection for live data.
- **Automatic card printing.** PDF export opens the system print dialog; you
  choose the printer.
- **Beneficiary self-service.** There is no pupil login or balance lookup.

---

## Screens

### Admin — Flutter Web

| # | Screen | Route |
|---|---|---|
| 1 | Login | `/login` |
| 2 | Onboarding / how-to | `/onboarding` |
| 3 | Dashboard | `/admin/dashboard` |
| 4 | Schools | `/admin/schools` |
| 5 | Beneficiaries | `/admin/beneficiaries` |
| 6 | Register beneficiary | `/admin/beneficiaries/new` |
| 7 | Beneficiary profile | `/admin/beneficiaries/:id` |
| 8 | Print cards | `/admin/print` |
| 9 | Materials & points | `/admin/materials` |
| 10 | Item shop | `/admin/rewards` |
| 11 | Reports | `/admin/reports` |
| 12 | Users | `/admin/users` |
| 13 | Account | `/account` |

### Collector — Android

| # | Screen | Route |
|---|---|---|
| 1 | Login | `/login` |
| 2 | Onboarding / how-to | `/onboarding` |
| 3 | Home | `/collector/home` |
| 4 | Find a pupil | `/collector/scan` |
| 5 | Search | `/collector/search` |
| 6 | Beneficiary card | `/collector/beneficiary/:id` |
| 7 | Record collection | `/collector/beneficiary/:id/collect` |
| 8 | Redeem | `/collector/beneficiary/:id/redeem` |
| 9 | Success | `/collector/success` |
| 10 | History | `/collector/history` |
| 11 | Account | `/account` |

Full content, actions and states: [`docs/SCREENS.md`](docs/SCREENS.md).

---

## Accounts and sessions

Every staff member can open **Account** from the top bar or the admin drawer.

- **Name** — staff rename themselves through the `update_my_name` RPC
  (migration `0006`). The RPC can change only the name, never the role.
- **Password** — changed through Supabase Auth. There is also a password-reset
  email flow on the login screen and in **Admin → Users**.
- **Fingerprint / face** — available on Android when the device has an enrolled
  biometric. Web falls back to the account password.
- **Session lock** — live sessions lock after 15 minutes of inactivity. The
  lock screen can unlock with biometrics or the password, or sign out.
- **Demo mode** — never locks, never persists security settings, and shows a
  “changes are not saved” banner.
- **First sign-in** — shows the onboarding guide once. Replay it from
  **Account → How to use ReLearn** or from the login screen.
- **Stale sessions** — if a saved session cannot load its staff profile, the app
  signs out and returns to login instead of opening an empty admin screen.

Android biometric support needs `FlutterFragmentActivity`, the
`USE_BIOMETRIC` permission, the legacy `USE_FINGERPRINT` permission and
`minSdk 23`. All are configured in this repository.

---

## Card printing

1. Open **Admin → Print cards**.
2. Choose a school and, optionally, a class.
3. Select individual cards, or leave the selection empty to use every filtered
   card.
4. Tap **Export PDF**. ReLearn builds the PDF locally and opens the system
   print dialog; choose a printer or “Save as PDF”.

The sheet holds eight cards on A4. Every card includes the pupil name, type,
class, school and public ID, plus a QR code that contains only the public ID.
The QR is printed at 25 mm so it stays readable on cheap printers.

You can also print one card from a beneficiary profile with **Print card**.

---

## Demo walkthrough

1. `flutter run -d chrome` — no credentials are needed, so demo mode starts
   automatically.
2. Sign in with the prefilled demo email and password.
3. Complete or skip the onboarding guide.
4. Open **Beneficiaries → Amina Yusuf** to see the QR, balance and ledger.
5. Switch to the collector app with the QR icon in the top bar.
6. Tap **Find a pupil** and enter `RL-0042-7K3Q`, or use the demo sample-card
   action.
7. Tap **Record collection**, adjust the material quantities and confirm.
8. See the success screen with the new balance.
9. Redeem an **Exercise book** and watch points and stock drop.
10. Open **Account** to replay the guide, then return to the dashboard and see
    the new activity.

Demo numbers reset when the app restarts. The sample-card action appears only
in demo mode.

---

## Stack

| Layer | Choice |
|---|---|
| UI | Flutter 3.x (Android + Web, one codebase) |
| State | Riverpod |
| Routing | go_router |
| Backend | Supabase (Postgres, Auth, Storage, RLS, RPC) |
| QR generation | `qr_flutter` in the UI, `pdf`/`barcode` in card PDFs |
| Card PDF | `pdf` + `printing` |
| Product photos | `image_picker` + Supabase Storage |
| Session security | `local_auth` + `shared_preferences` |
| Charts | Custom Flutter bars |
| Local offline store | Not implemented (roadmap) |
| Hosting | GitHub Releases for the APK and web zip; deploy the web build anywhere static |

Rationale and trade-offs: [`docs/STACK.md`](docs/STACK.md).

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
│   ├── core/                config, router, auth, services, theme, widgets
│   ├── data/                models, app store, Supabase repository
│   └── features/
│       ├── account/
│       ├── auth/
│       ├── onboarding/
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

Without Supabase credentials the app runs entirely in memory. Nothing is sent
to a server and changes disappear on restart.

### Run against Supabase

Copy `.env.example` to `.env`, fill in the project URL and **publishable** key,
then run with the define file (`.env` is gitignored):

```bash
cp .env.example .env
flutter run -d chrome --dart-define-from-file=.env
```

Live mode turns on automatically when both values are present. Set
`DEMO_MODE=true` in `.env` to force the in-memory store.

Accounts created from **Admin → Users** can sign in immediately. The hosted
project currently contains seeded demo schools and catalogue items; replace
them with real programme data before a pilot.

### Checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

---

## Supabase setup

1. Create a project at [supabase.com](https://supabase.com).
2. Apply the migrations and seed:

```bash
supabase link --project-ref <ref>
supabase db push
psql "$DATABASE_URL" -f supabase/seed.sql
```

Migrations:

| File | Purpose |
|---|---|
| `0001_init.sql` | Schema, enums, indexes, balance view, ledger, RLS and RPCs |
| `0002_staff_directory.sql` | Staff directory view, hardened signup, atomic restock |
| `0003_educational_catalogue.sql` | School supplies catalogue and point costs |
| `0004_item_images.sql` | Public `item-images` bucket, admin-only writes, `image_url` columns |
| `0005_reward_details.sql` | Item category and description for marketplace cards |
| `0006_update_my_name.sql` | Staff can rename themselves via a safe RPC |

3. Create the first admin user in **Authentication → Users**, then promote the
   profile. Every self-signup starts as a collector; admins are explicit:

```sql
update public.profiles set role = 'admin' where id = '<auth-user-id>';
```

4. Run the app with credentials:

```bash
cp .env.example .env
flutter run -d chrome --dart-define-from-file=.env
```

The **publishable/anon key is safe to ship** because RLS enforces access. The
**secret/service-role key** bypasses RLS: keep it server-side only, never in the
app or repository. See [`.env.example`](.env.example).

### Item images

`0004_item_images.sql` creates a public-read `item-images` bucket (5 MB limit;
PNG, JPEG, WebP). Only active admins can upload, replace or delete files, which
RLS checks through `public.is_admin()`. Admins can upload from the **Add item**
or **Edit item** form with the gallery or camera; the app sends the file to
`item-images` and saves the returned public URL. You can also upload from
**Storage → item-images** and paste the URL into the form.

---

## Architecture and data flow

```
Screens ──► Riverpod AppStore ──► SupabaseRepository ──► Supabase
   │              │
   └── local UI   └── in-memory demo seed (demo mode only)
```

- Screens watch a single `AppStore` snapshot. Feature screens do not query
  Postgres directly; they call store methods. Authentication and account
  screens use Supabase Auth directly because they manage the session itself.
- The client never writes a points total. Collection and redemption screens
  call `record_collection` and `redeem_reward`, which recalculate and write the
  ledger inside one transaction.
- `points_ledger` is append-only. Corrections are new `adjust` or `void`
  entries.
- Collection lines snapshot the rate, so later rate edits do not change
  history.
- RLS is the security boundary. Route guards and disabled buttons are only UX.

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
| `rewards` / `redemptions` | School supplies catalogue, stock and redemptions |
| `points_ledger` | Append-only earn / redeem / adjust / void entries |
| `beneficiary_balances` | Derived balance view |

Item photos live in the public `item-images` Storage bucket; `materials` and
`rewards` carry an `image_url`.

Full detail: [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) and
[`supabase/migrations/0001_init.sql`](supabase/migrations/0001_init.sql).

---

## Build and release

```bash
# Web admin
flutter build web --release --dart-define-from-file=.env

# Android APK
flutter build apk --release --dart-define-from-file=.env
```

Deploy `build/web` to any static host and add an SPA rewrite to `index.html`
for client-side routes. Vercel: build command `flutter build web`, output
directory `build/web`.

Every `v*` tag runs [`release.yml`](.github/workflows/release.yml), which
builds the APK and a zipped web admin and publishes both to GitHub Releases.

- Latest release: <https://github.com/Icedmist/relearn/releases/latest>
- Assets: `app-release.apk` and `relearn-web.zip`
- Build variables: repository variables `SUPABASE_URL` and
  `SUPABASE_PUBLISHABLE_KEY` (never the secret/service-role key)
- The published APK is currently **debug-signed**; configure a production
  keystore before Play Store distribution.

---

## Documentation

| Document | What it covers |
|---|---|
| [`docs/PRD.md`](docs/PRD.md) | Problem, goals, users, requirements, acceptance criteria, risks |
| [`docs/SCREENS.md`](docs/SCREENS.md) | Every screen, route, action and UI state |
| [`docs/STACK.md`](docs/STACK.md) | Stack decisions, architecture, deployment, costs |
| [`docs/DESIGN.md`](docs/DESIGN.md) | Name, logo concept, palette, typography, UI tokens |
| [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) | Schema, relationships, ID format, integrity rules |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Issue → branch → PR → squash merge workflow |
| [`CHANGELOG.md`](CHANGELOG.md) | Release history |

---

## Roadmap

| Stage | Scope | State |
|---|---|---|
| **0 · Scaffold** | Design system, routes, demo store, schema, docs | ✅ Done |
| **1 · Registration and cards** | Auth, schools, beneficiaries, IDs, QR, printable card PDFs | ✅ Done |
| **2 · Collection** | Collector sign-in, manual lookup, entry, history | ✅ Done |
| **3 · Points and rewards** | Server points engine, balances, catalogue, atomic redemption | ✅ Done |
| **4 · Field hardening** | Camera scanning, CSV import/export, offline queue, production keystore | Next |

Post-MVP ideas: pupil balance lookup, leaderboards, SMS/WhatsApp notifications,
iOS, multi-language, recycler buyer integration and impact reporting.

---

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md). The short version:

1. Open or pick an issue.
2. Branch from `main`: `feat/…`, `fix/…`, `docs/…`, `chore/…`.
3. Commit with Conventional Commits.
4. Open a PR that links the issue (`Closes #12`).
5. Wait for CI (`format`, `analyze`, `test`, `build web`).
6. **Squash merge** and delete the branch.

---

## License

MIT — see [`LICENSE`](LICENSE).

<p align="center"><sub>ReLearn · Recycle to Learn · Built for schools in Gombe, Nigeria.</sub></p>
