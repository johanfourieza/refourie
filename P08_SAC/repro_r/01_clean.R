# =============================================================================
# P08_SAC  S3 independent R recreation  --  01_clean.R
# Fourie, Grundlingh & Mariotti (2017) JICH 45(4): 580-606
#
# Input : SAC final.xlsx, sheet "Original" ONLY (raw attestation transcription)
# Output: ./P08_SAC/repro_r/_scratch/sac_terms.rds  (term level,
#         no names), sac_persons.rds (first term per person), and the occupation
#         dictionary output/hisco_dictionary.csv (occupation strings only).
# Rights: personal-class data. No names or individual rows are written to
#         output/. Names are used in memory only (to define service terms) and
#         surnames only to build the Dutch/Afrikaans surname flag; both are
#         dropped before anything is saved.
# =============================================================================

suppressMessages({
  library(tidyverse)
  library(readxl)
})

PROJ <- Sys.getenv("REPLICATEME_ROOT",
                   ".")
source(file.path(PROJ, "tools", "paths.R"))
OUT  <- file.path(PROJ, "P08_SAC", "repro_r", "output")
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
SCR  <- dscratch("P08_SAC", "repro_r")          # ./P08_SAC/repro_r/_scratch
XLSX <- dpath("P08_SAC", "original", "FourieSAC2026", "SAC final.xlsx")

raw <- read_excel(XLSX, sheet = "Original", col_types = "text")
stopifnot(nrow(raw) > 10000)

clean_txt <- function(x) {
  x <- trimws(gsub("\\s+", " ", x))
  x[x %in% c(".", "", "?", "-", ",")] <- NA
  x
}
num1 <- function(x) suppressWarnings(as.numeric(x))

# -----------------------------------------------------------------------------
# 1. Service terms and persons
#    A service term = a row carrying a name (first names or surname).
#    A person = a run of consecutive rows with the same value of `Unique`
#    (the transcribers' per-person counter, which restarts per source file).
#    Rows of the same person are ordered first term first in the sheet
#    (verified: row order == chronological order in 1,535/1,540 multi-term runs).
# -----------------------------------------------------------------------------
d <- raw %>%
  mutate(row_id = row_number()) %>%
  filter(!is.na(Names) | !is.na(Surname))

brk <- c(TRUE, d$Unique[-1] != d$Unique[-nrow(d)] |
               is.na(d$Unique[-1]) | is.na(d$Unique[-nrow(d)]))
d$person_id <- cumsum(brk)
d <- d %>% group_by(person_id) %>%
  mutate(term_no = row_number(), n_terms = n()) %>% ungroup()

# -----------------------------------------------------------------------------
# 2. Enlistment date
# -----------------------------------------------------------------------------
d <- d %>% mutate(
  enl_year  = num1(str_extract(Year, "^[0-9]{4}")),
  enl_year  = if_else(enl_year >= 1899 & enl_year <= 1910, enl_year, NA_real_),
  enl_month = num1(Month), enl_month = if_else(enl_month %in% 1:12, enl_month, NA_real_),
  enl_day   = num1(Day),   enl_day   = if_else(enl_day %in% 1:31, enl_day, NA_real_),
  enl_date  = suppressWarnings(as.Date(sprintf("%04d-%02d-%02d", enl_year, enl_month,
                                               coalesce(enl_day, 15)))),
  term_len_yrs = num1(`Enlisted years`)
)

# -----------------------------------------------------------------------------
# 3. Wage (shillings + pence/12; the sheet records "per day" although the paper
#    labels the unit "shillings per week")
# -----------------------------------------------------------------------------
parse_wage <- function(w) {
  w <- tolower(clean_txt(w))
  w <- gsub("sixpence|6 ?pence|6d", " 6d", w)
  w <- gsub("^six", "6", w)
  w <- gsub("3 pence", "3d", w)
  sh <- num1(str_match(w, "^([0-9]+)")[, 2])
  pe <- num1(str_match(w, "([0-9]+) ?d\\b")[, 2])
  out <- sh + coalesce(pe, 0) / 12
  out[is.na(sh)] <- NA
  out
}
d$wage <- parse_wage(d$Wage)

