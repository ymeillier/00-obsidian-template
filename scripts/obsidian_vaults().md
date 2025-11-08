
"`obsidian_vaults -s`" to sort output by path.



```bash
#!/bin/bash

## Function to list vaults
function obsidian_vaults() {
    local config_file="$HOME/Library/Application Support/obsidian/obsidian.json"
    local sort_by_path=0

    # 1. Check for the -s flag
    if [[ "$1" == "-s" ]]; then
        sort_by_path=1
        echo "Sorting by Path..."
    fi
    
    # Check dependencies
    if [ ! -f "$config_file" ]; then
        echo "Error: Obsidian configuration file not found at $config_file"
        return 1
    fi
    if ! command -v jq &> /dev/null; then
        echo "Error: 'jq' command not found. Please ensure it is installed."
        return 1
    fi

    echo "--- Obsidian Vaults ---"
    
    # --- Corrected jq logic ---
    local jq_query='
        .vaults | to_entries | 
        # 1. Map to create a simpler, more sortable structure
        map({
            id: .key,
            path: .value.path,
            ts_raw: .value.ts,
            ts_formatted: (.value.ts / 1000 | todate),
            open: (.value.open // false)
        })
    '

    # 2. Conditional Sorting Step
    if [[ $sort_by_path -eq 1 ]]; then
        # If sorting, apply sort_by to the array of objects
        jq_query+=' | sort_by(.path)'
    fi
    
    # 3. Final Output Formatting (Applied to each element in the array)
    jq_query+=' | .[] | 
        "ID: \( .id ) | Path: \( .path ) | Last Opened: \( .ts_formatted ) | Open: \( .open )"
    '
    
    # 4. Execute jq and format with column
    jq -r "$jq_query" "$config_file" | column -t -s '|'
}



```