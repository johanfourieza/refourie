		
*----------------------------------------------------------------------------------------------------------------------------------------------
*----------------------------------------------------------------------------------------------------------------------------------------------

                                                                * MRDOCK ANALYSIS*

*----------------------------------------------------------------------------------------------------------------------------------------------
*----------------------------------------------------------------------------------------------------------------------------------------------

*  I.   Correlating leader's birth region and Murdock's variables

*----------------------------------------------------------------------------------------------------------------------------------------------
*----------------------------------------------------------------------------------------------------------------------------------------------


clear
clear mata
set max_memory 32g, permanently
set matsize 11000, permanently 
 *cd "C:\Users\orxlm01\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld"

 
 
********************************************************************************
* Dataset with population 1800, capital and missions (calculated from GIS)
import delimited "1_murdock_capital_population_final.csv", clear 
replace d_mission=0 if d_mission==.
replace d_mission=1 if d_mission>1
replace d_capital=0 if d_capital==.
replace d_capital=1 if d_capital>1 /*because of Benins de facto and de jure capitals*/
replace d_leader=0 if d_leader==.
label var pop1800 "average population 1800 (hyde)"
replace d_leader=1 if d_leader>1

save "1_murdock_capital_population_final.dta", replace

 
*Pre-colonial Ethnicity-level variables

*****************************************************************************
* Jurisdictional Hierarchy beyond Local Community (i.e. centralization): v33
*****************************************************************************
tab v33
generate hierarchy =.
replace hierarchy=. if v33=="missing data"
replace hierarchy=0 if v33=="No levels"
replace hierarchy=1 if v33=="One levels"
replace hierarchy=2 if v33=="Two levels"
replace hierarchy=3 if v33=="Three levels"
label var hierarchy "v33, Jurisdictional Hierarchy beyond Local Community"


/*Ordered variable ranging from 0 to 3 indicating the number of jurisdictional levels (political complexity) in each society above
the local level. A 0 indicates stateless societies, 1 and 2 indicate petty and large paramount
chiefdoms (or their equivalent), 3 indicate large states. 
Source: Murdock (1967); variable code in the Ethnolinguistic Atlas v33; A revised version of Murdock’s Atlas has been made
available by J. Patrick Gray at:
http://eclectic.ss.uci.edu/~drwhite/worldcul/EthnographicAtlasWCRevisedByWorldCultures.sav.*/



************************************
*Centralization Indicator:
*******************************
generate centralization=.
replace centralization=1 if hierarchy==1 | hierarchy==2 | hierarchy==3
replace centralization=0 if hierarchy==0


***************
* Gathering: v1
***************
tab v1
generate gathering =.
replace gathering =0 if v1=="0-5% Dependence"
replace gathering =1 if v1=="6-15% Dependence"
replace gathering =1 if v1=="16-25% Dependence"
replace gathering =1 if v1=="26-35% Dependence"
replace gathering =1 if v1=="36-45% Dependence"
codebook gathering
label var gathering "v1, gathering dummy"

/*Binary index that indicates the reliance of the economy on "the collection
of wild plants and small land fauna." The index equals zero when the dependence is between
0% and 5%; the index equals one when dependence is greater than 5% dependence. Source:
Murdock (1967); variable code in the Ethnographic Atlas v1.*/

***************
* Hunting: v2 *
***************
codebook v2
generate hunting =.
replace hunting =0 if v2=="0-5% Dependence"
replace hunting =1 if v2=="6-15% Dependence"
replace hunting =1 if v2=="16-25% Dependence"
replace hunting =1 if v2=="26-35% Dependence"
replace hunting =1 if v2=="56-65% Dependence"

codebook hunting
label var hunting "v2, hunting dummy"

/*Binary index that indicates the intensity in hunting (including trapping and
fowling). The index equals zero when the dependence is between 0% and 5%; the index equals
one when dependence is greater than 5%. Source: Murdock (1967); variable code in the Ethnographic Atlas v2.*/

***************
* Fishing: v3 *
***************
codebook v3
generate fishing =.
replace fishing =0 if v3=="0-5% Dependence"
replace fishing =1 if v3=="6-15% Dependence"
replace fishing =1 if v3=="16-25% Dependence"
replace fishing =1 if v3=="26-35% Dependence"
replace fishing =1 if v3=="36-45% Dependence"
replace fishing =1 if v3=="56-65% Dependence"
replace fishing =1 if v3=="76-85% Dependence"

codebook fishing
label var fishing "v3, fishing dummy"

