# Best-Teacher Award #class25 - Installation Guide

**Version:** 1.0.0 (based on Mobility Trailblazers 2.5.41)
**Date:** November 12, 2025
**Language:** German (de_DE)

---

## Table of Contents
1. [System Requirements](#system-requirements)
2. [Pre-Installation Checklist](#pre-installation-checklist)
3. [Installation Steps](#installation-steps)
4. [Post-Installation Configuration](#post-installation-configuration)
5. [Importing Candidates](#importing-candidates)
6. [Creating Jury Members](#creating-jury-members)
7. [Testing the Installation](#testing-the-installation)
8. [Troubleshooting](#troubleshooting)

---

## System Requirements

### WordPress Environment
- **WordPress Version:** 5.8 or higher (6.x recommended)
- **PHP Version:** 7.4 or higher (**PHP 8.2+ strongly recommended**)
- **MySQL Version:** 5.6 or higher (8.0 recommended)
- **Memory Limit:** 64MB minimum (128MB recommended)
- **Max Execution Time:** 60 seconds minimum

### Server Requirements
- **mod_rewrite** enabled (for pretty permalinks)
- **HTTPS** enabled (required for security)
- **File Uploads** enabled
- **Max Upload Size:** 10MB minimum

### Recommended Hosting
- **Disk Space:** 500MB minimum
- **Database Storage:** 100MB minimum
- **Bandwidth:** Unlimited or generous allocation
- **Backup System:** Automated daily backups

---

## Pre-Installation Checklist

### ✅ Step 1: Prepare WordPress Installation

1. **Fresh WordPress Install:**
   ```bash
   # Download WordPress
   wp core download --locale=de_DE

   # Create wp-config.php
   wp config create --dbname=yourdb --dbuser=youruser --dbpass=yourpass

   # Install WordPress
   wp core install --url="https://awardvantage.com" --title="Best-Teacher Award" --admin_user=admin --admin_email=admin@example.com
   ```

2. **Set Permalink Structure:**
   - Go to Settings → Permalinks
   - Select "Post name" or "Custom Structure: /%postname%/"
   - Click "Save Changes"

3. **Set Timezone:**
   - Go to Settings → General
   - Timezone: Europe/Berlin (or appropriate timezone)
   - Date Format: d.m.Y (German format)
   - Time Format: H:i

### ✅ Step 2: Backup Existing Site (if upgrading)

```bash
# Backup database
wp db export backup-$(date +%Y%m%d).sql

# Backup files
tar -czf backup-files-$(date +%Y%m%d).tar.gz wp-content/
```

### ✅ Step 3: Verify Server Permissions

```bash
# Plugin directory should be writable
chmod 755 wp-content/plugins/
chmod 644 wp-content/plugins/*

# Upload directory permissions
chmod 755 wp-content/uploads/
chmod 644 wp-content/uploads/*
```

---

## Installation Steps

### Step 1: Upload Plugin Files

**Option A: Via WordPress Admin (Recommended)**
1. Download the plugin ZIP file
2. Go to WordPress Admin → Plugins → Add New
3. Click "Upload Plugin"
4. Select `best-teacher-award-class25.zip`
5. Click "Install Now"
6. **DO NOT activate yet**

**Option B: Via FTP/SFTP**
1. Extract `best-teacher-award-class25.zip`
2. Upload the `Plugin` folder to `/wp-content/plugins/`
3. Rename folder to `best-teacher-award-class25` (if needed)

**Option C: Via WP-CLI (Advanced)**
```bash
# Install from zip file
wp plugin install /path/to/best-teacher-award-class25.zip

# OR install from extracted folder
cp -r /path/to/Plugin /var/www/html/wp-content/plugins/best-teacher-award-class25
wp plugin list # Verify it appears
```

### Step 2: Activate the Plugin

1. Go to WordPress Admin → Plugins
2. Find "Best-Teacher Award #class25"
3. Click "Activate"
4. **Expected Result:** Plugin activates without errors

**Important Notes:**
- Plugin will create 4 custom database tables (`wp_mt_evaluations`, `wp_mt_jury_assignments`, `wp_mt_audit_log`, `wp_mt_error_log`)
- Two custom post types will be registered (`mt_candidate`, `mt_jury_member`)
- Two custom user roles will be created (`mt_jury_member`, `mt_jury_admin`)

### Step 3: Verify Activation

Go to WordPress Admin. You should see a new menu item:
- **"MT Award System"** in the admin sidebar

If you see this menu, activation was successful!

---

## Post-Installation Configuration

### Step 1: Configure Plugin Settings

1. Go to **MT Award System → Settings**
2. Configure the following:

**General Settings:**
- Award Name: "Best-Teacher Award #class25"
- Evaluation Criteria: (Keep defaults or customize)
- Scoring System: 0-10 scale with 0.5 increments ✓

**Email Notifications:**
- Enable email notifications: ✓
- From Name: "Best-Teacher Award Team"
- From Email: noreply@awardvantage.com
- Assignment notification template
- Reminder notification template

**Access Control:**
- Enable jury member self-registration: ☐ (Recommended: OFF)
- Allow jury to see other evaluations: ☐ (Recommended: OFF)
- Enable audit logging: ✓ (Recommended: ON)

### Step 2: Test Database Tables

Run this via WP-CLI or phpMyAdmin:
```sql
SHOW TABLES LIKE 'wp_mt_%';
```

**Expected output:**
- `wp_mt_audit_log`
- `wp_mt_evaluations`
- `wp_mt_jury_assignments`
- `wp_mt_error_log`

### Step 3: Verify User Roles

```bash
wp role list
```

**Expected custom roles:**
- `mt_jury_member` - Can submit evaluations
- `mt_jury_admin` - Can manage assignments and view all evaluations

---

## Importing Candidates

### Method 1: Using the Import Script (Recommended)

The plugin includes a pre-configured import script for the 38 German candidates.

**Step 1: Prepare Photos**
1. Upload candidate photos to `/private/` folder:
   - AlexanderBilgeri.jpg ✓
   - Anjes Tjarks .jpg ✓
   - andreas-herrmann.webp ✓
   - Upload remaining 35 photos

**Step 2: Run Import Script**
```bash
# Via WP-CLI (Recommended)
wp eval-file scripts/import-candidates-class25.php

# Expected output:
# [1/38] Processing: Alexander Bilgeri... SUCCESS (ID: 123)
# [2/38] Processing: Andreas Herrmann... SUCCESS (ID: 124)
# ...
# Import Complete!
# Imported: 38 candidates
# Skipped: 0 candidates
# Errors: 0 candidates
```

**Step 3: Verify Import**
```bash
wp post list --post_type=mt_candidate --format=count
# Expected: 38
```

### Method 2: Manual Import via WordPress Admin

1. Go to **MT Award System → Candidates → Add New**
2. Enter candidate information:
   - Title: Full Name
   - Content: Biography (in German)
   - Featured Image: Upload photo
   - Custom Fields:
     - `_mt_linkedin_url`: LinkedIn profile URL
3. Click "Publish"
4. Repeat for all 38 candidates

### Method 3: Bulk Import via CSV (Alternative)

Create a CSV file with the following columns:
```
name,bio,linkedin,photo_url
"Alexander Bilgeri","Biography text...","https://linkedin.com/...","https://..."
```

Then use the built-in import tool:
```bash
wp post import csv candidates.csv --post_type=mt_candidate
```

---

## Creating Jury Members

### Step 1: Create Jury Member WordPress Users

**Via WP-CLI (Batch Creation):**
```bash
# Example: Create a jury member
wp user create jury1 jury1@example.com --role=mt_jury_member --first_name="Max" --last_name="Mustermann" --user_pass="SecurePass123!" --send-email

# Repeat for all jury members
```

**Via WordPress Admin:**
1. Go to Users → Add New
2. Fill in details:
   - Username: (unique)
   - Email: (jury member's email)
   - Role: **MT Jury Member**
   - Password: Generate strong password
3. Click "Add New User"
4. Check "Send User Notification" to email credentials

### Step 2: Create Jury Member Profiles

For each WordPress user, create a corresponding jury member post:

1. Go to **MT Award System → Jury Members → Add New**
2. Enter details:
   - Title: Full Name (e.g., "Prof. Dr. Max Mustermann")
   - Content: Bio/expertise
   - Featured Image: Profile photo
   - Link to User: Select corresponding WordPress user
3. Click "Publish"

### Step 3: Verify Jury Member Setup

```bash
# List all jury members
wp post list --post_type=mt_jury_member --format=table

# Check user roles
wp user list --role=mt_jury_member --format=table
```

---

## Assigning Jury to Candidates

### Via WordPress Admin

1. Go to **MT Award System → Assignments**
2. Select a jury member from the dropdown
3. Check the candidates they should evaluate
4. Click "Save Assignments"
5. Jury member will receive an email notification (if enabled)

### Via WP-CLI (Bulk Assignment)

```php
// Example script: assign-jury.php
<?php
// Assign jury member ID 123 to candidates 1, 2, 3
wp_insert_post([
    'post_type' => 'mt_jury_assignment',
    'meta_input' => [
        '_mt_jury_member_id' => 123,
        '_mt_candidate_ids' => [1, 2, 3]
    ]
]);
```

Run: `wp eval-file scripts/assign-jury.php`

---

## Testing the Installation

### Test 1: Admin Access
1. Log in as Administrator
2. Navigate to **MT Award System**
3. Verify you can access:
   - Candidates list ✓
   - Jury Members list ✓
   - Assignments page ✓
   - Evaluations overview ✓
   - Settings ✓
   - Debug Center ✓

### Test 2: Jury Member Access
1. Log in as a jury member
2. Navigate to the jury dashboard (usually at `/jury-dashboard/`)
3. Verify you can see:
   - Assigned candidates ✓
   - Evaluation form with 5 criteria ✓
   - Ability to submit scores ✓
4. Submit a test evaluation
5. Verify it saves correctly

### Test 3: Evaluation Workflow
1. As admin, go to **MT Award System → Evaluations**
2. View submitted evaluations
3. Export evaluations to CSV
4. Verify data integrity

### Test 4: German Language
1. Verify WordPress locale is set to `de_DE`
2. Check that all interface text appears in German:
   - Dashboard labels ✓
   - Button text ✓
   - Error messages ✓
   - Email notifications ✓

### Test 5: Shortcodes (if using theme integration)
Insert these shortcodes in a test page:
```
[mt_jury_dashboard]
[mt_candidates_grid]
[mt_evaluation_stats]
```

Verify they render correctly.

---

## Troubleshooting

### Issue: Plugin Won't Activate

**Symptoms:** Error message on activation

**Solutions:**
1. Check PHP version: `php -v` (must be 7.4+)
2. Check memory limit in `php.ini`: `memory_limit = 128M`
3. Check error log: `/wp-content/debug.log`
4. Verify file permissions: `chmod 755 wp-content/plugins/best-teacher-award-class25/`

### Issue: Database Tables Not Created

**Symptoms:** No `wp_mt_*` tables in database

**Solution:**
```bash
# Deactivate and reactivate plugin
wp plugin deactivate best-teacher-award-class25
wp plugin activate best-teacher-award-class25

# Manually run activation
wp eval '(new MobilityTrailblazers\Core\MT_Activator())->activate();'

# Check tables
wp db query "SHOW TABLES LIKE 'wp_mt_%';"
```

### Issue: Candidates Not Importing

**Symptoms:** Import script fails or skips candidates

**Solutions:**
1. Check photo file paths: `ls private/*.jpg`
2. Verify file permissions: `chmod 644 private/*.jpg`
3. Run import with verbose output:
   ```bash
   wp eval-file scripts/import-candidates-class25.php --debug
   ```
4. Check for existing candidates: `wp post list --post_type=mt_candidate`

### Issue: Jury Members Can't Access Dashboard

**Symptoms:** 404 error on `/jury-dashboard/`

**Solutions:**
1. Flush rewrite rules:
   ```bash
   wp rewrite flush
   ```
2. Verify page exists: Go to Pages → find "Jury Dashboard"
3. Check user role: `wp user get USERNAME --field=roles`
4. Verify shortcode on page: `[mt_jury_dashboard]`

### Issue: German Translations Not Loading

**Symptoms:** Interface shows English text

**Solutions:**
1. Check WordPress locale:
   ```bash
   wp option get WPLANG
   # Should return: de_DE
   ```
2. Verify translation files exist:
   ```bash
   ls Plugin/languages/mobility-trailblazers-de_DE.*
   # Should show: .mo and .po files
   ```
3. Recompile translations:
   ```bash
   npm run i18n:compile
   ```
4. Clear WordPress cache:
   ```bash
   wp cache flush
   ```

### Issue: Email Notifications Not Sending

**Symptoms:** Jury members don't receive assignment emails

**Solutions:**
1. Test WordPress email:
   ```bash
   wp eval 'wp_mail("test@example.com", "Test", "Test email");'
   ```
2. Check SMTP settings (install WP Mail SMTP plugin if needed)
3. Verify email templates in Settings → Notifications
4. Check spam folder
5. Review debug log for email errors

### Issue: Evaluation Submission Fails

**Symptoms:** Error message when jury submits scores

**Solutions:**
1. Check browser console for JavaScript errors
2. Verify AJAX nonce is valid (refresh page)
3. Check debug log: `tail -f wp-content/debug.log`
4. Verify evaluation criteria are configured
5. Test with different browser
6. Disable browser extensions temporarily

---

## Security Considerations

### ✅ Pre-Deployment Security Checklist

- [ ] Change all default passwords
- [ ] Set strong admin password (20+ characters)
- [ ] Enable HTTPS (SSL certificate installed)
- [ ] Hide WordPress version: `remove_action('wp_head', 'wp_generator');`
- [ ] Disable file editing in wp-config.php: `define('DISALLOW_FILE_EDIT', true);`
- [ ] Limit login attempts (install Wordfence or similar)
- [ ] Enable automated backups
- [ ] Review user permissions

### 🔐 Plugin-Specific Security

- **Audit Logging:** Enabled by default. Review logs regularly at MT Award System → Debug Center → Audit Log
- **Rate Limiting:** Built-in (10 evaluations/minute, 20 inline saves/minute)
- **File Upload Validation:** Automatic malware scanning on CSV imports
- **Nonce Verification:** All AJAX requests protected
- **Capability Checks:** All admin actions require proper permissions

### ⚠️ Known Security Notes

1. **Debug Mode:** Ensure `WP_DEBUG` is `false` in production
2. **Database Prefix:** Use custom prefix (not `wp_`) for security
3. **Admin Username:** Don't use "admin" as username
4. **Regular Updates:** Check for plugin updates monthly

---

## Performance Optimization

### Recommended Caching

1. **Object Cache:** Install Redis or Memcached
   ```bash
   wp plugin install redis-cache --activate
   wp redis enable
   ```

2. **Page Caching:** Install WP Super Cache or W3 Total Cache

3. **CDN:** Use Cloudflare or similar for static assets

### Database Optimization

```bash
# Optimize database tables
wp db optimize

# Clean up revisions
wp post delete $(wp post list --post_type=revision --format=ids)

# Clean up transients
wp transient delete --all
```

### Monitor Performance

- Page load time target: < 2 seconds
- Database queries per page: < 50
- Memory usage: < 64MB
- Check via Debug Center → Performance tab

---

## Support & Resources

### Documentation
- Plugin README: `/Plugin/README.md`
- Technical Documentation: `/docs/` folder
- CLAUDE.md: Development guidelines

### Debug Tools
- **Debug Center:** MT Award System → Debug Center
  - System diagnostics
  - Database health check
  - Error log viewer
  - Performance metrics

### Getting Help

1. **Check Debug Log:** `/wp-content/debug.log`
2. **Review Audit Log:** MT Award System → Debug Center → Audit Log
3. **Run Diagnostics:** MT Award System → Debug Center → System Check
4. **Check GitHub Issues:** https://github.com/nicolasestrem/mobility-trailblazers/issues

### Emergency Contacts
- **Technical Support:** [Your support email]
- **Security Issues:** [Security contact]
- **General Inquiries:** [General contact]

---

## Maintenance Schedule

### Daily
- Monitor error logs
- Check email delivery
- Verify evaluation submissions

### Weekly
- Review audit logs
- Check database size
- Test evaluation workflow
- Review user access

### Monthly
- Update WordPress core
- Update plugins
- Optimize database
- Test backups
- Security audit

### Quarterly
- Full system backup
- Performance review
- User access audit
- Feature review

---

## Upgrade Path

When upgrading from Mobility Trailblazers or updating this plugin:

1. **Backup everything first**
2. Test in staging environment
3. Review changelog
4. Check compatibility with WordPress version
5. Update via WordPress Admin or WP-CLI
6. Flush caches
7. Test critical workflows
8. Monitor error logs

---

## Appendix: Quick Reference Commands

```bash
# Activate plugin
wp plugin activate best-teacher-award-class25

# Import candidates
wp eval-file scripts/import-candidates-class25.php

# Create jury member
wp user create USERNAME EMAIL --role=mt_jury_member

# List candidates
wp post list --post_type=mt_candidate --format=table

# Flush cache
wp cache flush

# Flush rewrites (fix 404s)
wp rewrite flush

# Check database tables
wp db query "SHOW TABLES LIKE 'wp_mt_%';"

# View error log
tail -f wp-content/debug.log

# Export evaluations
wp eval 'mt_export_evaluations_csv();'
```

---

**Installation Guide Version:** 1.0.0
**Last Updated:** November 12, 2025
**For Plugin Version:** 1.0.0 (based on MT 2.5.41)

**Need Help?** Contact support or review the full documentation in `/docs/`
