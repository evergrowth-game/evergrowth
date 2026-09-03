#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "${0}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EXTERNAL_MODS_FILE="$REPO_DIR/external_mods.md"
MODS_DIR="$REPO_DIR/mods"

if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: 'python3' is required to parse external_mods.md but was not found in PATH." >&2
    exit 1
fi

if [ ! -f "$EXTERNAL_MODS_FILE" ]; then
    echo "Error: external_mods.md not found at '$EXTERNAL_MODS_FILE'." >&2
    exit 1
fi

TEMP_DIR=""
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT INT TERM

usage() {
    local exit_code="${1:-1}"
    echo "Usage:"
    echo "  $SCRIPT_NAME list                                      List all tracked external mods and divergence status"
    echo "  $SCRIPT_NAME check-all [--git]                         Check all tracked external mods against ContentDB releases (--git for raw Git HEAD)"
    echo "  $SCRIPT_NAME diff <mod_name> [-d|--detailed|--full]     Show high-level upstream change summary (-d for full diff)"
    echo "  $SCRIPT_NAME sync <mod_name> [-y|--yes|-f|--force]     Sync a non-diverged external mod from upstream source"
    echo ""
    echo "Examples:"
    echo "  $SCRIPT_NAME list"
    echo "  $SCRIPT_NAME check-all"
    echo "  $SCRIPT_NAME check-all --git"
    echo "  $SCRIPT_NAME diff airtanks"
    echo "  $SCRIPT_NAME diff airtanks --detailed"
    echo "  $SCRIPT_NAME sync airtanks"
    echo "  $SCRIPT_NAME sync airtanks -y"
    exit "$exit_code"
}

parse_registry() {
    python3 - "$EXTERNAL_MODS_FILE" << 'EOF'
import sys, re

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    for line in f:
        m = re.match(r'^\|\s*`([^`]+)`\s*\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\|\s*(.*?)\s*\|', line)
        if not m:
            continue
        mod_name = m.group(1).strip()
        author = m.group(2).strip()
        license_str = m.group(3).strip()
        sources_str = m.group(4).strip()
        notes = m.group(5).strip()

        src_match = re.search(r'\[Source\]\(([^)]+)\)', sources_str)
        source_url = src_match.group(1).strip() if src_match else ''

        # Normalize Git clone endpoint (strip web UI browsing suffixes like /src/master/ or /tree/main/)
        if source_url:
            source_url = re.sub(r'/(src|tree)/[^/]+(/.*)?$', '', source_url)

        # Divergence check using word boundary pattern
        is_diverged = '1' if re.search(r'\b(custom-derived|customized|stripped|diverged)\b', notes, re.IGNORECASE) else '0'

        print(f'{mod_name}\t{source_url}\t{is_diverged}\t{notes}')
EOF
}

get_mod_entry() {
    local target="$1"
    parse_registry | awk -F'\t' -v target="$target" '$1 == target { print $0; exit }'
}

do_list() {
    echo "Tracked External Mods in Evergrowth:"
    printf "%-26s %-12s %s\n" "MOD NAME" "STATUS" "UPSTREAM SOURCE"
    printf "%-26s %-12s %s\n" "--------------------------" "------------" "----------------------------------------"
    
    local count=0
    while IFS=$'\t' read -r mod_name source_url is_diverged notes; do
        count=$((count + 1))
        local status="Tracked"
        if [ "$is_diverged" = "1" ]; then
            status="Diverged 🔒"
        fi
        printf "%-26s %-12s %s\n" "$mod_name" "$status" "$source_url"
    done < <(parse_registry)
    
    echo ""
    echo "Total: $count external mods tracked."
}

