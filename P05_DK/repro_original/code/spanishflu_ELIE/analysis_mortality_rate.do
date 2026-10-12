cd "/Users/eliemurard/Dropbox/spanishflu/"



use death_pop1911_town_age_sex_race,clear
collapse (sum) death* influenza* pop* , by( Town) 



foreach v of varlist death*  influenza* {
replace `v'=100* `v'/pop1911
}
*
foreach y in 1915 1916 1917 1918 1919 1920 {
g other_death_`y' = death`y' - influenza`y' 
}
*
g HP_inf= 29.49 if Town=="Cradock"
replace HP_inf=  30.9  if Town=="Mafeking"
replace HP_inf=  11.04 if Town=="Oudtshoorn"
replace HP = 26.48 if Town=="Paarl" 
replace HP = 38.97 if Town=="Queenstown"
replace HP = 12.52 if Town=="Kuruman"
g influenza= 10* ( influenza1918 + influenza1919 )


g urbanisation_1911= 100*(pop1911_urbancentre/pop1911 )

scatter influenza1918 pop1911 , mlabel(Town )  ylab(,angle(horizontal)) graphregion(color(white)) /// 
title("1918 death rate of Spanish influenza" "relative to 1911 population")  xtitle(Population in 1991) ytitle(Spanish influenza  Mortality rate)
graph export "mortality_pop1911.png", width(1000) replace  

twoway ( scatter influenza1918 other_death_1918 , mlabel(Town ))  || /// 
line other_death_1918 other_death_1918,   graphregion(color(white)) ///
  xtitle(Mortality rate due to other causes of death) ytitle(Spanish influenza Mortality rate) legend( order(2) label(1 "")  label(2 "45 degree line")  ) 
graph export "mortality_other.png", width(1000) replace  

twoway ( scatter influenza1918  urbanisation_1911, mlabel(Town )), name(inf1, replace) ///
title(Spanish influenza)  xtitle(share of population living in urban centre (>2000 pop) ) ytitle(Mortality rate) legend( label(1 "Spanish influenza")  label(2 "other causes")  ) 
twoway ( scatter other_death_1918 urbanisation_1911, mlabel(Town ) ),  name(other1, replace)  ///
title(Other causes)  xtitle(share of population living in urban centre (>2000 pop) ) ytitle(Mortality rate) legend( label(1 "Spanish influenza")  label(2 "other causes")  ) 
graph combine inf1 other1, xcommon title( Mortality rate in 1918 and urban share) title(1918)
graph export "mortality_urbanshare.png", width(1000) replace  


