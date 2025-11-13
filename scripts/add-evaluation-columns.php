<?php
/**
 * Add New Evaluation Criteria Columns
 * Best-Teacher Award #class25
 *
 * This script adds the new evaluation criteria columns to the database:
 * - didactic_excellence_score
 * - practical_impact_score
 *
 * Usage:
 *   docker exec awardvantage-wordpress-1 wp eval-file scripts/add-evaluation-columns.php --allow-root
 */

// Exit if not running in WP-CLI context
if (!defined('WP_CLI') && !defined('ABSPATH')) {
    exit('This script must be run via WP-CLI');
}

global $wpdb;

echo "===========================================\n";
echo "Adding New Evaluation Criteria Columns\n";
echo "Best-Teacher Award #class25\n";
echo "===========================================\n\n";

// Database table name
$table_name = $wpdb->prefix . 'mt_evaluations';

// Check if table exists
$table_exists = $wpdb->get_var("SHOW TABLES LIKE '$table_name'") === $table_name;

if (!$table_exists) {
    echo "ERROR: Table $table_name does not exist!\n";
    exit(1);
}

echo "Table found: $table_name\n\n";

// Check current columns
echo "Checking existing columns...\n";
$existing_columns = $wpdb->get_col("DESCRIBE $table_name");
echo "Current columns: " . implode(', ', $existing_columns) . "\n\n";

// Columns to add
$columns_to_add = [
    'didactic_excellence_score' => "ALTER TABLE $table_name ADD COLUMN didactic_excellence_score DECIMAL(3,1) DEFAULT NULL AFTER visibility_score",
    'practical_impact_score' => "ALTER TABLE $table_name ADD COLUMN practical_impact_score DECIMAL(3,1) DEFAULT NULL AFTER didactic_excellence_score"
];

$columns_added = 0;
$columns_skipped = 0;

foreach ($columns_to_add as $column_name => $sql) {
    if (in_array($column_name, $existing_columns)) {
        echo "SKIP: Column '$column_name' already exists\n";
        $columns_skipped++;
    } else {
        echo "Adding column: $column_name...";
        $result = $wpdb->query($sql);
        if ($result === false) {
            echo " FAILED\n";
            echo "Error: " . $wpdb->last_error . "\n";
        } else {
            echo " SUCCESS\n";
            $columns_added++;
        }
    }
}

echo "\n";
echo "===========================================\n";
echo "Migration Summary:\n";
echo "===========================================\n";
echo "Columns added:   $columns_added\n";
echo "Columns skipped: $columns_skipped\n";
echo "\n";

// Verify columns were added
echo "Verifying columns...\n";
$updated_columns = $wpdb->get_col("DESCRIBE $table_name");
echo "Updated columns: " . implode(', ', $updated_columns) . "\n\n";

// Check if new columns exist
$verification_passed = true;
foreach (array_keys($columns_to_add) as $column_name) {
    if (!in_array($column_name, $updated_columns)) {
        echo "ERROR: Column '$column_name' was not added!\n";
        $verification_passed = false;
    }
}

if ($verification_passed) {
    echo "✓ All columns verified successfully!\n\n";
    echo "You can now use the 2-criteria evaluation system:\n";
    echo "1. Didaktische Exzellenz (didactic_excellence_score)\n";
    echo "2. Praxisrelevanz und Impact (practical_impact_score)\n";
} else {
    echo "✗ Column verification failed!\n";
    exit(1);
}

echo "\n===========================================\n";
echo "Migration complete!\n";
echo "===========================================\n";