/*Binary index that indicates the intensity in fishing (including shell fishing and
the pursuit of large aquatic animals). The index equals zero when the dependence is between
0% and 5%; the index equals one when dependence is greater than 5%. Source: Murdock
(1967); variable code in the Ethnographic Atlas v3.
.*/


***************************
*Milking: v41
**************************

codebook v41
generate milking =.
replace milking =0 if v41=="little or no milking"
replace milking =1 if v41=="milked more often than sporadically"

codebook milking
label var milking "v41, milking"

/*Milking: Binary index that equals one when "domestic animals are milked more often
that sporadically" and zero when "little or no milking". Source: Murdock (1967); variable code
in the Ethnographic Atlas v41..*/

***************************
*Husbandry: v4
*************************
codebook v4
generate husbandry =.
replace husbandry =0 if v4=="0-5% Dependence"
replace husbandry =1 if v4=="6-15% Dependence"
replace husbandry =2 if v4=="16-25% Dependence"
replace husbandry =3 if v4=="26-35% Dependence"
replace husbandry =4 if v4=="36-45% Dependence"
replace husbandry =5 if v4=="46-55% Dependence"
replace husbandry =6 if v4=="56-65% Dependence"
replace husbandry =7 if v4=="66-75% Dependence"
replace husbandry =8 if v4=="86-100% Dependence"

codebook husbandry 
label var husbandry  "v4, husbandry"

/*0 − 9 scale index reflecting the percentage of subsistence coming
from animal husbandry for each ethnicity at the time of colonization. The index equals 0 when
there 0% − 5% dependence; 1 when there is 6% − 15% dependence; 2 when there is 16% − 25%
dependence; 3 when there is 26%−35% dependence; 4 when there is 36%−45% dependence; 5
when there is 46% − 55% dependence; 6 when there is 56% − 65% dependence; 7 when there is
66%−75% dependence; 8 when there is 76%−85% dependence; and 9 when there is 86%−100%
dependence. Source: Murdock (1967); variable code in the Ethnographic Atlas v4*/



*************************************
*Agriculture Dependence/intensity v5
*************************************
codebook v5

generate agricintensity =.
replace agricintensity =0 if v5=="0-5% Dependence"
replace agricintensity =1 if v5=="6-15% Dependence"
replace agricintensity =2 if v5=="16-25% Dependence"
replace agricintensity =3 if v5=="26-35% Dependence"
replace agricintensity =4 if v5=="36-45% Dependence"
replace agricintensity =5 if v5=="46-55% Dependence"
replace agricintensity=6 if v5=="56-65% Dependence"
replace agricintensity=7 if v5=="66-75% Dependence"
replace agricintensity =8 if v5=="86-100% Dependence"


codebook agricintensity
label var agricintensity  "v5, agricultural intensity"

/*0 − 9 scale index reflecting the intensity of agriculture.
"It includes penetration of the soil, planting, tending the growing crops, and harvesting but
not subsequent food preparation". The index equals 0 when there 0% − 5% dependence; 1
when there is 6% − 15% dependence; 2 when there is 16% − 25% dependence; 3 when there is
26% − 35% dependence; 4 when there is 36% − 45% dependence; 5 when there is 46% − 55%
dependence; 6 when there is 56% − 65% dependence; 7 when there is 66% − 75% dependence;
8 when there is 76% − 85% dependence; and 9 when there is 86% − 100% dependence. Source:
Murdock (1967); variable code in the Ethnographic Atlas v5.*/




************************
* Agriculture Type v28 *
************************
codebook v28
tab v28
generate agrictype =.

replace agrictype =0 if v28=="No agriculture"
replace agrictype =1 if v28=="Casual agriculture"
replace agrictype =2 if v28=="Extensive or shifting agriculture"
replace agrictype =3 if v28=="Intensive agriculture"
replace agrictype =4 if v28=="Intensive irrigated agriculture"


codebook agrictype
label var agrictype  "v28, intensity of agriculture"

/*0 − 9 scale index reflecting the intensity of agriculture.
"It includes penetration of the soil, planting, tending the growing crops, and harvesting but
not subsequent food preparation". The index equals 0 when there 0% − 5% dependence; 1
when there is 6% − 15% dependence; 2 when there is 16% − 25% dependence; 3 when there is
26% − 35% dependence; 4 when there is 36% − 45% dependence; 5 when there is 46% − 55%
dependence; 6 when there is 56% − 65% dependence; 7 when there is 66% − 75% dependence;
8 when there is 76% − 85% dependence; and 9 when there is 86% − 100% dependence. Source:
Murdock (1967); variable code in the Ethnographic Atlas v5.*/

