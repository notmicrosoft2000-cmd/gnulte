# GNULTE — GNU LAN Network Testing Environment

A suite of focused Linux tools — written in Go — for measuring how devices
behave under real latency, jitter, packet loss and bandwidth limits on your own
LAN. Scan the network, shape a target, watch the results live, then clean up.

| Binary | Root | What it does |
| --- | --- | --- |
| `gnulte` | **yes** | Interactive traffic shaping engine (ARP spoof → `tc netem` → live dashboard → HTML report) |
| `gnulte-scan` | no | Parallel subnet scanner + in-Go deep port scanner, OUI vendor, mDNS/NetBIOS names, device types, OS fingerprinting, colour-coded tables + interactive `-T` browser |
| `gnulte-devices` | no | Instant ARP/neighbour inventory — vendors, mDNS hostnames, type guesses, HTML reports |
| `gnulte-traffic` | no | Lightweight per-second latency / jitter / loss monitor against one or several hosts |
| `gnulte-wifi` | **yes** | Targeted 802.11 deauthentication for authorized Wi-Fi disassociation testing |

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

gnulte-scan --deep                                     # parallel sweep + in-Go port scan + OS fingerprint
gnulte-scan -T                                         # interactive full-screen device browser
gnulte-devices -s                                      # ARP inventory + optional live sweep
gnulte-traffic -t 192.168.1.20 -duration 60            # watch one host's latency
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

No root needed — parallel sweep + in-Go deep port scanner.

```sh
gnulte-scan                                    # device table
gnulte-scan --deep                             # + ports & service banners
gnulte-scan -i wlan0 -C 192.168.0.0/24 -j > devices.json
```

Reports IP, MAC, OUI vendor (embedded registry), mDNS `.local` / reverse-DNS
hostname, gateway detection, device type, and optional in-Go port scan with
banners. Export JSON, YAML, CSV, or an HTML report.

## gnulte-devices

Instant ARP/neighbour inventory — no sweep needed, runs as a normal user.

```sh
gnulte-devices                # every neighbour already known to the OS
gnulte-devices -s             # also sweep the subnet in parallel
gnulte-devices -H dev.html    # HTML report
```

Vendor, mDNS hostname, type guess, table / JSON / YAML / CSV / HTML export.

## gnulte-traffic

Lightweight latency / jitter / loss monitor — no shaping, no root.

```sh
gnulte-traffic -t 192.168.1.20
gnulte-traffic -t 10.0.0.5,10.0.0.6 -duration 120
```

## gnulte-wifi

Targeted 802.11 deauthentication. Needs an interface in monitor mode and root.

```sh
sudo gnulte-wifi -i wlan0mon -a 00:11:22:33:44:55 -s AA:BB:CC:DD:EE:FF
```

## Dependencies

### gnulte (shaping engine, root)
Required: `iproute2` (`tc`), `arp-scan` or `dsniff` (`arpspoof`), `iputils`

### gnulte-scan / gnulte-devices / gnulte-traffic
None beyond the Go toolchain (everything is in-Go). `arp-scan` is used
opportunistically as root for faster device discovery but is not required.

### gnulte-wifi (802.11 injection)
Root + a wireless adapter in monitor mode (`iw dev set type monitor` or
`airmon-ng`). Some chipsets inject faster than others.

## State files

All state lives under `~/.config/gnulte-go/`:

| File | Contents |
| --- | --- |
| `acceptance.json` | Versioned safety-policy acknowledgment record |
| `settings.json` | Theme, verbosity, console log mode, saved scan defaults |
| `profiles.json` | User-created `--save-profile` combinations |

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).

The GPL governs copyright, redistribution and modification — it grants no
permission to test, intercept, or disrupt any particular network. Authorized-use
and safety guidance is kept separate in [SAFETY.md](SAFETY.md),
[DISCLAIMER.md](DISCLAIMER.md), [AUTHORIZED-USE.md](AUTHORIZED-USE.md) and
[NETWORK-TESTING.md](NETWORK-TESTING.md); vulnerability reporting is governed by
[SECURITY.md](SECURITY.md).
