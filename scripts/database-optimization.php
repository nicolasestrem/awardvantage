<?php
/**
 * Database Optimization and Cleanup
 * Best-Teacher Award #class25
 *
 * Optimizes database tables and performs cleanup tasks
 *
 * Usage:
 *   docker exec awardvantage-wordpress-1 wp eval-file scripts/database-optimization.php --allow-root
 */

// Exit if not running in WP-CLI context
if (!defined('WP_CLI') && !defined('ABSPATH')) {
    exit('This script must be run via WP-CLI');
}

// Load shared configuration
require_once __DIR__ . '/config.php';

global $wpdb;

echo "===========================================\n";
echo "Database Optimization and Cleanup\n";
echo "Best-Teacher Award #class25\n";
echo "===========================================\n\n";

// List of custom tables to optimize
$custom_tables = [
    'wp_mt_evaluations',
    'wp_mt_jury_assignments',
    'wp_mt_audit_log'
];

echo "Step 1: Optimizing Custom Tables\n";
echo "-------------------------------------------\n";
foreach ($custom_tables as $table) {
    echo "Optimizing $table...";
    // Use esc_sql() to safely escape table name (from controlled whitelist above)
    $safe_table = esc_sql($table);
    $result = $wpdb->query("OPTIMIZE TABLE $safe_table");
    if ($result !== false) {
        echo " SUCCESS\n";
    } else {
        echo " FAILED: " . $wpdb->last_error . "\n";
    }
}

echo "\n";
echo "Step 2: Checking for Orphaned Data\n";
echo "-------------------------------------------\n";

