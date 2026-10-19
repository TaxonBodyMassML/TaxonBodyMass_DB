# Recommendations for the open queue rows -- 2026-10-19 (tbmcite 0.1.0)

531 open row(s) in pending_citations.csv, 531 recomputed by the policy rules of recommend.r (README, section "Recommendations"); agent and owner rows kept.

- --recommend: fishbase: 444 open row(s), 444 with a recommendation, 0 left to the owner (correction_notice 3, jstor_twin 1, publisher_twin 8, strong_candidate 57, openalex_only_candidate 10, grey_complete 1, fields_complete_no_match 151, fields_incomplete 213)
- --recommend: sealifebase: 87 open row(s), 87 with a recommendation, 0 left to the owner (jstor_twin 2, publisher_twin 2, strong_candidate 6, openalex_only_candidate 1, grey_complete 2, fields_complete_no_match 33, fields_incomplete 41)

## Rule x source

| rule | fishbase | sealifebase | total |
| --- | ---: | ---: | ---: |
| correction_notice | 3 | 0 | 3 |
| jstor_twin | 1 | 2 | 3 |
| publisher_twin | 8 | 2 | 10 |
| strong_candidate | 57 | 6 | 63 |
| openalex_only_candidate | 10 | 1 | 11 |
| grey_complete | 1 | 2 | 3 |
| fields_complete_no_match | 151 | 33 | 184 |
| fields_incomplete | 213 | 41 | 254 |
