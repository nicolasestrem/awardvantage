# Production Deployment Guide for Best-Teacher Award #class25
## AwardVantage.com Production Environment

---

## 📋 Pre-Deployment Checklist

Before deploying the plugin, ensure the following:

- [ ] **Backup existing database** using WP-CLI or phpMyAdmin
- [ ] **Verify PHP version** is 8.2 or higher
- [ ] **Confirm HTTPS** is configured and working
- [ ] **Check Redis** connection is active
- [ ] **Verify disk space** - Need at least 50MB free
- [ ] **Test staging environment** (if available)

---

## 🚀 Installation Methods

### Method A: Via WP-CLI in Docker (Recommended)

```bash
# 1. Copy plugin ZIP to server (adjust path as needed)
scp best-teacher-award-class25-v2.5.41-production.zip your-server:/path/to/docker/files/

# 2. Copy into WordPress container
docker cp best-teacher-award-class25-v2.5.41-production.zip awardvantage_wordpress:/tmp/

# 3. Install and activate the plugin
docker exec awardvantage_wpcli wp plugin install /tmp/best-teacher-award-class25-v2.5.41-production.zip --activate --allow-root

# 4. Flush rewrite rules for permalinks
docker exec awardvantage_wpcli wp rewrite flush --allow-root

# 5. Clear all caches
docker exec awardvantage_wpcli wp cache flush --allow-root
```

### Method B: Via WordPress Admin Panel

1. **Access WordPress Admin:**
   - Navigate to https://awardvantage.com/wp-admin/
   - Log in with administrator credentials

2. **Upload Plugin:**
   - Go to **Plugins → Add New → Upload Plugin**
   - Choose `best-teacher-award-class25-v2.5.41-production.zip`
   - Click **Install Now**

3. **Activate Plugin:**
   - Click **Activate** after installation
   - The plugin will automatically create database tables

4. **Flush Permalinks:**
   - Go to **Settings → Permalinks**
   - Click **Save Changes** (no need to change anything)

---

## ⚙️ Production Configuration

### 1. WordPress Configuration (wp-config.php)

Add these lines to your `wp-config.php` file:

```php
// Environment Configuration
define('WP_ENVIRONMENT_TYPE', 'production');
define('MT_ENVIRONMENT', 'production');

// Security Settings (IMPORTANT!)
define('WP_DEBUG', false);
define('WP_DEBUG_LOG', false);
define('WP_DEBUG_DISPLAY', false);
define('SCRIPT_DEBUG', false);

// Performance Settings
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '256M');

// Security Hardening
define('DISALLOW_FILE_EDIT', true);
define('DISALLOW_FILE_MODS', false); // Set to true after plugin installation
define('FORCE_SSL_ADMIN', true);

// Redis Cache (already configured in your Docker)
define('WP_CACHE', true);
```

### 2. Plugin Settings Configuration

After activation, configure the plugin:

1. **Navigate to:** Admin → Best-Teacher Award → Settings

2. **Configure Evaluation Criteria Weights:**
   - Didaktische Exzellenz: 1.0 (default)
   - Praxisrelevanz und Impact: 1.0 (default)

3. **Dashboard Settings:**
   - Header Style: Image
   - Header Image URL: Upload your branding image
   - Primary Color: Your brand color
   - Secondary Color: Your accent color

4. **Save all settings**

---

## 📊 Database Verification

### Verify Tables Created

Run this command to check if all tables were created:

```bash
docker exec awardvantage_wpcli wp db query "SHOW TABLES LIKE 'wp_mt_%';" --allow-root
```

Expected output:
```
wp_mt_evaluations
wp_mt_jury_assignments
wp_mt_audit_log
wp_mt_error_log
```

### Check Database Indexes

```bash
docker exec awardvantage_wpcli wp db query "SHOW INDEX FROM wp_mt_evaluations;" --allow-root
```

---

## 👥 User Setup

### 1. Create Jury Member Accounts

