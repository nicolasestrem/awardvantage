<?php
/**
 * Link Jury Member Posts to WordPress Users
 * Best-Teacher Award #class25
 *
 * Links the 30 jury member posts to their corresponding WordPress users (jury01-jury30)
 *
 * Usage:
 *   docker exec awardvantage-wordpress-1 wp eval-file scripts/link-jury-users.php --allow-root
 */

// Exit if not running in WP-CLI context
if (!defined('WP_CLI') && !defined('ABSPATH')) {
    exit('This script must be run via WP-CLI');
}

echo "===========================================\n";
echo "Linking Jury Members to WordPress Users\n";
echo "Best-Teacher Award #class25\n";
echo "===========================================\n\n";

// Get all jury member posts
$jury_members = get_posts([
    'post_type' => 'mt_jury_member',
    'posts_per_page' => -1,
    'post_status' => 'publish',
    'orderby' => 'ID',
    'order' => 'ASC'
]);

// Mapping of post IDs to usernames
$post_to_user = [
    46 => 'jury01',  // Jury Member 01
    47 => 'jury02',  // Jury Member 02
    48 => 'jury03',  // Jury Member 03
    49 => 'jury04',  // Jury Member 04
    50 => 'jury05',  // Jury Member 05
    51 => 'jury06',  // Jury Member 06
    52 => 'jury07',  // Jury Member 07
    53 => 'jury08',  // Jury Member 08
    54 => 'jury09',  // Jury Member 09
    55 => 'jury10',  // Jury Member 10
    56 => 'jury11',  // Jury Member 11
    57 => 'jury12',  // Jury Member 12
    58 => 'jury13',  // Jury Member 13
    59 => 'jury14',  // Jury Member 14
    60 => 'jury15',  // Jury Member 15
    61 => 'jury16',  // Jury Member 16
    62 => 'jury17',  // Jury Member 17
    63 => 'jury18',  // Jury Member 18
    64 => 'jury19',  // Jury Member 19
    65 => 'jury20',  // Jury Member 20
    66 => 'jury21',  // Jury Member 21
    67 => 'jury22',  // Jury Member 22
    68 => 'jury23',  // Jury Member 23
    69 => 'jury24',  // Jury Member 24
    70 => 'jury25',  // Jury Member 25
    71 => 'jury26',  // Jury Member 26
    72 => 'jury27',  // Jury Member 27
    73 => 'jury28',  // Jury Member 28
    74 => 'jury29',  // Jury Member 29
    75 => 'jury30',  // Jury Member 30
];

$linked = 0;
$failed = 0;

foreach ($jury_members as $jury_member) {
    $post_id = $jury_member->ID;
    $name = $jury_member->post_title;

    if (!isset($post_to_user[$post_id])) {
        echo sprintf("[%d] %s: SKIPPED - No mapping found\n", $post_id, $name);
        $failed++;
        continue;
    }

    $username = $post_to_user[$post_id];
    $user = get_user_by('login', $username);

    if (!$user) {
        echo sprintf("[%d] %s: FAILED - User '%s' not found\n", $post_id, $name, $username);
        $failed++;
        continue;
    }

    update_post_meta($post_id, '_mt_user_id', $user->ID);
    echo sprintf("[%d] %s: Linked to user '%s' (ID: %d)\n", $post_id, $name, $username, $user->ID);
    $linked++;
}

echo "\n";
echo "===========================================\n";
echo "Link Summary:\n";
echo "===========================================\n";
echo "Jury members linked: $linked\n";
echo "Failed links: $failed\n";
echo "\n";
echo "===========================================\n";
echo "Linking complete!\n";
echo "===========================================\n";
