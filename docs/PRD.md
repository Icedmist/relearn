# ReLearn — Product Requirements Document (MVP)

| Item | Detail |
|---|---|
| Product | **ReLearn** — recycling collection and educational rewards for schools |
| Tagline | *Recycle to Learn* |
| Platform | Flutter: Android collector app + Flutter Web admin (one codebase) |
| Backend | Supabase (Postgres, Auth, Row Level Security, RPC) |
| Version | 1.0 (MVP scope) |
| Status | Ready for Stage 1 build |
| Source | `ReLearn_PRD.docx` (11 Nov 2026), expanded and made testable |

---

## 1. Summary

ReLearn turns recyclable waste into school supplies. Pupils and teachers bring
recyclables to school; a field collector scans their printed QR ID card; the
server credits points at configured rates; points are redeemed on the spot for
pencils and exercise books. Programme staff get a live dashboard of
beneficiaries, materials, points and rewards.

**One-line pitch:** *Waste in, school supplies out.*

### The problem

Schools generate recyclable paper, PET bottles, cans and sachets every day, but
there is no simple, trustworthy way to convert that waste into learning
materials for the children who collect it. Existing recycling schemes pay cash
or need smartphones and accounts that pupils do not have.

### The insight

A printed QR card is the cheapest reliable identity a child can carry. No app,
no login, no data plan, no cost per scan. The collector's phone does the work;
the server keeps the truth.

### Product principles

1. **Card, not account.** Beneficiaries never log in. The QR carries only an ID.
2. **Server is the source of truth.** Points are computed server-side; the app
   previews only.
3. **Never lose a point.** Append-only ledger, idempotency keys, no deletes.
4. **Works on a cheap phone, on a bad network.** Offline queue and sync status.
5. **Low cost by design.** No paid QR service, no SMS, no third-party per-scan fees.
6. **Safeguard children's data.** Collect the minimum; guardian phone is optional.

---

## 2. Users and permissions

| Role | Who | Device | Permissions |
|---|---|---|---|
| **Admin** | Programme staff | Flutter Web | Full access: schools, beneficiaries, cards, materials, rewards, reports, users, points adjustments |
| **Collector** | Field agent | Android app | Scan/search beneficiaries, record collections, redeem rewards, view own history, request voids |
| **Beneficiary** | Pupil or teacher | Printed QR card | None (no app, no login). Card is presented to a collector |

### Permission matrix

| Capability | Admin | Collector |
|---|---|---|
| Manage schools | ✅ | ❌ |
| Register / import beneficiaries | ✅ | ❌ |
| Print / block cards | ✅ | ❌ |
| Record collection | ✅ (web, optional) | ✅ |
| Redeem reward | ✅ (web, optional) | ✅ |
| View all beneficiaries | ✅ | Search only |
| Configure materials & rates | ✅ | ❌ |
| Manage rewards & stock | ✅ | ❌ |
| Dashboard & reports | ✅ | Today's own totals only |
| Manage users | ✅ | ❌ |
| Adjust points / approve voids | ✅ | Request only |

---

## 3. Goals, non-goals and success

### Goals

- Run a real school end to end without developer help.
- Make registration, identification, collection, points and redemption simple
  and reliable.
- Keep cost and maintenance low; no paid QR or third-party services.
- Give admins clear reporting on beneficiaries, materials, points and rewards.

### Non-goals (MVP)

- Beneficiary-facing app, login or balance check.
- Cash, mobile money, online payments or monetary rewards.
- Multi-country, multi-language, complex logistics/routing.
- Gamification, leaderboards, SMS/push notifications.
- Native iOS app (Flutter Web covers desktop admin; iOS can come later).

### Success metrics

| Metric | Target at pilot |
|---|---|
| End-to-end demo | Register → print → scan → collect → credit → redeem → dashboard, unassisted |
| Scan to beneficiary screen | < 2 s on a normal connection |
| Double-credit incidents | 0 (idempotency enforced) |
| Negative balances | 0 (transaction check) |
| Collection entry time | < 30 s for a 2-line collection |
| Card print cost | Local printer / print shop PDF only |
| Admin weekly reporting effort | < 10 minutes |

