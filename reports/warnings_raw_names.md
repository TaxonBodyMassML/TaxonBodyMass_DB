# TaxonBodyMass_DB Raw Name Report -- 2026-10-06 13:30:48

Every raw taxon name that `FixFormatting()` (`R/library/fix_formatting.r`) changed beyond blank -> underscore or that matched a rule of `audit/raw_name_patterns.csv`, grouped by the class of the rule that decided its fate and by source. Row counts are records in the cached frames before any later filter. A dropped record shows `(dropped)`; a `Genus_sp` or `Genus_cf` result is a marker that `RemoveNonTaxa()` removes.

## Summary

1,357 distinct raw names (60,066 rows) in 15 class(es). Names not covered by any rule (class `error`): 0.

| class | names | rows | records dropped | sources |
|---|---:|---:|---:|---|
| life_stage | 17 | 127 | 127 | Verberk_2020 (10), DeLong_etal_2010 (5), Hrycik_2024 (2) |
| placeholder | 731 | 38,903 | 0 | Brose_etal_2018 (271), Makarieva_2008 (98), Brose_2005 (93), Herberstein_etal_2022 (85), DeLong_etal_2010 (57), Kendall_etal_2019 (49), Baach_2026 (46), Hrycik_2024 (44), DeLong_etal_2018 (27), Raymond_2011 (26), Barnes_2008 (20), Brown_etal_2018 (19), Kinsella_etal_2020 (13), vertnet-traits-sept2016 (12), Eklof_etal_2017 (7), Hirt_etal_2017 (7), vertnet-aves-sept2016 (5), Castro_2025 (2), Chown_etal_2007 (2), Ehnes_etal_2011 (2), Killen_etal_2016 (2), McCoy_2008 (2), vertnet-fishes-sept2016 (2), vertnet-mammalia-sept2016 (2), Gillooly_etal_2016 (1), Hechinger_etal_2011 (1), Lane_2019 (1), Smith_2003 (1) |
| qualifier | 32 | 3,522 | 0 | Brose_etal_2018 (25), DeLong_etal_2018 (2), Makarieva_2008 (2), vertnet-aves-sept2016 (2), Vanni_2017 (1) |
| hybrid | 41 | 144 | 0 | vertnet-aves-sept2016 (27), vertnet-traits-sept2016 (14), Tsuboi_etal_2018 (2), vertnet-reptilia-sept2016 (1) |
| ambiguous | 32 | 387 | 0 | vertnet-aves-sept2016 (16), vertnet-traits-sept2016 (14), Hrycik_2024 (4), Brose_etal_2018 (3), DeLong_etal_2018 (3), Brown_etal_2018 (2) |
| subgenus | 18 | 39 | 0 | Makarieva_2008 (5), Verberk_2020 (5), vertnet-fishes-sept2016 (2), vertnet-mammalia-sept2016 (2), Brose_etal_2018 (1), Lemoine_2026 (1), Pata_2025 (1), vertnet-aves-sept2016 (1) |
| sex | 38 | 659 | 0 | Verberk_2020 (35), Brose_etal_2018 (1), DeLong_etal_2010 (1), Makarieva_2008 (1) |
| form_strain_region | 11 | 64 | 0 | DeLong_etal_2010 (3), Makarieva_2008 (3), Brose_2005 (2), Brose_etal_2018 (2), Verberk_2020 (2), Kiorboe_2014 (1) |
| size_class | 25 | 6,021 | 1,255 | Brose_etal_2018 (25) |
| species_group | 7 | 53 | 0 | Hrycik_2024 (5), Kendall_etal_2019 (2) |
| synonym | 10 | 35 | 0 | Makarieva_2008 (4), DeLong_etal_2018 (2), Verberk_2020 (2), vertnet-aves-sept2016 (2) |
| authority | 166 | 6,765 | 0 | Brose_2005 (164), Makarieva_2008 (2), Brose_etal_2018 (1) |
| trinomial | 164 | 2,833 | 0 | Cai_etal_2025 (41), Makarieva_2008 (34), Brose_etal_2018 (30), McCoy_2008 (14), Quaardvark (11), Hirt_etal_2017 (10), Lislevand_etal_2007 (8), Brose_2005 (7), Herberstein_etal_2022 (5), AndersonGillooly_2017 (2), Baach_2026 (2), Verberk_2020 (2), Brown_etal_2018 (1), Hrycik_2024 (1), Kendall_etal_2019 (1), sealifebase (1), Smith_2003 (1), Tucker_etal_2014b (1) |
| encoding | 2 | 101 | 0 | Brose_etal_2018 (1), Makarieva_2008 (1) |
| symbols | 63 | 413 | 0 | Makarieva_2008 (31), Mahe_2023 (15), Brose_etal_2018 (6), vertnet-traits-sept2016 (3), Hechinger_etal_2011 (2), Brose_2005 (1), DeLong_etal_2010 (1), Herberstein_etal_2022 (1), Kinsella_etal_2020 (1), Pekar_etal_2021 (1), Tucker_etal_2014b (1), vertnet-aves-sept2016 (1), vertnet-fishes-sept2016 (1), vertnet-mammalia-sept2016 (1) |

## life_stage (17 names, 127 rows)

