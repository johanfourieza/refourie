# P22_MEFK S6, step 1: copy of repro_r/01_clean.R (S3, commit c9224fd) with correction C1 as a switch.
# Run with argument "noC1" to switch C1 off (verification: must reproduce S3 exactly). Only edits vs S3 are marked "S6:".
C1 <- !("noC1" %in% commandArgs(TRUE)); tag <- if (C1) "c1" else "noc1"   # S6: switch
# Only the raw sheets are read. Sheets 1 and 4-10 (summary tables) are NOT used.
# Output: ./P22_MEFK/modern/_scratch/{companies,shareholders}_{c1,noc1}.rds
# All codings below (sex/entity, foreign, region, investor class, sector) are RE-CODINGS from the
# paper's verbal rules (pp.152-153, 161, 165-167); the authors' classified file does not survive.
suppressPackageStartupMessages({library(readxl); library(dplyr); library(tidyr); library(stringr); library(here)})
root <- here::here(); if (basename(root) != "Fourie_ReplicateMe") root <- normalizePath(file.path(root, ".."))
source(file.path(root, "tools", "paths.R"))
f <- dpath("P22_MEFK", "original", "Limited liability", "Shareholder Record.xlsx")

# ---- companies (Sheet2) ----
co <- read_excel(f, "Sheet2", col_types = "text") |>
  transmute(rec = str_remove_all(Record, "[[:space:]]"), co_name = Company_Name,
            found_year = suppressWarnings(as.integer(str_extract(Founding_Year, "\\d{4}"))),
            business = str_to_lower(Nature_of_Business)) |>
  filter(!is.na(rec)) |> distinct(rec, .keep_all = TRUE) |>
  mutate(sector = case_when(
    str_detect(business, "min(e|ing)|gold|diamond|copper|prospect|explor|mineral|coal|petroleum|\\btin\\b|asbestos") ~ "mining",
    str_detect(business, "bank|trust|insur|assur|building soc|financ|loan|invest|mortgage|discount|saving|exchange|deposit") ~ "financial",
    is.na(business) ~ NA_character_, TRUE ~ "other"))

# ---- shareholders (Sheet3; first row holds the real header) ----
sh <- read_excel(f, "Sheet3", col_types = "text", skip = 1, .name_repair = "minimal")
names(sh)[1:12] <- c("rec", "co_name3", "first", "second", "surname", "title", "gender", "lang", "addr", "bus", "nsh", "val")
sh <- sh[, 1:12] |> mutate(across(everything(), ~ na_if(str_squish(.x), "."))) |>
  mutate(rec = str_remove_all(rec, "[[:space:]]")) |>
  fill(rec, co_name3) |>   # company id is entered only on the first row of each block
  filter(!is.na(first) | !is.na(surname)) |>
  mutate(row_id = row_number(),
         val = suppressWarnings(as.numeric(val)),
         name = str_to_lower(str_squish(paste(coalesce(first, ""), coalesce(second, ""), coalesce(surname, "")))),
         key = str_remove_all(name, "[^a-z ]") |> str_squish(),
         sname = str_to_lower(str_remove_all(coalesce(surname, word(first, -1)), "[^A-Za-z]")),
         a = str_to_lower(coalesce(addr, "")),
         b = str_to_lower(coalesce(bus, "")),
         ttl = str_to_lower(coalesce(title, "")))

# ---- sex / entity ----
ent_rx <- "\\b(ltd|limited|company|co\\.?|corporation|bank|syndicate|trust|society|estate of|executors?|trustees?|messrs|association|brothers|bros)\\b|&"
sh <- sh |> mutate(
  entity = str_detect(name, ent_rx) | ttl == "messrs",
  sex = case_when(entity ~ "entity",
                  gender %in% c("Female") | ttl %in% c("mrs", "miss", "ms/mrs", "lady") ~ "female",
                  gender %in% c("Male", "M") | str_detect(ttl, "^(mr|dr|rev|sir|capt|col|hon|lord|major|lieut|lt|jnr|jr|sr)") ~ "male",
                  TRUE ~ NA_character_),
  african = lang %in% "Xhosa",
  dutch   = lang %in% "Dutch")

