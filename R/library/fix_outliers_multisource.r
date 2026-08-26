FixOutliersMultiSource <- function(dat) {

  # Multi-source mass corrections — taxa present in 2+ source databases.
  #
  # Each call to RemoveSource() sets mass_g to NA for the named source and
  # strips it from the source_mass string (handles both "-" and "; " separators
  # in leading, middle, and trailing positions).
  #
  # ---------------------------------------------------------------------------
  # Gadus_morhua — 11 sources
  #   DeLong_etal_2018, Hirt_etal_2017, Killen_etal_2016, Castro_2025,
  #   Brown_etal_2018,
  #   Makarieva_2008, Brose_etal_2018, Quaardvark, AnAge, Cai_etal_2025,
  #   DeLong_etal_2010
  #   DeLong_etal_2018=0.1367  Hirt_etal_2017=6.194  Killen_etal_2016=150
  #   Castro_2025=173.8
  #   Brown_etal_2018=2918  Makarieva_2008=6650  Brose_etal_2018=26343
  #   Quaardvark=40000
  #   AnAge=52800  Cai_etal_2025=87654  DeLong_etal_2010=1.500e+10
  #   [min=0.1367 g  max=1.500e+10 g  mean=1.364e+09 g]
  # DeLong_etal_2010/sd02.csv: body_mass_g = 1.50E+10; impossible (max Atlantic
  #   cod ~96 kg)
  dat <- RemoveSource(dat, "Gadus_morhua", "DeLong_etal_2010")

  # Cephalorhynchus_commersonii — 8 sources
  #   Brown_etal_2018, AnAge, Quaardvark, Cai_etal_2025, Faurby_etal_2018,
  #   Smith_2003,
  #   sealifebase, Tucker_etal_2014a
  #   Brown_etal_2018=12500  AnAge=50000  Quaardvark=50000  Cai_etal_2025=72400
  #   Faurby_etal_2018=72400  Smith_2003=72400  sealifebase=75339
  #   Tucker_etal_2014a=31622777
  #   [min=12500 g  max=31622777 g  mean=4003477 g]
  dat <- RemoveSource(dat, "Cephalorhynchus_commersonii", "Tucker_etal_2014a")

  # Hippoglossoides_platessoides — 5 sources
  #   Makarieva_2008, Brown_etal_2018, AnAge, Cai_etal_2025, DeLong_etal_2010
  #   Makarieva_2008=390  Brown_etal_2018=464.6  AnAge=3520  Cai_etal_2025=4542
  #   DeLong_etal_2010=277000000
  #   [min=390 g  max=277000000 g  mean=55401783 g]
  dat <- RemoveSource(dat, "Hippoglossoides_platessoides", "DeLong_etal_2010")

  # Leuciscus_leuciscus — 6 sources
  #   Makarieva_2008, Brose_etal_2018, Hirt_etal_2017, AnAge, fishbase,
  #   DeLong_etal_2010
  #   Makarieva_2008=9.95  Brose_etal_2018=13.16  Hirt_etal_2017=67.35
  #   AnAge=550  fishbase=1033
  #   DeLong_etal_2010=13800000
  #   [min=9.95 g  max=13800000 g  mean=2300279 g]
  dat <- RemoveSource(dat, "Leuciscus_leuciscus", "DeLong_etal_2010")

  # Varanus_exanthematicus — 6 sources
  #   Gillooly_etal_2016, Makarieva_2008, Feldman_etal_2016, Meiri_2018, AnAge,
  #   Quaardvark
  #   Gillooly_etal_2016=440  Makarieva_2008=3836  Feldman_etal_2016=9996
  #   Meiri_2018=9996
  #   AnAge=35500  Quaardvark=35500
  #   [min=440 g  max=35500 g  mean=15878 g]
  dat <- RemoveSource(dat, "Varanus_exanthematicus", "Gillooly_etal_2016")

  # Daphnia_magna — 4 sources
  #   Brown_etal_2018, DeLong_etal_2018, AndersonGillooly_2017, DeLong_etal_2010
  #   Brown_etal_2018=1.986e-04  DeLong_etal_2018=6.920e-04
  #   AndersonGillooly_2017=0.00181
  #   DeLong_etal_2010=0.9116
  #   [min=1.986e-04 g  max=0.9116 g  mean=0.2286 g]
  dat <- RemoveSource(dat, "Daphnia_magna", "DeLong_etal_2010")

  # Alburnus_alburnus — 5 sources
  #   Hirt_etal_2017, Makarieva_2008, fishbase, Cai_etal_2025, DeLong_etal_2010
  #   Hirt_etal_2017=1  Makarieva_2008=9  fishbase=100  Cai_etal_2025=178.9
  #   DeLong_etal_2010=6920000
  #   [min=1 g  max=6920000 g  mean=1384058 g]
  dat <- RemoveSource(dat, "Alburnus_alburnus", "DeLong_etal_2010")

  # Pimephales_promelas — 5 sources
  #   Makarieva_2008, Quaardvark, Brose_etal_2018, Cai_etal_2025,
  #   DeLong_etal_2010
  #   Makarieva_2008=2  Quaardvark=3.5  Brose_etal_2018=10.94
  #   Cai_etal_2025=13.5
  #   DeLong_etal_2010=1770000
  #   [min=2 g  max=1770000 g  mean=354006 g]
  dat <- RemoveSource(dat, "Pimephales_promelas", "DeLong_etal_2010")

  # Antarctomysis_maxima — 4 sources: Castro_2025, Makarieva_2008, Pata_2025,
  #   Brose_etal_2018
  #   Castro_2025=0.59  Makarieva_2008=0.721  Pata_2025=0.721
  #   Brose_etal_2018=13
  #   [min=0.59 g  max=13 g  mean=3.758 g]
  dat <- RemoveSource(dat, "Antarctomysis_maxima", "Brose_etal_2018")

  # Etheostoma_flabellare — 4 sources: Cai_etal_2025, Castro_2025, fishbase,
  #   DeLong_etal_2010
  #   Cai_etal_2025=1  Castro_2025=1.241  fishbase=4.09
  #   DeLong_etal_2010=1230000
  #   [min=1 g  max=1230000 g  mean=307502 g]
  dat <- RemoveSource(dat, "Etheostoma_flabellare", "DeLong_etal_2010")

  # Engraulis_japonicus — 4 sources: Brown_etal_2018, fishbase, Cai_etal_2025,
  #   Makarieva_2008
  #   Brown_etal_2018=9  fishbase=24.6  Cai_etal_2025=57.8  Makarieva_2008=628.8
  #   [min=9 g  max=628.8 g  mean=180 g]
  dat <- RemoveSource(dat, "Engraulis_japonicus", "Makarieva_2008")

  # Gobio_gobio — 4 sources: Makarieva_2008, Brose_etal_2018, Cai_etal_2025,
  #   DeLong_etal_2010
  #   Makarieva_2008=17  Brose_etal_2018=98.02  Cai_etal_2025=106.7
  #   DeLong_etal_2010=9230000
  #   [min=17 g  max=9230000 g  mean=2307555 g]
  dat <- RemoveSource(dat, "Gobio_gobio", "DeLong_etal_2010")

  # Gallotia_simonyi — 3 sources: Hirt_etal_2017, Feldman_etal_2016,
  #   Meiri_2018
  #   Hirt_etal_2017=230  Feldman_etal_2016=2672  Meiri_2018=2672
  #   [min=230 g  max=2672 g  mean=1858 g]
  dat <- RemoveSource(dat, "Gallotia_simonyi", "Hirt_etal_2017")

  # Chydorus_sphaericus — 3 sources: Brose_etal_2018, DeLong_etal_2018,
  #   DeLong_etal_2010
  #   Brose_etal_2018=2.180e-06  DeLong_etal_2018=2.360e-06  DeLong_etal_2010=30
  #   [min=2.180e-06 g  max=30 g  mean=10 g]
  dat <- RemoveSource(dat, "Chydorus_sphaericus", "DeLong_etal_2010")

  # Periphylla_periphylla — 2 sources: Brose_etal_2018, Pata_2025
  #   Brose_etal_2018=2.7  Pata_2025=22.57
  #   [min=2.7 g  max=22.57 g  mean=12.64 g]
  dat <- RemoveSource(dat, "Periphylla_periphylla", "Brose_etal_2018")

  # Shinisaurus_crocodilurus — 3 sources: Meiri_2018, Cai_etal_2025,
  #   Feldman_etal_2016
  #   Meiri_2018=83.04  Cai_etal_2025=1335  Feldman_etal_2016=1335
  #   [min=83.04 g  max=1335 g  mean=917.7 g]
  dat <- RemoveSource(dat, "Shinisaurus_crocodilurus", "Meiri_2018")

  # Chodsigoa_smithii — 3 sources: Faurby_etal_2018, Cai_etal_2025, Smith_2003
  #   Faurby_etal_2018=14.4  Cai_etal_2025=18.8  Smith_2003=379
  #   [min=14.4 g  max=379 g  mean=137.4 g]
  dat <- RemoveSource(dat, "Chodsigoa_smithii", "Faurby_etal_2018")

  # Triturus_vulgaris — 2 sources: Makarieva_2008, Brose_etal_2018
  #   Makarieva_2008=8.75  Brose_etal_2018=138.2
  #   [min=8.75 g  max=138.2 g  mean=73.48 g]
  dat <- RemoveSource(dat, "Triturus_vulgaris", "Brose_etal_2018")

  # Filinia_pejleri — 2 sources: Brown_etal_2018, DeLong_etal_2010
  #   Brown_etal_2018=1.250e-08  DeLong_etal_2010=0.25
  #   [min=1.250e-08 g  max=0.25 g  mean=0.125 g]
  dat <- RemoveSource(dat, "Filinia_pejleri", "DeLong_etal_2010")

  # Filinia_terminalis — 2 sources: Brown_etal_2018, DeLong_etal_2010
  #   Brown_etal_2018=1.250e-08  DeLong_etal_2010=0.25
  #   [min=1.250e-08 g  max=0.25 g  mean=0.125 g]
  dat <- RemoveSource(dat, "Filinia_terminalis", "DeLong_etal_2010")

  # Etheostoma_spectabile — 2 sources: Cai_etal_2025, DeLong_etal_2010
  #   Cai_etal_2025=0.4  DeLong_etal_2010=538000
  #   [min=0.4 g  max=538000 g  mean=269000 g]
  dat <- RemoveSource(dat, "Etheostoma_spectabile", "DeLong_etal_2010")

  # Ceriodaphnia_dubia — 2 sources: DeLong_etal_2018, DeLong_etal_2010
  #   DeLong_etal_2018=1.454e-05  DeLong_etal_2010=33.6
  #   [min=1.454e-05 g  max=33.6 g  mean=16.8 g]
  dat <- RemoveSource(dat, "Ceriodaphnia_dubia", "DeLong_etal_2010")

  # Menura_alberti — 2 sources: Lislevand_etal_2007, Wilman_etal_2014
  #   Lislevand_etal_2007=127  Wilman_etal_2014=928
  #   [min=127 g  max=928 g  mean=527.5 g]
  dat <- RemoveSource(dat, "Menura_alberti", "Lislevand_etal_2007")

  # Epinephelus_tauvina — 2 sources: Cai_etal_2025, fishbase
  #   Cai_etal_2025=17846  fishbase=265000
  #   [min=17846 g  max=265000 g  mean=141423 g]
  dat <- RemoveSource(dat, "Epinephelus_tauvina", "fishbase")

  # Tor_putitora — 2 sources: fishbase, Cai_etal_2025
  #   fishbase=63500  Cai_etal_2025=189570
  #   [min=63500 g  max=189570 g  mean=126535 g]
  dat <- RemoveSource(dat, "Tor_putitora", "fishbase")

  # Notonecta_glauca — 2 sources: DeLong_etal_2018, Brose_etal_2018
  #   DeLong_etal_2018=0.104  Brose_etal_2018=1.44
  #   [min=0.104 g  max=1.44 g  mean=0.7718 g]
  dat <- RemoveSource(dat, "Notonecta_glauca", "Brose_etal_2018")

  # Osmerus_eperlanus — 2 sources: fishbase, Cai_etal_2025
  #   fishbase=178  Cai_etal_2025=745.2
  #   [min=178 g  max=745.2 g  mean=461.6 g]
  dat <- RemoveSource(dat, "Osmerus_eperlanus", "Cai_etal_2025")

  # Squalius_cephalus — 2 sources: Brose_etal_2018, fishbase
  #   Brose_etal_2018=58.54  fishbase=6250
  #   [min=58.54 g  max=6250 g  mean=3154 g]
  dat <- RemoveSource(dat, "Squalius_cephalus", "Brose_etal_2018")

  # Cubiceps_whiteleggii — 2 sources: Cai_etal_2025, fishbase
  #   Cai_etal_2025=0.3  fishbase=1100
  #   [min=0.3 g  max=1100 g  mean=550.1 g]
  dat <- RemoveSource(dat, "Cubiceps_whiteleggii", "Cai_etal_2025")

  # Archosargus_rhomboidalis — 3 sources: DeLong_etal_2018, Mahe_2023,
  #   Brose_etal_2018
  #   DeLong_etal_2018=3.798e-05  Mahe_2023=173.1  Brose_etal_2018=1200
  #   [min=3.798e-05 g  max=1200 g  mean=457.7 g]
  dat <- RemoveSource(dat, "Archosargus_rhomboidalis", "DeLong_etal_2018")

  return(dat)
}
