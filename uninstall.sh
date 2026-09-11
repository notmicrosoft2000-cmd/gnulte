#!/usr/bin/env bash
# uninstall.sh — GNULTE uninstaller

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
            echo "  --purge   Also remove config files (~/.gnulte.conf, ~/.gnulte_accepted)"
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
        ((removed++))
    else
        warn "Not found: $BINDIR/$f"
    fi
done

if [[ -f "$MANDIR/GNULTE.1" ]]; then
    rm -f "$MANDIR/GNULTE.1"
    ok "Removed man page"
fi

if [[ "$PURGE" == true ]]; then
    for f in ~/.gnulte.conf ~/.gnulte_accepted ~/.gnulte_profiles.conf; do
        if [[ -f "$f" ]]; then
            rm -f "$f"
            ok "Removed $f"
        fi
    done
fi

if [[ $removed -gt 0 ]]; then
    echo ""
    echo -e "${GREEN}${BOLD}GNULTE uninstalled.${NC}"
else
    echo -e "${YELLOW}GNULTE was not installed.${NC}"
fi