# -----------------------------------------------------------------------------
# 4. Height (cm), weight (kg), chest (inches), age (years)
# -----------------------------------------------------------------------------
parse_height <- function(h) {
  h <- tolower(clean_txt(h))
  h <- gsub("ft{1,2}|fr|fy|f\\b|t\\b", "ft", h)
  ft <- num1(str_match(h, "^([0-9](\\.0)?) ?ft")[, 2])
  rest <- str_trim(str_replace(h, "^[0-9](\\.0)? ?ft", ""))
  rest <- gsub("inch\\w*|in\\.?$|incb|lbs?", "", rest)
  rest <- gsub(",", ".", gsub("&", " ", rest))
  rest <- str_trim(rest)
  inch <- rep(NA_real_, length(h))
  # a b/c  or  a.b/c  (the latter = a + b/c, transcriber typo)
  m <- str_match(rest, "^([0-9]+)[ .]([0-9])/([0-9])$")
  ok <- !is.na(m[, 1]); inch[ok] <- num1(m[ok, 2]) + num1(m[ok, 3]) / num1(m[ok, 4])
  m <- str_match(rest, "^([0-9])/([0-9])$")
  ok2 <- !is.na(m[, 1]); inch[ok2] <- num1(m[ok2, 2]) / num1(m[ok2, 3])
  m <- str_match(rest, "^([0-9]+(\\.[0-9]+)?)$")
  ok3 <- !is.na(m[, 1]) & is.na(inch); inch[ok3] <- num1(m[ok3, 2])
  inch[rest == "" & !is.na(ft)] <- 0
  inch[!is.na(inch) & inch >= 12] <- NA     # e.g. "4.18" ambiguous -> NA if >=12
  cm <- (ft * 12 + inch) * 2.54
  cm[!is.na(cm) & (cm < 145 | cm > 205)] <- NA
  cm
}
parse_weight <- function(w) {
  w <- tolower(clean_txt(w))
  w <- gsub("s[rt]?\\b|ft\\b", "st", w)          # 10sr, 12s, 9ft (typos for st)
  w <- gsub("inch|lbs0|lbs00", "lbs", w)
  lb_only <- num1(str_match(w, "^([0-9.]+) ?lbs?$")[, 2])
  st <- num1(str_match(w, "^([0-9]+) ?st")[, 2])
  lb <- num1(str_match(w, "st ?([0-9.]+)")[, 2])
  lbs <- if_else(!is.na(st), st * 14 + coalesce(lb, 0), lb_only)
  kg <- lbs * 0.45359237
  kg[!is.na(kg) & (kg < 38 | kg > 120)] <- NA
  kg
}
parse_age <- function(a) {
  a <- tolower(clean_txt(a))
  y <- num1(str_match(a, "^([0-9]+(\\.[0-9]+)?)")[, 2])
  frac <- num1(str_match(a, "& ?([0-9]+)/12")[, 2]) / 12
  mos  <- num1(str_match(a, "([0-9.]+) ?(mos|mths|mo)")[, 2]) / 12
  qtr  <- if_else(grepl("1/4", a), 0.25, NA_real_)
  out <- y + coalesce(frac, mos, qtr, 0)
  out[!is.na(out) & (out < 14 | out > 65)] <- NA
  out
}
parse_dob <- function(x) {
  x <- clean_txt(x)
  m <- str_match(x, "^([0-9]{1,2})/([0-9]{1,2})/(1[89][0-9]{2})$")
  out <- suppressWarnings(as.Date(sprintf("%s-%02d-%02d", m[, 4], num1(m[, 3]), num1(m[, 2]))))
  mons <- c(jan=1,feb=2,mar=3,apr=4,may=5,jun=6,jul=7,aug=8,sep=9,oct=10,nov=11,dec=12)
  m2 <- str_match(tolower(x), "^([a-z]{3})[a-z.]* (1[89][0-9]{2})$")
  ok <- is.na(out) & !is.na(m2[, 1]) & m2[, 2] %in% names(mons)
  out[ok] <- as.Date(sprintf("%s-%02d-15", m2[ok, 3], mons[m2[ok, 2]]))
  m3 <- str_match(x, "^([0-9]{1,2})/(1[89][0-9]{2})$")
  ok <- is.na(out) & !is.na(m3[, 1]) & num1(m3[, 2]) %in% 1:12
  out[ok] <- as.Date(sprintf("%s-%02d-15", m3[ok, 3], num1(m3[ok, 2])))
  m4 <- str_match(x, "^(1[89][0-9]{2})$")
  ok <- is.na(out) & !is.na(m4[, 1])
  out[ok] <- as.Date(sprintf("%s-07-01", m4[ok, 2]))
  out
}

