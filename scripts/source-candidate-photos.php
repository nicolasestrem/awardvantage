#!/usr/bin/env php
<?php
/**
 * Candidate Photo Sourcing Script
 *
 * This script helps source missing candidate photos by:
 * 1. Generating a CSV report of candidates without photos
 * 2. Providing LinkedIn profile URLs for manual download
 * 3. Creating a photo upload helper
 *
 * Usage:
 *   wp eval-file scripts/source-candidate-photos.php
 *   OR
 *   php scripts/source-candidate-photos.php --mode=report
 *
 * @package BestTeacherAward
 * @version 1.0.0
 */

// Determine if running via WP-CLI or standalone
$is_wp_cli = defined('WP_CLI') && WP_CLI;

if (!$is_wp_cli) {
    // Standalone mode - load WordPress
    $wp_load_paths = [
        __DIR__ . '/../../../../wp-load.php',  // From scripts/ folder
        __DIR__ . '/../../../wp-load.php',
        __DIR__ . '/../../wp-load.php',
        __DIR__ . '/../wp-load.php',
    ];

    $wp_loaded = false;
    foreach ($wp_load_paths as $path) {
        if (file_exists($path)) {
            require_once $path;
            $wp_loaded = true;
            break;
        }
    }

    if (!$wp_loaded) {
        die("ERROR: Could not find WordPress installation. Please run via WP-CLI or from the correct directory.\n");
    }
}

/**
 * Main Script Class
 */
class Candidate_Photo_Sourcer {

    /**
     * Output directory for reports
     */
    private $output_dir;

    /**
     * Report data
     */
    private $report = [];

    /**
     * Constructor
     */
    public function __construct() {
        $this->output_dir = dirname(__DIR__) . '/photo-sourcing-reports';

        // Create output directory if it doesn't exist
        if (!file_exists($this->output_dir)) {
            mkdir($this->output_dir, 0755, true);
        }
    }

    /**
     * Run the main script
     */
    public function run($mode = 'report') {
        $this->log("===========================================");
        $this->log("Candidate Photo Sourcing Script");
        $this->log("===========================================\n");

        switch ($mode) {
            case 'report':
                $this->generate_report();
                break;
            case 'csv':
                $this->generate_csv();
                break;
            case 'download-list':
                $this->generate_download_list();
                break;
            case 'check-duplicates':
                $this->check_duplicates();
                break;
            case 'cleanup':
                $this->cleanup_duplicates();
                break;
            default:
                $this->show_usage();
        }

        $this->log("\n===========================================");
        $this->log("Script completed successfully!");
        $this->log("===========================================");
    }

    /**
     * Generate comprehensive report
     */
    private function generate_report() {
        $this->log("Generating comprehensive photo sourcing report...\n");

        // Get candidates without photos
        $candidates_without_photos = $this->get_candidates_without_photos();

        // Get candidates with photos
        $candidates_with_photos = $this->get_candidates_with_photos();

        // Check for duplicates
        $duplicates = $this->find_duplicates();

        $this->log("📊 STATISTICS:");
        $this->log("  Total candidates WITHOUT photos: " . count($candidates_without_photos));
        $this->log("  Total candidates WITH photos: " . count($candidates_with_photos));
        $this->log("  Duplicate entries found: " . count($duplicates));
        $this->log("  Unique candidates needing photos: " . (count($candidates_without_photos) - count($duplicates)) . "\n");

        $this->log("📋 CANDIDATES WITHOUT PHOTOS:\n");

        $missing_linkedin = 0;
        foreach ($candidates_without_photos as $candidate) {
            $linkedin = $candidate['linkedin_url'] ?: 'NO LINKEDIN URL';
            $status = $candidate['linkedin_url'] ? '✓' : '✗';

            if (!$candidate['linkedin_url']) {
                $missing_linkedin++;
            }

            $duplicate_marker = in_array($candidate['post_title'], array_column($duplicates, 'name')) ? ' [DUPLICATE]' : '';

            $this->log(sprintf(
                "  %s ID:%d - %s%s",
                $status,
                $candidate['ID'],
                $candidate['post_title'],
                $duplicate_marker
            ));

            if ($candidate['linkedin_url']) {
                $this->log("      LinkedIn: " . $candidate['linkedin_url']);
            }
        }

        $this->log("\n⚠️  ISSUES IDENTIFIED:");
        $this->log("  Candidates without LinkedIn URLs: $missing_linkedin");
        $this->log("  Duplicate entries to clean up: " . count($duplicates) . "\n");

        if (count($duplicates) > 0) {
            $this->log("🔍 DUPLICATE ENTRIES:");
            foreach ($duplicates as $dup) {
                $this->log(sprintf(
                    "  %s: ID %d (no photo) vs ID %d (with photo)",
                    $dup['name'],
                    $dup['id_without_photo'],
                    $dup['id_with_photo']
                ));
            }
            $this->log("\n💡 TIP: Run with --mode=cleanup to remove duplicate entries\n");
        }

        $this->log("📄 GENERATING CSV EXPORT...");
        $csv_file = $this->generate_csv();
        $this->log("  ✓ CSV saved to: $csv_file\n");

        $this->log("📋 GENERATING DOWNLOAD LIST...");
        $list_file = $this->generate_download_list();
        $this->log("  ✓ Download list saved to: $list_file\n");

        $this->log("✅ NEXT STEPS:");
        $this->log("  1. Review the CSV file: $csv_file");
        $this->log("  2. Use the download list to collect photos manually");
        $this->log("  3. Save photos to: /private/candidate-photos/");
        $this->log("  4. Run photo import script to upload to WordPress");
        if (count($duplicates) > 0) {
            $this->log("  5. Run: wp eval-file scripts/source-candidate-photos.php --mode=cleanup");
        }
    }

