#!/usr/bin/env bash
# Installs every CLI tool required by the Agent Skills in .agents/skills/,
# the Justfile recipes, and the AGENTS.md pre-commit checklist.
set -euo pipefail

# Pinned versions for tools installed from GitHub releases.
JUST_VERSION="1.58.0"
SHFMT_VERSION="3.13.1"
HADOLINT_VERSION="2.15.1"
ACTIONLINT_VERSION="1.7.12"
COSIGN_VERSION="3.1.3"

ARCH="$(dpkg --print-architecture)" # amd64 | arm64

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
trap 'echo "post-create.sh failed at line ${LINENO}" >&2' ERR

log "Installing base OS packages (apt)"
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
	bash \
	ca-certificates \
	coreutils \
	curl \
	findutils \
	gh \
	gnupg \
	iproute2 \
	jq \
	make \
	rsync \
	sed \
	shellcheck \
	skopeo \
	tar \
	unzip \
	wget \
	xdg-utils
sudo rm -rf /var/lib/apt/lists/*

log "Installing Python YAML validator dependency"
python3 -m pip install --no-cache-dir --upgrade pyyaml

log "Installing Node-based linters (markdownlint, prettier, renovate-config-validator)"
# The node feature installs npm under nvm (/usr/local/share/nvm), which is not on
# sudo's secure_path — so never call `sudo npm`. Source nvm if npm isn't on PATH,
# then install globally as the current user (the feature makes NVM_DIR writable).
if ! command -v npm >/dev/null 2>&1; then
	export NVM_DIR="${NVM_DIR:-/usr/local/share/nvm}"
	if [ -s "${NVM_DIR}/nvm.sh" ]; then
		# shellcheck disable=SC1091
		. "${NVM_DIR}/nvm.sh"
	fi
fi

if ! command -v npm >/dev/null 2>&1; then
	echo "npm not found; is the node devcontainer feature enabled?" >&2
	exit 1
fi

npm install -g --no-fund --no-audit \
	markdownlint-cli \
	prettier \
	renovate

log "Installing just ${JUST_VERSION}"
JUST_TARGET="x86_64-unknown-linux-musl"
[ "${ARCH}" = "arm64" ] && JUST_TARGET="aarch64-unknown-linux-musl"
curl -fsSL "https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-${JUST_TARGET}.tar.gz" |
	sudo tar -xz -C /usr/local/bin just

log "Installing shfmt ${SHFMT_VERSION}"
sudo curl -fsSL -o /usr/local/bin/shfmt \
	"https://github.com/mvdan/sh/releases/download/v${SHFMT_VERSION}/shfmt_v${SHFMT_VERSION}_linux_${ARCH}"
sudo chmod +x /usr/local/bin/shfmt

log "Installing hadolint ${HADOLINT_VERSION}"
# Release assets are named hadolint-linux-x86_64 / hadolint-linux-arm64.
HADOLINT_ARCH="x86_64"
[ "${ARCH}" = "arm64" ] && HADOLINT_ARCH="arm64"
sudo curl -fsSL -o /usr/local/bin/hadolint \
	"https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-linux-${HADOLINT_ARCH}"
sudo chmod +x /usr/local/bin/hadolint

log "Installing actionlint ${ACTIONLINT_VERSION}"
curl -fsSL "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_linux_${ARCH}.tar.gz" |
	sudo tar -xz -C /usr/local/bin actionlint

log "Installing cosign ${COSIGN_VERSION}"
sudo curl -fsSL -o /usr/local/bin/cosign \
	"https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-${ARCH}"
sudo chmod +x /usr/local/bin/cosign

log "Verifying toolchain"
failed=0
for tool in bash git gh jq just shellcheck shfmt hadolint \
	actionlint cosign skopeo markdownlint prettier renovate-config-validator python3 \
	curl wget rsync ss xdg-open; do
	if command -v "${tool}" >/dev/null 2>&1; then
		printf '  ok   %s\n' "${tool}"
	else
		printf '  MISS %s\n' "${tool}"
		failed=1
	fi
done

if [ "${failed}" -ne 0 ]; then
	echo "One or more tools failed to install." >&2
	exit 1
fi

log "Dev container ready. Run 'just --list' to see available recipes."
