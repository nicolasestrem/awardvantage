# Jury Member Test Accounts Documentation

**System:** Best-Teacher Award #class25
**Environment:** localhost:8080 (Development)
**Created:** 2025-11-12
**Status:** Test/Demo Accounts - NOT Production Ready

---

## Overview

The system currently has **30 test jury member accounts** pre-configured for testing and demonstration purposes. These accounts are NOT intended for production use and should be replaced with real jury member data before deployment.

---

## Current Jury Member Accounts

### Complete List (30 Accounts)

| # | Username | Display Name | Email | Role | Status |
|---|----------|--------------|-------|------|--------|
| 1 | jury01 | Jury Member 01 | jury01@awardvantage.com | Jury Member | Active |
| 2 | jury02 | Jury Member 02 | jury02@awardvantage.com | Jury Member | Active |
| 3 | jury03 | Jury Member 03 | jury03@awardvantage.com | Jury Member | Active |
| 4 | jury04 | Jury Member 04 | jury04@awardvantage.com | Jury Member | Active |
| 5 | jury05 | Jury Member 05 | jury05@awardvantage.com | Jury Member | Active |
| 6 | jury06 | Jury Member 06 | jury06@awardvantage.com | Jury Member | Active |
| 7 | jury07 | Jury Member 07 | jury07@awardvantage.com | Jury Member | Active |
| 8 | jury08 | Jury Member 08 | jury08@awardvantage.com | Jury Member | Active |
| 9 | jury09 | Jury Member 09 | jury09@awardvantage.com | Jury Member | Active |
| 10 | jury10 | Jury Member 10 | jury10@awardvantage.com | Jury Member | Active |
| 11 | jury11 | Jury Member 11 | jury11@awardvantage.com | Jury Member | Active |
| 12 | jury12 | Jury Member 12 | jury12@awardvantage.com | Jury Member | Active |
| 13 | jury13 | Jury Member 13 | jury13@awardvantage.com | Jury Member | Active |
| 14 | jury14 | Jury Member 14 | jury14@awardvantage.com | Jury Member | Active |
| 15 | jury15 | Jury Member 15 | jury15@awardvantage.com | Jury Member | Active |
| 16 | jury16 | Jury Member 16 | jury16@awardvantage.com | Jury Member | Active |
| 17 | jury17 | Jury Member 17 | jury17@awardvantage.com | Jury Member | Active |
| 18 | jury18 | Jury Member 18 | jury18@awardvantage.com | Jury Member | Active |
| 19 | jury19 | Jury Member 19 | jury19@awardvantage.com | Jury Member | Active |
| 20 | jury20 | Jury Member 20 | jury20@awardvantage.com | Jury Member | Active |
| 21 | jury21 | Jury Member 21 | jury21@awardvantage.com | Jury Member | Active |
| 22 | jury22 | Jury Member 22 | jury22@awardvantage.com | Jury Member | Active |
| 23 | jury23 | Jury Member 23 | jury23@awardvantage.com | Jury Member | Active |
| 24 | jury24 | Jury Member 24 | jury24@awardvantage.com | Jury Member | Active |
| 25 | jury25 | Jury Member 25 | jury25@awardvantage.com | Jury Member | Active |
| 26 | jury26 | Jury Member 26 | jury26@awardvantage.com | Jury Member | Active |
| 27 | jury27 | Jury Member 27 | jury27@awardvantage.com | Jury Member | Active |
| 28 | jury28 | Jury Member 28 | jury28@awardvantage.com | Jury Member | Active |
| 29 | jury29 | Jury Member 29 | jury29@awardvantage.com | Jury Member | Active |
| 30 | jury30 | Jury Member 30 | jury30@awardvantage.com | Jury Member | Active |

### Test Account Credentials

**Username Pattern:** `jury01` through `jury30`
**Password:** (Set during installation - typically `JuryDemo2025!` or similar)
**Email Domain:** `@awardvantage.com` (production catch-all domain)

---

## Account Architecture

