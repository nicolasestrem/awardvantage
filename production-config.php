<?php
/**
 * Production Configuration for Best-Teacher Award #class25
 * Add these settings to your wp-config.php file
 *
 * Site: AwardVantage.com
 * Version: 2.5.41-class25
 */

// ============================================================================
// ENVIRONMENT CONFIGURATION
// ============================================================================

/**
 * Set WordPress environment type to production
 * This affects how WordPress and plugins behave
 */
define('WP_ENVIRONMENT_TYPE', 'production');

/**
 * Set plugin-specific environment
 * Controls plugin debug output and logging levels
 */
define('MT_ENVIRONMENT', 'production');

// ============================================================================
// DEBUG SETTINGS (MUST BE DISABLED IN PRODUCTION!)
// ============================================================================

/**
 * Disable all debug output in production
 * CRITICAL: These must be false to prevent information disclosure
 */
define('WP_DEBUG', false);
define('WP_DEBUG_LOG', false);
define('WP_DEBUG_DISPLAY', false);
define('SCRIPT_DEBUG', false);

/**
 * Disable plugin debug mode
 * Prevents verbose logging and debug output
 */
define('MT_DEBUG', false);

// ============================================================================
// SECURITY HARDENING
// ============================================================================

/**
 * Disable file editing from WordPress admin
 * Prevents code injection through admin panel
 */
define('DISALLOW_FILE_EDIT', true);

/**
 * Force SSL for admin and login pages
 * Ensures all administrative actions use HTTPS
 */
define('FORCE_SSL_ADMIN', true);
define('FORCE_SSL_LOGIN', true);

/**
 * Limit login attempts (requires additional plugin)
 * Consider installing a security plugin for this
 */
define('WP_FAIL2BAN_BLOCK_USER_ENUMERATION', true);

/**
 * Hide WordPress version
 */
define('WP_HIDE_VERSION', true);

// ============================================================================
// PERFORMANCE OPTIMIZATION
// ============================================================================

/**
 * Memory limits
 * Adjust based on your server capacity
 */
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');

/**
 * Post revisions limit
 * Reduces database bloat
 */
define('WP_POST_REVISIONS', 10);

/**
 * Autosave interval
 * Reduces database writes (default is 60)
 */
define('AUTOSAVE_INTERVAL', 300); // 5 minutes

/**
 * Empty trash automatically
 */
define('EMPTY_TRASH_DAYS', 30);

/**
 * Disable automatic updates for production stability
 * Manual updates recommended after testing
 */
define('AUTOMATIC_UPDATER_DISABLED', true);
define('WP_AUTO_UPDATE_CORE', false);

// ============================================================================
// CACHING CONFIGURATION (REDIS)
// ============================================================================

/**
 * Enable WordPress object caching
 */
define('WP_CACHE', true);

/**
 * Redis configuration (already in your Docker setup)
 * These should already be defined in your existing wp-config.php
 */
// define('WP_REDIS_HOST', 'redis');
// define('WP_REDIS_PORT', 6379);
// define('WP_REDIS_PASSWORD', 'your-redis-password');
// define('WP_REDIS_DATABASE', 0);
// define('WP_REDIS_PREFIX', 'av_');

/**
 * Cache salt for multi-site or multiple instances
 */
define('WP_CACHE_KEY_SALT', 'awardvantage_prod_');

// ============================================================================
// PLUGIN-SPECIFIC SETTINGS
// ============================================================================

/**
 * Best-Teacher Award plugin settings
 */
define('MT_DISABLE_AUDIT_LOG', false); // Keep audit logging enabled
define('MT_AUDIT_LOG_RETENTION_DAYS', 90); // Keep logs for 90 days
define('MT_ENABLE_RATE_LIMITING', true); // Enable rate limiting for API endpoints
define('MT_RATE_LIMIT_EVALUATIONS', 10); // Max evaluations per minute
define('MT_RATE_LIMIT_INLINE_SAVES', 20); // Max inline saves per minute

/**
 * File upload restrictions
 */
