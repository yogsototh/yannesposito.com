#!/usr/bin/env bash
# check-links.sh -- Check external links in blog posts for broken or suspicious URLs
set -euo pipefail

cd "$(git rev-parse --show-toplevel)" || exit 1

# --- Configuration ---
POSTS_DIR="src/posts"
BLOCKLIST="engine/blocked-domains.txt"
CACHE_DIR=".cache/link-check"
CACHE_MAX_AGE=86400  # 24 hours
REQUEST_DELAY=1
CURL_TIMEOUT=15
QUICK=false
NO_CACHE=false
FIX=false

SUSPICIOUS_KEYWORDS=(
    "casino" "gambling" "poker" "slots" "bet "
    "crypto" "bitcoin" "ethereum" "blockchain" "web3" "nft"
    "adult" "porn" "xxx"
    "domain for sale" "buy this domain" "this domain is for sale"
    "parked domain" "domain parking" "coming soon"
    "pharma" "viagra" "cialis"
)

# --- Parse arguments ---
for arg in "$@"; do
    case "$arg" in
        --quick) QUICK=true ;;
        --no-cache) NO_CACHE=true ;;
        --fix) FIX=true ;;
        --help|-h)
            echo "Usage: check-links.sh [--quick] [--no-cache] [--fix]"
            echo "  --quick    : skip content checking (HTTP status only)"
            echo "  --no-cache : ignore cached results"
            echo "  --fix      : interactively disable broken/suspicious links"
            exit 0
            ;;
    esac
done

# --- Helpers ---
url_domain() {
    echo "$1" | sed 's|https\?://||' | sed 's|/.*||' | sed 's|:.*||'
}

cache_key() {
    echo -n "$1" | md5 2>/dev/null || echo -n "$1" | md5sum | cut -d' ' -f1
}

is_cached() {
    local key
    key=$(cache_key "$1")
    local file="$CACHE_DIR/$key"
    if [[ "$NO_CACHE" == "true" ]]; then return 1; fi
    if [[ ! -f "$file" ]]; then return 1; fi
    local mtime age
    # GNU stat (nix) uses -c %Y, macOS stat uses -f %m
    mtime=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo 0)
    age=$(( $(date +%s) - mtime ))
    (( age < CACHE_MAX_AGE ))
}

read_cache() {
    local key
    key=$(cache_key "$1")
    cat "$CACHE_DIR/$key"
}

write_cache() {
    local key
    key=$(cache_key "$1")
    mkdir -p "$CACHE_DIR"
    echo "$2" > "$CACHE_DIR/$key"
}

