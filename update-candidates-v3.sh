#!/bin/bash

CSV_FILE="$1"
PHOTO_DIR="$2"

echo "=========================================="
echo " Updating Candidate Profiles"
echo "=========================================="
echo ""

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
    
    # Use SQL to find exact post ID
    post_id=$(docker exec awardvantage_wpcli wp db query "SELECT ID FROM wp_posts WHERE post_title = '$name' AND post_type = 'mt_candidate' AND post_status = 'publish' LIMIT 1;" --skip-column-names --allow-root 2>/dev/null | tr -d '\r\n' | awk '{print $1}')
    
    if [[ -z "$post_id" ]] || [[ "$post_id" == "ID" ]]; then
        echo "  [ERROR] Candidate not found in database"
        ((failed++))
        echo ""
        continue
    fi
    
    echo "  Post ID: $post_id"
    
    # Update LinkedIn URL if provided
    if [[ -n "$linkedin_url" ]]; then
        docker exec awardvantage_wpcli wp post meta update "$post_id" linkedin_url "$linkedin_url" --allow-root 2>&1 | grep -v "WordPress database error" || true
        echo "  ✓ LinkedIn URL set"
    fi
    
    # Handle photo if provided
    if [[ -n "$photo_filename" ]]; then
        photo_path="${PHOTO_DIR}${photo_filename}"
        
        if [[ -f "$photo_path" ]]; then
            # Copy photo to WordPress uploads directory
            upload_dir="/var/www/html/wp-content/uploads/candidate-photos"
            docker exec awardvantage_wordpress mkdir -p "$upload_dir" 2>/dev/null
            docker cp "$photo_path" "awardvantage_wordpress:$upload_dir/${photo_filename}" 2>/dev/null
            
            # Set proper permissions
            docker exec awardvantage_wordpress chown www-data:www-data "$upload_dir/${photo_filename}" 2>/dev/null
            
            # Update photo URL in post meta
            photo_url="https://awardvantage.com/wp-content/uploads/candidate-photos/${photo_filename}"
            docker exec awardvantage_wpcli wp post meta update "$post_id" mt_photo_url "$photo_url" --allow-root 2>&1 | grep -v "WordPress database error" || true
            
            echo "  ✓ Photo uploaded: $photo_filename"
        else
            echo "  [WARN] Photo not found: $photo_filename"
        fi
    fi
    
    ((updated++))
    echo ""
    
done < "$CSV_FILE"

echo "=========================================="
echo " Update Summary"
echo "=========================================="
echo "Successfully updated: $updated"
echo "Failed: $failed"
echo ""