    /**
     * Generate CSV export
     */
    private function generate_csv() {
        $candidates = $this->get_candidates_without_photos();
        $filename = $this->output_dir . '/candidates-missing-photos-' . date('Y-m-d-His') . '.csv';

        $fp = fopen($filename, 'w');

        // Write header
        fputcsv($fp, [
            'ID',
            'Name',
            'LinkedIn URL',
            'Photo Status',
            'Duplicate',
            'Action Required'
        ]);

        // Check duplicates
        $duplicates = $this->find_duplicates();
        $duplicate_names = array_column($duplicates, 'name');

        // Write data
        foreach ($candidates as $candidate) {
            $is_duplicate = in_array($candidate['post_title'], $duplicate_names);

            fputcsv($fp, [
                $candidate['ID'],
                $candidate['post_title'],
                $candidate['linkedin_url'] ?: 'NOT AVAILABLE',
                'Missing',
                $is_duplicate ? 'YES - DELETE' : 'NO',
                $is_duplicate ? 'Delete this entry' : 'Source photo'
            ]);
        }

        fclose($fp);

        return $filename;
    }

    /**
     * Generate download list for manual sourcing
     */
    private function generate_download_list() {
        $candidates = $this->get_candidates_without_photos();
        $filename = $this->output_dir . '/photo-download-checklist-' . date('Y-m-d-His') . '.txt';

        $content = "=============================================\n";
        $content .= "CANDIDATE PHOTO DOWNLOAD CHECKLIST\n";
        $content .= "Generated: " . date('Y-m-d H:i:s') . "\n";
        $content .= "=============================================\n\n";

        $content .= "Instructions:\n";
        $content .= "1. Visit each LinkedIn URL below\n";
        $content .= "2. Right-click on the profile photo\n";
        $content .= "3. Save as: [Candidate-Name].jpg\n";
        $content .= "4. Save to: /private/candidate-photos/\n";
        $content .= "5. Check off [  ] when completed\n\n";

        $content .= "Photo Requirements:\n";
        $content .= "- Minimum size: 400x400 pixels\n";
        $content .= "- Recommended: 800x800 pixels or larger\n";
        $content .= "- Format: JPG, PNG, or WEBP\n";
        $content .= "- Aspect ratio: Square (1:1) or portrait (3:4)\n\n";

        $content .= "=============================================\n\n";

        // Check duplicates to exclude them
        $duplicates = $this->find_duplicates();
        $duplicate_names = array_column($duplicates, 'name');

        $number = 1;
        foreach ($candidates as $candidate) {
            // Skip duplicates in the download list
            if (in_array($candidate['post_title'], $duplicate_names)) {
                continue;
            }

            $linkedin = $candidate['linkedin_url'] ?: 'NO LINKEDIN - SEARCH GOOGLE';
            $filename = str_replace(' ', '-', $candidate['post_title']) . '.jpg';

            $content .= sprintf("[  ] %d. %s\n", $number, $candidate['post_title']);
            $content .= sprintf("    LinkedIn: %s\n", $linkedin);
            $content .= sprintf("    Save as: %s\n", $filename);
            $content .= "\n";

            $number++;
        }

        $content .= "\n=============================================\n";
        $content .= "Total photos to download: " . ($number - 1) . "\n";
        $content .= "=============================================\n";

        file_put_contents($filename, $content);

        return $filename;
    }

    /**
     * Get candidates without photos
     */
    private function get_candidates_without_photos() {
        global $wpdb;

        $query = "
            SELECT p.ID, p.post_title, m_linkedin.meta_value as linkedin_url
            FROM {$wpdb->posts} p
            LEFT JOIN {$wpdb->postmeta} m_thumb
                ON p.ID = m_thumb.post_id AND m_thumb.meta_key = '_thumbnail_id'
            LEFT JOIN {$wpdb->postmeta} m_linkedin
                ON p.ID = m_linkedin.post_id AND m_linkedin.meta_key = '_mt_linkedin_url'
            WHERE p.post_type = 'mt_candidate'
                AND p.post_status = 'publish'
                AND m_thumb.meta_value IS NULL
            ORDER BY p.post_title
        ";

        return $wpdb->get_results($query, ARRAY_A);
    }

