* [ENV] run_D_dropfarmers.do: lines 367-378 on the anonymised file
version 15
clear all
sysdir set PLUS "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
do "`c(pwd)'/../../tools/paths.do"
global D "$DATA/P04_CF/original/CF Mobility/Data"
use "$D/CF_mobility_replication_data_anonymized.dta", clear
/*******************************************************************************
DROPPING FARMERS
*******************************************************************************/
preserve
drop if f_occ_group_last == 2
drop if occ_group_last == 2

bysort p_split: tab f_occ_group_last occ_group_last, row

***re-estimate Altham statistics, then***

restore
