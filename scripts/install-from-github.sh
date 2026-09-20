#!/usr/bin/env bash
# Download and install the latest Drive Cards release from GitHub.
# Usage: bash install-from-github.sh
#
# Inspect this script before running:
#   curl -LO https://raw.githubusercontent.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/main/scripts/install-from-github.sh
#   less install-from-github.sh
#   bash install-from-github.sh
set -euo pipefail

REPO="aliksandrkarankevich-sudo/AI-PlasmaDriveCard"
TOOL="kpackagetool6"
TYPE="Plasma/Applet"
ID="io.github.cachyos.drivecard"
API="https://api.github.com/repos/${REPO}/releases/latest"

if ! command -v "${TOOL}" &>/dev/null; then
    echo "Error: ${TOOL} not found. Install plasma-framework or plasma6-sdk."
    exit 1
fi
if ! command -v curl &>/dev/null; then
    echo "Error: curl not found."
    exit 1
fi

echo "Fetching release info from GitHub..."
RELEASE_JSON="$(curl -fsSL "${API}")"
TAG="$(echo "${RELEASE_JSON}" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')"
if [[ -z "${TAG}" ]]; then
    echo "Error: could not determine latest release tag."
    exit 1
fi
echo "Latest release: ${TAG}"

# Find the .plasmoid asset URL
ASSET_URL="$(echo "${RELEASE_JSON}" | grep 'browser_download_url' | grep '\.plasmoid"' | head -1 | sed 's/.*"browser_download_url": *"\([^"]*\)".*/\1/')"
if [[ -z "${ASSET_URL}" ]]; then
    echo "Error: no .plasmoid file found in release ${TAG}."
    exit 1
fi
FILE="$(basename "${ASSET_URL}")"

# Optional SHA256 verification
SHA_URL="$(echo "${RELEASE_JSON}" | grep 'browser_download_url' | grep 'SHA256SUMS"' | head -1 | sed 's/.*"browser_download_url": *"\([^"]*\)".*/\1/')"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "${TMPDIR}"' EXIT

echo "Downloading ${FILE}..."
curl -fsSL -o "${TMPDIR}/${FILE}" "${ASSET_URL}"

if [[ -n "${SHA_URL}" ]] && command -v sha256sum &>/dev/null; then
    echo "Verifying checksum..."
    curl -fsSL -o "${TMPDIR}/SHA256SUMS" "${SHA_URL}"
    (cd "${TMPDIR}" && grep "${FILE}" SHA256SUMS | sha256sum --check --status)
    echo "Checksum OK."
else
    echo "Skipping checksum verification."
fi

if "${TOOL}" --type "${TYPE}" --show "${ID}" &>/dev/null; then
    echo "Upgrading existing installation to ${TAG}..."
    "${TOOL}" --type "${TYPE}" --upgrade "${TMPDIR}/${FILE}"
else
    echo "Installing Drive Cards ${TAG}..."
    "${TOOL}" --type "${TYPE}" --install "${TMPDIR}/${FILE}"
fi

echo ""
echo "Drive Cards ${TAG} installed successfully."
echo "Add or re-add the widget from the Plasma widget browser."
echo "To restart Plasma shell:"
echo "  kquitapp6 plasmashell && kstart plasmashell"
