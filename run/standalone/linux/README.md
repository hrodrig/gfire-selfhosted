# Linux (standalone binary and packages)

← [Standalone overview](../README.md) · [Repository README](../../../README.md).

Native Linux install — **not** Docker. Prefer packages over compiling.

**Application config:** [gfire example config](https://github.com/hrodrig/gfire/blob/main/gfire.example.yaml) · env overrides `GFIRE_*`.

---

## Install order on Linux

| Order | Method | Notes |
|-------|--------|--------|
| 1 | **`.deb`** (Debian / Ubuntu) | When published on [Releases](https://github.com/hrodrig/gfire/releases) |
| 2 | **`.rpm`** (Fedora / RHEL / Alma / Rocky) | Same |
| 3 | **install.sh** (get host) | See [Install script](#install-script) |
| 4 | **Tarball** from Releases | `gfire_*_linux_*.tar.gz` |
| 5 | **Build from source** | Last resort — [From source](#from-source-last-resort) |

Containers: [docker](../../docker/) / [Compose](../../docker-compose/).

---

## Debian / Ubuntu (`.deb`)

**When available** on Releases (replace version / arch):

```bash
wget -q -O /tmp/gfire.deb \
  https://github.com/hrodrig/gfire/releases/download/v1.0.0/gfire_1.0.0_linux_amd64.deb
sudo dpkg -i /tmp/gfire.deb
```

Then set storage/auth (env or `/etc` config if the package ships one) and start the service / `gfire server`.

> If the `.deb` asset is missing for a tag, use the [tarball](#tarball) or [install script](#install-script) for that release.

---

## Fedora / RHEL / AlmaLinux (`.rpm`)

**When available:**

```bash
sudo rpm -Uvh \
  https://github.com/hrodrig/gfire/releases/download/v1.0.0/gfire_1.0.0_linux_amd64.rpm
```

Same fallback as `.deb` if the asset is not on that release.

---

## Install script

Host documented by the product site (pin with `VERSION=`):

```bash
curl -fsSL https://get.gfire.hermesrodriguez.com/install.sh | sh
# Pin: VERSION=v1.0.0 curl -fsSL https://get.gfire.hermesrodriguez.com/install.sh | sh
```

Verify: `gfire version` · `curl -sS http://127.0.0.1:8080/healthz` after `gfire server` (and migrations if using Postgres).

---

## Tarball

1. Download `gfire_*_linux_*.tar.gz` from [gfire Releases](https://github.com/hrodrig/gfire/releases).
2. Extract; put `gfire` on `PATH` or under `${GFIRE_HOST_DATA}`.
3. Configure storage and run:

```bash
export GFIRE_HOST_DATA=/home/gfire/gfire-data
mkdir -p "$GFIRE_HOST_DATA"
export GFIRE_STORAGE_BACKEND=postgres
export GFIRE_STORAGE_POSTGRES_DSN='postgres://gfire:gfire@127.0.0.1:5432/gfire?sslmode=disable'
./gfire server
```

Apply Postgres migrations from the gfire tree at the same tag (engine does not auto-migrate).

---

## systemd

When `.deb`/`.rpm` ship a unit, enable it after editing the package env/config. Until then, run under your own unit or process supervisor pointing at the binary + env file under **`/etc/gfire/`** (convention) or **`${GFIRE_HOST_DATA}`**.

---

## From source (last resort)

Only if no release artifact fits your platform:

```bash
git clone https://github.com/hrodrig/gfire.git
cd gfire
git checkout v1.0.0   # or the tag you need
make build            # or: go build -o bin/gfire ./cmd/gfire
./bin/gfire server
```

Requires a Go toolchain matching upstream `go.mod`. Prefer release binaries for production.

---

**[↑ Standalone](../README.md)**
