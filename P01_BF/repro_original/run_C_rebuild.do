* [ENV-diagnostic] run_C_rebuild.do: lines 1573-1647 verbatim, run on data.dta stripped of the variables those lines create; checks that data.dta = na110702
version 11
clear all
set more off
sysdir set PLUS "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
do "`c(pwd)'/../../tools/paths.do"
global S "$DATA/P01_BF/repro_original/_scratch"
global ORIG "$DATA/P01_BF/original/Baten Fourie"
global OUT "`c(pwd)'/output"
cd "$S"   // [ENV] outreg2 files (na1, na3, numeracy) are written to D: scratch
use "$ORIG/data.dta", clear
preserve
keep number bco b_* bcohort bd_* eu_early bcoh eur_early-za_post
foreach v of varlist bco b_* bcohort bd_* eu_early bcoh eur_early-za_post {
  rename `v' o_`v'
}
tempfile old
gen long s2row = _n
save `old'
restore
drop bco b_* bcohort bd_* eu_early bcoh eur_early-za_post
gen long s2row = _n
g bco=origindum
replace bco="in" if bco=="India" | bco=="Ceylon" | origin=="Pondieberg"
replace bco="mz" if bco=="Mozambique" | bco=="Madagascar" | bco=="Mauritius" | origin=="Mauritz" 
replace bco="cn" if bco=="China" | cn
replace bco="id" if bco=="Indonesia" | origin=="Boeton" | origin=="Bourbon" | origin=="Bouton" 
replace bco="ko" if ko
replace bco="za" if bco=="Cape" | origin=="Kust" | origin=="Cust" |origin=="Westcoast"
replace bco="" if length(bco)>2
replace bco="oth_bl" if bl & bco==""
replace bco="eur" if eu
tab bco, gen (bco_)
ren bco_1 b_cn
ren bco_2 b_eur
ren bco_3 b_id
ren bco_4 b_in
ren bco_5 b_kobc
ren bco_6 b_mz
ren bco_7 b_oth_bl
ren bco_8 b_za

capture drop bcohort
g bcohort=""
replace bcohort="early" if bdec<=1740
replace bcohort="middle" if bdec>=1750 & bdec<=1780
replace bcohort="post1790" if bdec>=1790 & bdec~=.
tab bcohort, gen (bcohort_)
ren bcohort_1 bd_early
ren bcohort_3 bd_post1790
ren bcohort_2 bd_middle

g eu_early=0
replace eu_early=1 if b_eur & bd_early
g bcoh=.
replace bcoh=1 if bcohort=="early"
replace bcoh=2 if bcohort=="middle"
replace bcoh=3 if bcohort=="post1790"

g	eur_early	 =0
g	eur_mid	 =0
g	eur_post	 =0
g	id_early	 =0
g	id_mid	 =0
g	in_early	 =0
g	in_mid	 =0
g	ko_early	 =0
g	ko_mid	 =0
g	ko_post	 =0
g	mz_mid	 =0
g	mz_post	 =0
g	otb_early	 =0
g	otb_mid	 =0
g	otb_post	 =0			
g	za_mid	 =0			
g	za_post	 =0			

						
replace 	eur_early	 =1 if bco=="eur" & bcoh==	1
replace 	eur_mid	 =1 if bco=="eur" & bcoh==	2
replace 	eur_post	 =1 if bco=="eur" & bcoh==	3
replace 	id_early	 =1 if bco=="id" & bcoh==	1
replace 	id_mid	 =1 if bco=="id" & bcoh==	2 | (bco=="id" & bcoh==	3)
replace 	in_early	 =1 if bco=="in" & bcoh==	1
replace 	in_mid	 =1 if bco=="in" & bcoh==	2 | (bco=="in" & bcoh==	3)
replace 	ko_early	 =1 if bco=="ko" & bcoh==	1
replace 	ko_mid	 =1 if bco=="ko" & bcoh==	2
replace 	ko_post	 =1 if bco=="ko" & bcoh==	3
replace 	mz_mid	 =1 if bco=="mz" & bcoh==	2
replace 	mz_post	 =1 if bco=="mz" & bcoh==	3
replace 	otb_early	 =1 if bco=="oth_bl" & bcoh==	1 | (bco=="za" & bcoh==	1) | (bco=="mz" & bcoh==	1) 
replace 	otb_mid	 =1 if bco=="oth_bl" & bcoh==	2
replace 	otb_post	 =1 if bco=="oth_bl" & bcoh==	3
replace 	za_mid	 =1 if bco=="za" & bcoh==	2
replace 	za_post	 =1 if bco=="za" & bcoh==	3


* [ENV-diagnostic] compare rebuilt with stored variables
merge 1:1 s2row using `old', nogen
foreach v in bco b_cn b_eur b_id b_in b_kobc b_mz b_oth_bl b_za bcohort bd_early bd_middle bd_post1790 bcoh eur_early eur_mid eur_post id_early id_mid in_early in_mid ko_early ko_mid ko_post mz_mid mz_post otb_early otb_mid otb_post za_mid za_post {
  quietly count if `v' != o_`v'
  display "S2CHK `v' mismatches = " r(N)
}