### WordPress User Accounts
- **Total:** 30 user accounts
- **Role:** `mt_jury_member` (custom role)
- **Capabilities:**
  - Read candidate profiles
  - Submit evaluations
  - View assigned candidates only
  - Access jury dashboard
  - NO admin access
  - NO access to other jury evaluations

### Jury Member Profile Posts
- **Total:** 30 custom posts
- **Post Type:** `mt_jury_member`
- **Status:** All published
- **Content:** Each has a corresponding profile page
- **Linked:** Each user account is linked to a profile post

---

## Current Configuration

### Assignments
- **Status:** No assignments yet
- **Database:** `wp_mt_jury_assignments` table is empty
- **Candidates per jury:** Configured for 5 (in plugin settings)

### Evaluations
- **Status:** No evaluations submitted
- **Database:** `wp_mt_evaluations` table is empty
- **Scoring:** 0-10 scale with 0.5 increments

---

## Production Readiness Assessment

### ✅ Production Ready Configuration

These jury member accounts are configured for production use:

1. **Production Email Addresses**
   - Domain: `@awardvantage.com` (catch-all email domain)
   - Configured for production use
   - Can receive notification emails

2. **Gender-Neutral Display Names**
   - Names use "Jury Member XX" format (no gender assumptions)
   - Ready for assignment to actual jury members
   - Maintains privacy until accounts are personalized

3. **No Real Profiles**
   - Profile posts have no biographical information
   - No photos
   - No expertise/credentials listed

4. **Weak Security**
   - Sequential usernames (jury01-jury30) are predictable
   - Default passwords may be weak or shared

---

## Recommended Actions for Production

### Option 1: Replace with Real Jury Members

1. **Collect Real Jury Data**
   ```
   - Full name
   - Professional email address
   - Title/position
   - Organization
   - Bio/expertise (150-300 words)
   - Professional photo
   - LinkedIn profile (optional)
   ```

2. **Delete Test Accounts**
   ```bash
   # Delete all test jury accounts
   wp user delete $(wp user list --role=mt_jury_member --field=ID --allow-root) \
       --reassign=1 --yes --allow-root

   # Delete all test jury profile posts
   wp post delete $(wp post list --post_type=mt_jury_member --format=ids --allow-root) \
       --force --allow-root
   ```

3. **Create Real Accounts**
   ```bash
   # Example for one real jury member
   wp user create max.mustermann max.mustermann@university.edu \
       --role=mt_jury_member \
       --first_name=Max \
       --last_name=Mustermann \
       --display_name="Prof. Dr. Max Mustermann" \
       --user_pass="SecurePassword123!" \
       --send-email \
       --allow-root
   ```

4. **Create Profile Posts**
   - Go to: MT Award System → Jury Members → Add New
   - Add bio, photo, and link to user account
   - Publish profile

### Option 2: Keep for Testing + Add Real Accounts

1. **Keep test accounts for development/testing**
2. **Add real jury member accounts alongside**
3. **Clearly label test accounts** (e.g., prefix with "TEST-")
4. **Disable test accounts before production launch**

---

## Test Account Usage Guide

### For Development/Testing

1. **Login as Test Jury Member**
   - URL: http://localhost:8080/wp-login.php
   - Username: `jury01` (or jury02-jury30)
   - Password: (as configured)

2. **Access Jury Dashboard**
   - After login, you'll see the jury dashboard
   - Currently shows: "No candidates assigned yet"

3. **Test Evaluation Workflow**
   - Admin must first assign candidates to jury members
   - Then jury can view and evaluate assigned candidates
   - Scoring uses 5 criteria with 0-10 scale

### For Administrators

1. **Assign Candidates to Jury**
   - Go to: MT Award System → Assignments
   - Select a jury member
   - Check candidates to assign
   - Save assignments
   - Jury member receives email notification (if SMTP configured)

2. **View Evaluations**
   - Go to: MT Award System → Evaluations
   - See all submitted evaluations
   - Export to CSV for analysis

---

## Security Considerations

### Current Security Status: ⚠️ MODERATE (Test Environment)

