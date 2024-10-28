#!/bin/bash

community_file="community_strings.txt"

echo "Current SNMP community strings:"
if [[ -f "$community_file" ]]; then
    cat "$community_file"
else
    echo "No community strings found."
fi

echo
echo "Choose an option:"
echo "1. Add a new community string"
echo "2. Overwrite all community strings"
read -p "Enter your choice (1 or 2): " choice

if [[ "$choice" == "1" ]]; then
    read -p "Enter the new SNMP community string to add: " new_community
    echo "$new_community" >> "$community_file"
    echo "Community string '$new_community' added."

elif [[ "$choice" == "2" ]]; then
    echo "Enter new community strings, one per line. Press Ctrl+D when finished:"
    cat > "$community_file"
    echo "Community strings have been overwritten."

else
    echo "Invalid choice. Exiting."
    exit 1
fi

echo
echo "Updated SNMP community strings:"
cat "$community_file"
