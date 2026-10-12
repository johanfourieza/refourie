* [ENV] run_E_logit.do: lines 380-409 on the anonymised file
version 15
clear all
sysdir set PLUS "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
do "`c(pwd)'/../../tools/paths.do"
global D "$DATA/P04_CF/original/CF Mobility/Data"
use "$D/CF_mobility_replication_data_anonymized.dta", clear
* [ENV] regenerate missing origin_occ_group_share.dta from the analysis file itself
*       (share is constant within period x f_occ_group_last; master already holds share,
*        so the m:1 merge only checks keys and does not overwrite)
preserve
keep period f_occ_group_last share
duplicates drop
isid period f_occ_group_last
* [ENV A6] data files (.dta, outreg2 .xls) are written to the D: data root; the outreg2 .txt tables are copied back to output/
local PROJ "`c(pwd)'"
capture mkdir "$DATA/P04_CF/repro_original/output"
save "$DATA/P04_CF/repro_original/output/origin_occ_group_share.dta", replace
restore
cd "$DATA/P04_CF/repro_original/output"
* [ENV] model 2 calls i.f_gen_dad (2017 name, = gen_dad in SAF 2017 file); the 2016 file names it f_gen
gen f_gen_dad = f_gen
/*******************************************************************************
GEN SIZE OF CLASS AT THE TIME OF ATTAINMENT
********************************************************************************/
merge m:1 period f_occ_group_last using origin_occ_group_share.dta
drop _merge

/*******************************************************************************
BINARY LOGISTIC MODELS
*******************************************************************************/
rename mobility_last mobility

***model 1***

char period [omit] 1
xi: logit mobility i.period i.origin i.f_gen i.first_son i.prov
outreg2 using binary_mob1_SA.xls, label eform

***model 2***

char period [omit] 1
xi: logit mobility i.period i.origin i.f_gen_dad i.first_son i.prov share
outreg2 using binary_mob2_SA.xls, label eform

***model 3***

char period [omit] 1
xi: logit mobility i.period i.origin i.f_gen i.first_son i.prov share i.f_occ_group_last
outreg2 using binary_mob3_SA.xls, label eform

*******************************************************************************/
* [ENV A6] copy the outreg2 text tables back to the project output folder
foreach k in 1 2 3 {
    copy "binary_mob`k'_SA.txt" "`PROJ'/output/binary_mob`k'_SA.txt", replace
    erase "binary_mob`k'_SA.txt"
}
cd "`PROJ'"
