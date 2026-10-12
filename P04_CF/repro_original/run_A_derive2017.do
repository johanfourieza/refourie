* [ENV] run_A_derive2017.do: lines 1-157 on the 2017 SAF file (only file with occ_group1-8 / f_occ_group1-9 / fathers_dob)
version 15
clear all
sysdir set PLUS "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
do "`c(pwd)'/../../tools/paths.do"
global D "$DATA/P04_CF/original/CF Mobility/Data"
use "$D/SAF mobility data_10.08.2017.dta", clear
drop occ_group_last f_occ_group_last intra_mobility year period
capture label drop class
capture label drop per
capture label drop mobl   // [ENV] 2017 file already carries these value labels
/*******************************************************************************
Author:		Jeanne Cilliers

Overview:	This file replates the occupational mobility analysis carried out 
			by Cilliers & Fouire 2016

Updated:	04 October 2016

********************************************************************************/

set more off
preserve

/*******************************************************************************
GENERATE FATHERS'S SOCIAL GROUP, USING LAST OBSERVED OCCUPATION	
********************************************************************************/
set rmsg on
qui {
    gen prelast = .
    gen last = .
    foreach v of varlist f_occ_group* {
        qui replace prelast = last if !mi(`v')
        qui replace last = `v' if !mi(`v')
    }
}
set rmsg off

replace last = prelast if last == -1 & prelast != -1
drop prelast
rename last f_occ_group_last

la def class 1 "White collar" 2 "Farmer" 3 "Skilled/Semiskilled" 4 "Unskilled"
la val f_occ_group_last class
tab f_occ_group_last

/*******************************************************************************
GENERATE FATHERS'S SOCIAL GROUP, USING FIRST OBSERVED OCCUPATION	
********************************************************************************/
gen f_occ_group_first = f_occ_group1
replace f_occ_group_first = f_occ_group2 if f_occ_group_first == -1
la val f_occ_group_first class
tab f_occ_group_first 

/*******************************************************************************
GENERATE SONS'S SOCIAL GROUP, USING LAST OBSERVED OCCUPATION	
********************************************************************************/
set rmsg on
qui {
    gen prelast = .
    gen last = .
    foreach v of varlist occ_group* {
        qui replace prelast = last if !mi(`v')
        qui replace last = `v' if !mi(`v')
    }
}
set rmsg off

replace last = prelast if last == -1 & prelast != -1
drop prelast

rename last occ_group_last
la val occ_group_last class
tab occ_group_last

/*******************************************************************************
GENERATE SONS'S SOCIAL GROUP, USING FIRST OBSERVED OCCUPATION	
********************************************************************************/
gen occ_group_first = occ_group1
replace occ_group_first = occ_group2 if occ_group_first == -1
la val occ_group_first class
tab occ_group_first 

/******************************************************************************* 
GEN ANY MOBILITY VARIABLE USING LAST OCCUPATIONS
*******************************************************************************/

gen mobility_last = f_occ_group_last - occ_group_last
replace mobility_last = 1 if mobility_last<=-1
replace mobility_last = 1 if mobility_last>1 & mobility_last~=.

label define mobl 0 "no mobility" 1 "mobility"
label values mobility_last mobl

/******************************************************************************* 
GEN ANY MOBILITY VARIABLE USING FIRST OCCUPATIONS
*******************************************************************************/

gen mobility_first = f_occ_group_first - occ_group_first
replace mobility_first = 1 if mobility_first<=-1
replace mobility_first = 1 if mobility_first>1 & mobility_first~=.

label values mobility_first mobl

/******************************************************************************* 
GEN ANY MOBILITY VARIABLE USING FATHER'S LAST AND SON'S FIRST OCCUPATIONS
*******************************************************************************/

gen mobility_mix = f_occ_group_last - occ_group_first
replace mobility_mix = 1 if mobility_mix<=-1
replace mobility_mix = 1 if mobility_mix>1 & mobility_mix~=.

label values mobility_mix mobl

/******************************************************************************* 
GEN ANY MOBILITY VARIABLE FOR INTRA GENERATIONAL MOBILITY FOR SONS
*******************************************************************************/

gen intra_mobility = occ_group_last - occ_group_first
replace intra_mobility = 1 if intra_mobility<=-1
replace intra_mobility = 1 if intra_mobility>1 & intra_mobility~=.

label values intra_mobility mobl

/******************************************************************************* 
GEN ANY MOBILITY VARIABLE FOR INTRA GENERATIONAL MOBILITY FOR FATHERS
*******************************************************************************/

gen f_intra_mobility = f_occ_group_last - f_occ_group_first
replace f_intra_mobility = 1 if f_intra_mobility<=-1
replace f_intra_mobility = 1 if f_intra_mobility>1 & f_intra_mobility~=.

label values f_intra_mobility mobl

/*******************************************************************************
GEN YEAR OF BIRTH FOR FATHER AND SON
********************************************************************************/

gen year = year(dob)
gen fyear = year(fathers_dob)
keep if year >=1806 
keep if year <=1910

/*******************************************************************************
GEN PERIODS
*******************************************************************************/

gen period = .
replace period = 1 if year>=1806 & year<=1834
replace period = 2 if year>=1835 & year<=1867
replace period = 3 if year>=1868 & year<=1886
replace period = 4 if year>=1887 & year<=1910

label define per 1 "Slavery" 2 "Stagnation" 3 "Diamonds" 4 "Gold"
label values period per
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
