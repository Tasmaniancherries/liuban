# Contributing to Liuban

The repository is **proprietary** (`LICENSE`). Contributing implies you only submit changes you have the right to share under agreements with the maintainers.

The repo includes `.editorconfig` and `.gitattributes` (text defaults to LF). Prefer `dart format` so CI stays green. VS Code users: install recommended extensions from `.vscode/extensions.json` when prompted.

Report security issues privately; see `SECURITY.md` (also linked from **New issue** via `.github/ISSUE_TEMPLATE/config.yml`). Pull requests against `main` also run GitHub **Dependency review** when Dependency graph is enabled for the repository.

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

Optional coverage (matches CI’s `flutter test --coverage`; output is gitignored under `coverage/`):

```bash
flutter test --coverage
```

Optional web compile smoke (also run in CI):

```bash
flutter build web --release
```

Optional Android debug APK smoke (also run in CI; requires a working Android SDK locally):

```bash
flutter build apk --debug
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

