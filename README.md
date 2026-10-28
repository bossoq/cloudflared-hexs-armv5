# cloudflared-hexs-armv5

Minimal container image of [cloudflared](https://github.com/cloudflare/cloudflared) for the
**MikroTik hEX S (2025, E60iUGS)** — SoC EN7562CT (Cortex-A53) that RouterOS runs as **ARM 32-bit**.

## Why this exists
Cloudflare publishes official `cloudflared` **binaries** for 32-bit ARM, but **no official 32-bit
container image** (only amd64/arm64). This repo wraps the official binary in a tiny image.

> ⚠️ **Must be soft-float.** The hard-float `cloudflared-linux-armhf` (GOARM7) **exits with
> SIGILL (illegal instruction)** on the hEX S. Only `cloudflared-linux-arm` (GOARM5 soft-float)
> runs. Verified 2026-10-28 on a live hEX S (RouterOS 7.25). The image is built `linux/arm/v5`.

## Image
`ghcr.io/bossoq/cloudflared-hexs-armv5:<cloudflared-tag>` and `:latest`.

## Build pipeline (self-hosted)
- **GitHub Actions** workflow `build.yml`, runs on a **self-hosted runner** labelled `hexs-build`
  (LXC CT501 on the QProxmox host), builds with buildx and pushes to GHCR.
- Triggers: `workflow_dispatch` (optional `version` input), `repository_dispatch` type
  `cloudflared-release`, and a weekly safety-net schedule.
- **n8n** (CT402) polls cloudflared releases and fires `workflow_dispatch` on a new tag — see
  `n8n/cloudflared-release-monitor.json`. Needs a GitHub PAT (fine-grained, **Actions: write** on
  this repo) stored as an n8n *Header Auth* credential (`Authorization: Bearer <PAT>`).

## Deploy on the hEX S (recovery: ssh-sp behind Cloudflare Access)
Containers need external storage + container device-mode:
```
# one-time: USB stick formatted, container package installed
/system/device-mode/update container=yes        # requires physical button press
/container/config/set registry-url=https://ghcr.io tmpdir=usb1/pull layer-dir=usb1/layers
/interface/veth/add name=veth-cf address=172.19.0.2/24 gateway=172.19.0.1
# ...bridge veth-cf, give it NAT/route out...
/container/add remote-image=ghcr.io/bossoq/cloudflared-hexs-armv5:latest \
  interface=veth-cf root-dir=usb1/cf \
  cmd="tunnel run --token <TUNNEL_TOKEN>" \
  logging=yes start-on-boot=yes
/container/start [find root-dir="usb1/cf"]
```
(Public GHCR package = no registry creds on the router. Keep it private → set
`/container/config username=... password=...`.)
