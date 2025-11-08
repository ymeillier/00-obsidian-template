```bash
#Function for opening a current folder as a temp vault that always get overwritten for each new ephemeral inspection.

#Type: md_open ./file.md 
# to open a new temp vault for viewing/editing the readme file. 
# Run md_cleanup $PWD to remove references of this vault registration (so that don't have a larege number of registered temp vaults)


function obsidian_tmp() {
    
    # 1. Determine Source and Vault Directory (Use PWD)
    # The 'vault_dir' is the current working directory.
    local vault_dir="$(pwd)" 
    
    # The 'source_file' is now derived from the first .md file found,
    # or you can simply target the vault_dir for launching.
    # We will look for the first markdown file to open, defaulting to a common one.
    local source_file=""
    if [ -f "README.md" ]; then
        source_file="$(realpath "README.md")"
    else
        # Find the first .md file, if any
        local first_md_file=$(find "$vault_dir" -maxdepth 1 -type f -name "*.md" | head -n 1)
        if [ -n "$first_md_file" ]; then
            source_file="$(realpath "$first_md_file")"
        fi
    fi

    # 1b. Check Dependencies
    local config_file="$HOME/Library/Application Support/obsidian/obsidian.json"
    local TEMPLATE_CONFIG_PATH="/Users/meillier/Documents/Obsidian/00-Template/.obsidian"
    
    if ! command -v jq &> /dev/null; then echo "Error: 'jq' required. Aborting."; return 1; fi
    if ! perl -MURI::Escape -e '1' 2>/dev/null; then echo "Error: perl module URI::Escape required. Aborting."; return 1; fi

    echo "--- Initiating Temporary Obsidian Vault for Current Directory: $vault_dir ---"

    # 2. Check if the directory is already registered (Idempotence)
    local vault_id=$(jq -r --arg path "$vault_dir" \
        '.vaults | to_entries[] | select(.value.path == $path) | .key' \
        "$config_file" 2>/dev/null)

    # 3. Registration (Modified to use the fixed ID prefix)
    if [[ -z "$vault_id" ]]; then
        # Check for existing .obsidian folder (don't overwrite a persistent vault)
        if [ -d "$vault_dir/.obsidian" ]; then
             echo "Vault config already exists in the repo. Launching directly."
        else
            echo "Creating temporary vault configuration in: $vault_dir"
            
            # --- CRITICAL CHANGE FOR TEMPLATE COPY ---
            if [ -d "$TEMPLATE_CONFIG_PATH" ]; then
                # Copy the entire .obsidian contents from the template
                cp -r "$TEMPLATE_CONFIG_PATH" "$vault_dir/"
                echo "✅ Copied template configuration to new vault."
            else
                # Fallback: create an empty directory if the template is not found
                mkdir -p "$vault_dir/.obsidian"
                echo "⚠️ Template configuration not found. Created empty .obsidian folder."
            fi
            # --- END CRITICAL CHANGE ---
            
            # Generate new metadata
            local vault_name="$(basename "$vault_dir")-TEMP"
            local random_suffix=$(openssl rand -hex 1) # Gets 2 hex characters
            vault_id="99999999999999${random_suffix}" # Unique ID with cleanup marker
            local timestamp_ms=$(perl -MTime::HiRes -e 'printf "%.0f\n", Time::HiRes::time * 1000')
            
            # Ensure config file exists
            if [ ! -f "$config_file" ]; then mkdir -p "$(dirname "$config_file")"; echo '{"vaults":{}}' > "$config_file"; fi
            
            # Register in obsidian.json
            local jq_script='.vaults += { ($id): { "path": $path, "ts": ($ts | tonumber), "open": true } } | .lastOpenVault = $id'
            jq --arg id "$vault_id" --arg path "$vault_dir" --arg ts "$timestamp_ms" "$jq_script" "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"

            # Quit Obsidian (Required for config change)
            osascript -e 'quit app "Obsidian"' 2>/dev/null
            echo "Closing running Obsidian instances to finalize registration..."
            sleep 2
        fi
    fi

    # 4. Launch the vault, and optionally a specific file
    local launch_url=""
    local encoded_id=$(perl -MURI::Escape -e 'print uri_escape($ARGV[0])' "$vault_id")

    if [ -n "$source_file" ]; then
        local file_name="$(basename "$source_file")"
        local encoded_file=$(perl -MURI::Escape -e 'print uri_escape($ARGV[0])' "$file_name")
        launch_url="obsidian://open?vault=$encoded_id&file=$encoded_file"
        echo "Launching specific file: $file_name in ephemeral vault: $vault_dir"
    else
        launch_url="obsidian://open?vault=$encoded_id"
        echo "Launching ephemeral vault: $vault_dir"
    fi
    
    open "$launch_url"
    
    echo ""
    echo "🚨 ACTION REQUIRED: When done, manually run a cleanup function like: md_cleanup_all"
}

```