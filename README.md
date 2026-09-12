# GNULTE — GNU LAN Network Testing Environment

Interactive network testing for Linux. Simulates latency, jitter, packet loss, duplication, reordering and bandwidth limits against devices on your own network so you can see how applications actually behave under pressure.

## Safety Warning

GNULTE is a network testing framework capable of ARP-based
man-in-the-middle operation, traffic manipulation, network
impairment, and packet capture.

GNULTE-SCAN provides LAN discovery and optional active reconnaissance.

Only use these tools on networks, systems, devices, and communications
that you own or are explicitly authorized to test.

Do not use GNULTE or GNULTE-SCAN to intercept, scan, manipulate,
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

> **Legal:** GNULTE performs ARP spoofing and kernel-level traffic shaping. Use
> it only on networks you own or have explicit written permission to test.

## First run

On first launch GNULTE shows the legal and safety notices and requires
acknowledgment before any network-impacting operation can run. See
[FIRST-RUN-NOTICE.md](FIRST-RUN-NOTICE.md). If safety documents are
updated, GNULTE requires acknowledgment again.

## Install

```sh
git clone https://github.com/notmicrosoft2000-cmd/gnulte.git
cd gnulte
sudo ./installer.sh
```

The installer handles dependencies (`arp-scan`, `dsniff`, `iproute2`), installs
`GNULTE` and `gnulte-scan` to `/usr/local/bin`, installs the legal/safety
documents under `/usr/local/share/doc/gnulte`, and sets up the man page.

### Update

```sh
cd gnulte
sudo ./installer.sh --update
```

### Uninstall

```sh
sudo ./uninstall.sh         # binaries + man page + docs
sudo ./uninstall.sh --purge # also remove ~/.gnulte.conf, profiles, safety record
```

## Quick start

Run as your normal user — GNULTE elevates only the privileged operations it
needs (via sudo):

```sh
GNULTE                          # interactive: scan → select → configure → run
GNULTE -t 192.168.1.20 --profile voip --duration 300
GNULTE -r 192.168.1.0/24 -w 192.168.1.1 --profile throttle --duration 600
gnulte-scan --deep              # companion scanner (active recon)
```

## First-run acknowledgment & versioned policy

GNULTE and GNULTE-SCAN share a first-run safety gate. On first use (and again
whenever the versioned safety documents change) they show:

```
LICENSE · SAFETY.md · DISCLAIMER.md · AUTHORIZED-USE.md · NETWORK-TESTING.md
```

and require each to be explicitly acknowledged before any network-impacting
operation can run. The acknowledgment record is stored as a plain data file at
`~/.config/gnulte/acceptance` (`SAFETY_POLICY_VERSION=1`). It is never `eval`'d
or `source`'d, there is no `--skip-legal` flag, and a "No" answer to any
dangerous-operation confirmation cancels that operation before anything touches
the network. The record does not claim the user "read" the documents — it only
notes they were shown and acknowledged.

## Notes

- **IPv4 only** — IPv6 hosts are neither shaped nor spoofed in this version.
- **Per-target shaping** — traffic control is applied through `tc` filters that
  match only the selected targets; other devices on the interface are untouched.
- **Clean recovery** — on exit GNULTE restores the original `net.ipv4.ip_forward`
  value and the previous root qdisc, kills only the `arpspoof` instances it
  started, and broadcasts the gateway's ARP so target caches re-converge quickly.
- **`--capture`** stores everything the target sends *unencrypted* — treat the
  resulting `.pcap` like a secret.

## Flags

| Flag | Meaning |
| --- | --- |
| `-t, --target IP` | Target device (comma-separated for multiple) |
| `-m, --mac MAC` | Target by MAC address |
| `-r, --range CIDR` | Target a whole subnet |
| `-w, --whitelist IP` | Exclude IPs from a range test |
| `-l, --latency MS` | Base delay (default 2000 ms) |
| `-j, --jitter MS` | Delay variance (default 500 ms) |
| `-p, --loss %` | Packet drop percentage |
| `-d, --duplicate %` | Duplicate packets % |
| `-e, --reorder %` | Out-of-order packets % |
| `-b, --bandwidth KBPS` | Bandwidth cap (0 = unlimited) |
| `--profile NAME` | Preset: `gaming`, `streaming`, `voip`, `web`, `extreme`, `throttle` |
| `--random` | Vary parameters during the run |
| `--duration SECS` | Auto-stop after N seconds |
| `--export CSV` | Save per-second results to CSV |
| `--capture FILE` | Capture traffic to `.pcap` |
| `--dupcheck` | Detect duplicate IPs / ARP conflicts |
| `--block` | Fully block the target: ARP-spoof its traffic here without forwarding (100% outage) |
| `--sound` | Beep per ping result — faster reply = higher pitch, no reply = low buzz |
| `--scan -t IP` | Deep port/OS scan of one IP (active recon) |
| `--quick` | Fast ARP-only scan |
| `--minimal`, `--no-banner` | Skip the branding/boot screen |
| `--settings` | Interactive theme / verbosity / log config |
| `--theme NAME` | `classic`, `hacker`, `ocean`, `sunset`, `highcontrast`, `mono`, `custom` |
| `--verbosity LVL` | `easy`, `normal`, `expert` |

## gnulte-scan

Companion scanner — no root required.

```sh
gnulte-scan                            # device table
gnulte-scan --deep                     # + ports & OS fingerprint
gnulte-scan -i wlan0 -C 192.168.0.0/24 -c > devices.csv
```

Reports IP, MAC, OUI vendor, hostname (mDNS / rDNS / NetBIOS), gateway detection,
device type and optional nmap deep scan. Export JSON, YAML or CSV.

## Dependencies

- Required: `bash`, `iproute2`, `arp-scan`, `dsniff`, `iputils`
- Optional: `nmap` (deep scans), `avahi` + `samba` (name resolution), `fping`

## State files

- `~/.config/gnulte/acceptance` — safety-policy acceptance record (data file)
- `~/.gnulte.conf` — themes, verbosity, log mode
- `~/.gnulte_profiles.conf` — saved custom profiles

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).

The GPL governs copyright, redistribution and modification — it grants no
permission to test, intercept, or disrupt any particular network. Authorized-use
and safety guidance is kept separate in [SAFETY.md](SAFETY.md),
[DISCLAIMER.md](DISCLAIMER.md), [AUTHORIZED-USE.md](AUTHORIZED-USE.md) and
[NETWORK-TESTING.md](NETWORK-TESTING.md); vulnerability reporting is governed by
[SECURITY.md](SECURITY.md).
