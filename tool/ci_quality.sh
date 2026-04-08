#!/usr/bin/env bash
set -euo pipefail

flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
flutter test --coverage
