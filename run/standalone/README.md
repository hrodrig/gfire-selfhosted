# Standalone (no Docker)

← [Back to run/README](../README.md).

Run the **gfire** binary from [gfire Releases](https://github.com/hrodrig/gfire/releases) without containers.

**Preferred install order** (same family as pgwd/gghstats): packaged first, **build from source last**.

| Preference | Path |
|------------|------|
| 1 | **Homebrew** (macOS / Linuxbrew) — when the formula is published upstream |
| 2 | **`.deb` / `.rpm`** + systemd — when packages land on Releases |
| 3 | **install script** or **release tarball/zip** |
| 4 | Containers / Helm — see root [Pick a path](../../README.md#pick-a-path) |
| 5 | **Build from source** (`git clone` + `make` / `go build`) — last resort |

**Today (gfire v1.0.3):** Releases ship **archives** (`tar.gz` / `.zip`) + **GHCR** images. Homebrew / `.deb` / `.rpm` follow the product packaging roadmap — document the slots here so operators know the intended order; use archives or the install host until packages exist.

| OS | Guide |
|----|--------|
| **Linux** (packages, tarball, systemd) | **[linux/README.md](linux/README.md)** |
| **macOS** (Homebrew, tarball) | [macos/README.md](macos/README.md) |
| **Windows** (zip) | [windows/README.md](windows/README.md) |

**Production on a VPS** (Compose / Helm): prefer **`run/docker-compose/`** or Kubernetes — not bare binary alone unless you already operate Postgres/Redis yourself.

**[↑ Back to run/README](../README.md)**