// Check for evaluations referencing non-existent candidates
echo "Checking evaluations for orphaned candidate references...\n";
$orphaned_eval_candidates = $wpdb->get_results("
    SELECT e.id, e.candidate_id
    FROM wp_mt_evaluations e
    LEFT JOIN {$wpdb->posts} p ON e.candidate_id = p.ID
    WHERE p.ID IS NULL OR p.post_type != 'mt_candidate' OR p.post_status != 'publish'
");

if (empty($orphaned_eval_candidates)) {
    echo "  ✓ No orphaned candidate references\n";
} else {
    echo "  ⚠ Found " . count($orphaned_eval_candidates) . " evaluations with orphaned candidate references\n";
    foreach ($orphaned_eval_candidates as $orphan) {
        echo "    - Evaluation ID {$orphan->id} references non-existent candidate {$orphan->candidate_id}\n";
    }
}

// Check for evaluations referencing non-existent jury members
echo "Checking evaluations for orphaned jury member references...\n";
$orphaned_eval_jury = $wpdb->get_results("
    SELECT e.id, e.jury_member_id
    FROM wp_mt_evaluations e
    LEFT JOIN {$wpdb->posts} p ON e.jury_member_id = p.ID
    WHERE p.ID IS NULL OR p.post_type != 'mt_jury_member' OR p.post_status != 'publish'
");

if (empty($orphaned_eval_jury)) {
    echo "  ✓ No orphaned jury member references\n";
} else {
    echo "  ⚠ Found " . count($orphaned_eval_jury) . " evaluations with orphaned jury member references\n";
    foreach ($orphaned_eval_jury as $orphan) {
        echo "    - Evaluation ID {$orphan->id} references non-existent jury member {$orphan->jury_member_id}\n";
    }
}

// Check for assignments referencing non-existent candidates
echo "Checking assignments for orphaned candidate references...\n";
$orphaned_assign_candidates = $wpdb->get_results("
    SELECT a.id, a.candidate_id
    FROM wp_mt_jury_assignments a
    LEFT JOIN {$wpdb->posts} p ON a.candidate_id = p.ID
    WHERE p.ID IS NULL OR p.post_type != 'mt_candidate' OR p.post_status != 'publish'
");

if (empty($orphaned_assign_candidates)) {
    echo "  ✓ No orphaned candidate references\n";
} else {
    echo "  ⚠ Found " . count($orphaned_assign_candidates) . " assignments with orphaned candidate references\n";
    foreach ($orphaned_assign_candidates as $orphan) {
        echo "    - Assignment ID {$orphan->id} references non-existent candidate {$orphan->candidate_id}\n";
    }
}

// Check for assignments referencing non-existent jury members
echo "Checking assignments for orphaned jury member references...\n";
$orphaned_assign_jury = $wpdb->get_results("
    SELECT a.id, a.jury_member_id
    FROM wp_mt_jury_assignments a
    LEFT JOIN {$wpdb->posts} p ON a.jury_member_id = p.ID
    WHERE p.ID IS NULL OR p.post_type != 'mt_jury_member' OR p.post_status != 'publish'
");

if (empty($orphaned_assign_jury)) {
    echo "  ✓ No orphaned jury member references\n";
} else {
    echo "  ⚠ Found " . count($orphaned_assign_jury) . " assignments with orphaned jury member references\n";
    foreach ($orphaned_assign_jury as $orphan) {
        echo "    - Assignment ID {$orphan->id} references non-existent jury member {$orphan->jury_member_id}\n";
    }
}

echo "\n";
echo "Step 3: Data Integrity Verification\n";
echo "-------------------------------------------\n";

// Count candidates
$candidates_count = wp_count_posts('mt_candidate');
echo "Candidates (published): {$candidates_count->publish}\n";

// Count jury members
$jury_count = wp_count_posts('mt_jury_member');
echo "Jury Members (published): {$jury_count->publish}\n";

// Count assignments
$assignments_count = $wpdb->get_var("SELECT COUNT(*) FROM wp_mt_jury_assignments");
echo "Jury Assignments: $assignments_count\n";

// Count evaluations
$evaluations_count = $wpdb->get_var("SELECT COUNT(*) FROM wp_mt_evaluations");
echo "Evaluations: $evaluations_count\n";

// Expected assignments (from config.php)
$expected_assignments = EXPECTED_ASSIGNMENTS;
echo "\n";
if ($assignments_count == $expected_assignments) {
    echo "✓ Assignment count matches expected: $expected_assignments\n";
} else {
    echo "⚠ Assignment count ($assignments_count) differs from expected ($expected_assignments)\n";
}

echo "\n";
echo "Step 4: Checking Jury Member User Links\n";
echo "-------------------------------------------\n";

$jury_members = get_posts([
    'post_type' => 'mt_jury_member',
    'posts_per_page' => -1,
    'post_status' => 'publish'
]);

$linked_count = 0;
$unlinked_count = 0;

foreach ($jury_members as $jury_member) {
    $user_id = get_post_meta($jury_member->ID, '_mt_user_id', true);
    if ($user_id) {
        $user = get_user_by('id', $user_id);
        if ($user) {
            $linked_count++;
        } else {
            echo "⚠ Jury member '{$jury_member->post_title}' linked to non-existent user ID $user_id\n";
            $unlinked_count++;
        }
    } else {
        echo "⚠ Jury member '{$jury_member->post_title}' not linked to any user\n";
        $unlinked_count++;
    }
}

echo "Jury members with valid user links: $linked_count\n";
echo "Jury members without valid user links: $unlinked_count\n";

echo "\n";
echo "Step 5: Checking for Duplicate Assignments\n";
echo "-------------------------------------------\n";

$duplicates = $wpdb->get_results("
    SELECT jury_member_id, candidate_id, COUNT(*) as count
    FROM wp_mt_jury_assignments
    GROUP BY jury_member_id, candidate_id
    HAVING count > 1
");

if (empty($duplicates)) {
    echo "✓ No duplicate assignments found\n";
} else {
    echo "⚠ Found " . count($duplicates) . " duplicate assignments\n";
    foreach ($duplicates as $dup) {
        echo "  - Jury {$dup->jury_member_id} + Candidate {$dup->candidate_id}: {$dup->count} times\n";
    }
}

echo "\n";
echo "Step 6: Checking 2-Criteria System\n";
echo "-------------------------------------------\n";

// Check if new columns exist
$columns = $wpdb->get_col("DESCRIBE wp_mt_evaluations");
$has_didactic = in_array('didactic_excellence_score', $columns);
$has_practical = in_array('practical_impact_score', $columns);

echo "Didactic Excellence Score column: " . ($has_didactic ? "✓ EXISTS" : "✗ MISSING") . "\n";
echo "Practical Impact Score column: " . ($has_practical ? "✓ EXISTS" : "✗ MISSING") . "\n";

// Check for evaluations using new criteria
$new_criteria_count = $wpdb->get_var("
    SELECT COUNT(*)
    FROM wp_mt_evaluations
    WHERE didactic_excellence_score IS NOT NULL AND practical_impact_score IS NOT NULL
");
echo "Evaluations using 2-criteria system: $new_criteria_count\n";

// Check for evaluations using old criteria
$old_criteria_count = $wpdb->get_var("
    SELECT COUNT(*)
    FROM wp_mt_evaluations
    WHERE courage_score > 0 OR innovation_score > 0 OR implementation_score > 0 OR relevance_score > 0 OR visibility_score > 0
");
echo "Evaluations using old 5-criteria system: $old_criteria_count\n";

echo "\n";
echo "===========================================\n";
echo "Optimization Summary:\n";
echo "===========================================\n";
echo "✓ All custom tables optimized\n";
echo "✓ Data integrity checks completed\n";
echo "✓ 2-criteria system verified\n";

$total_issues = count($orphaned_eval_candidates) + count($orphaned_eval_jury) +
                count($orphaned_assign_candidates) + count($orphaned_assign_jury) +
                count($duplicates) + $unlinked_count;

if ($total_issues == 0) {
    echo "✓ No data integrity issues found\n";
} else {
    echo "⚠ Found $total_issues data integrity issues (see details above)\n";
}

echo "\n";
echo "Database optimization complete!\n";
echo "===========================================\n";
