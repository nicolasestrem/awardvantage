#!/usr/bin/env python3
"""
Verify all 38 candidates have photos
"""

import csv
import os
import glob

# Use environment variables or relative paths (relative to script location)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
CSV_FILE = os.environ.get('CSV_FILE', os.path.join(PROJECT_ROOT, 'deploy', 'candidates.csv'))
PHOTOS_DIR = os.environ.get('PHOTOS_DIR', os.path.join(PROJECT_ROOT, 'private', 'candidate-photos'))

def normalize_name(name):
    """Normalize name for comparison"""
    # Remove special characters
    name = name.lower()
    name = name.replace('ä', 'ae').replace('ö', 'oe').replace('ü', 'ue')
    name = name.replace('ß', 'ss').replace('è', 'e').replace('é', 'e')
    name = name.replace(' ', '').replace('-', '').replace('.', '')
    name = name.replace('dr', '').replace('prof', '')
    return name

def find_photo_for_candidate(candidate_name, all_photos):
    """Find matching photo file for candidate"""
    normalized = normalize_name(candidate_name)

    for photo in all_photos:
        photo_base = os.path.splitext(photo)[0]
        photo_normalized = normalize_name(photo_base)

        if normalized == photo_normalized:
            return photo

    return None

def main():
    print("=" * 100)
    print("CANDIDATE PHOTO VERIFICATION REPORT")
    print("=" * 100)
    print()

    # Get all photo files
    photo_extensions = ['*.jpg', '*.jpeg', '*.png', '*.webp']
    all_photos = []
    for ext in photo_extensions:
        all_photos.extend([os.path.basename(f) for f in glob.glob(os.path.join(PHOTOS_DIR, ext))])

    # Exclude test/corrupted files
    excluded = ['ChatGPT', 'NicolasEstrem', 'Hans-Peter', 'corrupted', 'Expert_2_Panel']
    all_photos = [p for p in all_photos if not any(ex in p for ex in excluded)]

    print(f"📁 Total valid photo files found: {len(all_photos)}\n")

    # Read candidates from CSV
    candidates = []
    with open(CSV_FILE, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['name'].strip():
                candidates.append(row)

    print(f"👥 Total candidates in CSV: {len(candidates)}\n")
    print("=" * 100)
    print()

    # Check each candidate
    have_photos = []
    need_photos = []

    for candidate in candidates:
        name = candidate['name']
        csv_photo = candidate['photo_filename'].strip()

        # Try to find photo
        found_photo = find_photo_for_candidate(name, all_photos)

        if found_photo:
            have_photos.append({
                'name': name,
                'photo': found_photo,
                'csv_match': found_photo == csv_photo
            })
        else:
            need_photos.append({
                'name': name,
                'csv_photo': csv_photo
            })

    # Report
    print("✅ CANDIDATES WITH PHOTOS")
    print("-" * 100)
    for i, item in enumerate(have_photos, 1):
        status = "✓" if item['csv_match'] else "⚠ (CSV needs update)"
        print(f"{i:2}. {item['name']:<35} → {item['photo']:<40} {status}")

    print()
    print("=" * 100)

    if need_photos:
        print("\n❌ CANDIDATES STILL NEEDING PHOTOS")
        print("-" * 100)
        for i, item in enumerate(need_photos, 1):
            print(f"{i}. {item['name']}")
        print()

    # Summary
    print("=" * 100)
    print("SUMMARY")
    print("=" * 100)
    print(f"✅ Candidates with photos: {len(have_photos)}/{len(candidates)}")
    print(f"❌ Candidates needing photos: {len(need_photos)}/{len(candidates)}")

    if len(have_photos) == len(candidates):
        print()
        print("🎉 SUCCESS! All 38 candidates have photos!")

    print()

if __name__ == '__main__':
    main()
