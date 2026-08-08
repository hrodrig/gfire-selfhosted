# gfire-selfhosted — band execution plan

> **For agents:** implement against [ROADMAP.md](../../../ROADMAP.md) item IDs (`GSH-*`). Design contract: [../specs/2026-08-07-gfire-selfhosted-design.md](../specs/2026-08-07-gfire-selfhosted-design.md).

**Goal:** Finish operator-ready companion (migrate + Helm + console pins) without putting secrets in git.

**Architecture:** Manifests-only repo; `GFIRE_HOST_DATA` holds live `.env` + durable volumes; products publish GHCR/Releases.

## Global constraints

- English only in repo artifacts
- Deny-all + whitelist `.gitignore`
- No commit without user-approved message
- Prefer `compose-stack.sh` + HOST_DATA over in-clone `.env`
- Chart name `gfire`, not `gfire-selfhosted`

---

## Next execution order

1. **GSH-008** — first commit when user approves message  
2. **GSH-010** — migrate helper (unblocks honest “5 min to first job”)  
3. **GSH-012** — smoke script  
4. **GSH-013** — Related tools links in product READMEs  
5. **Band 2** — Helm (GSH-020…)  
6. **Band 3** — console: [2026-08-07-gfire-selfhosted-console-stack.md](./2026-08-07-gfire-selfhosted-console-stack.md) (3 peers; needs UI images for dogfood)  
7. **Band 4** — fill brew/deb/rpm when upstream assets exist  

Do not start Band 5 Traefik/obs unless dogfood asks.
