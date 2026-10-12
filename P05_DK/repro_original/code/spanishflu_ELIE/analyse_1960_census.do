
use "/Volumes/Samsung_T5/LEAP_camp_data/census SA/census SA 1960/Stata Files/white60.dta",clear
g y= 1960-age
g y= 1960-age
collapse (sum) p urb, by(y)
scatter p y if inrange(y,1890,1930) , xline(1900 1910 1920 1930)

use "/Volumes/Samsung_T5/LEAP_camp_data/census SA/census SA 1960/Stata Files/white60.dta",clear
g y= 1960-age
g p=1
g bpl=birthpla  if inrange(birthpla,1,4)
collapse (sum) p urb, by(y  bpl)
label define bb 1 "Cape Province" 2 "Natal" 3"Transvaal" 4 "OFS", replace 
label values  bpl bb
scatter p y if inrange(y,1900,1930) & bpl==1 , xline(1900 1910 1920 1930) name(G1, replace) title("Cape Province")
scatter p y if inrange(y,1900,1930) & bpl==2 , xline(1900 1910 1920 1930) name(G2, replace)  title("Natal")
scatter p y if inrange(y,1900,1930) & bpl==3 , xline(1900 1910 1920 1930) name(G3, replace)  title("Transvaal" )
scatter p y if inrange(y,1900,1930) & bpl==4 , xline(1900 1910 1920 1930) name(G4, replace)  title("OFS")
graph combine G1 G2 G3 G4, xcommon  title("Number of whites indiv by birth cohorts and birthplace")
graph export "/Users/eliemurard/Dropbox/spanishflu/cohort_by_province.png",  width(1000) replace  

ta income


use "/Volumes/Samsung_T5/LEAP_camp_data/census SA/census SA 1960/Stata Files/white60.dta",clear
g y= 1960-age
g bpl=birthpla  if inrange(birthpla,1,4)

g edu_attain = . 
replace edu_attain = 0 if inlist(educ_lev,0,12)
replace edu_attain = 1 if inlist(educ_lev,11,1,2,3,4,5)
replace edu_attain = 2 if inlist(educ_lev,6,7,55)
replace edu_attain = 3 if inlist(educ_lev,8,9,54)
replace edu_attain = 4 if inlist(educ_lev,10,53,21,23)
replace edu_attain = 3 if inlist(educ_lev,51,52)
replace edu_attain = 5 if inlist(educ_lev,50)

replace edu_attain = 6 if  inlist(educ_lev,20,22,30,31,32,33,40,41)
replace edu_attain = 6 if  inrange(educ_lev,60,65)

label def ede 0 "no educ" 1"standard 5 or lower" 2"standard 6 or 7"  3 "standard 8 or 9" 4 "standard 10" 5 "standard 10 diploma" ///
6 "Bachelor or higher", replace 
label values edu_attain ede 

g tertiary= edu_attain == 6 if  edu_attain!=.
g standard10 = edu_attain>=4 if  edu_attain!=.
g standard8 = edu_attain>=3 if  edu_attain!=.

g standard10_dipl = edu_attain>=5 if  edu_attain!=.

g earning= 0 if income==0
replace earning =200 if inrange(income,1,4)
replace earning = 600 if inrange(income,5,8)
replace earning = 1000  if inrange(income,9,10)
replace earning =1400 if income==11
replace earning =1800 if income==12
replace earning =2500 if income==13
replace earning =3500 if income==14
replace earning = 5000 if inrange(income,15,16)
replace earning = 8000 if inrange(income,17,18)
replace earning = 12000 if inrange(income,19,22)

g inc_2500 = earning>= 2500 if earning!=. 
g inc_3500= earning>= 3500 if earning!=. 
g poor_600= earning <= 600 if earning!=. 

save temp,replace

collapse (mean) earning inc_* poor_600 tertiary standard10 standard10_dipl  standard8 , by(y sex bpl)

*scatter inc_2500 inc_3500 y if sex==1 & bpl==1 & inrange(y,1890,1930), xline(1900 1910 1920 1930)
*scatter poor_600  y if sex==1 & bpl==1 & inrange(y,1890,1930), xline(1900 1910 1920 1930)

scatter standard8  y if sex==1 & bpl==1 & inrange(y,1890,1930), xline(1900 1910 1920 1930) ///
 ytitle(share with std 8 or more)  title(standard 8 or more - White male ) name(G1, replace)
 
scatter  standard10 y if sex==1 & bpl==1 & inrange(y,1890,1930), xline(1900 1910 1920 1930) ///
 ytitle(share with std 10 or more)  title(standard 10 or more - Whites male ) name(G2, replace)

scatter  standard8 y if sex==2 & bpl==1 & inrange(y,1890,1930), xline(1900 1910 1920 1930) ///
 ytitle(share with std 8 or more)  title(standard 8 or more - Whites female) name(G3, replace)

 scatter  standard10 y if sex==2 & bpl==1 & inrange(y,1890,1930), xline(1900 1910 1920 1930) ///
 ytitle(share with std 10 or more)  title(standard 10 or more - Whites female ) name(G4, replace)

 graph combine G1 G3 G2 G4, xcommon  title("Average education by birth-cohort  in Cape Province")
 graph export "/Users/eliemurard/Dropbox/spanishflu/gender_edu_cape.png",  width(1000) replace  

 
scatter  standard10_dipl  y if sex==2 & bpl==1 & inrange(y,1890,1930), xline(1900 1910 1920 1930)



scatter earning y if sex==1 &  bpl==1 & inrange(y,1890,1930), xline(1900 1910 1920 1930) title(Average white male  income born in Cape Province)
 graph export "/Users/eliemurard/Dropbox/spanishflu/income_male_by_province.png",  width(1000) replace  

scatter earning y if sex==2 &  bpl==1  & inrange(y,1880,1940), xline(1900 1910 1920 1930)

use temp,replace
collapse (mean) earning inc_* poor_600 tertiary standard10 standard8 standard10_dipl , by(y )
scatter  standard10 y if inrange(y,1890,1930), xline(1900 1910 1920 1930) ///
 ytitle(share with std 10 or more)  title(Education standard 10 or more - All whites South-African)
 graph export "/Users/eliemurard/Dropbox/spanishflu/edu_10.png",  width(1000) replace  
scatter  standard8 y if inrange(y,1890,1930), xline(1900 1910 1920 1930) ///
 ytitle(share with std 8 or more)  title(Education standard 8 or more - All whites South-African)
 graph export "/Users/eliemurard/Dropbox/spanishflu/edu_8.png",  width(1000) replace  

 
scatter  earning y if inrange(y,1890,1930), xline(1900 1910 1920 1930)

scatter  standard10_dipl y if inrange(y,1890,1930), xline(1900 1910 1920 1930)
