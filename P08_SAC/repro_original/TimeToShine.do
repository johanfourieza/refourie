
use "C:\Users\User\Dropbox\Research\ELITE\Fourie Grundlingh Mariotti\SAC_FGM.dta"

*Drop unnecessary variables

drop year1 years2 years3 years4 years5 pounds1 pounds2 month1 months2 months3 months4 months5 inches1 inches2 extra extra2 days1 days2 days3 days4 days5

*Make years Stata-friendly

tostring birthday, gen (bday)
tostring birthmonth, gen (bmonth)
tostring birthyear, gen (byear)

gen addzeros = 0
tostring addzeros, gen(addzero)
gen newbirthday = addzero + bday if birthday > 0 & birthday <= 9
replace bday = newbirthday if newbirthday != ""

gen newbirthmonth = addzero + bmonth if birthmonth > 0 & birthmonth <= 9
replace bmonth = newbirthmonth if newbirthmonth != ""

drop newbirthday
drop newbirthmonth

gen birthdatefinal =  bday + bmonth + byear
gen dob = date(birthdatefinal, "DMY")
format dob %td

tostring eday, gen (eday1)
tostring emonth, gen (emonth1)
tostring eyear, gen (eyear1)

gen neweday = addzero + eday1 if eday > 0 & eday <= 9
replace eday1 = neweday if neweday != ""

gen newemonth = addzero + emonth1 if emonth > 0 & emonth <= 9
replace emonth1 = newemonth if newemonth != ""

drop neweday
drop newemonth

gen edatefinal =  eday1 + emonth1 + eyear1
gen doen = date(edatefinal, "DMY")
format doen %td

tostring dday, gen (dday1)
tostring dmonth, gen (dmonth1)
tostring dyear, gen (dyear1)

gen newdday = addzero + dday1 if dday > 0 & dday <= 9
replace dday1 = newdday if newdday != ""

gen newdmonth = addzero + dmonth1 if dmonth > 0 & dmonth <= 9
replace dmonth1 = newdmonth if newdmonth != ""

drop newdday
drop newdmonth

gen ddatefinal =  dday1 + dmonth1 + dyear1
gen dod = date(ddatefinal, "DMY")
format dod %td

gen agen = doen - dob
gen agen1 = agen/365
gen enlisttime = dod - doen

*Create new variable for day of dismissal

gen dod1 = doen + length
format dod1 %td

gen enlisttime1 = dod1 - doen

preserve

*Descriptives

gen dobyear = year(dob)

local var dobyear
sum `var', mean
local low=r(min)
local high=r(max)
local step=round((`high'-`low')/5)
twoway (kdensity `var' ), xlabel(`low'(`step')`high' , format(%ty))

drop if repeatlast==1



*Analysis of heights
drop if agen < 7300
drop if agen > 18250