do_check_all_cdb() {
    echo "Checking all external mods against ContentDB releases..."
    echo ""
    python3 - "$EXTERNAL_MODS_FILE" "$MODS_DIR" << 'EOF'
import sys, os, re, json, urllib.request

mods_file = sys.argv[1]
mods_dir = sys.argv[2]

# 1. Fetch entire ContentDB package catalog in one polite HTTP request
url = "https://content.luanti.org/api/packages/"
req = urllib.request.Request(url, headers={"User-Agent": "Minetest/5.8.0 (Evergrowth Updater)"})
try:
    with urllib.request.urlopen(req, timeout=15) as resp:
        cdb_catalog = json.loads(resp.read().decode("utf-8"))
except Exception as e:
    print(f"Error: Failed to fetch package catalog from ContentDB API: {e}", file=sys.stderr)
    sys.exit(1)

cdb_map = {}
for item in cdb_catalog:
    author = (item.get("author") or "").lower()
    name = (item.get("name") or "").lower()
    rel = item.get("release")
    if author and name:
        cdb_map[(author, name)] = rel
    if name and name not in cdb_map:
        cdb_map[name] = rel

packages = []
with open(mods_file, "r", encoding="utf-8") as f:
    for line in f:
        m = re.match(r"^\|\s*`([^`]+)`\s*\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\|\s*(.*?)\s*\|", line)
        if not m:
            continue
        mod_name = m.group(1).strip()
        author = m.group(2).strip()
        sources_str = m.group(4).strip()
        notes = m.group(5).strip()
        
        cdb_match = re.search(r"\[ContentDB\]\(https://content\.luanti\.org/packages/([^/]+)/([^/]+)/?\)", sources_str)
        cdb_author = cdb_match.group(1) if cdb_match else None
        cdb_name = cdb_match.group(2) if cdb_match else None
            
        is_diverged = bool(re.search(r"\b(custom-derived|customized|stripped|diverged)\b", notes, re.IGNORECASE))
        
        # Read local release ID from modpack.conf or mod.conf
        local_rel = None
        candidates = [
            os.path.join(mods_dir, mod_name, "modpack.conf"),
            os.path.join(mods_dir, mod_name, "mod.conf"),
            os.path.join(mods_dir, mod_name, mod_name, "mod.conf")
        ]
        for cand in candidates:
            if os.path.isfile(cand):
                with open(cand, "r", encoding="utf-8", errors="ignore") as cf:
                    for cline in cf:
                        cm = re.match(r"^\s*release\s*=\s*(\d+)", cline)
                        if cm:
                            local_rel = int(cm.group(1))
                            break
            if local_rel is not None:
                break
                
        packages.append({
            "mod_name": mod_name,
            "author": author,
            "cdb_author": cdb_author,
            "cdb_name": cdb_name,
            "is_diverged": is_diverged,
            "local_rel": local_rel,
            "notes": notes
        })

updates = 0
up_to_date = 0
diverged = 0
unversioned = 0
errors = 0

print(f"{'MOD NAME':<26} {'STATUS':<20} {'DETAILS'}")
print(f"{'--------------------------':<26} {'--------------------':<20} {'----------------------------------------'}")

for pkg in packages:
    mod_name = pkg["mod_name"]
    local_rel = pkg["local_rel"]
    is_diverged = pkg["is_diverged"]
    cdb_author = pkg["cdb_author"]
    cdb_name = pkg["cdb_name"]

    remote_rel = None
    if cdb_author and cdb_name:
        remote_rel = cdb_map.get((cdb_author.lower(), cdb_name.lower()))
    if remote_rel is None and cdb_name:
        remote_rel = cdb_map.get(cdb_name.lower())

    if is_diverged:
        diverged += 1
        detail = f"Release {local_rel or 'N/A'}"
        if remote_rel and local_rel and remote_rel > local_rel:
            detail += f" (Upstream: {remote_rel})"
        print(f"{mod_name:<26} {'Diverged 🔒':<20} {detail}")
    elif remote_rel is None:
        errors += 1
        print(f"{mod_name:<26} {'Not on ContentDB ❌':<20} {'No ContentDB release found'}")
    else:
        if local_rel is None:
            unversioned += 1
            print(f"{mod_name:<26} {'No Local Rel ID ⚠️':<20} Upstream: {remote_rel}")
        elif remote_rel > local_rel:
            updates += 1
            print(f"{mod_name:<26} {'Update Available ⚠️':<20} Local: {local_rel} -> Upstream: {remote_rel}")
        else:
            up_to_date += 1
            print(f"{mod_name:<26} {'Up to date ✅':<20} Release {local_rel}")

print("")
print("==================================================================")
print(f"Summary: {len(packages)} checked | {up_to_date} up to date | {updates} updates available | {unversioned} unversioned | {diverged} diverged | {errors} errors")
print("==================================================================")
if updates > 0:
    print("Tip: Run 'update_external_mods.sh diff <mod_name>' to inspect upstream source for any mod with updates.")
EOF
}