```bash
# Create a jury member (example)
docker exec awardvantage_wpcli wp user create jury01 jury01@example.com \
  --role=mt_jury_member \
  --user_pass="SecurePassword123!" \
  --first_name="Jury" \
  --last_name="Member 01" \
  --allow-root
```

### 2. Import Existing Jury Members

If you have a CSV file with jury members:

1. Go to **Admin → Best-Teacher Award → Import/Export**
2. Select **Import Jury Members**
3. Upload your CSV file
4. Map fields and import

### 3. Security for Jury Members

Jury members:
- ✅ Can access frontend jury dashboard
- ✅ Can submit evaluations
- ❌ Cannot access /wp-admin/ (redirected to homepage)
- ❌ No admin toolbar visible

---

## 📝 Import Candidate Data

### Option 1: Manual Entry

1. Go to **Admin → Candidates → Add New**
2. Fill in candidate information
3. Upload candidate photo
4. Save and publish

### Option 2: Bulk Import

```bash
# If you have the German candidates JSON file
docker exec awardvantage_wpcli wp mt candidates import /path/to/candidates.json --allow-root
```

### Option 3: Via Admin Interface

1. Go to **Admin → Best-Teacher Award → Import/Export**
2. Select **Import Candidates**
3. Upload JSON or CSV file
4. Review and confirm import

---

## 🔒 Security Hardening

### 1. File Permissions

```bash
# Set proper permissions for the plugin directory
docker exec awardvantage_wordpress chmod -R 755 /var/www/html/wp-content/plugins/best-teacher-award-class25/
docker exec awardvantage_wordpress chmod -R 644 /var/www/html/wp-content/plugins/best-teacher-award-class25/*.php
```

### 2. Database Security

```sql
-- Revoke unnecessary privileges (run in MariaDB)
REVOKE FILE ON *.* FROM 'wp_user'@'%';
REVOKE SUPER ON *.* FROM 'wp_user'@'%';
```

### 3. Rate Limiting

The plugin includes built-in rate limiting:
- Evaluation submissions: 10 per minute
- Inline saves: 20 per minute
- AJAX requests: 30 per minute

---

## ✅ Post-Deployment Verification

### 1. Frontend Tests

- [ ] Visit homepage - Should load without errors
- [ ] Check `/jury-dashboard/` - Should show login or dashboard
- [ ] Test responsive design on mobile

### 2. Jury Member Tests

```bash
# Test as jury member
# 1. Create test jury account
docker exec awardvantage_wpcli wp user create testjury testjury@test.com \
  --role=mt_jury_member --user_pass="Test123!" --allow-root

# 2. Assign a candidate for testing
# (Use admin interface to create assignment)
```

Test these actions:
- [ ] Login as jury member
- [ ] Try accessing `/wp-admin/` (should redirect to homepage)
- [ ] Access jury dashboard
- [ ] Submit an evaluation
- [ ] Save draft evaluation
- [ ] View assigned candidates

### 3. Admin Tests

- [ ] Access all admin pages
- [ ] Create new candidate
- [ ] Assign candidates to jury
- [ ] View evaluation reports
- [ ] Export evaluations to Excel
- [ ] Check audit logs

### 4. Performance Tests

```bash
# Check page load time
docker exec awardvantage_wpcli wp eval 'echo "Load time: " . timer_stop() . " seconds";' --allow-root

# Check database queries
docker exec awardvantage_wpcli wp eval 'echo "Queries: " . get_num_queries();' --allow-root

# Verify Redis cache is working
docker exec awardvantage_wpcli wp redis info --allow-root
```

---

## 🛠️ Troubleshooting

### Issue: Plugin Activation Fails

```bash
# Check PHP error log
docker logs awardvantage_wordpress 2>&1 | grep -i error

# Enable debug temporarily
docker exec awardvantage_wpcli wp config set WP_DEBUG true --raw --allow-root
```

### Issue: Database Tables Not Created

```bash
# Manually trigger activation
docker exec awardvantage_wpcli wp eval '\MobilityTrailblazers\Core\MT_Activator::activate();' --allow-root
```

### Issue: 404 Errors on Custom Pages

