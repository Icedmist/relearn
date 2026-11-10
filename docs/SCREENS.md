# ReLearn — Screen Specification

Every screen below exists as a route in the scaffold and is clickable in demo
mode. Widgets marked **[wire]** currently use demo data and are ready for a
Supabase repository.

---

## 0. Route map

| Route | Screen | Role | File |
|---|---|---|---|
| `/login` | Login / role select | Public | `features/auth/login_screen.dart` |
| `/admin/dashboard` | Dashboard | Admin | `features/admin/dashboard_screen.dart` |
| `/admin/schools` | Schools | Admin | `features/admin/schools_screen.dart` |
| `/admin/beneficiaries` | Beneficiaries | Admin | `features/admin/beneficiaries_screen.dart` |
| `/admin/beneficiaries/new` | Register beneficiary | Admin | `features/admin/register_beneficiary_screen.dart` |
| `/admin/beneficiaries/:id` | Beneficiary profile | Admin | `features/admin/beneficiary_profile_screen.dart` |
| `/admin/print` | Print cards | Admin | `features/admin/print_cards_screen.dart` |
| `/admin/materials` | Materials & points | Admin | `features/admin/materials_screen.dart` |
| `/admin/rewards` | Rewards & stock | Admin | `features/admin/rewards_screen.dart` |
| `/admin/reports` | Reports | Admin | `features/admin/reports_screen.dart` |
| `/admin/users` | Users | Admin | `features/admin/users_screen.dart` |
| `/collector/home` | Home | Collector | `features/collector/home_screen.dart` |
| `/collector/scan` | Scan | Collector | `features/collector/scan_screen.dart` |
| `/collector/search` | Search | Collector | `features/collector/search_screen.dart` |
| `/collector/beneficiary/:id` | Beneficiary card | Collector | `features/collector/beneficiary_card_screen.dart` |
| `/collector/beneficiary/:id/collect` | Record collection | Collector | `features/collector/record_collection_screen.dart` |
| `/collector/beneficiary/:id/redeem` | Redeem | Collector | `features/collector/redeem_screen.dart` |
| `/collector/success` | Success | Collector | `features/collector/success_screen.dart` |
| `/collector/history` | History | Collector | `features/collector/history_screen.dart` |

Navigation shells: `features/admin/admin_shell.dart` (NavigationRail on wide,
drawer on narrow) and `features/collector/collector_shell.dart` (bottom nav).

---

## 1. Login `/login`

**Purpose:** authenticate and route by role.

**Layout:** split screen on wide web (brand panel left, form right); single
column on mobile. Brand panel shows logo, tagline, and a one-line explanation.

**Content**
- Email, password, show/hide password.
- "Sign in" primary button.
- Demo mode: "Continue as Admin" and "Continue as Collector" (scaffold only).
- Forgot password link (P1).
- Version and environment badge in the footer.

**States:** idle, loading, invalid credentials, server unreachable, account
deactivated.

**Actions:** sign in → `/admin/dashboard` or `/collector/home`; demo buttons
bypass auth only while `AppConfig.demoMode` is true.

---

## 2. Admin — Dashboard `/admin/dashboard`

**Purpose:** a 30-second health check of the programme.

**Content**
- Greeting + date + school filter (P1).
- KPI cards: beneficiaries registered, kg collected, points awarded, points
  redeemed, rewards distributed. Each with delta vs previous period.
- "Collections over time" chart (7/30/90 days).
- "Top materials" horizontal bars.
- "Recent activity" list: collector, beneficiary, material/points, time.
- Low-stock alert banner when any reward stock ≤ 10.

**Actions:** change period; open beneficiary; open report.

**States:** loading skeletons, empty programme (CTA to register first school),
error retry.

**Demo:** KPIs and activity come from `DemoStore`.

---

## 3. Admin — Schools `/admin/schools`

**Purpose:** manage the school list.

**Content**
- Search, active/inactive filter.
- Table: name, address, beneficiaries count, points this term, status, actions.
- "Add school" button → dialog/side sheet (name, address, contact name, phone).
- Row actions: edit, deactivate/reactivate, view beneficiaries.

