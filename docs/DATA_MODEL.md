# ReLearn — Data Model

## 1. Relationships

```
auth.users 1──1 profiles
profiles(collector) 1──* collections
schools 1──* beneficiaries
schools 1──* collections
beneficiaries 1──* collections 1──* collection_items *──1 materials
beneficiaries 1──* redemptions *──1 rewards
beneficiaries 1──* points_ledger
```

Balances are **derived**, never stored on the beneficiary:

```sql
balance = coalesce(sum(points_ledger.points), 0)
```

This makes double-spend impossible to hide and every number auditable.

---

## 2. Tables

### `schools`

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | `gen_random_uuid()` |
| name | text | required |
| address | text | |
| contact_name | text | |
| contact_phone | text | |
| active | boolean | default true; deactivate, never delete |
| created_at / updated_at | timestamptz | |

### `profiles`

Mirrors `auth.users`; created by trigger on signup.

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | FK → `auth.users.id` |
| name | text | required |
| role | `admin` \| `collector` | default `collector` |
| active | boolean | default true |
| created_at / updated_at | timestamptz | |

### `beneficiaries`

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | internal |
| public_id | text unique | printed on the card, e.g. `RL-0042-7K3Q` |
| school_id | uuid FK | required |
| full_name | text | required |
| type | `pupil` \| `teacher` | required |
| class | text | required for pupils |
| guardian_phone | text | optional |
| active | boolean | default true |
| card_blocked | boolean | default false |
| created_at / updated_at | timestamptz | |

### `materials`

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| name | text unique | e.g. "Paper and cardboard" |
| unit | `kg` \| `piece` | |
| points_per_unit | numeric(10,2) | current rate |
| allowed | boolean | server rejects `false` |
| active | boolean | hidden from pickers when false |
| image_url | text | public URL from the `item-images` bucket |

### `collections`

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| beneficiary_id | uuid FK | |
| collector_id | uuid FK → profiles | |
| school_id | uuid FK | denormalised for reporting |
| idempotency_key | text unique | client UUID |
| note | text | optional |
| voided | boolean | default false |
| voided_at | timestamptz | |
| created_at | timestamptz | |

### `collection_items`

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| collection_id | uuid FK | cascade |
| material_id | uuid FK | |
| quantity | numeric(10,3) | > 0 |
| rate_snapshot | numeric(10,2) | rate at time of collection |
| points | integer | `round(quantity × rate_snapshot)` |

### `rewards`

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| name | text unique | Pencil, Exercise book |
| points_cost | integer | > 0 |
| stock | integer | ≥ 0, decremented in the redemption transaction |
| active | boolean | |
| image_url | text | public URL from the `item-images` bucket |

### `redemptions`

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| beneficiary_id | uuid FK | |
| reward_id | uuid FK | |
| qty | integer | > 0 |
| points_spent | integer | negative ledger entry amount |
| collector_id | uuid FK | |
| idempotency_key | text unique | |
| voided | boolean | default false |
| created_at | timestamptz | |

### `points_ledger` (append-only)

| Column | Type | Notes |
|---|---|---|
| id | bigserial PK | |
| beneficiary_id | uuid FK | |
| type | `earn` \| `redeem` \| `adjust` \| `void` | |
| points | integer | + earn/adjust up, − redeem/void down; never 0 |
| ref_id | uuid | collection/redemption id |
| note | text | required for adjust/void |
| actor_id | uuid | staff member responsible |
| created_at | timestamptz | |

Update and delete are blocked by a trigger. Corrections are new rows.

### `beneficiary_balances` (view)

| Column | Type |
|---|---|
| beneficiary_id | uuid |
| balance | bigint |

---

## 3. Public ID format

`RL-0042-7K3Q`

- `RL` — programme prefix.
- `0042` — zero-padded sequence (unique, sortable).
- `7K3` — three random characters.
- `Q` — check character over the sequence + random part.
- Alphabet: `23456789ABCDEFGHJKLMNPQRSTUVWXYZ` (32 chars, no `0 O 1 I`).
- Entire ID is case-insensitive for lookup; stored upper-case.

The sequence gives a short, readable number; the random part prevents guessing
another child's card; the check character catches manual-entry typos, which
matters because collectors can type an ID when a card is damaged.

---

## 4. Points formula

```
line_points = round(quantity × rate_snapshot)
total       = Σ line_points
balance     = Σ points_ledger.points
```

- `quantity` is kg (3 decimals) or pieces (integer).
- Rounding is half away from zero (`round()` in Postgres), applied per line.
- The client preview uses the same rule; the server result is authoritative.
- A redemption posts `points = -(points_cost × qty)`.

---

## 5. Integrity rules in the database

| Rule | Enforcement |
|---|---|
| No double credit/deduct | Unique `idempotency_key` + RPC returns existing result |
| No negative balance | `pg_advisory_xact_lock(beneficiary)` + balance check in `redeem_reward` |
| No negative stock | Row lock + `stock >= qty` check + `stock >= 0` constraint |
| No rate drift | `rate_snapshot` on every collection item |
| No deletes | No delete policies; ledger mutation trigger; `voided` flags |
| No unapproved materials | RPC checks `materials.allowed` and `active` |
| No client-calculated points | RPC ignores any client-provided points |
| Role enforcement | RLS + `is_admin()` / `is_collector()` in RPCs |

---

## 6. Reporting queries

Dashboard totals read from:

- **Beneficiaries:** `count(*) from beneficiaries where active`.
- **Materials collected:** `sum(quantity)` grouped by material over non-voided collections.
- **Points awarded:** `sum(points) from points_ledger where points > 0`.
- **Points redeemed:** `abs(sum(points)) from points_ledger where type = 'redeem'`.
- **Rewards distributed:** `sum(qty) from redemptions where not voided`.

All dashboard numbers exclude `voided = true` transactions but keep the
reversing ledger entry, so the ledger sum always matches the displayed balance.

---

## 7. Migration and seed

- [`../supabase/migrations/0001_init.sql`](../supabase/migrations/0001_init.sql) —
  schema, enums, views, RLS, RPCs, triggers.
- [`../supabase/migrations/0002_staff_directory.sql`](../supabase/migrations/0002_staff_directory.sql) —
  staff directory, hardened signup, atomic restock.
- [`../supabase/migrations/0003_educational_catalogue.sql`](../supabase/migrations/0003_educational_catalogue.sql) —
  educational supplies and point costs.
- [`../supabase/migrations/0004_item_images.sql`](../supabase/migrations/0004_item_images.sql) —
  `item-images` Storage bucket, admin-only writes and `image_url` columns.
- [`../supabase/seed.sql`](../supabase/seed.sql) — starting materials, rewards and
  a demo school.

### Storage

`item-images` is a public-read bucket for catalogue photos, capped at 5 MB per
file (PNG, JPEG, WebP). Writes are limited to active admins by RLS on
`storage.objects`. Item rows store the public URL in `image_url`.

Apply locally with the Supabase CLI:

```bash
supabase start
supabase db reset        # runs migrations + seed
supabase db push         # to the linked cloud project
```
