# Candidates Photo Audit Report
**Date:** 2025-11-13
**System:** Best-Teacher Award #class25
**Environment:** localhost:8080

---

## Executive Summary

**Total Candidates:** 58
**Unique Candidates:** 55 (3 duplicates identified)
**Candidates WITH Photos:** 20 (34%)
**Candidates MISSING Photos:** 38 (66%)
**Duplicate Entries:** 3 candidates appear twice

---

## Data Quality Issues Identified

### 1. Duplicate Candidates (CRITICAL)

The following 3 candidates appear twice in the system - once with a photo and once without:

| Candidate Name | With Photo (ID) | Without Photo (ID) | Action Needed |
|----------------|-----------------|-------------------|---------------|
| Anjes Tjarks | ID: 107 ✓ | ID: 10 ✗ | Delete ID 10 |
| Björn Bender | ID: 109 ✓ | ID: 12 ✗ | Delete ID 12 |
| Christoph Weigler | ID: 114 ✓ | ID: 14 ✗ | Delete ID 14 |

**Recommendation:** Delete the duplicate entries WITHOUT photos (IDs: 10, 12, 14) to clean up the database.

### 2. Two Separate Import Sources

**Source 1: 38 German Profiles (from Kandidaten.md)**
- Imported WITHOUT photos
- IDs: 8-45 (38 candidates)
- Match the documented profiles in `/private/Kandidaten.md`
- 37 unique candidates after removing 3 duplicates (10, 12, 14)

**Source 2: 20 Additional Candidates**
- Imported WITH photos
- IDs: 105-124 (20 candidates)
- NOT in the Kandidaten.md documentation
- All different candidates except 3 duplicates
- Source unknown - possibly imported from another list

---

## Candidates WITHOUT Photos (38)

### All 38 German Profiles from Kandidaten.md

