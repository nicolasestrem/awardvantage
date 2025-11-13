<?php
/**
 * Update LinkedIn URLs from Candidate list.pdf
 * Best-Teacher Award #class25
 *
 * Usage:
 *   docker exec awardvantage-wordpress-1 wp eval-file scripts/update-linkedin-urls.php --allow-root
 */

// Exit if not running in WP-CLI context
if (!defined('WP_CLI') && !defined('ABSPATH')) {
    exit('This script must be run via WP-CLI');
}

echo "===========================================\n";
echo "Updating LinkedIn URLs from Candidate list.pdf\n";
echo "Best-Teacher Award #class25\n";
echo "===========================================\n\n";

// LinkedIn URLs from Candidate list.pdf
$linkedin_urls = [
    'Alexander Bilgeri' => 'https://www.linkedin.com/in/alexander-bilgeri-40b4143b/',
    'Andreas Herrmann' => 'https://ch.linkedin.com/in/andreas-herrmann-4053541',
    'Anjes Tjarks' => 'https://www.linkedin.com/in/anjes-tjarks-19356835/',
    'Astrid Fontaine' => 'https://www.linkedin.com/in/dr-astrid-fontaine-28374519/',
    'Björn Bender' => 'https://www.linkedin.com/in/benderbjoern/',
    'Christian Böllhoff' => 'https://www.linkedin.com/in/christian-böllhoff/',
    'Christoph Weigler' => 'https://www.linkedin.com/in/cweigler/',
    'Gunnar Froh' => 'https://de.linkedin.com/in/gunnarfroh',
    'Hui Zhang' => 'https://www.linkedin.com/in/-hui-zhang/',
    'Jan Marco Leimeister' => 'https://www.linkedin.com/in/prof-jan-marco-leimeister/',
    'Johann Jungwirth' => 'https://www.linkedin.com/in/johannjungwirth/',
    'Judith Häberli' => 'https://www.linkedin.com/in/judith-häberli/',
    'Jürgen Stackmann' => 'https://www.linkedin.com/in/juergenstackmann/',
    'Karolin Frankenberger' => 'https://www.linkedin.com/in/prof-d-karolin-frankenberger-83510b47/',
    'Katrin Habenschaden' => 'https://www.linkedin.com/in/katrinhabenschaden/',
    'Karsten Crede' => 'https://www.linkedin.com/in/karstencrede/',
    'Kerstin Wagner' => 'https://de.linkedin.com/in/kerstin-wagner',
    'Kurt Bauer' => 'https://www.linkedin.com/in/kurt-bauer-1594218/',
    'Lukas Neckermann' => 'https://www.linkedin.com/in/lukasneckermann/',
    'Maja Göpel' => '', // Not found in PDF
    'Matthias Ballweg' => 'https://www.linkedin.com/in/matthias-ballweg/',
    'Melan Thuraiappah' => 'https://www.linkedin.com/in/melanthuraiappah/',
    'Michael Barillère-Scholz' => 'https://linkedin.com/in/dr-michael-barillère-scholz-5a8502138',
    'Nigell Storny' => 'https://nl.linkedin.com/in/nigel-storny-825b856',
    'Nikolaus Lang' => 'https://www.linkedin.com/in/nikolauslang/',
    'Oliver Wolff' => 'https://www.linkedin.com/in/christoph-wolff-861b2889/', // Christoph Wolff has formal HSG affiliation
    'Olga Nevska' => 'https://www.linkedin.com/in/olganevska-transformation-digitalization-strategy-leadership-innovation-ceo-managingdirector/',
    'Philipp Scharfenberger' => 'https://www.linkedin.com/in/dr-philipp-scharfenberger-26356712a/',
    'Philipp Rode' => 'https://www.linkedin.com/in/philipp-rode-814623102/',
    'Philipp Wetzel' => 'https://ch.linkedin.com/in/philippwetzel',
    'Rolf Wüstenhagen' => 'https://www.linkedin.com/in/rolf-wuestenhagen-stgallen/',
    'Sascha Meyer' => 'https://www.linkedin.com/in/sasmeyer/',
    'Sylvia Lier' => 'https://www.linkedin.com/in/sylvialier/',
    'Timo Schneckenburger' => 'https://www.linkedin.com/in/timoschneckenburger/',
    'Torsten Tomczak' => 'https://www.linkedin.com/in/torstentomczak/',
    'Volker Hartmann' => 'https://de.linkedin.com/in/dr-volker-hartmann-b5661211',
    'Wolfgang Jenewein' => 'https://www.linkedin.com/in/wolfgangjenewein/',
    'Zheng Han' => 'https://www.linkedin.com/in/profhanzheng/',
];