### MVP demo script (definition of done)

1. Register a school and a pupil.
2. Print the pupil's QR card.
3. Scan the card with a phone.
4. Record 2 kg of paper and see points credited.
5. Redeem an exercise book and see points deducted.
6. Confirm every step appears on the admin dashboard.

---

## 4. Core journey

```
Register school → Register beneficiary → Generate ID + QR → Print card
      → Collector scans card → Record materials → Server calculates points
      → Ledger credit → Redeem reward → Ledger debit + stock decrement
      → Dashboard and reports update
```

### Primary user stories

- **As an admin**, I can register a school and its pupils/teachers one by one or
  by CSV, so a whole class is onboarded in minutes.
- **As an admin**, I can print 8 ID cards per A4 page filtered by school/class,
  so cards are cheap and easy to distribute.
- **As a collector**, I can scan a card or search by name/ID/school, so a lost or
  damaged card never blocks a collection.
- **As a collector**, I record several materials with weights/quantities and see
  the points preview before confirming.
- **As a collector**, I redeem a reward only when balance and stock allow it, in
  one atomic operation.
- **As an admin**, I see totals and recent activity, and export transactions to
  CSV for reporting.
- **As an admin**, I can correct mistakes with an audited void or adjustment —
  never by deleting history.

---

## 5. Functional requirements

Priority: **P0** = required for the MVP demo, **P1** = important for pilot,
**P2** = later.

### Stage 1 — Registration and identification

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| F1.1 | Admin login with email/password and role-based access | P0 | Invalid credentials rejected; admin lands on dashboard; collector cannot open admin routes |
| F1.2 | Create, edit and deactivate schools | P0 | Deactivated school hidden from new registrations; historical data intact |
| F1.3 | Register pupils and teachers (name, type, school, class, optional guardian phone) | P0 | Validation on required fields; duplicate warning; record appears in list immediately |
| F1.4 | Bulk import beneficiaries from CSV with validation and error report | P1 | Valid rows imported; invalid rows listed with row number and reason; no partial corrupt rows |
| F1.5 | Generate unique human-readable beneficiary ID (e.g. `RL-0042-7K3Q`) server-side, with check character and no ambiguous characters | P0 | ID unique, excludes `0/O/1/I`; check character validates |
| F1.6 | Generate QR in-app (`qr_flutter`); QR encodes beneficiary ID only | P0 | Scanning returns exactly the public ID; no personal data in QR |
| F1.7 | Printable PDF ID cards (school, name, QR, ID text), 8 per A4, filter by school and class | P0 | PDF opens; 8 cards per page; QR scans from print at 300 dpi |
| F1.8 | Reprint/replace a lost card; ID unchanged; old card valid unless blocked | P1 | Blocking a card makes scans return "card blocked"; reprint uses same ID |

### Stage 2 — Collection management

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| F2.1 | Collector login; collectors see collector functions only | P0 | Session persists; admin routes denied |
| F2.2 | Scan QR with phone camera and load beneficiary | P0 | Valid card opens beneficiary card in < 2 s; unknown ID shows clear error |
| F2.3 | Manual search by name, ID or school when card is lost/unreadable | P0 | Results in < 1 s; tap opens beneficiary card |
| F2.4 | Record multiple materials per collection, each by weight (kg) or quantity (pieces) | P0 | At least one valid line required; total preview updates live |
| F2.5 | Collection history per collector and per beneficiary | P0 | Today's transactions visible offline and online |
| F2.6 | Offline mode: queue collections/redemptions locally, sync when online, visible sync status | P1 | Queued items survive app restart; sync is idempotent; badge shows pending count |
| F2.7 | Void request for a wrong collection (admin approves; original stays visible) | P1 | Request recorded; admin approval posts reversing ledger entry |

