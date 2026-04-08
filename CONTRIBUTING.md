# Contributing to Liuban

The repository is **proprietary** (`LICENSE`). Contributing implies you only submit changes you have the right to share under agreements with the maintainers.

Use a Flutter/Dart toolchain that satisfies `pubspec.yaml` `environment.sdk` (currently Dart **>=3.9.0**). CI pins a specific Flutter release via `env.FLUTTER_VERSION` in `.github/workflows/flutter.yml`.

The repo includes `.editorconfig` and `.gitattributes` (text defaults to LF). Prefer `dart format` so CI stays green. VS Code users: install recommended extensions from `.vscode/extensions.json` when prompted.

Report security issues privately; see `SECURITY.md` (also linked from **New issue** via `.github/ISSUE_TEMPLATE/config.yml`). Pull requests against `main` also run GitHub **Dependency review** when Dependency graph is enabled for the repository.

CI on `main` is two-stage: Dart **quality** (format / analyze / tests + coverage artifact) must pass before **Web & Android** smoke builds run, saving time when analysis or tests fail. The compile job also uploads a short-lived **debug APK** artifact for sanity checks (not for store release).

When upgrading Flutter for the whole team, bump **`env.FLUTTER_VERSION`** at the top of `.github/workflows/flutter.yml` (both jobs read it) so CI matches local toolchains.

## Workflow

- Create a short-lived branch from `main` for each change.
- Keep each PR focused on one topic.
- Rebase or merge `main` regularly to avoid large conflicts.

## Local Checks Before PR

Run the same checks as CI:

```bash
bash tool/ci_quality.sh
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

Combined smoke build command used by CI compile job:

```bash
bash tool/ci_smoke_builds.sh
```

If you changed dependencies in `pubspec.yaml`, commit `pubspec.lock` in the same PR.

Use `dart pub outdated` to see available upgrades. **`dart pub upgrade`** updates the lockfile within current constraints—commit those lockfile bumps when `dart analyze` and `flutter test` stay green. **Major** dependency moves (e.g. `go_router`) deserve their own PR with `dart pub upgrade --major-versions` (or hand-edited constraints) plus migration notes and tests.

The **`test`** dev dependency must stay compatible with the SDK-pinned `test_api` required by **`flutter_test`**; if `pub get` fails after raising `test`, follow the resolver hint (often staying on the latest `^1.30.x` line until Flutter bumps the pin).

Android: `android/gradle.properties` uses JVM heap settings that fit typical laptops and GitHub-hosted runners; if local builds are slow, you can raise `-Xmx` for your machine only (avoid committing very large values).

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