    /**
     * Get candidates with photos
     */
    private function get_candidates_with_photos() {
        global $wpdb;

        $query = "
            SELECT p.ID, p.post_title, m_thumb.meta_value as photo_id
            FROM {$wpdb->posts} p
            INNER JOIN {$wpdb->postmeta} m_thumb
                ON p.ID = m_thumb.post_id AND m_thumb.meta_key = '_thumbnail_id'
            WHERE p.post_type = 'mt_candidate'
                AND p.post_status = 'publish'
            ORDER BY p.post_title
        ";

        return $wpdb->get_results($query, ARRAY_A);
    }

    /**
     * Find duplicate candidate entries
     */
    private function find_duplicates() {
        global $wpdb;

        $query = "
            SELECT post_title, COUNT(*) as count
            FROM {$wpdb->posts}
            WHERE post_type = 'mt_candidate' AND post_status = 'publish'
            GROUP BY post_title
            HAVING count > 1
        ";

        $duplicate_names = $wpdb->get_results($query, ARRAY_A);

        $duplicates = [];
        foreach ($duplicate_names as $dup) {
            // Get both instances
            $instances = $wpdb->get_results($wpdb->prepare("
                SELECT p.ID, p.post_title, m.meta_value as has_photo
                FROM {$wpdb->posts} p
                LEFT JOIN {$wpdb->postmeta} m ON p.ID = m.post_id AND m.meta_key = '_thumbnail_id'
                WHERE p.post_type = 'mt_candidate'
                    AND p.post_status = 'publish'
                    AND p.post_title = %s
                ORDER BY has_photo IS NOT NULL DESC
            ", $dup['post_title']), ARRAY_A);

            if (count($instances) == 2) {
                $duplicates[] = [
                    'name' => $dup['post_title'],
                    'id_with_photo' => $instances[0]['ID'],
                    'id_without_photo' => $instances[1]['ID']
                ];
            }
        }

        return $duplicates;
    }

    /**
     * Check for duplicates
     */
    private function check_duplicates() {
        $this->log("Checking for duplicate candidate entries...\n");

        $duplicates = $this->find_duplicates();

        if (count($duplicates) == 0) {
            $this->log("✓ No duplicates found! Database is clean.\n");
            return;
        }

        $this->log("⚠️  Found " . count($duplicates) . " duplicate entries:\n");

        foreach ($duplicates as $dup) {
            $this->log(sprintf(
                "  • %s",
                $dup['name']
            ));
            $this->log(sprintf(
                "    - ID %d (WITH photo) - KEEP",
                $dup['id_with_photo']
            ));
            $this->log(sprintf(
                "    - ID %d (WITHOUT photo) - DELETE",
                $dup['id_without_photo']
            ));
            $this->log("");
        }

        $this->log("💡 To automatically remove duplicates, run:");
        $this->log("   wp eval-file scripts/source-candidate-photos.php --mode=cleanup\n");
    }

    /**
     * Clean up duplicate entries
     */
    private function cleanup_duplicates() {
        $this->log("Cleaning up duplicate candidate entries...\n");

        $duplicates = $this->find_duplicates();

        if (count($duplicates) == 0) {
            $this->log("✓ No duplicates to clean up!\n");
            return;
        }

        $this->log("Found " . count($duplicates) . " duplicate(s) to remove:\n");

        foreach ($duplicates as $dup) {
            $id_to_delete = $dup['id_without_photo'];
            $name = $dup['name'];

            $this->log("  Deleting: ID $id_to_delete - $name (without photo)...");

            // Delete the post
            $result = wp_delete_post($id_to_delete, true);  // true = bypass trash

            if ($result) {
                $this->log(" ✓ SUCCESS");
            } else {
                $this->log(" ✗ FAILED");
            }
        }

        $this->log("\n✅ Cleanup complete! Removed " . count($duplicates) . " duplicate entries.\n");
        $this->log("💡 Run with --mode=report to verify the cleanup.\n");
    }

    /**
     * Show usage instructions
     */
    private function show_usage() {
        $this->log("USAGE:");
        $this->log("  wp eval-file scripts/source-candidate-photos.php [--mode=MODE]\n");
        $this->log("MODES:");
        $this->log("  report           Generate comprehensive report (default)");
        $this->log("  csv              Generate CSV export only");
        $this->log("  download-list    Generate download checklist only");
        $this->log("  check-duplicates Check for duplicate entries");
        $this->log("  cleanup          Remove duplicate entries automatically\n");
        $this->log("EXAMPLES:");
        $this->log("  wp eval-file scripts/source-candidate-photos.php");
        $this->log("  wp eval-file scripts/source-candidate-photos.php --mode=csv");
        $this->log("  wp eval-file scripts/source-candidate-photos.php --mode=cleanup\n");
    }

    /**
     * Log message
     */
    private function log($message) {
        if (defined('WP_CLI') && WP_CLI) {
            WP_CLI::line($message);
        } else {
            echo $message . "\n";
        }
    }
}

// Parse command line arguments
$mode = 'report';
if (isset($argv)) {
    foreach ($argv as $arg) {
        if (strpos($arg, '--mode=') === 0) {
            $mode = substr($arg, 7);
        }
    }
}

// Run the script
$sourcer = new Candidate_Photo_Sourcer();
$sourcer->run($mode);