```bash
# Flush rewrite rules
docker exec awardvantage_wpcli wp rewrite flush --allow-root

# Regenerate permalinks
docker exec awardvantage_wpcli wp rewrite structure '/%postname%/' --allow-root
```

### Issue: Jury Members Can Access Admin

```bash
# Check user role
docker exec awardvantage_wpcli wp user get USERNAME --field=roles --allow-root

# Reset capabilities
docker exec awardvantage_wpcli wp cap add mt_jury_member mt_submit_evaluations --allow-root
docker exec awardvantage_wpcli wp cap remove mt_jury_member manage_options --allow-root
```

### Issue: Redis Cache Not Working

```bash
# Test Redis connection
docker exec awardvantage_redis redis-cli -a $REDIS_PASSWORD ping

# Flush Redis cache
docker exec awardvantage_wpcli wp redis flush --allow-root
```

---

## 📧 Email Configuration

### Configure SMTP for Notifications

1. Install an SMTP plugin (e.g., WP Mail SMTP)
2. Configure with your email service
3. Test email delivery:

```bash
docker exec awardvantage_wpcli wp eval 'wp_mail("admin@awardvantage.com", "Test", "Test email from Best-Teacher Award plugin");' --allow-root
```

---

## 🔄 Maintenance Tasks

### Daily Tasks

```bash
# Clear transients
docker exec awardvantage_wpcli wp transient delete --expired --allow-root
```

### Weekly Tasks

```bash
# Optimize database tables
docker exec awardvantage_wpcli wp db optimize --allow-root

# Clean up audit logs older than 90 days
docker exec awardvantage_wpcli wp eval '\MobilityTrailblazers\Core\MT_Audit_Logger::cleanup(90);' --allow-root
```

### Before Major Events

```bash
# Full cache clear
docker exec awardvantage_wpcli wp cache flush --allow-root
docker exec awardvantage_redis redis-cli -a $REDIS_PASSWORD FLUSHALL

# Database backup
docker exec awardvantage_wpcli wp db export backup-$(date +%Y%m%d-%H%M%S).sql --allow-root
```

---

## 📞 Support & Resources

### Documentation
- Plugin README: `/wp-content/plugins/best-teacher-award-class25/README.md`
- Security Guide: `/wp-content/plugins/best-teacher-award-class25/SECURITY.md`

### Debugging
- Enable Debug Center: Admin → Best-Teacher Award → Debug Center
- View audit logs: Admin → Best-Teacher Award → Audit Log
- System info: Admin → Best-Teacher Award → Debug Center → System Info

### Common WP-CLI Commands

```bash
# Plugin status
docker exec awardvantage_wpcli wp plugin list --allow-root

# View plugin version
docker exec awardvantage_wpcli wp plugin get best-teacher-award-class25 --field=version --allow-root

# Deactivate (if needed)
docker exec awardvantage_wpcli wp plugin deactivate best-teacher-award-class25 --allow-root

# Reactivate
docker exec awardvantage_wpcli wp plugin activate best-teacher-award-class25 --allow-root
```

---

## 🎯 Quick Start Summary

```bash
# 1. Deploy plugin
docker cp best-teacher-award-class25-v2.5.41-production.zip awardvantage_wordpress:/tmp/
docker exec awardvantage_wpcli wp plugin install /tmp/best-teacher-award-class25-v2.5.41-production.zip --activate --allow-root

# 2. Configure environment
docker exec awardvantage_wpcli wp config set WP_ENVIRONMENT_TYPE production --allow-root
docker exec awardvantage_wpcli wp config set MT_ENVIRONMENT production --allow-root

# 3. Flush everything
docker exec awardvantage_wpcli wp rewrite flush --allow-root
docker exec awardvantage_wpcli wp cache flush --allow-root

# 4. Verify installation
docker exec awardvantage_wpcli wp plugin verify best-teacher-award-class25 --allow-root
```

---

**Plugin Version:** 2.5.41-class25
**Compatible With:** WordPress 5.8+ | PHP 7.4+ | MariaDB 10.3+
**Deployment Date:** November 2024