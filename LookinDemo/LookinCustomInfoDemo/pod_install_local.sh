#!/usr/bin/env bash
# Local LookinServer pod — use this instead of `pod update --repo-update` (can hang on specs).
set -euo pipefail
cd "$(dirname "$0")"
echo "LookinServer root: $(ruby -e 'puts File.expand_path("../..", Dir.pwd)')"
pod deintegrate 2>/dev/null || true
rm -rf Pods Podfile.lock
pod install
echo "OK — open LookinCustomInfoDemo.xcworkspace"
