# ReLearn — Stack and Architecture

## 1. Decision summary

| Layer | Choice | Why |
|---|---|---|
| UI | **Flutter 3.x** | One codebase for the Android collector app and the Flutter Web admin, as required by the PRD |
| State | **Riverpod** | Testable, no BuildContext coupling, good async/offline state modelling |
| Routing | **go_router** | Declarative routes, deep links, role redirects, web URLs |
| Local DB / offline | **Drift (SQLite)** + sync queue | Real relational storage, reactive queries, survives restarts |
| Backend | **Supabase** | Managed Postgres, email auth, Row Level Security, RPC for atomic point operations |
| QR scan | **mobile_scanner** | Maintained, fast, Android + web support, MLKit-based |
| QR generate | **qr_flutter** | Pure Dart, no paid service, works offline |
| PDF cards | **pdf** + **printing** | On-device PDF generation and print/share sheet |
| Hosting | **Vercel** (web) + **Play Store internal track** (Android) | Zero-cost static hosting for Flutter Web; easy APK distribution |
| Charts | **fl_chart** | Lightweight, no licence issues |
| Fallback backend | Fastify + Drizzle + Postgres on DigitalOcean | Only if full control or self-hosting is required later |

### Why one Flutter project, not two apps

The PRD calls for a collector Android app and a web admin. Both share models,
validation, the design system and the Supabase client. One project with two
route trees (`/admin/*`, `/collector/*`) and platform-aware shells avoids a
second codebase while still letting the Android build exclude admin routes from
navigation. If the admin later needs heavy desktop-only widgets, split it into a
separate package — the shared `core/` and `data/` layers already allow that.

### Why Supabase over a custom API

- RLS gives row-level authorisation close to the data, so the client can read
  directly without an API layer for every screen.
- Postgres functions make the money-like operations (collect, redeem, adjust)
  atomic and idempotent.
- Managed backups, auth, and a generous free tier keep pilot costs near zero.
- If the project outgrows it, the Postgres schema and RPCs port directly to
  Fastify + Drizzle with minimal changes.

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Flutter app (Android + Web)                                 │
│                                                             │
│  presentation/  screens, widgets, theme                     │
│       │ Riverpod providers                                  │
│  application/   use cases: collect, redeem, sync            │
│       │                                                     │
│  data/          repositories ──► Supabase client (online)   │
│       │                    └──► Drift + sync queue (offline)│
└───────────────────────────┬─────────────────────────────────┘
                            │ HTTPS / JWT
┌───────────────────────────▼─────────────────────────────────┐
│ Supabase                                                    │
│  Auth (email/password)                                      │
│  Postgres + RLS                                             │
│  RPC: record_collection(), redeem_reward(), adjust_points() │
│  Views: beneficiary_balances, dashboard_totals              │
└─────────────────────────────────────────────────────────────┘
```

### Layering rules

1. Screens never call `supabase` directly; they call a repository/use case.
2. Points are never calculated in the UI for storage. The preview is a pure
   function shared with tests; the server recalculates on write.
3. Every write has an idempotency key generated on the client.
4. Offline writes go to the queue first, then replay in order when online.
5. Admin and collector route trees are guarded by role; RLS is the real
   enforcement, route guards are UX only.

---

## 3. Packages

| Package | Purpose | Stage |
|---|---|---|
| `flutter_riverpod` | State management, DI | 0 |
| `go_router` | Routing, deep links, redirects | 0 |
| `intl` | Dates, numbers, thousands separators | 0 |
| `flutter_svg` | Brand logo rendering | 0 |
| `qr_flutter` | QR generation for cards and profiles | 0 |
| `supabase_flutter` | Auth + Postgres + storage client | 1 |
| `mobile_scanner` | QR scanning | 2 |
| `drift`, `sqlite3_flutter_libs`, `path_provider`, `path` | Offline DB | 2 |
| `connectivity_plus` | Online/offline signal | 2 |
| `pdf`, `printing` | A4 card PDFs and printing | 1 |
| `fl_chart` | Dashboard charts | 4 |
| `csv` | CSV import/export | 1 |
| `file_picker` | CSV and logo asset picking | 1 |
| `shared_preferences` | Non-sensitive flags, last sync | 2 |
| `flutter_secure_storage` | Session tokens (Android) | 2 |
| `uuid` | Idempotency keys | 1 |
| `flutter_lints`, `mocktail`, `build_runner`, `drift_dev` | Dev tooling | 0/2 |

Versions are pinned in `pubspec.yaml` and locked in `pubspec.lock`.

---

## 4. Folder structure

```
relearn/
├── docs/                       PRD, screens, stack, design, data model
├── supabase/
│   ├── migrations/0001_init.sql
│   └── seed.sql
├── assets/brand/               logo SVGs and PNG
├── lib/
│   ├── main.dart               bootstrap, Supabase init (stage 1)
│   ├── app.dart                MaterialApp.router
│   ├── core/
│   │   ├── config/             AppConfig (dart-define)
│   │   ├── router/             go_router routes + guards
│   │   ├── theme/              colours + ThemeData
│   │   └── widgets/            logo, KPI card, empty state, pills
│   ├── data/
│   │   ├── models.dart         domain models
│   │   ├── demo_store.dart     in-memory store for the clickable scaffold
│   │   └── repositories/       Supabase + offline implementations (stage 1/2)
│   └── features/
│       ├── auth/
│       ├── admin/
│       ├── collector/
│       └── shared/
├── test/
└── pubspec.yaml
```

---

## 5. Environment and configuration

Use `--dart-define` so no secret ever enters git:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=DEMO_MODE=false
```

