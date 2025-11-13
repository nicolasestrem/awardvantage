#!/bin/bash

################################################################################
# Best-Teacher Award #class25 - Candidate Bio & Photo Update Script
# Populates candidate bios and photos from PDF sources
################################################################################

set -e

# Configuration
CONTAINER_CLI="${CONTAINER_CLI:-awardvantage_wpcli}"
LOG_FILE="update-bios-$(date +%Y%m%d-%H%M%S).log"
SUCCESS_COUNT=0
ERROR_COUNT=0
PHOTO_COUNT=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

# Functions
log() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
    ((++SUCCESS_COUNT))
}

error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"
    ((++ERROR_COUNT))
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo ""
    echo "==================================================" | tee -a "$LOG_FILE"
    echo " $1" | tee -a "$LOG_FILE"
    echo "==================================================" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

# Check Docker container is running
if ! docker ps --format "{{.Names}}" | grep -q "^$CONTAINER_CLI$"; then
    error "Docker container $CONTAINER_CLI is not running!"
    exit 1
fi

print_header "Best-Teacher Award - Candidate Bio & Photo Update"
log "Container: $CONTAINER_CLI"
log "Log File: $LOG_FILE"

# Function to update a single candidate
update_candidate() {
    local name="$1"
    local bio="$2"
    local photo_url="$3"
    local linkedin_url="$4"

    log "Processing: $name"

    # Find candidate post ID by title
    local post_id=$(docker exec "$CONTAINER_CLI" wp post list \
        --post_type=mt_candidate \
        --s="$name" \
        --field=ID \
        --format=csv \
        --allow-root 2>&1 | grep -oE '^[0-9]+$' | head -1)

    if [ -z "$post_id" ]; then
        error "Candidate not found: $name"
        return 1
    fi

    log "  Found candidate (Post ID: $post_id)"

    # Update bio in _mt_overview meta field
    if [ -n "$bio" ]; then
        docker exec "$CONTAINER_CLI" wp post meta update "$post_id" _mt_overview "$bio" --allow-root >/dev/null 2>&1
        log "  ✓ Bio updated"
    fi

    # Update LinkedIn URL if provided
    if [ -n "$linkedin_url" ]; then
        docker exec "$CONTAINER_CLI" wp post meta update "$post_id" _mt_linkedin_url "$linkedin_url" --allow-root >/dev/null 2>&1
    fi

    # Download and set photo if URL provided and no existing photo
    if [ -n "$photo_url" ]; then
        local has_thumbnail=$(docker exec "$CONTAINER_CLI" wp post meta get "$post_id" _thumbnail_id --allow-root 2>/dev/null || echo "")

        if [ -z "$has_thumbnail" ]; then
            log "  Downloading photo..."
            local photo_filename=$(basename "$photo_url" | sed 's/[?].*$//')

            # Download photo
            if curl -s -o "/tmp/$photo_filename" "$photo_url" 2>/dev/null; then
                # Copy to container
                docker cp "/tmp/$photo_filename" "$CONTAINER_CLI:/tmp/$photo_filename" 2>/dev/null

                # Import to WordPress
                local attachment_id=$(docker exec "$CONTAINER_CLI" wp media import "/tmp/$photo_filename" \
                    --post_id="$post_id" \
                    --featured_image \
                    --porcelain \
                    --allow-root 2>&1 | grep -oE '^[0-9]+$' | head -1 || true)

                # Cleanup
                rm -f "/tmp/$photo_filename" 2>/dev/null || true
                docker exec "$CONTAINER_CLI" rm -f "/tmp/$photo_filename" 2>/dev/null || true

                if [ -n "$attachment_id" ] && [ "$attachment_id" -gt 0 ] 2>/dev/null; then
                    log "  ✓ Photo uploaded (Attachment ID: $attachment_id)"
                    ((++PHOTO_COUNT))
                else
                    warning "  Failed to upload photo"
                fi
            else
                warning "  Failed to download photo from URL"
            fi
        else
            log "  Photo already exists, skipping"
        fi
    fi

    success "Updated: $name (Post ID: $post_id)"
}

# Main update loop
print_header "Updating Candidates"

# Candidate 1: Alexander Bilgeri
update_candidate "Alexander Bilgeri" \
"Alexander Bilgeri ist seit 2022 Vice President Communications Human Resources, Production, Purchasing and Sustainability bei der BMW Group und bringt über 18 Jahre Erfahrung in verschiedenen globalen Senior-Kommunikationspositionen mit. Als Dozent im SMART Mobility Management (CAS) Executive Programm am Institut für Mobilität der Universität St. Gallen (IMO-HSG) teilt er praxisnahe Einblicke aus der Führung der Mobilitätstransformation bei einem der weltweit führenden Automobilhersteller. Seine Expertise umfasst Unternehmenskommunikation, Nachhaltigkeitskommunikation und strategische Botschaftsgestaltung im Kontext der Elektromobilität. Er studierte Betriebswirtschaftslehre an der Ludwig-Maximilians-Universität München (Diplom-Kaufmann, 2000). Seine Relevanz für die Mobility Trailblazers-Initiative liegt in seiner Schlüsselrolle bei der Kommunikation von BMWs Elektromobilitätsstrategie und Nachhaltigkeitstransformation." \
"https://smart-mobility-management.com/wp-content/uploads/2025/07/Alexander_Bilgeri-1-scaled.jpg" \
"https://www.linkedin.com/in/alexander-bilgeri-40b4143b/" || true

# Candidate 2: Andreas Herrmann
update_candidate "Andreas Herrmann" \
"Prof. Dr. Andreas Herrmann ist Professor für Betriebswirtschaftslehre und Direktor des Instituts für Mobilität (IMO-HSG) an der Universität St. Gallen, das er gemeinsam mit Prof. Torsten Tomczak und Prof. Wolfgang Jenewein leitet. Seine Forschungsschwerpunkte liegen in Verhaltensökonomie, autonomem Fahren und Mobilitätstransformation, mit 15 veröffentlichten Büchern und über 250 wissenschaftlichen Artikeln in führenden Zeitschriften wie dem Journal of Marketing und Harvard Business Review. Er ist Gastprofessor an der London School of Economics (LSE Cities) und der Stockholm School of Economics sowie Akademischer Direktor des Executive Education Programms für Smart Mobility Management an der HSG. Als Gründungsfigur im Mobilitätsforschungs-Ökosystem der HSG und Host des Mobility Pioneers Podcasts (mit Jürgen Stackmann, Matthias Ballweg und Björn Bender) ist er zentral für die Mobility Trailblazers-Initiative. Seine Arbeit verbindet akademische Forschung mit praktischer Anwendung durch langjährige Kooperationsprojekte mit Unternehmen wie Audi, Porsche, Roche und Sonova." \
"https://smart-mobility-management.com/wp-content/uploads/2025/04/Prof.-Dr.-Andreas-Herrmann-2-540x705-L.jpg" \
"https://ch.linkedin.com/in/andreas-herrmann-4053541" || true

# Candidate 3: Anjes Tjarks
update_candidate "Anjes Tjarks" \
"Anjes Tjarks ist seit dem 10. Juni 2020 Senator für Verkehr und Mobilitätswende in Hamburg und damit einer der prominentesten politischen Anführer der urbanen Mobilitätstransformation in Deutschland. Er promovierte in Politikwissenschaft und Kognitiver Linguistik mit einer Dissertation über "Familienbilder als Weltbilder" und studierte Anglistik und Politik in Hamburg und Stellenbosch, Südafrika. Als langjähriges Mitglied von Bündnis 90/Die Grünen seit 1998 und ehemaliger stellvertretender Landesvorsitzender (2008-2011) bringt er umfangreiche Erfahrung in der Umsetzung nachhaltiger Mobilitätspolitik in einer deutschen Metropolregion mit. Seine HSG-Verbindung besteht als Dozent im SMART Mobility Management (CAS) Executive Programm, wo er Einblicke in politische Rahmenbedingungen und Regierungsansätze zur Mobilitätswende vermittelt. Seine Relevanz für Mobility Trailblazers liegt in seiner einzigartigen Position als Brückenbauer zwischen politischer Gestaltung und akademischem Diskurs." \
"https://smart-mobility-management.com/wp-content/uploads/2025/06/Tjarks_quadrat_gr-scaled-L.jpg" \
"https://www.linkedin.com/in/anjes-tjarks-19356835/" || true