### Stage 3 — Points and rewards

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| F3.1 | Points = `round(quantity × points_per_unit)` at the current rate | P0 | Server-computed; client preview matches server result |
| F3.2 | Append-only points ledger; balance = sum of entries | P0 | No update/delete on ledger; balance reconciles |
| F3.3 | Show balance and transaction history on beneficiary screen | P0 | Balance and last 20 entries visible; offline shows last synced |
| F3.4 | Reward catalogue (Pencil, Exercise Book) with points cost and stock | P0 | Inactive/out-of-stock rewards cannot be redeemed |
| F3.5 | Redeem reward: check balance and stock, deduct both in one transaction | P0 | Insufficient balance/stock rejected with reason; no partial writes |
| F3.6 | Admin configures materials, units and points values | P0 | Rate changes affect new collections only (rate snapshot) |
| F3.7 | Admin manual points adjustment with mandatory reason (audit trail) | P1 | Reason required; entry shows actor and timestamp |

### Stage 4 — Dashboard and reporting

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| F4.1 | Dashboard totals: beneficiaries, materials by type, points awarded/redeemed, rewards distributed | P0 | Figures reconcile with ledger and collections |
| F4.2 | Filter by school, date range and material | P1 | Filters combine; totals update; clear-all resets |
| F4.3 | Transaction reports (collections + redemptions) with CSV export | P1 | CSV opens in Excel; respects active filters |
| F4.4 | Per-school and per-collector summaries | P2 | Summary table with counts and points |

---

## 6. Screens

Full specification, routes and states: [`SCREENS.md`](./SCREENS.md).

### Admin (Flutter Web)

1. Login
2. Dashboard
3. Schools
4. Beneficiaries
5. Register beneficiary (single + CSV)
6. Beneficiary profile
7. Print cards
8. Materials & points
9. Rewards & stock
10. Reports
11. Users

### Collector (Android)

