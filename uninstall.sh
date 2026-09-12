#!/usr/bin/env bash
# uninstall.sh - GNULTE uninstaller
# Copyright (C) 2026 GNULTE contributors
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}[*]${NC} $1"; }
ok()    { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }

PREFIX="${PREFIX:-/usr/local}"
BINDIR="${PREFIX}/bin"
MANDIR="${PREFIX}/share/man/man1"
PURGE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --purge) PURGE=true; shift ;;
        --prefix) PREFIX="$2"; BINDIR="${PREFIX}/bin"; MANDIR="${PREFIX}/share/man/man1"; shift 2 ;;
        --help)
            echo "Usage: sudo ./uninstall.sh [--purge]"
            echo "  --purge   Also remove config, acceptance and profile files"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

[[ $EUID -eq 0 ]] || { echo -e "${RED}[x]${NC} Run as root: sudo ./uninstall.sh"; exit 1; }

removed=0

for f in GNULTE gnulte-scan; do
    if [[ -f "$BINDIR/$f" ]]; then
        rm -f "$BINDIR/$f"
        ok "Removed $BINDIR/$f"
        removed=$((removed + 1))
    else
        warn "Not found: $BINDIR/$f"
    fi
done

if [[ -f "$MANDIR/GNULTE.1" ]]; then
    rm -f "$MANDIR/GNULTE.1"
    ok "Removed man page"
fi

if [[ -d "$PREFIX/share/doc/gnulte" ]]; then
    rm -rf "$PREFIX/share/doc/gnulte"
    ok "Removed documentation ($PREFIX/share/doc/gnulte)"
fi

if [[ "$PURGE" == true ]]; then
    for f in ~/.gnulte.conf ~/.gnulte_accepted ~/.gnulte_profiles.conf; do
        if [[ -f "$f" ]]; then
            rm -f "$f"
            ok "Removed $f"
        fi
    done
    ACCDIR="${XDG_CONFIG_HOME:-$HOME/.config}/gnulte"
    if [[ -d "$ACCDIR" ]]; then
        rm -rf "$ACCDIR"
        ok "Removed safety acceptance record ($ACCDIR)"
    fi
fi

if [[ $removed -gt 0 ]]; then
    echo ""
    echo -e "${GREEN}${BOLD}GNULTE uninstalled.${NC}"
else
    echo -e "${YELLOW}GNULTE was not installed.${NC}"
fi