is_blocked() {
    local domain
    domain=$(url_domain "$1")
    if [[ -z "$domain" ]]; then return 1; fi
    if [[ ! -f "$BLOCKLIST" ]]; then return 1; fi
    while IFS= read -r blockedline; do
        [[ "$blockedline" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${blockedline// }" ]] && continue
        blockedline=$(echo "$blockedline" | xargs)
        if [[ "$domain" == "$blockedline" || "$domain" == *".$blockedline" ]]; then
            return 0
        fi
    done < "$BLOCKLIST"
    return 1
}

check_http() {
    local url="$1"
    local code
    # Try HEAD first (faster)
    code=$(curl -sI -o /dev/null -w '%{http_code}' --max-time "$CURL_TIMEOUT" -L \
           -A "Mozilla/5.0 (compatible; link-checker/1.0)" \
           "$url" 2>/dev/null || echo "000")
    # Some servers reject HEAD (405), fallback to GET
    if [[ "$code" == "405" ]]; then
        code=$(curl -s -o /dev/null -w '%{http_code}' --max-time "$CURL_TIMEOUT" -L \
               -A "Mozilla/5.0 (compatible; link-checker/1.0)" \
               "$url" 2>/dev/null || echo "000")
    fi
    # Sanitize: only keep the last 3 digits (curl may concatenate codes on redirects)
    code="${code: -3}"
    echo "$code"
}

check_content() {
    local url="$1"
    local content=""

    # Try snag first, fallback to curl
    if command -v snag &>/dev/null; then
        content=$(snag --quiet --format text "$url" 2>/dev/null || true)
    fi
    if [[ -z "$content" ]]; then
        content=$(curl -sL --max-time "$CURL_TIMEOUT" \
                  -A "Mozilla/5.0 (compatible; link-checker/1.0)" \
                  "$url" 2>/dev/null || true)
    fi

    if [[ -z "$content" ]]; then
        echo "fetch_failed"
        return
    fi

    local matched=()
    local lower_content
    lower_content=$(echo "$content" | tr '[:upper:]' '[:lower:]')
    for keyword in "${SUSPICIOUS_KEYWORDS[@]}"; do
        if echo "$lower_content" | grep -qi "$keyword"; then
            matched+=("$keyword")
        fi
    done

    if (( ${#matched[@]} > 0 )); then
        local IFS=", "
        echo "suspicious: ${matched[*]}"
    else
        echo "clean"
    fi
}

# --- Phase 1: Extract URLs ---
echo "Extracting external URLs from $POSTS_DIR..."

declare -A url_files  # url -> "file1 file2 ..."
declare -a all_urls=()

while IFS= read -r orgfile; do
    # Pattern 1: org-mode links [[https://...][...]]
    while IFS= read -r url; do
        [[ -z "$url" ]] && continue
        url_files["$url"]="${url_files[$url]:-} $orgfile"
        all_urls+=("$url")
    done < <(grep -oE '\[\[https?://[^]]+\]\[' "$orgfile" 2>/dev/null \
             | sed 's/^\[\[//; s/\]\[$//' || true)

    # Pattern 2: footnote bare URLs [fn:name] https://...
    while IFS= read -r url; do
        [[ -z "$url" ]] && continue
        url_files["$url"]="${url_files[$url]:-} $orgfile"
        all_urls+=("$url")
    done < <(grep -oE '\[fn:[^]]*\] https?://[^ ]+' "$orgfile" 2>/dev/null \
             | grep -oE 'https?://[^ ]+' || true)
done < <(find "$POSTS_DIR" -name '*.org' -type f | sort)

# Deduplicate URLs (filter out empty entries)
mapfile -t unique_urls < <(printf '%s\n' "${all_urls[@]}" | grep -v '^$' | sort -u)

echo "Found ${#unique_urls[@]} unique external URLs."
echo ""

# --- Phase 2-5: Check each URL ---
declare -a broken=()
declare -a suspicious=()
declare -a blocked=()
declare -a ok=()
declare -a errors=()

count=0
total=${#unique_urls[@]}

for url in "${unique_urls[@]}"; do
    count=$((count + 1))
    domain=$(url_domain "$url")
    files="${url_files[$url]:-unknown}"
    files=$(echo "$files" | xargs)  # trim whitespace

    printf "\r[%d/%d] Checking %s...                    " "$count" "$total" "$domain" >&2

    # Check blocklist
    if is_blocked "$url"; then
        blocked+=("$url|$files")
        write_cache "$url" "blocked"
        continue
    fi

    # Check cache
    if is_cached "$url"; then
        cached=$(read_cache "$url")
        case "$cached" in
            ok*) ok+=("$url|${cached#ok }|$files") ;;
            broken*) broken+=("$url|${cached#broken }|$files") ;;
            suspicious*) suspicious+=("$url|${cached#suspicious: }|$files") ;;
            blocked) blocked+=("$url|$files") ;;
        esac
        continue
    fi

    # HTTP check
    code=$(check_http "$url")

    if [[ "$code" == "000" ]]; then
        broken+=("$url|timeout/unreachable|$files")
        write_cache "$url" "broken timeout/unreachable"
        sleep "$REQUEST_DELAY"
        continue
    fi

    if (( code >= 400 )); then
        broken+=("$url|HTTP $code|$files")
        write_cache "$url" "broken HTTP $code"
        sleep "$REQUEST_DELAY"
        continue
    fi

    # Content check (unless --quick)
    if [[ "$QUICK" == "false" ]]; then
        result=$(check_content "$url")
        if [[ "$result" == suspicious* ]]; then
            keywords="${result#suspicious: }"
            suspicious+=("$url|$keywords|$files")
            write_cache "$url" "suspicious: $keywords"
            sleep "$REQUEST_DELAY"
            continue
        fi
    fi

    ok+=("$url|HTTP $code|$files")
    write_cache "$url" "ok HTTP $code"
    sleep "$REQUEST_DELAY"
done

printf "\r%80s\r" "" >&2  # clear progress line

# --- Phase 6: Report ---
echo ""
echo "================================================================="
echo "  LINK CHECK REPORT"
echo "================================================================="

if (( ${#blocked[@]} > 0 )); then
    echo ""
    echo "--- BLOCKED (known bad domains) ---"
    for entry in "${blocked[@]}"; do
        IFS='|' read -r url files <<< "$entry"
        echo "  $url"
        echo "    found in: $files"
    done
fi

if (( ${#broken[@]} > 0 )); then
    echo ""
    echo "--- BROKEN LINKS ---"
    for entry in "${broken[@]}"; do
        IFS='|' read -r url reason files <<< "$entry"
        echo "  [$reason] $url"
        echo "    found in: $files"
    done
fi

if (( ${#suspicious[@]} > 0 )); then
    echo ""
    echo "--- SUSPICIOUS CONTENT ---"
    for entry in "${suspicious[@]}"; do
        IFS='|' read -r url keywords files <<< "$entry"
        echo "  $url"
        echo "    keywords: $keywords"
        echo "    found in: $files"
    done
fi

echo ""
echo "--- SUMMARY ---"
echo "  Total: ${#unique_urls[@]}  |  OK: ${#ok[@]}  |  Broken: ${#broken[@]}  |  Suspicious: ${#suspicious[@]}  |  Blocked: ${#blocked[@]}"
echo ""

# --- Interactive fix mode ---
if [[ "$FIX" == "true" ]] && (( ${#broken[@]} + ${#suspicious[@]} + ${#blocked[@]} > 0 )); then
    echo "================================================================="
    echo "  INTERACTIVE FIX"
    echo "================================================================="
    echo ""

    fix_link() {
        local url="$1"
        local detail="$2"
        local files="$3"
        echo "  URL: $url"
        echo "  [$detail]"
        echo "  found in: $files"
        printf "  Disable this link? [y/N/s(kip all)] "
        read -r answer </dev/tty
        case "$answer" in
            s|S) return 2 ;;
            y|Y) ;;
            *) echo "  -> skipped"; echo ""; return 0 ;;
        esac
        printf "  Reason: "
        read -r reason </dev/tty
        if [[ -z "$reason" ]]; then
            reason="$detail"
        fi
        for f in $files; do
            [[ -f "$f" ]] || continue
            engine/disable-link.sh "$f" "$url" "$reason"
        done
        echo ""
    }

    for entry in "${blocked[@]}"; do
        IFS='|' read -r url files <<< "$entry"
        fix_link "$url" "blocked domain" "$files"
        [[ $? -eq 2 ]] && break
    done

    for entry in "${broken[@]}"; do
        IFS='|' read -r url reason files <<< "$entry"
        fix_link "$url" "$reason" "$files"
        [[ $? -eq 2 ]] && break
    done

    for entry in "${suspicious[@]}"; do
        IFS='|' read -r url keywords files <<< "$entry"
        fix_link "$url" "suspicious: $keywords" "$files"
        [[ $? -eq 2 ]] && break
    done
fi

# Exit with non-zero if problems found
if (( ${#broken[@]} + ${#suspicious[@]} + ${#blocked[@]} > 0 )); then
    exit 1
fi
