ARG DEBIAN_VERSION=13.6

FROM docker.io/gautada/debian:13.6 as npm

ARG NODE_VERSION=24.x
# ╭――――――――――――――――――╮
# │ METADATA         │
# ╰――――――――――――――――――╯
LABEL org.opencontainers.image.title="node"
LABEL org.opencontainers.image.description="A small, opinionated Node base container."
LABEL org.opencontainers.image.url="https://hub.docker.com/r/gautada/node"
LABEL org.opencontainers.image.source="https://github.com/gautada/node"
LABEL org.opencontainers.image.license="Liscense"

# ╭――――――――――――――――――╮
# │ PACKAGES         │
# ╰――――――――――――――――――╯
RUN apt-get update \
 && apt-get upgrade --yes \
 && curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && corepack enable \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && echo "n8n@${IMAGE_VERSION}" \
 && npm install "n8n@${IMAGE_VERSION}" -g 

# ╭――――――――――――――――――――╮
# │ USER               │
# ╰――――――――――――――――――――╯
# Rename the base debian user to container based user.
# Follows the same pattern as other gautada containers.
# The user name ryan was chosen after Ryan Dahl, the creator of Node.js.
# as suggested by ChatGPT
ARG OLDUSER=debian
ARG USER=ryan
RUN /usr/sbin/usermod -l $USER $OLDUSER \
 && /usr/sbin/usermod -d /home/$USER -m $USER \
 && /usr/sbin/groupmod -n $USER $OLDUSER \
 && PASSWORD="$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 24)" \
 && printf '%s:%s\n' "$USER" "$PASSWORD" | /usr/sbin/chpasswd

# ╭――――――――――――――――――╮
# │ VERSION          │
# ╰――――――――――――――――――╯
# Overrides the base image's Debian version reporter, per debian's own
# contract: container-version should print ONLY this layer's version.
COPY usr/bin/container-version /usr/bin/container-version
RUN chmod 0755 /usr/bin/container-version

# ╭――――――――――――――――――╮
# │ HEALTH           │
# ╰――――――――――――――――――╯
# Adds two drop-ins to the base image's health.d mechanism. Both run
# standalone (no network, no runtime config), so they're valid for
# liveness, readiness, startup, and test alike.
# COPY etc/health.d/pythonversion-check /etc/health.d/pythonversion-check
# RUN chmod 0755 /etc/health.d/pythonversion-check
