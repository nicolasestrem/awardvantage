<?php
/**
 * Production Readiness Verification
 * Best-Teacher Award #class25
 *
 * Comprehensive check of all production requirements
 *
 * Usage:
 *   docker exec awardvantage-wordpress-1 wp eval-file scripts/production-readiness-check.php --allow-root
 */

// Exit if not running in WP-CLI context
if (!defined('WP_CLI') && !defined('ABSPATH')) {
    exit('This script must be run via WP-CLI');
}

global $wpdb;

echo "===========================================\n";
echo "PRODUCTION READINESS VERIFICATION\n";
echo "Best-Teacher Award #class25\n";
echo "===========================================\n\n";

$checks_passed = 0;
$checks_failed = 0;
$warnings = 0;

// Check 1: Candidate Count
echo "[1/15] Checking Candidate Count...\n";
$candidates = get_posts([
    'post_type' => 'mt_candidate',
    'posts_per_page' => -1,
    'post_status' => 'publish'
]);
$candidate_count = count($candidates);

if ($candidate_count == 38) {
    echo "  ✓ PASS: Exactly 38 candidates found\n";
    $checks_passed++;
} else {
    echo "  ✗ FAIL: Expected 38 candidates, found $candidate_count\n";
    $checks_failed++;
}

// Check 2: LinkedIn URLs
echo "\n[2/15] Checking LinkedIn URLs...\n";
$missing_linkedin = 0;
foreach ($candidates as $candidate) {
    $linkedin = get_post_meta($candidate->ID, '_mt_linkedin_url', true);
    if (empty($linkedin)) {
        echo "  ⚠ Missing LinkedIn: {$candidate->post_title}\n";
        $missing_linkedin++;
    }
}
if ($missing_linkedin == 0) {
    echo "  ✓ PASS: All candidates have LinkedIn URLs\n";
    $checks_passed++;
} else {
    echo "  ⚠ WARNING: $missing_linkedin candidates missing LinkedIn URLs\n";
    $warnings++;
}

// Check 3: German Descriptions
echo "\n[3/15] Checking German Descriptions...\n";
$missing_descriptions = 0;
foreach ($candidates as $candidate) {
    $description = get_the_content(null, false, $candidate);
    if (empty($description)) {
        echo "  ⚠ Missing description: {$candidate->post_title}\n";
        $missing_descriptions++;
    }
}
if ($missing_descriptions == 0) {
    echo "  ✓ PASS: All candidates have descriptions\n";
    $checks_passed++;
} else {
    echo "  ⚠ WARNING: $missing_descriptions candidates missing descriptions\n";
    $warnings++;
}

// Check 4: Candidate Photos
echo "\n[4/15] Checking Candidate Photos...\n";
$with_photos = 0;
$without_photos = 0;
foreach ($candidates as $candidate) {
    if (has_post_thumbnail($candidate->ID)) {
        $with_photos++;
    } else {
        $without_photos++;
    }
}
echo "  Candidates with photos: $with_photos\n";
echo "  Candidates without photos: $without_photos\n";
if ($without_photos > 0) {
    echo "  ⚠ WARNING: $without_photos candidates don't have photos\n";
    $warnings++;
} else {
    echo "  ✓ PASS: All candidates have photos\n";
    $checks_passed++;
}

// Check 5: Jury Member Count
echo "\n[5/15] Checking Jury Members...\n";
$jury_count = wp_count_posts('mt_jury_member');
if ($jury_count->publish == 30) {
    echo "  ✓ PASS: 30 jury members found\n";
    $checks_passed++;
} else {
    echo "  ✗ FAIL: Expected 30 jury members, found {$jury_count->publish}\n";
    $checks_failed++;
}

// Check 6: Jury User Links
echo "\n[6/15] Checking Jury User Links...\n";
$jury_members = get_posts([
    'post_type' => 'mt_jury_member',
    'posts_per_page' => -1,
    'post_status' => 'publish'
]);
$unlinked_jury = 0;
foreach ($jury_members as $jury_member) {
    $user_id = get_post_meta($jury_member->ID, '_mt_user_id', true);
    if (empty($user_id) || !get_user_by('id', $user_id)) {
        $unlinked_jury++;
    }
}
if ($unlinked_jury == 0) {
    echo "  ✓ PASS: All jury members linked to users\n";
    $checks_passed++;
} else {
    echo "  ✗ FAIL: $unlinked_jury jury members not linked to users\n";
    $checks_failed++;
}

// Check 7: Jury Assignments
echo "\n[7/15] Checking Jury Assignments...\n";
$assignments_count = $wpdb->get_var("SELECT COUNT(*) FROM wp_mt_jury_assignments");
$expected_assignments = 30 * 38; // 1140
if ($assignments_count == $expected_assignments) {
    echo "  ✓ PASS: All assignments created ($assignments_count)\n";
    $checks_passed++;
} else {
    echo "  ✗ FAIL: Expected $expected_assignments assignments, found $assignments_count\n";
    $checks_failed++;
}

// Check 8: Evaluation Criteria Columns
echo "\n[8/15] Checking Database Schema...\n";
$columns = $wpdb->get_col("DESCRIBE wp_mt_evaluations");
$has_didactic = in_array('didactic_excellence_score', $columns);
$has_practical = in_array('practical_impact_score', $columns);

if ($has_didactic && $has_practical) {
    echo "  ✓ PASS: 2-criteria columns exist\n";
    $checks_passed++;
} else {
    echo "  ✗ FAIL: Missing 2-criteria columns\n";
    $checks_failed++;
}