# Candidate 4: Astrid Fontaine
update_candidate "Astrid Fontaine" \
"Dr. Astrid Fontaine ist seit Januar 2024 Chief Human Resources Officer und Mitglied des Vorstands der Schaeffler AG, wo sie auch als Arbeitsdirektorin die Transformation der Belegschaft in Richtung Elektromobilität verantwortet. Sie promovierte in Wirtschaftsinformatik an der Emory University (2007-2012) und verfügt über Abschlüsse in Maschinenbau und Betriebswirtschaftslehre, was ihr tiefgreifende technische und wirtschaftliche Kompetenz für ihre HR-Führungsrolle verleiht. Zuvor war sie Vorstandsmitglied bei Volkswagen Nutzfahrzeuge (2021-2023) und bei Bentley Motors (2018-2021) und leitete erfolgreich Belegschaftstransformationen bei großen Automobilherstellern. Ihre HSG-Verbindung umfasst ihre Rolle als Dozentin im SMART Mobility Management (CAS) Executive Programm und ihre Auszeichnung als eine der 25 Mobility Trailblazers 2025 durch das IMO-HSG. Die Automobilwoche würdigt sie als "eine der einflussreichsten Frauen in der Automobilindustrie", und sie ist Mitglied der Expertengruppe Transformation der Automobilindustrie beim Bundesministerium für Wirtschaft." \
"https://smart-mobility-management.com/wp-content/uploads/2025/05/AstridFontaine-2-scaled-L.jpg" \
"https://www.linkedin.com/in/dr-astrid-fontaine-28374519/" || true

# Candidate 5: Björn Bender
update_candidate "Björn Bender" \
"Björn Bender ist CEO und Executive Chairman von Rail Europe, einem globalen Travel-Tech-Unternehmen, das innovative Bahnvertriebslösungen für über 25.000 B2B-Partner in mehr als 70 Ländern bereitstellt. Seine Expertise umfasst nachhaltige Mobilität, Bahndigitalisierung und multimodale Transportinnovation, mit über 20 Jahren Führungserfahrung im Mobilitätssektor, darunter frühere Führungspositionen bei den Schweizerischen Bundesbahnen (SBB) als Head of Innovation und bei der Deutschen Bahn als VP Sales & Partner Management für New Mobility. Bender ist Mitglied des Advisory Boards am IMO-HSG (Institut für Mobilität der Universität St. Gallen) und seit 2020 Gastdozent im Executive Education Programm "Smart Mobility Management" an der HSG. Er gründete den gemeinnützigen Verein Mobility Allstars e.V., der sich der Beschleunigung der Mobilitätstransformation in der DACH-Region widmet, und ist Co-Host der Podcasts "Mobility Pioneers" und zuvor "New Mobility Planet" mit HSG-Professoren. Seine starke Verbindung zur Universität St. Gallen positioniert ihn als wichtige Brücke zwischen Industrie und Wissenschaft für die Mobility Trailblazers-Initiative." \
"https://cdn.prod.website-files.com/5ffcf7adae1ea96d09069b40/65650dfb8c43c894c9a903db_MOTION%20Magazine%20Bjorn%20RailEurope_by_BenoitBillard-3.jpg" \
"https://www.linkedin.com/in/benderbjoern/" || true

# Candidate 6: Christian Böllhoff
update_candidate "Christian Böllhoff" \
"Christian Böllhoff ist CEO und geschäftsführender Partner der Prognos AG Basel, einem der führenden europäischen Beratungs- und Forschungsunternehmen, das sich auf fundierte Entscheidungen für eine lebenswerte Zukunft durch Analyse von Megatrends, Digitalisierung und Nachhaltigkeit konzentriert. Mit einem Hintergrund in der Treuhandanstalt, bei Bosch-Siemens-Hausgeräte, Gemini Consulting und der Holtzbrinck-Verlagsgruppe (einschließlich CEO des Handelsblatts) bringt er tiefgreifende Expertise in Wirtschaftsprognosen, Mobilitätstransformation und strategischer Vorausschau mit. Böllhoff ist Gastdozent und Experte für das CAS Smart Mobility Management Programm an der Universität St. Gallen, wo er seit der Launch-Kohorte 2020-2021 beiträgt und sich darauf konzentriert, wie Megatrends die Mobilitätspolitik und -planung prägen. Seine Arbeit umfasst die Entwicklung des ADAC Mobilitätsindex mit Prognos zur Messung nachhaltiger Mobilitätsfortschritte in Deutschland. Seine HSG-Zugehörigkeit als Fakultätsexperte im Executive Education Programm positioniert ihn als wichtige Stimme für datengestützte Mobilitätsstrategien und die Schnittstelle von Nachhaltigkeit, Demografie und Stadtplanung." \
"https://smart-mobility-management.com/wp-content/uploads/2025/05/628a5d7f74308-bpfull.jpg" \
"https://www.linkedin.com/in/christian-böllhoff/" || true

# Candidate 7: Christoph Weigler
update_candidate "Christoph Weigler" \
"Christoph Weigler (geboren 1983) ist General Manager von Uber für Deutschland, Österreich und die Schweiz (DACH-Region) und leitet seit August 2016 die Expansion und strategische Entwicklung des Unternehmens mit Fokus auf nachhaltige Mobilität und plattformbasierte Transportlösungen. Bevor er im Oktober 2015 zu Uber kam, arbeitete er als Senior Manager bei Bain & Company in München und San Francisco, wo er zahlreiche Automobilhersteller bei strategischen Transformationen zu ganzheitlichen Mobilitätsanbietern und Markteintrittsstrategien für China beriet, wobei er zwei Jahre in China und ein Jahr im Silicon Valley verbrachte. Weigler ist seit der Gründung 2020 Kernfakultätsmitglied für das CAS Smart Mobility Management Programm an der Universität St. Gallen, wo er über Plattformdienste, Shared Mobility-Ökosysteme und die Zukunft urbaner Mobilität unterrichtet. Er studierte Betriebswirtschaftslehre an der European Business School in Oestrich-Winkel und an der Tsinghua University in Peking und ist ein prominenter Redner auf Mobilitätskonferenzen wie der IAA Mobility. Seine Expertise in Ride-Hailing-Plattformen, urbaner Mobilitätstransformation und der Integration von Shared Mobility mit öffentlichem Verkehr macht ihn hochrelevant für die Mobility Trailblazers-Initiative." \
"https://smart-mobility-management.com/wp-content/uploads/2025/05/Christoph-Weigler-2-scaled-1-1030x798.jpg" \
"https://www.linkedin.com/in/cweigler/" || true

# Candidate 8: Gunnar Froh
update_candidate "Gunnar Froh" \
"Gunnar Froh ist Gründer und CEO von Wunder Mobility, einem in Hamburg ansässigen globalen Marktführer für Software- und Hardwarelösungen für Fahrzeug-Sharing, mit Einsätzen in über 200 Städten auf fünf Kontinenten, die Technologieplattformen für Unternehmen, Städte und Startups zum Start und zur Skalierung von Shared Mobility-Services bereitstellen. Wunder Mobility wurde 2014 gegründet, bedient Betreiber von E-Bikes, E-Scootern, E-Mopeds und Autos mit White-Label-SaaS-Lösungen und hat 72 Millionen US-Dollar an Finanzierung eingesammelt. Bevor er Wunder Mobility gründete, spielte Froh eine führende Rolle bei der Internationalisierung von Airbnb, nachdem sie Accoleo (einen von ihm 2011 mitgegründeten Wohnungsmarktplatz) übernommen hatten, und arbeitete zuvor als Berater bei McKinsey und gründete die gemeinnützige Carsharing-Organisation CampusCar. Er ist seit dem Start 2020 Gastdozent und Experte für das CAS Smart Mobility Management Programm an der Universität St. Gallen, Mitglied des Innovation Advisory Board des United Nations Population Fund und Host des Wunder Mobility Podcasts. Seine Expertise in Shared Mobility-Technologie, Mikromobilität, Softwareplattformen für Fahrzeug-Sharing und Unternehmertum in nachhaltiger Mobilität macht ihn zu einem wertvollen Beitragenden für die Mobility Trailblazers-Initiative." \
"" \
"https://de.linkedin.com/in/gunnarfroh" || true

