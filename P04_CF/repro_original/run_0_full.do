* [ENV] run_0_full.do: verbatim do-file on the Oct-2016 anonymised file
version 15
clear all
sysdir set PLUS "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
do "`c(pwd)'/../../tools/paths.do"
global D "$DATA/P04_CF/original/CF Mobility/Data"
use "$D/CF_mobility_replication_data_anonymized.dta", clear
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

/*******************************************************************************
ALTHAM STATISTICS
********************************************************************************

The calculation of d(P,I), d(Q,I), d(P,Q), and the G2 statistics shown in the 
text can be done by the following STATA code. 

********************************************************************************/
clear
set matsize 300

gen psplit =.
replace psplit = 1 if period == 1 | period == 2
replace psplit = 2 if period ==3 | period ==4
tab psplit

la def psplit 1 "Before 1868" 2 " After 1868"
la val psplit psplit

bysort psplit: tab f_occ_group_last occ_group_last, row

/* Read in the frequencies for tables p and q,
together with the character labels (father and son)
for columns and rows
*/
input str4 father str4 son p q
"1. w" "1. w" 432 684
"2. f" "1. w" 286 614
"3. s" "1. w" 104 176
"4. u" "1. w" 55 86
"1. w" "2. f" 257 270
"2. f" "2. f" 2170 2187
"3. s" "2. f" 147 92
"4. u" "2. f" 223 189
"1. w" "3. s" 70 126
"2. f" "3. s" 143 244
"3. s" "3. s" 139 132
"4. u" "3. s" 33 45
"1. w" "4. u" 35 17
"2. f" "4. u" 209 100
"3. s" "4. u" 30 7
"4. u" "4. u" 137 55
end

/* Change r and s below to reflect the dimensions of
your tables
*/

gen r=4
gen s=4
table son father [fw=p], row col
table son father [fw=q], row col
quietly generate logp=log(p)
quietly generate logq=log(q)
quietly generate logpq=log(p/q)
quietly encode father, gen(F)
quietly encode son, gen(S)
quietly anova logp F S
quietly gen dpi=sqrt(e(rss)*4*r*s)
display "d(P,I)=" dpi

quietly xi: glm p i.father i.son, f(poisson)
quietly gen g2p=e(deviance)
quietly gen g2pdf=e(df)
quietly gen g2probp=1-chi2(g2pdf,g2p)
display "G2=" g2p
display "degrees of freedom=" g2pdf
display "probability [H0: d(P,I)=0]=" g2probp
quietly anova logq F S
quietly gen dqi=sqrt(e(rss)*4*r*s)
display "d(Q,I)=" dqi
quietly xi: glm q i.father i.son, f(poisson)
quietly gen g2q=e(deviance)
quietly gen g2qdf=e(df)
quietly gen g2probq=1-chi2(g2qdf,g2q)
display "G2=" g2q
display "degrees of freedom=" g2qdf
display "probability [H0: d(Q,I)=0]=" g2probq
quietly anova logpq F S
quietly gen dpq=sqrt(e(rss)*4*r*s)
display "d(P,Q)=" dpq
quietly expand 2
quietly gen pq=p if _n < r*s+1
quietly gen str1 table="p" if _n < r*s+1
quietly replace pq=q if _n > r*s
quietly replace table="q" if _n > r*s
quietly xi: glm pq i.son i.father i.table i.son*i.father i.son*i.table i.father*i.table, f(poisson)
quietly gen g2pq=e(deviance)
quietly gen g2pqdf=e(df)
quietly gen g2probpq=1-chi2(g2pqdf,g2pq)
display "G2=" g2pq
display "degrees of freedom=" g2pqdf
display "probability [H0: d(P,Q)=0]=" g2probpq
/* Input the row totals for table p which we want
the new table qn to mimic
*/
gen rt = .
tokenize 1541 4140 2110 1208
qui forval i = 1/4 {
replace rt = `i' if S == `i'
}
/* Input the column totals for table p which we want
the new table qn to mimic
*/
gen ct = .
tokenize 682 5498 1875 944
qui forval i = 1/4 {
replace ct = `i' if F == `i'
}