# ---- residence: foreign (outside Africa, p.154 "from outside Africa"), country, Transvaal, Cape region ----
uk  <- "london|england|e\\. ?c\\b|stock exchange|scotland|edinburgh|glasgow|dundee|liverpool|manchester|birmingham|ireland|dublin|belfast|wales|cardiff|bristol|leeds|sheffield|newcastle|brighton|\\bkent\\b|surrey|middlesex|yorkshire|lancashire|devon|hampshire|sussex|essex|bath\\b|oxford|cambridge|southampton|plymouth|nottingham|leicester|norwich|hull\\b|torquay|cheltenham|bournemouth|great britain|u\\.?k\\.?$"
nl  <- "holland|netherlands|amsterdam|rotterdam|hague|haag|utrecht|leiden|leyden|groningen|haarlem|arnhem"
de  <- "germany|hamburg|bremen|frankfurt|munich|m.nchen|cologne|k.ln|dresden|leipzig|stuttgart|prussia"
be  <- "belgium|brussels|bruxelles|antwerp|anvers|ghent|li.ge"
oth <- "france|paris|austria|vienna|wien|australia|melbourne|sydney|adelaide|queensland|victoria, aus|india|bombay|calcutta|madras|u\\.?s\\.?a|america|new york|chicago|boston|switzerland|geneva|zurich|italy|norway|sweden|denmark|canada|new zealand"
tvl <- "transvaal|johannesburg|pretoria|krugersdorp|barberton|potchefstroom|klerksdorp|boksburg|germiston|roodepoort|randfontein|heidelberg, t|middelburg, t|lydenburg|pilgrim|zeerust|rustenburg|z\\.?a\\.?r"
afr_other <- "bloemfontein|orange free state|o\\.?f\\.?s|natal|durban|pietermaritzburg|maritzburg|rhodesia|salisbury|bulawayo|harrismith|kroonstad|jagersfontein|fauresmith|ladybrand|basutoland|bechuanaland|beira"
north <- "kimberley|beaconsfield|barkly west|barkly-west|hope ?town|vryburg|mafeking|kenhardt|prieska|upington|carnarvon|namaqualand|springbok|o'?okiep|port nolloth|taungs|kuruman|griqualand|herbert|douglas|philipstown|britstown|victoria west|de aar|richmond|fraserburg|sutherland|williston|calvinia|warrenton|windsorton|klipdam|du ?toit'?s ?pan|bultfontein|barkley west|griquatown"
east <- "port elizabeth|east london|king william|graa?f+[- ]?reinet|queenstown|cathcart|uitenhage|grahamstown|cradock|tarkastad|tylden|whittlesea|adendorp|burghersdorp|aliwal|middelburg|somerset east|kei road|komgha|stutterheim|fort beaufort|alice|bedford|dordrecht|molteno|steynsburg|colesberg|humansdorp|alexandria|bathurst|port alfred|peddie|kingwilliamstown|thomas river|toise river|kabusie|sterkstroom|lady frere|indwe|\\bcala\\b|umtata|butterworth|transkei|elliot|barkly east|maclear|venterstad|hanover|jansenville|aberdeen|pearston|willowmore|murraysburg|steytlerville|kokstad|matatiele|engcobo|idutywa|tsomo|keiskama|bolotwa|cookhouse|seymour|adelaide|hogsback|berlin|frankfort|kei|middleburg|queen'?s ?town|naauwpoort|dohne|imvani|philadelphia|skerkstroom"
west <- "cape town|capetown|rondebosch|wynberg|claremont|sea point|woodstock|newlands|kenilworth|rosebank|mowbray|salt river|observatory|green point|muizenberg|kalk bay|simon'?s ?town|paarl|wellington|worcester|oudtsho|malmesbury|stellenbosch|robertson|somerset west|caledon|montagu|knysna|george|mossel bay|ceres|tulbagh|piquetberg|piketberg|riversdale|swellendam|beaufort west|ladismith|calitzdorp|uniondale|durbanville|klapmuts|klein drakenstein|drakenstein|franschhoek|goudini|hex river|de doorns|bredasdorp|hermanus|clanwilliam|moorreesburg|hopefield|darling|villiersdorp|prince albert|laingsburg|touws river|maitland|plumstead|diep river|retreat|bellville|kuils river|durban road|eerste river|sir lowry|strand|gordon'?s bay|elgin|grabouw|napier|stanford|porterville|riebeek|vredenburg|saldanha|st\\.? helena bay|nooitgedacht|de hoop|klipfontein|bethseda|broederstroom|brackenfell|constantia|tokai|camps bay|three anchor|matjiesfontein|faure|heidelberg c\\.? ?c|keeromstraat|cape tow|\\bstad\\b|cape police"
sh <- sh |> mutate(
  country = case_when(C1 & str_detect(a, "east london") ~ NA_character_,  # S6: correction C1
                      str_detect(a, uk) ~ "UK", str_detect(a, nl) ~ "Netherlands", str_detect(a, de) ~ "Germany",
                      str_detect(a, be) ~ "Belgium", str_detect(a, oth) & !str_detect(a, paste(west, east, north, sep = "|")) ~ "Other foreign",
                      TRUE ~ NA_character_),
  foreign = !is.na(country),
  london = foreign & str_detect(a, "london|e\\. ?c\\b|stock exchange"),
  transvaal = !foreign & str_detect(a, tvl),
  region = case_when(foreign ~ "Foreign", transvaal | str_detect(a, afr_other) ~ "Other Africa",
                     str_detect(a, north) ~ "North", str_detect(a, east) ~ "East", str_detect(a, west) ~ "West",
                     a == "" ~ NA_character_, TRUE ~ "Unassigned"))