A life-stage annotation (stage code, nauplius, copepodite, larva, megalops, juvenile, immature, egg, pupa, ...): the record is not an adult and is dropped through DropImputed() (scope rule of #8), one entry per source in audit/imputed_rows.csv.

By source: Verberk_2020 (10 names, 107 rows); Hrycik_2024 (2 names, 15 rows); DeLong_etal_2010 (5 names, 5 rows).

| raw name | result | classes | rows | source |
|---|---|---|---:|---|
| `Mirounga angustirostris Juveniles` | (dropped) | life_stage | 23 | Verberk_2020 |
| `Arctocephalus forsteri Juveniles` | (dropped) | life_stage | 21 | Verberk_2020 |
| `Phoca vitulina Juveniles` | (dropped) | life_stage | 21 | Verberk_2020 |
| `Callorhinus ursinus Juveniles Males` | (dropped) | life_stage | 19 | Verberk_2020 |
| `immature tubificid without hairs` | (dropped) | life_stage | 8 | Hrycik_2024 |
| `Arctocephalus galapagoensis Juveniles` | (dropped) | life_stage | 7 | Verberk_2020 |
| `immature tubificid with hairs` | (dropped) | life_stage | 7 | Hrycik_2024 |
| `Phoca hispida Juveniles` | (dropped) | life_stage | 7 | Verberk_2020 |
| `Neophoca cinerea Juveniles` | (dropped) | life_stage | 4 | Verberk_2020 |
| `Leptonichotes wedelli Juveniles` | (dropped) | life_stage | 3 | Verberk_2020 |
| `Brachyuran larvae (megalops)` | (dropped) | life_stage | 1 | DeLong_etal_2010 |
| `Calanus pacificus (II)` | (dropped) | life_stage | 1 | DeLong_etal_2010 |
| `Calanus pacificus (IV)` | (dropped) | life_stage | 1 | DeLong_etal_2010 |
| `Calanus pacificus (N1)` | (dropped) | life_stage | 1 | DeLong_etal_2010 |
| `Calanus pacificus (V)` | (dropped) | life_stage | 1 | DeLong_etal_2010 |
| `Erignathus barbatus Juveniles` | (dropped) | life_stage | 1 | Verberk_2020 |
| `Phoca sibirica Juveniles` | (dropped) | life_stage | 1 | Verberk_2020 |

## placeholder (731 names, 38,903 rows)

No species-level identification (sp., spp., spec., indet., ssp., undefinable, undetermined, morphospecies codes, 'species A', 'Unidentified'): the record leaves FixFormatting() as the marker Genus_sp (or Genus_spp, Genus_spec, Genus_indet, Genus_unk, Genus_type as written) and RemoveNonTaxa() removes it (the rules that renamed the six Brose_etal_2018 'Genus spec.' markers and 'Gomphonema type D' to bare genera, making genus-level records of them, were removed under #43).

By source: Brose_etal_2018 (271 names, 32,511 rows); Barnes_2008 (20 names, 2,601 rows); Brose_2005 (93 names, 2,491 rows); Kendall_etal_2019 (49 names, 300 rows); Eklof_etal_2017 (7 names, 194 rows); Makarieva_2008 (98 names, 144 rows); Herberstein_etal_2022 (85 names, 137 rows); Baach_2026 (46 names, 99 rows); Raymond_2011 (26 names, 98 rows); DeLong_etal_2010 (57 names, 62 rows); DeLong_etal_2018 (27 names, 61 rows); Hrycik_2024 (44 names, 54 rows); Ehnes_etal_2011 (2 names, 49 rows); Brown_etal_2018 (19 names, 19 rows); vertnet-traits-sept2016 (12 names, 18 rows); Kinsella_etal_2020 (13 names, 13 rows); Chown_etal_2007 (2 names, 11 rows); Hirt_etal_2017 (7 names, 9 rows); Castro_2025 (2 names, 7 rows); vertnet-aves-sept2016 (5 names, 6 rows); vertnet-fishes-sept2016 (2 names, 5 rows); Hechinger_etal_2011 (1 names, 3 rows); vertnet-mammalia-sept2016 (2 names, 3 rows); Killen_etal_2016 (2 names, 2 rows); Lane_2019 (1 names, 2 rows); McCoy_2008 (2 names, 2 rows); Gillooly_etal_2016 (1 names, 1 rows); Smith_2003 (1 names, 1 rows).

The 60 names with most records (of 897):

| raw name | result | classes | rows | source |
|---|---|---|---:|---|
| `Lithobius sp.` | `Lithobius_sp` | placeholder | 3,190 | Brose_etal_2018 |
| `Staphylinidae spec` | `Staphylinidae_spec` | placeholder | 2,396 | Brose_etal_2018 |
| `Geophilomorpha sp.` | `Geophilomorpha_sp` | placeholder | 1,883 | Brose_etal_2018 |
| `Lithobius sp2 {l}` | `Lithobius_sp` | placeholder | 1,850 | Brose_etal_2018 |
| `Campodea sp. {l}` | `Campodea_sp` | placeholder | 1,697 | Brose_etal_2018 |
| `Neobisium sp.` | `Neobisium_sp` | placeholder | 1,646 | Brose_etal_2018 |
| `Ammodytes sp.` | `Ammodytes_sp` | placeholder | 1,204 | Barnes_2008 |
| `Lithobius sp3 {m}` | `Lithobius_sp` | placeholder | 1,174 | Brose_etal_2018 |
| `Atheta sp.` | `Atheta_sp` | placeholder | 1,027 | Brose_etal_2018 |
| `Lithobius sp1 {s}` | `Lithobius_sp` | placeholder | 834 | Brose_etal_2018 |
| `Cantharidae sp.` | `Cantharidae_sp` | placeholder | 797 | Brose_etal_2018 |
| `Trichoniscus sp.` | `Trichoniscus_sp` | placeholder | 753 | Brose_etal_2018 |
| `Coleoptera sp.` | `Coleoptera_sp` | placeholder | 749 | Brose_etal_2018 |
| `Lithobius sp2 {s}` | `Lithobius_sp` | placeholder | 705 | Brose_etal_2018 |
| `Oncaea sp.` | `Oncaea_sp` | placeholder | 605 | Barnes_2008 |
| `Julidae sp.` | `Julidae_sp` | placeholder | 542 | Brose_etal_2018 |
| `Carabidae sp.` | `Carabidae_sp` | placeholder | 495 | Brose_etal_2018 |
| `Suctobelbella sp.` | `Suctobelbella_sp` | placeholder | 487 | Brose_etal_2018 |
| `Pterostichus sp.` | `Pterostichus_sp` | placeholder | 465 | Brose_etal_2018 |
| `Campodea sp. {m}` | `Campodea_sp` | placeholder | 449 | Brose_etal_2018 |
| `Oithona sp.` | `Oithona_sp` | placeholder | 396 | Barnes_2008 |
| `Protaphorura sp.` | `Protaphorura_sp` | placeholder | 308 | Brose_etal_2018 |
| `Scydmaenidae sp1 {m}` | `Scydmaenidae_sp` | placeholder | 266 | Brose_etal_2018 |
| `Acrotrichis sp.` | `Acrotrichis_sp` | placeholder | 260 | Brose_etal_2018 |
| `Scydmaenidae sp2` | `Scydmaenidae_sp` | placeholder | 257 | Brose_etal_2018 |
| `Sympetrum sp` | `Sympetrum_sp` | placeholder | 250 | Brose_etal_2018 |
| `Sympetrum sp` | `Sympetrum_sp` | placeholder | 250 | Brose_2005 |
| `Somatochlora sp` | `Somatochlora_sp` | placeholder | 236 | Brose_etal_2018 |
| `Somatochlora sp` | `Somatochlora_sp` | placeholder | 236 | Brose_2005 |
| `Glomeris sp.` | `Glomeris_sp` | placeholder | 233 | Brose_etal_2018 |
| `Cylisticus sp.` | `Cylisticus_sp` | placeholder | 229 | Brose_etal_2018 |
| `Brachychthoniidae spp.` | `Brachychthoniidae_spp` | placeholder | 228 | Brose_etal_2018 |
| `Polydesmidae sp.` | `Polydesmidae_sp` | placeholder | 217 | Brose_etal_2018 |
| `Lysigamasus sp.` | `Lysigamasus_sp` | placeholder | 211 | Brose_etal_2018 |
| `Harpalus sp.` | `Harpalus_sp` | placeholder | 210 | Brose_etal_2018 |
| `Abax sp.` | `Abax_sp` | placeholder | 199 | Brose_etal_2018 |
| `Trisopterus sp.` | `Trisopterus_sp` | placeholder | 189 | Barnes_2008 |
| `Elateridae sp.` | `Elateridae_sp` | placeholder | 181 | Brose_etal_2018 |
| `Caligus sp.` | `Caligus_sp` | placeholder | 179 | Brose_etal_2018 |
| `Asplanchna sp.` | `Asplanchna_sp` | placeholder | 178 | Brose_etal_2018 |
| `Brachyderinae sp.` | `Brachyderinae_sp` | placeholder | 174 | Brose_etal_2018 |
| `Lithobius sp1 {l}` | `Lithobius_sp` | placeholder | 170 | Brose_etal_2018 |
| `Tibellus sp` | `Tibellus_sp` | placeholder | 159 | Brose_etal_2018 |
| `Tibellus sp` | `Tibellus_sp` | placeholder | 159 | Brose_2005 |
| `Coenagrion sp` | `Coenagrion_sp` | placeholder | 150 | Brose_etal_2018 |
| `Coenagrion sp` | `Coenagrion_sp` | placeholder | 150 | Brose_2005 |
| `Nitidulidae sp.` | `Nitidulidae_sp` | placeholder | 132 | Brose_etal_2018 |
| `Oocyctis sp.` | `Oocyctis_sp` | placeholder | 129 | Brose_etal_2018 |
| `Curculionidae sp.` | `Curculionidae_sp` | placeholder | 128 | Brose_etal_2018 |
| `Tetramorium sp` | `Tetramorium_sp` | placeholder | 128 | Brose_etal_2018 |
| `Mallomonas sp.` | `Mallomonas_sp` | placeholder | 126 | Brose_etal_2018 |
| `Notiophilus sp.` | `Notiophilus_sp` | placeholder | 119 | Brose_etal_2018 |
| `Isotomidae sp.` | `Isotomidae_sp` | placeholder | 118 | Brose_etal_2018 |
| `Oligochaeta indet.` | `Oligochaeta_indet` | placeholder | 115 | Brose_etal_2018 |
| `Trechinae sp.` | `Trechinae_sp` | placeholder | 115 | Brose_etal_2018 |
| `Synchaeta sp.` | `Synchaeta_sp` | placeholder | 114 | Brose_etal_2018 |
| `Ptiliidae sp.` | `Ptiliidae_sp` | placeholder | 110 | Brose_etal_2018 |
| `Formica sp` | `Formica_sp` | placeholder | 109 | Brose_etal_2018 |
| `Formica sp` | `Formica_sp` | placeholder | 109 | Brose_2005 |
| `anthotoe spp.` | `Anthotoe_spp` | placeholder | 96 | Brose_etal_2018 |

## qualifier (32 names, 3,522 rows)

An identification qualifier before the epithet (cf., aff., nr.): the record leaves FixFormatting() as the marker Genus_cf (or Genus_nr, Genus_aff as written) and RemoveNonTaxa() removes it. A bare genus with its epithet in brackets (VertNet) folds to the binomial instead.

By source: Brose_etal_2018 (25 names, 3,510 rows); vertnet-aves-sept2016 (2 names, 7 rows); DeLong_etal_2018 (2 names, 2 rows); Makarieva_2008 (2 names, 2 rows); Vanni_2017 (1 names, 1 rows).

| raw name | result | classes | rows | source |
|---|---|---|---:|---|
| `Zercon cf gurensis` | `Zercon_cf` | qualifier | 853 | Brose_etal_2018 |
| `Scolopendrella cf. subnuda {s}` | `Scolopendrella_cf` | qualifier | 621 | Brose_etal_2018 |
| `Lysigamasus cf conus` | `Lysigamasus_cf` | qualifier | 470 | Brose_etal_2018 |
| `Scolopendrella cf. subnuda {m}` | `Scolopendrella_cf` | qualifier | 310 | Brose_etal_2018 |
| `Zercon cf peltatus` | `Zercon_cf` | qualifier | 174 | Brose_etal_2018 |
| `Leptogamasus cf. tectegynellus` | `Leptogamasus_cf` | qualifier | 119 | Brose_etal_2018 |
| `Pachylaelaps cf. vexillifer` | `Pachylaelaps_cf` | qualifier | 119 | Brose_etal_2018 |
| `Lysigamasus cf arcuatus` | `Lysigamasus_cf` | qualifier | 116 | Brose_etal_2018 |
| `Lysigamasus cf runcatellus` | `Lysigamasus_cf` | qualifier | 72 | Brose_etal_2018 |
| `Prozercon cf traeghardi` | `Prozercon_cf` | qualifier | 69 | Brose_etal_2018 |
| `Lithobius cf. mutabilis` | `Lithobius_cf` | qualifier | 58 | Brose_etal_2018 |
| `Lysigamasus cf wasmanni` | `Lysigamasus_cf` | qualifier | 57 | Brose_etal_2018 |
| `Macrocheles cf. opacus aciculatus` | `Macrocheles_cf` | qualifier | 57 | Brose_etal_2018 |
| `Zercon cf triangularis` | `Zercon_cf` | qualifier | 52 | Brose_etal_2018 |
| `Lysigamasus cf rostriforceps` | `Lysigamasus_cf` | qualifier | 51 | Brose_etal_2018 |
| `Epicrius cf. spinituberculatus` | `Epicrius_cf` | qualifier | 49 | Brose_etal_2018 |
| `Zercon cf romagniolus` | `Zercon_cf` | qualifier | 47 | Brose_etal_2018 |
| `Pseudachorutes cf dubius` | `Pseudachorutes_cf` | qualifier | 45 | Brose_etal_2018 |
| `Amblyseius cf. nemorivagus` | `Amblyseius_cf` | qualifier | 37 | Brose_etal_2018 |
| `Melogona cf. voigti` | `Melogona_cf` | qualifier | 37 | Brose_etal_2018 |
| `Cornodendrolaelaps cf cornutulus` | `Cornodendrolaelaps_cf` | qualifier | 27 | Brose_etal_2018 |
| `Entomobrya cf. multifasciata` | `Entomobrya_cf` | qualifier | 24 | Brose_etal_2018 |
| `Micranurida cf sensillata` | `Micranurida_cf` | qualifier | 18 | Brose_etal_2018 |
| `Ballistura cf. hankoi` | `Ballistura_cf` | qualifier | 14 | Brose_etal_2018 |
| `Phthiracarus cf crenophilus` | `Phthiracarus_cf` | qualifier | 14 | Brose_etal_2018 |
| `Empidonax [traillii]` | `Empidonax_traillii` | qualifier | 6 | vertnet-aves-sept2016 |
| `Arietellus cf.` | `Arietellus_cf` | qualifier | 1 | Makarieva_2008 |
| `Buteo (rufofuscus)` | `Buteo_rufofuscus` | qualifier | 1 | vertnet-aves-sept2016 |
| `Leporinus cf` | `Leporinus_cf` | qualifier | 1 | Vanni_2017 |
| `Procapritermes nr. sandakanensis` | `Procapritermes_nr` | qualifier | 1 | Makarieva_2008 |
| `Protoperidinium cf. divergens` | `Protoperidinium_cf` | qualifier | 1 | DeLong_etal_2018 |
| `Pseudobodo c.f. tremulans` | `Pseudobodo_cf` | qualifier | 1 | DeLong_etal_2018 |

## hybrid (41 names, 144 rows)

A hybrid or intergrade, two names joined by x, or the word hybrid in place of the epithet (a hybrid of unrecorded parentage): the record is credited to the first name written (the name is cut at the x or before the word; a genus alone before the cut gives a genus-level record), owner decision 2026-10-04 (#38) and the default of #48.

By source: vertnet-aves-sept2016 (27 names, 63 rows); vertnet-traits-sept2016 (14 names, 46 rows); Tsuboi_etal_2018 (2 names, 34 rows); vertnet-reptilia-sept2016 (1 names, 1 rows).

| raw name | result | classes | rows | source |
|---|---|---|---:|---|
| `Cebus nigritusXlibidinosus` | `Cebus_nigritus` | hybrid | 33 | Tsuboi_etal_2018 |
| `Icterus bullockii x galbula` | `Icterus_bullockii` | hybrid | 18 | vertnet-traits-sept2016 |
| `Tympanuchus phasianellus X cupido` | `Tympanuchus_phasianellus` | hybrid | 17 | vertnet-aves-sept2016 |
| `Geomys bursarius x lutescens` | `Geomys_bursarius` | hybrid | 12 | vertnet-traits-sept2016 |
| `Aechmophorus clarkii x occidentalis` | `Aechmophorus_clarkii` | hybrid | 9 | vertnet-aves-sept2016 |
| `Colaptes cafer X auratus` | `Colaptes_cafer` | hybrid | 4 | vertnet-aves-sept2016 |
| `Melanerpes aurifrons x hoffmannii ?` | `Melanerpes_aurifrons` | hybrid | 4 | vertnet-traits-sept2016 |
| `Anas platyrhynchos x rubripes` | `Anas_platyrhynchos` | hybrid | 3 | vertnet-aves-sept2016 |
| `Passer domesticus x hispaniolensis` | `Passer_domesticus` | hybrid | 3 | vertnet-aves-sept2016 |
| `Tympanuchus cupido X phasianellus` | `Tympanuchus_cupido` | hybrid | 3 | vertnet-aves-sept2016 |
| `Anas hybrid` | `Anas` | hybrid | 2 | vertnet-aves-sept2016 |
| `Melanerpes aurifrons x hoffmannii ?` | `Melanerpes_aurifrons` | hybrid | 2 | vertnet-aves-sept2016 |
| `Spermophilus-h richardsonii x elegans` | `Spermophilush_richardsonii` | hybrid | 2 | vertnet-traits-sept2016 |
| `Vermivora chrysoptera x pinus` | `Vermivora_chrysoptera` | hybrid | 2 | vertnet-aves-sept2016 |
| `Anas rubripes x platyrhynchos` | `Anas_rubripes` | hybrid | 1 | vertnet-traits-sept2016 |
| `Aythya baeri x novaeseelandia` | `Aythya_baeri` | hybrid | 1 | vertnet-aves-sept2016 |
| `Carduelis sinica x Serinus canaria` | `Carduelis_sinica` | hybrid | 1 | Tsuboi_etal_2018 |
| `Centrocercus X Tympanuchus urophasianus X phasianellus` | `Centrocercus` | hybrid | 1 | vertnet-aves-sept2016 |
| `Colinus virginianus x cristatus` | `Colinus_virginianus` | hybrid | 1 | vertnet-traits-sept2016 |
| `Corvus albus x ruficollis` | `Corvus_albus` | hybrid | 1 | vertnet-aves-sept2016 |
| `Dendroica hybrid` | `Dendroica` | hybrid | 1 | vertnet-aves-sept2016 |
| `Icterus galbula x bullockii` | `Icterus_galbula` | hybrid | 1 | vertnet-traits-sept2016 |
| `Lonchura cantans x striata` | `Lonchura_cantans` | hybrid | 1 | vertnet-traits-sept2016 |
| `Lonchura X Poephila cantans x guttata` | `Lonchura` | hybrid | 1 | vertnet-traits-sept2016 |
| `Loxia curvirostra x leucoptera` | `Loxia_curvirostra` | hybrid | 1 | vertnet-aves-sept2016 |
| `Melidectes belfordi x rufocrissalis` | `Melidectes_belfordi` | hybrid | 1 | vertnet-traits-sept2016 |
| `Melospiza hybrid` | `Melospiza` | hybrid | 1 | vertnet-aves-sept2016 |
| `Parus atricapillus x carolinensis` | `Parus_atricapillus` | hybrid | 1 | vertnet-aves-sept2016 |
| `Phasianus X Chrysolo colchicus` | `Phasianus` | hybrid | 1 | vertnet-traits-sept2016 |
| `Pheucticus ludovicianus x melan` | `Pheucticus_ludovicianus` | hybrid | 1 | vertnet-traits-sept2016 |
| `Pheucticus ludovicianus x melan` | `Pheucticus_ludovicianus` | hybrid | 1 | vertnet-aves-sept2016 |
| `Pheucticus ludovicianus X melanocephalus` | `Pheucticus_ludovicianus` | hybrid | 1 | vertnet-aves-sept2016 |
| `Ploceus castanops X ssp?` | `Ploceus_castanops` | hybrid | 1 | vertnet-aves-sept2016 |
| `Sphyrapicus nuchalis x ruber` | `Sphyrapicus_nuchalis` | hybrid | 1 | vertnet-aves-sept2016 |
| `Sphyrapicus ruber x varius` | `Sphyrapicus_ruber` | hybrid | 1 | vertnet-traits-sept2016 |
| `Sphyrapicus ruber x varius` | `Sphyrapicus_ruber` | hybrid | 1 | vertnet-aves-sept2016 |
| `Thamnophis atratus x hammondii` | `Thamnophis_atratus` | hybrid | 1 | vertnet-reptilia-sept2016 |
| `Tympanuchus cupido x phasianellus` | `Tympanuchus_cupido` | hybrid | 1 | vertnet-aves-sept2016 |
| `Uraeginthus bengalus x cyanocephalus` | `Uraeginthus_bengalus` | hybrid | 1 | vertnet-aves-sept2016 |
| `Vermivora hybrid` | `Vermivora` | hybrid | 1 | vertnet-aves-sept2016 |
| `Vermivora peregrina X ruficapilla` | `Vermivora_peregrina` | hybrid | 1 | vertnet-aves-sept2016 |
| `Vidua purpurascens x paradisaea` | `Vidua_purpurascens` | hybrid | 1 | vertnet-aves-sept2016 |
| `Zenaida aurita x galapagoens` | `Zenaida_aurita` | hybrid | 1 | vertnet-aves-sept2016 |
| `Zenaida galapagoensis x macr` | `Zenaida_galapagoensis` | hybrid | 1 | vertnet-traits-sept2016 |

## ambiguous (32 names, 387 rows)

Two or more alternative taxa in one name (joined by /, a comma, a semicolon or "and"): the record is credited to the first name written (the name is cut at the separator; an incomplete first fragment such as Lithobius_cyrt is left to the enrichment), owner decision 2026-10-04.

By source: Brose_etal_2018 (3 names, 136 rows); vertnet-aves-sept2016 (16 names, 122 rows); vertnet-traits-sept2016 (14 names, 118 rows); Hrycik_2024 (4 names, 6 rows); DeLong_etal_2018 (3 names, 3 rows); Brown_etal_2018 (2 names, 2 rows).

| raw name | result | classes | rows | source |
|---|---|---|---:|---|
| `Lithobius cyrt/mutabi` | `Lithobius_cyrt` | ambiguous | 80 | Brose_etal_2018 |
| `Pipilo maculatus,  ocai` | `Pipilo_maculatus` | ambiguous | 60 | vertnet-aves-sept2016 |
| `Fish eggs/larvae` | `Fish_eggs` | ambiguous | 54 | Brose_etal_2018 |
| `Pipilo maculatus,  ocai` | `Pipilo_maculatus` | ambiguous | 42 | vertnet-traits-sept2016 |
| `Larus glaucescens,  occidentalis` | `Larus_glaucescens` | ambiguous | 17 | vertnet-traits-sept2016 |
| `Junco caniceps,  oreganus` | `Junco_caniceps` | ambiguous | 13 | vertnet-traits-sept2016 |
| `Larus glaucescens,  occidentalis` | `Larus_glaucescens` | ambiguous | 13 | vertnet-aves-sept2016 |
| `Empidonax traillii/alnorum` | `Empidonax_traillii` | ambiguous | 11 | vertnet-aves-sept2016 |
| `Carduelis hornemanni,  flammea` | `Carduelis_hornemanni` | ambiguous | 9 | vertnet-traits-sept2016 |
| `Carduelis hornemanni,  flammea` | `Carduelis_hornemanni` | ambiguous | 9 | vertnet-aves-sept2016 |
| `Empidonax traillii/alnorum` | `Empidonax_traillii` | ambiguous | 9 | vertnet-traits-sept2016 |
| `Junco caniceps,  oreganus` | `Junco_caniceps` | ambiguous | 8 | vertnet-aves-sept2016 |
| `Leucosticte tephrocotis,  atrata` | `Leucosticte_tephrocotis` | ambiguous | 8 | vertnet-traits-sept2016 |
| `Leucosticte tephrocotis,  atrata` | `Leucosticte_tephrocotis` | ambiguous | 8 | vertnet-aves-sept2016 |
| `Sphyrapicus nuchalis,  ruber` | `Sphyrapicus_nuchalis` | ambiguous | 8 | vertnet-traits-sept2016 |
| `Baeolophus atricristatus,  bicolor` | `Baeolophus_atricristatus` | ambiguous | 3 | vertnet-traits-sept2016 |
| `Empidonax alnorum/traillii` | `Empidonax_alnorum` | ambiguous | 3 | vertnet-traits-sept2016 |
| `Musculium/Sphaerium` | `Musculium` | ambiguous | 3 | Hrycik_2024 |
| `Pheucticus melanocephalus,  ludovicianus` | `Pheucticus_melanocephalus` | ambiguous | 3 | vertnet-aves-sept2016 |
| `Diptera larvae/pupae` | `Diptera_larvae` | ambiguous | 2 | Brose_etal_2018 |
| `Neotoma bryanti,  lepida` | `Neotoma_bryanti` | ambiguous | 2 | vertnet-traits-sept2016 |
| `Vermivora pinus,  chrysoptera` | `Vermivora_pinus` | ambiguous | 2 | vertnet-aves-sept2016 |
| `Baeolophus atricristatus,  bicolor` | `Baeolophus_atricristatus` | ambiguous | 1 | vertnet-aves-sept2016 |
| `Coccinella septempunctata and Harpalus pennsylvanicus` | `Coccinella_septempunctata` | ambiguous | 1 | DeLong_etal_2018 |
| `Coccinella transversalis and Coccinella septempunctata` | `Coccinella_transversalis` | ambiguous | 1 | DeLong_etal_2018 |
| `Empidonax alnorum/traillii` | `Empidonax_alnorum` | ambiguous | 1 | vertnet-aves-sept2016 |
| `Empidonax difficilis/occidentalis` | `Empidonax_difficilis` | ambiguous | 1 | vertnet-aves-sept2016 |
| `Junco aikeni,  oreganus` | `Junco_aikeni` | ambiguous | 1 | vertnet-traits-sept2016 |
| `Junco aikeni,  oreganus` | `Junco_aikeni` | ambiguous | 1 | vertnet-aves-sept2016 |
| `Junco oreganus,  hyemalis` | `Junco_oreganus` | ambiguous | 1 | vertnet-traits-sept2016 |
| `Nais communis/variablis` | `Nais_communis` | ambiguous | 1 | Hrycik_2024 |
| `Pacific herring, Clupea palasi` | `Pacific_herring` | ambiguous | 1 | Brown_etal_2018 |
| `Petrochelidon; Hirundo fulva; rustica` | `Petrochelidon` | ambiguous | 1 | vertnet-aves-sept2016 |
| `Polioptila albiloris/nigriceps` | `Polioptila_albiloris` | ambiguous | 1 | vertnet-aves-sept2016 |
| `Potamothrix bedoti/bavaricus` | `Potamothrix_bedoti` | ambiguous | 1 | Hrycik_2024 |
| `Serinus, Carpodacus Carpodacus mexicanus` | `Serinus` | ambiguous | 1 | vertnet-traits-sept2016 |
| `Sitobion avenae, Metopolophium dirhodum` | `Sitobion_avenae` | ambiguous | 1 | DeLong_etal_2018 |
| `Skate, Raja orinacea` | `Skate` | ambiguous | 1 | Brown_etal_2018 |
| `Sphyrapicus nuchalis,  ruber` | `Sphyrapicus_nuchalis` | ambiguous | 1 | vertnet-aves-sept2016 |
| `Sylvia atricapilla/borin` | `Sylvia_atricapilla` | ambiguous | 1 | vertnet-aves-sept2016 |
| `Valvata sincera/piscinalis` | `Valvata_sincera` | ambiguous | 1 | Hrycik_2024 |
| `Vireo gilvus,  olivaceus` | `Vireo_gilvus` | ambiguous | 1 | vertnet-traits-sept2016 |

## subgenus (18 names, 39 rows)

A subgenus in brackets between the genus and the epithet, or the genus written twice, is removed; the binomial is kept.

By source: Brose_etal_2018 (1 names, 10 rows); Verberk_2020 (5 names, 10 rows); Lemoine_2026 (1 names, 6 rows); Makarieva_2008 (5 names, 5 rows); vertnet-fishes-sept2016 (2 names, 3 rows); vertnet-aves-sept2016 (1 names, 2 rows); vertnet-mammalia-sept2016 (2 names, 2 rows); Pata_2025 (1 names, 1 rows).

| raw name | result | classes | rows | source |
|---|---|---|---:|---|
| `Jaera (Jaera) albifrons` | `Jaera_albifrons` | subgenus | 10 | Brose_etal_2018 |
| `Clivina (Paraclivina) tuberculata` | `Clivina_tuberculata` | subgenus | 6 | Lemoine_2026 |
| `Podilymbus (Podiceps) podiceps` | `Podilymbus_podiceps` | subgenus | 5 | Verberk_2020 |
| `Falcipennis Falcipennis canadensis` | `Falcipennis_canadensis` | subgenus | 2 | vertnet-aves-sept2016 |
| `Noturus Noturus flavus` | `Noturus_flavus` | subgenus | 2 | vertnet-fishes-sept2016 |
| `Podilymbus (Podiceps) nigricollis` | `Podilymbus_nigricollis` | subgenus | 2 | Verberk_2020 |
| `Acanthamoeba (Hartmanella) castellani` | `Acanthamoeba_castellani` | subgenus | 1 | Makarieva_2008 |
| `Castor Castor canadensis` | `Castor_canadensis` | subgenus | 1 | vertnet-mammalia-sept2016 |
| `Crithida (Strigomonas) fasciculata` | `Crithida_fasciculata` | subgenus | 1 | Makarieva_2008 |
| `Crithidia (Strigomonas) oncopelti` | `Crithidia_oncopelti` | subgenus | 1 | Makarieva_2008 |
| `Hiodon Hiodon tergisus` | `Hiodon_tergisus` | subgenus | 1 | vertnet-fishes-sept2016 |
| `Leucocarbo (Phal.) carunculatus` | `Leucocarbo_carunculatus` | subgenus | 1 | Verberk_2020 |
| `Leucocarbo (Phal.) chalconotus` | `Leucocarbo_chalconotus` | subgenus | 1 | Verberk_2020 |
| `Podilymbus (Podiceps) ruficollis` | `Podilymbus_ruficollis` | subgenus | 1 | Verberk_2020 |
| `Spermophilus Spermophilus parryii` | `Spermophilus_parryii` | subgenus | 1 | vertnet-mammalia-sept2016 |
| `Tomopteris (Johnstonella) pacifica` | `Tomopteris_pacifica` | subgenus | 1 | Pata_2025 |
| `Trichomonas (Tritrichomonas) foetus` | `Trichomonas_foetus` | subgenus | 1 | Makarieva_2008 |
| `Trypanosoma (Schizotrypanum) cruzi` | `Trypanosoma_cruzi` | subgenus | 1 | Makarieva_2008 |

## sex (38 names, 659 rows)

A sex mark (F, M, female(s), male(s), the signs U+2640/U+2642) is removed; the record is kept as the species' value (owner decision, #37).

By source: Verberk_2020 (35 names, 402 rows); Brose_etal_2018 (1 names, 254 rows); Makarieva_2008 (1 names, 2 rows); DeLong_etal_2010 (1 names, 1 rows).

| raw name | result | classes | rows | source |
|---|---|---|---:|---|
| `Pergamasinae (male)` | `Pergamasinae` | sex | 254 | Brose_etal_2018 |
| `Mirounga leonina Females` | `Mirounga_leonina` | sex | 73 | Verberk_2020 |
| `Phocartos hookeri females` | `Phocartos_hookeri` | sex | 52 | Verberk_2020 |
| `Mirounga angustirostris Females` | `Mirounga_angustirostris` | sex | 33 | Verberk_2020 |
| `Arctocephalus gazella Female` | `Arctocephalus_gazella` | sex | 32 | Verberk_2020 |
| `Phoca vitulina Females` | `Phoca_vitulina` | sex | 27 | Verberk_2020 |
| `Arctocephalus tropicalis Females` | `Arctocephalus_tropicalis` | sex | 23 | Verberk_2020 |
| `Arctocephalus forsteri Female` | `Arctocephalus_forsteri` | sex | 18 | Verberk_2020 |
| `Arctocephalus pusillus Female` | `Arctocephalus_pusillus` | sex | 14 | Verberk_2020 |
| `Mirounga leonina Males` | `Mirounga_leonina` | sex | 12 | Verberk_2020 |
| `Phoca vitulina Males` | `Phoca_vitulina` | sex | 12 | Verberk_2020 |
| `Halichoerus grypus Females` | `Halichoerus_grypus` | sex | 11 | Verberk_2020 |
| `Phoca hispida Males` | `Phoca_hispida` | sex | 10 | Verberk_2020 |
| `Phocoena phocoena Females` | `Phocoena_phocoena` | sex | 10 | Verberk_2020 |
| `Physeter macrocephalus Males` | `Physeter_macrocephalus` | sex | 8 | Verberk_2020 |
| `Callorhinus ursinus females` | `Callorhinus_ursinus` | sex | 7 | Verberk_2020 |
| `Otaria flavescens Females` | `Otaria_flavescens` | sex | 7 | Verberk_2020 |
| `Mirounga angustirostris Males` | `Mirounga_angustirostris` | sex | 6 | Verberk_2020 |
| `Erignathus barbatus females` | `Erignathus_barbatus` | sex | 5 | Verberk_2020 |
| `Halichoerus grypus Males` | `Halichoerus_grypus` | sex | 5 | Verberk_2020 |
| `Leptonichotes wedelli Females` | `Leptonichotes_wedelli` | sex | 5 | Verberk_2020 |
| `Phoca hispida females` | `Phoca_hispida` | sex | 5 | Verberk_2020 |
| `Neophoca cinerea females` | `Neophoca_cinerea` | sex | 4 | Verberk_2020 |
| `Phoca sibirica females` | `Phoca_sibirica` | sex | 4 | Verberk_2020 |
| `Odobenus rosmarus Males` | `Odobenus_rosmarus` | sex | 3 | Verberk_2020 |
| `Phocoena phocoena Males` | `Phocoena_phocoena` | sex | 3 | Verberk_2020 |
| `Arctocephalus galapagoensis Females` | `Arctocephalus_galapagoensis` | sex | 2 | Verberk_2020 |
| `Orcinus orca Males` | `Orcinus_orca` | sex | 2 | Verberk_2020 |
| `Pagophilus groenlandica Females` | `Pagophilus_groenlandica` | sex | 2 | Verberk_2020 |
| `Tetrao urogallus ♀` | `Tetrao_urogallus` | sex | 2 | Makarieva_2008 |
| `Arctocephalus forsteri Male` | `Arctocephalus_forsteri` | sex | 1 | Verberk_2020 |
| `Arctocephalus gazella Male` | `Arctocephalus_gazella` | sex | 1 | Verberk_2020 |
| `Arctocephalus philippi Female` | `Arctocephalus_philippi` | sex | 1 | Verberk_2020 |
| `Arctocephalus pusillus Male` | `Arctocephalus_pusillus` | sex | 1 | Verberk_2020 |
| `Arctocephalus townsendi Female` | `Arctocephalus_townsendi` | sex | 1 | Verberk_2020 |
| `Calanus pacificus (F)` | `Calanus_pacificus` | sex | 1 | DeLong_etal_2010 |
| `Orcinus orca Females` | `Orcinus_orca` | sex | 1 | Verberk_2020 |
| `Physeter macrocephalus Females` | `Physeter_macrocephalus` | sex | 1 | Verberk_2020 |

## form_strain_region (11 names, 64 rows)

A form, strain, culture or population annotation is removed; the record is kept (a form written in place of the epithet, Conochilus_colonial, folds to the genus-level record Conochilus, #48).

By source: Makarieva_2008 (3 names, 19 rows); Brose_2005 (2 names, 18 rows); Brose_etal_2018 (2 names, 18 rows); Verberk_2020 (2 names, 4 rows); DeLong_etal_2010 (3 names, 3 rows); Kiorboe_2014 (1 names, 2 rows).

| raw name | result | classes | rows | source |
|---|---|---|---:|---|
| `Anacystis nidulans PCC (Synechococcus` | `Anacystis_nidulans` | synonym+form_strain_region | 11 | Makarieva_2008 |
| `Conochilus (solitary)` | `Conochilus` | form_strain_region | 11 | Brose_etal_2018 |
| `Conochilus (solitary)` | `Conochilus` | form_strain_region | 11 | Brose_2005 |
| `Conochilus (colonial)` | `Conochilus` | form_strain_region | 7 | Brose_etal_2018 |
| `Conochilus (colonial)` | `Conochilus` | form_strain_region | 7 | Brose_2005 |
| `Spirulina platensis 1968-3786` | `Spirulina_platensis` | form_strain_region | 4 | Makarieva_2008 |
| `Spirulina platensis P` | `Spirulina_platensis` | form_strain_region | 4 | Makarieva_2008 |
| `Ilybius chalconatus Bulgaria` | `Ilybius_chalconatus` | form_strain_region | 2 | Verberk_2020 |
| `Ilybius chalconatus Spain` | `Ilybius_chalconatus` | form_strain_region | 2 | Verberk_2020 |
| `Salpa maxima. Agg` | `Salpa_maxima` | form_strain_region | 2 | Kiorboe_2014 |
| `Mycoplasma pulmonis UAB CTIP` | `Mycoplasma_pulmonis` | form_strain_region | 1 | DeLong_etal_2010 |
| `Paraphysomonas imperforata (arctic)*` | `Paraphysomonas_imperforata` | form_strain_region+symbols | 1 | DeLong_etal_2010 |
| `Paraphysomonas imperforata (newfoundland)*` | `Paraphysomonas_imperforata` | form_strain_region+symbols | 1 | DeLong_etal_2010 |

## size_class (25 names, 6,021 rows)

A size-class tag of the Brose_etal_2018 soil food webs: {m}, {l}, {xl}, {xxl}, {xxxl}, medium and large are removed and the record kept; the small classes {xs}, {s} and small are non-adult records and are dropped through DropImputed() (owner decision 2026-10-04).

By source: Brose_etal_2018 (25 names, 6,021 rows).

| raw name | result | classes | rows | source |
|---|---|---|---:|---|
| `Trichoniscus pusillus {m}` | `Trichoniscus_pusillus` | size_class | 918 | Brose_etal_2018 |
| `Scutigerella immaculata {m}` | `Scutigerella_immaculata` | size_class | 692 | Brose_etal_2018 |
| `Harpactea lepida large` | `Harpactea_lepida` | size_class | 673 | Brose_etal_2018 |
| `Lithobius aeruginosus {l}` | `Lithobius_aeruginosus` | size_class | 655 | Brose_etal_2018 |
| `Lithobius curtipes {l}` | `Lithobius_curtipes` | size_class | 450 | Brose_etal_2018 |
| `Scutigerella immaculata {s}` | (dropped) | size_class | 438 | Brose_etal_2018 |
| `Lithobius curtipes {m}` | `Lithobius_curtipes` | size_class | 392 | Brose_etal_2018 |
| `Lithobius aeruginosus {m}` | `Lithobius_aeruginosus` | size_class | 388 | Brose_etal_2018 |
| `Trachytes pauperior{s}` | (dropped) | size_class | 369 | Brose_etal_2018 |
| `Allaiulus nitidus {xl}` | `Allaiulus_nitidus` | size_class | 236 | Brose_etal_2018 |
| `Harpactea lepida small` | (dropped) | size_class | 185 | Brose_etal_2018 |
| `Lithobius aeruginosus {s}` | (dropped) | size_class | 82 | Brose_etal_2018 |
| `Allaiulus nitidus {xxl}` | `Allaiulus_nitidus` | size_class | 80 | Brose_etal_2018 |
| `Trichoniscus pusillus {l}` | `Trichoniscus_pusillus` | size_class | 77 | Brose_etal_2018 |
| `Lithobius curtipes {s}` | (dropped) | size_class | 71 | Brose_etal_2018 |
| `Trichoniscus pusillus {s}` | (dropped) | size_class | 53 | Brose_etal_2018 |
| `Glomeris conspersa {xl}` | `Glomeris_conspersa` | size_class | 46 | Brose_etal_2018 |
| `Lumbricus rubellus {xxl}` | `Lumbricus_rubellus` | size_class | 45 | Brose_etal_2018 |
| `Salvelinus fontinalis large` | `Salvelinus_fontinalis` | size_class | 35 | Brose_etal_2018 |
| `Salvelinus fontinalis small` | (dropped) | size_class | 35 | Brose_etal_2018 |
| `Octolasion tyrtaeum{xxxl}` | `Octolasion_tyrtaeum` | size_class | 25 | Brose_etal_2018 |
| `Glomeris conspersa {l}` | `Glomeris_conspersa` | size_class | 23 | Brose_etal_2018 |
| `Octolasion tyrtaeum{xxl}` | `Octolasion_tyrtaeum` | size_class | 23 | Brose_etal_2018 |
| `Scutigerella immaculata {xs}` | (dropped) | size_class | 22 | Brose_etal_2018 |
| `Lumbricus rubellus {xl}` | `Lumbricus_rubellus` | size_class | 8 | Brose_etal_2018 |

## species_group (7 names, 53 rows)

A species group or aggregate marker after a binomial (group, grp, complex, agg., s.l.) is removed and the record credited to the nominal species written before it (owner decision 2026-10-04).

By source: Kendall_etal_2019 (2 names, 47 rows); Hrycik_2024 (5 names, 6 rows).

| raw name | result | classes | rows | source |
|---|---|---|---:|---|
| `Hylaeus modestus grp` | `Hylaeus_modestus` | species_group | 40 | Kendall_etal_2019 |
| `Lasioglossum tegulare grp` | `Lasioglossum_tegulare` | species_group | 7 | Kendall_etal_2019 |
| `Heterotrissocladius marcidus group` | `Heterotrissocladius_marcidus` | species_group | 2 | Hrycik_2024 |
| `Heterotrissocladius subpilosus group` | `Heterotrissocladius_subpilosus` | species_group | 1 | Hrycik_2024 |
| `Phaenopsectra obediens group` | `Phaenopsectra_obediens` | species_group | 1 | Hrycik_2024 |
| `Polypedilum halterale group` | `Polypedilum_halterale` | species_group | 1 | Hrycik_2024 |
| `Polypedilum scalaenum group` | `Polypedilum_scalaenum` | species_group | 1 | Hrycik_2024 |

## synonym (10 names, 35 rows)

An alternative name, epithet or common name in brackets after the binomial is removed.

By source: Verberk_2020 (2 names, 25 rows); Makarieva_2008 (4 names, 4 rows); DeLong_etal_2018 (2 names, 3 rows); vertnet-aves-sept2016 (2 names, 3 rows).

| raw name | result | classes | rows | source |
|---|---|---|---:|---|
| `Phalacrocorax capillatus - filamentosus` | `Phalacrocorax_capillatus` | synonym | 18 | Verberk_2020 |
| `Phalacrocorax brasilianus (previously olivaceus)` | `Phalacrocorax_brasilianus` | synonym | 7 | Verberk_2020 |
| `Euphonia musica(elegantissima)` | `Euphonia_musica` | synonym | 2 | vertnet-aves-sept2016 |
| `Tigrosa helluo (Hogna helluo)` | `Tigrosa_helluo` | synonym | 2 | DeLong_etal_2018 |
| `Anhinga rufa (anhinga)` | `Anhinga_rufa` | synonym | 1 | Makarieva_2008 |
| `Aspidoscelis sexlinata (Cnemidophorus sexlineatus)` | `Aspidoscelis_sexlinata` | synonym | 1 | DeLong_etal_2018 |
| `Eudocimus albus (Guara alba)` | `Eudocimus_albus` | synonym | 1 | Makarieva_2008 |
| `Eurostopodus argus (Eurostopodus` | `Eurostopodus_argus` | synonym | 1 | Makarieva_2008 |
| `Myadestes obscurus (occidentalis)` | `Myadestes_obscurus` | synonym | 1 | vertnet-aves-sept2016 |
| `Tetrahymena geleii (pyriformis)` | `Tetrahymena_geleii` | synonym | 1 | Makarieva_2008 |

## authority (166 names, 6,765 rows)

An author or author-and-year citation is removed.

By source: Brose_2005 (164 names, 6,750 rows); Brose_etal_2018 (1 names, 8 rows); Makarieva_2008 (2 names, 7 rows).

The 60 names with most records (of 167):

| raw name | result | classes | rows | source |
|---|---|---|---:|---|
| `Paederus riparius (L.)` | `Paederus_riparius` | authority | 260 | Brose_2005 |
| `Sympetrum vulgatum (L.)` | `Sympetrum_vulgatum` | authority | 199 | Brose_2005 |
| `Conocephalus dorsalis (Latr.)` | `Conocephalus_dorsalis` | authority | 191 | Brose_2005 |
| `Sympetrum sanguineum (Müller)` | `Sympetrum_sanguineum` | encoding+authority | 162 | Brose_2005 |
| `Chartoscirta cincta (Herrich-Schäffer)` | `Chartoscirta_cincta` | encoding+authority | 157 | Brose_2005 |
| `Pisaura mirabilis (Clerck, 1757)` | `Pisaura_mirabilis` | authority | 145 | Brose_2005 |
| `Somatochlora flavomaculata (Van der Linden)` | `Somatochlora_flavomaculata` | authority | 143 | Brose_2005 |
| `Robertus insignis O. P.-Cambridge, 1907` | `Robertus_insignis` | authority | 129 | Brose_2005 |
| `Larinioides cornutus (Clerck, 1757)` | `Larinioides_cornutus` | authority | 120 | Brose_2005 |
| `Tibellus maritimus (Menge, 1875)` | `Tibellus_maritimus` | authority | 112 | Brose_2005 |
| `Dolichopus nubilius Meigen, 1924` | `Dolichopus_nubilius` | authority | 108 | Brose_2005 |
| `Marpissa radiata (Grube, 1859)` | `Marpissa_radiata` | authority | 103 | Brose_2005 |
| `Edaphus blühweissi (Scheerp.)` | `Edaphus_bluhweissi` | encoding+authority | 100 | Brose_2005 |
| `Hebrus pusillus (Fallen)` | `Hebrus_pusillus` | authority | 96 | Brose_2005 |
| `Neoscona adianta (Walckenaer, 1802)` | `Neoscona_adianta` | authority | 95 | Brose_2005 |
| `Evarcha arcuata (Clerck, 1757)` | `Evarcha_arcuata` | authority | 94 | Brose_2005 |
| `Sympetrum striolatum (Charpentier)` | `Sympetrum_striolatum` | authority | 94 | Brose_2005 |
| `Dolomedes fimbriatus (Clerck, 1757)` | `Dolomedes_fimbriatus` | authority | 93 | Brose_2005 |
| `Lesteva sicula (Er.)` | `Lesteva_sicula` | authority | 90 | Brose_2005 |
| `Limnia paludicola (Elberg)` | `Limnia_paludicola` | authority | 86 | Brose_2005 |
| `Pirata piraticus (Clerck, 1757)` | `Pirata_piraticus` | authority | 85 | Brose_2005 |
| `Coenagrion pulchellum (Vander Linden)` | `Coenagrion_pulchellum` | authority | 80 | Brose_2005 |
| `Limnobaris dolorosa (Goeze, 1777)` | `Limnobaris_dolorosa` | authority | 79 | Brose_2005 |
| `Pirata tenuitarsis Simon, 1876` | `Pirata_tenuitarsis` | authority | 78 | Brose_2005 |
| `Antistea elegans (Blackwall, 1841)` | `Antistea_elegans` | authority | 70 | Brose_2005 |
| `Sepedon spinipes (Scopoli)` | `Sepedon_spinipes` | authority | 67 | Brose_2005 |
| `Euaesthetus ruficapillus (Boisd.)` | `Euaesthetus_ruficapillus` | authority | 66 | Brose_2005 |
| `Sitticus caricis (Westring, 1861)` | `Sitticus_caricis` | authority | 66 | Brose_2005 |
| `Gabrius fermoralis (Hochh.)` | `Gabrius_fermoralis` | authority | 64 | Brose_2005 |
| `Herina frondescentiae (L.)` | `Herina_frondescentiae` | authority | 64 | Brose_2005 |
| `Ischnura elegans (Vander Linden)` | `Ischnura_elegans` | authority | 64 | Brose_2005 |
| `Libellula quadrimaculata (L.)` | `Libellula_quadrimaculata` | authority | 64 | Brose_2005 |
| `Lathrobium fovalum (Steph.)` | `Lathrobium_fovalum` | authority | 63 | Brose_2005 |
| `Tetartopeus terminatum (Grav.)` | `Tetartopeus_terminatum` | authority | 60 | Brose_2005 |
| `Herina parva (Loew)` | `Herina_parva` | authority | 58 | Brose_2005 |
| `Ilione lineata (Fallén)` | `Ilione_lineata` | encoding+authority | 57 | Brose_2005 |
| `Swammerdamella brevicornis (Meigen, 1830)` | `Swammerdamella_brevicornis` | authority | 57 | Brose_2005 |
| `Theridion pictum (Walckenaer, 1802)` | `Theridion_pictum` | authority | 56 | Brose_2005 |
| `Ilione albiseta (Scopoli)` | `Ilione_albiseta` | authority | 55 | Brose_2005 |
| `Oxyloma elegans (Risso)` | `Oxyloma_elegans` | authority | 55 | Brose_2005 |
| `Pardosa prativaga (L. Koch, 1870)` | `Pardosa_prativaga` | authority | 52 | Brose_2005 |
| `Hercostomus assimilis (Staeger, 1842)` | `Hercostomus_assimilis` | authority | 50 | Brose_2005 |
| `Gnathonarium dentatum (Wider, 1834)` | `Gnathonarium_dentatum` | authority | 49 | Brose_2005 |
| `Myllaena dubia (Grav.)` | `Myllaena_dubia` | authority | 48 | Brose_2005 |
| `Theridion impressum L. Koch, 1881` | `Theridion_impressum` | authority | 48 | Brose_2005 |
| `Hebrus ruficeps (Thomson)` | `Hebrus_ruficeps` | authority | 47 | Brose_2005 |
| `Clubiona stagnatilis Kulczynski, 1897` | `Clubiona_stagnatilis` | authority | 46 | Brose_2005 |
| `Stalia boops (Schioedte)` | `Stalia_boops` | authority | 46 | Brose_2005 |
| `Cloeon simile (Eaton)` | `Cloeon_simile` | authority | 44 | Brose_2005 |
| `Tetragnatha extensa (L., 1758)` | `Tetragnatha_extensa` | authority | 43 | Brose_2005 |
| `Dolichopus nitidus Fallén, 1823` | `Dolichopus_nitidus` | encoding+authority | 42 | Brose_2005 |
| `Anelosimus vittatus (C. L. Koch, 1836)` | `Anelosimus_vittatus` | authority | 41 | Brose_2005 |
| `Pherbina coryleti (Fallén)` | `Pherbina_coryleti` | encoding+authority | 41 | Brose_2005 |
| `Trichia sericea (Draparnaud)` | `Trichia_sericea` | authority | 40 | Brose_2005 |
| `Vertigo antivertigo (Draparnaud)` | `Vertigo_antivertigo` | authority | 40 | Brose_2005 |
| `Dolichovespula sylvestris (Scopoli)` | `Dolichovespula_sylvestris` | authority | 39 | Brose_2005 |
| `Hemistenus flavipes (Steph.)` | `Hemistenus_flavipes` | authority | 39 | Brose_2005 |
| `Cicadella viridis (L.)` | `Cicadella_viridis` | authority | 38 | Brose_2005 |
| `Conocephalus discolor (Thunbg.)` | `Conocephalus_discolor` | authority | 38 | Brose_2005 |
| `Nestus mendicus (Er.)` | `Nestus_mendicus` | authority | 38 | Brose_2005 |

## trinomial (164 names, 2,833 rows)

A third, lowercase token (a subspecies or variety epithet, with or without a rank marker such as var. or ssp.) folds into the species.

By source: Brose_etal_2018 (30 names, 2,534 rows); Brose_2005 (7 names, 137 rows); Cai_etal_2025 (41 names, 41 rows); Makarieva_2008 (34 names, 34 rows); AndersonGillooly_2017 (2 names, 15 rows); McCoy_2008 (14 names, 15 rows); Hirt_etal_2017 (10 names, 11 rows); Quaardvark (11 names, 11 rows); Hrycik_2024 (1 names, 9 rows); Lislevand_etal_2007 (8 names, 8 rows); Herberstein_etal_2022 (5 names, 5 rows); Verberk_2020 (2 names, 4 rows); Kendall_etal_2019 (1 names, 3 rows); Baach_2026 (2 names, 2 rows); Brown_etal_2018 (1 names, 1 rows); sealifebase (1 names, 1 rows); Smith_2003 (1 names, 1 rows); Tucker_etal_2014b (1 names, 1 rows).

The 60 names with most records (of 172):

| raw name | result | classes | rows | source |
|---|---|---|---:|---|
| `root feeding nematodes` | `Root_feeding` | trinomial | 1,560 | Brose_etal_2018 |
| `Eunoe spica spicoides` | `Eunoe_spica` | trinomial | 249 | Brose_etal_2018 |
| `Navicula lanceolata phyllepta` | `Navicula_lanceolata` | trinomial | 89 | Brose_etal_2018 |
| `Thalassiosira gracilis expecta` | `Thalassiosira_gracilis` | trinomial | 81 | Brose_etal_2018 |
| `Porania antarctica glabra` | `Porania_antarctica` | trinomial | 72 | Brose_etal_2018 |
| `Limacina helicina antarctica` | `Limacina_helicina` | trinomial | 62 | Brose_etal_2018 |
| `Cyclops varians rubellus` | `Cyclops_varians` | trinomial | 43 | Brose_etal_2018 |
| `Cyclops varians rubellus` | `Cyclops_varians` | trinomial | 43 | Brose_2005 |
| `Tectocepheus velatus alatus` | `Tectocepheus_velatus` | trinomial | 42 | Brose_etal_2018 |
| `Frustulia rhomboides saxonica` | `Frustulia_rhomboides` | trinomial | 35 | Brose_etal_2018 |
| `Fragilaria capucina var. capucina` | `Fragilaria_capucina` | trinomial | 31 | Brose_etal_2018 |
| `Hyla arborea arborea` | `Hyla_arborea` | trinomial | 26 | Brose_etal_2018 |
| `Hyla arborea arborea` | `Hyla_arborea` | trinomial | 26 | Brose_2005 |
| `Diatoma hyemale quadratum` | `Diatoma_hyemale` | trinomial | 25 | Brose_etal_2018 |
| `Melanotaenia splendida splendida` | `Melanotaenia_splendida` | trinomial | 25 | Brose_2005 |
| `Rana temporaria temporaria` | `Rana_temporaria` | trinomial | 25 | Brose_etal_2018 |
| `Rana temporaria temporaria` | `Rana_temporaria` | trinomial | 25 | Brose_2005 |
| `Cocconeis placentula var. euglypta` | `Cocconeis_placentula` | trinomial | 24 | Brose_etal_2018 |
| `Tylosurus acus acus` | `Tylosurus_acus` | trinomial | 19 | Brose_etal_2018 |
| `Tectocepheus velatus sarekensis` | `Tectocepheus_velatus` | trinomial | 17 | Brose_etal_2018 |
| `Ekmocucumis turqueti turqueti` | `Ekmocucumis_turqueti` | trinomial | 16 | Brose_etal_2018 |
| `Platybelone argalus argalus` | `Platybelone_argalus` | trinomial | 15 | Brose_etal_2018 |
| `Tectocepheus velatus velatus` | `Tectocepheus_velatus` | trinomial | 15 | Brose_etal_2018 |
| `Lagopus lagopus scoticus` | `Lagopus_lagopus` | trinomial | 14 | AndersonGillooly_2017 |
| `Diplodus argenteus caudimacula` | `Diplodus_argenteus` | trinomial | 13 | Brose_etal_2018 |
| `Tylosurus crocodilus crocodilus` | `Tylosurus_crocodilus` | trinomial | 13 | Brose_etal_2018 |
| `Canis familiaris dingo` | `Canis_familiaris` | trinomial | 12 | Brose_2005 |
| `Pteraster affinis aculeatus` | `Pteraster_affinis` | trinomial | 12 | Brose_etal_2018 |
| `Perknaster fuscus antarcticus` | `Perknaster_fuscus` | trinomial | 10 | Brose_etal_2018 |
| `Dreissena rostriformis bugensis` | `Dreissena_rostriformis` | trinomial | 9 | Hrycik_2024 |
| `Achnanthes austriaca minor` | `Achnanthes_austriaca` | trinomial | 8 | Brose_etal_2018 |
| `Fragilaria capucina var. rumpens` | `Fragilaria_capucina` | trinomial | 8 | Brose_etal_2018 |
| `Cycethra verrucosa mawsoni` | `Cycethra_verrucosa` | trinomial | 7 | Brose_etal_2018 |
| `Cadulus dalli antarcticum` | `Cadulus_dalli` | trinomial | 6 | Brose_etal_2018 |
| `Frustulia rhomboides viridula` | `Frustulia_rhomboides` | trinomial | 5 | Brose_etal_2018 |
| `Perknaster fuscus antarcticus` | `Perknaster_fuscus` | trinomial | 5 | Brose_2005 |
| `Canis lupus arctos` | `Canis_lupus` | trinomial | 4 | Brose_etal_2018 |
| `Augochloropsis metallica fulgida` | `Augochloropsis_metallica` | trinomial | 3 | Kendall_etal_2019 |
| `Chrysemys picta bellii` | `Chrysemys_picta` | trinomial | 3 | Verberk_2020 |
| `Dendroica coronata sp.` | `Dendroica_coronata` | trinomial | 2 | McCoy_2008 |
| `Golfingia margaritacea margaritacea` | `Golfingia_margaritacea` | trinomial | 2 | Brose_etal_2018 |
| `Salmo trutta fario` | `Salmo_trutta` | trinomial | 2 | Hirt_etal_2017 |
| `Acanthiza pusilla apicalis` | `Acanthiza_pusilla` | trinomial | 1 | Lislevand_etal_2007 |
| `Acanthopagrus schlegelii schlegelii` | `Acanthopagrus_schlegelii` | trinomial | 1 | Makarieva_2008 |
| `Acanthopagrus_schlegelii_schlegelii` | `Acanthopagrus_schlegelii` | trinomial | 1 | Cai_etal_2025 |
| `Aethotaxis_mitopteryx_mitopteryx` | `Aethotaxis_mitopteryx` | trinomial | 1 | Cai_etal_2025 |
| `Anabarilius_liui_yalongensis` | `Anabarilius_liui` | trinomial | 1 | Cai_etal_2025 |
| `Anax parthenope julius` | `Anax_parthenope` | trinomial | 1 | Hirt_etal_2017 |
| `Anguilla australis australis` | `Anguilla_australis` | trinomial | 1 | Makarieva_2008 |
| `Anguilla_australis_australis` | `Anguilla_australis` | trinomial | 1 | Cai_etal_2025 |
| `Anguilla_bengalensis_labiata` | `Anguilla_bengalensis` | trinomial | 1 | Cai_etal_2025 |
| `Anguilla_bicolor_bicolor` | `Anguilla_bicolor` | trinomial | 1 | Cai_etal_2025 |
| `Aonyx capensis congica` | `Aonyx_capensis` | trinomial | 1 | Quaardvark |
| `Aphanius dispar dispar` | `Aphanius_dispar` | trinomial | 1 | Makarieva_2008 |
| `Aphyosemion_gabunense_marginatum` | `Aphyosemion_gabunense` | trinomial | 1 | Cai_etal_2025 |
| `Apis mellifera ligustica` | `Apis_mellifera` | trinomial | 1 | Baach_2026 |
| `Apis mellifera ligustica` | `Apis_mellifera` | trinomial | 1 | Makarieva_2008 |
| `Ardea intermedia intermedia` | `Ardea_intermedia` | trinomial | 1 | Herberstein_etal_2022 |
| `Auxis_rochei_rochei` | `Auxis_rochei` | trinomial | 1 | Cai_etal_2025 |
| `Basileuterus rufifrons delatri` | `Basileuterus_rufifrons` | trinomial | 1 | Lislevand_etal_2007 |

## encoding (2 names, 101 rows)

Non-ASCII characters: Latin-1 input converted to UTF-8, diacritics transliterated to their base letters, anything else removed.

By source: Brose_etal_2018 (1 names, 100 rows); Makarieva_2008 (1 names, 1 rows).

| raw name | result | classes | rows | source |
|---|---|---|---:|---|
| `Edaphus blŸhweissi` | `Edaphus_blYhweissi` | encoding | 100 | Brose_etal_2018 |
| `Nausithoë rubra` | `Nausithoe_rubra` | encoding | 1 | Makarieva_2008 |

## symbols (63 names, 413 rows)

Characters that cannot occur in a Latin name (punctuation, quotes, asterisks, question marks, hyphens, digits) removed.

By source: Brose_etal_2018 (6 names, 336 rows); Makarieva_2008 (31 names, 41 rows); Mahe_2023 (15 names, 15 rows); vertnet-traits-sept2016 (3 names, 5 rows); Hechinger_etal_2011 (2 names, 3 rows); vertnet-aves-sept2016 (1 names, 3 rows); Herberstein_etal_2022 (1 names, 2 rows); Pekar_etal_2021 (1 names, 2 rows); Brose_2005 (1 names, 1 rows); DeLong_etal_2010 (1 names, 1 rows); Kinsella_etal_2020 (1 names, 1 rows); Tucker_etal_2014b (1 names, 1 rows); vertnet-fishes-sept2016 (1 names, 1 rows); vertnet-mammalia-sept2016 (1 names, 1 rows).

The 60 names with most records (of 66):

| raw name | result | classes | rows | source |
|---|---|---|---:|---|
| `Pseudo-Nitzschia heimii` | `PseudoNitzschia_heimii` | symbols | 81 | Brose_etal_2018 |
| `Pseudo-Nitzschia liniola` | `PseudoNitzschia_liniola` | symbols | 81 | Brose_etal_2018 |
| `Pseudo-Nitzschia prolongatoides` | `PseudoNitzschia_prolongatoides` | symbols | 81 | Brose_etal_2018 |
| `Pseudo-Nitzschia subcurvata` | `PseudoNitzschia_subcurvata` | symbols | 81 | Brose_etal_2018 |
| `Anabaena flos-aquae` | `Anabaena_flosaquae` | symbols | 11 | Brose_etal_2018 |
| `Bacillus megate-` | `Bacillus_megate` | symbols | 4 | Makarieva_2008 |
| `Delftia acido-` | `Delftia_acido` | symbols | 4 | Makarieva_2008 |
| `Serratia mar-` | `Serratia_mar` | symbols | 4 | Makarieva_2008 |
| `Lampornis viridi-pallens` | `Lampornis_viridipallens` | symbols | 3 | vertnet-aves-sept2016 |
| `Seicercus ?` | `Seicercus` | symbols | 3 | vertnet-traits-sept2016 |
| `Nocardia coral-` | `Nocardia_coral` | symbols | 2 | Makarieva_2008 |
| `Quietula y-cauda` | `Quietula_ycauda` | symbols | 2 | Hechinger_etal_2011 |
| `Zygiella x-notata` | `Zygiella_xnotata` | symbols | 2 | Herberstein_etal_2022 |
| `Zygiella x-notata` | `Zygiella_xnotata` | symbols | 2 | Pekar_etal_2021 |
| `Alphestes afer*` | `Alphestes_afer` | symbols | 1 | Mahe_2023 |
| `Anabaena flos-aquae` | `Anabaena_flosaquae` | symbols | 1 | Makarieva_2008 |
| `Anoplolepis steinergroeveri*` | `Anoplolepis_steinergroeveri` | symbols | 1 | Makarieva_2008 |
| `Azomonas agi-` | `Azomonas_agi` | symbols | 1 | Makarieva_2008 |
| `Azomonas agilis?` | `Azomonas_agilis` | symbols | 1 | DeLong_etal_2010 |
| `Beneckea na-` | `Beneckea_na` | symbols | 1 | Makarieva_2008 |
| `Bodianus rufus*` | `Bodianus_rufus` | symbols | 1 | Mahe_2023 |
| `Brucella meliten-` | `Brucella_meliten` | symbols | 1 | Makarieva_2008 |
| `Camponotus maculatus*` | `Camponotus_maculatus` | symbols | 1 | Makarieva_2008 |
| `Cephalopholis cruentata*` | `Cephalopholis_cruentata` | symbols | 1 | Mahe_2023 |
| `Cephalopholis fulva*` | `Cephalopholis_fulva` | symbols | 1 | Mahe_2023 |
| `Cheilopogon xenopterus-group` | `Cheilopogon_xenopterusgroup` | symbols | 1 | vertnet-traits-sept2016 |
| `Cheilopogon xenopterus-group` | `Cheilopogon_xenopterusgroup` | symbols | 1 | vertnet-fishes-sept2016 |
| `Clepticus parrae*` | `Clepticus_parrae` | symbols | 1 | Mahe_2023 |
| `Daubentonia_madagascariensi
s` | `Daubentonia_madagascariensis` | symbols | 1 | Tucker_etal_2014b |
| `Dorylaimus stagnalis -` | `Dorylaimus_stagnalis` | symbols | 1 | Brose_2005 |
| `Epinephelus guttatus*` | `Epinephelus_guttatus` | symbols | 1 | Mahe_2023 |
| `Epinephelus striatus*` | `Epinephelus_striatus` | symbols | 1 | Mahe_2023 |
| `Euborellia annulipes*` | `Euborellia_annulipes` | symbols | 1 | Makarieva_2008 |
| `Eurycea pterophila?` | `Eurycea_pterophila` | symbols | 1 | Makarieva_2008 |
| `Francisella tula-` | `Francisella_tula` | symbols | 1 | Makarieva_2008 |
| `Halomonas halo-` | `Halomonas_halo` | symbols | 1 | Makarieva_2008 |
| `Holacanthus tricolor*` | `Holacanthus_tricolor` | symbols | 1 | Mahe_2023 |
| `Karoophasma biedouwensis*` | `Karoophasma_biedouwensis` | symbols | 1 | Makarieva_2008 |
| `Klebsiella pneu-` | `Klebsiella_pneu` | symbols | 1 | Makarieva_2008 |
| `Lachnolaimus maximus*` | `Lachnolaimus_maximus` | symbols | 1 | Mahe_2023 |
| `Messor capensis*` | `Messor_capensis` | symbols | 1 | Makarieva_2008 |
| `Methylobacte- extorquens` | `Methylobacte_extorquens` | symbols | 1 | Makarieva_2008 |
| `Molga torosa?` | `Molga_torosa` | symbols | 1 | Makarieva_2008 |
| `Moraxella oslo-` | `Moraxella_oslo` | symbols | 1 | Makarieva_2008 |
| `Myotis velifer /` | `Myotis_velifer` | symbols | 1 | vertnet-mammalia-sept2016 |
| `Neanthes "arenaceodentata"` | `Neanthes_arenaceodentata` | symbols | 1 | Hechinger_etal_2011 |
| `Neisseria elon-` | `Neisseria_elon` | symbols | 1 | Makarieva_2008 |
| `Neisseria gon-` | `Neisseria_gon` | symbols | 1 | Makarieva_2008 |
| `Neisseria mu-` | `Neisseria_mu` | symbols | 1 | Makarieva_2008 |
| `Nocardia far-` | `Nocardia_far` | symbols | 1 | Makarieva_2008 |
| `Non-Oribatida` | `NonOribatida` | symbols | 1 | Brose_etal_2018 |
| `Phrynosoma m'calli` | `Phrynosoma_mcalli` | symbols | 1 | Makarieva_2008 |
| `Pipilo erythrophthalmus-oca` | `Pipilo_erythrophthalmusoca` | symbols | 1 | vertnet-traits-sept2016 |
| `Proteus mor-` | `Proteus_mor` | symbols | 1 | Makarieva_2008 |
| `Scarus iseri*` | `Scarus_iseri` | symbols | 1 | Mahe_2023 |
| `Scarus taeniopterus*` | `Scarus_taeniopterus` | symbols | 1 | Mahe_2023 |
| `Scarus vetula*` | `Scarus_vetula` | symbols | 1 | Mahe_2023 |
| `Sparisoma aurofrenatum*` | `Sparisoma_aurofrenatum` | symbols | 1 | Mahe_2023 |
| `Sparisoma rubripinne*` | `Sparisoma_rubripinne` | symbols | 1 | Mahe_2023 |
| `Sparisoma viride*` | `Sparisoma_viride` | symbols | 1 | Mahe_2023 |