1. Login (persistent session)
2. Home (scan, search, today's totals, sync status)
3. Scan (camera + flashlight)
4. Search
5. Beneficiary card
6. Record collection
7. Redeem
8. Success
9. History (request void)

---

## 7. Data model

| Table | Key fields |
|---|---|
| `schools` | id, name, address, active |
| `profiles` | id (auth user), name, role (`admin` \| `collector`), active |
| `beneficiaries` | id, public_id (unique), school_id, full_name, type (`pupil` \| `teacher`), class, guardian_phone, active, card_blocked |
| `materials` | id, name, unit (`kg` \| `piece`), points_per_unit, allowed, active |
| `collections` | id, beneficiary_id, collector_id, school_id, idempotency_key (unique), created_at, voided |
| `collection_items` | id, collection_id, material_id, quantity, rate_snapshot, points |
| `rewards` | id, name, points_cost, stock, active |
| `redemptions` | id, beneficiary_id, reward_id, qty, points_spent, collector_id, idempotency_key (unique), created_at, voided |
| `points_ledger` | id, beneficiary_id, type (`earn` \| `redeem` \| `adjust` \| `void`), points (+/-), ref_id, note, created_at |
| `beneficiary_balances` (view) | beneficiary_id, balance = `sum(points_ledger.points)` |

Implementation: [`supabase/migrations/0001_init.sql`](../supabase/migrations/0001_init.sql).

---

## 8. Business rules and integrity

1. **Card data:** QR holds only the beneficiary public ID. Points and personal
   data live in the database.
2. **No duplicates:** every collection/redemption carries a client-generated
   idempotency key with a unique constraint. Retries and double taps cannot
   credit or deduct twice.
3. **No negative balances:** redemption runs in one DB transaction that checks
   balance and stock before deducting.
4. **Rate snapshots:** the rate used is stored on each collection line; later
   rate changes never alter history.
5. **No deletions:** corrections are `void` or `adjust` ledger entries; original
   records stay visible.
6. **Excluded materials:** iron, metal scrap and anything that could encourage
   theft of school property are not in the catalogue. Server rejects materials
   with `allowed = false`, not just the UI.
7. **Server-side calculation:** points always computed by the server; the app
   only shows a preview.
8. **Access control:** Row Level Security enforces roles; collectors cannot edit
   settings or view admin reports.
9. **One card, one person:** a blocked card is rejected at scan time; reprint
   keeps the same public ID.
10. **Stock integrity:** redemptions decrement stock in the same transaction;
    stock can never go below zero.

### Starting material catalogue (admin-editable)

| Material | Unit | Notes |
|---|---|---|
| Paper and cardboard | kg | Points value set by admin |
| Plastic bottles (PET) | piece or kg | Points value set by admin |
| Aluminium cans | piece or kg | Points value set by admin |
| Sachet water wrappers | kg | Points value set by admin |
| Iron / metal scrap | — | **Excluded by design** |

### Suggested starting rates (pilot decision)

| Material | Rate | Reward | Cost |
|---|---|---|---|
| Paper/cardboard | 10 pts / kg | Pencil | 20 pts |
| PET bottles | 2 pts / piece | Exercise book | 80 pts |
| Aluminium cans | 3 pts / piece | | |
| Sachet wrappers | 8 pts / kg | | |

These are placeholders only; confirm with the pilot school before launch.

---

## 9. Non-functional requirements

- **Devices:** smooth on ordinary low-to-mid-range Android phones (2 GB RAM,
  Android 8+).
- **Connectivity:** collectors work offline; queued writes sync once online with
  visible status.
- **Cost:** no paid QR services; QR generation and card PDFs run on-device.
- **Security:** HTTPS, hashed credentials, RLS, audit trail on adjustments and
  voids.
- **Performance:** scan → beneficiary screen < 2 s on a normal connection; admin
  dashboard first paint < 3 s.
- **Maintainability:** one Flutter codebase, managed Postgres, migrations in
  version control.
- **Data protection:** minimal data on children; guardian phone optional; only
  authorised staff can access records.
- **Accessibility:** 16 px minimum body text in the collector app; tap targets
  ≥ 48 dp; works in bright outdoor light (high contrast).
- **Localisation:** English only for MVP; all strings centralised for later.

---

## 10. Technology stack

Summary (full rationale in [`STACK.md`](./STACK.md)):

| Layer | Choice |
|---|---|
| App framework | Flutter (Android collector + Flutter Web admin) |
| State & routing | Riverpod, go_router |
| Local storage / offline | Drift (SQLite) + sync queue |
| QR scanning | mobile_scanner |
| QR generation | qr_flutter |
| PDF cards | pdf + printing |
| Backend | Supabase (Postgres, Auth, RLS, RPC) |
| Admin hosting | Vercel (Flutter Web build) |
| Fallback backend | Fastify + Drizzle + Postgres on DigitalOcean |

---

## 11. Delivery plan

| Stage | Scope | Review point |
|---|---|---|
| **Stage 1** | Supabase schema, auth, schools, beneficiaries, ID/QR generation, printable cards | Print and scan a sample card |
| **Stage 2** | Collector login, scan, search, material entry, history, offline queue | Record a collection on a real phone |
| **Stage 3** | Points engine, balances, rewards catalogue, redemption | Redeem an exercise book end to end |
| **Stage 4** | Dashboard, filters, reports, CSV export | Full demo in a school |

This repository currently contains the **Stage 0 scaffold**: design system,
navigation, demo data and all screens clickable, ready for backend wiring.

---

## 12. Risks and open questions

| Risk / question | Mitigation / decision needed |
|---|---|
| Poor connectivity in schools | Offline queue with idempotent sync |
| Cards damaged or lost | Manual search; reprint same ID; admin can block |
| Theft-prone materials | Strict allowed-materials list enforced server-side |
| Points rates and reward costs not set | Decide starting rates before the pilot (proposal above) |
| Reward stock supply | Decide who funds/supplies pencils and exercise books, and replenishment |
| Handling children's data | Confirm school and guardian consent process before pilot |
| Who prints cards | Decide: in-house or send PDFs to a print shop |
| Shared collector phones | Decide whether one device is shared per school; session handling |

---

## 13. Future (post-MVP)

- Beneficiary/parent balance lookup by ID (no login required).
- School-level leaderboards and house competitions.
- SMS or WhatsApp notification on redemption.
- iOS admin/collector build.
- Multi-language (Hausa, Yoruba, Igbo, French).
- Recycler buyer integration and material resale reporting.
- Carbon/impact reporting for sponsors.