do_check_all_git() {
    echo "Checking all external mods against upstream Git repositories (raw HEAD)..."
    echo ""
    printf "%-26s %-20s %s\n" "MOD NAME" "STATUS" "DETAILS"
    printf "%-26s %-20s %s\n" "--------------------------" "--------------------" "----------------------------------------"

    local total=0
    local up_to_date=0
    local updates_available=0
    local diverged=0
    local errors=0

    while IFS=$'\t' read -r mod_name source_url is_diverged notes; do
        total=$((total + 1))
        local local_mod_path="$MODS_DIR/$mod_name"
        
        if [ ! -d "$local_mod_path" ]; then
            printf "%-26s %-20s %s\n" "$mod_name" "Missing Locally ❌" "Directory not in mods/"
            errors=$((errors + 1))
            continue
        fi

        if [ -z "$source_url" ]; then
            printf "%-26s %-20s %s\n" "$mod_name" "No Source URL ❌" "No source URL in external_mods.md"
            errors=$((errors + 1))
            continue
        fi

        cleanup
        TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/eg_mod_${mod_name}_XXXXXX")"

        local clone_err
        if ! clone_err="$(git clone --depth 1 --quiet -- "$source_url" "$TEMP_DIR/clone" 2>&1)"; then
            printf "%-26s %-20s %s\n" "$mod_name" "Fetch Failed ❌" "Git clone error"
            errors=$((errors + 1))
            continue
        fi

        local upstream_mod_root
        upstream_mod_root="$(locate_mod_root "$TEMP_DIR/clone" "$mod_name" "$local_mod_path")"

        strip_vcs_metadata "$TEMP_DIR/clone"
        if [ "$upstream_mod_root" != "$TEMP_DIR/clone" ]; then
            strip_vcs_metadata "$upstream_mod_root"
        fi

        set +e
        local diff_output
        diff_output="$(git diff --no-index --shortstat "$local_mod_path" "$upstream_mod_root" 2>/dev/null)"
        local diff_status=$?
        set -e

        if [ "$diff_status" -eq 0 ]; then
            if [ "$is_diverged" = "1" ]; then
                printf "%-26s %-20s %s\n" "$mod_name" "Diverged (Sync) 🔒" "Matches upstream"
                diverged=$((diverged + 1))
            else
                printf "%-26s %-20s %s\n" "$mod_name" "Up to date ✅" "Matches upstream HEAD"
                up_to_date=$((up_to_date + 1))
            fi
        elif [ "$diff_status" -eq 1 ]; then
            local stat_summary
            stat_summary="$(echo "$diff_output" | sed 's/^[[:space:]]*//')"
            if [ "$is_diverged" = "1" ]; then
                printf "%-26s %-20s %s\n" "$mod_name" "Diverged 🔒" "$stat_summary"
                diverged=$((diverged + 1))
            else
                printf "%-26s %-20s %s\n" "$mod_name" "Update Available ⚠️" "$stat_summary"
                updates_available=$((updates_available + 1))
            fi
        else
            printf "%-26s %-20s %s\n" "$mod_name" "Diff Error ❌" "Exit code $diff_status"
            errors=$((errors + 1))
        fi
    done < <(parse_registry)

    cleanup
    echo ""
    echo "=================================================================="
    echo "Summary: $total checked | $up_to_date up to date | $updates_available updates available | $diverged diverged | $errors errors"
    echo "=================================================================="
    if [ "$updates_available" -gt 0 ]; then
        echo "Tip: Run '$SCRIPT_NAME diff <mod_name>' to inspect changes for any mod with updates."
    fi
}

