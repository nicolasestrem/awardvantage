<?php
/**
 * Shared Configuration Constants
 * Best-Teacher Award #class25
 *
 * This file contains system-wide configuration constants used across
 * all maintenance and setup scripts.
 *
 * Usage:
 *   require_once __DIR__ . '/config.php';
 */

// System Constants
define('JURY_MEMBER_COUNT', 30);
define('CANDIDATE_COUNT', 38);
define('EXPECTED_ASSIGNMENTS', JURY_MEMBER_COUNT * CANDIDATE_COUNT); // 1140

// Database Table Names (with wp_ prefix)
define('TABLE_EVALUATIONS', 'wp_mt_evaluations');
define('TABLE_ASSIGNMENTS', 'wp_mt_jury_assignments');
define('TABLE_AUDIT_LOG', 'wp_mt_audit_log');

// Post Types
define('POST_TYPE_CANDIDATE', 'mt_candidate');
define('POST_TYPE_JURY_MEMBER', 'mt_jury_member');

// Evaluation Criteria (2-criteria system)
define('CRITERION_DIDACTIC_EXCELLENCE', 'didactic_excellence');
define('CRITERION_PRACTICAL_IMPACT', 'practical_impact');

// Score Range
define('SCORE_MIN', 0);
define('SCORE_MAX', 10);
define('SCORE_INCREMENT', 0.5);

// Jury Member Username Pattern
define('JURY_USERNAME_PREFIX', 'jury');
define('JURY_USERNAME_DIGITS', 2); // Zero-padded to 2 digits (jury01-jury30)

// Candidate ID Range
define('CANDIDATE_ID_START', 1);
define('CANDIDATE_ID_END', 38);

// Jury Member Post ID Range
define('JURY_POST_ID_START', 46);
define('JURY_POST_ID_END', 75);

// Email Domain
define('PRODUCTION_EMAIL_DOMAIN', 'awardvantage.com');

// Environment Check
if (!defined('WP_CLI') && !defined('ABSPATH')) {
    // This file is meant to be included by WordPress/WP-CLI scripts only
    die('This config file must be included by WordPress or WP-CLI scripts.');
}

// Helper Functions
if (!function_exists('mt_get_jury_username')) {
    /**
     * Get jury username by number
     *
     * @param int $number Jury member number (1-30)
     * @return string Jury username (e.g., "jury01")
     */
    function mt_get_jury_username($number) {
        return JURY_USERNAME_PREFIX . str_pad($number, JURY_USERNAME_DIGITS, '0', STR_PAD_LEFT);
    }
}

if (!function_exists('mt_get_jury_display_name')) {
    /**
     * Get jury display name by number
     *
     * @param int $number Jury member number (1-30)
     * @return string Jury display name (e.g., "Jury Member 01")
     */
    function mt_get_jury_display_name($number) {
        return 'Jury Member ' . str_pad($number, JURY_USERNAME_DIGITS, '0', STR_PAD_LEFT);
    }
}

if (!function_exists('mt_get_jury_email')) {
    /**
     * Get jury email by number
     *
     * @param int $number Jury member number (1-30)
     * @return string Jury email (e.g., "jury01@awardvantage.com")
     */
    function mt_get_jury_email($number) {
        return mt_get_jury_username($number) . '@' . PRODUCTION_EMAIL_DOMAIN;
    }
}
