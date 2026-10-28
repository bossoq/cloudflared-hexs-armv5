# cloudflared for MikroTik hEX S (RouterOS ARM 32-bit, EN7562CT / Cortex-A53).
# MUST use the soft-float binary `cloudflared-linux-arm` (GOARM5): the hard-float
# `armhf` (GOARM7) build exits with SIGILL (illegal instruction) on this device.
# Verified 2026-10-28 on a live hEX S (RouterOS 7.25): `cloudflared version` -> exit 0.
#
# Cross-builds on amd64 with ZERO qemu: the fetch stage is pinned to $BUILDPLATFORM
# and the final `scratch` stage contains no RUN.
ARG CF_VERSION=latest
ARG CF_ASSET=cloudflared-linux-arm
FROM --platform=$BUILDPLATFORM debian:bookworm-slim AS build
ARG CF_VERSION
ARG CF_ASSET
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl \
 && if [ "$CF_VERSION" = "latest" ]; then \
      CF_VERSION="$(curl -fsSL https://api.github.com/repos/cloudflare/cloudflared/releases/latest | grep -oP '\"tag_name\":\s*\"\K[^\"]+')"; \
    fi \
 && echo "Fetching cloudflared ${CF_VERSION} (${CF_ASSET})" \
 && curl -fsSL -o /cloudflared \
      "https://github.com/cloudflare/cloudflared/releases/download/${CF_VERSION}/${CF_ASSET}" \
 && chmod +x /cloudflared \
 && rm -rf /var/lib/apt/lists/*

FROM scratch
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /cloudflared /cloudflared
ENTRYPOINT ["/cloudflared","--no-autoupdate"]
