# GNULTE — GNU LAN Network Testing Environment

A suite of focused Linux tools — written in Go — for measuring how devices
behave under real latency, jitter, packet loss and bandwidth limits on your own
LAN. Scan the network, shape a target, watch the results live, then clean up.

| Binary | Root | What it does |
| --- | --- | --- |
| `gnulte` | **yes** | Interactive traffic shaping engine (ARP spoof → `tc netem` → live dashboard → HTML report). Discreet `-S` stealth spoofing mode |
| `gnulte-lan` | optional | Live LAN watch — five-screen console: hosts, talkers (ranked with bars & peers), flows (A ⇄ B, root socket), neighbours (ARP) and screen 5's **Live Interconnection map** (devices as nodes, live flows as pulsing edges). Handoff (`⏎` → `gnulte -t <ip>`), `x` saves the watch to the shared device store |
| `gnulte-scan` | optional | Parallel subnet scanner + in-Go deep port scanner, ARP sweep when root, OUI vendor, mDNS/NetBIOS names, device types, OS fingerprinting, colour-coded tables + tabbed interactive `-T` monitor (Devices / Log / Summary) and live re-scanning with `--watch N` |
| `gnulte-devices` | no | Instant ARP/neighbour inventory — vendors, mDNS hostnames, type guesses, HTML reports |
| `gnulte-wifi` | **yes** | Targeted 802.11 deauthentication for authorized Wi-Fi disassociation testing — per-frame jitter, rotating deauth reason codes, optional channel hopping |

## Steady Hands (v16)

A stability release on top of v15's **Live Interconnection** — one shared
device store (`~/.config/gnulte-go/devices.json`) wiring the toolkit together
— with the sharp edges filed off and a few things added:

- **Ctrl+C exits cleanly instead of killing the run.** A shared signal handler
  was racing each tool's own graceful shutdown and winning with a hard
  `os.Exit(130)`, so the first Ctrl+C cut a run dead mid-teardown. It now
  restores the screen and terminal first and lets the shutdown finish, forcing
  the exit only on a *second* Ctrl+C or after a grace period. The old hard kill
  also skipped cleanup, so targets were left with a poisoned ARP cache and no
  connectivity.
- **A live watch stops when you tell it to.** Interrupting a scan mid-sweep
  took **10.9s** to respond, because the name-identification waits bounded
  themselves by a deadline but never checked for cancellation. Every wait now
  ends at once. Measured: **0.00s**.
- **Honest sampling cadence.** The gap between readings is measured from when a
  reading lands, not from when the probe started — so a target that takes two
  seconds to answer still gets its full one-second gap, instead of the next
  probe firing the instant the slow one returns.
- **gnulte-lan arrows do one thing.** Holding an arrow key no longer scoots the
  cursor dozens of rows past where you pointed it.
- **`gnulte --note TEXT`** — label a run; the note rides into the console
  header and the report.
- **`gnulte-scan --watch N --json`** — one JSON object per sweep on stdout
  (`{"kind":"baseline"}`, then `{"kind":"delta"}`), narrative to stderr, so
  `gnulte-scan --watch 5 --json | jq` is a working motion sensor.
- **Quick scan** — `r` re-scans on demand in the `-T` browser with a
  `▲ new ▼ gone ~ changed` legend; devices the store already knows are marked
  `*` in the target picker, and you can select by keyword (`Mobile`,
  `@hostname`).

## Safety Warning

GNULTE is a network testing framework capable of ARP-based
man-in-the-middle operation, traffic manipulation, network
impairment, and packet capture.

GNULTE-SCAN and GNULTE-DEVICES provide LAN discovery and active
reconnaissance. GNULTE-WIFI can disconnect Wi-Fi clients.

Only use these tools on networks, systems, devices, and communications
that you own or are explicitly authorized to test.

Do not use GNULTE or its companion tools to intercept, scan, manipulate,
capture, disrupt, or degrade third-party systems without authorization.

The authors do not grant permission to test any particular third-party
network.

Users are responsible for complying with applicable laws, regulations,
contracts, policies, and authorization requirements.

See:

```
SAFETY.md
DISCLAIMER.md
AUTHORIZED-USE.md
NETWORK-TESTING.md
```

> **License:** GPLv3-or-later (see [LICENSE](LICENSE)). The safety and
> acceptable-use policy above is **not** part of the software license —
> the GPL governs copyright/redistribution; the safety documents are
> separate guidance. The software is licensed under the GPL even though
> its misuse may be unlawful where you are not authorized to test.

> **Legal:** `gnulte` and `gnulte-wifi` perform ARP spoofing and kernel-level
> traffic shaping or 802.11 frame injection. Use them only on networks you own
> or have explicit written permission to test.

