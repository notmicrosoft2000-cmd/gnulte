#!/usr/bin/env bash
# Build a .deb for GNULTE using dpkg-deb (no debhelper required).
# Run from anywhere; paths are resolved relative to this script.
# Works on Debian, Ubuntu and derivatives.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
VER="8.0"
REL="1"
PKG="gnulte"
DEST="$HERE/build/${PKG}_${VER}-${REL}_all"

echo "==> Assembling package root: $DEST"
rm -rf "$HERE/build"
mkdir -p "$DEST/DEBIAN" \
         "$DEST/usr/bin" \
         "$DEST/usr/share/man/man1" \
         "$DEST/usr/share/doc/$PKG"

echo "==> Installing files"
copy_quiet() { cp -f "$1" "$2"; }
copy_quiet "$ROOT/GNULTE"                      "$DEST/usr/bin/GNULTE"
copy_quiet "$ROOT/man/GNULTE.1"                "$DEST/usr/share/man/man1/GNULTE.1"
copy_quiet "$ROOT/README.md"                   "$DEST/usr/share/doc/$PKG/README.md"
copy_quiet "$ROOT/LICENSE"                     "$DEST/usr/share/doc/$PKG/LICENSE"
copy_quiet "$HERE/debian/changelog"            "$DEST/usr/share/doc/$PKG/changelog"
copy_quiet "$HERE/debian/control"              "$DEST/DEBIAN/control"
copy_quiet "$HERE/debian/copyright"            "$DEST/usr/share/doc/$PKG/copyright"

echo "==> Compressing man page and changelog"
gzip -n -9 -c "$DEST/usr/share/man/man1/GNULTE.1"  > "$DEST/usr/share/man/man1/GNULTE.1.gz"
gzip -n -9 -c "$DEST/usr/share/doc/$PKG/changelog" > "$DEST/usr/share/doc/$PKG/changelog.gz"
rm -f "$DEST/usr/share/man/man1/GNULTE.1" "$DEST/usr/share/doc/$PKG/changelog"

chmod 755 "$DEST/usr/bin/GNULTE"

echo "==> Building .deb"
dpkg-deb --build --root-owner-group "$DEST" "$HERE/build/${PKG}_${VER}-${REL}_all.deb"
rm -rf "$DEST"

echo "==> Done: ${HERE}/build/${PKG}_${VER}-${REL}_all.deb"
echo "    Install with: sudo apt install ./build/${PKG}_${VER}-${REL}_all.deb"