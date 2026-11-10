<!--
Keep PRs focused and squash-merged. The PR title becomes the commit subject.
Use Conventional Commits: feat(scope): summary
-->

## Summary

What changed and why?

## Issue

Closes #

## Screens / routes

List affected screens, e.g. `/collector/record`.

## Data and security impact

- Tables / RPCs:
- RLS / permissions:
- Personal data:

## Test plan

- [ ] `dart format --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `flutter build web --release`
- [ ] Manual: describe the flow you clicked through

## Checklist

- [ ] No secrets, service-role keys or real child data
- [ ] Docs/changelog updated if behaviour changed
- [ ] Loading, empty, error and offline states considered
- [ ] Points remain server-calculated; no deletes introduced