## First run

On first launch each binary shows the legal and safety notices and requires
acknowledgment before any network-impacting operation can run. See
[FIRST-RUN-NOTICE.md](FIRST-RUN-NOTICE.md). If safety documents are
updated, GNULTE requires acknowledgment again.

## Install

```sh
git clone https://github.com/notmicrosoft2000-cmd/gnulte-go.git
cd gnulte-go
sudo ./install.sh
```

The installer builds the five binaries (static, `-trimpath`) and installs them
to `/usr/local/bin`, plus safety documentation under
`/usr/local/share/doc/gnulte-go/`.

### Update

```sh
cd gnulte-go
git pull
sudo ./install.sh
```

### Uninstall

```sh
sudo ./uninstall.sh           # binaries + docs
sudo ./uninstall.sh --purge   # also remove acceptance record and config
```

## Quick start

Traffic shaping needs root (`gnulte`, `gnulte-wifi`); everything else runs as
a normal user.

```sh
sudo gnulte                                            # interactive: scan → select → configure → run
sudo gnulte -t 192.168.1.20 --profile voip --duration 300
sudo gnulte -r 192.168.1.0/24 -w 192.168.1.100 --profile throttle --duration 600
sudo gnulte -t 192.168.1.20 --profile voip --duration 300 -S   # discreet spoofing: answer only when asked

gnulte-scan --deep                                     # parallel sweep + in-Go port scan + OS fingerprint
gnulte-scan -T                                         # tabbed interactive monitor (Devices / Log / Summary)
gnulte-scan --watch 5                                  # live re-scan every 5s: ▲ new · ▼ gone · ~ changed
gnulte-devices -s                                      # ARP inventory + optional live sweep
gnulte-lan                                             # five-screen live watch (auto-discovers subnet)
gnulte-lan -t 192.168.1.20 --duration 60               # watch one host up close
```

## Flags

| Flag | Meaning |
| --- | --- |
| `-t, --target IP` | Target device (comma-separated for multiple) |
| `-m, --mac MAC` | Target by MAC address |
| `-r, --range CIDR` | Target a whole subnet |
| `-w, --whitelist IP` | Exclude IPs from a range test |
| `-l, --latency MS` | Base delay (ms) |
| `-j, --jitter MS` | Delay variance (ms) |
| `-p, --loss %` | Packet drop percentage |
| `-d, --duplicate %` | Duplicate packets % |
| `-e, --reorder %` | Out-of-order packets % |
| `-b, --bandwidth KBPS` | Bandwidth cap (0 = unlimited) |
| `--profile NAME` | Preset: `gaming`, `streaming`, `voip`, `web`, `extreme`, `throttle` |
| `--random` | Vary parameters during the run |
| `-S, --stealth` | Discreet ARP spoofing: built-in in-Go spoofer, replies only when asked, slow jittered cache refresh (defaults from settings) |
| `--duration SECS` | Auto-stop after N seconds |
| `--traffic-window` | Open the multi-target traffic monitor in a separate terminal window |
| `--export FILE` | Stream per-second results to CSV |
| `--capture FILE` | Capture traffic to `.pcap` |
| `--report FILE` | Write the post-test HTML report (full log history + SVG charts) |
| `--dupcheck` | Detect duplicate IPs / ARP conflicts |
| `--block` | Fully block the target: ARP-spoof its traffic here without forwarding (100% outage) |
| `--settings` | Open the full-screen settings editor (theme, verbosity, log mode, saved defaults) |
| `--sound` / `--no-sound` | Toggle per-ping beep (default on; pitch scales with latency) |
| `--force` | Skip interactive confirmations |
| `--no-banner`, `--minimal` | Skip the branding screen |

## gnulte-scan

Parallel sweep + in-Go deep port scanner. No root needed for pings; run it as
root and it also sweeps by ARP automatically, so hosts that block ping still
show up (`--arp` forces it, `--no-arp` disables).

```sh
gnulte-scan                                    # device table
gnulte-scan --deep                             # + ports & service banners
gnulte-scan -T                                 # tabbed monitor: Devices / Log / Summary (Tab or 1/2/3), 'o' = settings page
sudo gnulte-scan                              # ... with the automatic ARP sweep
gnulte-scan -i wlan0 -C 192.168.0.0/24 -j > devices.json
```

Reports IP, MAC, OUI vendor (embedded registry), mDNS `.local` / reverse-DNS
hostname, gateway detection, device type, and optional in-Go port scan with
banners. Export JSON, YAML, CSV, or an HTML report filed into the
`~/GNULTE Reports` hub — on the terminal it brands itself **SCANLTE**.

