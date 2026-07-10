#!/usr/bin/env bash
#
# Launch the TripleCheck 3D graph on Linux desktop.
#
#   ./launch.sh            build if stale, then run (debug)
#   ./launch.sh release    same, optimised build
#   ./launch.sh dev        flutter run, with hot reload
#   ./launch.sh data       regenerate assets/data/triplecheck.json from ../old
#
set -euo pipefail

cd "$(dirname "$0")"

MODE="${1:-debug}"

# Heavy Flutter/Gradle builds must serialise through the machine-wide lock,
# otherwise two concurrent builds exhaust RAM.
LOCK="$HOME/bin/android-build-locked"
if [ ! -x "$LOCK" ]; then
  LOCK=""
fi

SOURCE_DIR="${GRAPH3D_SOURCE:-../old/graph-2017-01-09}"

case "$MODE" in
  data)
    echo "==> converting $SOURCE_DIR"
    exec node tool/convert_data.js "$SOURCE_DIR" assets/data/triplecheck.json
    ;;
  dev)
    exec $LOCK flutter run -d linux
    ;;
  debug|release|profile)
    ;;
  *)
    echo "usage: $0 [debug|release|profile|dev|data]" >&2
    exit 64
    ;;
esac

BUNDLE="build/linux/x64/$MODE/bundle/graph3d"

# Rebuild when the binary is missing or any source is newer than it.
if [ ! -x "$BUNDLE" ] || [ -n "$(find lib pubspec.yaml assets -newer "$BUNDLE" 2>/dev/null)" ]; then
  echo "==> building ($MODE)"
  $LOCK flutter build linux "--$MODE"
else
  echo "==> up to date ($MODE)"
fi

echo "==> running $BUNDLE"
exec "./$BUNDLE"
