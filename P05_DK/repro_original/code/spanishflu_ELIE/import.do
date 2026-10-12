

cd "/Users/eliemurard/Dropbox/spanishflu/"
*import excel "POCQMK 1915-1920_CLEAN_v24-08-04-2020.xlsx",  firstrow clear

import excel "POCQMK 1915-1920_CLEAN_v26-18-04-2020.xlsx",  firstrow clear



g influenza= diseasegroup=="Influenza / Spanish Influenza"
g death= 1

g race= "white" if Race=="White"
replace race="non-white" if Race=="Black" | Race=="Coloured"

destring age_years , force replace
rename age_years age

									
gen agegroup=""
replace agegroup="0-4"   if age >=0 & age<=4
replace agegroup="5-9"   if age >4 & age<=9
replace agegroup="10-14" if age >9 & age<=14
replace agegroup="15-19" if age >14 & age<=19
replace agegroup="20-24" if age >19 & age<=24
replace agegroup="25-34" if age >24 & age<=34
replace agegroup="35-49" if age >34 & age<=49
replace agegroup="50-69" if age >49 & age<=69
replace agegroup="70+" if age >69

drop if race==""
g sex="male" if  Sex=="Male"|   Sex=="male" 
drop if Sex=="NA"
replace  sex="female" if  Sex=="Female"|   Sex=="female" 

drop if sex==""
drop if agegroup ==""
drop if race ==""

destring Yearofdeath , force replace

keep if inlist(Yearofdeath,1915,1916,1917,1918,1919,1920) 

collapse (sum) death influenza, by(Yearofdeath Town sex agegroup race) 

save death, replace




import excel "/Volumes/Samsung_T5/LEAP_camp_data/census SA/Census 1911.xlsx", sheet("Ages  ") firstrow clear



replace B= subinstr(B," ","",.)
keep if B=="Cradock" | ///
	    B=="Mafeking" | ///
        B=="Oudtshoorn" |        ///    
        B==    "Paarl" |        ///
		B=="Queenstown"| ///
		B=="Kuruman" | ///
	    B=="Simonstown"  | ///
		B=="Vryburg"
	  
rename B Town

replace Town="Simon's Town" if Town=="Simonstown" 

keep Town m* f* 
reshape long m_w_ f_w_ m_nw_ f_nw_ , i(Town) j(age)
gen agegroup=""
replace agegroup="0-4"   if age >=0 & age<=4
replace agegroup="5-9"   if age==59
replace agegroup="10-14" if age== 1014
replace agegroup="15-19" if age==1519
replace agegroup="20-24" if age ==2024
replace agegroup="25-34" if age ==2534
replace agegroup="35-49" if age ==3549
replace agegroup="50-69" if age==5069
replace agegroup="70+" if age==70

foreach v of varlist m_* f_*{
destring `v', force replace
}
collapse (sum)  m_* f_*, by(Tow	agegroup)

reshape long m_ f_ , i(Tow	agegroup) j(race) string

replace race= "white" if race=="w_" 
replace race="non-white"  if race=="nw_" 

rename m_ pop1911_m
rename f_ pop1911_f
reshape long pop1911, i(Tow	agegroup race) j(sex) string
replace sex="male" if  sex=="_m"
replace  sex="female" if  sex=="_f"

save census11, replace


import excel "/Volumes/Samsung_T5/LEAP_camp_data/census SA/Census 1911.xlsx", sheet("Ages- Centres of 2000") firstrow clear

replace B= subinstr(B," ","",.)

keep if B=="Cradock" | ///
	    B=="Mafeking" | ///
        B=="Oudtshoorn" |        ///    
        B==    "Paarl" |        ///
		B=="Queenstown"| ///
		B=="Kuruman" | ///
	    B=="Simonstown"  | ///
		B=="Vryburg"
	  
rename B Town

replace Town="Simon's Town" if Town=="Simonstown" 
keep Town m* f* 
reshape long m_w_ f_w_ m_nw_ f_nw_ , i(Town) j(age)
gen agegroup=""
replace agegroup="0-4"   if age >=0 & age<=4
replace agegroup="5-9"   if age==59
replace agegroup="10-14" if age== 1014
replace agegroup="15-19" if age==1519
replace agegroup="20-24" if age ==2024
replace agegroup="25-34" if age ==2534
replace agegroup="35-49" if age ==3549
replace agegroup="50-69" if age==5069
replace agegroup="70+" if age==70

foreach v of varlist m_* f_*{
destring `v', force replace
}
collapse (sum)  m_* f_*, by(Tow	agegroup)

reshape long m_ f_ , i(Tow	agegroup) j(race) string

replace race= "white" if race=="w_" 
replace race="non-white"  if race=="nw_" 

rename m_ pop1911_m
rename f_ pop1911_f
reshape long pop1911, i(Tow	agegroup race) j(sex) string
replace sex="male" if  sex=="_m"
replace  sex="female" if  sex=="_f"
rename  pop1911 pop1911_urbancentre
save census11_urbancentre, replace




use death, clear
reshape wide death influenza, i(Town race agegroup sex) j(Year)
merge 1:1 Town agegroup race sex using census11
drop _m

merge 1:1 Town agegroup race sex using census11_urbancentre
drop _m

foreach v of varlist death* infl* pop* {
replace `v'=0 if `v'==.
}


save death_pop1911_town_age_sex_race, replace


		
