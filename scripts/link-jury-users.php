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
    46 => 'jury01',  // Gerhard Müller
    47 => 'jury02',  // Monika Schwarz
    48 => 'jury03',  // Daniel Schmitt
    49 => 'jury04',  // Christian Schneider
    50 => 'jury05',  // Claudia Koch
    51 => 'jury06',  // Frank Hartmann
    52 => 'jury07',  // Stefan Bauer
    53 => 'jury08',  // Horst Schäfer
    54 => 'jury09',  // Peter Hoffmann
    55 => 'jury10',  // Jürgen Wolf
    56 => 'jury11',  // Petra Meyer
    57 => 'jury12',  // Michael Richter
    58 => 'jury13',  // Klaus Weber
    59 => 'jury14',  // Helmut Fischer
    60 => 'jury15',  // Andreas Werner
    61 => 'jury16',  // Andrea Klein
    62 => 'jury17',  // Anna Schröder
    63 => 'jury18',  // Elisabeth Hofmann
    64 => 'jury19',  // Martin Lange
    65 => 'jury20',  // Werner Schulz
    66 => 'jury21',  // Dieter Wagner
    67 => 'jury22',  // Maria Krüger
    68 => 'jury23',  // Thomas Becker
    69 => 'jury24',  // Gabriele Schmidt
    70 => 'jury25',  // Alexander Schmitz
    71 => 'jury26',  // Hans Neumann
    72 => 'jury27',  // Wolfgang Zimmermann
    73 => 'jury28',  // Sabine Meier
    74 => 'jury29',  // Matthias Krause
    75 => 'jury30',  // Susanne Braun
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
