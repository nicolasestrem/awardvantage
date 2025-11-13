# Production Readiness Checklist & Migration Guide
**Best-Teacher Award #class25**
**Version:** 1.0
**Date:** 2025-11-13

---

## Quick Status Overview

| Category | Status | % Complete |
|----------|--------|------------|
| **WordPress Core** | ✅ Ready | 100% |
| **Plugin Installation** | ✅ Ready | 100% |
| **Database Setup** | ✅ Ready | 100% |
| **Content Quality** | ⚠️ Issues | 60% |
| **Jury Setup** | ⚠️ Not Ready | 30% |
| **Testing** | ⚠️ Partial | 40% |
| **Overall Readiness** | ⚠️ Needs Work | 65% |

---

## Pre-Production Checklist

### Phase 1: Critical Issues (MUST FIX)

#### ☐ 1.1 Remove Duplicate Candidates
**Status:** 🔴 NOT DONE
**Time:** 5 minutes
**Priority:** HIGH

**Action:**
```bash
docker exec awardvantage-wordpress-1 wp eval-file scripts/source-candidate-photos.php --mode=cleanup --allow-root
```

**Verification:**
```bash
docker exec awardvantage-wordpress-1 wp post list --post_type=mt_candidate --format=count --allow-root
# Should show 55 instead of 58
```

**Impact if skipped:** Data confusion, potential evaluation errors

---

#### ☐ 1.2 Decide on Final Candidate List
**Status:** 🔴 DECISION NEEDED
**Time:** 30 minutes (discussion)
**Priority:** HIGH

**Options:**
- **Option A:** Keep all 55 unique candidates
- **Option B:** Keep only documented 38 German profiles, delete 17 additional ones

**Questions to answer:**
1. Where did the 20 additional candidates (IDs 105-124) come from?
2. Are they valid Best-Teacher Award candidates?
3. Do you want 38 or 55 candidates in the final system?

**If choosing Option B (keep only 38):**
```bash
# Delete the 17 additional candidates (after confirming IDs)
docker exec awardvantage-wordpress-1 wp post delete 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 --force --allow-root
```

---

#### ☐ 1.3 Source Missing Candidate Photos
**Status:** 🟡 IN PROGRESS
**Time:** 3-5 hours
**Priority:** HIGH

**Current Status:**
- ✓ Photo audit complete (CANDIDATES-PHOTO-AUDIT.md)
- ✓ Photo sourcing script created
- ✗ Photos not yet downloaded

**Action:**
```bash
# Generate download checklist
docker exec awardvantage-wordpress-1 wp eval-file scripts/source-candidate-photos.php --mode=download-list --allow-root
```

**Manual Steps:**
1. Open: `/photo-sourcing-reports/photo-download-checklist-*.txt`
2. Visit each LinkedIn URL
3. Right-click profile photo → Save As
4. Save to: `/private/candidate-photos/[Name].jpg`
5. Upload to WordPress via admin panel or import script

**Missing Photos Count:**
- After removing duplicates: 35 candidates need photos
- 1 candidate has no LinkedIn URL (Maja Göpel - need manual search)

**Impact if skipped:** Unprofessional appearance, incomplete profiles

---

#### ☐ 1.4 Replace Test Jury Accounts
**Status:** 🔴 NOT DONE
**Time:** 2-4 hours
**Priority:** HIGH

**Current Status:**
- 30 accounts with production emails (@awardvantage.com catch-all)
- Gender-neutral names (Jury Member 01-30), no bios, no photos

**Decision Needed:**
- Do you have real jury member data ready?
- How many real jury members do you need?

**If replacing ALL test accounts:**

1. **Collect Real Jury Data:**
   - Full names
   - Professional email addresses
   - Titles/positions
   - Organizations
   - Bios (150-300 words)
   - Professional photos

2. **Delete Test Accounts:**
   ```bash
   # CAUTION: This deletes all 30 test accounts
   docker exec awardvantage-wordpress-1 wp user delete $(docker exec awardvantage-wordpress-1 wp user list --role=mt_jury_member --field=ID --allow-root) --reassign=1 --yes --allow-root

   # Delete test profile posts
   docker exec awardvantage-wordpress-1 wp post delete $(docker exec awardvantage-wordpress-1 wp post list --post_type=mt_jury_member --format=ids --allow-root) --force --allow-root
   ```