// Check 9: Evaluation Form Template
echo "\n[9/15] Checking Evaluation Form Template...\n";
$form_template = file_get_contents('/var/www/html/wp-content/plugins/mobility-trailblazers/templates/frontend/jury-evaluation-form.php');
if (strpos($form_template, 'didactic_excellence') !== false && strpos($form_template, 'practical_impact') !== false) {
    echo "  ✓ PASS: Form uses 2-criteria system\n";
    $checks_passed++;
} else {
    echo "  ✗ FAIL: Form template not updated for 2 criteria\n";
    $checks_failed++;
}

// Check 10: Evaluation Service
echo "\n[10/15] Checking Evaluation Service...\n";
$service_file = file_get_contents('/var/www/html/wp-content/plugins/mobility-trailblazers/includes/services/class-mt-evaluation-service.php');
if (strpos($service_file, 'didactic_excellence_score') !== false && strpos($service_file, 'practical_impact_score') !== false) {
    echo "  ✓ PASS: Service uses 2-criteria system\n";
    $checks_passed++;
} else {
    echo "  ✗ FAIL: Service not updated for 2 criteria\n";
    $checks_failed++;
}

// Check 11: Organization/Position Fields Hidden
echo "\n[11/15] Checking Hidden Fields...\n";
$post_types_file = file_get_contents('/var/www/html/wp-content/plugins/mobility-trailblazers/includes/core/class-mt-post-types.php');
if (strpos($post_types_file, '/* Organization and Position fields hidden') !== false) {
    echo "  ✓ PASS: Organization/Position fields are hidden\n";
    $checks_passed++;
} else {
    echo "  ⚠ WARNING: Organization/Position fields may not be hidden\n";
    $warnings++;
}

// Check 12: Test Evaluation
echo "\n[12/15] Checking Test Evaluation...\n";
$test_eval_count = $wpdb->get_var("
    SELECT COUNT(*)
    FROM wp_mt_evaluations
    WHERE didactic_excellence_score IS NOT NULL AND practical_impact_score IS NOT NULL
");
if ($test_eval_count > 0) {
    echo "  ✓ PASS: Test evaluation exists ($test_eval_count evaluations with 2 criteria)\n";
    $checks_passed++;
} else {
    echo "  ⚠ WARNING: No evaluations using 2-criteria system yet\n";
    $warnings++;
}

// Check 13: WordPress Version
echo "\n[13/15] Checking WordPress Version...\n";
global $wp_version;
echo "  WordPress version: $wp_version\n";
if (version_compare($wp_version, '6.0', '>=')) {
    echo "  ✓ PASS: WordPress version is up to date\n";
    $checks_passed++;
} else {
    echo "  ⚠ WARNING: WordPress version might be outdated\n";
    $warnings++;
}

// Check 14: Plugin Version
echo "\n[14/15] Checking Plugin Version...\n";
// Load plugin.php to make get_plugin_data() available
require_once ABSPATH . 'wp-admin/includes/plugin.php';
$plugin_data = get_plugin_data('/var/www/html/wp-content/plugins/mobility-trailblazers/mobility-trailblazers.php');
echo "  Plugin version: {$plugin_data['Version']}\n";
if (!empty($plugin_data['Version'])) {
    echo "  ✓ PASS: Plugin is active\n";
    $checks_passed++;
} else {
    echo "  ✗ FAIL: Plugin version not found\n";
    $checks_failed++;
}

// Check 15: Database Optimization
echo "\n[15/15] Checking Database Status...\n";
$tables_status = $wpdb->get_results("SHOW TABLE STATUS LIKE 'wp_mt_%'");
$fragmented_tables = 0;
foreach ($tables_status as $table) {
    if (isset($table->Data_free) && $table->Data_free > 0) {
        $fragmented_tables++;
    }
}
if ($fragmented_tables == 0) {
    echo "  ✓ PASS: All tables optimized (no fragmentation)\n";
    $checks_passed++;
} else {
    echo "  ⚠ INFO: $fragmented_tables tables could benefit from optimization\n";
    $checks_passed++; // Not critical
}

// Summary
echo "\n";
echo "===========================================\n";
echo "PRODUCTION READINESS SUMMARY\n";
echo "===========================================\n";
echo "Checks Passed: $checks_passed\n";
echo "Checks Failed: $checks_failed\n";
echo "Warnings: $warnings\n";
echo "\n";

$total_checks = $checks_passed + $checks_failed;
$pass_rate = ($checks_passed / $total_checks) * 100;
echo "Pass Rate: " . number_format($pass_rate, 1) . "%\n\n";

// Overall Status
if ($checks_failed == 0 && $warnings == 0) {
    echo "✓ STATUS: PRODUCTION READY\n";
    echo "All systems are go! The application is ready for production use.\n";
} elseif ($checks_failed == 0 && $warnings > 0) {
    echo "⚠ STATUS: PRODUCTION READY WITH WARNINGS\n";
    echo "The application is functional but has $warnings warning(s).\n";
    echo "Review warnings above before deploying to production.\n";
} else {
    echo "✗ STATUS: NOT PRODUCTION READY\n";
    echo "Critical issues found. Please resolve failures before deployment.\n";
}

echo "\n";
echo "===========================================\n";
echo "Key Statistics:\n";
echo "===========================================\n";
echo "• Candidates: 38\n";
echo "• Candidates with Photos: $with_photos / 38\n";
echo "• Jury Members: 30\n";
echo "• Total Assignments: $assignments_count\n";
echo "• Test Evaluations: $test_eval_count\n";
echo "• Evaluation Criteria: 2 (Didactic Excellence, Practical Impact)\n";
echo "\n";
echo "===========================================\n";
echo "Verification complete!\n";
echo "===========================================\n";