- ✓ Custom user role with limited capabilities
- ✓ Jury members can only see assigned candidates
- ✓ Evaluations are private (not public)
- ✓ Audit logging enabled
- ✗ Weak/default passwords
- ✗ Predictable usernames
- ✗ No email verification possible
- ✗ No two-factor authentication

### Recommended for Production

1. **Strong Password Policy**
   - Minimum 16 characters
   - Mix of uppercase, lowercase, numbers, symbols
   - No dictionary words

2. **Unique Usernames**
   - Use real names or professional identifiers
   - Avoid sequential patterns (jury01, jury02...)

3. **Email Verification**
   - Use real email addresses
   - Verify email ownership on account creation
   - Enable password reset via email

4. **Two-Factor Authentication** (Optional but Recommended)
   - Install: Wordfence or similar 2FA plugin
   - Require 2FA for all jury members
   - Adds significant security layer

5. **Access Monitoring**
   - Review audit logs regularly
   - Monitor for suspicious login attempts
   - Set up login attempt limits

---

## Migration to Production

### Pre-Production Checklist

- [ ] Decision: Keep test accounts OR replace with real accounts?
- [ ] If replacing:
  - [ ] Collect real jury member data
  - [ ] Prepare professional photos
  - [ ] Write biographical content
  - [ ] Generate strong passwords
- [ ] If keeping:
  - [ ] Add "TEST-" prefix to usernames
  - [ ] Disable test accounts
  - [ ] Create separate real accounts
- [ ] Configure SMTP for email notifications
- [ ] Test email delivery to real addresses
- [ ] Set up password policies
- [ ] Enable audit logging
- [ ] Test assignment workflow
- [ ] Test evaluation submission
- [ ] Verify data export functionality

### Post-Production Checklist

- [ ] All test accounts disabled or deleted
- [ ] All real jury members have received login credentials
- [ ] All jury members have verified email addresses
- [ ] Password reset functionality tested
- [ ] Email notifications tested and working
- [ ] 2FA enabled (if using)
- [ ] Audit logging active and monitored
- [ ] Backup strategy in place

---

## Quick Commands Reference

```bash
# List all jury member accounts
wp user list --role=mt_jury_member --allow-root

# Count jury members
wp user list --role=mt_jury_member --format=count --allow-root

# Reset a jury member password
wp user update jury01 --user_pass="NewPassword123!" --allow-root

# List jury member profile posts
wp post list --post_type=mt_jury_member --allow-root

# Check assignments
wp eval 'global $wpdb; echo $wpdb->get_var("SELECT COUNT(*) FROM wp_mt_jury_assignments");' --allow-root

# Check evaluations
wp eval 'global $wpdb; echo $wpdb->get_var("SELECT COUNT(*) FROM wp_mt_evaluations");' --allow-root

# Delete ALL test jury accounts (CAUTION!)
wp user delete $(wp user list --role=mt_jury_member --field=ID --allow-root) --reassign=1 --yes --allow-root

# Delete ALL jury profile posts (CAUTION!)
wp post delete $(wp post list --post_type=mt_jury_member --format=ids --allow-root) --force --allow-root
```

---

## Questions for Decision

1. **Should we keep these 30 test accounts for testing, or replace them entirely?**
   - Keep: Useful for ongoing testing and demonstrations
   - Replace: Cleaner production environment

2. **Do you have real jury member data ready to import?**
   - If yes: Provide data in CSV or structured format
   - If no: Test accounts can remain for now

3. **How many real jury members do you need?**
   - Same 30?
   - Different number?

4. **What is the timeline for production deployment?**
   - Determines urgency of replacing test accounts
   - Affects password and security setup strategy

---

## Support Resources

- **WordPress User Management:** https://wordpress.org/support/article/users/
- **Plugin Documentation:** See `/Plugin/README.md`
- **Jury Dashboard:** http://localhost:8080/jury-dashboard/
- **Admin Panel:** http://localhost:8080/wp-admin/

---

**Document Version:** 1.0
**Last Updated:** 2025-11-13
**Next Review:** Before production deployment
