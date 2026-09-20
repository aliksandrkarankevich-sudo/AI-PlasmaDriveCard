#!/usr/bin/env bash
# install-from-github.sh — download and install the latest Drive Cards release
# Usage: bash install-from-github.sh [--prerelease]
set -euo pipefail

REPO="aliksandrkarankevich-sudo/AI-PlasmaDriveCard"
API="https://api.github.com/repos/${REPO}/releases"
PRERELEASE=false
[[ "${1:-}" == "--prerelease" ]] && PRERELEASE=true

if ! command -v kpackagetool6 &>/dev/null; then
    echo "ERROR: kpackagetool6 not found. Please install plasma-framework or kde-plasma-desktop."
    exit 1
fi
if ! command -v curl &>/dev/null; then
    echo "ERROR: curl not found."
    exit 1
fi

echo "Fetching release list from GitHub..."
RELEASES=$(curl -fsSL "${API}")

# Pick latest stable or, if --prerelease, the latest of any kind
if $PRERELEASE; then
    RELEASE=$(echo "${RELEASES}" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for r in data:
    print(json.dumps(r)); break
")
else
    RELEASE=$(echo "${RELEASES}" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for r in data:
    if not r.get('prerelease') and not r.get('draft'):
        print(json.dumps(r)); break
")
fi

if [[ -z "${RELEASE}" ]]; then
    echo "No suitable release found. Try --prerelease to install the latest beta."
    exit 1
fi

TAG=$(echo "${RELEASE}" | python3 -c "import sys,json; r=json.loads(sys.stdin.read()); print(r['tag_name'])")
PLASMOID_URL=$(echo "${RELEASE}" | python3 -c "
import sys, json
r = json.loads(sys.stdin.read())
for a in r.get('assets', []):
    if a['name'].endswith('.plasmoid'):
        print(a['browser_download_url']); break
")
SHA_URL=$(echo "${RELEASE}" | python3 -c "
import sys, json
r = json.loads(sys.stdin.read())
for a in r.get('assets', []):
    if a['name'] == 'SHA256SUMS':
        print(a['browser_download_url']); break
")

if [[ -z "${PLASMOID_URL}" ]]; then
    echo "ERROR: No .plasmoid asset found in release ${TAG}."
    exit 1
fi

FILE=$(basename "${PLASMOID_URL}")
TMPDIR=$(mktemp -d)
trap 'rm -rf "${TMPDIR}"' EXIT

echo "Downloading ${TAG}: ${FILE}"
curl -fsSL -o "${TMPDIR}/${FILE}" "${PLASMOID_URL}"

if [[ -n "${SHA_URL}" ]]; then
    echo "Verifying checksum..."
    curl -fsSL -o "${TMPDIR}/SHA256SUMS" "${SHA_URL}"
    (cd "${TMPDIR}" && grep "${FILE}" SHA256SUMS | sha256sum -c -)
else
    echo "WARNING: No SHA256SUMS found — skipping checksum verification."
fi

if kpackagetool6 --type Plasma/Applet --list 2>/dev/null | grep -q "io.github.cachyos.drivecard"; then
    echo "Upgrading existing installation..."
    kpackagetool6 --type Plasma/Applet --upgrade "${TMPDIR}/${FILE}"
else
    echo "Installing Drive Cards..."
    kpackagetool6 --type Plasma/Applet --install "${TMPDIR}/${FILE}"
fi

echo
echo "Done! Drive Cards ${TAG} installed."
echo "Add the widget from the desktop context menu → Add Widgets → Drive Cards."