d <- d %>% mutate(
  height_cm = parse_height(Origheight),
  weight_kg = parse_weight(Weight),
  age_reported = parse_age(Age),
  dob = parse_dob(`Date of birth`),
  age_dob = as.numeric(enl_date - dob) / 365.25,
  age_dob = if_else(!is.na(age_dob) & age_dob >= 14 & age_dob <= 65, age_dob, NA_real_),
  age = coalesce(age_reported, age_dob),
  birth_year = coalesce(as.numeric(format(dob, "%Y")), enl_year - age_reported),
  chestmin = num1(gsub(",", ".", Chestmin)), chestmax = num1(gsub(",", ".", Chestmax)),
  chest1   = num1(gsub(",", ".", Chest)),
  chest = case_when(!is.na(chestmin) & !is.na(chestmax) ~ (chestmin + chestmax) / 2,
                    !is.na(chest1) ~ chest1,
                    TRUE ~ NA_real_),
  chest = if_else(!is.na(chest) & (chest < 25 | chest > 50), NA_real_, chest)
)

# -----------------------------------------------------------------------------
# 5. Marital status, religion
# -----------------------------------------------------------------------------
d <- d %>% mutate(
  ms = tolower(clean_txt(`Married or Single`)),
  married = case_when(is.na(ms) ~ NA_real_,
                      grepl("^married|separat", ms) ~ 1, TRUE ~ 0),
  rel = tolower(clean_txt(Religion)),
  rc = case_when(is.na(rel) ~ NA_real_,
                 grepl("roman catholic|^catholic$|^rc$|^r\\.c", rel) ~ 1, TRUE ~ 0)
)

# -----------------------------------------------------------------------------
# 6. Country / region of birth
# -----------------------------------------------------------------------------
std_country <- function(c, bp) {
  c <- tolower(trimws(gsub('"', "", c))); c[c %in% c(".", "")] <- NA
  bp <- tolower(trimws(bp)); bp[bp %in% c(".", "")] <- NA
  # fall back on birthplace only when country is missing
  bp_map <- case_when(
    grepl("dublin|waterford|cork|belfast", bp) ~ "ireland",
    grepl("cardiff|swansea", bp) ~ "wales",
    grepl("banff|edinburgh|glasgow|aberdeen", bp) ~ "scotland",
    grepl("grahamstown|c\\.c\\.|cape", bp) ~ "cape colony",
    grepl("japan", bp) ~ "japan",
    grepl("quebec|ontario", bp) ~ "canada",
    !is.na(bp) ~ "england",       # remaining birthplaces in that subset are English places
    TRUE ~ NA_character_)
  c <- coalesce(c, bp_map)
  case_when(
    c %in% c("england","london","isle of wight","surrey","devon","essex","middlesex",
             "staffordshire","new england","worcester","isle of man","jersey",
             "jersey, channel isl.","guernsey","channel islands") ~ "England",
    c %in% c("scotland","shetland island","scotch") ~ "Scotland",
    c %in% c("ireland","county galway","dublin, ireland","louth (?)") ~ "Ireland",
    c %in% c("wales","s. wales","n. wales","south wales","wale") ~ "Wales",
    c %in% c("canada","nova scotia","nova scotia, canada","vancouver") ~ "Canada",
    c %in% c("newfoundland") ~ "Newfoundland",
    c %in% c("usa","u.s.a.","united states","america","texas, usa","utah, usa",
             "usa (kansas)","u.s. of america") ~ "USA",
    c %in% c("south america","argentine republic","west indies","w. indies",
             "barbados","trinidad") ~ "Other Americas",
    c %in% c("australia","new south wales","n.s.wales","queensland","tasmania",
             "s. australia","south australia","australian") ~ "Australia",
    c %in% c("new zealand","new zeeland") ~ "New Zealand",
    c %in% c("india","bengal","bengal, india","anglo indian") ~ "India",
    c %in% c("ceylon","japan","china","asia minor","mauritius") ~ "Other Asia",
    c %in% c("germany","denmark","france","sweden","norway","russia","iceland",
             "gibraltar","malta","belgium","hungary","switzerland","turkey") ~ "Europe",
    c %in% c("transvaal","heidelberg","heidelberg (?)","lichtenburg","johannesburg",
             "potchefstroom, tvl.","standerton","zeerust","tvl, south africa") ~ "Transvaal",
    c %in% c("orange river colony","o.r.c.","orc","o.f.s.","ovs","orange free state",
             "free state","orange river") ~ "Orange Free State",
    c %in% c("burgher","burgher ?","dutchman") ~ "Boer republic (unspecified)",
    c %in% c("cape colony","cape colon","cape colonial","colonial","kimberley, c.c.",
             "griqualand west","griqualand east","griqualand","transkei") ~ "Cape Colony",
    c %in% c("natal","natal, south africa","durban, natal") ~ "Natal",
    c %in% c("south africa","sa","south african","africa") ~ "South Africa",
    c %in% c("rhodesia","matabeleland","swaziland","german sa") ~ "Other southern Africa",
    TRUE ~ NA_character_)
}
region_of <- function(cs) case_when(
  cs %in% c("England") ~ "England", cs == "Scotland" ~ "Scotland",
  cs == "Ireland" ~ "Ireland", cs == "Wales" ~ "Wales",
  cs %in% c("Canada","Newfoundland","USA","Other Americas") ~ "Americas",
  cs %in% c("Australia","New Zealand") ~ "Australasia",
  cs %in% c("India","Other Asia") ~ "Asia",
  cs == "Europe" ~ "Europe",
  cs %in% c("Transvaal","Orange Free State","Boer republic (unspecified)") ~ "Boer republics",
  cs %in% c("Cape Colony","Natal","South Africa","Other southern Africa") ~ "Southern Africa",
  TRUE ~ NA_character_)

