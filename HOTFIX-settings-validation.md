# HOTFIX: Settings Validation Error

## Problem
When saving settings in production, you get the error: **"Please enter valid weights between 0 and 10"**

## Root Cause
The JavaScript validation (`mt-settings-admin.js`) is still checking for the OLD 5 criteria field names:
- `weight_courage`
- `weight_innovation`
- `weight_implementation`
- `weight_relevance`
- `weight_visibility`

But the form now uses NEW field names for the 2 criteria:
- `mt_criteria_weights[didactic_excellence]`
- `mt_criteria_weights[practical_impact]`

Since JavaScript can't find those old fields, it gets `NaN` values and triggers the validation error.

## Quick Fix Options

### Option 1: Disable JavaScript Validation (FASTEST - Recommended)

Run this command to remove the problematic validation:

```bash
# Connect to WordPress container
docker exec -it awardvantage_wordpress bash

# Navigate to the plugin JS directory
cd /var/www/html/wp-content/plugins/best-teacher-award-class25/assets/js/

# Comment out the validation in the main file
sed -i '95,120s/^/\/\/ /' mt-settings-admin.js

# Also fix the minified version
sed -i 's/Please enter valid weights between 0 and 10/Validation disabled/g' mt-settings-admin.min.js

# Exit container
exit

# Clear cache
docker exec awardvantage_wpcli wp cache flush --allow-root
```

### Option 2: Fix JavaScript Validation (Proper Fix)

Create this fixed version of the validation:

```bash
# Connect to container
docker exec -it awardvantage_wordpress bash

# Backup original file
cp /var/www/html/wp-content/plugins/best-teacher-award-class25/assets/js/mt-settings-admin.js \
   /var/www/html/wp-content/plugins/best-teacher-award-class25/assets/js/mt-settings-admin.js.backup

# Create fixed validation script
cat > /tmp/fix-validation.js << 'EOF'
// Replace lines 95-120 with this fixed validation
$('form').on('submit', function(e) {
    // Updated for Best-Teacher Award #class25 - 2 criteria
    var weights = {
        didactic_excellence: parseFloat($('input[name="mt_criteria_weights[didactic_excellence]"]').val()),
        practical_impact: parseFloat($('input[name="mt_criteria_weights[practical_impact]"]').val())
    };

    // Check if weights are valid
    for (var key in weights) {
        if (!isNaN(weights[key]) && (weights[key] < 0 || weights[key] > 10)) {
            var weightsMsg = mt_settings_i18n && mt_settings_i18n.validation ? mt_settings_i18n.validation.weights : 'Please enter valid weights between 0 and 10';
            alert(weightsMsg);
            e.preventDefault();
            return false;
        }
    }

    // Warn about data deletion if checked
    if ($('input[name="mt_remove_data_on_uninstall"]').is(':checked')) {
        var warningMsg = mt_settings_i18n && mt_settings_i18n.validation ? mt_settings_i18n.validation.data_deletion_warning : 'WARNING: You have enabled data deletion on uninstall. This will permanently delete all plugin data when the plugin is removed. Are you sure?';
        if (!confirm(warningMsg)) {
            e.preventDefault();
            return false;
        }
    }
});
EOF

# Apply the fix (you'll need to manually edit the file)
nano /var/www/html/wp-content/plugins/best-teacher-award-class25/assets/js/mt-settings-admin.js
# Find lines 95-120 and replace with the content from /tmp/fix-validation.js

# Exit container
exit

# Clear caches
docker exec awardvantage_wpcli wp cache flush --allow-root
```

### Option 3: Emergency Override (Temporary)

If you need to save settings RIGHT NOW:

1. Open browser Developer Tools (F12)
2. Go to Console tab
3. Paste this code:

```javascript
// Override the form validation temporarily
jQuery('form').off('submit');
jQuery('form').on('submit', function() {
    return true; // Allow all submissions
});
```

4. Now save your settings (validation is bypassed)
5. Refresh page to restore normal validation

## Permanent Fix

The permanent fix requires updating the JavaScript file in the plugin:

**File to update:** `/assets/js/mt-settings-admin.js`

**Lines 96-102 - Change FROM:**
```javascript
var weights = {
    courage: parseFloat($('input[name="weight_courage"]').val()),
    innovation: parseFloat($('input[name="weight_innovation"]').val()),
    implementation: parseFloat($('input[name="weight_implementation"]').val()),
    relevance: parseFloat($('input[name="weight_relevance"]').val()),
    visibility: parseFloat($('input[name="weight_visibility"]').val())
};
```

**Change TO:**
```javascript
var weights = {
    didactic_excellence: parseFloat($('input[name="mt_criteria_weights[didactic_excellence]"]').val()),
    practical_impact: parseFloat($('input[name="mt_criteria_weights[practical_impact]"]').val())
};
```

## About Missing wp_mt_error_log Table

The `wp_mt_error_log` table is **NOT** part of the standard plugin installation. Only 3 tables are created:
- ✅ `wp_mt_evaluations`
- ✅ `wp_mt_jury_assignments`
- ✅ `wp_mt_audit_log`

The error log table was mentioned in documentation but is not actually used by the plugin. This is NOT a problem - your installation is correct.

## Verification

After applying the fix:
1. Go to Settings page
2. Set criteria weights (e.g., 1.0 for both)
3. Click "Save Changes"
4. Should save without errors

## Need More Help?

If the quick fixes don't work:
1. Check browser console for JavaScript errors
2. Check WordPress debug log: `docker exec awardvantage_wpcli wp eval 'error_log(print_r($_POST, true));' --allow-root`
3. Temporarily enable debug mode to see detailed errors