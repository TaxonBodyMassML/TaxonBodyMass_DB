#!/usr/bin/env python3
"""Build references.csv for Vanni_2017 from the 'Data source references' of
Metadata S1 (ecy1792-sup-0002-metadatas1.pdf, Wiley supplement of Vanni et al.
2017 Ecology 98:1475, doi 10.1002/ecy.1792; a publisher file kept locally and
not committed).

    pdftotext -layout ecy1792-sup-0002-metadatas1.pdf metadata_s1.txt
    python3 build_references.py metadata_s1.txt

The list runs from the heading 'Data source references' to 'Additional
references cited' (Literature cited, pp. 15-25 of the supplement). Entries
start at column 0; wrapped lines are indented; page numbers stand alone on a
line; a page break can leave the continuation of an entry at column 0 (four
cases, joined when the fragment starts in lower case). The 'Ikeda database' entry is one entry whose six
indented sub-references stay in its text.

Keys are the `Source name` values of Aquatic_animal_excretion_data.csv (90
distinct, the garbled 'B?mstedt & Tande 1985' read as 'Bamstedt & Tande
1985'), mapped to the entries by hand in KEY_MAP below; a key without an entry
(unpublished data of the data paper's coauthors, three papers the list does not
print) keeps the key as its citation with a note. Columns: key, citation, note.
"""
import csv, re, sys

txt = open(sys.argv[1], encoding='utf-8').read().split('\n')
start = next(i for i, l in enumerate(txt) if l.strip() == 'Data source references') + 1
end = next(i for i, l in enumerate(txt) if l.strip() == 'Additional references cited')
entries = []
cur = None
for ln in txt[start:end]:
    s = ln.rstrip()
    if not s.strip() or re.match(r'^\s*\d+\s*$', s):
        continue
    if s.startswith(' '):                       # wrapped or sub-entry line
        cur = (cur + ' ' + s.strip()) if cur else s.strip()
        continue
    frag = s.strip()
    # a page break can put the continuation at column 0: lower-case start, or
    # the open entry has no year in brackets yet (e.g. 'Munshaw ... nutrient')
    if cur is not None and frag[0].islower():
        cur = cur + ' ' + frag
        continue
    if cur:
        entries.append(cur)
    cur = frag
if cur:
    entries.append(cur)
entries = [re.sub(r'\s+', ' ', e).strip() for e in entries]

def find(prefix):
    hits = [e for e in entries if e.startswith(prefix)]
    if len(hits) != 1:
        sys.exit(f'{prefix!r}: {len(hits)} entries')
    return hits[0]

