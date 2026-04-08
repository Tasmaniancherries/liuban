#!/usr/bin/env bash
set -euo pipefail

flutter pub get --enforce-lockfile
flutter build web --release
flutter build apk --debug
