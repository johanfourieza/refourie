* [ENV] run_B_tabs2016.do: lines 145-157 on the Oct-2016 anonymised analysis file (already holds the outputs of lines 14-144 incl. labels)
version 15
clear all
sysdir set PLUS "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
do "`c(pwd)'/../../tools/paths.do"
global D "$DATA/P04_CF/original/CF Mobility/Data"
use "$D/CF_mobility_replication_data_anonymized.dta", clear
tab period

/*******************************************************************************
TAB SAMPLE MEANS
*******************************************************************************/
bysort period: tab occ_group_last
bysort period: tab occ_group_first

/*******************************************************************************
4X4 ABSOLUTE MOBILITY TABLES
*******************************************************************************/
bysort period: tab f_occ_group_last occ_group_last, row
tab f_occ_group_last occ_group_last, row
* [ENV-diagnostic, not original code] psplit tabulation that line 178 intends (data were cleared at line 167)
bysort psplit: tab f_occ_group_last occ_group_last, row