d <- d %>% mutate(country_std = std_country(Country, Birthplace),
                  region = region_of(country_std))
unmapped_country <- d %>% filter(!is.na(Country), !trimws(Country) %in% c(".",""),
                                 is.na(country_std)) %>% count(Country)
if (nrow(unmapped_country)) { message("Unmapped countries:"); print(unmapped_country) }

# -----------------------------------------------------------------------------
# 7. Dutch/Afrikaans surname flag (paper fn 18: surname classification)
#    Rule: Dutch/Afrikaans particle prefix, Dutch orthography (ij, -wyk/-dyk),
#    or membership of a generic list of common Afrikaner surnames written from
#    general knowledge (not derived row by row). German-, English- and
#    Scandinavian-origin names are not counted as Boer surnames.
# -----------------------------------------------------------------------------
afr_list <- c("adendorff","alberts","badenhorst","barnard","basson","beetge","bekker",
  "bester","beukes","bezuidenhout","blaauw","bodenstein","booysen","bornman","boshoff",
  "bosman","botes","botha","bouwer","breytenbach","brits","brummer","burger","buys",
  "celliers","cilliers","claasen","cloete","coetzee","coetzer","conradie","cronje",
  "delport","dippenaar","dorfling","dreyer","eksteen","eloff","els","engelbrecht",
  "erasmus","esterhuizen","eybers","ferreira","ferriera","fick","fouche","fourie",
  "furstenburg","geldenhuys","geyer","geyser","goosen","gouws","graaff","greyling",
  "griesel","griezel","grimbeek","grobler","groenewald","hancke","hanekom","harmse",
  "hatting","hattingh","havenga","herbst","heyns","hofmeyr","hugo","human","jacobs",
  "jansen","janse","jooste","jordaan","joubert","kamfer","kempen","kleynhans","kok",
  "kotze","kriel","krige","kruger","labuschagne","lategan","laubscher","liebenberg",
  "lindique","loggenberg","lombard","lotter","lourens","louw","lowies","ludick","malan",
  "malherbe","marais","mare","maritz","matthee","meintjes","meyer","minnaar","mocke",
  "moolman","mostert","mouton","myburgh","naude","neethling","nel","nell","niemand",
  "nieuwoudt","nortje","oberholzer","odendaal","oelofse","olivier","oosthuizen",
  "oppermann","opperman","pelser","petzer","pienaar","pieters","pieterse","pistorius",
  "potgieter","pretorius","prinsloo","putter","raath","rabe","rabie","rademeyer",
  "raubenheimer","rautenbach","redelinghuis","redelinghuys","retief","reyneke",
  "robbertze","robertze","roets","roos","rossouw","roux","scheepers","schoeman",
  "scholtz","schutte","serfontein","slabbert","smal","smit","smuts","snyman","spies",
  "stander","stapelberg","steenberg","steenkamp","steyn","stoltz","strydom","swanepoel",
  "swart","taljaard","terblanche","theron","theunissen","trichardt","triechardt",
  "truter","uys","venter","vermaak","verwey","viljoen","visagie","visser","vlok","voges",
  "vorster","vosloo","welthagen","wepener","wessels","willemse","wolmarans","zietsman")
boer_surname <- function(s) {
  s <- tolower(trimws(gsub("[0-9]|\\(.*\\)", "", s)))
  s <- iconv(s, to = "ASCII//TRANSLIT")
  grepl("^(van|de|du|le|la|te|ver)( |$)|^(van|du|le|de)[a-z]", s) & !grepl("^(de[a-z]{4,}|le[a-z]{4,}|la[a-z]{3,})$", s) |
    grepl("ij|[dw]yk$", s) |
    s %in% afr_list |
    grepl("^le ?roux$|^du ?plooy$", s)
}
d <- d %>% mutate(boer_sn = boer_surname(Surname))