define('MT_MAX_UPLOAD_SIZE', 5 * 1024 * 1024); // 5MB max file size
define('MT_ALLOWED_UPLOAD_TYPES', 'jpg,jpeg,png,gif,webp,pdf'); // Allowed file extensions

/**
 * Email notifications
 */
define('MT_ENABLE_EMAIL_NOTIFICATIONS', true);
define('MT_ADMIN_EMAIL_OVERRIDE', 'admin@awardvantage.com'); // Override admin email for notifications

// ============================================================================
// DATABASE OPTIMIZATION
// ============================================================================

/**
 * Database optimization settings
 */
define('WP_ALLOW_REPAIR', false); // Set to true only when needed
define('DO_NOT_UPGRADE_GLOBAL_TABLES', true); // Prevent accidental upgrades

/**
 * Query performance
 */
define('SAVEQUERIES', false); // Set to true only for debugging
define('WP_USE_EXT_MYSQL', false); // Use mysqli instead

// ============================================================================
// SECURITY HEADERS (Add to .htaccess or nginx config)
// ============================================================================

/**
 * Add these headers to your web server configuration:
 *
 * X-Frame-Options: SAMEORIGIN
 * X-Content-Type-Options: nosniff
 * X-XSS-Protection: 1; mode=block
 * Referrer-Policy: strict-origin-when-cross-origin
 * Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';
 */

// ============================================================================
// CRON OPTIMIZATION
// ============================================================================

/**
 * Disable WP-Cron for better performance
 * You're already using a real cron job in Docker
 */
define('DISABLE_WP_CRON', true);

/**
 * Alternative cron method (if needed)
 */
define('ALTERNATE_WP_CRON', false);

// ============================================================================
// MULTISITE CONFIGURATION (if applicable)
// ============================================================================

/**
 * If running multisite, add these:
 */
// define('WP_ALLOW_MULTISITE', false);
// define('MULTISITE', false);

// ============================================================================
// ERROR HANDLING
// ============================================================================

/**
 * Custom error handling
 */
define('WP_DISABLE_FATAL_ERROR_HANDLER', false); // Keep WordPress error recovery
define('WP_SANDBOX_SCRAPING', false); // Disable in production

/**
 * Error reporting level
 */
@ini_set('error_reporting', E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED);
@ini_set('display_errors', 0);
@ini_set('log_errors', 1);
@ini_set('error_log', '/var/www/html/wp-content/debug.log');

// ============================================================================
// ADDITIONAL SECURITY MEASURES
// ============================================================================

/**
 * Authentication unique keys and salts
 * IMPORTANT: Generate new ones at https://api.wordpress.org/secret-key/1.1/salt/
 */
// define('AUTH_KEY',         'put your unique phrase here');
// define('SECURE_AUTH_KEY',  'put your unique phrase here');
// define('LOGGED_IN_KEY',    'put your unique phrase here');
// define('NONCE_KEY',        'put your unique phrase here');
// define('AUTH_SALT',        'put your unique phrase here');
// define('SECURE_AUTH_SALT', 'put your unique phrase here');
// define('LOGGED_IN_SALT',   'put your unique phrase here');
// define('NONCE_SALT',       'put your unique phrase here');

/**
 * WordPress database table prefix
 * Change from default 'wp_' for security
 */
// $table_prefix = 'av_'; // Example custom prefix

// ============================================================================
// MONITORING AND LOGGING
// ============================================================================

/**
 * Enable application monitoring (requires additional setup)
 */
define('WP_APPLICATION_MONITORING', true);

/**
 * Log file locations
 */
define('WP_ERROR_LOG_FILE', '/var/www/html/wp-content/logs/error.log');
define('MT_AUDIT_LOG_FILE', '/var/www/html/wp-content/logs/audit.log');

// ============================================================================
// END OF CONFIGURATION
// ============================================================================

/**
 * IMPORTANT NOTES:
 *
 * 1. Add these configurations to your wp-config.php file ABOVE the line:
 *    "/* That's all, stop editing! Happy publishing. *\/"
 *
 * 2. Test each setting in a staging environment first
 *
 * 3. Monitor your error logs after deployment
 *
 * 4. Keep this file as reference but don't upload it to production
 *
 * 5. Regularly review and update security settings
 */