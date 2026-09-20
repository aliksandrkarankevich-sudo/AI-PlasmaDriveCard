#!/usr/bin/env bash
# Download and install the latest Drive Cards release from GitHub.
# Usage: bash install-from-github.sh [--prerelease]
set -euo pipefail

REPO="aliksandrkarankevich-sudo/AI-PlasmaDriveCard"
API="https://api.github.com/repos/${REPO}"
PRERELEASE="${1:-}"

# ── Dependency checks ────────────────────────────────────────────────
for cmd in curl sha256sum kpackagetool6; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: '$cmd' not found." >&2
        [ "$cmd" = "kpackagetool6" ] && echo "Install plasma-framework or kde-cli-tools." >&2
        exit 1
    fi
done

# ── Find release ─────────────────────────────────────────────────────
if [[ "$PRERELEASE" == "--prerelease" ]]; then
    echo "Looking for latest release (including pre-releases)…"
    RELEASE_JSON=$(curl -fsSL "${API}/releases" | python3 -c "
import json, sys
releases = json.load(sys.stdin)
if not releases: raise SystemExit('No releases found')
print(json.dumps(releases[0]))
")
else
    echo "Looking for latest stable release…"
    RELEASE_JSON=$(curl -fsSL "${API}/releases/latest")
fi

VERSION=$(echo "$RELEASE_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'])")
PLASMOID_URL=$(echo "$RELEASE_JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
assets = data.get('assets', [])
for a in assets:
    if a['name'].endswith('.plasmoid'):
        print(a['browser_download_url'])
        break
else:
    raise SystemExit('No .plasmoid file found in release assets')
")
SHA_URL=$(echo "$RELEASE_JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
assets = data.get('assets', [])
for a in assets:
    if a['name'] == 'SHA256SUMS':
        print(a['browser_download_url'])
        break
else:
    print('')
")

FILENAME=$(basename "$PLASMOID_URL")
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Found: $VERSION"
echo "Downloading $FILENAME…"
curl -fsSL -o "${TMPDIR}/${FILENAME}" "$PLASMOID_URL"

# ── Verify checksum if available ────────────────────────────────────
if [[ -n "$SHA_URL" ]]; then
    echo "Verifying checksum…"
    curl -fsSL -o "${TMPDIR}/SHA256SUMS" "$SHA_URL"
    (cd "$TMPDIR" && grep "$FILENAME" SHA256SUMS | sha256sum -c --status) || {
        echo "Error: checksum verification failed." >&2
        exit 1
    }
    echo "Checksum OK."
else
    echo "Warning: no SHA256SUMS file in this release, skipping verification."
fi

# ── Install ──────────────────────────────────────────────────────────
PKG_ID="io.github.cachyos.drivecard"
if kpackagetool6 --type Plasma/Applet --show "$PKG_ID" &>/dev/null 2>&1; then
    echo "Updating existing installation to $VERSION…"
    kpackagetool6 --type Plasma/Applet --upgrade "${TMPDIR}/${FILENAME}"
else
    echo "Installing Drive Cards $VERSION…"
    kpackagetool6 --type Plasma/Applet --install "${TMPDIR}/${FILENAME}"
fi

echo ""
echo "Drive Cards $VERSION installed successfully."
echo "Restart Plasma to use the widget:  plasmashell --replace &"