# Candidate 9: Hui Zhang
update_candidate "Hui Zhang" \
"Hui Zhang ist Group Vice President bei NIO und Managing Director von NIO GmbH/NIO Performance Engineering in Deutschland. Er ist tief in die Mobility-as-a-Service (MaaS)-Strategie und Elektrofahrzeuginnovation involviert und setzt sich für kollaborative Ansätze für nachhaltige Mobilitätsökosysteme ein. Zhang ist mit der Universität St. Gallen über das IMO-HSG (Institut für Mobilität) als Teil des Mobility Pioneers-Netzwerks verbunden, wo er Treffen veranstaltet und an Diskussionen über Mobilitätsinnovation teilnimmt. Er nahm am 51. St. Gallen Symposium in Kopenhagen teil, wo er NIOs Engagement für MaaS verkündete. Seine Expertise konzentriert sich auf autonomes Fahren, Elektromobilität und den Aufbau vernetzter Transportökosysteme, was ihn zu einer Schlüsselstimme im Mobilitätstransformationsdialog innerhalb des HSG-Netzwerks macht." \
"https://smart-mobility-management.com/wp-content/uploads/2025/05/Hui-Zhang-1-scaled-L.jpg" \
"https://www.linkedin.com/in/=hui=zhang/" || true

# Candidate 10: Jan Marco Leimeister
update_candidate "Jan Marco Leimeister" \
"Professor Jan Marco Leimeister hat eine Vollprofessur am Institut für Wirtschaftsinformatik (IWI-HSG) der Universität St. Gallen inne und leitet gleichzeitig den Lehrstuhl für Wirtschaftsinformatik an der Universität Kassel. Seine Expertise konzentriert sich auf digitale Transformation, hybride Intelligenz, Service Design und Management, Collaboration Engineering und KI-gesteuerte Innovationen einschließlich generativer KI und Conversational AI. Obwohl nicht ausschließlich mobilitätsorientiert, unterstützt seine Forschung zu digitaler Transformation, IT-Innovationsmanagement und datengesteuerten Service-Innovationen direkt die technologische Evolution der Mobilitätsbranche. Leimeister wird kontinuierlich zu den Top 1% der Betriebswirtschaftsprofessoren im deutschsprachigen Raum gezählt und dient als Berater und Advisor, der Organisationen bei der Navigation durch digitalen Wandel unterstützt. Seine Verbindung zu Mobilität/Nachhaltigkeit ergibt sich durch seine Arbeit an digitalen Innovationen, die Smart Mobility-Lösungen und nachhaltige Geschäftstransformation ermöglichen." \
"" \
"https://www.linkedin.com/in/prof=jan=marco=leimeister/" || true

# Candidate 11: Johann Jungwirth
update_candidate "Johann Jungwirth" \
"Johann Jungwirth ist Executive Vice President of Autonomous Vehicles bei Mobileye (Intel Company) mit Sitz in Jerusalem und leitet Mobilitätslösungen mit selbstfahrenden Fahrzeugen. Er ist prominent mit der Universität St. Gallen durch das SMART Mobility Management Executive Programm (IMO-HSG-verbunden) verbunden, wo er als wichtiger Dozent und Experte fungiert. Als Co-Autor mit HSG-Professor Andreas Herrmann des Buches "Inventing Mobility for All: Mastering Mobility-as-a-Service with Self-Driving Vehicles" bringt Jungwirth über 20 Jahre Erfahrung in der Automobilindustrie mit Fokus auf autonome Fahrtechnologie mit. Seine Expertise umfasst MaaS-Implementierung, ADAS (Advanced Driver Assistance Systems) und die Demokratisierung autonomer Mobilität, um den Transport sicherer, zugänglicher und nachhaltiger zu machen. Er ist weltweit als Vordenker anerkannt, der daran arbeitet, Mobilität durch den Einsatz autonomer Fahrzeuge zu transformieren, und war maßgeblich an Partnerschaften mit Volkswagen Group, Porsche und anderen großen OEMs beteiligt." \
"https://smart-mobility-management.com/wp-content/uploads/2025/05/Johann-Jungwirth.jpg" \
"https://www.linkedin.com/in/johannjungwirth/" || true

# Candidate 12: Judith Häberli
update_candidate "Judith Häberli" \
"Judith Häberli ist Mitgründerin und Chief Growth Officer (CGO) von Urban Connect, der führenden multimodalen, datengetriebenen Corporate Mobility-Plattform der Schweiz, die CO2-arme Fahrzeugökosysteme für große Unternehmen wie Roche, Google, Lonza, Hilti und Bosch anbietet. Sie hat einen Abschluss in Wirtschaftswissenschaften von der Universität Zürich und qualifizierte sich als Smart Mobility Manager an der Executive School der Universität St. Gallen, was ihre formale HSG-Verbindung etabliert. Häberli ist Mitglied des Advisory Boards des Instituts für Mobilität der Universität St. Gallen (IMO-HSG) und Vorstandsmitglied des DACH-weiten Vereins Mobility Allstars. Als Gewinnerin des EY Entrepreneur of the Year 2023 Schweiz in der Kategorie "Emerging Entrepreneur" und anerkannt als BILANZ Digital Shaper 2023 unter den führenden Schweizer Digitalisierungsführern treibt sie die Dekarbonisierung von Unternehmen durch nachhaltige Mitarbeitermobilitätslösungen voran. Ihre Relevanz für Mobility Trailblazers liegt in ihrem unternehmerischen Erfolg beim Aufbau skalierbarer, klimaneutraler Mobilitätsinfrastruktur, die 873+ Flottenoperationen erreicht hat und messbare Emissionsreduktionen für Unternehmenskunden demonstriert." \
"" \
"https://www.linkedin.com/in/judith-häberli/" || true

# Candidate 13: Jürgen Stackmann
update_candidate "Jürgen Stackmann" \
"Jürgen Stackmann ist Director des Future Mobility Lab am IMO-HSG Institut für Mobilität der Universität St. Gallen, eine Position, die er seit 2020 innehat. Seine Expertise liegt in nachhaltiger Mobilitätstransformation, Verhaltensökonomie angewandt auf Transport und zukünftigen Mobilitätssystemen einschließlich Shared Mobility und Elektrifizierung. Er bringt über 30 Jahre Erfahrung in der Automobilindustrie mit, nachdem er Top-Führungspositionen innehatte, darunter CEO von SEAT (2013-2015), Vorstandsmitglied für Vertrieb und Marketing bei Volkswagen Pkw und Vorstandsmitglied bei Škoda Auto, gefolgt von Führungspositionen bei Ford Europa. Seine HSG-Verbindung konzentriert sich auf die Leitung von Forschungsinitiativen wie der "New Mobility Buddies"-Studie und dem CAS Smart Mobility Management Programm, wo er durch kollaborative Partnerschaften mit Städten, Mobilitätsanbietern und Startups in Deutschland und der Schweiz evidenzbasierten Mobilitätsverhaltensänderungen vorantreibt. Seine Arbeit ist hochrelevant für Mobility Trailblazers, da er die Transformation der Automobilindustrie mit akademischer Forschung verbindet, um reale nachhaltige Mobilitätslösungen zu schaffen." \
"https://imo.unisg.ch/wp-content/uploads/2022/04/JS-300x300.jpg" \
"https://www.linkedin.com/in/juergenstackmann/" || true

# Candidate 14: Karolin Frankenberger
update_candidate "Karolin Frankenberger" \
"Prof. Dr. Karolin Frankenberger ist Dekanin der Executive School of Management, Technology and Law an der Universität St. Gallen und Ordinaria für Strategisches Management und Innovation, die das Institut für Management & Strategy (IfB-HSG) leitet. Ihre Expertise umfasst Geschäftsmodellinnovation, digitale Transformation, Kreislaufwirtschaft und nachhaltige Geschäftsökosysteme – kritische Bereiche für die Transformation des Mobilitätssektors. Sie promovierte summa cum laude an der HSG (2004) mit Forschungsaufenthalten an der Harvard Business School und der University of Connecticut und verbrachte anschließend sieben Jahre als Senior Engagement Manager bei McKinsey & Company, bevor sie 2011 zur HSG zurückkehrte. Ihr international gefeiertes Buch "The Business Model Navigator" ist ein Standardreferenzwerk, und sie hat in führenden Zeitschriften wie Harvard Business Review und Academy of Management Journal publiziert. Ihre HSG-Verbindung ist fundamental – sie ist seit 2011 an der Universität und erhielt 2025 den Best Lecturer Award von HSG-Studenten. Ihre Forschung zur Transformation traditioneller Geschäftsmodelle hin zu Nachhaltigkeit und ihre Arbeit zu Innovationsökosystemen machen sie außergewöhnlich relevant für die Führung von Mobilitätsunternehmen durch den Übergang zu nachhaltigen, technologiegetriebenen Geschäftsmodellen." \
"https://ifb.unisg.ch/wp-content/uploads/2023/03/Karolin_Frankenberger.png.webp" \
"https://www.linkedin.com/in/prof=d=karolin=frankenberger=83510b47/" || true

