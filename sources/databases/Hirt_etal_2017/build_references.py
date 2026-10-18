"""
build_references.py - Build references.csv for Hirt_etal_2017.

Extracts all unique mass.ref values from Hirt_etal_2017.csv, maps them to full
citations transcribed from the supplement PDF (41559_2017_241_MOESM1_ESM.pdf),
and searches Crossref for DOIs.

Run from the DB root or from the source folder:
  python3 sources/databases/Hirt_etal_2017/build_references.py
"""

import csv, json, os, re, time, unicodedata, urllib.request, urllib.parse
from difflib import SequenceMatcher

CROSSREF_EMAIL = 'mnovak.m@gmail.com'
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_FILE   = os.path.join(SCRIPT_DIR, 'Hirt_etal_2017.csv')
REFS_OUT   = os.path.join(SCRIPT_DIR, 'references.csv')
CACHE_FILE = os.path.join(SCRIPT_DIR, 'crossref_cache_hirt.json')

# Full citations from PDF (only those appearing as mass.ref in the data)
CITATIONS = {
    '1':  'Amaya, C. C., Klawinski, P. D. & Formanowicz, J., Daniel R. The Effects of Leg Autotomy on Running Speed and Foraging Ability in Two Species of Wolf Spider, (Lycosidae). Am. Midl. Nat. 145, 201–205 (2001).',
    '2':  'Apontes, P. & Brown, C. A. Between-sex variation in running speed and a potential cost of leg autotomy in the wolf spider Pirata sedentarius. Am. Midl. Nat. 154, 115–125 (2005).',
    '3':  'Auerbach, P. S. Wilderness Medicine: Expert Consult Premium Edition - Enhanced Online Features. (Elsevier Health Sciences, 2011).',
    '5':  'Bainbridge, R. The speed of swimming of fish as related to size and to the frequency and amplitude of the tail beat. J. Exp. Biol. 35, 109–133 (1958).',
    '6':  'Bainbridge, R. Speed and stamina in three fish. J. Exp. Biol. 37, 129–153 (1960).',
    '7':  'Bejan, A. & Marden, J. H. Unifying constructal theory for scale effects in running, swimming and flying. J. Exp. Biol. 209, 238–248 (2006).',
    '8':  'Blaxter, J. H. S. & Dickson, W. Observations on the swimming speeds of fish. J. Cons. 24, 472–479 (1959).',
    '9':  'Bleckmann, H. & Barth, F. G. Sensory ecology of a semi-aquatic spider (Dolomedes triton). Behav. Ecol. Sociobiol. 14, 303–312 (1984).',
    '10': 'Block, B. A., Booth, D. & Carey, F. G. Direct Measurement of Swimming Speeds and Depth of Blue Marlin. J. Exp. Biol. 166, 267–284 (1992).',
    '11': 'Bonner, J. T. Size and Cycle: An Essay on the Structure of Biology. (Princeton University Press, 2015).',
    '16': 'Christiansen, P. Locomotion in terrestrial mammals: the influence of body mass, limb length and bone proportions on speed. Zool. J. Linn. Soc. 136, 685–714 (2002).',
    '18': 'Clemente, C. J., Thompson, G. G. & Withers, P. C. Evolutionary relationships of sprint speed in Australian varanid lizards. J. Zool. 278, 270–280 (2009).',
    '24': 'Dangles, O., Ory, N., Steinmann, T., Christides, J.-P. & Casas, J. Spider\'s attack versus cricket\'s escape: velocity modes determine success. Anim. Behav. 72, 603–610 (2006).',
    '27': 'de Albuquerque, R. L., Bonine, K. E. & Garland Jr, T. Speed and endurance do not trade off in phrynosomatid lizards. Physiol. Biochem. Zool. 88, 634–647 (2015).',
    '28': 'Dijkstra, K.-D. B. & Lewington, R. Field Guide to the Dragonflies of Britain and Europe: Including western Turkey and north-western Africa. (British Wildlife Publishing Dorset, 2006).',
    '29': 'Dudley, R. The Biomechanics of Insect Flight: Form, Function, Evolution. (Princeton University Press, 2002).',
    '30': 'Dunning, J. B., JR. CRC Handbook of Avian Body Masses. (CRC Press Inc, 2007).',
    '32': 'Forsythe, T. G. Locomotion in ground beetles (Coleoptera Carabidae): an interpretation of leg structure in functional terms. J. Zool. 200, 493–507 (1983).',
    '33': 'Full, R. J. & Tu, M. S. Mechanics of a rapid running insect: two-, four- and six-legged locomotion. J. Exp. Biol. 156, 215–231 (1991).',
    '34': 'Garland, T. The relation between maximal running speed and body mass in terrestrial mammals. J. Zool. 199, 157–170 (1983).',
    '37': 'Gorb, S., Gorb, E. & Kastner, V. Scale effects on the attachment pads and friction forces in syrphid flies (Diptera, Syrphidae). J. Exp. Biol. 204, 1421–1431 (2001).',
    '42': 'Heinrichs, E. A. & others. Biology and management of rice insects. (John Wiley & Sons, 1994).',
    '44': 'Iriarte-Díaz, J. Differential scaling of locomotor performance in small and large terrestrial mammals. J. Exp. Biol. 205, 2897–2908 (2002).',
    '45': 'Kamoun, S. & Hogenhout, S. A. Flightlessness and Rapid Terrestrial Locomotion in Tiger Beetles of the Cicindela L. Subgenus Rivacindela van Nidek from Saline Habitats of Australia (Coleoptera: Cicindelidae). Coleopt. Bull. 50, 221–230 (1996).',
    '47': 'Kikuchi, Y. & Fukatsu, T. Live imaging of symbiosis: spatiotemporal infection dynamics of a GFP-labelled Burkholderia symbiont in the bean bug Riptortus pedestris. Mol. Ecol. 23, 1445–1456 (2014).',
    '50': 'Laming, S. R., Jenkins, S. R. & McCarthy, I. D. Repeatability of escape response performance in the queen scallop, Aequipecten opercularis. J. Exp. Biol. 216, 3264–3272 (2013).',
    '51': 'Li, X., Ma, L., Sun, L. & Zhu, C. Biotic characteristics in the deltamethrin-susceptible and resistant strains of Culex pipiens pallens (Diptera: Culicidae) in China. Appl. Entomol. Zool. 37, 305–308 (2002).',
    '53': 'Marsh, A. C. Microclimatic factors influencing foraging patterns and success of the thermophilic desert ant, Ocymyrmex barbiger. Insectes Sociaux 32, 286–296 (1985).',
    '54': 'McGinley, R. H., Prenter, J. & Taylor, P. W. Whole-organism performance in a jumping spider, Servaea incana (Araneae: Salticidae): links with morphology and between performance traits. Biol. J. Linn. Soc. 110, 644–657 (2013).',
    '56': 'Myhrvold, N. P. et al. An amniote life-history database to perform comparative analyses with birds, mammals, and reptiles. Ecology 96, 3109–3109 (2015).',
    '57': 'Nelson, M. K. & Formanowicz, D. R. Relationship between escape speed and flight distance in a wolf spider, Hogna carolinensis (walckenaer 1805). J. Arachnol. 33, 153–158 (2005).',
    '60': 'O\'Donnell, C. F. J. Home range and use of space by Chalinolobus tuberculatus, a temperate rainforest bat from New Zealand. J. Zool. 253, 253–264 (2001).',
    '61': 'O\'DOR, R. & Webber, D. M. Invertebrate athletes: trade-offs between transport efficiency and power density in cephalopod evolution. J. Exp. Biol. 160, 93–112 (1991).',
    '64': 'Pitnick, S., Markow, T. A. & Spicer, G. S. Delayed male maturity is a cost of producing large sperm in Drosophila. Proc. Natl. Acad. Sci. 92, 10614–10618 (1995).',
    '65': 'Prenter, J., Pérez-Staples, D. & Taylor, P. W. Functional relations between locomotor performance traits in spiders and implications for evolutionary hypotheses. BMC Res. Notes 3, 306 (2010).',
    '67': 'Roberts, M. J. & others. Spiders of Britain & Northern Europe. (HarperCollins Publishers, 1995).',
    '68': 'Rohr, J. J., Fish, F. E. & Gilpatrick, J. W. Maximum swim speeds of captive and free-ranging delphinids: Critical analysis of extraordinary performance. Mar. Mammal Sci. 18, 1–19 (2002).',
    '69': 'Rubin, S., Young, M. H.-Y., Wright, J. C., Whitaker, D. L. & Ahn, A. N. Exceptional running and turning performance in a mite. J. Exp. Biol. 219, 676–685 (2016).',
    '72': 'Saleuddin, A. S. M. & Wilbur, K. M. The Mollusca: Physiology. 5, (Academic Press, 2012).',
    '74': 'Spagna, J. C., Valdivia, E. A. & Mohan, V. Gait characteristics of two fast-running spider species (Hololena adnexa and Hololena curta), including an aerial phase (Araneae: Agelenidae). J. Arachnol. 39, 84–91 (2011).',
    '76': 'Ting, L. H., Blickhan, R. & Full, R. J. Dynamic and static stability in hexapedal runners. J. Exp. Biol. 197, 251–269 (1994).',
    '78': 'Tudorache, C., Viaene, P., Blust, R., Vereecken, H. & De Boeck, G. A comparison of swimming capacity and energy use in seven European freshwater fish species. Ecol. Freshw. Fish 17, 284–291 (2008).',
    '79': 'Uchiyama, J. H. & Boggs, C. H. Length-weight relationships of dolphinfish, Coryphaena hippurus, and wahoo, Acanthocybium solandri: seasonal effects of spawning and possible migration in the central North Pacific. Mar. Fish. Rev. 68, 19–29 (2006).',
    '80': 'Van Damme, R. & Vanhooydonck, B. Origins of interspecific variation in lizard sprint capacity. Funct. Ecol. 15, 186–202 (2001).',
    '82': 'Walters, V. & Fierstine, H. L. Measurements of swimming speeds of yellowfin tuna and wahoo. Biol. Sci. 2 (1964).',
    '83': 'Wehner, R., Fukushi, T. & Isler, K. On being small: brain allometry in ants. Brain. Behav. Evol. 69, 220–228 (2007).',
    '87': 'Wilson, D. S. Prudent Predation: A Field Study Involving Three Species of Tiger Beetles. Oikos 31, 128–136 (1978).',
    '89': 'Wu, G. C., Wright, J. C., Whitaker, D. L. & Ahn, A. N. Kinematic evidence for superfast locomotory muscle in two species of teneriffiid mites. J. Exp. Biol. 213, 2551–2556 (2010).',
    '90': 'Yin, M. C. & Blaxter, J. H. S. Escape speeds of marine fish larvae during early development and starvation. Mar. Biol. 96, 459–468 (1987).',
    '91': 'Gierak, R. 2013. "Euphausia superba" (On-line), Animal Diversity Web. http://animaldiversity.org/accounts/Euphausia_superba/',
    '92': 'Glyshaw, P. and E. Wason 2013. "Anopheles quadrimaculatus" (On-line), Animal Diversity Web. http://animaldiversity.org/accounts/Anopheles_quadrimaculatus/',
    '94': 'Thompson, B. 2001. "Anthonomus grandis" (On-line), Animal Diversity Web. http://animaldiversity.org/accounts/Anthonomus_grandis/',
    '95': 'Tung, L. 2003. "Makaira nigricans" (On-line), Animal Diversity Web. http://animaldiversity.org/accounts/Makaira_nigricans/',
    '101': 'www.speedofanimals.com',
}

