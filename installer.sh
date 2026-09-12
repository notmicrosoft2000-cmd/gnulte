#!/usr/bin/env bash
# installer.sh - GNULTE installer
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
# Detects package manager, installs dependencies, binaries and man page.
# Re-run to check for updates and reinstall.

set -euo pipefail

VERSION="8.2"
REPO="https://github.com/notmicrosoft2000-cmd/gnulte.git"
PREFIX="${PREFIX:-/usr/local}"
BINDIR="${PREFIX}/bin"
MANDIR="${PREFIX}/share/man/man1"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}[*]${NC} $1"; }
ok()    { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
err()   { echo -e "${RED}[x]${NC} $1"; exit 1; }

usage() {
    cat <<EOF
GNULTE Installer v${VERSION}

Usage: sudo ./installer.sh [OPTIONS]

Options:
  --update        Check for updates and reinstall if newer
  --no-deps       Skip dependency installation
  --prefix DIR    Install prefix (default: /usr/local)
  --yes           Skip confirmation prompts
  --help          Show this help

EOF
    exit 0
}

UPDATE_ONLY=false
SKIP_DEPS=false
YES=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --update)    UPDATE_ONLY=true; shift ;;
        --no-deps)   SKIP_DEPS=true; shift ;;
        --prefix)    PREFIX="$2"; BINDIR="${PREFIX}/bin"; MANDIR="${PREFIX}/share/man/man1"; shift 2 ;;
        --yes)       YES=true; shift ;;
        --help)      usage ;;
        *)           err "Unknown option: $1" ;;
    esac
done

# --- checks ---

[[ $EUID -eq 0 ]] || err "Run as root: sudo ./installer.sh"
[[ -d "$SRC_DIR/.git" ]] || err "Not a GNULTE repository. Clone first: git clone $REPO"
[[ -f "$SRC_DIR/GNULTE" ]] || err "GNULTE script not found in $SRC_DIR"
[[ -f "$SRC_DIR/gnulte-scan" ]] || err "gnulte-scan not found in $SRC_DIR"

# --- detect package manager ---

detect_pkg() {
    if command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    else
        echo "unknown"
    fi
}

PKG=$(detect_pkg)

# --- install dependencies ---

install_deps() {
    info "Installing dependencies..."
    case "$PKG" in
        pacman)
            pacman -S --needed --noconfirm arp-scan dsniff iproute2 2>/dev/null || \
                pacman -S --needed arp-scan dsniff iproute2
            ;;
        apt)
            apt-get update -qq
            apt-get install -y arp-scan dsniff iproute2
            ;;
        dnf)
            dnf install -y arp-scan dsniff iproute
            ;;
        *)
            warn "Unknown package manager. Install manually: arp-scan, dsniff, iproute2"
            return 1
            ;;
    esac
    ok "Dependencies installed."
}

if [[ "$SKIP_DEPS" == false ]]; then
    install_deps
fi

# --- check for updates ---

info "Checking for updates..."
cd "$SRC_DIR"
git fetch --quiet 2>/dev/null || { warn "Could not reach remote. Continuing with local version."; }

BRANCH=$(git symbolic-ref --short -q HEAD 2>/dev/null || echo "")
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "$LOCAL")

if [[ "$LOCAL" != "$REMOTE" ]]; then
    AHEAD=$(git rev-list HEAD..@{u} --count 2>/dev/null || echo "?")
    warn "Update available: ${AHEAD} new commit(s) on remote."
    if [[ "$UPDATE_ONLY" == false ]]; then
        if [[ "$YES" == false ]]; then
            read -rp "Pull update now? [Y/n] " ans
            ans=${ans:-Y}
        else
            ans="Y"
        fi
        if [[ "${ans^^}" == "Y" ]]; then
            warn "SECURITY: answering Y pulls and executes REMOTE CODE AS ROOT."
            warn "         Only do this after reviewing the changes (git log origin/${BRANCH:-HEAD}..HEAD)."
            git pull --ff-only || err "Pull failed. Resolve manually."
            ok "Updated to latest."
        fi
    fi
else
    ok "Already up to date."
fi

if [[ "$UPDATE_ONLY" == true ]]; then
    ok "Update check complete."
    exit 0
fi

# --- install binaries ---

info "Installing to ${BINDIR}..."
mkdir -p "$BINDIR"
install -m755 "$SRC_DIR/GNULTE" "$BINDIR/GNULTE"
install -m755 "$SRC_DIR/gnulte-scan" "$BINDIR/gnulte-scan"

# Verify what we just installed before calling it done
if ! bash -n "$SRC_DIR/GNULTE" || ! bash -n "$SRC_DIR/gnulte-scan"; then
    err "Syntax check of installed scripts FAILED — not installing. Fix the repository first."
fi
if ! grep -q "Version 8.2" "$SRC_DIR/GNULTE"; then
    err "Installed GNULTE does not look like v8.2 (version marker missing). Aborting."
fi
ok "GNULTE and gnulte-scan installed."

# --- install man page ---

if [[ -f "$SRC_DIR/man/GNULTE.1" ]]; then
    mkdir -p "$MANDIR"
    install -m644 "$SRC_DIR/man/GNULTE.1" "$MANDIR/GNULTE.1"
    ok "Man page installed."
fi

# --- install legal / safety documents ---

DOCDIR="$PREFIX/share/doc/gnulte"
mkdir -p "$DOCDIR"
for doc in LICENSE README.md SAFETY.md DISCLAIMER.md AUTHORIZED-USE.md SECURITY.md \
           NETWORK-TESTING.md FIRST-RUN-NOTICE.md CONTRIBUTING.md; do
    if [[ -f "$SRC_DIR/$doc" ]]; then
        install -m644 "$SRC_DIR/$doc" "$DOCDIR/$doc"
    fi
done
ok "Legal/safety documentation installed to $DOCDIR."

# --- done ---

echo ""
echo -e "${GREEN}${BOLD}GNULTE v${VERSION} installed successfully.${NC}"
echo -e "  Binary:  ${BINDIR}/GNULTE"
echo -e "  Scanner: ${BINDIR}/gnulte-scan"
echo -e "  Man:     ${MANDIR}/GNULTE.1"
echo -e "  Docs:    ${DOCDIR}/"
echo ""
echo -e "Run ${CYAN}GNULTE${NC} (your normal user; it elevates via sudo as needed)."
echo -e "Run ${CYAN}sudo ./installer.sh --update${NC} to check for updates."
echo ""
echo -e "${YELLOW}${BOLD}Note:${NC} on first launch GNULTE shows the safety documents and requires"
echo -e "acknowledgment before any network-impacting operation can run."
