# WordPress Debug Logging Setup

This document explains how to enable WordPress debug logging in the AwardVantage Docker environment.

## Overview

WordPress debug logging writes PHP errors, warnings, and debug messages to `/wp-content/debug.log`, allowing you to troubleshoot issues without displaying errors to end users.

## Configuration

To enable debug logging, add the following constants to the `WORDPRESS_CONFIG_EXTRA` section in your `private/docker-compose-AV.yml` file:

```yaml
services:
  wordpress:
    environment:
      WORDPRESS_CONFIG_EXTRA: |
        define('FS_METHOD', 'direct');
        define('WP_MEMORY_LIMIT', '256M');
        define('WP_DEBUG', true);
        define('WP_DEBUG_LOG', true);
        define('WP_DEBUG_DISPLAY', false);
        define('SCRIPT_DEBUG', true);
```

### Constants Explained

- **WP_DEBUG**: Enables WordPress debug mode
- **WP_DEBUG_LOG**: Writes errors to `/wp-content/debug.log`
- **WP_DEBUG_DISPLAY**: Set to `false` to prevent errors from displaying on the frontend
- **SCRIPT_DEBUG**: Forces WordPress to use non-minified versions of JavaScript and CSS files

## Applying Changes

After updating the configuration, restart the Docker containers:

```bash
cd private
docker compose -f docker-compose-AV.yml down
docker compose -f docker-compose-AV.yml up -d
```

## Accessing the Debug Log

Once enabled, the debug log is accessible at:

- **URL**: https://awardvantage.com/wp-content/debug.log
- **Container path**: `/var/www/html/wp-content/debug.log`

### View Log in Real-Time

To tail the log file from within the Docker container:

```bash
docker compose -f docker-compose-AV.yml exec wordpress tail -f /var/www/html/wp-content/debug.log
```

### Clear the Log

To clear the debug log:

```bash
docker compose -f docker-compose-AV.yml exec wordpress sh -c "> /var/www/html/wp-content/debug.log"
```

## Security Note

The debug log may contain sensitive information. Ensure it's not accessible in production environments or protected by proper access controls.

## Disabling Debug Mode

To disable debug logging, either:
1. Remove the debug constants from `docker-compose-AV.yml`, or
2. Set `WP_DEBUG` to `false`

Then restart the containers as shown above.
