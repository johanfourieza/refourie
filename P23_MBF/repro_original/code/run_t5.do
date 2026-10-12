* S2 PATCHED RUN FILE (environment only; see PATCHES.md). Lines 484-535 of "1.4_leaders and murdock (not included).do" (Table 5 regressions)
* on the surviving 1_murdockanddbirth_final.dta (7 Jun 2022). Construction lines 1-483 not run (they rebuild and overwrite that file).
version 16
clear all
set more off
local ado "./P23_MBF/repro_original/ado"
sysdir set PLUS "`ado'/plus"
sysdir set PERSONAL "`ado'/personal"
do "./tools/paths.do"
cd "./P23_MBF/repro_original/out_t5"
// run regression

* (1) Region of birth of ALL leader
use "$DATA/P23_MBF/original/ld/1_murdockanddbirth_final.dta", clear  



logit d_birth d_mission , vce(robust)
outreg2 using "3_dbirthethnic.xls", replace tex     nocons    ///
	addtext(Constant, yes, Country FE, no, Controls geo, no , Controls precolonial, no )     ///
	ctitle("d_birth") dec(2) ///
	drop(centralization agricintensity  d_settlement hierarchy pop1800  d_slavery  lat lon d_capital coast river meanalt tsi meantemp   i.iso2)   ///
	 addstat(Pseudo R2, e(r2_p))
	 
logit d_birth d_mission i.iso2, vce(robust)
outreg2 using "3_dbirthethnic.xls", append tex     nocons    ///
	addtext(Constant, yes, Country FE, yes, Controls geo, no, Controls precolonial, no )     ///
	ctitle("d_birth") dec(2) ///
	drop(centralization agricintensity  d_settlement hierarchy pop1800  d_slavery  lat lon d_capital coast river meanalt tsi meantemp   i.iso2)   ///
	 addstat(Pseudo R2, e(r2_p))	
	 

logit d_birth d_mission lat lon   coast 	river meanalt tsi i.iso2, vce(robust)
outreg2 using "3_dbirthethnic.xls", append tex     nocons    ///
	addtext(Constant, yes, Country FE, yes, Controls geo, yes , Controls precolonial, no , )     ///
	ctitle("d_birth") dec(2) ///
	drop(centralization agricintensity  d_settlement hierarchy pop1800  d_slavery  lat lon d_capital coast river meanalt tsi meantemp   i.iso2)   ///
	 addstat(Pseudo R2, e(r2_p))	 
	

logit d_birth d_mission lat lon coast river meanalt tsi meantemp centralization agricintensity  d_settlement hierarchy pop1800  d_slavery i.iso2, vce(robust)
outreg2 using "3_dbirthethnic.xls", append tex     nocons    ///
	addtext(Constant, yes, Country FE, yes, Controls geo, yes , Controls precolonial, yes )     ///
	ctitle("d_birth") dec(2) ///
	drop(centralization agricintensity  d_settlement hierarchy pop1800  d_slavery  lat lon d_capital coast river meanalt tsi meantemp   i.iso2)   ///
	 addstat(Pseudo R2, e(r2_p))	
	 