keep Town death1915 death1916 death1917 death1918 death1919 death1920
reshape long death, i(Town) j(year)
levelsof Town, local(t)
local i=1
foreach y of local t {
line death year  if (Town== "`y'"), sort  name(G__`i', replace) title(`y') xtitle(year) ytitle(Mortality rate) ///
				ylab(,angle(horizontal)) graphregion(color(white)) 
local i=1 +`i'
}
*
graph combine G__1 G__2 G__3 G__4 G__5 G__6, xcommon title(Annual Mortality rate with respect to 1911 population)
	graph export "timeseries.png", width(1000) replace  

/**/


* race town**


use death_pop1911_town_age_sex_race,clear
collapse (sum) death* influenza* pop* , by( race Town) 
foreach v of varlist death*  influenza* {
replace `v'=100* `v'/pop1911
}
*
foreach y in 1915 1916 1917 1918 1919 1920 {
g other_death_`y' = death`y' - influenza`y' 
}
*
graph bar influenza1918  other_death_1918 if Town=="Cradock", legend(label(1 "Spanish flu") label(2 "Other causes") ) over(race) name(G_1,replace) title(Cradock)  bar(1, color(red)) bar(2, color(gs13))    graphregion(color(white))  ylab(,angle(horizontal))
graph bar influenza1918 other_death_1918 if Town=="Kuruman", legend(label(1 "Spanish flu") label(2 "Other causes") ) over(race) name(G_2,replace) title(Kuruman)  bar(1, color(red)) bar(2, color(gs13))  graphregion(color(white))  ylab(,angle(horizontal))
graph bar influenza1918 other_death_1918 if Town=="Mafeking",legend(label(1 "Spanish flu") label(2 "Other causes") )  over(race) name(G_3,replace) title(Mafeking)   bar(1, color(red)) bar(2, color(gs13))  graphregion(color(white))  ylab(,angle(horizontal))
graph bar influenza1918 other_death_1918 if Town=="Oudtshoorn", legend(label(1 "Spanish flu") label(2 "Other causes") ) over(race)  name(G_4,replace) title(Oudtshoorn)   bar(1, color(red)) bar(2, color(gs13))  graphregion(color(white))  ylab(,angle(horizontal))
graph bar influenza1918 other_death_1918 if Town=="Paarl", legend(label(1 "Spanish flu") label(2 "Other causes") ) over(race)  name(G_5,replace) title(Paarl)   bar(1, color(red)) bar(2, color(gs13))  graphregion(color(white))  ylab(,angle(horizontal))
graph bar influenza1918 other_death_1918 if Town=="Queenstown",legend(label(1 "Spanish flu") label(2 "Other causes") )  over(race)  name(G_6,replace) title(Queenstown)   bar(1, color(red)) bar(2, color(gs13))  graphregion(color(white))  ylab(,angle(horizontal))

*graph combine G_1 G_2 G_3 G_4 G_5 G_6, xcommon title( Mortality rate in 1918 by town (relative to 1911 population))
*	graph export "town_race.png", width(1000) replace  

	grc1leg G_1 G_2 G_3 G_4 G_5 G_6, xcommon title(Mortality Rate in 1918 By Race and Town) legendfrom(G_1)  graphregion(color(white)) 
graph export "town_race.png", width(1000) replace 

	*
graph bar death1918 death1917 if Town=="Cradock", legend(label(1 "1918") label(2 "1917") ) over(race) name(G_1,replace) title(Cradock)  bar(1, color(red)) bar(2, color(gs13))   
graph bar death1918 death1917 if Town=="Kuruman", legend(label(1 "1918") label(2 "1917")  ) over(race) name(G_2,replace) title(Kuruman)  bar(1, color(red)) bar(2, color(gs13)) 
graph bar death1918 death1917 if Town=="Mafeking",legend(label(1 "1918") label(2 "1917")  )  over(race) name(G_3,replace) title(Mafeking)   bar(1, color(red)) bar(2, color(gs13)) 
graph bar death1918 death1917 if Town=="Oudtshoorn", legend(label(1 "1918") label(2 "1917")  ) over(race)  name(G_4,replace) title(Oudtshoorn)   bar(1, color(red)) bar(2, color(gs13))
graph bar death1918 death1917 if Town=="Paarl", legend(label(1 "1918") label(2 "1917") ) over(race)  name(G_5,replace) title(Paarl)   bar(1, color(red)) bar(2, color(gs13))
graph bar death1918 death1917 if Town=="Queenstown",legend(label(1 "1918") label(2 "1917")  )  over(race)  name(G_6,replace) title(Queenstown)   bar(1, color(red)) bar(2, color(gs13))

graph combine G_1 G_2 G_3 G_4 G_5 G_6, xcommon title(Annual Mortality Rate By Race and Town)
	graph export "town_race_1817.png", width(1000) replace  

*
	 
	
/* age*/

use death_pop1911_town_age_sex_race,clear
collapse (sum) death* influenza* pop* ,by(  agegroup ) 

*race*

foreach v of varlist death*  influenza* {
replace `v'=100* `v'/pop1911
}
*
foreach y in 1915 1916 1917 1918 1919 1920 {
g other_death_`y' = death`y' - influenza`y' 
}
*

gen age=.
replace age=2 if agegroup=="0-4"   
replace age=7 if agegroup=="5-9"   
replace age=12 if agegroup=="10-14" 
replace age=17 if agegroup=="15-19" 
replace age=22 if agegroup=="20-24" 
replace age=30 if agegroup=="25-34" 
replace age=42 if agegroup=="35-49" 
replace age=60 if agegroup=="50-69" 
replace age=70 if  agegroup=="70+" 

twoway connected influenza1918 other_death_1918  age ,sort  title(1918)	ylab(,angle(horizontal)) graphregion(color(white))  ///
legend( label(1 "Spanish influenza")  label(2 "other causes")  ) xtitle(age) ytitle(Mortality rate) ///
xlabel(2 "0-4" 7 "5-9" 12 "10-14" 17 "15-19" 22 "20-24" 30 "25-34" 42 "35-49"  60 "50-69"  70 "70+" ,angle(45)) 
	graph export "byage_1918.png", width(1000) replace  

twoway connected death1919  death1918  death1917  age ,sort title(all death)	ylab(,angle(horizontal)) graphregion(color(white))  ///
legend( label(1 "1919")  label(2 "1918")  label(3 "1917")  ) xtitle(age) ytitle(Mortality rate) ///
xlabel(2 "0-4" 7 "5-9" 12 "10-14" 17 "15-19" 22 "20-24" 30 "25-34" 42 "35-49"  60 "50-69"  70 "70+" ,angle(45)) 
	graph export "byage_years.png", width(1000) replace  
	
	
* sex *** 

use death_pop1911_town_age_sex_race,clear
collapse (sum) death* influenza* pop* ,by(  agegroup sex ) 	  
	  
foreach v of varlist death*  influenza* {
replace `v'=100* `v'/pop1911
}
foreach y in 1915 1916 1917 1918 1919 1920 {
g other_death_`y' = death`y' - influenza`y' 
}
gen age=.
replace age=2 if agegroup=="0-4"   
replace age=7 if agegroup=="5-9"   
replace age=12 if agegroup=="10-14" 
replace age=17 if agegroup=="15-19" 
replace age=22 if agegroup=="20-24" 
replace age=30 if agegroup=="25-34" 
replace age=42 if agegroup=="35-49" 
replace age=60 if agegroup=="50-69" 
replace age=70 if  agegroup=="70+"	  

twoway (line influenza1918   age if sex=="male" ,sort lpattern(dash) lcolor(gs0) ) || ///
	(line influenza1918  age if sex=="female" ,sort lpattern(solid) lcolor(gs11)) , ///
 	ylab(,angle(horizontal)) graphregion(color(white)) title(Spanish influenza 1918)  name(influen, replace) ///
legend( label(1 "male")  label(2 "female")  ) xtitle(age) ytitle(Mortality rate) ///
xlabel(2 "0-4" 7 "5-9" 12 "10-14" 17 "15-19" 22 "20-24" 30 "25-34" 42 "35-49"  60 "50-69"  70 "70+" ,angle(45)) 

twoway (line other_death_1918  age if sex=="male" , lpattern(dash) lcolor(gs0) sort ) || ///
	(line other_death_1918 age if sex=="female" , lpattern(solid) lcolor(gs11) sort ) ,  title(Other death 1918)  name(other, replace) ///
	ylab(,angle(horizontal)) graphregion(color(white))  ///
legend( label(1 "male")  label(2 "female")  ) xtitle(age) ytitle(Mortality rate) ///
xlabel(2 "0-4" 7 "5-9" 12 "10-14" 17 "15-19" 22 "20-24" 30 "25-34" 42 "35-49"  60 "50-69"  70 "70+" ,angle(45)) 

graph combine influen other, xcommon title(Mortality rate with respect to 1911 population)
	graph export "bysex.png", width(1000) replace  

** race

use death_pop1911_town_age_sex_race,clear
collapse (sum) death* influenza* pop* ,by(  agegroup race) 	  
	  
foreach v of varlist death*  influenza* {
replace `v'=100* `v'/pop1911
}
foreach y in 1915 1916 1917 1918 1919 1920 {
g other_death_`y' = death`y' - influenza`y' 
}
gen age=.
replace age=2 if agegroup=="0-4"   
replace age=7 if agegroup=="5-9"   
replace age=12 if agegroup=="10-14" 
replace age=17 if agegroup=="15-19" 
replace age=22 if agegroup=="20-24" 
replace age=30 if agegroup=="25-34" 
replace age=42 if agegroup=="35-49" 
replace age=60 if agegroup=="50-69" 
replace age=70 if  agegroup=="70+"	  

twoway (line influenza1918   age if race=="non-white" ,sort lpattern(dash) lcolor(gs0) ) || ///
	(line influenza1918  age if race=="white" ,sort lpattern(solid) lcolor(gs11)) , ///
 	ylab(,angle(horizontal)) graphregion(color(white)) title(Spanish influenza 1918)  name(influen, replace) ///
legend( label(1 "non-white")  label(2 "white")  ) xtitle(age) ytitle(Mortality rate) ///
xlabel(2 "0-4" 7 "5-9" 12 "10-14" 17 "15-19" 22 "20-24" 30 "25-34" 42 "35-49"  60 "50-69"  70 "70+" ,angle(45)) 

twoway (line other_death_1918  age if race=="non-white" ,sort lpattern(dash) lcolor(gs0)  ) || ///
	(line other_death_1918 age if race=="white" ,sort lpattern(solid) lcolor(gs11) ) ,  title(Other death 1918)  name(other, replace) ///
	ylab(,angle(horizontal)) graphregion(color(white))  ///
legend(label(1 "non-white")  label(2 "white")  ) xtitle(age) ytitle(Mortality rate) ///
xlabel(2 "0-4" 7 "5-9" 12 "10-14" 17 "15-19" 22 "20-24" 30 "25-34" 42 "35-49"  60 "50-69"  70 "70+" ,angle(45)) 

twoway (line influenza1917  age if race=="non-white" ,sort lpattern(dash) lcolor(gs0)  ) || ///
	(line influenza1917  age if race=="white" ,sort lpattern(solid) lcolor(gs11) ) ,  title(all death 1917)  name(m1917, replace) ///
	ylab(,angle(horizontal)) graphregion(color(white))  ///
legend(label(1 "non-white")  label(2 "white")  ) xtitle(age) ytitle(Mortality rate) ///
xlabel(2 "0-4" 7 "5-9" 12 "10-14" 17 "15-19" 22 "20-24" 30 "25-34" 42 "35-49"  60 "50-69"  70 "70+" ,angle(45)) 


graph combine influen other, xcommon title( Mortality rate with respect to the 1911 population)  graphregion(color(white)) 
	graph export "by_race.png", width(1000) replace  