## gnulte-devices

Instant ARP/neighbour inventory — no sweep needed, runs as a normal user.

```sh
gnulte-devices                # every neighbour already known to the OS
gnulte-devices -s             # also sweep the subnet in parallel
gnulte-devices -H dev.html    # HTML report
```

Vendor, mDNS hostname, type guess, table / JSON / YAML / CSV / HTML export.

## gnulte-lan

Live LAN watch — passive, auto-discovers the subnet (router and self
skipped), then repaints the LAN every interval in a five-screen console:
`1` hosts (dashboard) · `2` talkers (ranked with bars & peers) · `3` flows
(A ⇄ B pairs, root socket) · `4` neighbours (live ARP) · `5` map (Live
Interconnection — devices as nodes, live flows as pulsing edges, root
socket).

```sh
gnulte-lan                            # watch the whole LAN
gnulte-lan -t 192.168.1.20            # one host, up close
sudo gnulte-lan                       # + byte-accurate talkers, flows, net rates, live map
gnulte-lan --duration 60 --export watch.csv --alarm-rate 500   # headless 60s watch
```

Every IP keeps one stable colour across screens; rows scale with terminal
width (compact, normal, or a 4-line `MORE` variant with p50/p95 at 116+
columns). `⏎`/`g` hand the selected host off to `gnulte -t <ip>` in a fresh
terminal, `Tab`/`d` open the detail pane, `x` saves the whole watch to the
shared device store, `s` re-sorts, `a` filters to alarming hosts, `o` edits
settings live, `Esc` peels screens before quitting. First-run is speeds-free:
no raw capture socket means a polite `¡ speeds-free` note and an explicit
FLOWS/MAP `⛔ needs the capture socket (root)` gate instead of guessing.

## gnulte-wifi

Targeted 802.11 deauthentication. Needs an interface in monitor mode and root.
Frames are sent with per-frame jitter (`--jitter-ms`, default 2ms) so the
timing is irregular, the deauth reason code rotates every burst
(`--mix-reasons`), and `--hop-channels` swims the adapter across your configured
channels after each burst. A second Ctrl+C force-quits during the summary.

```sh
sudo gnulte-wifi -i wlan0mon -a 00:11:22:33:44:55 -s AA:BB:CC:DD:EE:FF
sudo gnulte-wifi -i wlan0mon --channels 1,6,11 --hop-channels
```

## Dependencies

### gnulte (shaping engine, root)
Required: `iproute2` (`tc`), `arp-scan` or `dsniff` (`arpspoof`), `iputils`
Stealth mode (`-S`) drops the `arpspoof(8)` requirement — spoofing is done
in-Go over a raw socket (root / `CAP_NET_RAW`).

### gnulte-lan (live watch)
Runs fully without root (latency, identity, alarms). Root unlocks the raw
capture socket: byte-accurate talkers, per-pair flows, net rates and screen
5's live map. `tc` is shaped during a gnulte handoff, not by the watch itself.

### gnulte-scan / gnulte-devices
None beyond the Go toolchain (everything is in-Go). `arp-scan` is used
opportunistically as root for faster device discovery but is not required;
gnulte-scan's own in-Go ARP sweep takes over automatically under root.

### gnulte-wifi (802.11 injection)
Root + a wireless adapter in monitor mode (`iw dev set type monitor` or
`airmon-ng`). Some chipsets inject faster than others.

## State files

All state lives under `~/.config/gnulte-go/`:

| File | Contents |
| --- | --- |
| `acceptance.json` | Versioned safety-policy acknowledgment record |
| `config.json` | Settings TUI state: theme, verbosity, log mode, ARP sweep, stealth spoofing, Wi-Fi timing, saved scan defaults |
| `devices.json` | Shared device store — the Live Interconnection database written by `gnulte-lan`, read by `gnulte` (`w` picker) and `gnulte-scan` |
| `profiles.json` | User-created `--save-profile` combinations |

Post-test HTML reports are filed under `~/GNULTE Reports/` (a per-tool
folder per run): `GNULTE go!/gnulte-go-report-<timestamp>/` for `gnulte` and
`Gnulte-scan/` for `gnulte-scan`.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).

The GPL governs copyright, redistribution and modification — it grants no
permission to test, intercept, or disrupt any particular network. Authorized-use
and safety guidance is kept separate in [SAFETY.md](SAFETY.md),
[DISCLAIMER.md](DISCLAIMER.md), [AUTHORIZED-USE.md](AUTHORIZED-USE.md) and
[NETWORK-TESTING.md](NETWORK-TESTING.md); vulnerability reporting is governed by
[SECURITY.md](SECURITY.md).