# Website / non-peer-reviewed note
WEBSITE_KEYS = {'91', '92', '94', '95', '101'}

def normalize(s):
    s = unicodedata.normalize('NFD', s)
    s = ''.join(c for c in s if unicodedata.category(c) != 'Mn')
    return re.sub(r'[^a-z0-9 ]', ' ', s.lower()).strip()

def sim(a, b):
    return SequenceMatcher(None, normalize(a), normalize(b)).ratio()

def crossref_by_title(citation, cache):
    # Extract first author surname and year from citation
    m = re.match(r'^([A-Z][a-z]+)', citation)
    author = m.group(1) if m else ''
    m2 = re.search(r'\((\d{4})\)', citation)
    year = m2.group(1) if m2 else ''
    # Extract title-like fragment (between author and journal)
    title_match = re.search(r'\.\s+(.+?)\.\s+(?:[A-Z]|$)', citation)
    title = title_match.group(1) if title_match else citation[:80]

    key = f'title:{title[:80]}:{year}'
    if key in cache:
        return cache[key]
    params = {
        'query': f'{author} {year} {title[:60]}',
        'rows': '5',
        'mailto': CROSSREF_EMAIL,
        'select': 'DOI,title,published',
    }
    url = 'https://api.crossref.org/works?' + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url,
              headers={'User-Agent': f'TaxonBodyMass/1.0 (mailto:{CROSSREF_EMAIL})'})
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read())
    except Exception as e:
        print(f'  ERROR: {e}')
        cache[key] = None
        return None

    items = data.get('message', {}).get('items', [])
    for item in items:
        cr_title = ' '.join(item.get('title', []))
        title_s = sim(title, cr_title)
        if title_s < 0.80:
            continue
        pub = item.get('published', {})
        parts = pub.get('date-parts', [[]])
        pub_year = str(parts[0][0]) if parts and parts[0] else ''
        if year and pub_year and pub_year != year:
            continue
        doi = item.get('DOI', '').strip()
        if doi:
            cache[key] = doi
            return doi
    cache[key] = None
    return None


