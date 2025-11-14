xmind() {
  local xmind_files=($(find . -maxdepth 1 -type f -name "*.xmind"))
  local num_files=${#xmind_files[@]}

  if [ "$num_files" -eq 0 ]; then
    echo "No .xmind files found in the current directory."
  elif [ "$num_files" -eq 1 ]; then
    echo "Opening ${xmind_files[0]}..."
    open "${xmind_files[0]}"
  else
    echo "Multiple .xmind files found:"
    for i in "${!xmind_files[@]}"; do
      echo "$((i+1))) ${xmind_files[$i]}"
    done

    local choice
    while true; do
      read -p "Enter the number of the file to open: " choice
      if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$num_files" ]; then
        echo "Opening ${xmind_files[$((choice-1))]}..."
        open "${xmind_files[$((choice-1))]}"
        break
      else
        echo "Invalid choice. Please enter a number between 1 and $num_files."
      fi
    done
  fi
}