************************
* Polygyny v8 *
************************
codebook v8
tab v8
generate polygyny =.

replace polygyny =0 if v8=="Independent nuclear family, monogamous"
replace polygyny =0 if v8=="Large extended families"
replace polygyny =0 if v8=="Minimal extended families"
replace polygyny =0 if v8=="Small extended families"

replace polygyny =. if v8=="Missing data"

replace polygyny =1 if v8=="Polygynous: unusual co-wives"
replace polygyny =1 if v8=="Polygynous: usual co-wives"
replace polygyny =1 if v8=="Independent nuclear family, polygyny"



codebook polygyny 
label var polygyny   "v8, polygyny "

/*Polygyny: Indicator that equals one when polygyny is practiced and zero otherwise.
Source: Murdock (1967); variable code in the Ethnographic Atlas v8..*/



************************
* Clan Communities v15 *
************************
codebook v15
tab v15

generate clancommunities =.
replace clancommunities =0 if v15=="No agriculture"
replace clancommunities=0 if v15=="Casual agriculture"
replace clancommunities =0 if v15=="Segmented comunities witout local exogamy"
replace clancommunities =0 if v15=="Agamous communities"
replace clancommunities =0 if v15=="Exogamous communities"
replace clancommunities =0 if v15=="Segmented communities"

replace clancommunities =1 if v15=="Clan communities, or clan barrios"

codebook clancommunities
label var clancommunities "v15, clan communities"

/* Indicator that equals one when Murdock’s community marriage
organization variable indicates that "clan communities or clan barrios" are present and zero
otherwise. Source: Murdock (1967); variable code in the Ethnographic Atlas v15*/



************************
* Settlement pattern v30 *
************************
codebook v30
tab v30

generate settlementpattern =.
replace settlementpattern =0 if v30=="Nomadic or fully migratory"
replace settlementpattern=1 if v30=="Seminomadic"
replace settlementpattern =2 if v30=="Semisedentary"
replace settlementpattern =3 if v30=="Compact but impermenant settlements"
replace settlementpattern =4 if v30=="Neighborhoods of dispersed family homesteads"
replace settlementpattern =5 if v30=="Separated hamlets, forming a single community"
replace settlementpattern =6 if v30=="Compact and relatively permanent"
replace settlementpattern =7 if v30=="Complex settlements"


codebook settlementpattern
label var settlementpattern "v30, settlement pattern"

/*  Changed scale. Ordered variable ranging from 1 to 8 quantifying "settlement
pattern of each group". 0 indicates fully nomadic (migratory) groups, 1 indicates semi-nomadic
groups, 2 indicates semi-sedentary groups, 3 identifies groups that live in compact and impermanent settlements, 4 indicates societies those in neighborhoods of dispersed family homes,
5 indicates for groups in separated hamlets forming a single community, 6 indicates societies
living in compact and relatively permanent settlements, and 7 denotes the groups residing in
complex settlements. Source: Murdock (1967); variable code in the Ethnographic Atlas v30.*/

*******************
/* Complex Settlements: Indicator that equals one for ethnicities living in compact and
relatively permanent settlements (v30 = 7) or in complex settlements (v30 = 8), and zero
otherwise. Source: Murdock (1967); variable code in the Ethnographic Atlas v30.**/
 
generate d_settlement=.
replace d_settlement=1 if settlementpattern==6 | settlementpattern==7
replace d_settlement=0 if settlementpattern==0 | settlementpattern==1  | settlementpattern==2  | settlementpattern==3  | settlementpattern==4  | settlementpattern==5







***************************************************
* Patrilineal Descent Type v43 *
***************************************************
codebook v43
tab v43

generate patrilineal =.
replace patrilineal =0 if v43=="ambilineal"
replace patrilineal=1 if v43=="bilateral"
replace patrilineal =2 if v43=="duolateral"
replace patrilineal =3 if v43=="matrilineal"
replace patrilineal =4 if v43=="mixed"
replace patrilineal =5 if v43=="patrilineal"


generate d_patrilineal=.
replace d_patrilineal=1 if patrilineal==5
replace d_patrilineal=0 if patrilineal==0 |  patrilineal==1 | patrilineal==2 |  patrilineal==3 | patrilineal==4 

codebook settlementpattern
label var settlementpattern "v43, patrilineal"

/*  Indicator that equals one if the society is characterized by
patrilineal descent and zero otherwise. Source: Murdock (1967); variable code in the Ethnographic Atlas v43.*/




***************************************************
* Class stratification v67*
***************************************************
codebook v67
tab v67

