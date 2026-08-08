# Disclaimer — use at your own risk

**Last updated:** 2026-08-07

This repository (`gfire-selfhosted`) provides **deployment manifests, scripts, and documentation only**. It is **not** a managed service, hosted product, or data-processing service operated by the maintainers on your behalf.

## Use at your own risk

By downloading, cloning, configuring, or running anything described in this repository (Compose stacks, Helm charts, install scripts, examples, or docs), you agree that you do so **entirely at your own risk**.

## Your data is your responsibility

You alone are responsible for:

- All **data** you store, process, enqueue, or transmit with GFire or related companions (jobs, payloads, databases, backups, logs, secrets, credentials, personal data, customer data, etc.)
- Choosing where data lives (including **`GFIRE_HOST_DATA`**, volumes, disks, clouds, and backups)
- Access control, encryption, retention, deletion, and compliance with laws applicable to **your** use
- Securing tokens, passwords, DSNs, and TLS for **your** deployments

**The maintainers are not responsible for your data** — including loss, corruption, unauthorized access, disclosure, ransomware, misconfiguration, or incomplete backups — whether caused by software defects, operator error, third-party infrastructure, or misuse.

## Improper / unsuitable use

You are responsible for ensuring that your use is lawful and appropriate. The maintainers are **not** liable for:

- Misuse, abuse, or illegal use of the software or these manifests
- Running workloads you do not understand or have not tested
- Exposing APIs, databases, or admin surfaces to the internet without adequate controls
- Using example / lab defaults (weak passwords, auth disabled, published ports) in production
- Running on a VPS or bare metal without hardening the host (SSH, firewall, updates, backups)
- Damage arising from following outdated, incomplete, or environment-specific guidance without your own validation

For **self-managed VPS** hardening ideas (recommendations only — you validate and apply), see the family docs at [gghstats-selfhosted `run/vps-recommended`](https://github.com/hrodrig/gghstats-selfhosted/tree/main/run/vps-recommended).

## No warranty / limitation of liability

This material is provided **“AS IS”** and **“AS AVAILABLE”**, without warranty of any kind, express or implied, including but not limited to merchantability, fitness for a particular purpose, and non-infringement — consistent with the [MIT License](./LICENSE).

**To the maximum extent permitted by applicable law**, the authors and copyright holders shall **not** be liable for any claim, damages, or other liability — whether in contract, tort, or otherwise — arising from use of this repository, the related GFire software, or inability to use them, including but not limited to loss of data, loss of profits, business interruption, or security incidents.

## Release and acknowledgment

By using this repository you acknowledge that:

1. You have read this disclaimer and the [MIT License](./LICENSE).
2. You accept **full operational and data responsibility** for your deployments.
3. You **release** the maintainers from claims related to your data, configuration choices, and use of these materials, to the extent permitted by law.

If you do not agree, **do not use** these manifests or run the software based on them.

## Security reports

Vulnerability reports for this repository: see [SECURITY.md](./SECURITY.md).  
Application issues belong in the respective product repos (`gfire`, `gfireui`, `gfireui-backend`).