3. **Create Real Accounts:**
   ```bash
   # Example for one jury member
   docker exec awardvantage-wordpress-1 wp user create max.mustermann max.mustermann@university.edu \
       --role=mt_jury_member \
       --first_name=Max \
       --last_name=Mustermann \
       --display_name="Prof. Dr. Max Mustermann" \
       --user_pass="SecurePassword123!" \
       --send-email \
       --allow-root
   ```

4. **Create Profile Posts:**
   - Via WordPress admin: MT Award System → Jury Members → Add New
   - Add bio, photo, link to user account

**If keeping test accounts temporarily:**
- Add prefix "TEST-" to usernames
- Disable accounts before production
- Create real accounts alongside

**Impact if skipped:** Cannot send real invitations, unprofessional

---

### Phase 2: Testing & Verification (SHOULD DO)

#### ☐ 2.1 Test Complete Evaluation Workflow
**Status:** 🟡 PARTIALLY TESTED
**Time:** 2 hours
**Priority:** MEDIUM

**Test Steps:**
1. ☐ Admin login works
2. ☐ Can access all MT Award System pages
3. ☐ Can create jury assignments
4. ☐ Jury member login works
5. ☐ Jury dashboard displays correctly
6. ☐ Evaluation form loads with 5 criteria
7. ☐ Can submit evaluation scores
8. ☐ Evaluation saves to database
9. ☐ Can view all evaluations in admin
10. ☐ Can export evaluations to CSV

**Test Script:**
```bash
# 1. Assign jury01 to 5 candidates
#    (Do this via admin panel: MT Award System → Assignments)

# 2. Login as jury01
#    URL: http://localhost:8080/wp-login.php
#    User: jury01, Password: [your password]

# 3. Submit test evaluations

# 4. Verify in database
docker exec awardvantage-db-1 mariadb -uaward -pawardpasssfdasdfasdfasdf awardvantage -e "SELECT COUNT(*) FROM wp_mt_evaluations;"

# 5. Export to CSV via admin panel
```

---

#### ☐ 2.2 Test German Language Implementation
**Status:** ✅ VERIFIED
**Time:** 15 minutes
**Priority:** LOW

**Verification:**
```bash
docker exec awardvantage-wordpress-1 wp option get WPLANG --allow-root
# Should output: de_DE
```

**Manual Checks:**
- ☐ Admin interface in German
- ☐ Jury dashboard in German
- ☐ Evaluation form labels in German
- ☐ Error messages in German

---

#### ☐ 2.3 Security Verification
**Status:** ⚠️ NEEDS REVIEW
**Time:** 30 minutes
**Priority:** MEDIUM

**Security Checklist:**
- ☐ WordPress admin password is strong (20+ chars)
- ☐ Jury member passwords are strong
- ☐ WP_DEBUG is set to false
- ☐ File editing is disabled (DISALLOW_FILE_EDIT = true)
- ☐ wp-config.php has secure salts/keys
- ☐ Database password is strong
- ☐ No test/default credentials remain

**Actions:**
```bash
# Check debug mode
docker exec awardvantage-wordpress-1 wp config get WP_DEBUG --allow-root

# Should be false for production

# Change admin password
docker exec awardvantage-wordpress-1 wp user update Nicolas --user_pass="NewStrongPassword123!" --allow-root
```

---

#### ☐ 2.4 Database Optimization
**Status:** ✅ SCRIPT READY
**Time:** 10 minutes
**Priority:** LOW

**Action:**
```bash
bash scripts/database-maintenance.sh full
```

**This performs:**
- Database health check
- Table optimization
- Cleanup of old data (revisions, trash, spam)
- Orphaned meta cleanup

---

### Phase 3: Optional Enhancements (NICE TO HAVE)

#### ☐ 3.1 Configure SMTP for Email Notifications
**Status:** 🔴 NOT CONFIGURED
**Time:** 30 minutes
**Priority:** OPTIONAL (per user request to skip)

