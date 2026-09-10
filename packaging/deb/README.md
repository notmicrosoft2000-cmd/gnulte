# GNULTE .deb packaging

Builds a real `.deb` (architecture `all`, pure Bash) using `dpkg-deb`
directly — no debhelper/dh needed.

## On Debian / Ubuntu

```sh
sudo apt install dpkg-dev        # provides dpkg-deb
./build-deb.sh
```

Output:

```
build/gnulte_8.0-1_all.deb
```

Install it:

```sh
sudo apt install ./build/gnulte_8.0-1_all.deb
```

The package installs:

- `/usr/bin/GNULTE`
- `/usr/share/man/man1/GNULTE.1.gz`
- `/usr/share/doc/gnulte/` (`README.md`, `LICENSE`, `copyright`, `changelog.gz`)

## Build with debhelper instead (optional)

If you prefer the standard Debian source-package flow, copy `GNULTE`,
`man/GNULTE.1`, `README.md` and `LICENSE` into a source root next to this
`debian/` directory, then:

```sh
dpkg-buildpackage -us -uc
```

> Note: run this anywhere you have `dpkg-dev`; you cannot build `.deb` files on
> Arch-based systems without installing `dpkg` via pacman.