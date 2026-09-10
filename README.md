# GNULTE — GNU LAN Network Testing Environment

GNULTE is an interactive terminal tool for **authorised network testing** on
networks you own or have explicit written permission to test. It simulates
real-world network degradation (latency, jitter, packet loss, duplication,
reordering, bandwidth throttling) against target devices so you can observe how
applications and devices behave under poor network conditions.

> **LEGAL NOTICE:** GNULTE performs ARP spoofing to route traffic through your
> machine (`arpspoof`) and kernel-level traffic shaping (`tc`). Using it against
> networks or devices you do not own, or without authorisation, is illegal in
> most jurisdictions. The in-app disclaimer must be accepted before any test
> runs. You are solely responsible for your use.

---

## What it does

- Scans your LAN (`arp-scan`) and identifies devices by vendor, hostname, open
  ports and type (phone, TV, router, IoT, …).
- Lets you target a single device, several devices, a whole subnet
  (`-r 192.168.1.0/24`), or an IP resolved from a MAC.
- Applies traffic control on your router-facing interface with `tc netem`:
  latency, jitter, loss, duplication, reordering, and bandwidth limits.
- Runs interactive parameter prompting with built-in expected impact estimation
  (`estimate_impact`) and **sanity validation** so you cannot accidentally type
  nonsensical values.
- Shows a **live dashboard** of per-target stats during the run (it pings each
  target once per second and renders last/min/max/avg/loss live).
- **Self-healing**: spoof processes are watched and auto-restarted if they die,
  targets are verified reachable before the run, and every long operation has a
  loading bar.
- Generates a **post-test report** (`gnulte-report-<ts>/report.txt` +
  `report.html` with SVG latency graphs) plus optional CSV export.

## `gnulte-scan` — LAN device discovery companion

`GNULTE` needs root (ARP spoofing + `tc`), but discovering and fingerprinting
your network does not. The companion tool **`gnulte-scan`** finds every active
device and extracts the maximum possible detail about each one — no root needed
when the arp-scan OUI database is present:

- **IP, MAC, OUI vendor, device type** (routers, phones, TVs, printers, cameras,
  IoT, PCs, …) — vendor from `arp-scan` (if run as root) or from the OUI
  database file shipped with `arp-scan`, read directly without root.
- **Device name** from up to five sources, in priority order: **mDNS/Bonjour**
  (`avahi-resolve-address`), reverse DNS (`getent`/`dig`/`host`/`nslookup`) and
  **NetBIOS** (`nmblookup`). Device names on home LANs are usually descriptive
  (`MiBox4`, `tapo-camera`, `DESKTOP-ABC123`), which drives accurate type
  detection.
- **Gateway/router detection** by matching the gateway's IP *and* MAC, so the
  router is always tagged `Router (Gateway)` — even when every OS sleeps.
- Optional **`--deep`** nmap pass (open ports + OS fingerprint).
- Export: **JSON / YAML / CSV**.

```sh
gnulte-scan                     # table
gnulte-scan --deep              # + ports & OS (slower)
gnulte-scan -j > devices.json   # JSON export
gnulte-scan -i wlan0 -C 192.168.0.0/24 -c   # custom iface+subnet, CSV
```

For best name resolution install the optional tools:
`avahi` (mDNS), `samba`/`samba-utils` (NetBIOS), `fping` (faster sweeps) and
`nmap` (`--deep`). The AUR/`.deb` packages install `gnulte-scan` to
`/usr/bin/gnulte-scan` alongside `GNULTE`.

## Install from this repo

The single-file script requires only a standard Bash. Install the binary into
your `PATH`:

```sh
sudo install -m755 GNULTE /usr/local/bin/GNULTE
```

Or use the packaged versions in `packaging/` (see below).

## Quick use

```sh
sudo GNULTE                     # interactive: scan → select → configure → run
sudo GNULTE --quick             # fast ARP-only scan
sudo GNULTE --scan -t 192.168.1.20   # deep port/OS scan of one IP
```

### Command-line options

| Flag | Meaning |
| --- | --- |
| `-t, --target IP` | Target IP (comma-separated for multiple) |
| `-m, --mac MAC` | Target by MAC address |
| `-r, --range CIDR` | Target a whole subnet (e.g. `192.168.1.0/24`) |
| `-w, --whitelist IP` | Exclude IPs from a range test |
| `-l, --latency MS` | Base delay (default 2000 ms) |
| `-j, --jitter MS` | Random variance (default 500 ms) |
| `-p, --loss %` | Packet drop percentage |
| `-d, --duplicate %` | Duplicate packets % |
| `-e, --reorder %` | Out-of-order packets % |
| `-b, --bandwidth KBPS` | Bandwidth cap (0 = unlimited) |
| `--profile NAME` | Presets: `gaming`, `streaming`, `voip`, `web`, `extreme`, `throttle` |
| `--random` | Vary parameters randomly during the run |
| `--duration SECONDS` | Auto-stop after N seconds |
| `--export CSV` | Save per-second results to CSV |
| `--capture FILE` | Capture the target's traffic with `tcpdump` to a `.pcap` while the
  test runs, so you can inspect what the apps actually experience |
