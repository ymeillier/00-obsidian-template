
```bash
function obsidian_cleanup_id() {
    # 1. Input Validation
    if [ -z "$1" ]; then
        echo "Error: Vault ID is required as the first argument."
        echo "Usage: md_cleanup_specific <Vault_ID>"
        return 1
    fi

    local vault_id_to_remove="$1"
    local config_file="$HOME/Library/Application Support/obsidian/obsidian.json"

    if ! command -v jq &> /dev/null; then
        echo "Error: 'jq' is required for JSON manipulation. Aborting."
        return 1
    fi

    echo "--- Initiating Cleanup for Specific Vault ID: $vault_id_to_remove ---"
    
    # 2. Extract Vault Path from JSON
    # Use jq to get the path of the specific vault ID
    local vault_dir=$(jq -r --arg id "$vault_id_to_remove" \
        '.vaults[$id].path' \
        "$config_file" 2>/dev/null)

    # Check if the vault ID exists in the configuration
    if [ -z "$vault_dir" ] || [ "$vault_dir" = "null" ]; then
        echo "❌ Vault ID '$vault_id_to_remove' not found in $config_file."
        return 2
    fi
    
    # 3. Perform Cleanup Actions
    echo "Processing Vault Path: $vault_dir"
    
    # 3a. File System Cleanup (Removes the .obsidian folder)
    if [ -d "$vault_dir/.obsidian" ]; then
        read -r -p "⚠️ Confirm removal of the **.obsidian folder** at '$vault_dir/.obsidian' (y/N)? " confirmation
        if [[ "$confirmation" =~ ^[Yy]$ ]]; then
            rm -rf "$vault_dir/.obsidian"
            echo " - ✅ Removed .obsidian folder."
        else
            echo " - ⏭️ Skipped removal of .obsidian folder."
        fi
    else
        echo " - ℹ️ .obsidian folder not found at path (already cleaned or never existed)."
    fi
    
    # 3b. JSON Configuration Cleanup (Deletes the entry by ID)
    read -r -p "⚠️ Confirm removal of Vault ID **'$vault_id_to_remove'** from $config_file (y/N)? " confirmation_json
    if [[ "$confirmation_json" =~ ^[Yy]$ ]]; then
        jq "del(.vaults[\"$vault_id_to_remove\"])" \
            "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"
        echo " - ✅ Removed ID from obsidian.json."
    else
        echo " - ⏭️ Skipped removal of Vault ID from obsidian.json."
    fi

    # 4. Quit Obsidian (To force immediate config reload)
    osascript -e 'quit app "Obsidian"' 2>/dev/null
    echo ""
    echo "✨ Complete. Cleanup for Vault ID '$vault_id_to_remove' finished and Obsidian closed."
}
```