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
- Shows a **live dashboard** of per-target stats during the run.
- Generates a **post-test report** (`gnulte-report-<ts>/report.txt` +
  `report.html` with SVG latency graphs) plus optional CSV export.

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
| `--log-mode MODE` | `normal`, `simple`, or `quiet` |
| `--log-file FILE` | Save a session log |
| `--force` | Skip interactive prompts (use with explicit flags) |

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

The produced `.deb` installs `/usr/bin/GNULTE`, a man page and documentation.
Architecture is `all` (pure Bash script).

## Files and state

- `~/.gnulte_accepted` — disclaimer acceptance marker
- `~/.gnulte.conf` — user configuration (edit via `GNULTE --config`)
- `~/.gnulte_profiles.conf` — custom saved profiles
- `gnulte-report-<ts>/` — post-test reports (created in the working directory)

## Dependencies

- `bash`, `iproute2` (`tc`), `procps` (`sysctl`), `iputils` (`ping`)
- `arpscan` (`arp-scan`), `dsniff` (`arpspoof`)
- Optional: `nmap` (deep scans), a terminal emulator / `tmux` (per-target
  monitor windows)

## License

GPL-3.0-or-later. See `LICENSE`.