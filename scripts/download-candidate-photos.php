<?php
/**
 * Download and Attach Candidate Photos
 * Best-Teacher Award #class25
 *
 * This script downloads candidate photos from stored URLs and sets them as featured images
 *
 * Usage:
 *   docker exec awardvantage-wordpress-1 wp eval-file scripts/download-candidate-photos.php --allow-root
 */

// Exit if not running in WP-CLI context
if (!defined('WP_CLI') && !defined('ABSPATH')) {
    exit('This script must be run via WP-CLI');
}

// Load WordPress media functions
require_once(ABSPATH . 'wp-admin/includes/media.php');
require_once(ABSPATH . 'wp-admin/includes/file.php');
require_once(ABSPATH . 'wp-admin/includes/image.php');

echo "===========================================\n";
echo "Downloading Candidate Photos\n";
echo "Best-Teacher Award #class25\n";
echo "===========================================\n\n";

// Get all candidates with photo URLs
$candidates = get_posts([
    'post_type' => 'mt_candidate',
    'posts_per_page' => -1,
    'post_status' => 'publish',
    'meta_query' => [
        [
            'key' => '_mt_photo_url',
            'compare' => 'EXISTS'
        ]
    ]
]);

$downloaded = 0;
$failed = 0;
$skipped = 0;

foreach ($candidates as $candidate) {
    $name = $candidate->post_title;
    $photo_url = get_post_meta($candidate->ID, '_mt_photo_url', true);

    if (empty($photo_url)) {
        echo sprintf("[%d] %s: SKIPPED - No photo URL\n", $candidate->ID, $name);
        $skipped++;
        continue;
    }

    // Check if candidate already has a featured image
    if (has_post_thumbnail($candidate->ID)) {
        echo sprintf("[%d] %s: SKIPPED - Already has photo\n", $candidate->ID, $name);
        $skipped++;
        continue;
    }

    echo sprintf("[%d] %s: Downloading from %s...\n", $candidate->ID, $name, $photo_url);

    // Download file to temp location
    $tmp_file = download_url($photo_url);

    if (is_wp_error($tmp_file)) {
        echo sprintf("    FAILED - %s\n", $tmp_file->get_error_message());
        $failed++;
        continue;
    }

    // Get file extension from URL
    $file_ext = pathinfo(parse_url($photo_url, PHP_URL_PATH), PATHINFO_EXTENSION);
    if (empty($file_ext)) {
        $file_ext = 'jpg'; // Default to jpg
    }

    // Prepare file array for media_handle_sideload
    $file_array = [
        'name' => sanitize_file_name($name) . '.' . $file_ext,
        'tmp_name' => $tmp_file
    ];

    // Upload to media library
    $attachment_id = media_handle_sideload($file_array, $candidate->ID, $name);

    // Clean up temp file
    if (file_exists($tmp_file)) {
        @unlink($tmp_file);
    }

    if (is_wp_error($attachment_id)) {
        echo sprintf("    FAILED - %s\n", $attachment_id->get_error_message());
        $failed++;
        continue;
    }

    // Set as featured image
    set_post_thumbnail($candidate->ID, $attachment_id);

    echo sprintf("    SUCCESS - Uploaded as attachment ID %d\n", $attachment_id);
    $downloaded++;
}

echo "\n";
echo "===========================================\n";
echo "Download Summary:\n";
echo "===========================================\n";
echo "Photos downloaded: $downloaded\n";
echo "Photos skipped: $skipped\n";
echo "Failed downloads: $failed\n";
echo "\n";

// List candidates without photos
$candidates_without_photos = get_posts([
    'post_type' => 'mt_candidate',
    'posts_per_page' => -1,
    'post_status' => 'publish',
    'meta_query' => [
        [
            'relation' => 'OR',
            [
                'key' => '_thumbnail_id',
                'compare' => 'NOT EXISTS'
            ],
            [
                'key' => '_thumbnail_id',
                'value' => '',
                'compare' => '='
            ]
        ]
    ]
]);

if (!empty($candidates_without_photos)) {
    echo "===========================================\n";
    echo "Candidates without photos (" . count($candidates_without_photos) . "):\n";
    echo "===========================================\n";
    foreach ($candidates_without_photos as $candidate) {
        $photo_url = get_post_meta($candidate->ID, '_mt_photo_url', true);
        $status = empty($photo_url) ? 'No URL in PDF' : 'Has URL';
        echo sprintf("[%d] %s - %s\n", $candidate->ID, $candidate->post_title, $status);
    }
    echo "\n";
}

echo "===========================================\n";
echo "Photo download complete!\n";
echo "===========================================\n";
