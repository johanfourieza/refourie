cd "/Users/eliemurard/Dropbox/spanishflu/"
*import excel "POCQMK 1915-1920_CLEAN_v24-08-04-2020.xlsx",  firstrow clear

import excel "POCQMK 1915-1920_CLEAN_v27-18-04-2020.xlsx",  firstrow clear


*g influenza= diseasegroup=="Influenza / Spanish Influenza"
*g death= 1

g influenza=SF_indicator 


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

encode Town, gen(town_num)


drop if Yearofdeath<=1917

g month_d=substr(death_date ,1,3) 
replace month_d = subinstr(month_d,"/","",.) 
g day_d= substr(death_date ,-7,3) 
replace day_d= subinstr( day_d,"/","",.) 
destring month_d,replace force
destring day_d,replace force

rename Yearofdeath year_d 

g month_i=substr(date_infection ,1,3) 
replace month_i = subinstr(month_i,"/","",.) 
g day_i= substr(date_infection ,-7,3) 
replace day_i= subinstr(  day_i,"/","",.) 
g year_i = substr(date_infection ,-4,4) 

destring month_i,replace force
destring day_i,replace force
destring year_i,replace force

replace month_i =. if  month_i >12
replace month_d =. if  month_d >12

g days_death_since_1_1_18 =  day_d - 1 + 30*(month_d-1) + 360*(year_d-1918) 
g days_infection_since_1_1_18 = day_i - 1 + 30*(month_i-1) + 360*(year_i-1918) 


*** regressors

g black= Race=="Black"
g white= Race=="White"

g male= sex=="male"	

destring HISCO_4 , force replace
g sales_service = HISCO_4 ==2 if HISCO_4 !=.
g  non_employed= HISCO_4 ==5 if HISCO_4 !=.
g  farmer = HISCO_4 ==3 if HISCO_4 !=.
g  production = HISCO_4 ==4 if HISCO_4 !=.
g  professionals = HISCO_4 ==1 if HISCO_4 !=.

label var sales_service "Occupation: sales-services" 
label var professionals "Occupation: professionals-managers" 
	
cap drop agegroup*	
gen agegroup=.
 label define agg , replace 
				local g 10
				local B 60
				local Ncohorts = ((`B'/`g')+1)
				forval x = 1/`Ncohorts' {
					replace agegroup=  `g'*(`x'-1)  if age >=`g'*(`x'-1) & age <= ((`g'*`x')-1)
					
					local a= `g'*(`x'-1)
					local b= `g'*(`x'-1)
					local c=  `g'*`x' -1
					label define agg `a'  "`b'-`c'" ,  add
					
					if `x'==`Ncohorts' {
						replace agegroup=`g'*(`x'-1) if age > `g'*(`x'-1) & age != .
					}	
					
				}
*
label values agegroup   agg
	levelsof agegroup , local(levels) 
  foreach l of local levels {
  	g agegroup_`l' = agegroup == `l'
	local laa :  label  agg  `l'
	label var  agegroup_`l' "Age: `laa'"
  }
 *
 
 levelsof town_num , local(levels) 
  foreach l of local levels {
  	g town_num_`l' = town_num == `l'
	local laa :  label  town_num `l'
	label var  town_num_`l' "Town: `laa'"
  }
  *
  
 g agegroup_0_5 =  inrange(age,0,5) if age!=.
 g agegroup_6_15 =  inrange(age,6,15) if age!=.
 g agegroup_16_29 =  inrange(age,16,29) if age!=.
  
  label var  agegroup_60 "age 60+" 
  
  
global ages agegroup_0 agegroup_10 agegroup_20 agegroup_30 agegroup_60	
global towns town_num_2 town_num_3 town_num_4 town_num_5 town_num_6 town_num_7 town_num_8


	run "/Users/eliemurard/Dropbox/Greek_catastrophe/Do_files/semipar.ado" 
	
*xi: semiparX died_early_2 black white  male if influenza==1, nonpar(age) ci level(90)
			
		*	cluster(province_num) degree(1) bwidth(10) ///
		*	xtitle("Share of refugees in 1928") 
	
	

