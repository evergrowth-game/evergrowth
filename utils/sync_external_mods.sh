#!/bin/bash
# Sync external mods from global minetest directory into the game's local mods directory.

# Ensure we are in the game root directory
GAME_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXTERNAL_MODS_FILE="$GAME_ROOT/external_mods.md"

if [ ! -f "$EXTERNAL_MODS_FILE" ]; then
    echo "Error: external_mods.md not found at $EXTERNAL_MODS_FILE" >&2
    exit 1
fi

# Print usage if help requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [mod_name | all]"
    echo "  [mod_name]  Sync only the specified mod (e.g., 3d_armor)"
    echo "  all         Sync all 74 external mods tracked in external_mods.md (default)"
    exit 0
fi

TARGET_MOD="${1:-all}"

# Extract mod names and paths from external_mods.md table
# Example format: | `3d_armor` | `~/...` |
parse_mods() {
    grep -E '^\| `[a-zA-Z0-9_-]+` \| `' "$EXTERNAL_MODS_FILE" | while read -r line; do
        # Extract mod name (between first set of backticks)
        mod_name=$(echo "$line" | cut -d'`' -f2)
        # Extract source path (between second set of backticks)
        source_path=$(echo "$line" | cut -d'`' -f4)
        echo "$mod_name|$source_path"
    done
}

sync_mod() {
    local mod_name="$1"
    local source_path="$2"
    local dest_path="$GAME_ROOT/mods/$mod_name"

    if [ ! -d "$source_path" ]; then
        echo "Warning: Source directory not found for $mod_name at: $source_path" >&2
        return 1
    fi

    echo "Syncing $mod_name..."
    # Perform the rsync operation
    rsync -a --delete --exclude='.git' --exclude='.DS_Store' "$source_path/" "$dest_path/"
    return $?
}

# Main execution
success=0
total=0
failed=0

# Parse mods into an array/list
mapfile -t mods < <(parse_mods)

if [ "${#mods[@]}" -eq 0 ]; then
    echo "Error: No tracked external mods parsed from $EXTERNAL_MODS_FILE" >&2
    exit 1
fi

if [ "$TARGET_MOD" = "all" ]; then
    echo "Starting full sync of all ${#mods[@]} external mods..."
    for mod_entry in "${mods[@]}"; do
        mod_name=$(echo "$mod_entry" | cut -d'|' -f1)
        source_path=$(echo "$mod_entry" | cut -d'|' -f2)
        total=$((total + 1))
        if sync_mod "$mod_name" "$source_path"; then
            success=$((success + 1))
        else
            failed=$((failed + 1))
        fi
    done
    echo "Sync complete: $success succeeded, $failed failed/skipped."
else
    # Find specific mod in list
    found=0
    for mod_entry in "${mods[@]}"; do
        mod_name=$(echo "$mod_entry" | cut -d'|' -f1)
        source_path=$(echo "$mod_entry" | cut -d'|' -f2)
        if [ "$mod_name" = "$TARGET_MOD" ]; then
            found=1
            sync_mod "$mod_name" "$source_path"
            exit $?
        fi
    done
    if [ "$found" -eq 0 ]; then
        echo "Error: Mod '$TARGET_MOD' is not listed as an external mod in external_mods.md" >&2
        exit 1
    fi
fi
