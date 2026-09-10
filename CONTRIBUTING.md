# Contributing to GNULTE

Thanks for your interest! GNULTE is a network testing environment and, as such,
carries real responsibility. Please keep the guidance below in mind.

## Safety and legal policy

GNULTE performs ARP spoofing and kernel-level traffic shaping. It is intended
**only** for testing networks you own or have explicit written permission to
test.

- Do not add features that circumvent the disclaimer gate, whitelist handling,
  self-IP exclusion, or cleanup logic.
- Preserve the "authorised use only" messaging and automatic safeguards in every
  new feature.
- Anything that makes mischief *easier* or *irreversible* will be rejected.

## Getting set up

```sh
git clone <your-fork-url>
cd GNULTE
```

Run and test the script as you normally would:

```sh
sudo ./GNULTE --quick        # quick ARP scan of your LAN
./GNULTE --version           # non-root check
./GNULTE -h                  # help
```

## Code style

The whole app is one Bash (>= 4) script. Please match the existing style:

- 4-space indentation, functions grouped under section banners
- `set -u` is NOT used, so guard every variable expansion (use `${VAR:-default}`)
- Never use `local` outside function scope
- Keep interactive prompts, `log_*` helpers, and ANSI color variables for output
- No external dependencies beyond the standard tools already listed in
  `README.md` / the packages (`tc`, `arpspoof`, `arp-scan`, `ping`, `nmap`)

## Verifying your changes

```sh
bash -n GNULTE                      # syntax check
shellcheck -S warning GNULTE        # static analysis (installed on most distros)
```

Also re-run the packaged builds to make sure nothing broke:

```sh
./packaging/deb/build-deb.sh        # on Debian/Ubuntu
cd packaging/aur && makepkg -f      # on Arch/CachyOS
```

## Pull requests

1. Create a branch with a descriptive name (`fix/dashboard-kind`, `feat/foo`).
2. Keep changes small and focused; one feature/fix per PR.
3. Explain what you changed and how you tested it in the PR description.
4. If it changes user-visible behaviour, update `README.md` and the package
   metadata too.

## Performance / correctness notes

- The monitor samples every target once per second; batch network work per tick.
- New `tc` configurations must be chained (htb → netem), never replace an
  existing root qdisc.
- Any new time/measurement handling must stay POSIX-portable arithmetic-safe.