replace rt=rt*2
replace ct=ct*2
mstdize q rt ct , by(S F) g(qn) center format(%9.0f)
replace qn=qn/2
/* Display the new table qn with the same
row and column totals as the original table p
*/
table son father [pw=qn], row col center format(%9.0f)

********************************************************************************
/* Quasi-independence measures */
********************************************************************************
clear
set matsize 300
/* Read in the frequencies for tables p and q again,
together with the character labels (father and son)
for columns and rows
*/
input str4 father str4 son p q
"1. w" "1. w" 432 684
"2. f" "1. w" 286 614
"3. s" "1. w" 104 176
"4. u" "1. w" 55 86
"1. w" "2. f" 257 270
"2. f" "2. f" 2170 2187
"3. s" "2. f" 147 92
"4. u" "2. f" 223 189
"1. w" "3. s" 70 126
"2. f" "3. s" 143 244
"3. s" "3. s" 139 132
"4. u" "3. s" 33 45
"1. w" "4. u" 35 17
"2. f" "4. u" 209 100
"3. s" "4. u" 30 7
"4. u" "4. u" 137 55
end

/* Change r and s below to reflect the dimensions of
your tables
*/
gen r=4
gen s=4
table son father [fw=p], row col
table son father [fw=q], row col
quietly generate logp=log(p)
quietly generate logq=log(q)
quietly generate logpq=log(p/q)
quietly encode father, gen(F)
quietly encode son, gen(S)

/* Generate a variable with a unique value
for each diagonal element, and another value
for all other elements
*/
gen ind = 5
qui forval i = 1/4 {
replace ind = F if F == S
}
/* Perform the same analysis as previously, but
include the variable that distinguishes the
diagonal elements from the off-diagonal elements
*/
quietly anova logp F S ind
quietly gen dpi=sqrt(e(rss)*4*r*s)
display "d(P,I)=" dpi
quietly xi: glm p i.father i.son i.ind, f(poisson)
quietly gen g2p=e(deviance)
quietly gen g2pdf=e(df)
quietly gen g2probp=1-chi2(g2pdf,g2p)
display "G2=" g2p
display "degrees of freedom=" g2pdf
display "probability [H0: d(P,I)=0]=" g2probp
quietly anova logq F S ind
quietly gen dqi=sqrt(e(rss)*4*r*s)
display "d(Q,I)=" dqi
quietly xi: glm q i.father i.son i.ind, f(poisson)
quietly gen g2q=e(deviance)
quietly gen g2qdf=e(df)
quietly gen g2probq=1-chi2(g2qdf,g2q)
display "G2=" g2q
display "degrees of freedom=" g2qdf
display "probability [H0: d(Q,I)=0]=" g2probq
quietly anova logpq F S ind
quietly gen dpq=sqrt(e(rss)*4*r*s)
display "d(P,Q)=" dpq
quietly expand 2
quietly gen pq=p if _n < r*s+1
quietly gen str1 table="p" if _n < r*s+1
quietly replace pq=q if _n > r*s
quietly replace table="q" if _n > r*s
quietly xi: glm pq i.son i.father i.table i.ind i.son*i.father i.son*i.table i.father*i.table i.ind*i.son i.ind*i.father i.ind*i.table, f(poisson)
quietly gen g2pq=e(deviance)
quietly gen g2pqdf=e(df)
quietly gen g2probpq=1-chi2(g2pqdf,g2pq)
display "G2=" g2pq
display "degrees of freedom=" g2pqdf
display "probability [H0: d(P,Q)=0]=" g2probpq

/*******************************************************************************
DROPPING FARMERS
*******************************************************************************/
preserve
drop if f_occ_group_last == 2
drop if occ_group_last == 2

bysort p_split: tab f_occ_group_last occ_group_last, row

***re-estimate Altham statistics, then***

restore

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
