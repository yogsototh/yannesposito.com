#!/usr/bin/env bash
# disable-link.sh -- Disable a link in an .org file and add domain to blocklist
# Usage: disable-link.sh <file> <url> <reason> [date]
#
# Example:
#   engine/disable-link.sh src/posts/0004-how-i-internet/index.org \
#       https://laarc.io "site changed ownership" "March 2026"
set -euo pipefail

cd "$(git rev-parse --show-toplevel)" || exit 1

if [[ $# -lt 3 ]]; then
    echo "Usage: disable-link.sh <file> <url> <reason> [date]"
    echo ""
    echo "  file   - path to the .org file"
    echo "  url    - the URL to disable"
    echo "  reason - human-readable reason (will be visible to readers)"
    echo "  date   - optional, defaults to current 'Month YYYY'"
    echo ""
    echo "Example:"
    echo "  engine/disable-link.sh src/posts/0004-how-i-internet/index.org \\"
    echo "      https://example.com \"site changed ownership\""
    exit 1
fi

FILE="$1"
URL="$2"
REASON="$3"
DATE="${4:-$(date +"%B %Y")}"

if [[ ! -f "$FILE" ]]; then
    echo "Error: file not found: $FILE"
    exit 1
fi

DOMAIN=$(echo "$URL" | sed 's|https\?://||' | sed 's|/.*||' | sed 's|:.*||')
NOTE="(link removed since $DATE -- $REASON)"

# Escape URL for sed (handle special characters)
# Note: uses macOS sed -i '' syntax
ESC_URL=$(printf '%s\n' "$URL" | sed 's/[&/\\.?+*^$[\]]/\\&/g')

CHANGED=false

# Pattern 1: org-mode links [[url][display text]] -> display text (note)
if grep -q "\[\[$URL\]" "$FILE"; then
    sed -i '' "s|\[\[$ESC_URL\]\[\([^]]*\)\]\]|\1 $NOTE|g" "$FILE"
    CHANGED=true
fi

# Pattern 2: org-mode links [[url]] with no display text -> domain (note)
if grep -q "\[\[$URL\]\]" "$FILE"; then
    sed -i '' "s|\[\[$ESC_URL\]\]|$DOMAIN $NOTE|g" "$FILE"
    CHANGED=true
fi

# Pattern 3: footnote bare URLs [fn:name] url -> [fn:name] domain (note)
if grep -qE "\[fn:[^]]*\] *$URL" "$FILE" 2>/dev/null; then
    sed -i '' "s|\(\[fn:[^]]*\]\) *$ESC_URL|\1 $DOMAIN $NOTE|g" "$FILE"
    CHANGED=true
fi

# Pattern 4: standalone bare URL on its own line
if grep -qx "$URL" "$FILE" 2>/dev/null; then
    sed -i '' "s|^$ESC_URL$|$DOMAIN $NOTE|g" "$FILE"
    CHANGED=true
fi

if [[ "$CHANGED" == "false" ]]; then
    echo "Warning: URL not found in $FILE: $URL"
    echo "The file was not modified."
    exit 1
fi

# Add domain to blocklist
BLOCKLIST="engine/blocked-domains.txt"
if [[ ! -f "$BLOCKLIST" ]]; then
    echo "# Blocked domains" > "$BLOCKLIST"
fi
if ! grep -qxF "$DOMAIN" "$BLOCKLIST" 2>/dev/null; then
    echo "$DOMAIN" >> "$BLOCKLIST"
    echo "Added $DOMAIN to $BLOCKLIST"
fi

echo "Disabled $URL in $FILE"
echo ""
git diff "$FILE"
