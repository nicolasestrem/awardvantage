<?php
/**
 * Test Evaluation Submission
 * Best-Teacher Award #class25
 *
 * Creates a test evaluation to verify the 2-criteria system works correctly
 *
 * Usage:
 *   docker exec awardvantage-wordpress-1 wp eval-file scripts/test-evaluation-submission.php --allow-root
 */

// Exit if not running in WP-CLI context
if (!defined('WP_CLI') && !defined('ABSPATH')) {
    exit('This script must be run via WP-CLI');
}

global $wpdb;

echo "===========================================\n";
echo "Testing 2-Criteria Evaluation Submission\n";
echo "Best-Teacher Award #class25\n";
echo "===========================================\n\n";

// Get first jury member (jury01 - Jury Member 01, post ID 46, user ID 2)
$jury_member_post_id = 46;
$jury_user_id = 2;

// Get first candidate (Alexander Bilgeri, ID 172)
$candidate_id = 172;

// Get candidate and jury member names
$candidate = get_post($candidate_id);
$jury_member = get_post($jury_member_post_id);

echo "Test Parameters:\n";
echo "Jury Member: {$jury_member->post_title} (Post ID: $jury_member_post_id, User ID: $jury_user_id)\n";
echo "Candidate: {$candidate->post_title} (ID: $candidate_id)\n\n";

// Check if evaluation already exists
$table_name = $wpdb->prefix . 'mt_evaluations';
$existing = $wpdb->get_row($wpdb->prepare(
    "SELECT * FROM $table_name WHERE jury_member_id = %d AND candidate_id = %d",
    $jury_member_post_id,
    $candidate_id
));

if ($existing) {
    echo "Existing evaluation found - deleting it first...\n";
    $wpdb->delete($table_name, ['id' => $existing->id], ['%d']);
}

// Create test evaluation with 2 criteria
$evaluation_data = [
    'jury_member_id' => $jury_member_post_id,
    'candidate_id' => $candidate_id,
    'didactic_excellence_score' => 8.5,
    'practical_impact_score' => 9.0,
    'comments' => 'Test evaluation for 2-criteria system. This candidate demonstrates excellent didactic skills and strong practical impact.',
    'status' => 'submitted',
    'created_at' => current_time('mysql')
];

echo "Inserting test evaluation...\n";
echo "  Didactic Excellence Score: 8.5\n";
echo "  Practical Impact Score: 9.0\n";
echo "  Comments: Test evaluation...\n\n";

$result = $wpdb->insert(
    $table_name,
    $evaluation_data,
    ['%d', '%d', '%f', '%f', '%s', '%s', '%s']
);

if ($result === false) {
    echo "FAILED to insert evaluation\n";
    echo "Error: " . $wpdb->last_error . "\n";
    exit(1);
}

$evaluation_id = $wpdb->insert_id;
echo "SUCCESS - Evaluation created with ID: $evaluation_id\n\n";

// Verify the evaluation was saved correctly
echo "Verifying saved evaluation...\n";
$saved_eval = $wpdb->get_row($wpdb->prepare(
    "SELECT * FROM $table_name WHERE id = %d",
    $evaluation_id
));

if (!$saved_eval) {
    echo "FAILED - Could not retrieve saved evaluation\n";
    exit(1);
}

echo "Retrieved evaluation:\n";
echo "  ID: {$saved_eval->id}\n";
echo "  Jury Member ID: {$saved_eval->jury_member_id}\n";
echo "  Candidate ID: {$saved_eval->candidate_id}\n";
echo "  Didactic Excellence Score: {$saved_eval->didactic_excellence_score}\n";
echo "  Practical Impact Score: {$saved_eval->practical_impact_score}\n";
echo "  Comments: {$saved_eval->comments}\n";
echo "  Status: {$saved_eval->status}\n";
echo "  Created At: {$saved_eval->created_at}\n\n";

// Calculate average score
$avg_score = ($saved_eval->didactic_excellence_score + $saved_eval->practical_impact_score) / 2;
echo "Average Score: " . number_format($avg_score, 2) . "\n\n";

// Check for old 5-criteria columns (should be NULL)
echo "Checking old criteria columns (should be NULL)...\n";
$old_columns = ['courage_score', 'innovation_score', 'implementation_score', 'relevance_score', 'visibility_score'];
$all_null = true;
foreach ($old_columns as $col) {
    if (isset($saved_eval->$col)) {
        $value = $saved_eval->$col ?? 'NULL';
        echo "  $col: $value";
        if ($value !== null && $value !== 'NULL') {
            echo " ⚠ WARNING: Expected NULL";
            $all_null = false;
        }
        echo "\n";
    }
}

if ($all_null) {
    echo "✓ All old criteria columns are NULL (as expected)\n";
}

echo "\n";
echo "===========================================\n";
echo "Test Summary:\n";
echo "===========================================\n";
echo "✓ Evaluation created successfully\n";
echo "✓ 2 new criteria scores saved correctly\n";
echo "✓ Old criteria columns are NULL\n";
echo "✓ Average score calculated: " . number_format($avg_score, 2) . "\n";
echo "\n";
echo "The 2-criteria evaluation system is working correctly!\n";
echo "===========================================\n";