| ID | Name | LinkedIn URL | Notes |
|----|------|--------------|-------|
| 8 | Alexander Bilgeri | [LinkedIn](https://www.linkedin.com/in/alexander-bilgeri-40b4143b/) | |
| 9 | Andreas Herrmann | [LinkedIn](https://ch.linkedin.com/in/andreas-herrmann-4053541) | |
| 10 | Anjes Tjarks | [LinkedIn](https://www.linkedin.com/in/anjes-tjarks-19356835/) | **DUPLICATE - DELETE** |
| 11 | Astrid Fontaine | [LinkedIn](https://www.linkedin.com/in/dr-astrid-fontaine-28374519/) | |
| 12 | Björn Bender | [LinkedIn](https://www.linkedin.com/in/benderbjoern/) | **DUPLICATE - DELETE** |
| 13 | Christian Böllhoff | [LinkedIn](https://www.linkedin.com/in/christian-böllhoff/) | |
| 14 | Christoph Weigler | [LinkedIn](https://www.linkedin.com/in/cweigler/) | **DUPLICATE - DELETE** |
| 15 | Gunnar Froh | [LinkedIn](https://de.linkedin.com/in/gunnarfroh) | |
| 16 | Hui Zhang | [LinkedIn](https://www.linkedin.com/in/-hui-zhang/) | |
| 17 | Jan Marco Leimeister | [LinkedIn](https://www.linkedin.com/in/prof-jan-marco-leimeister/) | |
| 18 | Johann Jungwirth | [LinkedIn](https://www.linkedin.com/in/johannjungwirth/) | |
| 19 | Judith Häberli | [LinkedIn](https://www.linkedin.com/in/judith-häberli/) | |
| 20 | Jürgen Stackmann | [LinkedIn](https://www.linkedin.com/in/juergenstackmann/) | |
| 21 | Karolin Frankenberger | [LinkedIn](https://www.linkedin.com/in/prof-dr-karolin-frankenberger-83510b47/) | |
| 22 | Katrin Habenschaden | [LinkedIn](https://www.linkedin.com/in/katrinhabenschaden/) | |
| 23 | Karsten Crede | [LinkedIn](https://www.linkedin.com/in/karstencrede/) | |
| 24 | Kerstin Wagner | [LinkedIn](https://de.linkedin.com/in/kerstin-wagner) | |
| 25 | Kurt Bauer | [LinkedIn](https://www.linkedin.com/in/kurt-bauer-1594218/) | |
| 26 | Lukas Neckermann | [LinkedIn](https://www.linkedin.com/in/lukasneckermann/) | |
| 27 | Maja Göpel | **NO LinkedIn URL** | ⚠️ No LinkedIn profile available |
| 28 | Matthias Ballweg | [LinkedIn](https://www.linkedin.com/in/matthias-ballweg/) | |
| 29 | Melan Thuraiappah | [LinkedIn](https://www.linkedin.com/in/melanthuraiappah/) | |
| 30 | Michael Barillère-Scholz | [LinkedIn](https://linkedin.com/in/dr-michael-barillère-scholz-5a8502138) | |
| 31 | Nigel Storny | [LinkedIn](https://nl.linkedin.com/in/nigel-storny-825b856) | |
| 32 | Nikolaus Lang | [LinkedIn](https://www.linkedin.com/in/nikolauslang/) | |
| 33 | Christoph Wolff | [LinkedIn](https://www.linkedin.com/in/christoph-wolff-861b2889/) | |
| 34 | Olga Nevska | [LinkedIn](https://www.linkedin.com/in/olganevska-transformation-digitalization-stratetgy-leadership-innovation-ceo-managingdirector/) | |
| 35 | Philipp Scharfenberger | [LinkedIn](https://www.linkedin.com/in/dr-philipp-scharfenberger-26356712a/) | |
| 36 | Philipp Rode | [LinkedIn](https://www.linkedin.com/in/philipp-rode-814623102/) | |
| 37 | Philipp Wetzel | [LinkedIn](https://ch.linkedin.com/in/philippwetzel) | |
| 38 | Rolf Wüstenhagen | [LinkedIn](https://www.linkedin.com/in/rolf-wuestenhagen-stgallen/) | |
| 39 | Sascha Meyer | [LinkedIn](https://www.linkedin.com/in/sasmeyer/) | |
| 40 | Sylvia Lier | [LinkedIn](https://www.linkedin.com/in/sylvialier/) | |
| 41 | Timo Schneckenburger | [LinkedIn](https://www.linkedin.com/in/timoschneckenburger/) | |
| 42 | Torsten Tomczak | [LinkedIn](https://www.linkedin.com/in/torstentomczak/) | |
| 43 | Volker Hartmann | [LinkedIn](https://de.linkedin.com/in/dr-volker-hartmann-b56612111) | |
| 44 | Wolfgang Jenewein | [LinkedIn](https://www.linkedin.com/in/wolfgangjenewein/) | |
| 45 | Zheng Han | [LinkedIn](https://www.linkedin.com/in/profhanzheng/) | |

**After removing 3 duplicates: 35 candidates need photos**

---

## Candidates WITH Photos (20)

### Additional Candidates (Source Unknown)

| ID | Name | Photo ID | Source |
|----|------|----------|--------|
| 105 | Alexander Möller | 125 | Unknown |
| 106 | André Schwämmlein | 126 | Unknown |
| 107 | Anjes Tjarks | 127 | **Duplicate of ID 10** |
| 108 | Anna-Theresa Korbutt | 128 | Unknown |
| 109 | Björn Bender | 129 | **Duplicate of ID 12** |
| 110 | Boris Palmer | 130 | Unknown |
| 111 | Catrin von Cisewski | 131 | Unknown |
| 112 | Christine von Breitenbuch | 133 | Unknown |
| 113 | Christoph Seyerlein | 134 | Unknown |
| 114 | Christoph Weigler | 135 | **Duplicate of ID 14** |
| 115 | Dr. Christian Dahlheim | 132 | Unknown |
| 116 | Dr. Corsin Sulser | 136 | Unknown |
| 117 | Dr. Jan Hegner | 143 | Unknown |
| 118 | Fabian Beste | 137 | Unknown |
| 119 | Felix Pörnbacher | 138 | Unknown |
| 120 | Franz Reiner | 139 | Unknown |
| 121 | Friedrich Dräxlmaier | 140 | Unknown |
| 122 | Günther Schuh | 141 | Unknown |
| 123 | Horst Graef | 142 | Unknown |
| 124 | Johannes Pallasch | 144 | Unknown |

**Note:** These 20 candidates are NOT documented in `/private/Kandidaten.md`

---

## Photo Sourcing Strategy

### Immediate Actions

1. **Delete Duplicates** (IDs: 10, 12, 14)
   - Reduces missing photos from 38 to 35
   - Cleans up data quality issues

2. **Photo Collection Sources**
   - LinkedIn profiles (37 of 38 have URLs)
   - University St. Gallen website (IMO-HSG faculty/staff)
   - Company websites (BMW, Deutsche Bahn, ÖBB, etc.)
   - Professional photography databases
   - Direct contact/request from candidates

3. **Special Case: Maja Göpel**
   - No LinkedIn URL provided
   - Search: Google Images, Wikipedia, official website
   - Well-known public figure (Honorarprofessorin)

### Photo Requirements

- **Format:** JPG, PNG, or WEBP
- **Minimum Size:** 400x400 pixels
- **Recommended:** 800x800 pixels or larger
- **Aspect Ratio:** Square (1:1) or portrait (3:4)
- **File Naming:** Use candidate name (e.g., `Maja-Goepel.jpg`)
- **Location:** `/private/candidate-photos/`

---

## Recommended Next Steps

### Priority 1: Data Cleanup (High Priority)
- [ ] Delete duplicate entries (IDs: 10, 12, 14)
- [ ] Verify the source of the 20 additional candidates (IDs 105-124)
- [ ] Decide: Keep all 55 unique candidates or remove the 17 additional ones?

### Priority 2: Photo Sourcing (Medium Priority)
- [ ] Run automated LinkedIn photo scraper (if available)
- [ ] Manual download from LinkedIn profiles
- [ ] Search company websites for professional photos
- [ ] Find Maja Göpel's photo from public sources

### Priority 3: Documentation (Low Priority)
- [ ] Document where the 20 additional candidates came from
- [ ] Update Kandidaten.md if keeping all 55 candidates
- [ ] Create import log for future reference

---

## Questions for User

1. **Should we delete the 3 duplicate entries?** (Recommended: YES)
2. **Should we keep all 20 additional candidates?** (IDs 105-124)
3. **Where did the 20 additional candidates come from?**
4. **Do you want me to create an automated photo download script?**
5. **Should the final system have 38 or 55 unique candidates?**

---

## Technical Notes

- Database: MariaDB 11
- Table: `wp_posts` (post_type = 'mt_candidate')
- Photo storage: Featured images in `wp_postmeta` (_thumbnail_id)
- Media uploads: 21 files currently in media library
- System: WordPress 6.8.3, Plugin v2.5.41-class25

---

**Report Generated:** 2025-11-13
**Next Review:** After data cleanup decisions