# -----------------------------------------------------------------------------
# 8. Occupation: own HISCO coding to the minor-group (2-digit) level
#    Ordered regex rules; first match wins. Parenthetical text is removed and
#    compound callings ("X & Y", "X/Y", "X and Y") are coded by the first-listed
#    occupation. Minor groups follow the paper's Table 6 labels (02 merged into
#    03; 07 merged into 06; 00 = gentleman / no occupation; 10 = students).
# -----------------------------------------------------------------------------
norm_call <- function(x) {
  x <- tolower(trimws(x)); x <- gsub("[\"']", "", x); x <- gsub("\\s+", " ", x)
  x <- gsub("[.]$", "", x); x <- trimws(x); x[x %in% c("", "?", "-")] <- NA; x
}
retail <- "draper|grocer|grocery|ironmonger|outfitter|hosier|clothier|bookseller|fishmonger|merchant|hardwarehouseman|boot and leather|linen warehouse|storekeeper|shop|tailor"
R <- tribble(~pat, ~h,
  "^(nil|none|nothing|no occupation|no profession|no trade.*|independent|gentleman|layman|none - gentleman)$", "00",
  "gentleman rider", "18",
  "electrical fitter", "85",
  "brass (finisher|trimmer)|metal polisher|lather", "83",
  "pattern maker", "81",
  "carpet (planner|finisher)", "75",
  "ref guard", "58",
  "outfitter|tobacconist|pawn ?broker", "41",
  "nurseryman", "62",
  "ticket", "36",
  "bus proprietor|coach business", "41",
  "instrument maker|sight spring", "84",
  "farm[- ]?pupil", "62",
  "student|undergrad|scholar|pupil", "10",
  "golf club maker|fishing rod|fish hook|piano|organ builder|toy maker|basket|brush maker|umbrella|pipe maker|tattooist", "94",
  "(loco|railway|railroad).*engineer|^loco", "98",
  "stationary engine|engine (man|attendant)|^engineman|pumpman", "96",
  "marine engineer|master mariner|mate|^pilot|officer r\\.?n|^officer rnr", "04",
  "(motor|cycle|jobbing) engineer", "84",
  "engineers turner", "83",
  "telegraph linesman|telephone (engineer|jointer)|linesman|lineman|wireman", "85",
  "electric(al)? engineer|elec\\. engineer", "03",
  "assayer|analyst", "01",
  "medical|doctor|physician|surgeon|dentist|dental|veterinary|^vet|chemist|druggist|dispenser|pharmac|nurse|nursing|hospital|asylum|sick|compounder|optician", "06",
  "architect|engineer|surveyor|draughtsman|draftsman|^c\\.e$|explosive", "03",
  "accountant", "11",
  "shorthand|stenographer|typist|typewriter|shorthand typer", "32",
  "telegraph|telephon|signaller", "38",
  "clerk|clerical|secretar|correspond", "30",
  "solicitor|barrister|lawyer|conveyancer|crown law|^law$", "12",
  "teacher|schoolmaster|school master|tutor|instructor", "13",
  "journalist|reporter|author|editor|publisher", "15",
  "artist|photographer|^art$|fine art|sculptor|china painter", "16",
  "musician|^actor|organist|bandsman|piper|trumpeter|theatrical|composer|vocalist", "17",
  "jockey|golf|athlete|swimmer|gymnast|cricketer|steeplechase", "18",
  "interpreter|naturalist|librar", "19",
  "farm (labourer|servant|hand|worker|overseer|steward|bailiff)|ranch overseer|land steward", "62",
  "manager|banker|contractor|manufacturer", "21",
  "foreman|overseer|overlooker|inspector|supervisor|ganger", "22",
  "govt servant|government|civil service|collector", "31",
  "bookkeeper|book-keeper|cashier", "33",
  "conductor|ticket|^guard|railway guard", "36",
  "postman|mail|post-boy", "37",
  "storeman|store man|time ?keeper|checker|weigh master|booker|stock keeper", "39",
  "labourer|laborer", "99",
  "porter|packer|stevedore|docker|warehouseman|crane|winch|furniture remover|bottler|corker|labeller|trussman|pile driver", "97",
  "merchant (service|navy|seaman)|sailor|seaman|mariner|seafaring|boat-?swain|waterman|lighterman|driver|coachman|^coach$|carter|carman|cabman|^cab( |driver|man|$)|teamster|transport|chauffeur|motor-?man|tramcar|van ?man|vanman|drayman|lorryman|carrier|shunter|brakesman|signal[- ]?man|fireman|stoker|locomotive|railroading|trucker|deliverer", "98",
  "retailer|buyer", "41",
  "(auctioneer|estate agent|land agen|lands agent|insurance|stock ?broker|broker|commission agent|stock exchange|mining agent|land agency)", "44",
  "traveller|canvasser|agent", "43",
  "salesman|saleman|shop assistant|shopman|hawker|milkman|breadsman|window dresser", "45",
  "hotel (proprietor|keeper)|hotelkeeper|publican|licensed victualler|caterer|innkeeper|job ?master|posting master|horse hirer|liveryman", "51",
  "cook|chef|waiter|barman|bartender|tapster|steward|cell[ae]r ?man|collerman", "53",
  "farm servant|railway servant|rail servant", "XX",
  "valet|footman|butler|servant|^boots|hotel boots|batman|manservant|hall porter", "54",
  "cleaner|caretaker|usher|lamplighter", "55",
  "laund", "56",
  "hair ?dresser|barber", "57",
  "soldier|army|military|militia|police|constable|constabulary|r\\.i\\.c|nwmp|n\\.w\\.m|z\\.?a\\.?r\\.?p|trooper|warder|gaoler|prison|fire brigade|staats|artiller|rifles|c\\.m\\.r|cavalry|scout|dispatch rider|messenger|watchman|sheriff|ammunition|lieutenant|captain|petty officer|gunner|inquiry agent|bailiff", "58",
  "billiard|attendant|guide|bookmaker", "59",
  "farmer|farming|rancher|ranching|^ranch$|grazier|planter|agricultur|landowner|yeoman|stock raising|fruit growing|market garden|^boer$|horse breeder", "61",
  "ploughman|groom|stable|horse ?(breaker|trainer|keeper)|colt breaker|rough rider|stock ?man|stock ?(rider|driver|riding)|drover|shepherd|cowboy|cattle ?man|musterer|boundary rider|range rider|station hand|shearer|dairyman|garden|nurseryman|horticultur|groundsman|ostler|gardiner|bushman|^whip$|huntsman|m\\.f\\.h|ranchman|^trainer", "62",
  "^lumber|woodman|forest|forrester|woodranger|wood burner", "63",
  "fisherman|game ?keeper|deer stalker|trapper|mole catcher|hunter|sealer", "64",
  "(^| )miners?( |$)|^mining$|collier|coalminer|prospector|quarry|digger|well sinker|pit sinker|blaster|driller|stonebreaker", "71",
  "smelter|furnace|steel ?work|iron (worker|founder|& steel)|moulder|founder|caster|metal roller|rollerman|amalgamator|cyanide|refiner|heater|mould maker|coremaker|electroplater", "72",
  "sawyer|paper maker", "73",
  "soap|oil blender|gas worker|colour mixer", "74",
  "weaver|spinner|spinning|dyer|bleacher|tenter|warp|lap piecer|carder|wool (sorter|classer|stapler)|cloth (finisher|lapper)|linen finisher|beamer|creeler|power loom|worsted|lace maker|callico|calico|linoleum|woollen carder", "75",
  "tanner|currier|fellmonger", "76",
  "butcher|baker|miller|millier|confectioner|brewer|maltster|malster|malts ?man|distiller|cheese ?maker|butter maker|poultry dresser|mineral water|soda water|biscuit|bean curer", "77",
  "tobacco|cigar(?! box)", "78",
  "stone ?cutter|marble|monumental", "82",
  "paper (cutter|ruler|finisher)|^ruler$", "91",
  "shoe(?!ing)|boot|saddle|sadler|harness|clicker|shoe laster|portmanteau|leather|whip maker", "80",
  "tailor|taylor|cutter|upholster|hatter|shirt|mattress|furrier|sail ?maker|tent|costumier|dressmaker", "79",
  "cabinet|cooper|wheelwright|coach ?builder|coach-body|carriage (builder|finisher)|wagon|wood ?(turner|carver|mechanic|moulder)|chair maker|french polisher|trench polisher|packing case|cartwright|carver|cigar box", "81",
  "plumber|gas ?fitter|steam fitter|pipe (fitter|layer)|hot-water|tin ?smith|tinplater|tin worker|tinker|boiler|plater|rivet|rivitter|rigger|splicer|wire rope|coppersmith|metal (worker|spinner|pipe)|ironwork|ironplate|sink & bath|wire worker", "87",
  "jewel|silversmith|goldsmith|silver polisher|diamond worker", "88",
  "fitter|mechanic|millwright|watch|clock|cycle|bicycle|safe making", "84",
  "blacksmith|smith$|shoeing|farrier|ferrier|tool (maker|forger|sharpener)|filer|turner|machinist|machine (hand|operator|man)|armourer|gun|arms smith|hammerman|striker|stiker|chain maker|small arms", "83",
  "electric", "85",
  "glass|potter|brick ?maker|brick burner|tile ?maker|terracotta", "89",
  "rubber", "90",
  "printer|compositor|lithographer|bookbind|binder|stereotyper|engraver|etcher|^press$|pressman", "92",
  "painter|decorator|sign ?writer|paper ?hanger", "93",
  "carpenter|joiner|bricklayer|mason|plasterer|slater|slate layer|slating|builder|plate ?layer|glazier|thatcher|tiler|scaffolder|shipwright|ship ?builder|road making|trackman", "95",
  "grocer|ironmonger|draper|drapery|fruiterer|merchant|trader|dealer|shop ?keeper|store ?keeper|tobacconist|stationer|fishmonger|cheesemonger|poulterer|outfitter|clothier|hosier|florist|book ?seller|pawn ?broker|chandler|seedsman|silk mercer|hardware|wholesaler|provision|wine|spirit trade|tea trade|grain trade|woollen trade|lace trade|music trade|mercantile|tradesman|^commercial$|lace|colourman|glove|furnish", "41",
  "railway|railwayman|keeper|careman|fareman|fallsman|fetler|bleeder|pipemounter|plateman|art in trans|handyman|helper|mill ?hand|millhand|apprentice|improver|worker$|^shipping$|^insurance$", "99"
)
code_one <- function(s) {
  if (is.na(s) || s == "") return(NA_character_)
  if (grepl("assistant|\\basst", s)) {
    if (grepl(retail, s)) return("45")
    s <- trimws(gsub("assistant|asst\\.?|\\bto\\b|,", "", s))
    if (s == "") return(NA_character_)
  }
  for (i in seq_len(nrow(R))) if (grepl(R$pat[i], s, perl = TRUE)) {
    h <- R$h[i]
    if (h == "XX") h <- if (grepl("farm", s)) "62" else "99"
    return(h)
  }
  NA_character_
}
code_calling <- function(x) {
  if (is.na(x)) return(NA_character_)
  y <- trimws(gsub("\\(.*?\\)", "", x)); if (y == "") y <- gsub("[()]", "", x)
  segs <- trimws(str_split(y, " & | and |/|,|;| - |: ")[[1]]); segs <- segs[segs != ""]
  h <- code_one(segs[1])
  if (is.na(h)) h <- code_one(y)
  if (is.na(h) && length(segs) > 1) for (s in segs[-1]) { h <- code_one(s); if (!is.na(h)) break }
  h
}
d$calling_norm <- norm_call(d$Calling)
dict <- d %>% filter(!is.na(calling_norm)) %>% count(calling_norm, name = "n_terms") %>%
  mutate(hisco2 = map_chr(calling_norm, code_calling))