# Candidate 15: Katrin Habenschaden
update_candidate "Katrin Habenschaden" \
"Katrin Habenschaden ist seit Dezember 2023 Leiterin Nachhaltigkeit & Umwelt bei der Deutsche Bahn AG und verantwortlich für die grüne Transformation des größten deutschen Mobilitätsunternehmens mit dem Ziel, bis 2040 Klimaneutralität zu erreichen. Ihre Expertise umfasst nachhaltige Mobilitätstransformation, Klimapolitik, Kreislaufwirtschaft und Biodiversität in Transportsystemen. Zuvor war sie Zweite Bürgermeisterin von München (2020-2023), wo sie die Klimaschutz-, Mobilitätstransformations- und Umweltinitiativen der Stadt mit dem ehrgeizigen Ziel leitete, München bis 2035 klimaneutral zu machen. Die ausgebildete Bankkauffrau und Betriebswirtin bringt umfangreiche Erfahrung in Transformationsprozessen und urbaner Mobilitätsplanung mit. Ihre Verbindung zur Universität St. Gallen erfolgt durch ihre Rolle als Advisory Board Member am IMO-HSG Institut für Mobilität, wo sie zum CAS Smart Mobility Management Programm beiträgt und an Forschungsinitiativen wie Smart Mobility Summit-Diskussionen teilnimmt. Ihre Relevanz für Mobility Trailblazers liegt in ihrer einzigartigen dualen Perspektive der urbanen Mobilitätspolitikgestaltung und großangelegten Unternehmens-Nachhaltigkeitstransformation im deutschen Bahnsektor." \
"https://imo.unisg.ch/wp-content/uploads/2023/05/DSC03054.jpg" \
"https://www.linkedin.com/in/katrinhabenschaden/" || true

# Candidate 16: Karsten Crede
update_candidate "Karsten Crede" \
"Karsten Crede trat im März 2024 als Dozent am Institut für Mobilität (IMO-HSG) der Universität St. Gallen ein und konzentriert sich auf Smart Mobility- und Versicherungsthemen. Seine Expertise liegt an der Schnittstelle von Automobiltechnologie, Mobilitätsversicherungslösungen und digitaler Transformation im Mobilitätssektor. Er war bis Dezember 2023 CEO von Ergo Mobility Solutions und Vorstandsmitglied von Ergo Digital Ventures, wo er innovative Automobilversicherungsprodukte auf Basis von Fahrzeugdaten und Technologie entwickelte und strategische Partnerschaften mit BMW, Volvo und Great Wall Motors etablierte. Vor Ergo hatte er verschiedene Positionen in der Volkswagen Group (2010-2016) und der Gerling-Versicherungsgruppe inne. Er ist Mitbegründer von The Mobility Insurance Network und verfügt über tiefgreifende Expertise in nutzungsbasierter Versicherung, Telematik, Elektromobilitätsversicherung und Connected Car Services. Seine HSG-Zugehörigkeit repräsentiert einen Übergang von der Industriepraxis zur akademischen Lehre und bringt über 25 Jahre Automobilversicherungsexpertise zu zukünftigen Mobilitätsführern. Seine Relevanz für Mobility Trailblazers ergibt sich aus seiner Pionierarbeit bei der Schaffung von Versicherungsrahmen für neue Mobilitätsmodelle einschließlich Auto-Abonnements, Shared Mobility und autonomer Fahrzeuge." \
"" \
"https://www.linkedin.com/in/karstencrede/" || true

# Candidate 17: Kerstin Wagner
update_candidate "Kerstin Wagner" \
"Kerstin Wagner ist seit Juni 2012 Executive VP of Talent Acquisition bei der Deutsche Bahn AG und überwacht globale Arbeitgebermarkenbildung, Recruiting-Strategie und Zeitarbeitsverwaltung für über 300.000 Mitarbeiter in 49 Ländern. Ihre Expertise umfasst nachhaltige Mobilität und Belegschaftstransformation im Transportsektor mit starkem Fokus auf die Positionierung der Deutschen Bahn als Führerin in umweltbewussten Mobilitätslösungen. Sie ist Gastdozentin im CAS SMART Mobility Management Programm an der Universität St. Gallen (IMO-HSG-verbunden), wo sie Einblicke in nachhaltige Talentakquise und Belegschaftsentwicklung im Mobilitätssektor teilt. Wagners HSG-Verbindung erfolgt durch das Executive Education Programm, wo sie als ausgewiesene Expertin neben anderen Mobilitätsindustrie-Führern fungiert. Ihre Arbeit ist mit der Mobility Trailblazers-Initiative durch ihren Pionieransatz zur Talentakquise in nachhaltiger Mobilität und ihre Befürwortung innovationsgetriebener Belegschaftsstrategien in der Mobilitätsrevolution abgestimmt." \
"https://smart-mobility-management.com/wp-content/uploads/2025/05/Kerstin-Wagner-scaled-L.jpg" \
"https://de.linkedin.com/in/kerstin-wagner" || true

# Candidate 18: Kurt Bauer
update_candidate "Kurt Bauer" \
"Kurt Bauer ist Leiter Fernverkehr und neue Bahngeschäfte bei der ÖBB (Österreichische Bundesbahnen), wo er die strategische Entwicklung für Europas expandierendes Fernverkehrsnetz leitet. Mit über 10 Jahren in der Bahnindustrie und fortgeschrittenen Abschlüssen in Verkehrstechnik vom Imperial College London und International Business von der Leopold-Franzens-Universität Innsbruck ist Bauer ein anerkannter Experte für nachhaltige Mobilitätslösungen. Seine HSG-Zugehörigkeit umfasst seine Rolle als ausgewiesener Gastredner im CAS SMART Mobility Management Executive Programm an der Universität St. Gallen und seinen Auftritt im IMO-HSG Mobility Pioneers Podcast zur Diskussion von Nightjet-Services und der Zukunft europäischer Bahnmobilität. Seine Arbeit an der ÖBB-Klimaticket-Initiative und der Erweiterung von Nachtzugservices verkörpert sein Engagement für nachhaltigen Transport. Für Mobility Trailblazers repräsentiert Bauer innovative Führung im öffentlichen Bahnverkehr und demonstriert, wie traditionelle Mobilitätsanbieter die Nachhaltigkeitstransformation vorantreiben können." \
"https://smart-mobility-management.com/wp-content/uploads/2025/05/Kurt-Bauer-scaled-L.jpg" \
"https://www.linkedin.com/in/kurt-bauer-1594218/" || true

# Candidate 19: Lukas Neckermann
update_candidate "Lukas Neckermann" \
"Lukas Neckermann ist Managing Director von Neckermann Strategic Advisors, einer in London ansässigen Beratung, die sich ausschließlich auf Smart Cities und Smart Mobility spezialisiert, und dient als Dozent an der Universität St. Gallen. Mit über 20 Jahren Führungserfahrung bei BMW und Allianz Group sowie Rollen als Berater für Mobilitäts-Startups wie NEXT Modular Transportation, MSCI und ehemaliger Interim COO von Splyt ist Neckermann eine führende Stimme in der Mobilitätsrevolution. Er hat Abschlüsse von der Cornell University (Science and Technology Studies) und NYU Stern School of Business (MBA) und ist Autor von vier einflussreichen Büchern, darunter "The Mobility Revolution" (2015), "Smart Cities, Smart Mobility" (2017) und "Corporate Mobility Breakthrough 2020". Seine HSG-Verbindung erfolgt durch seine Rolle als Dozent mit Fokus auf die "Three Zeroes"-Transformation: Zero Emissions, Zero Accidents, Zero Ownership. Neckermanns Relevanz für Mobility Trailblazers ist von höchster Bedeutung – er prägte buchstäblich den Begriff "Mobilitätsrevolution" und bietet strategische Beratung an der Schnittstelle von Mobilitätsinnovation, autonomen Fahrzeugen und nachhaltiger urbaner Transformation." \
"https://www.neckermann.net/wp-content/uploads/2016/07/f-N_LJPG.jpg" \
"https://www.linkedin.com/in/lukasneckermann/" || true

