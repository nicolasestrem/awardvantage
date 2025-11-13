#!/usr/bin/env python3
"""
Automated Photo Sourcing Script
Downloads candidate photos from various sources (LinkedIn, university sites, etc.)
"""

import csv
import os
import sys
import requests
from urllib.parse import urlparse, quote
import time
from PIL import Image
from io import BytesIO
import re

# Configuration
# Use environment variables or relative paths (relative to script location)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
CSV_FILE = os.environ.get('CSV_FILE', os.path.join(PROJECT_ROOT, 'deploy', 'candidates.csv'))
PHOTOS_DIR = os.environ.get('PHOTOS_DIR', os.path.join(PROJECT_ROOT, 'private', 'candidate-photos'))
MIN_SIZE = 400
TARGET_SIZE = 800
MAX_RETRIES = 3
TIMEOUT = 15

# Source URLs for specific candidates (manually curated from research)
KNOWN_PHOTO_URLS = {
    'Gunnar Froh': [
        'https://smart-mobility-management.com/wp-content/uploads/2025/05/Gunnar-Froh.jpg',
        'https://www.linkedin.com/in/gunnarfroh'
    ],
    'Jan Marco Leimeister': [
        'https://imo.unisg.ch/wp-content/uploads/Jan-Marco-Leimeister.jpg',
        'https://www.wi.uni-kassel.de/fileadmin/_processed_/d/1/csm_JML_Foto_2024_quadratisch_800x800_81f5e3c0e0.jpg',
        'https://www.linkedin.com/in/prof=jan=marco=leimeister'
    ],
    'Judith Häberli': [
        'https://www.linkedin.com/in/judith-häberli'
    ],
    'Karsten Crede': [
        'https://www.linkedin.com/in/karstencrede'
    ],
    'Maja Göpel': [
        'https://www.scientists4future.org/wp-content/uploads/2019/12/MajaGoepel_c_JuttaZeitler.jpg',
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Maja_G%C3%B6pel_2019.jpg/800px-Maja_G%C3%B6pel_2019.jpg'
    ],
    'Melan Thuraiappah': [
        'https://www.linkedin.com/in/melanthuraiappah'
    ],
    'Michael Barillère-Scholz': [
        'https://linkedin.com/in/dr-michael-barillère-scholz-5a8502138'
    ],
    'Nigell Storny': [
        'https://smart-mobility-management.com/wp-content/uploads/2025/05/Nigel-Storny.jpg',
        'https://nl.linkedin.com/in/nigel-storny-825b856'
    ],
    'Christoph Wolff': [
        'https://smart-mobility-management.com/wp-content/uploads/2025/05/Oliver-Christoph-Wolff.jpg',
        'https://www.linkedin.com/in/christoph-wolff-861b2889'
    ],
    'Olga Nevska': [
        'https://www.linkedin.com/in/olganevska=transformation=digitalization=strategy=leadership=innovation=ceo=managingdirector'
    ],
    'Philipp Rode': [
        'https://www.lse.ac.uk/Cities/Assets/Images/People/Philipp-Rode-square.jpg',
        'https://www.lse.ac.uk/Cities/People/Philipp-Rode',
        'https://www.linkedin.com/in/philipp-rode-814623102'
    ],
    'Philipp Wetzel': [
        'https://ch.linkedin.com/in/philippwetzel'
    ],
    'Rolf Wüstenhagen': [
        'https://iwoe.unisg.ch/wp-content/uploads/2020/07/Rolf-Wuestenhagen_IWOe-HSG.jpg',
        'https://www.linkedin.com/com/in/rolf-wuestenhagen=stgallen'
    ],
    'Sascha Meyer': [
        'https://smart-mobility-management.com/wp-content/uploads/2025/05/Sascha-Meyer.jpg',
        'https://www.volkswagenag.com/presence/konzern/presse/Pressebilder/Sascha-Meyer.jpg',
        'https://www.linkedin.com/in/sasmeyer'
    ],
    'Zheng Han': [
        'https://www.linkedin.com/in/profhanzheng'
    ]
}

