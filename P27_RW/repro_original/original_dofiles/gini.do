*Gini

clear
clear matrix
set mem 100m
set more off
use "C:\Documents and Settings\johanf\My Documents\Navorsing 1 Aug\Economic History\PhD Utrecht\1. Wealth in the Cape economy\value_sum.dta", clear

*Create variables

gen commodities = .
replace commodities = beesten + paarden + schapen
gen prodprim = .
replace prodprim = ploeg + koornharp + schuijt + emmers + graaven + geweer
gen prodsec = .
replace prodsec = brandewijnskeetels + waagen + aambeeld + bankschroef
gen conbasic = .
replace conbasic = balans + tang + stoven + kadels + stoel + broek
gen conluxury = .
replace conluxury = strijkijsters + boeken + horlogie + snuijfdoos + schilderij + spiegel + vogelkooi + ring


* Gini decomposition by type of asset
descogini total slaves commodities prodprim prodsec conbasic conluxury if(decade == 1700)
descogini total slaves commodities prodprim prodsec conbasic conluxury if(decade == 1710)
descogini total slaves commodities prodprim prodsec conbasic conluxury if(decade == 1720)
descogini total slaves commodities prodprim prodsec conbasic conluxury if(decade == 1730)
descogini total slaves commodities prodprim prodsec conbasic conluxury if(decade == 1740)
descogini total slaves commodities prodprim prodsec conbasic conluxury if(decade == 1750)
descogini total slaves commodities prodprim prodsec conbasic conluxury if(decade == 1760)
descogini total slaves commodities prodprim prodsec conbasic conluxury if(decade == 1770)
descogini total slaves commodities prodprim prodsec conbasic conluxury if(decade == 1780)
descogini total slaves commodities prodprim prodsec conbasic conluxury if(decade == 1790)
descogini total slaves commodities prodprim prodsec conbasic conluxury if(decade == 1800)
descogini total slaves commodities prodprim prodsec conbasic conluxury

*Gini decomposition by group
ginidesc total if decade == 1700, by(group)
ginidesc total if decade == 1710, by(group)
ginidesc total if decade == 1720, by(group)
ginidesc total if decade == 1730, by(group)
ginidesc total if decade == 1740, by(group)
ginidesc total if decade == 1750, by(group)
ginidesc total if decade == 1760, by(group)
ginidesc total if decade == 1770, by(group)
ginidesc total if decade == 1780, by(group)
ginidesc total if decade == 1790, by(group)
ginidesc total if decade == 1800, by(group)
ginidesc total, by(group)