# Candidate 20: Maja Göpel
update_candidate "Maja Göpel" \
"Prof. Dr. Maja Göpel ist Politökonomin, Transformationsforscherin und Nachhaltigkeitswissenschaftlerin, die von 2017-2020 als Generalsekretärin des Wissenschaftlichen Beirats der Bundesregierung Globale Umweltveränderungen (WBGU) tätig war. Sie ist Honorarprofessorin an der Leuphana Universität Lüneburg, Mitbegründerin von Scientists for Future und Gründerin von Mission Wertvoll. Ihre HSG-Verbindung erfolgte als "Personality in Residence" am SQUARE (HSG Learning Center) vom 13.-16. März 2023, wo sie Vorträge und Interviews zur gesellschaftlichen Transformation in Richtung Nachhaltigkeit hielt. Göpel ist Mitglied des Club of Rome, World Future Council und des Deutschen Bioökonomierats und Bestsellerautorin von "Unsere Welt neu denken" und "The Great Mindshift" (2016). Ihre Expertise in Nachhaltigkeitstransformationen, politischer Ökonomie und systemischem Wandel positioniert sie als Vordenkerin bei der Neudefinition wirtschaftlicher Paradigmen jenseits wachstumsfokussierter Modelle. Für Mobility Trailblazers repräsentiert Göpel den breiteren sozioökonomischen Transformationskontext, der für nachhaltige Mobilität notwendig ist, und liefert den theoretischen und ethischen Rahmen für systemischen Wandel in der Organisation von Transport, Städten und Konsummustern." \
"" \
"" || true

# Candidate 21: Matthias Ballweg
update_candidate "Matthias Ballweg" \
"Dr. Matthias Ballweg ist Mitgründer von CIRCULAR REPUBLIC bei UnternehmerTUM, Europas größtem Startup- und Entrepreneurship-Hub, wo er Multi-Stakeholder-Kooperationsprojekte orchestriert, die sich auf Kreislaufwirtschaft und nachhaltige Mobilität konzentrieren. Er promovierte in Verhaltenspsychologie und war zuvor Vice President Strategy bei MAN Truck & Bus und leitete gemeinsam Systemiqs globale Circular Economy Platform. Seine Verbindung zur Universität St. Gallen erfolgt durch das IMO-HSG (Institut für Mobilität), wo er den Mobility Pioneers Podcast gemeinsam mit Professor Andreas Herrmann hostet und als Dozent im CAS Smart Mobility Management Executive Education Programm fungiert. Seine Expertise umfasst Kreislaufwirtschaft, nachhaltige Mobilität und Klimalösungen, was ihn hochrelevant für Mobility Trailblazers-Initiativen macht, die sich auf systemische Transformation von Transportsystemen konzentrieren." \
"" \
"https://www.linkedin.com/in/matthias-ballweg/" || true

# Candidate 22: Melan Thuraiappah
update_candidate "Melan Thuraiappah" \
"Prof. Dr. Melan Thuraiappah absolvierte seine Promotion an der Universität St. Gallen (2016-2020) in Business Innovation und Leadership Culture mit summa cum laude Auszeichnung, was seine starke HSG-Verbindung etabliert. Nach seinem Doktorat führte er Postdoktorandenforschung an der Stanford University (2021-2022) in künstlicher Intelligenz, translationaler Medizin und Teamzusammensetzung durch, wo er prädiktive Modelle für klinische Entscheidungsfindung entwickelte. Er ist derzeit Professor für Leadership & Innovation an der FHDW (Fachhochschule der Wirtschaft) und Partner bei Jenewein AG, einem Leadership-Coaching-Unternehmen, das globale Konzerne bedient. Während sein primärer Forschungsfokus auf Leadership und Innovation liegt statt spezifisch auf Mobilität, verbindet ihn sein HSG-Hintergrund in Business Innovation und seine Arbeit bei Unternehmen wie Audi AG, Philips und Robert Bosch mit nachhaltigen Innovationsökosystemen, die für zukünftige Mobilitätstransformation relevant sind." \
"" \
"https://www.linkedin.com/in/melanthuraiappah/" || true

# Candidate 23: Michael Barillère-Scholz
update_candidate "Michael Barillère-Scholz" \
"Dr. Michael Barillère-Scholz ist Mitgründer und CEO von ioki, einem Deutsche Bahn-Unternehmen, das zu Europas Plattformmarktführer für fahrerbasierte und autonome On-Demand-Mobilitätslösungen geworden ist. Seine Verbindung zur Universität St. Gallen ergibt sich aus dem Abschluss eines Diploms in Business Consulting an der St. Galler Business School (2001-2002), die mit dem Universitäts St. Gallen-System verbunden ist. Er promovierte in Wirtschaftsinformatik an der Universität Paderborn und hat einen Master in Transport & Logistics von der Hochschule Ostwestfalen-Lippe. Unter seiner Führung hat ioki prestigeträchtige Auszeichnungen erhalten, darunter den Deutschen Mobilitätspreis und den Deutschen Verkehrswendepreis für die Revolutionierung des öffentlichen Verkehrs durch digitale Transformation. Seine Expertise in bedarfsorientiertem Transport, autonomem Fahren und Smart Mobility Analytics macht ihn zu einem Pionier in nachhaltigen urbanen Mobilitätslösungen und hochrelevant für Mobility Trailblazers-Initiativen." \
"" \
"https://linkedin.com/in/dr-michael-barillère-scholz-5a8502138" || true

# Candidate 24: Nigell Storny
update_candidate "Nigell Storny" \
"Nigell Storny ist Managing Director bei LeasePlan Schweiz (und zuvor Österreich), wo er nachhaltige Flottenmanagement-Initiativen leitet. Er ist ein prominenter Befürworter der Elektromobilität und hat LeasePlan Schweiz zur EV100-Initiative der Climate Group verpflichtet mit dem Ziel, bis 2030 Netto-Null-Emissionen über verwaltete Flotten hinweg zu erreichen. Seine Arbeit konzentriert sich auf die Umstellung von Unternehmensflotten auf Elektrofahrzeuge und die Förderung nachhaltiger Mobilitätslösungen im Schweizer Markt. Während er im Schweizer Mobilitäts-/Nachhaltigkeitssektor tätig ist und möglicherweise Verbindungen zur breiteren Schweizer Geschäftswelt hat, konnte keine direkte Bildungs- oder berufliche Zugehörigkeit zur Universität St. Gallen (HSG) durch verfügbare Quellen verifiziert werden. WICHTIGER HINWEIS: Die Zugehörigkeit zur Universität St. Gallen konnte trotz umfangreicher Recherche nicht bestätigt werden." \
"" \
"https://nl.linkedin.com/in/nigel-storny-825b856" || true

# Candidate 25: Nikolaus Lang
update_candidate "Nikolaus Lang" \
"Nikolaus S. Lang ist seit 2021 Honorarprofessor für Betriebswirtschaftslehre an der Universität St. Gallen und Managing Director & Senior Partner bei der Boston Consulting Group (BCG), wo er als Global Leader der Global Advantage-Praxis und Gründer & Direktor von BCGs Center for Mobility Innovation fungiert. Er ist ein globaler Experte für Konnektivität, autonome Fahrzeuge, Carsharing und Flottenmanagement und berät Städte, öffentliche Verkehrsbetreiber und Mobilitätsunternehmen weltweit zu innovativen Mobilitätslösungen. Lang absolvierte sein Promotionsstudium an der Universität St. Gallen (1994-1997, summa cum laude) und seinen Master an der HSG (1992-1994), was eine über 25-jährige Verbindung zur Institution etabliert. Er ist Co-Autor von "Beyond Great" und Mitglied des Global Urban and Autonomous Mobility Council des Weltwirtschaftsforums, was ihn als Schlüssel-Vordenker für Mobilitätstransformationsinitiativen positioniert. Seine duale Rolle als BCG-Executive und HSG-Professor verbindet Industriepraxis und akademische Forschung in Mobilitätsinnovation." \
"https://ifb.unisg.ch/wp-content/uploads/2021/04/Nikolaus_Lang.png.webp" \
"https://www.linkedin.com/in/nikolauslang/" || true