def download_image(url, candidate_name, retry=0):
    """Download image from URL"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }

        print(f"  Attempting to download from: {url}")
        response = requests.get(url, headers=headers, timeout=TIMEOUT, allow_redirects=True)

        if response.status_code == 200:
            # Check if it's an image
            content_type = response.headers.get('content-type', '')
            if 'image' not in content_type.lower() and len(response.content) < 1000:
                print(f"  ❌ Not an image (content-type: {content_type})")
                return None

            # Try to open and verify image
            try:
                img = Image.open(BytesIO(response.content))
                width, height = img.size

                print(f"  📐 Image size: {width}x{height}")

                # Check minimum size
                if width < MIN_SIZE or height < MIN_SIZE:
                    print(f"  ❌ Image too small (min {MIN_SIZE}x{MIN_SIZE})")
                    return None

                print(f"  ✅ Valid image ({len(response.content)} bytes)")
                return response.content
            except Exception as e:
                print(f"  ❌ Invalid image: {e}")
                return None
        else:
            print(f"  ❌ HTTP {response.status_code}")
            return None

    except requests.exceptions.Timeout:
        print(f"  ⏱️  Timeout after {TIMEOUT}s")
        if retry < MAX_RETRIES:
            print(f"  🔄 Retry {retry + 1}/{MAX_RETRIES}")
            time.sleep(2)
            return download_image(url, candidate_name, retry + 1)
        return None
    except Exception as e:
        print(f"  ❌ Error: {e}")
        return None

def sanitize_filename(name):
    """Convert candidate name to filename"""
    # Remove special characters and convert to camelCase
    name = name.replace('ä', 'ae').replace('ö', 'oe').replace('ü', 'ue')
    name = name.replace('Ä', 'Ae').replace('Ö', 'Oe').replace('Ü', 'Ue')
    name = name.replace('ß', 'ss').replace('è', 'e').replace('é', 'e')

    parts = name.split()
    filename = ''.join(part.capitalize() for part in parts)
    return filename

def get_image_extension(image_data):
    """Detect image format from binary data"""
    try:
        img = Image.open(BytesIO(image_data))
        format_lower = img.format.lower()
        if format_lower == 'jpeg':
            return 'jpg'
        return format_lower
    except:
        return 'jpg'

def main():
    print("=" * 80)
    print("AUTOMATED CANDIDATE PHOTO SOURCING")
    print("=" * 80)
    print()

    # Read CSV
    candidates_to_source = []
    with open(CSV_FILE, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if not row['photo_filename'].strip():
                candidates_to_source.append(row)

    print(f"📊 Found {len(candidates_to_source)} candidates without photos\n")

    if not candidates_to_source:
        print("✅ All candidates already have photos!")
        return

    # Process each candidate
    success_count = 0
    failed_candidates = []

    for i, candidate in enumerate(candidates_to_source, 1):
        name = candidate['name']
        linkedin_url = candidate['linkedin_url']

        print(f"\n[{i}/{len(candidates_to_source)}] {name}")
        print("-" * 80)

        # Try known photo URLs first
        image_data = None
        if name in KNOWN_PHOTO_URLS:
            for url in KNOWN_PHOTO_URLS[name]:
                # Skip LinkedIn URLs for now (require special handling)
                if 'linkedin.com' in url:
                    continue

                image_data = download_image(url, name)
                if image_data:
                    break

        # Save if successful
        if image_data:
            filename_base = sanitize_filename(name)
            extension = get_image_extension(image_data)
            filename = f"{filename_base}.{extension}"
            filepath = os.path.join(PHOTOS_DIR, filename)

            with open(filepath, 'wb') as f:
                f.write(image_data)

            print(f"  💾 Saved as: {filename}")
            success_count += 1
        else:
            print(f"  ❌ Failed to download photo")
            failed_candidates.append({
                'name': name,
                'linkedin': linkedin_url
            })

        # Rate limiting
        time.sleep(1)

    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"✅ Successfully downloaded: {success_count}/{len(candidates_to_source)}")
    print(f"❌ Failed: {len(failed_candidates)}")

    if failed_candidates:
        print("\n📋 Candidates still needing photos:")
        for candidate in failed_candidates:
            print(f"  - {candidate['name']}")
            if candidate['linkedin']:
                print(f"    LinkedIn: {candidate['linkedin']}")

    print()

if __name__ == '__main__':
    main()
