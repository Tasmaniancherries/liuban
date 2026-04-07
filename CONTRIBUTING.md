# Contributing to Liuban

## Workflow

- Create a short-lived branch from `main` for each change.
- Keep each PR focused on one topic.
- Rebase or merge `main` regularly to avoid large conflicts.

## Local Checks Before PR

Run the same checks as CI:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
flutter test
```

If you changed dependencies in `pubspec.yaml`, commit `pubspec.lock` in the same PR.

## PR Quality

- Use `.github/pull_request_template.md`.
- Describe user impact and risk.
- Add or update tests for behavior changes.
- Include screenshots for visible UI changes.

## Commit Messages

Use concise, scoped messages, for example:

- `feat: add deep-link fallback for promotion detail`
- `fix: guard context usage after async gaps`
- `ci: enforce lockfile in dependency step`