# Candidate 26: Christoph Wolff (Oliver Wolff - Clarification: Christoph Wolff has formal HSG affiliation)
update_candidate "Christoph Wolff" \
"Dr. Christoph Wolff ist seit 2022 CEO des Smart Freight Centre und Visiting Professor an der Universität St. Gallen, wo er seit 2020 Kurse über "Future of Mobility" und Nachhaltigkeit im CAS Smart Mobility Management Programm unterrichtet. Er ist auch Honorarprofessor an der Wirtschafts- und Sozialwissenschaftlichen Fakultät der Universität zu Köln und Senior Fellow am UC Davis Institute for Transportation Studies. Zuvor war er Mitglied des Executive Committee und Global Head of Mobility beim Weltwirtschaftsforum (2018-2021) und Managing Director der European Climate Foundation (2014-2018). Seine Expertise umfasst Frachtdekarbonisierung, nachhaltige Logistik, Elektromobilität und Klimapolitik, mit formalen akademischen Lehrverpflichtungen an der HSG, die sich auf Mobilitätstransformation und Nachhaltigkeitsinnovation konzentrieren. Seine HSG-Verbindung repräsentiert eine wichtige Brücke zwischen globaler Klimaaktion und Mobilitätsforschung." \
"" \
"https://www.linkedin.com/in/christoph-wolff-861b2889/" || true

# Candidate 27: Olga Nevska
update_candidate "Olga Nevska" \
"Dr. Olga Nevska ist seit 2019 Geschäftsführerin von Telekom MobilitySolutions und Gastdozentin am Institut für Mobilität der Universität St. Gallen, wo sie Executive Education-Kurse über Smart Mobility, Corporate Mobility, Digitalisierung, Elektrifizierung und Dekarbonisierung unterrichtet. Sie promovierte in Wirtschafts- und Rechtswissenschaften an der Freien Universität Berlin und setzt sich für nachhaltige, geteilte und vernetzte Mobilität für Unternehmensflotten ein, wobei sie die Transformation einer der größten deutschen Unternehmensfahrzeugflotten (25.000+ Fahrzeuge) zu einem innovativen Mobilitätsanbieter überwacht. Als eine der 100 Frauen, die Deutschland voranbringen, vom Handelsblatt ausgezeichnet und unter den TOP 50 Frauen in der Automobilindustrie von Automobilwoche (2023) anerkannt, ist sie eine führende Stimme in Mobility-as-a-Service (MaaS) und Corporate Mobility Transformation. Ihre HSG-Zugehörigkeit positioniert sie als Schlüssel-Praktikerin, die Real-World-Flottenmanagement- und Corporate Mobility-Expertise in die Executive Education Programme der Universität einbringt. Sie repräsentiert die kritische Schnittstelle von Telekommunikation, Corporate Mobility und Nachhaltigkeitstransition im Mobility Trailblazers-Kontext." \
"https://www.linkedin.com/in/olganevska=transformation=digitalization=strategy=leadership=innovation=ceo=managingdirector/" \
"https://www.linkedin.com/in/olganevska=transformation=digitalization=strategy=leadership=innovation=ceo=managingdirector/" || true

# Candidate 28: Philipp Scharfenberger
update_candidate "Philipp Scharfenberger" \
"Dr. Philipp Scharfenberger ist Vizedirek tor des Instituts für Mobilität (IMO-HSG) und Dozent/Projektleiter am Institut für Marketing und Customer Insight der Universität St. Gallen. Seine Forschung konzentriert sich auf Konsum- und Mobilitätsbedürfnisse, Markenmanagement und Mobilitätsverhaltenswandel, mit Publikationen in peer-reviewed Zeitschriften über Konsumentenverhalten und nachhaltige Mobilität. Er leitet das Future Mobility Lab, das Forschung zu Verhaltensänderungen und nachhaltiger Mobilitätsadoption durchführt (einschließlich der "New Mobility Buddys"-Studie), und leitet gemeinsam das AMAG X IMO Lab, das sich auf individuelle nachhaltige Mobilitätslösungen konzentriert. Als Schlüsselakademiker am IMO-HSG unterrichtet er Konsumentenverhalten, Marketingkommunikation und Mobilitätsmanagement sowohl auf Bachelor- als auch auf Masterebene. Seine Arbeit verbindet akademische Forschung und praktische Anwendung durch Zusammenarbeit mit Automobilunternehmen, FMCG-Firmen und Mobilitätsdienstleistern in Deutschland und der Schweiz. Er ist maßgeblich daran beteiligt, Mobilitätsforschung in umsetzbare Erkenntnisse für die Mobility Trailblazers-Initiative zu übersetzen und repräsentiert die nächste Generation von HSG-Mobilitätswissenschaftlern." \
"https://imc.unisg.ch/app/uploads/2021/10/philipp-scharfenberger.jpg" \
"https://www.linkedin.com/in/dr-philipp-scharfenberger-26356712a/" || true

# Candidate 29: Philipp Rode
update_candidate "Philipp Rode" \
"Dr. Philipp Rode ist Executive Director von LSE Cities an der London School of Economics und Visiting Professor am Institut für Mobilität (IMO-HSG) der Universität St. Gallen, wo er als Schlüsselfakultätsmitglied in Mobilitätsforschung und -bildung fungiert. Seine Expertise umfasst nachhaltige Stadtentwicklung, neue urbane Mobilität, Verkehrsübergänge und soziotechnologischen Wandel, mit Forschung, die in führenden Zeitschriften wie Transport Policy und Transportation Research Part A veröffentlicht wurde. Er hat bemerkenswerte globale Wirkung erzielt, indem er die UN Habitat III Policy Unit on Urban Governance mitleitete, die die New Urban Agenda (2016) informierte, als Steering Committee Member der Coalition for Urban Transitions (2016-2021) diente und im Board of Directors des Institute for Transportation and Development Policy sitzt. Seine HSG-Verbindung ist strategisch und forschungsorientiert durch Zusammenarbeit mit dem IMO-HSG an Projekten, die urbane Verkehrsübergänge, Fairness in Mobilitätspolitik und die Überwindung von Autoabhängigkeit untersuchen, was ihn hochrelevant für die Mobility Trailblazers-Initiative durch seine internationale Vordenkerschaft für nachhaltige urbane Mobilitätssysteme macht. Er hat Abschlüsse in Transportsystemen (TU Berlin), City Design (LSE) und Cities/Urban Governance (PhD, LSE) und erhielt 2000 den Schinkel Urban Design Prize." \
"" \
"https://www.linkedin.com/in/philipp-rode-814623102/" || true

# Candidate 30: Philipp Wetzel
update_candidate "Philipp Wetzel" \
"Philipp Wetzel ist seit Juli 2018 Managing Director des AMAG Innovation & Venture LAB bei der AMAG Group und ist direkt mit der Universität St. Gallen durch die AMAG X IMO Lab-Kooperation verbunden, eine dreijährige Partnerschaft, die 2023 etabliert wurde, um individuelle nachhaltige Mobilitätslösungen einschließlich Mobility as a Service, Elektromobilität und autonomer Mobilität zu entwickeln. Seine Expertise umfasst Mobilitätsinnovation, digitale Transformation und die Entwicklung neuer Geschäftsmodelle, mit Verantwortung für das Scouting von Mobilitätstrends, die Entwicklung von Ventures und die Leitung strategischer Initiativen in Smart Mobility. Er hat bedeutende Wirkung erzielt, indem er AMAGs Innovationsökosystem von Grund auf aufbaute, Partnerschaften mit führenden Universitäten einschließlich HSG etablierte und Mobilitäts-Ventures wie Clyde entwickelte, das mit dem Future Mobility Lab des IMO-HSG zusammenarbeitet. Seine HSG-Verbindung ist durch die AMAG X IMO Lab-Kooperationsvereinbarung formalisiert, die die Finanzierung einer Doktorandenstelle an der HSG und gemeinsame Forschung zu nachhaltigen Mobilitätsthemen umfasst, was ihn als hochrelevant für die Mobility Trailblazers-Initiative durch seine Brücke zwischen Automobilindustrie-Innovation und akademischer Forschung positioniert. Er hat einen Abschluss als Dipl. Ing. ETH mit MBA und bringt umfangreiche Erfahrung aus Consulting und der Konsumgüterindustrie mit, nachdem er 2012 zu AMAG kam, wo er zuvor als Director Marketing & Business Development und Chief Digital Officer tätig war." \
"" \
"https://ch.linkedin.com/in/philippwetzel" || true