`AppConfig` reads these values and defaults to demo mode when they are absent.
The **anon key is safe for clients** because RLS enforces access; the
**service-role key must never ship in the app** and is only used in scripts.

A checked-in `.env.example` documents the keys; `.env` is gitignored.

---

## 6. Backend design

### Tables

See [`docs/DATA_MODEL.md`](./DATA_MODEL.md) and
[`supabase/migrations/0001_init.sql`](../supabase/migrations/0001_init.sql).

### RPC functions (atomic, security definer, role-checked)

| Function | Input | Guarantees |
|---|---|---|
| `record_collection(p_beneficiary_id, p_items jsonb, p_idempotency_key)` | items `[{material_id, quantity}]` | Validates card/beneficiary/material, snapshots rate, computes points, inserts collection + items + ledger credit, returns new balance |
| `redeem_reward(p_beneficiary_id, p_reward_id, p_qty, p_idempotency_key)` | quantity | Locks reward and balance, checks stock and points, decrements stock, inserts redemption + ledger debit, returns new balance |
| `adjust_points(p_beneficiary_id, p_points, p_reason)` | delta + reason | Admin only, mandatory reason, ledger `adjust` |
| `void_transaction(p_kind, p_id, p_reason)` | collection/redemption id | Admin only, posts reversing entry, marks original voided |
| `next_public_id(p_school_code)` | — | Generates `RL-XXXX-XXXX` with check character, excludes ambiguous characters |

Idempotency: unique indexes on `collections.idempotency_key` and
`redemptions.idempotency_key`; the RPC returns the existing row on conflict
instead of double-crediting.

### RLS policy sketch

- `profiles`: users read their own row; admins read all.
- `schools`, `beneficiaries`, `materials`, `rewards`: admins full CRUD;
  collectors read active rows and can read beneficiaries (needed for scans) but
  cannot update.
- `collections`, `redemptions`: collectors insert only through RPC; read their
  own; admins read all.
- `points_ledger`: read-only for the owning beneficiary's collector flows;
  all writes happen inside security-definer RPCs.
- `beneficiary_balances`: security-invoker view over the ledger.

---

## 7. Offline and sync design

1. Collector action writes a row to `sync_queue` (Drift) with a UUID
   idempotency key and a JSON payload.
2. UI shows the optimistic result and a "pending" badge.
3. A sync worker drains the queue in order when connectivity returns.
4. Each RPC is idempotent, so retries are safe.
5. On conflict (e.g. balance changed elsewhere), the item is marked `conflict`
   and surfaced to the collector with the server result.
6. Reference data (materials, rewards, beneficiaries) is cached with a
   `last_synced_at`; stale data is allowed for scanning but never for final
   balances.

Offline is **P1**: the scaffold ships an in-memory store, and the queue lands in
Stage 2.

---

## 8. Testing

| Level | Tool | What |
|---|---|---|
| Unit | `flutter_test` | Points formula, ID check character, balance math, CSV parsing |
| Widget | `flutter_test` | Record collection preview, redeem guards, login validation |
| Integration | `integration_test` | Demo script: register → print data → scan ID → collect → redeem |
| Backend | `supabase test db` / SQL tests | RPC atomicity, idempotency, RLS per role |

CI (GitHub Actions): `flutter analyze`, `flutter test`, `flutter build web`, and
a SQL migration check. APK build on tags only.

---

## 9. Build and deploy

```bash
# Web admin (Vercel)
flutter build web --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...

# Android (Play internal track / direct APK)
flutter build appbundle --release
flutter build apk --release --split-per-abi
```

Vercel: build command `flutter build web`, output `build/web`, install Flutter
in the build image or use a prebuilt Docker image. Add a rewrite to
`index.html` for client-side routes.

Android: set `applicationId com.relearn.app`, minSdk 23 (mobile_scanner),
target latest, camera permission in the manifest.

---

## 10. Cost estimate (pilot)

| Item | Cost |
|---|---|
| Supabase free tier | $0 (500 MB DB, 50k MAU) |
| Vercel Hobby | $0 |
| Domain | ~$12/year |
| Card printing | Local, per page |
| Total | **< $15/year** plus printing |

Upgrade triggers: DB > 500 MB, > 50k monthly users, or need for daily backups —
still under $25/month.

---

## 11. What is deliberately not used

- **Firebase:** NoSQL is a poor fit for a ledger and reporting queries.
- **Paid QR services:** violates the cost principle; on-device QR is enough.
- **A separate Node API for MVP:** RLS + RPC covers the needs with less to host.
- **GraphQL:** adds a layer without solving a current problem.
- **google_fonts at runtime:** network dependency and layout shift; use system
  fonts or bundle a font file later.