class_of <- function(h) case_when(
  is.na(h) ~ NA_character_,
  h == "61" ~ "Farmers",
  h %in% c("53","54","55","56","59","62","63","64","97","98","99") ~ "Lower",
  TRUE ~ "Upper, middle")
dict <- dict %>% mutate(hisco_major = substr(hisco2, 1, 1), occ_class = class_of(hisco2))
cat("Distinct callings:", nrow(dict), " uncoded:", sum(is.na(dict$hisco2)),
    " uncoded terms:", sum(dict$n_terms[is.na(dict$hisco2)]), "\n")
if (any(is.na(dict$hisco2))) print(dict %>% filter(is.na(hisco2)) %>% arrange(desc(n_terms)), n = 50)
d <- d %>% left_join(dict %>% select(calling_norm, hisco2, hisco_major, occ_class), by = "calling_norm") %>%
  mutate(farmer = case_when(is.na(occ_class) ~ NA_real_, occ_class == "Farmers" ~ 1, TRUE ~ 0))

# -----------------------------------------------------------------------------
# 9. Discharge: died, tenure, exit category
# -----------------------------------------------------------------------------
d <- d %>% mutate(
  cause = clean_txt(`Cause of discharge`), cl = tolower(cause),
  died = case_when(is.na(cl) ~ NA_real_,
                   grepl("died|death|dead|deceas|killed|drown|suicide", cl) ~ 1, TRUE ~ 0),
  died_cause = case_when(died != 1 ~ NA_character_,
                         grepl("killed|wound|action", cl) ~ "battle",
                         grepl("enteric|typhoid", cl) ~ "enteric",
                         grepl("drown", cl) ~ "drowning",
                         grepl("suicide", cl) ~ "suicide",
                         grepl("^(died|deceased|death|dead)\\.?$", cl) ~ "unknown",
                         TRUE ~ "other"),
  exit = case_when(is.na(cl) ~ NA_character_,
                   died == 1 ~ "died",
                   grepl("desert", cl) ~ "desertion",
                   grepl("purchas", cl) ~ "purchase",
                   grepl("transfer|rejoin|return.*regiment|re-?transfer|retransfer", cl) ~ "transfer",
                   grepl("medically|invalid|unfit", cl) ~ "unfit",
                   grepl("dismiss|unsuitab|misconduct|undesirable|inefficien", cl) ~ "dismissal",
                   grepl("reduction|retrench|no longer|abolition|change in establishment", cl) ~ "retrenchment",
                   grepl("time expired|expir|completion|finished", cl) ~ "expired",
                   grepl("free", cl) ~ "free",
                   TRUE ~ "other"),
  lo = tolower(clean_txt(Lengthorig)),
  l_y = num1(str_match(lo, "([0-9.]+) ?(years?|yrs?)\\b")[, 2]),
  l_m = num1(str_match(lo, "([0-9.]+) ?(months?|mos?|mths?)\\b")[, 2]),
  l_d = num1(str_match(lo, "([0-9.]+) ?days?\\b")[, 2]),
  tenure_days = if_else(is.na(l_y) & is.na(l_m) & is.na(l_d), NA_real_,
                        365 * coalesce(l_y, 0) + 30.4375 * coalesce(l_m, 0) + coalesce(l_d, 0)),
  tenure = if_else(coalesce(died, 0) == 1, NA_real_, tenure_days)
)