**States:** empty, no search results, validation errors, confirm deactivate.

**Rules:** deactivation never deletes data; inactive schools are excluded from
new registrations.

---

## 4. Admin — Beneficiaries `/admin/beneficiaries`

**Purpose:** find and manage people.

**Content**
- Search by name/ID, filters: school, type (pupil/teacher), class, status.
- Table/cards: name, public ID, school, type, class, balance, card status.
- Bulk actions: export CSV (P1), print selected cards.
- Primary CTA: "Register beneficiary".
- Entry point for CSV import.

**Actions:** open profile; register; import CSV; print.

---

## 5. Admin — Register beneficiary `/admin/beneficiaries/new`

**Purpose:** create one person or import many.

**Single form**
- Full name (required), type (pupil/teacher), school (required), class
  (required for pupils), guardian phone (optional).
- On save: server generates `public_id`; show success sheet with QR preview and
  "Print card" / "Register another" actions.

**CSV import (P1)**
- Download template (`name,type,school,class,guardian_phone`).
- Drag/drop or pick file.
- Validation preview: N valid, M errors with row numbers and reasons.
- Import valid rows only after confirmation; download error report.
- Import is idempotent per file hash (guard against double upload).

**States:** saving, duplicate warning, invalid school, partial import result.

---

## 6. Admin — Beneficiary profile `/admin/beneficiaries/:id`

**Purpose:** the single view of a person.

**Content**
- Header: name, type, school, class, status, public ID.
- QR preview (regenerate print), "Print card", "Replace card", "Block card".
- Balance card with large number.
- Tabs: History (ledger), Collections, Redemptions, Notes.
- Full ledger with type, points ±, reference, actor, reason, timestamp.
- "Adjust points" action (P1) with mandatory reason.

**Rules:** block card makes scans fail with a clear collector message; reprint
keeps the ID; no delete anywhere.

---

## 7. Admin — Print cards `/admin/print`

**Purpose:** produce cheap physical cards.

**Content**
- Filters: school (required), class (optional), include inactive (off).
- Selection list with select-all.
- Live A4 preview, 8 cards per page (2 × 4), crop marks.
- Card face: ReLearn mark, school name, beneficiary name, class, QR, public ID,
  "This card belongs to your school. Return it if found."
- Export/print button → PDF via `pdf`/`printing`.

**States:** no beneficiaries, generating PDF, print dialog.

**Notes:** QR encodes only the public ID; minimum QR size 25 mm; quiet zone
preserved.

---

## 8. Admin — Materials & points `/admin/materials`

**Purpose:** control what is accepted and what it is worth.

**Content**
- Table: material, unit, points per unit, allowed, active, last changed.
- Add/edit dialog: name, unit (kg/piece), points per unit, allowed toggle,
  active toggle.
- Warning banner explaining that excluded materials (iron/metal scrap) are
  rejected server-side.

**Rules:** rates apply to new collections only; rate snapshots protect history.

---

## 9. Admin — Rewards & stock `/admin/rewards`

**Purpose:** manage the catalogue and stock.

**Content**
- Cards/table: reward, points cost, stock, active, redemptions count.
- Add/edit: name, points cost, stock, active.
- "Restock" quick action with quantity; stock movement history (P2).
- Low-stock highlight at ≤ 10.

**Rules:** cannot redeem inactive or zero-stock rewards; stock decrements
atomically with redemption.

---

## 10. Admin — Reports `/admin/reports`

**Purpose:** exportable truth.

**Content**
- Tabs: Collections | Redemptions | Points ledger.
- Filters: school, date range, material/reward, collector.
- Summary strip: rows, total kg, points in/out.
- Table with pagination.
- "Export CSV" respects active filters.
- Per-school / per-collector summary (P2).

---

## 11. Admin — Users `/admin/users`

**Purpose:** manage collectors and admins.

**Content**
- Table: name, email, role, status, last active.
- Create user (email, name, role) → invite email via Supabase Auth.
- Reset password (send link), deactivate/reactivate.
- Role change restricted to admins.

---

## 12. Collector — Login `/login`

Same screen as admin; collector credentials route to `/collector/home`.
Session persists (secure storage). Offline login is allowed with a cached
session for 30 days (P1).