*** REGRESSION 

	global option varlabels  tex plain fragment  bdec(3)  se   starloc(1) starlevels(10 5  1) nocenter
	
	cap drop  died_early
	g died_early =  days_death_since_1_1_18 <=288  /*(year_d ==1918 & month_d <= 10 & day_d <=20) */
	g died_early_2 =  days_death_since_1_1_18 <=284  /*(year_d ==1918 & month_d <= 10 & day_d <=20) */
	g died_early_3 =  days_death_since_1_1_18 <=281  /*(year_d ==1918 & month_d <= 10 & day_d <=20) */
	
	
	
	g died_later = days_death_since_1_1_18>=314    /*(year_d ==1918 & month_d >= 11 & day_d >=15) | ( year_d >=1919)*/
	
	
	
	qui su   days_death_since_1_1_18    if influenza==1 
	local av = round(r(mean), 0.01) 
	qui su   days_death_since_1_1_18    if influenza==1 &  professionals !=.
	local av_2 = round(r(mean), 0.01) 

		outreg,clear(table1)
	
	qui reg   days_death_since_1_1_18   black white  male $ages      if influenza==1
	outreg, merge(table1) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av'"   )
	
	qui reg   days_death_since_1_1_18   black white  male $ages   $towns   if influenza==1 
	outreg, merge(table1) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av'"   )
	
	qui reg   days_death_since_1_1_18 sales_service  professionals  black white  male $ages   $towns   if influenza==1 
	outreg, merge(table1) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av_2'"   )
	
	nois outreg ,   replay(table1) $option 
	nois outreg using  "table1.tex" ,   replay(table1) $option replace title(spanish death)
	
	
	qui su    died_early     if influenza==1 
	local av = round(r(mean), 0.01) 
	qui su    died_early     if influenza==1 &  professionals !=.
	local av_2 = round(r(mean), 0.01) 

		outreg,clear(table1)
	
	qui reg   died_early   black white  male $ages      if influenza==1
	outreg, merge(table1) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av'"   )
	
	qui reg   died_early  black white  male $ages   $towns   if influenza==1 
	outreg, merge(table1) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av'"   )
	
	qui reg   died_early  sales_service  professionals  black white  male $ages   $towns   if influenza==1 
	outreg, merge(table1) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av_2'"   )
	
	nois outreg ,   replay(table1) $option 
	nois outreg using  "table1_1.tex" ,   replay(table1) $option replace title(spanish death)
	
	qui su    died_early     if influenza==1 
	local av = round(r(mean), 0.01) 
	qui su    died_early     if influenza==1 &  professionals !=.
	local av_2 = round(r(mean), 0.01) 

	
	outreg,clear(table1)
	
	qui su     died_early_2    if influenza==1 
	local av = round(r(mean), 0.01) 
	

	
	qui reg   died_early_2  black white  male $ages      if influenza==1
	outreg, merge(table1) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av'"   )
	
	qui reg  died_early_2   black white  male $ages   $towns   if influenza==1 
	outreg, merge(table1) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av'"   )
	
	*qui reg   died_early_2 sales_service  professionals  black white  male $ages   $towns   if influenza==1 
	*outreg, merge(table1) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av_2'"   )
	
	nois outreg ,   replay(table1) $option 
	nois outreg using  "table1_2.tex" ,   replay(table1) $option replace title(spanish death)
	
	outreg,clear(table1)
	
	qui reg   died_early_3  black white  male $ages      if influenza==1
	outreg, merge(table1) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av'"   )
	
	qui reg  died_early_3   black white  male $ages   $towns   if influenza==1 
	outreg, merge(table1) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av'"   )
	
	qui reg   died_early_3 sales_service  professionals  black white  male $ages   $towns   if influenza==1 
	outreg, merge(table1) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av_2'"   )
	
	nois outreg ,   replay(table1) $option 
	nois outreg using  "table1_3.tex" ,   replay(table1) $option replace title(spanish death)
	
	
	
	
	
*** INFECTIONS 
	
	qui su   days_infection_since_1_1_18    if influenza==1 
	local av = round(r(mean), 0.01) 
	qui su   days_infection_since_1_1_18   if influenza==1 &  professionals !=.
	local av_2 = round(r(mean), 0.01) 

	
	replace days_infection_since_1_1_18 =. if days_infection_since_1_1_18 <0
	outreg,clear(table2)
	
	qui reg   days_infection_since_1_1_18   black white  male $ages      if influenza==1 
	outreg, merge(table2) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av'"   )
	
	qui reg   days_infection_since_1_1_18 black white  male $ages   $towns   if influenza==1 
	outreg, merge(table2) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av'"   )
	
	qui reg   days_infection_since_1_1_18 sales_service  professionals  black white  male $ages   $towns   if influenza==1 
	outreg, merge(table2) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av_2'"   )
	
	nois outreg ,   replay(table2) $option 
	
*OTHER DAYS
	
	qui su   days_infection_since_1_1_18    if influenza!=1 
	local av = round(r(mean), 0.01) 
	qui su   days_infection_since_1_1_18   if influenza!=1 &  professionals !=.
	local av_2 = round(r(mean), 0.01) 

	outreg,clear(table2)
	
	qui reg   days_death_since_1_1_18   black white  male $ages    if influenza!=1 
	outreg, merge(table2) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av'"   \ "test equality coeff", `tt') 
	
	qui reg   days_death_since_1_1_18   black white  male $ages   $towns   if influenza!=1 
	outreg, merge(table2) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av'"   \ "test equality coeff", `tt') 
	
	qui reg   days_death_since_1_1_18 sales_service  professionals  black white  male $ages   $towns   if influenza!=1 
	outreg, merge(table2) nod    ctitle("", "")  ${option} addrows("Average outcome", "`av'"   \ "test equality coeff", `tt') 
	nois outreg ,   replay(table2) $option 
	nois outreg using  "table2.tex" ,   replay(table2) $option replace title(other death)
	
	
	*nois outreg using  "${tables}/selection_mig_couples.tex" ,   replay(table1) $option replace 
	
	
		
		
		
