#!/bin/bash

# Function to convert name to filename format (remove spaces, umlauts, special chars)
name_to_filename() {
    local name="$1"
    # Remove spaces
    name="${name// /}"
    # Convert umlauts
    name="${name//ä/ae}"
    name="${name//ö/oe}"
    name="${name//ü/ue}"
    name="${name//Ä/Ae}"
    name="${name//Ö/Oe}"
    name="${name//Ü/Ue}"
    name="${name//ß/ss}"
    # Remove accents and special characters (simplified)
    name="${name//é/e}"
    name="${name//è/e}"
    name="${name//à/a}"
    name="${name//ò/o}"
    echo "$name"
}

echo "=== Matching Photos to Candidates ==="
echo ""

# Read CSV and find candidates without photos
while IFS=',' read -r name linkedin_url photo_filename; do
    # Skip header
    if [[ "$name" == "name" ]]; then
        continue
    fi
    
    # Skip empty lines
    if [[ -z "$name" ]]; then
        continue
    fi
    
    # Check if photo_filename is empty
    if [[ -z "$photo_filename" ]]; then
        echo "Candidate: $name"
        
        # Convert name to expected filename format
        base_filename=$(name_to_filename "$name")
        echo "  Expected base: $base_filename"
        
        # Check for matches in both directories
        found=0
        for ext in jpg jpeg png webp; do
            for dir in "private/candidate-photos" "candidate-photos"; do
                file="/mnt/ssd1tb/dietpi_userdata/docker-files/awardvantage/$dir/${base_filename}.${ext}"
                if [[ -f "$file" ]]; then
                    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
                    echo "  ✓ FOUND: $dir/${base_filename}.${ext} (${size} bytes)"
                    found=1
                fi
            done
        done
        
        if [[ $found -eq 0 ]]; then
            echo "  ✗ NO MATCH FOUND"
        fi
        echo ""
    fi
done < candidates.csv

echo ""
echo "=== Additional Photos Not in CSV ==="
echo ""

# List all photos in public directory
for photo in candidate-photos/*; do
    if [[ -f "$photo" ]]; then
        filename=$(basename "$photo")
        # Check if this photo is referenced in CSV
        if ! grep -q "$filename" candidates.csv; then
            size=$(stat -f%z "$photo" 2>/dev/null || stat -c%s "$photo" 2>/dev/null)
            echo "  $filename (${size} bytes)"
        fi
    fi
done