# -----------------------------------------------------------------------------
# 10. Table 2 characteristics
# -----------------------------------------------------------------------------
yesno <- function(x) {
  x <- tolower(clean_txt(x))
  case_when(is.na(x) ~ NA_real_,
            grepl("^(no|not|nil|none|never)\\b|very little|^little|^a little|slight|learning|not much", x) ~ 0,
            TRUE ~ 1)
}
ol <- tolower(clean_txt(d$`Other languages?`))
mk <- tolower(clean_txt(d$`Marks and Scars`))
d <- d %>% mutate(
  blue_eyes = if_else(is.na(clean_txt(Eyes)), NA_real_, as.numeric(grepl("blue", tolower(Eyes)))),
  red_hair  = if_else(is.na(clean_txt(Hair)), NA_real_,
                      as.numeric(grepl("red|ruddy|auburn|ginger", tolower(Hair)))),
  black_lang = if_else(is.na(ol), NA_real_,
                       as.numeric(grepl("kaf+ir|zulu|sotho|suto|basotho|basutho|swazi|matabele|tebele|shona|xhosa|native|sechuana|shangaan|makosa|sa languages|kaffir", ol))),
  french = if_else(is.na(ol), NA_real_, as.numeric(grepl("french", ol))),
  tattoo = if_else(is.na(mk), NA_real_, as.numeric(grepl("tat+o", mk))),
  ride = yesno(Ride), shoot = yesno(Shoot), swim = yesno(Swim),
  place_enl = clean_txt(Place)
)