# Candidate 31: Rolf Wüstenhagen
update_candidate "Rolf Wüstenhagen" \
"Prof. Dr. Rolf Wüstenhagen ist seit 2003 Ordinarius für Management Erneuerbarer Energien und Direktor des Instituts für Wirtschaft und Umwelt (IWÖ-HSG) an der Universität St. Gallen und innehabend des Good Energies Chair. Seine Expertise konzentriert sich auf Clean Energy Investment und Finanzierung, gesellschaftliche Akzeptanz erneuerbarer Energien und Entscheidungsfindung unter Politikrisiko, mit besonderer Relevanz für nachhaltige Mobilität durch den Energie-Mobilitäts-Nexus in Elektrofahrzeugen und Ladeinfrastruktur. Er hat bedeutende Anerkennung als Lead Author für den IPCC Special Report on Renewable Energy (2008-2011) erhalten, war Mitglied des Beratungsgremiums der Schweizer Bundesregierung für Energiestrategie 2050 (2011-2015), Akademischer Direktor des REM-HSG Executive Education Programms seit 2010 und wurde als einer der weltweit 20 einflussreichsten Fakultätsvordenker für verantwortungsvolles Geschäft in sozialen Medien (2018) anerkannt. Seine HSG-Verbindung ist grundlegend als ordentlicher Vollprofessor, der zwei große akademische Programme leitet (Renewable Energy Management und Managing Climate Solutions), Kurse über Clean Energy Marketing und Investment unterrichtet und Doktorandenforschung über Klimalösungen und Energieübergänge betreut. Er ist hochrelevant für die Mobility Trailblazers-Initiative durch seine Forschung zur Konvergenz von Solar-Photovoltaik, Batteriespeicherung, Digitalisierung und Elektromobilität, die die kritische Energieinfrastruktur für nachhaltige Transportsysteme adressiert. Er hat Abschlüsse in Betriebswirtschaftslehre (TU Berlin) und einen PhD in Business (Universität St. Gallen) und arbeitete zuvor in der Venture Capital-Industrie bei SAM Private Equity vor seiner akademischen Karriere." \
"" \
"https://www.linkedin.com/com/in/rolf-wuestenhagen=stgallen/" || true

# Candidate 32: Sascha Meyer
update_candidate "Sascha Meyer" \
"Sascha Meyer ist seit August 2022 CEO von MOIA GmbH, Europas größtem vollelektrischem Ridepooling-Anbieter, der eine Flotte von 565 batterie-elektrischen Fahrzeugen in Hamburg und Hannover betreibt, und ist mit der Universität St. Gallen als Gastdozent verbunden, der über Smart Mobility, Mobility-as-a-Service und autonome Fahrzeuge unterrichtet, und wurde kürzlich als einer der 25 Mobility Trailblazers 2025 vom IMO-HSG Institut für Mobilität der HSG ausgezeichnet. Seine Expertise umfasst autonome Fahrtechnologie, Shared Mobility-Geschäftsmodelle und die Digitalisierung des urbanen Verkehrs, mit tiefgreifendem Wissen über den Aufbau und Betrieb großangelegter elektrischer Ridepooling-Services und die Entwicklung von Level-4 autonomen Fahrzeugsystemen. Er hat wesentliche Industriewirkung erzielt, indem er MOIA zu einem integralen Bestandteil von Hamburgs öffentlichem Verkehrssystem aufbaute (über 11 Millionen Passagiere seit 2019 befördert), seit Juni 2024 als Vice Chair der Shared Mobility Division bei UITP (Internationaler Verband für öffentliches Verkehrswesen) dient und die Entwicklung autonomer Mobilitätsservices mit geplantem kommerziellem Start in Hamburg 2027 unter Verwendung des ID. Buzz AD autonomen Fahrzeugs leitet. Seine HSG-Verbindung kombiniert Gastdozentenverpflichtungen mit praktischer Zusammenarbeit, indem er vom IMO-HSG als Mobility Trailblazer 2025 anerkannt wurde und zu den Bildungsprogrammen der Universität über zukünftige Mobilitätssysteme beiträgt. Er ist außergewöhnlich relevant für die Mobility Trailblazers-Initiative als aktiver Praktiker, der autonome elektrische Shared Mobility in großem Maßstab implementiert und die Lücke zwischen akademischen Konzepten und realer Umsetzung überbrückt, nachdem er zuvor mehrere Jahre als Unternehmensberater internationale Firmen zur digitalen Transformation von Transport und Logistik beriet, bevor er 2017 zu MOIA als Head of Product kam, dann Chief Product Officer (2019-2022)." \
"" \
"https://www.linkedin.com/in/sasmeyer/" || true

# Candidate 33: Sylvia Lier
update_candidate "Sylvia Lier" \
"Sylvia Lier ist Geschäftsführerin der TAF mobile GmbH, wo sie cloudbasierte Mobility-as-a-Service (MaaS)-Plattformen und digitale Angebote einschließlich Mobilitätsbudgets und sensorbasierter Ticketing-Systeme entwickelt. Ihre Expertise umfasst multimodale persönliche Mobilität mit über 25 Jahren Erfahrung in Fahrzeugflottenmanagement, plattformbasierter Shared Mobility und öffentlichem Verkehr, nachdem sie zuvor als CEO von DB Fuhrparkservice GmbH und kaufmännisches Vorstandsmitglied der Rheinbahn AG tätig war. Sie ist seit 2021 Dozentin am Institut für Mobilität (IMO-HSG) der Universität St. Gallen im Smart Mobility Management Programm, wo sie akademische Expertise über nachhaltige Mobilitätstransformation beiträgt. Ihre Erfolge umfassen den 2018 Clara Jaschke Innovation Award der Pro-Bahn-Allianz für das Mobilitätsbudget-Konzept, den Deutschen Mobilitätspreis (BMDV) und Anerkennung als LinkedIn Top Voice. Als Mobility Trailblazer verkörpert sie den Übergang von autozentrierter zu multimodaler nachhaltiger Mobilität, berät aktiv Ministerien und Think Tanks zur Mobilitätstransformation und vertritt die Vision, dass "Menschen auch ohne eigenes Auto gut und klimafreundlich mobil sein können"." \
"https://smart-mobility-management.com/wp-content/uploads/2025/05/Sylvia-Lier-1-scaled-L.jpg" \
"https://www.linkedin.com/in/sylvialier/" || true

# Candidate 34: Timo Schneckenburger
update_candidate "Timo Schneckenburger" \
"Timo Schneckenburger ist Geschäftsführer der OTEC GmbH & Co KG, einem familiengeführten Immobilienentwicklungsunternehmen, das sich auf innovative Stadtentwicklungsprojekte konzentriert, insbesondere im Münchner Werksviertel-Mitte, wo er nachhaltige Bau- und Mobilitätsinfrastrukturinitiativen leitet. Seine Expertise verbindet Marketing, Innovation und nachhaltige urbane Mobilität, entwickelt durch Führungspositionen einschließlich 14 Jahren als Chief Marketing and Commercial Officer bei HD Plus (Satelliten-TV-Plattform) und früheren Positionen bei BMW Group und O2 Telekommunikation. Er dient als Dozent/Speaker im Smart Mobility Management (CAS) Executive Education Programm der Universität St. Gallen am IMO-HSG, wo er praktische Industrieperspektiven zu Mobilitätsinnovation und digitaler Transformation beiträgt. Seine jüngsten Erfolge umfassen die Leitung des VePa Parkturm-Projekts – Europas erstem öffentlichen Parkturm mit integrierter Ladeinfrastruktur – das demonstriert, wie "urbane Mobilität effizient, ästhetisch und nachhaltig gestaltet werden kann". Durch seine HSG-Zugehörigkeit verbindet er Immobilienentwicklung mit Mobilitätsinnovation, was ihn relevant für Mobility Trailblazers für seine Arbeit zur Integration nachhaltiger Transportlösungen in urbane Infrastruktur und sein Engagement für die Schaffung von "Räumen, in denen Menschen gut zusammenleben können", macht." \
"https://smart-mobility-management.com/wp-content/uploads/2025/05/Timo-Schneckenburger_2.jpg" \
"https://www.linkedin.com/in/timoschneckenburger/" || true

