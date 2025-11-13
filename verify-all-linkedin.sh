#!/bin/bash

echo "=========================================="
echo " LinkedIn URL Verification - Full Scan"
echo "=========================================="
echo ""

# Check for any remaining mismatches or corrupted _mt_linkedin_url
echo "Checking for corrupted _mt_linkedin_url fields..."
corrupted=$(docker exec awardvantage_wpcli wp db query "
SELECT p.ID, p.post_title,
       MAX(CASE WHEN pm.meta_key = 'linkedin_url' THEN pm.meta_value END) as linkedin_url,
       MAX(CASE WHEN pm.meta_key = '_mt_linkedin_url' THEN pm.meta_value END) as _mt_linkedin_url
FROM wp_posts p
LEFT JOIN wp_postmeta pm ON p.ID = pm.post_id
WHERE p.post_type = 'mt_candidate' AND p.post_status = 'publish'
GROUP BY p.ID, p.post_title
HAVING (linkedin_url IS NOT NULL AND linkedin_url != '') 
   AND (_mt_linkedin_url IS NULL OR _mt_linkedin_url = '' OR _mt_linkedin_url NOT LIKE 'http%')
ORDER BY p.post_title;
" --allow-root 2>/dev/null)

if [ -z "$corrupted" ] || [ "$corrupted" = "ID	post_title	linkedin_url	_mt_linkedin_url" ]; then
    echo "✓ No corrupted _mt_linkedin_url fields found!"
else
    echo "⚠️  Still found corrupted fields:"
    echo "$corrupted"
fi

echo ""
echo "=========================================="
echo " Checking for URL Mismatches"
echo "=========================================="
echo ""

# Check if linkedin_url and _mt_linkedin_url match for all candidates
mismatches=$(docker exec awardvantage_wpcli wp db query "
SELECT p.ID, p.post_title,
       MAX(CASE WHEN pm.meta_key = 'linkedin_url' THEN pm.meta_value END) as linkedin_url,
       MAX(CASE WHEN pm.meta_key = '_mt_linkedin_url' THEN pm.meta_value END) as _mt_linkedin_url
FROM wp_posts p
LEFT JOIN wp_postmeta pm ON p.ID = pm.post_id
WHERE p.post_type = 'mt_candidate' AND p.post_status = 'publish'
GROUP BY p.ID, p.post_title
HAVING linkedin_url IS NOT NULL 
   AND linkedin_url != ''
   AND _mt_linkedin_url IS NOT NULL
   AND _mt_linkedin_url != ''
   AND linkedin_url != _mt_linkedin_url
ORDER BY p.post_title;
" --allow-root 2>/dev/null)

if [ -z "$mismatches" ] || [ "$mismatches" = "ID	post_title	linkedin_url	_mt_linkedin_url" ]; then
    echo "✓ All LinkedIn URLs match between fields!"
else
    echo "⚠️  Found mismatches:"
    echo "$mismatches"
fi

echo ""
echo "=========================================="
echo " Summary Statistics"
echo "=========================================="
echo ""

# Count total candidates with LinkedIn URLs
total=$(docker exec awardvantage_wpcli wp db query "
SELECT COUNT(DISTINCT p.ID) as count
FROM wp_posts p
INNER JOIN wp_postmeta pm ON p.ID = pm.post_id
WHERE p.post_type = 'mt_candidate' 
  AND p.post_status = 'publish'
  AND pm.meta_key = 'linkedin_url'
  AND pm.meta_value != '';
" --skip-column-names --allow-root 2>/dev/null | tr -d '\r\n' | awk '{print $1}')

# Count candidates with valid _mt_linkedin_url
valid_mt=$(docker exec awardvantage_wpcli wp db query "
SELECT COUNT(DISTINCT p.ID) as count
FROM wp_posts p
INNER JOIN wp_postmeta pm ON p.ID = pm.post_id
WHERE p.post_type = 'mt_candidate' 
  AND p.post_status = 'publish'
  AND pm.meta_key = '_mt_linkedin_url'
  AND pm.meta_value LIKE 'http%';
" --skip-column-names --allow-root 2>/dev/null | tr -d '\r\n' | awk '{print $1}')

echo "Total candidates with linkedin_url: $total"
echo "Candidates with valid _mt_linkedin_url: $valid_mt"
echo ""

if [ "$total" = "$valid_mt" ]; then
    echo "✓ All candidates have matching, valid LinkedIn URLs!"
    echo "✓ Frontend should now display LinkedIn links correctly"
else
    echo "⚠️  Some candidates may still have issues"
fi

echo ""

