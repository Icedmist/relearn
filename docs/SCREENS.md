# ReLearn — Screen Specification

Every screen below exists as a route. Live mode reads and writes Supabase; demo
mode uses the in-memory seed and never touches the network.

---

## 0. Route map

| Route | Screen | Role | File |
|---|---|---|---|
| `/login` | Login / role select | Public | `features/auth/login_screen.dart` |
| `/onboarding` | Onboarding / how-to | Public | `features/onboarding/onboarding_screen.dart` |
| `/account` | Account centre | Staff | `features/account/account_screen.dart` |
| `/admin/dashboard` | Dashboard | Admin | `features/admin/dashboard_screen.dart` |
| `/admin/schools` | Schools | Admin | `features/admin/schools_screen.dart` |
| `/admin/beneficiaries` | Beneficiaries | Admin | `features/admin/beneficiaries_screen.dart` |
| `/admin/beneficiaries/new` | Register beneficiary | Admin | `features/admin/register_beneficiary_screen.dart` |
| `/admin/beneficiaries/:id` | Beneficiary profile | Admin | `features/admin/beneficiary_profile_screen.dart` |
| `/admin/print` | Print cards | Admin | `features/admin/print_cards_screen.dart` |
| `/admin/materials` | Materials & points | Admin | `features/admin/materials_screen.dart` |
| `/admin/rewards` | Item shop | Admin | `features/admin/rewards_screen.dart` |
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
- "Sign in" primary button and forgot-password link.
- "How ReLearn works" link to `/onboarding`.
- Demo mode: prefilled demo credentials and a role selector; no production
  shortcuts.
- Version in the footer.

**States:** idle, loading, invalid credentials, server unreachable, account
deactivated, onboarding required.

**Actions:** sign in → onboarding (first run) or role home. Demo mode still uses
the in-memory store and never locks.

---

## 1a. Onboarding `/onboarding`

**Purpose:** explain the collection loop on first sign-in and from "How to use".

**Content**
- Four pages: welcome, collect, redeem, staff tools.
- Page dots, Back, Next, Skip and Get started.
- `next` query parameter decides where to continue (default `/login`).

**States:** first run, replay from Account, opened from login.

**Actions:** finish/skip marks `relearn.onboarding_seen` and navigates to `next`.

---

## 1b. Account centre `/account`

**Purpose:** let any signed-in staff member manage their own account.

**Content**
- Profile card: name, email, role, initials and edit-name action.
- Security: change password, fingerprint/face unlock toggle (Android/iOS),
  session-lock explanation and "Lock now".
- App: replay the guide, version, data-mode note.
- Sign out with confirmation.

**States:** demo mode (editing disabled, clear notice), biometrics unavailable,
biometric confirmation failed, password updated, name updated, save error.

**Actions:** update name via `update_my_name`, update password via Supabase Auth,
toggle biometrics, lock the session, sign out.

---

## 2. Admin — Dashboard `/admin/dashboard`

**Purpose:** a 30-second health check of the programme.

**Content**
- Greeting from the signed-in profile, plus the current date.
- KPI cards: active beneficiaries, kg collected this month, points awarded,
  points redeemed, rewards distributed.
- "Collections over time" chart for the last 7 days.
- "Top materials" horizontal bars.
- "Recent activity" list: beneficiary, materials/points, collector, time.
- Low-stock alert banner when any reward stock ≤ 10.

**Actions:** open reports; register a beneficiary; open a beneficiary from the
activity list; restock from the low-stock banner.

**States:** loading bar, empty programme, error banner with dismiss/retry.

**Demo:** KPIs and activity come from the in-memory seed.

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
- Primary CTA: "Register beneficiary"; print-cards shortcut.
- No bulk actions or CSV import in this build.

**Actions:** open profile; register; open the print-cards screen.

---

## 5. Admin — Register beneficiary `/admin/beneficiaries/new`

**Purpose:** create one person at a time.

**Content**
- Full name (required), type (pupil/teacher), school (required), class
  (required for pupils), guardian phone (optional).
- On save: the server generates `public_id`; a success dialog shows the QR and
  ID with "View profile" and "Register another" actions.

**States:** saving, invalid school, server error. CSV import remains on the
roadmap and is not shown in this build.

---

## 6. Admin — Beneficiary profile `/admin/beneficiaries/:id`

**Purpose:** the single view of a person.

**Content**
- Header: name, type, school, class, status, public ID.
- ID card with QR and public ID, "Print card" (single-card PDF).
- Details card and a large balance.
- Points history from the append-only ledger with type, points ±, actor and
  timestamp.
- "Block card" toggle and "Adjust points" with a mandatory reason.

**Rules:** a blocked card cannot be opened for collection or redemption; the
public ID never changes; no delete anywhere.

---

## 7. Admin — Print cards `/admin/print`

**Purpose:** produce cheap physical cards.

**Content**
- Filters: school (defaults to the first school), class (optional).
- Card previews with select-all; an empty selection means every filtered card.
- A4 preview of the first 12 filtered cards.
- Card face: ReLearn mark, school name, beneficiary name, type, class, public
  ID, 25 mm QR and "This card belongs to your school. Return it if found."
- "Export PDF" builds an eight-cards-per-A4-sheet PDF locally and opens the
  system print/save dialog via `printing`.

**States:** no beneficiaries, generating PDF, print dialog, PDF error.

**Notes:** QR encodes only the public ID; there are no crop marks; printing
happens through the operating system or browser dialog.

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

## 9. Admin — Item shop `/admin/rewards`

**Purpose:** manage the catalogue and stock as a marketplace preview.

**Content**
- Searchable, category-filtered grid with item artwork, category, description,
  points, stock, visibility and redemptions count.
- Add/edit: name, category, description, points, stock, image URL, active.
- "Restock" quick action with quantity; stock movement history (P2).
- Low-stock highlight at ≤ 10.

**Rules:** cannot redeem inactive or zero-stock rewards; stock decrements
atomically with redemption.

---

## 10. Admin — Reports `/admin/reports`

**Purpose:** review transaction-level truth on screen.

**Content**
- Tabs: Collections | Redemptions | Points ledger.
- School filter (all schools by default).
- Summary strip: rows and total points for the active tab.
- Full rows for the current filter; no pagination.
- CSV export remains on the roadmap and is not shown in this build.

---

## 11. Admin — Users `/admin/users`

**Purpose:** manage collectors and admins.

**Content**
- List: name, email, role and status.
- Create account (name, email, temporary password, role). Admins can create
  both collectors and admins; the account can sign in immediately.
- Reset password (send link), deactivate/reactivate.
- No inline role change in this build; change the profile in the database.

---

## 12. Collector — Login `/login`

Same screen as admin; collector credentials route to `/collector/home`.
The Supabase session persists until sign-out or expiry. There is no offline
login in this build.

---

## 13. Collector — Home `/collector/home`

**Purpose:** start work in one tap.

**Content**
- Greeting, school/route name.
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
- Full-screen lookup UI with a scan frame and instructions.
- Camera scanning is **not enabled in this build**; the screen says so.
- "Enter ID manually" opens a beneficiary by public ID.
- "Open a sample card" in demo mode only.

**States:** unknown ID, blocked card, inactive beneficiary.

**Rules:** the public ID is validated against the loaded beneficiary list before
navigation.

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
- Marketplace grid with category filters, item artwork, points, stock and
  "can afford" state.
- Selected-item detail panel with quantity stepper.
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
- "Request void" opens a reason dialog; void requests are not available in this
  build, so the dialog explains that an admin must adjust the balance instead.
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
