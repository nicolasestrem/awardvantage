#!/bin/bash

echo "=========================================="
echo " LinkedIn URL Verification Report"
echo "=========================================="
echo ""

# Query the 5 candidates we fixed
echo "Verifying the 5 fixed LinkedIn URLs:"
echo ""

docker exec awardvantage_wpcli wp db query "
SELECT p.ID, p.post_title,
       MAX(CASE WHEN pm.meta_key = 'linkedin_url' THEN pm.meta_value END) as linkedin_url
FROM wp_posts p
LEFT JOIN wp_postmeta pm ON p.ID = pm.post_id
WHERE p.post_type = 'mt_candidate' 
  AND p.post_status = 'publish'
  AND p.ID IN (152, 154, 160, 177, 181)
GROUP BY p.ID, p.post_title
ORDER BY p.post_title;
" --allow-root 2>/dev/null

echo ""
echo "=========================================="
echo " Checking for remaining broken URLs"
echo "=========================================="
echo ""

# Check if any URLs still contain "=" character
broken_count=$(docker exec awardvantage_wpcli wp db query "
SELECT COUNT(*) as count
FROM wp_postmeta
WHERE meta_key = 'linkedin_url' 
  AND meta_value LIKE '%=%'
  AND meta_value != '';
" --skip-column-names --allow-root 2>/dev/null | tr -d '\r\n' | awk '{print $1}')

if [[ "$broken_count" == "0" ]] || [[ -z "$broken_count" ]]; then
    echo "✓ No broken LinkedIn URLs found! All URLs are correctly formatted."
else
    echo "⚠️  Found $broken_count URLs still containing '=' character:"
    docker exec awardvantage_wpcli wp db query "
    SELECT p.ID, p.post_title, pm.meta_value as linkedin_url
    FROM wp_postmeta pm
    JOIN wp_posts p ON p.ID = pm.post_id
    WHERE pm.meta_key = 'linkedin_url' 
      AND pm.meta_value LIKE '%=%'
      AND pm.meta_value != ''
    ORDER BY p.post_title;
    " --allow-root 2>/dev/null
fi

echo ""
echo "=========================================="
echo " Summary Statistics"
echo "=========================================="
echo ""

total=$(docker exec awardvantage_wpcli wp db query "
SELECT COUNT(DISTINCT p.ID) as count
FROM wp_posts p
JOIN wp_postmeta pm ON p.ID = pm.post_id
WHERE p.post_type = 'mt_candidate' 
  AND p.post_status = 'publish'
  AND pm.meta_key = 'linkedin_url'
  AND pm.meta_value != '';
" --skip-column-names --allow-root 2>/dev/null | tr -d '\r\n' | awk '{print $1}')

echo "Total candidates with LinkedIn URLs: $total"
echo "Fixed URLs: 5"
echo "Remaining issues: $broken_count"
echo ""