// Photo URLs from Candidate list.pdf
$photo_urls = [
    'Alexander Bilgeri' => 'https://smart-mobility-management.com/wp-content/uploads/2025/07/Alexander_Bilgeri-1-scaled.jpg',
    'Andreas Herrmann' => 'https://smart-mobility-management.com/wp-content/uploads/2025/04/Prof.-Dr.-Andreas-Herrmann-2-540x705-1.jpg',
    'Anjes Tjarks' => 'https://smart-mobility-management.com/wp-content/uploads/2025/06/Tjarks_quadrat_gr-scaled-1.jpg',
    'Astrid Fontaine' => 'https://smart-mobility-management.com/wp-content/uploads/2025/05/AstridFontaine-2-scaled-1.jpg',
    'Björn Bender' => 'https://cdn.prod.website-files.com/5ffef7a4ae1ea96d09069b40/65650dfb8c43c894c9a903db_MOTION%20Magazine%20Bjorn%20RailEurope_by_BenoitBillard-3.jpg',
    'Christian Böllhoff' => 'https://smart-mobility-management.com/wp-content/uploads/2025/05/628a5d7f74308-bpfull.jpg',
    'Christoph Weigler' => 'https://smart-mobility-management.com/wp-content/uploads/2025/05/Christoph-Weigler-2-scaled-1-1030x798.jpg',
    'Hui Zhang' => 'https://smart-mobility-management.com/wp-content/uploads/2025/05/Hui-Zhang-1-scaled-1.jpg',
    'Johann Jungwirth' => 'https://smart-mobility-management.com/wp-content/uploads/2025/05/Johann-Jungwirth.jpg',
    'Jürgen Stackmann' => 'https://imo.unisg.ch/wp-content/uploads/2022/04/JS-300x300.jpg',
    'Karolin Frankenberger' => 'https://ifb.unisg.ch/wp-content/uploads/2023/03/Karolin_Frankenberger.png.webp',
    'Katrin Habenschaden' => 'https://imo.unisg.ch/wp-content/uploads/2023/05/DSC03054.jpg',
    'Kerstin Wagner' => 'https://smart-mobility-management.com/wp-content/uploads/2025/05/Kerstin-Wagner-scaled-1.jpg',
    'Kurt Bauer' => 'https://smart-mobility-management.com/wp-content/uploads/2025/05/Kurt-Bauer-scaled-1.jpg',
    'Lukas Neckermann' => 'https://www.neckermann.net/wp-content/uploads/2016/07/f_N_LIIPG.jpg',
    'Nikolaus Lang' => 'https://ifb.unisg.ch/wp-content/uploads/2021/04/Nikolaus_Lang.png.webp',
    'Philipp Scharfenberger' => 'https://imc.unisg.ch/app/uploads/2021/10/philipp-scharfenberger.jpg',
    'Sylvia Lier' => 'https://smart-mobility-management.com/wp-content/uploads/2025/05/Sylvia-Lier-1-scaled-1.jpg',
    'Timo Schneckenburger' => 'https://smart-mobility-management.com/wp-content/uploads/2025/05/Timo-Schneckenburger_2.jpg',
    'Volker Hartmann' => 'https://www.reuschlaw.de/wp-content/uploads/2024/06/volker-51341-hires-2.jpg',
    'Wolfgang Jenewein' => 'https://jenewein.ch/wp-content/uploads//00_Jenewein80-1024x683.jpg',
];

// Get all candidates
$candidates = get_posts([
    'post_type' => 'mt_candidate',
    'posts_per_page' => -1,
    'post_status' => 'publish'
]);

$updated = 0;
$skipped = 0;
$photo_urls_added = 0;

foreach ($candidates as $candidate) {
    $name = $candidate->post_title;

    // Update LinkedIn URL
    if (isset($linkedin_urls[$name])) {
        $linkedin_url = $linkedin_urls[$name];
        update_post_meta($candidate->ID, '_mt_linkedin_url', $linkedin_url);
        echo sprintf("[%d] %s: LinkedIn updated\n", $candidate->ID, $name);
        $updated++;

        // Update photo URL note if available
        if (isset($photo_urls[$name])) {
            $photo_url = $photo_urls[$name];
            // Store photo URL for manual download
            update_post_meta($candidate->ID, '_mt_photo_url', $photo_url);
            echo sprintf("    Photo URL: %s\n", $photo_url);
            $photo_urls_added++;
        } else {
            echo "    Photo URL: Not found in PDF\n";
        }
    } else {
        echo sprintf("[%d] %s: SKIPPED - Not found in mapping\n", $candidate->ID, $name);
        $skipped++;
    }
}

echo "\n";
echo "===========================================\n";
echo "Update Summary:\n";
echo "===========================================\n";
echo "LinkedIn URLs updated: $updated\n";
echo "Photo URLs stored: $photo_urls_added\n";
echo "Candidates skipped: $skipped\n";
echo "\n";
echo "Next step: Download photos from stored URLs\n";
echo "===========================================\n";