**If you change your mind:**

1. Install WP Mail SMTP plugin:
   ```bash
   docker exec awardvantage-wordpress-1 wp plugin install wp-mail-smtp --activate --allow-root
   ```

2. Configure via: Settings → WP Mail SMTP

3. Test email:
   ```bash
   docker exec awardvantage-wordpress-1 wp eval 'wp_mail("test@example.com", "Test", "Test email");' --allow-root
   ```

---

#### ☐ 3.2 Enable SSL/HTTPS
**Status:** 🔴 NOT CONFIGURED
**Time:** 1 hour
**Priority:** MEDIUM

**For Production Domain:**
1. Obtain SSL certificate (Let's Encrypt, Cloudflare, etc.)
2. Configure in Docker/Apache
3. Update WordPress URLs:
   ```bash
   docker exec awardvantage-wordpress-1 wp option update siteurl "https://your-domain.com" --allow-root
   docker exec awardvantage-wordpress-1 wp option update home "https://your-domain.com" --allow-root
   ```

---

#### ☐ 3.3 Performance Optimization
**Status:** 🔴 NOT DONE
**Time:** 1-2 hours
**Priority:** LOW

**Optional Enhancements:**
- Install caching plugin (WP Super Cache, W3 Total Cache)
- Optimize images (Smush, Imagify)
- Enable CDN (Cloudflare)
- Database query optimization

---

## Migration Guide: localhost → Production

### Preparation

1. **Export Database**
   ```bash
   docker exec awardvantage-wordpress-1 wp db export /tmp/awardvantage-production.sql --allow-root
   docker cp awardvantage-wordpress-1:/tmp/awardvantage-production.sql ./awardvantage-production.sql
   ```

2. **Export Plugin Files**
   ```bash
   cd /mnt/c/Users/nicol/Desktop/awardvantage
   tar -czf best-teacher-award-plugin.tar.gz import/best-teacher-award-class25/Plugin/
   ```

3. **Export Uploaded Media**
   ```bash
   # If you have uploaded media files
   docker exec awardvantage-wordpress-1 tar -czf /tmp/uploads.tar.gz wp-content/uploads/
   docker cp awardvantage-wordpress-1:/tmp/uploads.tar.gz ./uploads.tar.gz
   ```

### On Production Server

1. **Install WordPress**
   ```bash
   # Fresh WordPress installation
   wp core download --locale=de_DE
   wp config create --dbname=proddb --dbuser=produser --dbpass=prodpass
   wp core install --url="https://production-domain.com" --title="Best-Teacher Award" --admin_user=admin --admin_email=admin@example.com
   ```

2. **Upload Plugin**
   ```bash
   tar -xzf best-teacher-award-plugin.tar.gz -C /var/www/html/wp-content/plugins/
   wp plugin activate best-teacher-award-class25
   ```

3. **Import Database**
   ```bash
   # Import and update URLs
   wp db import awardvantage-production.sql
   wp search-replace "http://localhost:8080" "https://production-domain.com"
   wp search-replace "localhost:8080" "production-domain.com"
   ```

4. **Upload Media**
   ```bash
   tar -xzf uploads.tar.gz -C /var/www/html/wp-content/
   ```

5. **Flush Caches**
   ```bash
   wp cache flush
   wp rewrite flush
   ```

6. **Test Everything**
   - Admin login
   - Jury login
   - Evaluation workflow
   - Data integrity

---

## Final Pre-Launch Checklist

###Before Going Live:

- ☐ All duplicate candidates removed
- ☐ Final candidate list confirmed (38 or 55)
- ☐ All candidate photos uploaded
- ☐ All test jury accounts replaced with real accounts
- ☐ Real jury members have received login credentials
- ☐ Full evaluation workflow tested end-to-end
- ☐ Database optimized
- ☐ WordPress admin password changed
- ☐ All jury passwords are strong
- ☐ WP_DEBUG set to false
- ☐ SSL certificate installed (if using HTTPS)
- ☐ SMTP configured and tested (if using email)
- ☐ Production domain configured
- ☐ Database backed up (if you change your mind about backups!)

### Post-Launch Monitoring:

- ☐ Monitor audit logs daily (first week)
- ☐ Check for errors in debug log
- ☐ Verify email delivery (if configured)
- ☐ Monitor database size
- ☐ Check system performance
- ☐ Gather user feedback

---

## Quick Command Reference

```bash
# System status
docker ps
docker exec awardvantage-wordpress-1 wp core version --allow-root

# Remove duplicates
docker exec awardvantage-wordpress-1 wp eval-file scripts/source-candidate-photos.php --mode=cleanup --allow-root

# Generate photo checklist
docker exec awardvantage-wordpress-1 wp eval-file scripts/source-candidate-photos.php --mode=report --allow-root

# Database maintenance
bash scripts/database-maintenance.sh full

# Count candidates
docker exec awardvantage-wordpress-1 wp post list --post_type=mt_candidate --format=count --allow-root

# Count jury members
docker exec awardvantage-wordpress-1 wp user list --role=mt_jury_member --format=count --allow-root

# Check evaluations
docker exec awardvantage-db-1 mariadb -uaward -pawardpasssfdasdfasdfasdf awardvantage -e "SELECT COUNT(*) FROM wp_mt_evaluations;"

# Export database
docker exec awardvantage-wordpress-1 wp db export /tmp/backup.sql --allow-root
```

---

## Support & Troubleshooting

### Common Issues

**Issue: Can't login as jury member**
```bash
# Reset password
docker exec awardvantage-wordpress-1 wp user update jury01 --user_pass="NewPassword123!" --allow-root
```

**Issue: Evaluation not saving**
```bash
# Check database connection
docker exec awardvantage-db-1 mariadb -uaward -pawardpasssfdasdfasdfasdf awardvantage -e "SELECT 1;"

# Check evaluations table
docker exec awardvantage-db-1 mariadb -uaward -pawardpasssfdasdfasdfasdf awardvantage -e "DESCRIBE wp_mt_evaluations;"
```

**Issue: Photos not displaying**
```bash
# Check media permissions
docker exec awardvantage-wordpress-1 ls -la wp-content/uploads/

# Regenerate thumbnails
docker exec awardvantage-wordpress-1 wp media regenerate --yes --allow-root
```

**Issue: 404 errors on candidate pages**
```bash
# Flush permalinks
docker exec awardvantage-wordpress-1 wp rewrite flush --allow-root
```

---

## Documentation Files Reference

1. **SYSTEM-VERIFICATION-REPORT.md** - Complete system audit
2. **CANDIDATES-PHOTO-AUDIT.md** - Photo sourcing guide
3. **JURY-MEMBER-ACCOUNTS.md** - Jury account documentation
4. **PRODUCTION-READINESS-CHECKLIST.md** - This file
5. **INSTALLATION-GUIDE.md** - Original installation instructions

---

## Estimated Time to Production

| Task | Time | Status |
|------|------|--------|
| Remove duplicates | 5 min | Not done |
| Decide candidate list | 30 min | Decision needed |
| Source photos | 3-5 hrs | Not done |
| Replace jury accounts | 2-4 hrs | Not done |
| Full workflow testing | 2 hrs | Partial |
| Database optimization | 10 min | Script ready |
| Security hardening | 30 min | Needs review |
| **Total** | **8-12 hours** | **65% ready** |

---

## Questions? Decisions Needed?

1. **Candidate List:** Keep all 55 or only 38?
2. **Additional Candidates:** Where did IDs 105-124 come from?
3. **Jury Members:** Do you have real jury data ready?
4. **Timeline:** When do you need this live?
5. **Photos:** Should I proceed with LinkedIn downloads?
6. **SMTP:** Do you want email notifications enabled?

**Contact:** See project documentation for support resources

---

**Checklist Version:** 1.0
**Last Updated:** 2025-11-13
**Next Review:** After completing Phase 1 tasks

---

## Ready to Deploy?

Once all items in Phase 1 are checked off:
✅ You're ready for production deployment!

Until then:
⚠️ System is ready for testing but NOT production-ready
