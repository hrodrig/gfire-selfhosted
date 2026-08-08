# Contributing to gfire-selfhosted

Thank you for helping improve these deployment manifests.

## How to contribute

- **Issues:** Use [GitHub Issues](https://github.com/hrodrig/gfire-selfhosted/issues) for bugs, doc gaps, or manifest improvements (Compose, Helm).
- **Pull requests:** Open PRs against **`develop`**. Keep changes focused.
- **Application behavior** (engine, UI, BFF): contribute in **[gfire](https://github.com/hrodrig/gfire)**, **[gfireui](https://github.com/hrodrig/gfireui)**, or **[gfireui-backend](https://github.com/hrodrig/gfireui-backend)** — this repo is **infrastructure only**.

## Checks before submitting

- Paths under **`run/`** match the documented layout.
- From the clone root: **`make release-check`** (minimal Compose **`config`**; Helm checks when the chart exists).
- **English** for README and comments.
- If you bump **[`VERSION`](VERSION)**, keep the README **Version** badge and **CHANGELOG** aligned.
- **`.gitignore`** is deny-all + whitelist — new top-level paths need an explicit `!` allow rule.

## Git flow

- Day-to-day work on **`develop`**.
- **`main`** holds reviewed snapshots; annotated tags **`v<semver>`** on **`main`** for infra releases.
