# macOS (standalone)

← [Standalone overview](../README.md).

**Preferred order:** Homebrew → release tarball → build from source (last).

## Homebrew

**When the formula exists** (product tap / homebrew-core style — follow [gfire README](https://github.com/hrodrig/gfire) Install section):

```bash
brew install hrodrig/gfire/gfire   # tap/name may match upstream docs when published
gfire version
```

If brew is not published yet for your tag, use the tarball below.

## Tarball

1. Download the **darwin** archive from [gfire Releases](https://github.com/hrodrig/gfire/releases) (amd64 / arm64).
2. Extract; clear quarantine if needed: `xattr -d com.apple.quarantine ./gfire`.
3. Set `GFIRE_STORAGE_*` and run `gfire server` — see [../README.md](../README.md).

## Install script

Same get-host script as Linux (if it supports your arch):

```bash
VERSION=v1.0.3 curl -fsSL https://get.gfire.hermesrodriguez.com/install.sh | sh
```

## From source (last resort)

```bash
git clone https://github.com/hrodrig/gfire.git && cd gfire
git checkout v1.0.3
make build
./bin/gfire server
```

Long-running server on a Mac host: consider Launchd, or prefer **Docker / Compose** under `run/`.

---

**[↑ Standalone](../README.md)**
