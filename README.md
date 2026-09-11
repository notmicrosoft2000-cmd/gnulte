# GNULTE — GNU LAN Network Testing Environment

Interactive network testing for Linux. Simulates latency, jitter, packet loss, duplication, reordering and bandwidth limits against devices on your own network so you can see how applications actually behave under pressure.

> **Legal:** GNULTE performs ARP spoofing and kernel-level traffic shaping. Use
> it only on networks you own or have explicit written permission to test.

## Install

```sh
git clone https://github.com/notmicrosoft2000-cmd/gnulte.git
cd gnulte
sudo ./installer.sh
```

The installer handles dependencies (`arp-scan`, `dsniff`, `iproute2`), installs
`GNULTE` and `gnulte-scan` to `/usr/local/bin`, and sets up the man page.

### Update

```sh
cd gnulte
sudo ./installer.sh --update
```

### Uninstall

```sh
sudo ./uninstall.sh         # binaries + man page
sudo ./uninstall.sh --purge # also remove ~/.gnulte.conf and ~/.gnulte_accepted
```

## Quick start

```sh
sudo GNULTE                          # interactive: scan → select → configure → run
sudo GNULTE -t 192.168.1.20 --profile voip --duration 300
sudo GNULTE -r 192.168.1.0/24 -w 192.168.1.1 --profile throttle --duration 600
```

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
| `--scan -t IP` | Deep port/OS scan of one IP |
| `--quick` | Fast ARP-only scan |
| `--stealth` | Hide GNULTE's presence on systems you own |
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

- `~/.gnulte_accepted` — disclaimer acceptance
- `~/.gnulte.conf` — themes, verbosity, log mode
- `~/.gnulte_profiles.conf` — saved custom profiles

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