# Source name (key as the data cite it) -> prefix of the Metadata S1 entry, or
# None when the list has no entry for the key.
KEY_MAP = {
    'Alves et al 2010': 'Alves, JM, et al. (2010)',
    'Andersen 1989': 'Andersen, V (1989)',
    'Andre et al 2003': 'Andre ER, Hecky RE, Duthie HC (2003)',
    'Arnott & Vanni 1996': 'Arnott DL, Vanni MJ (1996)',
    'Bamstedt & Tande 1985': 'Bamstedt U, Tande KS (1985)',
    'Barlow & Bishop 1965': 'Barlow JP, Bishop JW (1965)',
    'Bayne & Scullard 1977': 'Bayne BL, Scullard C (1977)',
    'Benstead et al 2010': 'Benstead JP, et al. (2010)',
    'Brabrand et al 1990': 'Brabrand Å, Faafeng BA, Nilssen JPM (1990)',
    'Burkhardt & Lehman 1994': 'Burkhardt S, Lehman JT (1994)',
    'Capps & Flecker 2013': 'Capps KA, Flecker AS (2013)',
    'Christian et al 2008': 'Christian AD, Crump BG, Berg DJ (2008)',
    'Clarke et al 1994': 'Clarke A, Prothero-Thomas E, Whitehouse MJ (1994)',
    'Conroy et al 2005': 'Conroy JD, et al. (2005)',
    'Dalton, CM & AS Flecker, unpublished': None,
    'Devine & Vanni 2002': 'Devine JA, Vanni MJ (2002)',
    'Evans-White & Lamberti 2005': 'Evans-White MA, Lamberti GA (2005)',
    'Follum & Gray 1987': 'Follum OA, Gray JS (1987)',
    'Fukuhara & Yasuda 1985': 'Fukuhara H, Yasuda K (1985)',
    'Fukuhara & Yasuda 1985, 1989': None,
    'Gardner et al 1993': 'Gardner WS, Briones EE, Kaegi EC, Rowe GT (1993)',
    'Gauvin et al 1989': None,
    'Gido 2002': 'Gido KB (2002)',
    'Godinot & Chadwick 2009': 'Godinot C, Chadwick NE (2009)',
    'Gorsky et al 1987': 'Gorsky G, Palazzoli I, Fenaux R (1987)',
    'Gray 1985': 'Gray JS (1985)',
    'Haertel-Borer et al 2004': 'Haertel-Borer SS, Allen DM, Dame RF (2004)',
    'Hall et al 2003': 'Hall RO, Tank JL, Dybdahl MF (2003)',
    'Hall et al 2007': 'Hall RO, Koch BJ, Marshall MC, Taylor BW, Tronstad LM (2007)',
    'Henry & Santos 2008': 'Henry R, Santos CM (2008)',
    'Higgins et al 2006': 'Higgins KA, Vanni MJ, Gonzalez MJ (2006)',
    'Hood, JM unpub': None,
    'Ikeda database': 'Ikeda database (http://eprints.lib.hokudai.ac.jp/dspace/handle/2115/33838)',
    'James et al 2000': 'James WF, et al. (2000)',
    'James et al 2001': 'James MR, Weatherhead MA, Ross AH (2001)',
    'Jansen et al 2012': 'Jansen HM, Strand O, Verdegem M, Smaal A (2012)',
    'Ji et al 2011': 'Ji, L, et al. (2011)',
    'Johnson et al 2010': 'Johnson CR, Luecke C, Whalen SC, Evans MA (2010)',
    'Kiibus & Kautsky 1996': 'Kiibus M, Kautsky N (1996)',
    'Kouassi et al 2006': 'Kouassi E, Pagano M, Saint-Jean L, Sorbe JC (2006)',
    'Lamarra 1975': 'Lamarra VAJ (1975)',
    'Lauritsen & Mozley 1989': 'Lauritsen DD, Mozley SC (1989)',
    'Lessard-Pilon, S, PB McIntyre, AS Flecker & SA Thomas, unpubl': None,
    'Martin et al 2006': 'Martin S, et al. (2006)',
    'Mather et al 1995': 'Mather ME, Vanni MJ, Wissing TE, Davis SA, Schaus MH (1995)',
    'McIntyre 2006': 'McIntyre PB (2006)',
    'McIntyre et al 2008': 'McIntyre PB, et al. (2008)',
    'McIntyre, PB, unpub': None,
    'McManamay et al 2011': 'McManamay RA, Webster JR, Valett HM, Dolloff CA (2011)',
    'Mellina et al 1993': 'Mellina E, Rasmussen JB, Mills EL (1995)',
    'Meyer & Schultz 1983': 'Meyer JL, Schultz ET (1985)',
    'Milanovich & Hopton 2014, and unpubl': 'Milanovich JR, Hopton ME (2014)',
    'Milanovich, JR & JC Maerz, unpubl': 'Milanovich JR, et al. unpublished data.',
    'Morgan & Hicks 2013': 'Morgan DKJ, Hicks BJ (2013)',
    'Moslemi et al 2012': 'Moslemi JM, Snider SB, MacNeill K, Gilliam JF, Flecker AS (2012)',
    'Munshaw et al. 2013': 'Munshaw RG, Palen WJ, Courcelles DM, Finlay JC (2013)',
    'Naddafi et al 2008': 'Naddafi R, Pettersson K, Eklov P (2008)',
    'Nalepa et al 1991': None,
    'Paffenhofer & Gardner 1984': 'Paffenhofer GA, Gardner WS (1984)',
    'Pilati & Vanni 2007': 'Pilati A, Vanni MJ (2007)',
    'Post & Walters 2009': 'Post DM, Walters AW (2009)',
    'Prosch & McLachlan 1984': 'Prosch RM, McLachlan A (1984)',
    'Roopin et al 2008': 'Roopin M, Henry RP, Chadwick NE (2008)',
    'Rugenski 2013': 'Rugenski AT (2013)',
    'Schaus et al 1997': 'Schaus MH, et al. (1997)',
    'Schaus et al 2010': 'Schaus MH, et al. (2010)',
    'Schaus et al 2013': 'Schaus MH, et al. (2013)',
    'Sereda et al 2008': 'Sereda JM, Hudson JJ, Taylor WD, Demers E (2008)',
    'Shimauchi & Uye 2007': 'Shimauchi H, Uye S (2007)',
    'Shostell & Bukaveckas 2004': 'Shostell J, Bukaveckas PA (2004)',
    'Small et al 2011': 'Small GE, Pringle CM, Pyron M, Duff JH (2011)',
    'Solomon et al 2010': 'Solomon CT, Olden JD, Johnson PTJ, Dillon, RT Jr, Vander Zanden MJ (2010)',
    'Srna & Baggaley 1976': 'Srna RF, Baggaley A (1976)',
    'Sterrett et al 2015': 'Sterrett SC, Maerz JC, RA Katz (2015)',
    'Tarvainen et al 2005': 'Tarvainen M, Ventela AM, Helminen H, Sarvala J. (2005)',
    'Tatrai 1982': 'Tatrai I (1982)',
    'Taylor et al. 2012': 'Taylor JM, Back JA, Valenti TW, King RS (2012)',
    'Torres & Vanni 2007': 'Torres LE, Vanni MJ (2007)',
    'Turner 2010': 'Turner CB (2010)',
    'Urabe 1993': 'Urabe J (1993)',
    'Vanderploeg et al 1986': 'Vanderploeg HA, Laird GA, Liebig JR, Gardner WS (1986)',
    'Vanni et al 2002': 'Vanni MJ, Flecker AS, Hood JM, Headworth JL (2002)',
    'Vanni, MJ unpubl': None,
    'Vaughn et al 2004': 'Vaughn CC, Gido KB, Spooner DE (2004)',
    'Villeger et al 2012a': 'Villeger S, Ferraton F, Mouillot D, de Wit R (2012a)',
    'Villeger et al 2012b': 'Villeger S, Grenouillet G, Suc V, Brosse S (2012b)',
    'Whiles et al 2009': 'Whiles MR, Huryn AD, Taylor BW, Reeve JD (2009)',
    'Wilhelm et al 1999': 'Wilhelm, F.M., Hudson, J.J. & Schindler, D.W. (1999)',
    'Wilson & Xenopoulos 2010': 'Wilson HF, Xenopoulos MA (2011)',
    'Zimmer et al 2006': 'Zimmer KD, Herwig BR, Laurich LM (2006)',
}
NOTES = {
    'Dalton, CM & AS Flecker, unpublished': 'unpublished data of coauthors of the data paper (no entry in the Metadata S1 list)',
    'Hood, JM unpub': 'unpublished data of a coauthor of the data paper (no entry in the Metadata S1 list)',
    'Lessard-Pilon, S, PB McIntyre, AS Flecker & SA Thomas, unpubl': 'unpublished data of coauthors of the data paper (no entry in the Metadata S1 list)',
    'McIntyre, PB, unpub': 'unpublished data of the second compiler (no entry in the Metadata S1 list)',
    'Vanni, MJ unpubl': 'unpublished data of the first compiler (source numbers 83, 84 and 85 share this name; no entry in the Metadata S1 list)',
    'Fukuhara & Yasuda 1985, 1989': "key as the data cite it; the Metadata S1 list has Fukuhara & Yasuda (1985) and Fukuhara & Sakamoto (1987) and no 1989 entry; the rows (chironomid larvae) are not used",
    'Gauvin et al 1989': 'no entry in the Metadata S1 list (key as the data cite it)',
    'Nalepa et al 1991': 'no entry in the Metadata S1 list (key as the data cite it)',
    'Mellina et al 1993': "key year 1993 as the data cite it; the Metadata S1 entry is dated 1995",
    'Meyer & Schultz 1983': "key year 1983 as the data cite it; the Metadata S1 entry is dated 1985",
    'Wilson & Xenopoulos 2010': "key year 2010 as the data cite it; the Metadata S1 entry is dated 2011",
    'Milanovich & Hopton 2014, and unpubl': "the key also names unpublished data ('Milanovich JR, et al. unpublished data.' in the list)",
    'Milanovich, JR & JC Maerz, unpubl': "the list's entry 'Milanovich JR, et al. unpublished data.'",
    'Ikeda database': "T. Ikeda's database (Hokkaido University eprints handle 2115/33838); the entry lists the six Ikeda papers the database compiles; the same measurements underlie the Ikeda_2014 source of this database",
    'Hall et al 2007': 'book chapter (Cambridge University Press); raw data from R.O. Hall and B.J. Koch',
    'McIntyre 2006': 'PhD dissertation, Cornell University',
    'Rugenski 2013': 'PhD dissertation, Southern Illinois University',
}
rows = []
for key, prefix in KEY_MAP.items():
    citation = find(prefix) if prefix else key
    rows.append({'key': key, 'citation': citation, 'note': NOTES.get(key, '')})
used = {find(p) for p in KEY_MAP.values() if p}
unused = [e for e in entries if e not in used]
with open('references.csv', 'w', newline='', encoding='utf-8') as f:
    w = csv.DictWriter(f, fieldnames=['key', 'citation', 'note'], quoting=csv.QUOTE_ALL)
    w.writeheader(); w.writerows(rows)
print(f'{len(entries)} entries in the list, {len(rows)} keys written, {len(unused)} entries cited by no key:')
for e in unused: print('  ', e[:120])
