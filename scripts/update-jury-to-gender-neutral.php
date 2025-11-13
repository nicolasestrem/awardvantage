<?php
/**
 * Update Jury Members to Gender-Neutral Names and Production Emails
 * Best-Teacher Award #class25
 *
 * Changes all jury member names from gendered names to "Jury Member XX"
 * Updates emails from @awardvantage-demo.local to @awardvantage.com
 *
 * Usage:
 *   docker exec awardvantage-wordpress-1 wp eval-file scripts/update-jury-to-gender-neutral.php --allow-root
 */

// Exit if not running in WP-CLI context
if (!defined('WP_CLI') && !defined('ABSPATH')) {
    exit('This script must be run via WP-CLI');
}

echo "===========================================\n";
echo "Updating Jury Members to Gender-Neutral Names\n";
echo "Best-Teacher Award #class25\n";
echo "===========================================\n\n";

// Mapping of jury usernames to their post IDs and new display names
$jury_mapping = [
    ['username' => 'jury01', 'post_id' => 46, 'new_name' => 'Jury Member 01'],
    ['username' => 'jury02', 'post_id' => 47, 'new_name' => 'Jury Member 02'],
    ['username' => 'jury03', 'post_id' => 48, 'new_name' => 'Jury Member 03'],
    ['username' => 'jury04', 'post_id' => 49, 'new_name' => 'Jury Member 04'],
    ['username' => 'jury05', 'post_id' => 50, 'new_name' => 'Jury Member 05'],
    ['username' => 'jury06', 'post_id' => 51, 'new_name' => 'Jury Member 06'],
    ['username' => 'jury07', 'post_id' => 52, 'new_name' => 'Jury Member 07'],
    ['username' => 'jury08', 'post_id' => 53, 'new_name' => 'Jury Member 08'],
    ['username' => 'jury09', 'post_id' => 54, 'new_name' => 'Jury Member 09'],
    ['username' => 'jury10', 'post_id' => 55, 'new_name' => 'Jury Member 10'],
    ['username' => 'jury11', 'post_id' => 56, 'new_name' => 'Jury Member 11'],
    ['username' => 'jury12', 'post_id' => 57, 'new_name' => 'Jury Member 12'],
    ['username' => 'jury13', 'post_id' => 58, 'new_name' => 'Jury Member 13'],
    ['username' => 'jury14', 'post_id' => 59, 'new_name' => 'Jury Member 14'],
    ['username' => 'jury15', 'post_id' => 60, 'new_name' => 'Jury Member 15'],
    ['username' => 'jury16', 'post_id' => 61, 'new_name' => 'Jury Member 16'],
    ['username' => 'jury17', 'post_id' => 62, 'new_name' => 'Jury Member 17'],
    ['username' => 'jury18', 'post_id' => 63, 'new_name' => 'Jury Member 18'],
    ['username' => 'jury19', 'post_id' => 64, 'new_name' => 'Jury Member 19'],
    ['username' => 'jury20', 'post_id' => 65, 'new_name' => 'Jury Member 20'],
    ['username' => 'jury21', 'post_id' => 66, 'new_name' => 'Jury Member 21'],
    ['username' => 'jury22', 'post_id' => 67, 'new_name' => 'Jury Member 22'],
    ['username' => 'jury23', 'post_id' => 68, 'new_name' => 'Jury Member 23'],
    ['username' => 'jury24', 'post_id' => 69, 'new_name' => 'Jury Member 24'],
    ['username' => 'jury25', 'post_id' => 70, 'new_name' => 'Jury Member 25'],
    ['username' => 'jury26', 'post_id' => 71, 'new_name' => 'Jury Member 26'],
    ['username' => 'jury27', 'post_id' => 72, 'new_name' => 'Jury Member 27'],
    ['username' => 'jury28', 'post_id' => 73, 'new_name' => 'Jury Member 28'],
    ['username' => 'jury29', 'post_id' => 74, 'new_name' => 'Jury Member 29'],
    ['username' => 'jury30', 'post_id' => 75, 'new_name' => 'Jury Member 30'],
];

$users_updated = 0;
$users_failed = 0;
$posts_updated = 0;
$posts_failed = 0;

echo "Step 1: Updating WordPress User Accounts\n";
echo "-------------------------------------------\n";

foreach ($jury_mapping as $jury) {
    $username = $jury['username'];
    $new_name = $jury['new_name'];
    $new_email = $username . '@awardvantage.com';

    // Get user by username
    $user = get_user_by('login', $username);

    if (!$user) {
        echo sprintf("[FAIL] User '%s' not found\n", $username);
        $users_failed++;
        continue;
    }

    $old_name = $user->display_name;
    $old_email = $user->user_email;

    // Update user
    $result = wp_update_user([
        'ID' => $user->ID,
        'display_name' => $new_name,
        'user_email' => $new_email
    ]);

    if (is_wp_error($result)) {
        echo sprintf("[FAIL] %s: %s\n", $username, $result->get_error_message());
        $users_failed++;
    } else {
        echo sprintf("[OK] %s: '%s' → '%s' | %s → %s\n",
            $username, $old_name, $new_name, $old_email, $new_email);
        $users_updated++;
    }
}

echo "\n";
echo "Step 2: Updating Jury Member Posts\n";
echo "-------------------------------------------\n";

foreach ($jury_mapping as $jury) {
    $post_id = $jury['post_id'];
    $new_name = $jury['new_name'];

    // Get post
    $post = get_post($post_id);

    if (!$post || $post->post_type !== 'mt_jury_member') {
        echo sprintf("[FAIL] Post ID %d not found or wrong type\n", $post_id);
        $posts_failed++;
        continue;
    }

    $old_title = $post->post_title;

    // Update post title
    $result = wp_update_post([
        'ID' => $post_id,
        'post_title' => $new_name
    ], true);

    if (is_wp_error($result)) {
        echo sprintf("[FAIL] Post %d: %s\n", $post_id, $result->get_error_message());
        $posts_failed++;
    } else {
        echo sprintf("[OK] Post %d: '%s' → '%s'\n", $post_id, $old_title, $new_name);
        $posts_updated++;
    }
}

echo "\n";
echo "===========================================\n";
echo "Update Summary:\n";
echo "===========================================\n";
echo "WordPress Users:\n";
echo "  Updated: $users_updated\n";
echo "  Failed:  $users_failed\n";
echo "\n";
echo "Jury Member Posts:\n";
echo "  Updated: $posts_updated\n";
echo "  Failed:  $posts_failed\n";
echo "\n";

$total_expected = 60; // 30 users + 30 posts
$total_updated = $users_updated + $posts_updated;

if ($total_updated == $total_expected && $users_failed == 0 && $posts_failed == 0) {
    echo "✓ SUCCESS: All 60 records updated (30 users + 30 posts)\n";
    echo "\n";
    echo "All jury members now have:\n";
    echo "  - Gender-neutral names: 'Jury Member 01' through 'Jury Member 30'\n";
    echo "  - Production emails: jury01@awardvantage.com through jury30@awardvantage.com\n";
} else {
    echo "⚠ WARNING: Expected 60 updates, completed $total_updated\n";
    echo "  Failures: " . ($users_failed + $posts_failed) . "\n";
}

echo "\n===========================================\n";
echo "Update complete!\n";
echo "===========================================\n";
