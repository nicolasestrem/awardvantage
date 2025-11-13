# Production Deployment Guide
**Best-Teacher Award #class25**

**Target Audience:** System Administrators / LLM Assistants
**Purpose:** Complete production deployment guide
**Version:** 1.0
**Date:** 2025-11-13

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Server Preparation](#server-preparation)
4. [Docker Setup](#docker-setup)
5. [WordPress Installation](#wordpress-installation)
6. [Plugin Installation](#plugin-installation)
7. [Database Configuration](#database-configuration)
8. [Data Import](#data-import)
9. [Jury Member Setup](#jury-member-setup)
10. [Verification](#verification)
11. [Security Hardening](#security-hardening)
12. [Troubleshooting](#troubleshooting)
13. [Rollback Procedures](#rollback-procedures)

---

## Overview

This guide provides step-by-step instructions for deploying the Best-Teacher Award #class25 system to a production server. The system has been fully configured and tested locally with:

- **38 production candidates** with German descriptions and LinkedIn URLs
- **30 jury member accounts** with gender-neutral names and production emails
- **2-criteria evaluation system** (didactic excellence + practical impact)
- **1,140 jury assignments** (complete matrix: 30 jury × 38 candidates)
- **100% production readiness** (all critical checks passed)

### System Architecture

```
Production Server
├── Docker Containers
│   ├── WordPress (PHP 8.2 + Apache)
│   ├── MariaDB 11
│   └── (Optional) Mailpit / SMTP
├── WordPress Core (6.8.3 German)
├── Plugin: Mobility Trailblazers v2.5.41-class25
├── Custom Database Tables (4)
└── Data: 38 candidates, 30 jury members
```

---

## Prerequisites

### Required Access
- [ ] Production server with SSH access
- [ ] Domain DNS control (awardvantage.com)
- [ ] GitHub repository access
- [ ] Docker/Docker Compose installed on server

### Required Software
- Docker Engine 20.10+
- Docker Compose 2.0+
- Git
- SSH client
- WP-CLI (will be installed in container)

### Required Information
- Server IP address
- Domain: awardvantage.com
- SSL certificate (Let's Encrypt recommended)
- Database credentials (will be generated)
- Admin email: nicolas.estrem@gmail.com

---

## Server Preparation

### Step 1: Connect to Production Server

```bash
# SSH into your production server
ssh user@your-production-server.com

# Update system packages
sudo apt update && sudo apt upgrade -y
```

### Step 2: Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Verify installation
docker --version
docker compose version
```

### Step 3: Create Project Directory

```bash
# Create project directory
sudo mkdir -p /var/www/awardvantage
sudo chown -R $USER:$USER /var/www/awardvantage
cd /var/www/awardvantage
```

---

## Docker Setup

### Step 1: Clone Repository

```bash
# Clone the repository
git clone https://github.com/nicolasestrem/awardvantage.git .

# Checkout the production-ready branch
git checkout complete-best-teacher-award-setup
```

### Step 2: Create Environment File

```bash
# Navigate to private directory
cd private

# Create .env file from example
cp ../.env.example .env

# Edit .env with production values
nano .env
```

**Required .env values:**
```env
# Database Configuration
MYSQL_ROOT_PASSWORD=<generate-strong-password>
MYSQL_DATABASE=awardvantage_prod
MYSQL_USER=awardvantage_user
MYSQL_PASSWORD=<generate-strong-password>

# WordPress Configuration
WORDPRESS_DB_HOST=db:3306
WORDPRESS_DB_NAME=awardvantage_prod
WORDPRESS_DB_USER=awardvantage_user
WORDPRESS_DB_PASSWORD=<same-as-MYSQL_PASSWORD>

# Domain Configuration
WORDPRESS_URL=https://awardvantage.com
WORDPRESS_HOME=https://awardvantage.com
```

### Step 3: Review Docker Compose Configuration

The `docker-compose-AV.yml` file should be configured for production:

```bash
# Review docker-compose-AV.yml
cat docker-compose-AV.yml
```

Key settings to verify:
- Port mapping: `8080:80` (or `80:80` for production)
- Volume persistence: `wp_data` and `db_data`
- Network isolation: `awardvantage_net`
- Health checks enabled

### Step 4: Start Docker Containers

```bash
# Start containers in detached mode
docker compose -f docker-compose-AV.yml up -d

# Verify containers are running
docker ps

# Check logs
docker logs awardvantage-wordpress-1
docker logs awardvantage-db-1
```

**Expected output:**
```
awardvantage-wordpress-1  running
awardvantage-db-1        running (healthy)
```

---

## WordPress Installation

### Step 1: Initial WordPress Setup

```bash
# Access WordPress installation
# Open browser: http://your-server-ip:8080

# OR use WP-CLI for automated setup:
docker exec awardvantage-wordpress-1 wp core install \
  --url="https://awardvantage.com" \
  --title="Best-Teacher Award" \
  --admin_user="admin" \
  --admin_password="<generate-strong-password>" \
  --admin_email="nicolas.estrem@gmail.com" \
  --allow-root
```

### Step 2: Configure WordPress Settings

```bash
# Set German language
docker exec awardvantage-wordpress-1 wp language core install de_DE --allow-root
docker exec awardvantage-wordpress-1 wp language core activate de_DE --allow-root

# Set timezone
docker exec awardvantage-wordpress-1 wp option update timezone_string 'Europe/Berlin' --allow-root

# Set permalink structure
docker exec awardvantage-wordpress-1 wp rewrite structure '/%postname%/' --allow-root
docker exec awardvantage-wordpress-1 wp rewrite flush --allow-root
```

---

## Plugin Installation

### Step 1: Copy Plugin Files

The plugin is already included in the repository under `/import/best-teacher-award-class25/Plugin/`.

```bash
# Copy plugin to WordPress plugins directory
docker cp /var/www/awardvantage/import/best-teacher-award-class25/Plugin \
  awardvantage-wordpress-1:/var/www/html/wp-content/plugins/mobility-trailblazers

# Set correct permissions
docker exec awardvantage-wordpress-1 chown -R www-data:www-data \
  /var/www/html/wp-content/plugins/mobility-trailblazers
```

### Step 2: Activate Plugin

```bash
# Activate the plugin
docker exec awardvantage-wordpress-1 wp plugin activate mobility-trailblazers --allow-root

# Verify plugin is active
docker exec awardvantage-wordpress-1 wp plugin list --allow-root
```

**Expected output:**
```
mobility-trailblazers  2.5.41-class25  active
```

---

## Database Configuration

The plugin automatically creates necessary database tables on activation. However, we need to add the 2-criteria evaluation columns.

### Step 1: Add Evaluation Columns

```bash
# Copy the script to container
docker cp /var/www/awardvantage/scripts/add-evaluation-columns.php \
  awardvantage-wordpress-1:/tmp/

# Execute the script
docker exec awardvantage-wordpress-1 wp eval-file \
  /tmp/add-evaluation-columns.php --allow-root
```

**Expected output:**
```
Adding column: didactic_excellence_score... SUCCESS
Adding column: practical_impact_score... SUCCESS
✓ All columns verified successfully!
```

### Step 2: Verify Database Tables

```bash
# List custom tables
docker exec awardvantage-wordpress-1 wp eval \
  'global $wpdb; echo implode("\n", $wpdb->get_col("SHOW TABLES LIKE \"wp_mt_%\""));' \
  --allow-root
```

**Expected tables:**
```
wp_mt_evaluations
wp_mt_jury_assignments
wp_mt_audit_log
wp_mt_error_log
```

---

## Data Import

### Step 1: Import Candidates

```bash
# Copy import script
docker cp /var/www/awardvantage/scripts/import-38-candidates.php \
  awardvantage-wordpress-1:/tmp/

# Execute import
docker exec awardvantage-wordpress-1 wp eval-file \
  /tmp/import-38-candidates.php --allow-root
```

**Expected output:**
```
Candidates created: 38
Failed imports:     0
Total published candidates in system: 38
✓ Exactly 38 candidates as expected!
```

### Step 2: Update LinkedIn URLs

```bash
# Copy script
docker cp /var/www/awardvantage/scripts/update-linkedin-urls.php \
  awardvantage-wordpress-1:/tmp/

# Execute
docker exec awardvantage-wordpress-1 wp eval-file \
  /tmp/update-linkedin-urls.php --allow-root
```

**Expected output:**
```
LinkedIn URLs updated: 38
Photo URLs stored: 21
```

### Step 3: Add German Descriptions

```bash
# Copy script
docker cp /var/www/awardvantage/scripts/update-german-descriptions.php \
  awardvantage-wordpress-1:/tmp/

# Execute
docker exec awardvantage-wordpress-1 wp eval-file \
  /tmp/update-german-descriptions.php --allow-root
```

**Expected output:**
```
Descriptions updated: 37
Candidates skipped: 1
```

### Step 4: Download Candidate Photos

```bash
# Copy script
docker cp /var/www/awardvantage/scripts/download-candidate-photos.php \
  awardvantage-wordpress-1:/tmp/

# Execute
docker exec awardvantage-wordpress-1 wp eval-file \
  /tmp/download-candidate-photos.php --allow-root
```

**Expected output:**
```
Photos downloaded: 19
Photos skipped: 0
Failed downloads: 2
```

---

## Jury Member Setup

### Step 1: Verify Jury Members Exist

The 30 jury members should already exist from the plugin activation. Verify:

```bash
# Count jury members
docker exec awardvantage-wordpress-1 wp post list \
  --post_type=mt_jury_member --format=count --allow-root
```

**Expected output:** `30`

### Step 2: Update to Gender-Neutral Names

```bash
# Copy update script
docker cp /var/www/awardvantage/scripts/update-jury-to-gender-neutral.php \
  awardvantage-wordpress-1:/tmp/

# Execute
docker exec awardvantage-wordpress-1 wp eval-file \
  /tmp/update-jury-to-gender-neutral.php --allow-root
```

**Expected output:**
```
WordPress Users:
  Updated: 30
  Failed:  0

Jury Member Posts:
  Updated: 30
  Failed:  0

✓ SUCCESS: All 60 records updated (30 users + 30 posts)
```

### Step 3: Link Jury Members to Users

```bash
# Copy script
docker cp /var/www/awardvantage/scripts/link-jury-users.php \
  awardvantage-wordpress-1:/tmp/

# Execute
docker exec awardvantage-wordpress-1 wp eval-file \
  /tmp/link-jury-users.php --allow-root
```

**Expected output:**
```
Jury members linked: 30
Failed links: 0
```

### Step 4: Create Jury Assignments

```bash
# Copy script
docker cp /var/www/awardvantage/scripts/create-jury-assignments.php \
  awardvantage-wordpress-1:/tmp/

# Execute
docker exec awardvantage-wordpress-1 wp eval-file \
  /tmp/create-jury-assignments.php --allow-root
```

**Expected output:**
```
Assignments created: 1140
Assignments skipped: 0
Expected: 1140 (30 jury × 38 candidates)
Total assignments in database: 1140
```

---

## Verification

### Step 1: Run Production Readiness Check

```bash
# Copy verification script
docker cp /var/www/awardvantage/scripts/production-readiness-check.php \
  awardvantage-wordpress-1:/tmp/

# Execute
docker exec awardvantage-wordpress-1 wp eval-file \
  /tmp/production-readiness-check.php --allow-root
```

**Expected output:**
```
Checks Passed: 12
Checks Failed: 0
Warnings: 3

Pass Rate: 100.0%

⚠ STATUS: PRODUCTION READY WITH WARNINGS
```

### Step 2: Database Optimization

```bash
# Copy optimization script
docker cp /var/www/awardvantage/scripts/database-optimization.php \
  awardvantage-wordpress-1:/tmp/

# Execute
docker exec awardvantage-wordpress-1 wp eval-file \
  /tmp/database-optimization.php --allow-root
```

**Expected output:**
```
✓ All custom tables optimized
✓ Data integrity checks completed
✓ 2-criteria system verified
✓ No data integrity issues found
```

### Step 3: Test Evaluation Submission

```bash
# Copy test script
docker cp /var/www/awardvantage/scripts/test-evaluation-submission.php \
  awardvantage-wordpress-1:/tmp/

# Execute
docker exec awardvantage-wordpress-1 wp eval-file \
  /tmp/test-evaluation-submission.php --allow-root
```

**Expected output:**
```
SUCCESS - Evaluation created with ID: 1
✓ Evaluation created successfully
✓ 2 new criteria scores saved correctly
```

### Step 4: Test Jury Login

```bash
# Test jury member login
# Open browser: https://awardvantage.com/wp-login.php
# Username: jury01
# Password: (Use the password set during Step 3.5)

# Or verify via CLI:
docker exec awardvantage-wordpress-1 wp user get jury01 --allow-root
```

---

## Security Hardening

### Step 1: SSL/HTTPS Setup

```bash
# Install Certbot for Let's Encrypt
sudo apt install certbot python3-certbot-apache -y

# Obtain SSL certificate
sudo certbot --apache -d awardvantage.com -d www.awardvantage.com

# Verify auto-renewal
sudo certbot renew --dry-run
```

### Step 2: Change Default Passwords

```bash
# Change admin password
docker exec awardvantage-wordpress-1 wp user update admin \
  --user_pass="<new-strong-password>" --allow-root

# Change jury passwords (example for jury01)
docker exec awardvantage-wordpress-1 wp user update jury01 \
  --user_pass="<unique-strong-password>" --allow-root

# Repeat for all jury members jury01-jury30
```

### Step 3: Install Security Plugins

```bash
# Install Wordfence
docker exec awardvantage-wordpress-1 wp plugin install wordfence --activate --allow-root

# Configure firewall (via WordPress admin)
```

### Step 4: Disable WP_DEBUG

```bash
# Edit wp-config.php
docker exec awardvantage-wordpress-1 sed -i \
  "s/define( 'WP_DEBUG', true );/define( 'WP_DEBUG', false );/" \
  /var/www/html/wp-config.php
```

### Step 5: Set Up Backups

```bash
# Install backup plugin
docker exec awardvantage-wordpress-1 wp plugin install \
  updraftplus --activate --allow-root

# Or use external backup solution
# Example: Daily database backup
cat > /etc/cron.daily/backup-awardvantage << 'EOF'
#!/bin/bash
docker exec awardvantage-db-1 mysqldump -u root -p<password> \
  awardvantage_prod > /backups/awardvantage-$(date +%Y%m%d).sql
EOF

chmod +x /etc/cron.daily/backup-awardvantage
```

---

## Troubleshooting

### Database Connection Issues

```bash
# Check database container
docker logs awardvantage-db-1

# Test database connection
docker exec awardvantage-wordpress-1 wp db check --allow-root

# Reset database connection
docker compose -f docker-compose-AV.yml restart wordpress
```

### Plugin Not Activating

```bash
# Check plugin files
docker exec awardvantage-wordpress-1 ls -la \
  /var/www/html/wp-content/plugins/mobility-trailblazers/

# Check permissions
docker exec awardvantage-wordpress-1 chown -R www-data:www-data \
  /var/www/html/wp-content/plugins/

# Check PHP errors
docker exec awardvantage-wordpress-1 tail -f \
  /var/www/html/wp-content/debug.log
```

### Missing Data After Import

```bash
# Verify post count
docker exec awardvantage-wordpress-1 wp post list \
  --post_type=mt_candidate --format=count --allow-root

# Re-run import scripts if needed
# (They are idempotent and safe to re-run)
```

### Evaluation Form Not Working

```bash
# Verify evaluation columns exist
docker exec awardvantage-wordpress-1 wp eval \
  'global $wpdb; print_r($wpdb->get_results("DESCRIBE wp_mt_evaluations"));' \
  --allow-root

# Check for JavaScript errors in browser console
```

---

## Rollback Procedures

### Rollback Database

```bash
# Stop containers
docker compose -f docker-compose-AV.yml down

# Restore from backup
docker run -v awardvantage_db_data:/var/lib/mysql \
  -v /backups:/backup --rm mariadb:11 \
  bash -c "mysql -u root -p<password> awardvantage_prod < /backup/awardvantage-<date>.sql"

# Restart containers
docker compose -f docker-compose-AV.yml up -d
```

### Rollback to Previous Version

```bash
# Stop containers
docker compose -f docker-compose-AV.yml down

# Checkout previous version
git checkout <previous-commit-hash>

# Restart containers
docker compose -f docker-compose-AV.yml up -d
```

---

## Post-Deployment Checklist

- [ ] All Docker containers running and healthy
- [ ] WordPress accessible at https://awardvantage.com
- [ ] SSL certificate installed and working
- [ ] 38 candidates imported and visible
- [ ] 30 jury members updated to gender-neutral names
- [ ] All emails using @awardvantage.com domain
- [ ] 1,140 jury assignments created
- [ ] Evaluation system tested (2 criteria)
- [ ] Test jury login works (jury01-jury30)
- [ ] Admin login works
- [ ] Database backups configured
- [ ] Security plugins installed
- [ ] WP_DEBUG disabled
- [ ] Default passwords changed
- [ ] Production readiness check: 100% pass

---

## Support & Documentation

### Key Documentation Files

- `DEPLOYMENT-SUMMARY.md` - Complete deployment summary
- `JURY-MEMBER-ACCOUNTS.md` - Jury account details
- `PRODUCTION-READINESS-CHECKLIST.md` - Production checklist
- `SYSTEM-VERIFICATION-REPORT.md` - System verification results

### Scripts Directory

All scripts are located in `/scripts/`:
- `import-38-candidates.php`
- `update-linkedin-urls.php`
- `update-german-descriptions.php`
- `download-candidate-photos.php`
- `update-jury-to-gender-neutral.php`
- `link-jury-users.php`
- `create-jury-assignments.php`
- `add-evaluation-columns.php`
- `database-optimization.php`
- `production-readiness-check.php`
- `test-evaluation-submission.php`

### Contact Information

- **Repository:** https://github.com/nicolasestrem/awardvantage
- **Admin Email:** nicolas.estrem@gmail.com
- **Domain:** awardvantage.com

---

**Deployment Guide Version:** 1.0
**Last Updated:** 2025-11-13
**System Status:** Production Ready
**Pass Rate:** 100% (12/12 critical checks)

---

## Quick Reference Commands

```bash
# Check system status
docker ps
docker logs awardvantage-wordpress-1
docker exec awardvantage-wordpress-1 wp plugin list --allow-root

# Verify data
docker exec awardvantage-wordpress-1 wp post list --post_type=mt_candidate --format=count --allow-root
docker exec awardvantage-wordpress-1 wp user list --role=mt_jury_member --format=count --allow-root

# Run verification
docker exec awardvantage-wordpress-1 wp eval-file /tmp/production-readiness-check.php --allow-root

# Database backup
docker exec awardvantage-db-1 mysqldump -u root -p<password> awardvantage_prod > backup.sql

# Restart services
docker compose -f docker-compose-AV.yml restart
```

---

**END OF PRODUCTION DEPLOYMENT GUIDE**
