# Windows (standalone)

← [Standalone overview](../README.md).

**Preferred order:** release **`.zip`** from [gfire Releases](https://github.com/hrodrig/gfire/releases) → build from source (last).

1. Download `gfire_*_windows_*.zip`, extract `gfire.exe`.
2. Set `GFIRE_STORAGE_*` (or a config file) and run `gfire.exe server`.
3. Postgres migrations still required for the postgres backend (same as other platforms).

**From source (last resort):** clone [gfire](https://github.com/hrodrig/gfire), checkout the release tag, `go build -o gfire.exe ./cmd/gfire`.

---

**[↑ Standalone](../README.md)**