# -----------------------------------------------------------------------------
# 11. Afrikaans dummy (SA-born x Boer surname), save without identifying fields
# -----------------------------------------------------------------------------
d <- d %>% mutate(
  sa_born = region %in% c("Boer republics", "Southern Africa"),
  afrikaans = as.numeric(sa_born & boer_sn),
  hisco_major = as.character(hisco_major)
)
keep <- c("person_id","term_no","n_terms","enl_year","enl_month","enl_day","term_len_yrs",
          "wage","height_cm","weight_kg","age","age_reported","birth_year","chest","married","rc",
          "country_std","region","sa_born","afrikaans","calling_norm","hisco2","hisco_major",
          "occ_class","farmer","died","died_cause","exit","tenure_days","tenure",
          "blue_eyes","red_hair","black_lang","french","tattoo","ride","shoot","swim","place_enl")
terms <- d %>% select(all_of(keep))
persons <- terms %>% filter(term_no == 1)

saveRDS(terms,   file.path(SCR, "sac_terms.rds"))
saveRDS(persons, file.path(SCR, "sac_persons.rds"))
write_csv(dict %>% arrange(desc(n_terms), calling_norm), file.path(OUT, "hisco_dictionary.csv"))
write_csv(tibble(rule_order = seq_len(nrow(R)), regex = R$pat, hisco_minor = R$h),
          file.path(OUT, "hisco_rules.csv"))

cat("Terms:", nrow(terms), " persons:", nrow(persons),
    " persons with >=2/3/4 terms:", sum(persons$n_terms >= 2), sum(persons$n_terms >= 3),
    sum(persons$n_terms >= 4), "\n")
cat("Afrikaans (SA-born, Boer surname):", sum(persons$afrikaans), " of SA-born", sum(persons$sa_born), "\n")
