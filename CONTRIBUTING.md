# Contributing to ReLearn

This project uses a lightweight **agent contributing workflow**: every change
starts as an issue, lands on a short-lived branch, passes CI, and enters `main`
through a **squash-merged pull request**. No direct pushes to `main`.

---

## 1. Before you start

```bash
git clone https://github.com/Icedmist/relearn.git
cd relearn
flutter pub get
flutter analyze
flutter test
```

Read [`docs/PRD.md`](docs/PRD.md) and [`docs/SCREENS.md`](docs/SCREENS.md) before
changing product behaviour. Data-integrity rules in
[`docs/PRD.md`](docs/PRD.md#8-business-rules-and-integrity) are non-negotiable.

---

## 2. The workflow

### Step 1 — Open or claim an issue

Every PR must close an issue. Use the templates:

- **Feature** — user story, acceptance criteria, screens affected.
- **Bug** — steps, expected, actual, device/version.
- **Task** — docs, CI, refactor.

Create one with the CLI:

```bash
gh issue create \
  --title "feat: add CSV import for beneficiaries" \
  --body "Closes the Stage 1 registration gap. Acceptance criteria: ..." \
  --label "feature,stage-1"
```

Claim it by commenting and assigning yourself:

```bash
gh issue edit 12 --add-assignee @me
```

### Step 2 — Branch from an up-to-date `main`

```bash
git switch main
git pull --ff-only
git switch -c feat/csv-import
```

Branch names:

| Prefix | Use |
|---|---|
| `feat/` | New capability |
| `fix/` | Bug fix |
| `docs/` | Documentation only |
| `chore/` | Tooling, CI, dependencies |
| `refactor/` | No behaviour change |

### Step 3 — Make the change

- Keep the change focused on the issue.
- Follow the existing structure and naming.
- Add or update tests for logic that can regress.
- Run the checks locally:

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

### Step 4 — Commit with Conventional Commits

```
<type>(<scope>): <short imperative summary>

<body — why, not what>

Closes #12
```

Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `perf`, `ci`.

Example:

```
feat(collector): add manual ID entry to the scan screen

A damaged card must never block a collection. The fallback validates the
check character before lookup.

Closes #14
```

### Step 5 — Push and open the PR

```bash
git push -u origin feat/csv-import
gh pr create \
  --base main \
  --title "feat: add CSV import for beneficiaries" \
  --body "## Summary
- Adds template download, validation preview and error report
- Rejects duplicate imports by file hash

## Screens
- /admin/beneficiaries/new

## Test plan
- [ ] flutter analyze
- [ ] flutter test
- [ ] Upload sample CSV with 2 invalid rows

Closes #12"
```

The PR template asks for summary, screens, data impact and test plan.

### Step 6 — CI must be green

`.github/workflows/ci.yml` runs:

1. `dart format --set-exit-if-changed`
2. `flutter analyze`
3. `flutter test`
4. `flutter build web --release`

A PR cannot be squash-merged with a failing check.

### Step 7 — Review, squash merge, delete branch

```bash
gh pr merge --squash --delete-branch
```

- **Squash merge only.** One clean commit per change on `main`.
- The PR title becomes the commit subject; keep it Conventional.
- Delete the branch after merge.
- Never force-push `main`.

### Step 8 — Tag releases

Tags follow SemVer (`v0.1.0`, `v0.2.0`). Annotated tags only:

```bash
git switch main
git pull --ff-only
git tag -a v0.2.0 -m "Stage 1: registration, QR cards and PDF export"
git push origin v0.2.0
```

---

## 3. Agent checklist

Copy this into the PR or use it as a self-check:

```markdown
- [ ] Issue linked (`Closes #N`)
- [ ] Branch named by type
- [ ] Conventional commit subject
- [ ] `dart format` clean
- [ ] `flutter analyze` clean
- [ ] `flutter test` green
- [ ] `flutter build web` succeeds
- [ ] Screen states covered (loading, empty, error, offline)
- [ ] No secrets, service-role keys or real child data committed
- [ ] Docs updated if behaviour changed
- [ ] PR squash-merged, branch deleted
```

---

## 4. Code conventions

### Dart / Flutter

- `flutter_lints` defaults; no `print` in shipped code.
- Prefer `const` constructors and small widgets.
- Screens do not call Supabase; use a repository or the demo store.
- Money-like values (points) are integers; quantities use `double`/`numeric`.
- All user-facing strings are centralised in the feature for later localisation.
- Use `withValues(alpha:)`, not the deprecated `withOpacity`.
- Keep the collector UI at 16 px body text and ≥ 48 dp tap targets.

### Data and security

- Never commit `.env`, service-role keys or real beneficiary data.
- Points are calculated on the server only.
- Every write carries an idempotency key.
- No `DELETE` on ledger, collections or redemptions; use void/adjust.
- RLS must be enabled on every new table.

### Commits

One logical change per commit. The PR is squashed, so the PR title matters most.

---

## 5. Reporting bugs

Use the bug template and include:

- App version (`v0.1.0`) and commit.
- Device and Android version, or browser.
- Role (admin/collector) and route.
- Steps, expected and actual.
- A screenshot or screen recording where possible.
- Whether the device was online.

Security or child-data issues: do **not** open a public issue. Email the
maintainers directly.

---

## 6. Definition of done

A change is done when:

1. The acceptance criteria in the issue are met.
2. CI is green and the PR is squash-merged.
3. Docs and the changelog are updated when behaviour changes.
4. A reviewer can reproduce the result from the PR test plan.