---

## 13. Collector — Home `/collector/home`

**Purpose:** start work in one tap.

**Content**
- Greeting, school/route name, sync status pill.
- Large primary "Scan QR card" button.
- Secondary "Search beneficiary".
- Today: collections count, kg, points awarded, rewards given.
- Pending sync count + "Sync now" when online.
- Recent beneficiaries (last 3) for quick return.

**States:** offline banner, syncing, sync failed with retry.

---

## 14. Collector — Scan `/collector/scan`

**Purpose:** identify a beneficiary fast.

**Content**
- Full-screen camera preview (`mobile_scanner`).
- Scan frame with corner brackets, instruction text.
- Flashlight toggle, camera switch.
- "Enter ID manually" fallback.
- Haptic + sound on successful scan.

**States:** permission denied (link to settings), camera error, unknown ID,
blocked card, inactive beneficiary, duplicate scan debounce (1.5 s).

**Rules:** scanning pauses after a hit to prevent double navigation.

---

## 15. Collector — Search `/collector/search`

**Purpose:** recover from lost/unreadable cards.

**Content**
- Search field (name, public ID, school) with debounce.
- Recent searches.
- Result rows: name, ID, school, class, balance; tap opens beneficiary card.
- Empty state with tips.

---

## 16. Collector — Beneficiary card `/collector/beneficiary/:id`

**Purpose:** the collector's decision screen.

**Content**
- Name, type, school, class, public ID.
- Large balance with "pts".
- Last transaction summary.
- Primary actions: **Record collection**, **Redeem reward**.
- Secondary: view history.
- Blocked card warning if blocked.

---

## 17. Collector — Record collection `/collector/beneficiary/:id/collect`

**Purpose:** capture materials accurately.

**Content**
- Beneficiary strip (name, balance).
- Material picker (only allowed + active).
- Line items: material, unit, quantity (stepper + numeric keypad), rate,
  line points. Add another line.
- Live points preview: `round(qty × rate)` per line + total.
- Optional note.
- Confirm button (disabled with no valid lines).
- Success → `/collector/success` with earned points and new balance.

**States:** invalid quantity, material disabled mid-session (server rejects),
offline (queued state), submit error with retry.

**Rules:** client preview only; server recalculates; idempotency key generated
per submission.

---

## 18. Collector — Redeem `/collector/beneficiary/:id/redeem`

**Purpose:** exchange points for supplies.

**Content**
- Beneficiary strip and current balance.
- Reward cards with points cost, stock, and "can afford" state.
- Quantity stepper.
- Summary: cost, balance after, stock after.
- Confirm button disabled if insufficient balance/stock.
- Option to record a collection instead if balance is short.

**States:** insufficient balance, out of stock, offline queued, conflict on
sync (re-check balance).

---

## 19. Collector — Success `/collector/success`

**Purpose:** confirm the outcome and get back to work.

**Content**
- Big check animation, action summary (earned/redeemed points).
- New balance.
- Auto-return to home after 5 s, or "Scan next".
- "View receipt" (P1) showing line items.

---

## 20. Collector — History `/collector/history`

**Purpose:** review today's work and correct mistakes.

**Content**
- Today's totals.
- Transaction list (time, beneficiary, type, points, sync state).
- Tap → detail with lines and collector.
- "Request void" with reason (P1); shows pending/approved/rejected.
- Date picker to view previous days.

---

## 21. Cross-cutting UI states

Every list screen must implement: loading, empty, error + retry, offline, and
permission denied. Every destructive/irreversible action needs a confirmation
with the reason stated. Every number that changes (points, stock, balance) must
show a success confirmation and reconcile on next refresh.

---

## 22. Design notes

- Admin density: comfortable table rows (56 px), sticky headers, filters in a
  single toolbar row on desktop.
- Collector: one primary action per screen, 56 px buttons, high contrast for
  outdoor use, thumb-reachable actions.
- Colour is never the only signal: pair green/amber with icons and text.
- Points always display with thousands separators and a "pts" suffix.
- IDs use a monospace/tabular font for easy reading aloud.
