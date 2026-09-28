# io_death_rates_extras.R
# Optional add-ons. Run AFTER io_death_rates.R in the same R session.
# 1. NEVDRS reconciliation: suicide by sector for 2020-2021 only, next to Can's 84 / 72 / 55.
# 2. Certificate-code cross-check: the certificate's own IndustryCode (Census code, trailing
#    digit dropped; OHIs subindicators.sas lines 87-91 and 392) rolled to a NAICS sector and
#    compared with the NIOCCS sector.
# 3. Review list: cases that are not coded, or overdose by text only, written to Cache.

# 1. NEVDRS reconciliation
recon <- rate_table("suicide", "ind_group", den_ind, yrs = 2020:2021) %>% filter(sex == "T") %>%
  select(group, deaths, rate) %>% mutate(nevdrs_sheet = c("Not in workforce" = 84, "23" = 72, "31-33" = 55)[group])
print(recon %>% filter(!is.na(nevdrs_sheet) | deaths > 0))
write_csv(recon, file.path(cfg$out_dir, "nevdrs_reconciliation_2020_2021.csv"), na = "")

# 2. Certificate-code cross-check (needs IndustryCode; add it to `fields` in the main script)
if ("IndustryCode" %in% names(cases)) {
  bands <- tribble(~lo, ~hi, ~sec, 170,290,"11", 370,490,"21", 570,690,"22", 770,770,"23", 1070,3990,"31-33", 4070,4590,"42",
    4670,5790,"44-45", 6070,6390,"48-49", 6470,6780,"51", 6870,6990,"52", 7070,7190,"53", 7270,7490,"54", 7570,7570,"55",
    7580,7790,"56", 7860,7890,"61", 7970,8470,"62", 8560,8590,"71", 8660,8690,"72", 8770,9290,"81", 9370,9590,"92")
  code4 <- suppressWarnings(as.numeric(cases$IndustryCode)) * 10
  cases$sector_cert <- sapply(code4, function(x) { h <- which(!is.na(x) & bands$lo <= x & x <= bands$hi); if (length(h)) bands$sec[h[1]] else NA })
  print(cases %>% filter(!ind_group %in% nonrate, !is.na(sector_cert)) %>%
          group_by(ind_group) %>% summarise(n = n(), agree_pct = round(100 * mean(ind_group == sector_cert), 1)))
}

# 3. Review list (record level: Cache only)
review <- cases %>% filter(ind_group == "Not coded" | occ_group == "Not coded" | overdose_text_only) %>%
  select(DeathCertificateId, year, all_of(outcomes$outcome), overdose_text_only, IndustryLit, OccupationLIt, NAICSCode, SOCCode, ind_group, occ_group)
write_csv(review, file.path(cfg$cache_dir, "review_list.csv"), na = "")
message(nrow(review), " cases on the review list")