fetch_upstream() {
    local mod_name="$1"
    local source_url="$2"

    if [ -z "$source_url" ]; then
        echo "Error: No upstream git source URL found for '$mod_name' in external_mods.md." >&2
        exit 1
    fi

    cleanup
    TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/eg_mod_${mod_name}_XXXXXX")"
    echo "Fetching upstream source from $source_url..."
    
    local clone_err
    if ! clone_err="$(git clone --depth 15 --quiet -- "$source_url" "$TEMP_DIR/clone" 2>&1)"; then
        echo "Error: Failed to clone upstream repository at '$source_url'." >&2
        [ -n "$clone_err" ] && echo "$clone_err" >&2
        exit 1
    fi
}

locate_mod_root() {
    local clone_path="$1"
    local mod_name="$2"
    local local_path="${3:-}"

    # If local mod is a modpack, or clone root is a modpack matching the local target
    if [ -n "$local_path" ] && ([ -f "$local_path/modpack.conf" ] || [ -f "$local_path/modpack.txt" ]); then
        if [ -f "$clone_path/modpack.conf" ] || [ -f "$clone_path/modpack.txt" ]; then
            echo "$clone_path"
            return
        fi
    fi

    # 1. Prefer explicit subfolder named after the mod if it contains a mod manifest (and root is not a matching modpack)
    if [ -d "$clone_path/$mod_name" ] && ([ -f "$clone_path/$mod_name/mod.conf" ] || [ -f "$clone_path/$mod_name/init.lua" ]) && [ ! -f "$clone_path/modpack.conf" ] && [ ! -f "$clone_path/modpack.txt" ]; then
        echo "$clone_path/$mod_name"
        return
    fi

    # 2. Check if clone root contains a mod or modpack manifest
    if [ -f "$clone_path/mod.conf" ] || [ -f "$clone_path/modpack.conf" ] || [ -f "$clone_path/modpack.txt" ] || [ -f "$clone_path/init.lua" ]; then
        echo "$clone_path"
        return
    fi

    # 3. Check if there is an unambiguous single subfolder containing a mod manifest
    local candidates=()
    for d in "$clone_path"/*/; do
        if [ -d "$d" ] && ([ -f "$d/mod.conf" ] || [ -f "$d/init.lua" ]); then
            candidates+=("${d%/}")
        fi
    done
    if [ "${#candidates[@]}" -eq 1 ]; then
        echo "${candidates[0]}"
        return
    fi

    echo "$clone_path"
}

strip_vcs_metadata() {
    local target_dir="$1"
    if [ -n "$target_dir" ] && [ "$target_dir" != "/" ] && [ -d "$target_dir" ]; then
        rm -rf "$target_dir/.git" \
               "$target_dir/.github" \
               "$target_dir/.gitignore" \
               "$target_dir/.gitattributes" \
               "$target_dir/.gitlab-ci.yml" \
               "$target_dir/.DS_Store" \
               "$target_dir/.luacheckrc" 2>/dev/null || true
    fi
}

do_diff() {
    local target="$1"
    local detailed="${2:-false}"

    local entry
    entry="$(get_mod_entry "$target")"
    if [ -z "$entry" ]; then
        echo "Error: Mod '$target' is not an external mod tracked in external_mods.md." >&2
        exit 1
    fi

    local local_mod_path="$MODS_DIR/$target"
    if [ ! -d "$local_mod_path" ]; then
        echo "Error: Local mod directory not found at '$local_mod_path'." >&2
        exit 1
    fi

    local mod_name source_url is_diverged notes
    IFS=$'\t' read -r mod_name source_url is_diverged notes <<< "$entry"

    if [ "$is_diverged" = "1" ]; then
        echo "⚠️  NOTE: '$mod_name' is custom-diverged in Evergrowth ($notes)."
        echo "   Comparing against upstream baseline ($source_url):"
        echo ""
    fi

    fetch_upstream "$mod_name" "$source_url"
    
    local upstream_mod_root
    upstream_mod_root="$(locate_mod_root "$TEMP_DIR/clone" "$mod_name" "$local_mod_path")"

    echo "=================================================================="
    echo " Upstream Feature & Commit Summary for '$mod_name'"
    echo " Source: $source_url"
    echo "=================================================================="
    echo ""
    echo "Recent Upstream Commits:"
    git -C "$TEMP_DIR/clone" log --oneline -n 8 --no-decorate || true
    echo ""

    # Strip VCS metadata directory from cloned workspace before performing diff
    strip_vcs_metadata "$TEMP_DIR/clone"
    if [ "$upstream_mod_root" != "$TEMP_DIR/clone" ]; then
        strip_vcs_metadata "$upstream_mod_root"
    fi

    echo "File Change Summary (Local Snapshot vs Upstream HEAD):"
    set +e
    git diff --no-index --stat "$local_mod_path" "$upstream_mod_root"
    local diff_status=$?
    set -e

    if [ "$diff_status" -eq 0 ]; then
        echo "✅ Local mod snapshot matches upstream HEAD."
    elif [ "$diff_status" -eq 1 ]; then
        if [ "$detailed" = "true" ]; then
            echo ""
            echo "=================================================================="
            echo " Detailed Line Diff (Local Snapshot -> Upstream HEAD)"
            echo "=================================================================="
            set +e
            git diff --no-index --color=auto "$local_mod_path" "$upstream_mod_root"
            set -e
        else
            echo ""
            echo "Tip: Run '$SCRIPT_NAME diff $mod_name --detailed' to view full line-by-line diff."
        fi
    else
        echo "Error: Failed to execute diff between local snapshot and upstream source (exit code $diff_status)." >&2
        exit 1
    fi
}

do_sync() {
    local target="$1"
    local auto_confirm="${2:-false}"

    local entry
    entry="$(get_mod_entry "$target")"
    if [ -z "$entry" ]; then
        echo "Error: Mod '$target' is not an external mod tracked in external_mods.md." >&2
        exit 1
    fi

    local local_mod_path="$MODS_DIR/$target"
    if [ ! -d "$local_mod_path" ]; then
        echo "Error: Local mod directory not found at '$local_mod_path'." >&2
        exit 1
    fi

    local mod_name source_url is_diverged notes
    IFS=$'\t' read -r mod_name source_url is_diverged notes <<< "$entry"

    if [ "$is_diverged" = "1" ]; then
        echo "❌ Protection Error: Mod '$mod_name' is custom-diverged in Evergrowth." >&2
        echo "   Reason: $notes" >&2
        echo "   Overwriting diverged mods from upstream is prohibited." >&2
        exit 1
    fi

    fetch_upstream "$mod_name" "$source_url"
    local upstream_mod_root
    upstream_mod_root="$(locate_mod_root "$TEMP_DIR/clone" "$mod_name" "$local_mod_path")"

    strip_vcs_metadata "$TEMP_DIR/clone"
    if [ "$upstream_mod_root" != "$TEMP_DIR/clone" ]; then
        strip_vcs_metadata "$upstream_mod_root"
    fi

    echo ""
    echo "Planned Sync for '$mod_name':"
    set +e
    git diff --no-index --stat "$local_mod_path" "$upstream_mod_root"
    local diff_status=$?
    set -e

    if [ "$diff_status" -eq 0 ]; then
        echo "Mod is already up to date with upstream HEAD."
        exit 0
    elif [ "$diff_status" -ge 2 ]; then
        echo "Error: Failed to compare local mod against upstream directory (exit code $diff_status). Aborting sync." >&2
        exit 1
    fi
    echo ""

    if [ -z "$upstream_mod_root" ] || [ ! -d "$upstream_mod_root" ] || [ -z "$(ls -A "$upstream_mod_root")" ]; then
        echo "Error: Resolved upstream directory '$upstream_mod_root' is empty or invalid. Aborting sync." >&2
        exit 1
    fi

    if [ "$auto_confirm" != "true" ]; then
        local confirm=""
        if [ -t 0 ]; then
            read -r -p "Apply upstream update to 'mods/$mod_name'? [y/N] " confirm
        elif (exec 3</dev/tty) 2>/dev/null; then
            read -r -p "Apply upstream update to 'mods/$mod_name'? [y/N] " confirm < /dev/tty
        else
            echo "Error: Non-interactive environment detected. Pass -y/--yes to confirm sync." >&2
            exit 1
        fi
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Sync cancelled."
            exit 0
        fi
    fi

    echo "Syncing '$mod_name' from upstream..."
    rsync -a --delete \
        --exclude='.git' \
        --exclude='.github' \
        --exclude='.gitignore' \
        --exclude='.gitattributes' \
        --exclude='.gitlab-ci.yml' \
        --exclude='.DS_Store' \
        --exclude='.luacheckrc' \
        "$upstream_mod_root/" "$local_mod_path/"

    echo "✅ Successfully synced '$mod_name' to upstream HEAD."
}

ACTION="${1:-}"
case "$ACTION" in
    -h|--help|help)
        usage 0
        ;;
    list)
        do_list
        ;;
    check-all|check|status)
        shift || true
        USE_GIT="false"
        for arg in "$@"; do
            case "$arg" in
                --git)
                    USE_GIT="true"
                    ;;
                -h|--help)
                    usage 0
                    ;;
                *)
                    echo "Error: Unknown option '$arg'." >&2
                    usage 1
                    ;;
            esac
        done
        if [ "$USE_GIT" = "true" ]; then
            do_check_all_git
        else
            do_check_all_cdb
        fi
        ;;
    diff)
        shift
        DETAILED="false"
        TARGET=""
        for arg in "$@"; do
            case "$arg" in
                -d|--detailed|--full)
                    DETAILED="true"
                    ;;
                -h|--help)
                    usage 0
                    ;;
                -*)
                    echo "Error: Unknown option '$arg'." >&2
                    usage 1
                    ;;
                *)
                    if [ -z "$TARGET" ]; then
                        TARGET="$arg"
                    else
                        echo "Error: Unexpected additional argument '$arg'." >&2
                        usage 1
                    fi
                    ;;
            esac
        done
        [ -z "$TARGET" ] && usage 1
        do_diff "$TARGET" "$DETAILED"
        ;;
    sync)
        shift
        AUTO_CONFIRM="false"
        TARGET=""
        for arg in "$@"; do
            case "$arg" in
                -y|--yes|-f|--force)
                    AUTO_CONFIRM="true"
                    ;;
                -h|--help)
                    usage 0
                    ;;
                -*)
                    echo "Error: Unknown option '$arg'." >&2
                    usage 1
                    ;;
                *)
                    if [ -z "$TARGET" ]; then
                        TARGET="$arg"
                    else
                        echo "Error: Unexpected additional argument '$arg'." >&2
                        usage 1
                    fi
                    ;;
            esac
        done
        [ -z "$TARGET" ] && usage 1
        do_sync "$TARGET" "$AUTO_CONFIRM"
        ;;
    *)
        usage 1
        ;;
esac
