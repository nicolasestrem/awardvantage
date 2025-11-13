<?php
/**
 * Create Jury Assignments
 * Best-Teacher Award #class25
 *
 * Assigns all candidates to all jury members (matrix assignment)
 *
 * Usage:
 *   docker exec awardvantage-wordpress-1 wp eval-file scripts/create-jury-assignments.php --allow-root
 */

// Exit if not running in WP-CLI context
if (!defined('WP_CLI') && !defined('ABSPATH')) {
    exit('This script must be run via WP-CLI');
}

// Load shared configuration
require_once __DIR__ . '/config.php';

global $wpdb;

echo "===========================================\n";
echo "Creating Jury Assignments\n";
echo "Best-Teacher Award #class25\n";
echo "===========================================\n\n";

// Get all candidates
$candidates = get_posts([
    'post_type' => 'mt_candidate',
    'posts_per_page' => -1,
    'post_status' => 'publish',
    'orderby' => 'ID',
    'order' => 'ASC'
]);

// Get all jury members
$jury_members = get_posts([
    'post_type' => 'mt_jury_member',
    'posts_per_page' => -1,
    'post_status' => 'publish',
    'orderby' => 'ID',
    'order' => 'ASC'
]);

echo sprintf("Found %d candidates\n", count($candidates));
echo sprintf("Found %d jury members\n\n", count($jury_members));

$table_name = $wpdb->prefix . 'mt_jury_assignments';
// Escape table name for safe SQL usage
$safe_table_name = esc_sql($table_name);
$created = 0;
$skipped = 0;

foreach ($jury_members as $jury_member) {
    $jury_member_id = $jury_member->ID;
    $jury_name = $jury_member->post_title;

    echo sprintf("Assigning candidates to %s (ID: %d)...\n", $jury_name, $jury_member_id);

    foreach ($candidates as $candidate) {
        $candidate_id = $candidate->ID;

        // Check if assignment already exists
        $exists = $wpdb->get_var($wpdb->prepare(
            "SELECT id FROM $safe_table_name WHERE jury_member_id = %d AND candidate_id = %d",
            $jury_member_id,
            $candidate_id
        ));

        if ($exists) {
            $skipped++;
            continue;
        }

        // Create assignment
        $result = $wpdb->insert(
            $table_name,
            [
                'jury_member_id' => $jury_member_id,
                'candidate_id' => $candidate_id,
                'assigned_at' => current_time('mysql')
            ],
            ['%d', '%d', '%s']
        );

        if ($result) {
            $created++;
        }
    }
}

echo "\n";
echo "===========================================\n";
echo "Assignment Summary:\n";
echo "===========================================\n";
echo "Assignments created: $created\n";
echo "Assignments skipped: $skipped\n";
echo sprintf("Expected: %d (%d jury × %d candidates)\n", EXPECTED_ASSIGNMENTS, JURY_MEMBER_COUNT, CANDIDATE_COUNT);
echo "\n";

// Verify total count
$total = $wpdb->get_var("SELECT COUNT(*) FROM $safe_table_name");
echo "Total assignments in database: $total\n";

echo "\n===========================================\n";
echo "Assignment creation complete!\n";
echo "===========================================\n";
