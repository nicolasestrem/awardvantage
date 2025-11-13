<?php
/**
 * Import 38 Production Candidates
 * Best-Teacher Award #class25
 *
 * This script imports the 38 candidates from the CSV file
 *
 * Usage:
 *   docker exec awardvantage-wordpress-1 wp eval-file scripts/import-38-candidates.php --allow-root
 */

// Exit if not running in WP-CLI context
if (!defined('WP_CLI') && !defined('ABSPATH')) {
    exit('This script must be run via WP-CLI');
}

echo "===========================================\n";
echo "Importing 38 Production Candidates\n";
echo "Best-Teacher Award #class25\n";
echo "===========================================\n\n";

// Candidate data from Liste_DozentInnen_2025 (1).csv
$candidates = [
    ['first' => 'Alexander', 'last' => 'Bilgeri'],
    ['first' => 'Andreas', 'last' => 'Herrmann'],
    ['first' => 'Anjes', 'last' => 'Tjarks'],
    ['first' => 'Astrid', 'last' => 'Fontaine'],
    ['first' => 'Björn', 'last' => 'Bender'],
    ['first' => 'Christian', 'last' => 'Böllhoff'],
    ['first' => 'Christoph', 'last' => 'Weigler'],
    ['first' => 'Gunnar', 'last' => 'Froh'],
    ['first' => 'Hui', 'last' => 'Zhang'],
    ['first' => 'Jan Marco', 'last' => 'Leimeister'],
    ['first' => 'Johann', 'last' => 'Jungwirth'],
    ['first' => 'Judith', 'last' => 'Häberli'],
    ['first' => 'Jürgen', 'last' => 'Stackmann'],
    ['first' => 'Karolin', 'last' => 'Frankenberger'],
    ['first' => 'Katrin', 'last' => 'Habenschaden'],
    ['first' => 'Karsten', 'last' => 'Crede'],
    ['first' => 'Kerstin', 'last' => 'Wagner'],
    ['first' => 'Kurt', 'last' => 'Bauer'],
    ['first' => 'Lukas', 'last' => 'Neckermann'],
    ['first' => 'Maja', 'last' => 'Göpel'],
    ['first' => 'Matthias', 'last' => 'Ballweg'],
    ['first' => 'Melan', 'last' => 'Thuraiappah'],
    ['first' => 'Michael', 'last' => 'Barillère-Scholz'],
    ['first' => 'Nigell', 'last' => 'Storny'],
    ['first' => 'Nikolaus', 'last' => 'Lang'],
    ['first' => 'Oliver', 'last' => 'Wolff'],
    ['first' => 'Olga', 'last' => 'Nevska'],
    ['first' => 'Philipp', 'last' => 'Scharfenberger'],
    ['first' => 'Philipp', 'last' => 'Rode'],
    ['first' => 'Philipp', 'last' => 'Wetzel'],
    ['first' => 'Rolf', 'last' => 'Wüstenhagen'],
    ['first' => 'Sascha', 'last' => 'Meyer'],
    ['first' => 'Sylvia', 'last' => 'Lier'],
    ['first' => 'Timo', 'last' => 'Schneckenburger'],
    ['first' => 'Torsten', 'last' => 'Tomczak'],
    ['first' => 'Volker', 'last' => 'Hartmann'],
    ['first' => 'Wolfgang', 'last' => 'Jenewein'],
    ['first' => 'Zheng', 'last' => 'Han'],
];

$created = 0;
$failed = 0;

foreach ($candidates as $index => $candidate) {
    $full_name = trim($candidate['first'] . ' ' . $candidate['last']);
    $number = $index + 1;

    echo sprintf("[%d/38] Creating: %s...", $number, $full_name);

    // Create candidate post
    $post_data = [
        'post_title' => $full_name,
        'post_type' => 'mt_candidate',
        'post_status' => 'publish',
        'post_content' => '', // Will be filled with German description later
    ];

    $post_id = wp_insert_post($post_data, true);

    if (is_wp_error($post_id)) {
        echo " FAILED\n";
        echo "  Error: " . $post_id->get_error_message() . "\n";
        $failed++;
        continue;
    }

    // Add meta data - LinkedIn URL placeholder
    $first_normalized = strtolower(str_replace([' ', 'ü', 'ö', 'ä'], ['', 'u', 'o', 'a'], $candidate['first']));
    $last_normalized = strtolower(str_replace([' ', 'ü', 'ö', 'ä', 'ß'], ['', 'u', 'o', 'a', 'ss'], $candidate['last']));
    $linkedin_placeholder = sprintf('https://www.linkedin.com/in/%s-%s/', $first_normalized, $last_normalized);

    update_post_meta($post_id, '_mt_linkedin_url', $linkedin_placeholder);
    update_post_meta($post_id, '_mt_website_url', '');
    update_post_meta($post_id, '_mt_organization', ''); // Hidden but keeping for data integrity
    update_post_meta($post_id, '_mt_position', ''); // Hidden but keeping for data integrity
    update_post_meta($post_id, '_mt_overview', '');
    update_post_meta($post_id, '_mt_description_full', '');

    echo " SUCCESS (ID: $post_id)\n";
    $created++;
}

echo "\n";
echo "===========================================\n";
echo "Import Summary:\n";
echo "===========================================\n";
echo "Candidates created: $created\n";
echo "Failed imports:     $failed\n";
echo "\n";

// Verify count
$total_candidates = wp_count_posts('mt_candidate');
$published_count = $total_candidates->publish;

echo "Total published candidates in system: $published_count\n";

if ($published_count == 38) {
    echo "✓ Exactly 38 candidates as expected!\n";
} else {
    echo "✗ WARNING: Expected 38 candidates, but found $published_count\n";
}

echo "\n===========================================\n";
echo "Next Steps:\n";
echo "===========================================\n";
echo "1. Update LinkedIn URLs from Candidate list.pdf\n";
echo "2. Add German descriptions from Kandidaten_list.pdf\n";
echo "3. Download and upload candidate photos\n";
echo "\n";
echo "Import complete!\n";
echo "===========================================\n";
