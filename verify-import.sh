#!/bin/bash

echo "=========================================="
echo " Import Verification Report"
echo "=========================================="
echo ""

# Get all candidates with their metadata
candidates_with_linkedin=0
candidates_without_linkedin=0
candidates_with_photos=0
candidates_without_photos=0

declare -a candidates_missing_photos
declare -a candidates_missing_linkedin

while IFS=$'\t' read -r id title linkedin_url photo_url; do
    if [[ "$id" == "ID" ]]; then
        continue
    fi
    
    # Check LinkedIn URL
    if [[ -n "$linkedin_url" ]] && [[ "$linkedin_url" != "NULL" ]]; then
        ((candidates_with_linkedin++))
    else
        ((candidates_without_linkedin++))
        candidates_missing_linkedin+=("$title")
    fi
    
    # Check Photo URL
    if [[ -n "$photo_url" ]] && [[ "$photo_url" != "NULL" ]]; then
        ((candidates_with_photos++))
    else
        ((candidates_without_photos++))
        candidates_missing_photos+=("$title")
    fi
    
done < <(docker exec awardvantage_wpcli wp db query "
    SELECT p.ID, p.post_title,
           MAX(CASE WHEN pm.meta_key = 'linkedin_url' THEN pm.meta_value END) as linkedin_url,
           MAX(CASE WHEN pm.meta_key = 'mt_photo_url' THEN pm.meta_value END) as photo_url
    FROM wp_posts p
    LEFT JOIN wp_postmeta pm ON p.ID = pm.post_id
    WHERE p.post_type = 'mt_candidate' AND p.post_status = 'publish'
    GROUP BY p.ID, p.post_title
    ORDER BY p.post_title;
" --skip-column-names --allow-root 2>/dev/null)

echo "📊 Statistics:"
echo "  Total candidates: $((candidates_with_linkedin + candidates_without_linkedin))"
echo ""
echo "  Candidates WITH LinkedIn URLs: $candidates_with_linkedin"
echo "  Candidates WITHOUT LinkedIn URLs: $candidates_without_linkedin"
echo ""
echo "  Candidates WITH Photos: $candidates_with_photos"
echo "  Candidates WITHOUT Photos: $candidates_without_photos"
echo ""

if [[ ${#candidates_missing_linkedin[@]} -gt 0 ]]; then
    echo "⚠️  Candidates Missing LinkedIn URLs:"
    for candidate in "${candidates_missing_linkedin[@]}"; do
        echo "  - $candidate"
    done
    echo ""
fi

if [[ ${#candidates_missing_photos[@]} -gt 0 ]]; then
    echo "📷 Candidates Missing Photos:"
    for candidate in "${candidates_missing_photos[@]}"; do
        echo "  - $candidate"
    done
    echo ""
fi

echo "=========================================="
echo " Photo Files Summary"
echo "=========================================="
echo ""
echo "Photos in uploads directory:"
docker exec awardvantage_wordpress ls -1 /var/www/html/wp-content/uploads/candidate-photos/ 2>/dev/null | wc -l
echo ""

echo "=========================================="
echo " Import Complete!"
echo "=========================================="