# Candidate 35: Torsten Tomczak
update_candidate "Torsten Tomczak" \
"Prof. em. Dr. Dr. h.c. Torsten Tomczak ist emeritierter Professor für Marketing an der Universität St. Gallen und Mitbegründer (2021) und Co-Direktor des Instituts für Mobilität (IMO-HSG) gemeinsam mit Prof. Andreas Herrmann und Prof. Wolfgang Jenewein, was ihn zu einem grundlegenden Architekten des Mobilitätsforschungs- und -bildungsökosystems der HSG macht. Seine Expertise umfasst strategisches Marketing, Markenmanagement und Innovation, mit über 30 Jahren Lehre und Forschung an der HSG, wo er zuvor das Institut für Customer Insight leitete und als Vize-Rektor für Forschung (2011-2015) diente. Seine Erfolge umfassen die Autorenschaft von über 30 Büchern und 350+ Artikeln, die in führenden Zeitschriften wie Journal of Marketing und Journal of Product Innovation Management veröffentlicht wurden, den Credit Suisse Award for Best Teaching und Mentorpreis von HSG-Studenten erhielt und 2019 einen Ehrendoktor von der Universität Luzern verliehen bekam. Er ist Senior Partner der Beratung Tomczak-Gross & Partners, Präsident der Schweizerischen Akademie für Marketing-Wissenschaft und Co-Host des Marketing-Podcasts "Dirty Deeds Done Well". Seine IMO-HSG-Zugehörigkeit ist zentral – er etablierte dieses Institut, um die globale Mobilitätstransformation zu beobachten und wissenschaftliche Erkenntnisse in Politik, öffentlichen Diskurs und Geschäftspraxis zu übertragen, was ihn als Mobility Trailblazer durch seine Rolle beim Aufbau der intellektuellen Führung der HSG in nachhaltiger Mobilitätsforschung und Executive Education positioniert." \
"" \
"https://www.linkedin.com/in/torstentomczak/" || true

# Candidate 36: Volker Hartmann
update_candidate "Volker Hartmann" \
"Dr. Volker Hartmann ist ab Juli 2025 Chief Legal Officer und Chief Human Resources Officer bei ARX Robotics und Of Counsel bei reuschlaw, mit über 15 Jahren Erfahrung in autonomem Fahren, Robotik und KI-Recht im Automobil- und Mobilitätssektor. Seine Expertise konzentriert sich auf Produkthaftungsrecht, Compliance und regulatorische Angelegenheiten für autonome und vernetzte Fahrzeuge, nachdem er führende Rechtspositionen bei Audi, Mercedes-Benz, VW Group und Autonomous Driving-Startups innehatte. Er ist seit 2021 Gastdozent für Smart Mobility an der Universität St. Gallen und regelmäßiges Fakultätsmitglied des SMART Mobility Management-Zertifikatprogramms an der HSG, wo er rechtliche Aspekte des autonomen Fahrens und intelligenter Mobilität unterrichtet. Seine umfangreichen Publikationen in führenden Rechtszeitschriften und seine Arbeit an der Schnittstelle von Technologie und Recht machen ihn zu einem anerkannten Experten für Mobilitätsinnovation und regulatorische Rahmenbedingungen. Als Mobility Trailblazer bringt er kritische rechtliche Enablement-Expertise ein, um sichere und konforme autonome Mobilitätslösungen in ganz Europa voranzutreiben." \
"https://www.reuschlaw.de/wp-content/uploads/2024/06/volker-51341-hires-2.jpg" \
"https://de.linkedin.com/in/dr-volker-hartmann-b5661211" || true

# Candidate 37: Wolfgang Jenewein
update_candidate "Wolfgang Jenewein" \
"Prof. Dr. Wolfgang Jenewein ist Titularprofessor für Betriebswirtschaftslehre an der Universität St. Gallen und leitet gemeinsam das Institut für Mobilität (IMO-HSG) mit Andreas Herrmann und Torsten Tomczak, mit Fokus auf Führung in der Mobilitätstransformation. Seine Forschungs- und Lehrexpertise umfasst positive Führung, kulturelle Transformation von Organisationen und High-Performance-Teammanagement in Wirtschaft und Sport, was ihn integral für das Mobilitätsinnovationsökosystem der HSG macht. Er hat mehrere Lehrpreise erhalten, darunter den Credit Suisse Best Teaching Award (2016) und den CEMS Best Teacher Worldwide Award (2018), und wurde vom Focus-Magazin als einer von Deutschlands fünf einflussreichsten Leadership-Coaches ausgezeichnet. Über die Wissenschaft hinaus ist er geschäftsführender Gründer von JENEWEIN AG und berät Fortune-500-Unternehmen und coacht Executive Teams im Mobilitätssektor zu Transformationsstrategien. Seine Verbindung zu Mobilitätsinitiativen durch das IMO-HSG und seine Expertise in Change Management positionieren ihn als Schlüssel-Vordenker für die Entwicklung zukunftsbereiter Mobilitätsorganisationen und die Kultivierung innovativer Führung in der Transportrevolution." \
"https://jenewein.ch/wp-content/uploads//00_Jenewein80-1024x683.jpg" \
"https://www.linkedin.com/in/wolfgangjenewein/" || true

# Candidate 38: Zheng Han
update_candidate "Zheng Han" \
"Prof. Dr. Zheng Han ist Chair Professor für Innovation und Entrepreneurship an der Tongji University Shanghai (Sino-German School for Postgraduate Studies) und dient als Visiting Professor und Advisory Board Member am Institut für Mobilität der Universität St. Gallen. Er absolvierte seine Promotion an der Universität St. Gallen als Stipendiat des Schweizerischen Nationalfonds, was tiefe Forschungsverbindungen zu HSGs Innovations- und Asien-Kompetenzzentren etabliert. Seine Expertise verbindet Innovationsmanagement, Entrepreneurship und strategische Mobilitätstransformation mit einzigartigem Fokus auf China-Europa-Technologietransfer und Automobilindustrieevolution, nachdem er sieben Jahre als Chief Representative des Fortune-500-Unternehmens Haniel Group in China tätig war. Er unterrichtet regelmäßig in EMBA- und Executive-Programmen an führenden Institutionen einschließlich ETH Zürich, Mannheim Business School und dem SMART Mobility Management Programm der Universität St. Gallen und bringt Einblicke in chinesische Mobilitätsinnovation und internationale Strategie ein. Als Brücke zwischen asiatischen und europäischen Mobilitätsökosystemen bietet er unschätzbare Perspektive auf globale Mobilitätstrends, Elektrofahrzeug-Marktdynamiken und interkulturelle Innovationsstrategien, die für die Mobility Trailblazers-Initiative essentiell sind." \
"" \
"https://www.linkedin.com/in/profhanzheng/" || true

print_header "Update Summary"
echo -e "${GREEN}Successfully updated: $SUCCESS_COUNT${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}Photos uploaded: $PHOTO_COUNT${NC}" | tee -a "$LOG_FILE"
echo -e "${RED}Failed: $ERROR_COUNT${NC}" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
log "Full log saved to: $LOG_FILE"

# Clear caches
if [ $SUCCESS_COUNT -gt 0 ]; then
    log "Clearing WordPress caches..."
    docker exec "$CONTAINER_CLI" wp cache flush --allow-root >/dev/null 2>&1
    docker exec "$CONTAINER_CLI" wp transient delete --all --allow-root >/dev/null 2>&1
    success "Caches cleared"
fi

echo ""
if [ $ERROR_COUNT -eq 0 ]; then
    success "Update completed successfully!"
    exit 0
else
    warning "Update completed with errors. Check $LOG_FILE for details."
    exit 1
fi