| `--dupcheck` | Detect duplicate IPs / ARP conflicts on your LAN |
| `--log-mode MODE` | `normal`, `simple`, or `quiet` |
| `--verbosity LEVEL` | `easy` (plain language) · `normal` · `expert` (raw commands + confirm each step) |
| `--theme NAME` | Colour theme: `classic` · `hacker` · `ocean` · `sunset` · `highcontrast` · `mono` · `custom` |
| `--settings` | Interactive settings app: theme preview, verbosity, log mode |
| `--log-file FILE` | Save a session log |
| `--force` | Skip interactive prompts (use with explicit flags) |
| `--stealth` | Disguised `arpspoof` binary name, generic monitor-window titles, and no
  branding screen — for low-visibility use on networks you own |

### Example test scenarios

- **Video call robustness** on a phone you own:
  `sudo GNULTE -t 192.168.1.20 --profile voip --duration 300`
- **Gaming lag simulation**: `sudo GNULTE -t 192.168.1.20 --profile gaming`
- **Whole-LAN soak test**, excluding yourself and a printer:
  `sudo GNULTE -r 192.168.1.0/24 -w 192.168.1.1 -w 192.168.1.60 --profile throttle --duration 600`
- **Random chaos demo** on your own test device:
  `sudo GNULTE -t 192.168.1.20 --latency 1500 --jitter 800 --loss 5 --random`
- **Verifying a firewall/NMS alerting**: run a controlled backoff until your AP
  alerts, with a CSV export:
  `sudo GNULTE -t 192.168.1.20 -l 200 -j 300 -b 512 --export results.csv`

## How it works (the safe parts)

1. Asks you to accept the **disclaimer** (persisted in `~/.gnulte_accepted`).
2. Detects your interface, gateway and IP.
3. Scans and lets you choose targets. If you use `--range`, your own IP and any
   `--whitelist` IPs are excluded automatically.
4. Enables IP forwarding, runs `arpspoof` (target ⇄ gateway) so the target's
   traffic transits your machine, then applies `tc netem` on the interface.
   Bandwidth limiting is **chained under** the netem qdisc (htb → netem) so
   nothing is lost.
5. Monitors with a live dashboard, then **cleans up**: removes the qdisc, kills
   spoof processes, disables forwarding, and writes the report.

## Packaged builds

### Arch / AUR (`packaging/aur/`)

On any Arch-based distro (Arch, CachyOS, EndeavourOS, Garuda):

```sh
cd packaging/aur
makepkg -si
```

To publish it as a real AUR package, push this source tree to a public git repo
(e.g. GitHub) and update the `source=` URL in `PKGBUILD`; then submit it at
`aur.archlinux.org` following the [AUR submission rules](https://wiki.archlinux.org/title/AUR_submission_guidelines).

### Debian / Ubuntu (`packaging/deb/`)

On a Debian/Ubuntu machine (or in CI), install build tools and build:

```sh
sudo apt install build-essential debhelper
cd packaging/deb
dpkg-buildpackage -us -uc
```

The produced `.deb` installs `/usr/bin/GNULTE` and `/usr/bin/gnulte-scan`, a man
page and documentation. Architecture is `all` (pure Bash scripts).

## Files and state

- `~/.gnulte_accepted` — disclaimer acceptance marker
- `~/.gnulte.conf` — user configuration (edit via `GNULTE --config` or `GNULTE --settings`)
- `~/.gnulte_profiles.conf` — custom saved profiles
- `gnulte-report-<ts>/` — post-test reports (created in the working directory)

### Settings & themes

`GNULTE --settings` is a small interactive app to pick a **colour theme** (with a
live preview of `classic`, `hacker`, `ocean`, `sunset`, `highcontrast`, `mono`,
`custom`), the **verbosity level** (`easy` = plain-language explanations,
`normal` = current output, `expert` = raw commands shown *and* a confirmation
before each spoof/shaping step), and the **console log mode**. Changes are saved
to `~/.gnulte.conf`. The same options are available as flags:
`--theme`, `--verbosity`, `--log-mode`.

## Dependencies

- `bash`, `iproute2` (`tc`), `procps` (`sysctl`), `iputils` (`ping`)
- `arpscan` (`arp-scan`), `dsniff` (`arpspoof`)
- Optional: `nmap` (deep scans), a terminal emulator / `tmux` (per-target
  monitor windows), `avahi` + `samba` + `fping` (best `gnulte-scan` results)

## License

GPL-3.0-or-later. See `LICENSE`.