def main():
    # Read mass.ref keys that appear in the data
    with open(CSV_FILE, newline='', encoding='utf-8') as f:
        rows = list(csv.DictReader(f))
    used_keys = sorted(set(r['mass.ref'] for r in rows), key=lambda x: int(x))
    print(f'Data mass.ref keys: {len(used_keys)}')

    # Load cache
    cache = {}
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE) as f:
            cache = json.load(f)

    # Build references
    output = []
    for key in used_keys:
        citation = CITATIONS.get(key, f'[Reference {key} — not transcribed]')
        note = 'website' if key in WEBSITE_KEYS else ''
        doi = ''
        if key not in WEBSITE_KEYS and 'Princeton University Press' not in citation \
                and 'CRC Press' not in citation and 'Elsevier' not in citation \
                and 'Academic Press' not in citation and 'John Wiley' not in citation \
                and 'Oxford University Press' not in citation \
                and 'Rutgers University Press' not in citation \
                and 'British Wildlife' not in citation \
                and 'JHU Press' not in citation \
                and 'HarperCollins' not in citation \
                and 'University of Chicago Press' not in citation \
                and 'Lynx' not in citation \
                and 'Struik' not in citation \
                and 'SCAR and SCOR' not in citation:
            print(f'  [{key}] searching: {citation[:60]}')
            doi = crossref_by_title(citation, cache) or ''
            if doi:
                print(f'    -> {doi}')
            else:
                print(f'    -> not found')
            time.sleep(0.25)
        elif 'Princeton University Press' in citation or 'CRC Press' in citation \
                or 'Elsevier' in citation or 'Academic Press' in citation \
                or 'John Wiley' in citation or 'Oxford University Press' in citation \
                or 'Rutgers University Press' in citation or 'British Wildlife' in citation \
                or 'JHU Press' in citation or 'HarperCollins' in citation \
                or 'University of Chicago Press' in citation or 'Lynx' in citation \
                or 'Struik' in citation or 'SCAR and SCOR' in citation:
            note = 'book'

        output.append({'key': key, 'citation': citation, 'doi': doi, 'note': note})

    # Save cache
    with open(CACHE_FILE, 'w') as f:
        json.dump(cache, f, indent=2)

    # Write references.csv
    with open(REFS_OUT, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=['key', 'citation', 'doi', 'note'])
        w.writeheader()
        w.writerows(output)

    n_doi = sum(1 for r in output if r['doi'])
    print(f'\nDone: {len(output)} references, {n_doi} with DOI')


if __name__ == '__main__':
    main()
