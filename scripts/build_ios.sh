#!/usr/bin/env bash
set -euo pipefail

echo "==> flutter analyze"
flutter analyze || { echo "✗ Analyze failed"; exit 1; }

echo ""
echo "==> flutter test"
flutter test || { echo "✗ Tests failed"; exit 1; }

echo ""
echo "==> flutter build ios --release"
flutter build ios --release