generate stratification =.
replace stratification =0 if v67=="no secondary type"
replace stratification=1 if v67=="elite"
replace stratification =2 if v67=="dual"
replace stratification =3 if v67=="complex"

codebook stratification
label var stratification "v67, class stratification"

/*  Class Stratification: Ordered variable ranging from 0 to 4 quantifying "the degree of class differentiation, excluding purely political and religious statuses". 
A zero score indicates "absence of significant class distinctions among freemen, ignoring variations in individual repute achieved through skill, valor, piety, or wisdom." 
A score of 1 indicates "the presence of wealth distinctions, based on possession or distribution of property, which however have not crystallized into distinct and hereditary social classes." 
A score of 2 indicates "elite stratification. in which an elite class derives its superior status from control over scarce resources, particularly land, and is thereby differentiated from a property-less proletariat or serf class". 
A score of 3 indicates a "dual stratification into a hereditary aristocracy and a lower class of ordinary commoners or freemen, where traditionally ascribed noble status is at least as decisive as control
over scarce resources. 
A score of 4 indicates "complex stratification into social classes correlated in large measure with extensive differentiation of occupational statuses." Source: Murdock
(1967); variable code in the Ethnographic Atlas v67.*/
 
 

***************************************************
* Slavery v70*
***************************************************
codebook v70
tab v70

generate slavery =.
replace slavery =0 if v70=="absence or near absence"
replace slavery=1 if v70=="incipient or nonhereditary"
replace slavery=2 if v70=="reported but type not identified"
replace slavery =3 if v70=="hereditary and socially significant"

generate d_slavery=.
replace d_slavery=1 if slavery==3 | slavery==2 | slavery==1
replace d_slavery=0 if slavery==0

codebook slavery
label var slavery "v70, slavery"

/*  : Indicator that equals one when some type of slavery (hereditary, incipient, or
significant) is present and zero when there it is absent or near absent. Source: Murdock (1967);
variable code in the Ethnographic Atlas v70; the construction of the index follows Fenske (2009).*/
  
 
 
***************************************************
* Elections v72*
***************************************************
codebook v72
tab v72

generate elections =.
replace elections =1 if v72=="Election or other formal consensus"
replace elections=0 if v72=="Absence of any such office"  |  v72=="Appointment by higher authority" |  v72=="Influence, wealth or social status" |  v72=="Informal consensus"  ///
 |  v72=="Matrilineal heir"  |  v72=="Patrilineal heir" |  v72=="Senority or age"

codebook elections
label var elections "v72, elections"

/* Indicator that equals 1 when succession to the office of the local headman is
conducted via "election or other formal consensus, nonhereditary" and zero otherwise. Source:
Murdock (1967); variable code in the Ethnographic Atlas v72.
*/
 
 
 
***************************************************
* Inheritance rules of property v74*
***************************************************
codebook v74
tab v74

generate rulesproperty =.
replace rulesproperty =1 if v74=="children, equally for both sexes" 

replace rulesproperty =1  if v74=="children, with daughters recieving less" 
replace rulesproperty =1  if v74=="matrilineal (sister's sons)" 
replace rulesproperty =1  if v74=="other matrilineal heirs" 
replace rulesproperty =1  if v74=="other patrilineal heirs" 
replace rulesproperty =1  if v74=="patrilineal (sons)" 
replace rulesproperty=0 if v74=="absence of individual property rights"  


codebook rulesproperty 
label var rulesproperty  "v74, inheritance rules of property"
save "1_murdockanddbirth_final.dta", replace




*******

//merge alsan's dataset for which she has calculated geographical variables at the ethnic elevel

import delimited "1_murdock_alsan(geo).csv", clear 
keep  name isocode lat lon name malaria_index meantemp r coast river meanalt city1800 lat lon province tsi
*drop _merge
merge m:1 name using "1_murdockanddbirth_final.dta"
tab _merge
keep if _merge==3

rename d_leader	d_birth
encode isocode, gen(iso2)


save "1_murdockanddbirth_final.dta", replace

****
//add variable with military information

import delimited "1_murdock_leader.csv", clear // leaders with name of tribe, idbirth and geo1birth
collapse  (count) count_leader=id_leader (sum) numbercoup d_foreign d_elite_ed d_universi d_military , by(name)
sort country_string
save "3_murdock_leader.dta", replace

use "1_murdockanddbirth_final.dta", clear 
drop _merge 
merge m:1 name using "3_murdock_leader.dta"
replace d_military=0 if d_military==. 
save "1_murdockanddbirth_final.dta", replace




// run regression

* (1) Region of birth of ALL leader
use "1_murdockanddbirth_final.dta", clear  



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
	 















