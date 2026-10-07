# Recommendations for the open queue rows -- 2026-10-06 (tbmcite 0.1.0)

968 open row(s) in pending_citations.csv, 917 recomputed by the policy rules of recommend.r (README, section "Recommendations"); agent and owner rows kept.

- --recommend: Faurby_etal_2018: 277 open row(s), 10 with a recommendation, 267 left to the owner (owner_review_flagged 4, titleless_journal_key 263, titleless_incomplete 4, fields_complete_no_match 1, fields_incomplete 5)
- --recommend: Hebert_etal_2016: 10 open row(s), 10 with a recommendation, 0 left to the owner (grey_complete 4, fields_complete_no_match 6)
- --recommend: Jones_2009: 608 open row(s), 608 with a recommendation, 0 left to the owner (titleless_incomplete 1, jstor_twin 29, publisher_twin 66, strong_candidate 84, fields_complete_no_match 368, fields_incomplete 39, agent 21); 21 agent / owner row(s) kept (--force recomputes them)
- --recommend: Kiorboe_2013: 2 open row(s), 2 with a recommendation, 0 left to the owner (grey_complete 1, fields_complete_no_match 1)
- --recommend: Makarieva_2008: 22 open row(s), 15 with a recommendation, 7 left to the owner (agent 22); 22 agent / owner row(s) kept (--force recomputes them)
- --recommend: Meiri_2018: 23 open row(s), 23 with a recommendation, 0 left to the owner (strong_candidate 2, fields_complete_no_match 3, fields_incomplete 17, agent 1); 1 agent / owner row(s) kept (--force recomputes them)
- --recommend: Myhrvold_2015: 7 open row(s), 6 with a recommendation, 1 left to the owner (agent 7); 7 agent / owner row(s) kept (--force recomputes them)
- --recommend: Wilman_etal_2014: 19 open row(s), 19 with a recommendation, 0 left to the owner (titleless_incomplete 1, fields_complete_no_match 12, fields_incomplete 6)

## Rule x source

| rule | Faurby_etal_2018 | Hebert_etal_2016 | Jones_2009 | Kiorboe_2013 | Makarieva_2008 | Meiri_2018 | Myhrvold_2015 | Wilman_etal_2014 | total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| owner_review_flagged | 4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 4 |
| titleless_journal_key | 263 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 263 |
| titleless_incomplete | 4 | 0 | 1 | 0 | 0 | 0 | 0 | 1 | 6 |
| jstor_twin | 0 | 0 | 29 | 0 | 0 | 0 | 0 | 0 | 29 |
| publisher_twin | 0 | 0 | 66 | 0 | 0 | 0 | 0 | 0 | 66 |
| strong_candidate | 0 | 0 | 84 | 0 | 0 | 2 | 0 | 0 | 86 |
| grey_complete | 0 | 4 | 0 | 1 | 0 | 0 | 0 | 0 | 5 |
| fields_complete_no_match | 1 | 6 | 368 | 1 | 0 | 3 | 0 | 12 | 391 |
| fields_incomplete | 5 | 0 | 39 | 0 | 0 | 17 | 0 | 6 | 67 |
| agent | 0 | 0 | 21 | 0 | 22 | 1 | 7 | 0 | 51 |
