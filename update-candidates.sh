#!/bin/bash

CSV_FILE="$1"
PHOTO_DIR="$2"

if [[ -z "$CSV_FILE" ]] || [[ -z "$PHOTO_DIR" ]]; then
    echo "Usage: $0 <csv_file> <photo_directory>"
    exit 1
fi

echo "=========================================="
echo " Updating Candidate Profiles"
echo "=========================================="
echo ""

# Counter for statistics
updated=0
failed=0

# Process CSV line by line
while IFS=',' read -r name linkedin_url photo_filename; do
    # Skip header
    if [[ "$name" == "name" ]]; then
        continue
    fi
    
    # Skip empty lines
    if [[ -z "$name" ]]; then
        continue
    fi
    
    echo "[INFO] Updating: $name"
    
    # Find candidate post ID by title (exact match)
    post_id=$(docker exec awardvantage_wpcli wp post list \
        --post_type=mt_candidate \
        --post_title="$name" \
        --field=ID \
        --format=csv \
        --allow-root 2>/dev/null | head -1)
    
    if [[ -z "$post_id" ]]; then
        echo "  [ERROR] Candidate not found: $name"
        ((failed++))
        continue
    fi
    
    echo "  Post ID: $post_id"
    
    # Update LinkedIn URL if provided
    if [[ -n "$linkedin_url" ]]; then
        docker exec awardvantage_wpcli wp post meta update "$post_id" linkedin_url "$linkedin_url" --allow-root >/dev/null 2>&1
        echo "  ✓ Updated LinkedIn URL"
    fi
    
    # Handle photo if provided
    if [[ -n "$photo_filename" ]]; then
        photo_path="${PHOTO_DIR}${photo_filename}"
        
        if [[ -f "$photo_path" ]]; then
            # Copy photo to WordPress uploads directory
            upload_dir="/var/www/html/wp-content/uploads/candidate-photos"
            docker exec awardvantage_wordpress mkdir -p "$upload_dir" 2>/dev/null
            docker cp "$photo_path" "awardvantage_wordpress:$upload_dir/${photo_filename}"
            
            # Set proper permissions
            docker exec awardvantage_wordpress chown www-data:www-data "$upload_dir/${photo_filename}"
            
            # Update photo URL in post meta
            photo_url="https://awardvantage.com/wp-content/uploads/candidate-photos/${photo_filename}"
            docker exec awardvantage_wpcli wp post meta update "$post_id" mt_photo_url "$photo_url" --allow-root >/dev/null 2>&1
            
            echo "  ✓ Updated photo: $photo_filename"
        else
            echo "  [WARN] Photo not found: $photo_path"
        fi
    fi
    
    ((updated++))
    echo ""
    
done < "$CSV_FILE"

echo "=========================================="
echo " Update Summary"
echo "=========================================="
echo "Candidates updated: $updated"
echo "Failed: $failed"
echo ""

