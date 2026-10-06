# Rizzuto et al. (2019) snowshoe hare body composition

Source: Rizzuto, M., Leroux, S. J., Vander Wal, E., Wiersma, Y. F., Heckford, T. R., & Balluffi-Fry, J. (2019) Patterns and potential drivers of intraspecific variability in the body C, N, and P composition of a terrestrial consumer, the snowshoe hare (*Lepus americanus*). Ecology and Evolution 9:14453-14464. https://doi.org/10.1002/ece3.5880 (CC BY 4.0). Bib key `Rizzuto:2019aa` (`Bib/TaxonBodyMass_Citations.bib`), CiteID `Rizzuto_2019`.
Data: the authors' figshare deposit https://doi.org/10.6084/m9.figshare.7884854 (v2, CC BY 4.0), downloaded 2026-10-05: `HH_MorphRawData.csv` (50 hares of Newfoundland, 2017-2018: whole-hare wet mass `Hare_Weight` in g, the wet and dry mass of the carcass homogenate sample `WeightFinalSample_A` / `SampleDryWeight_A`, morphometrics; the first row is a trial dissection labelled `Test_1`), `SSH_C_data.csv` (%C of dry mass, two replicates per hare) and the deposit's `README.md` (kept as `README_figshare.md`). The homogenate is the whole carcass without fur, skin and ears, with the cleaned digestive tract (paper, Methods).
Licence: CC BY 4.0 (README, README_figshare.md: the figshare record; https://doi.org/10.6084/m9.figshare.7884854). The two csv files and the deposit README are tracked; the ratios csv is ours.

`summarise_hares.py` computes per hare DW/WW = `SampleDryWeight_A` / `WeightFinalSample_A` and C/WW = mean %C / 100 x DW/WW and writes `rizzuto2019_hare_ratios.csv` (one row per hare and a `HARES_MEDIAN` row): DW/WW median 0.2925 (mean 0.2899, range 0.222-0.357, n = 50), C/WW median 0.1290. These supply the `mammal` row of `R/library/mass_conversion.r`, whose basis is therefore one species.

StoichLife (`Gonzalez_2025`) holds the same 50 hares: its `body.weight.gr` is `Hare_Weight` x the hare's own sample ratio (45 of 50 rows match to 0.05 g; the five hares with B and C replicate samples differ slightly), so the `mammal` factor restores the measured wet masses to within the spread of the individual ratios.

Not a body-mass source: no BodyMass_*.r script reads this folder.