# ---- investor class (re-coding of pp.152-153, 161; order matters) ----
cls_rx <- list(
  c("Farmers", "farmers", "farm|boer|agricultur|grazier|fruit grower|wine grower|stock breeder|ostrich"),
  c("Rentiers", "landowners", "land ?owner|landed proprietor|property owner|landlord"),
  c("Rentiers", "gentlemen", "gentlem[ae]n|esquire|^esq|retired|independent|annuitant|private means|^none$"),
  c("Middle class", "financiers", "broker|financier|banker|share ?dealer"),
  c("Businessmen", "capitalists", "capitalist|speculator"),
  c("Businessmen", "merchants", "merchant|importer|exporter|shipper|shipping"),
  c("Businessmen", "manufacturers", "manufactur|brewer|miller|distiller|tanner|maker of"),
  c("Businessmen", "contractors", "contractor|builder|constructor"),
  c("Middle class", "upper-middle", "attorney|solicitor|advocate|barrister|accountant|medical|doctor|physician|surgeon|dentist|architect|engineer|surveyor|minister|clergy|rev\\b|reverend|priest|missionary|magistrate|judge|journalist|editor|^mla$|m\\. ?l\\. ?a|parliament|manager|director|professor|veterinar|rector|chaplain|bishop|dean|notary|actuary"),
  c("Middle class", "lower-middle", "clerk|teacher|school ?master|schoolmistress|secretary|agent|student|civil servant|book ?keeper|salesman|traveller|inspector|police|messenger|warder|writer|collector|post ?master|telegraph|station ?master|railway|official|cashier|teller|interpreter|nurse|governess|organist|photographer|auctioneer|chemist|druggist|pharmac"),
  c("Businessmen", "general business", "dealer|trader|store ?keeper|shop ?keeper|hotel|innkeeper|grocer|butcher|baker|draper|jeweller|outfitter|ironmonger|tobacconist|wine and spirit|canteen|livery|stationer|bookseller|business|proprietor|commission|buyer|shipowner|clothier|hawker|undertaker|hairdresser"),
  c("Working class", "working class", "carpent|joiner|smith|fitter|painter|plumber|mason|brick|labou?rer|miner|digger|wagon ?maker|coach ?builder|couch ?builder|cooper|tailor|shoe ?maker|boot ?maker|saddler|printer|boiler ?maker|barman|store ?man|storehouse|overseer|mechanic|driver|dyer|servant|gardener|fisherman|boatman|sailor|seaman|plasterer|glazier|turner|moulder|compositor|porter|cook|waiter|watchmaker|upholsterer|engine")
)
sh <- sh |> mutate(cls = NA_character_, sub = NA_character_)
for (r in cls_rx) { hit <- is.na(sh$cls) & str_detect(sh$b, r[3]) & !(sh$b %in% c("", "?", "??", "???")); sh$cls[hit] <- r[1]; sh$sub[hit] <- r[2] }
# women (separate spheres): housewives, widows, spinsters, married ladies -> middle class "women"; occupation 'lady' -> rentiers 'ladies'
w <- str_detect(sh$b, "housewife|house wife|widow|spinster|married (lady|woman)|^wife") ; sh$cls[w] <- "Middle class"; sh$sub[w] <- "women"
l <- sh$b %in% c("lady", "ladies"); sh$cls[l] <- "Rentiers"; sh$sub[l] <- "ladies"
# formally employed women are counted in the middle-class 'women' subgroup too (p.161)
fw <- sh$sex %in% "female" & sh$cls %in% "Middle class"; sh$sub[fw] <- "women"
sh$cls[sh$entity] <- "Company investors"; sh$sub[sh$entity] <- "company"
sh$cls[is.na(sh$cls) & sh$b %in% c("", "?", "??", "???", "-", "unknown", "deceased")] <- "Information not available"
sh$cls[is.na(sh$cls)] <- "Unclassified occupation"

sh <- sh |> left_join(co |> select(rec, found_year, sector), by = "rec")
dir.create(dirname(dscratch("P22_MEFK", "modern", "x")), showWarnings = FALSE)
saveRDS(co, dscratch("P22_MEFK", "modern", paste0("companies_", tag, ".rds")))
saveRDS(sh, dscratch("P22_MEFK", "modern", paste0("shareholders_", tag, ".rds")))
# aggregate audit tables (no names) to the Dropbox output folder
out <- file.path(root, "P22_MEFK", "modern", "output", paste0("clean_", tag)); dir.create(out, showWarnings = FALSE, recursive = TRUE)  # S6
write.csv(count(sh, cls, sub), file.path(out, "class_counts.csv"), row.names = FALSE)
write.csv(count(sh, region), file.path(out, "region_counts.csv"), row.names = FALSE)
write.csv(sh |> filter(cls == "Unclassified occupation") |> count(b, sort = TRUE), file.path(out, "unclassified_occupations.csv"), row.names = FALSE)
write.csv(sh |> filter(region == "Unassigned") |> count(a, sort = TRUE) |> head(200), file.path(out, "unassigned_addresses_top200.csv"), row.names = FALSE)
cat("C1 =", C1, "| east london rows", sum(str_detect(sh$a, "east london")), "| "); cat("shareholder rows", nrow(sh), "| companies (Sheet2)", nrow(co), "\n")
