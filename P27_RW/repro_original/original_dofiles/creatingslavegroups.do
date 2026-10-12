*Creating slave groups

use "C:\Documents and Settings\johanf\My Documents\Navorsing 1 Aug\Economic History\PhD Utrecht\1. Wealth in the Cape economy\opgaafrolle.dta"

drop if jaar == 1716
drop if jaar == 1682

generate slawe =  sm + sv + ss + sd

generate group = .
replace group = 1 if slawe == 0
replace group = 2 if slawe > 0 & slawe < 6
replace group = 3 if slawe > 5 & slawe < 16
replace group = 4 if slawe > 15
tab group jaar
