
/*************************************************************************
Author:		Jeanne Cillies

Overview:	This file cleans the occupation variable and assigns relevant HISCLASS codes
NB NOTE!!! IT WAS FOUND THAT THE OCCUPATION SMITH WAS AN ERRONEOUS MEASURE AND WAS ACTUALLY 
REFERRING TO THE SURNAME 'SMITH' RATHER THAN THE OCCUPATION. 'BLACKSMITH' WAS THE 
ACCURATE MEASURE. SO SMITH NEEDS TO BE DROPPED. DECIDED HERE TO CODE IT AS -1 SO 
THAT IT WOULD AUTOMATICALLY BE DROPPED.

Now covers 4 generations

Inputs:		"SAF 2014.dta"
						
Outputs:	SAF_2014_Occupations

Created:	3 July 2014
Updated:	37 September 2016

***************************************************************************/


****************************************************************************
*rename occupation occup
split occup, p(",")
order occup, b(occup1)

*rename f_occupation f_occup
split f_occup, p(",")
order f_occup, b(f_occup1)

*rename gf_occupation gf_occup
split gf_occup, p(",")
order gf_occup, b(gf_occup1)

*rename ggf_occupation ggf_occup
split ggf_occup, p(",")
order ggf_occup, b(ggf_occup1)

forvalues x = 1/9 {

gen occ`x'_hisclass =.

replace	occ`x'_hisclass	=	2	if 	occup`x'	=="accountant"
replace	occ`x'_hisclass	=	-1	if 	occup`x'	=="apprentice"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="artist"
replace	occ`x'_hisclass	=	-1	if 	occup`x'	=="assistant"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="attorney"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="auctioneer"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="baker"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="bank manager"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="barber"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="blacksmith"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="brewer"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="brickmaker"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="butcher"
replace	occ`x'_hisclass	=	11	if 	occup`x'	=="button maker"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="captain"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="carpenter"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="chemist"
replace	occ`x'_hisclass	=	5	if 	occup`x'	=="clerk"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="clockmaker"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="coachman"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="colonel"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="confectioner"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="constable"
replace	occ`x'_hisclass	=	3	if 	occup`x'	=="contractor"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="cook"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="cooper"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="coppersmith"
replace	occ`x'_hisclass	=	3	if 	occup`x'	=="corporal"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="dentist"
replace	occ`x'_hisclass	=	-1	if 	occup`x'	=="dresser"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="electrician"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="engineer"
replace	occ`x'_hisclass	=	8	if 	occup`x'	=="farmer"
replace	occ`x'_hisclass	=	10	if 	occup`x'	=="fisherman"
replace	occ`x'_hisclass	=	12	if 	occup`x'	=="gardener"
replace	occ`x'_hisclass	=	8	if 	occup`x'	=="grazier"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="greengrocer"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="gunsmith"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="hairdresser"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="innkeeper"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="jeweller"
replace	occ`x'_hisclass	=	11	if 	occup`x'	=="labourer"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="lieutenant"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="locksmith"
replace	occ`x'_hisclass	=	3	if 	occup`x'	=="manager"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="mason"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="mattress maker"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="merchant"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="miller"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="miner"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="minister"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="musician"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="organist"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="painter"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="physician"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="policeman"
replace	occ`x'_hisclass	=	3	if 	occup`x'	=="postmaster"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="printer"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="publisher"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="saddler"
replace	occ`x'_hisclass	=	11	if 	occup`x'	=="sailor"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="sculptor"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="secretary"
replace	occ`x'_hisclass	=	3	if 	occup`x'	=="sergeant"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="shipwright"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="shopkeeper"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="silversmith"
replace	occ`x'_hisclass	=	-1	if 	occup`x'	=="smith"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="soldier"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="solicitor"
replace	occ`x'_hisclass	=	3	if 	occup`x'	=="steward"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="surgeon"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="surveyor"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="tailor"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="tanner"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="teacher"
replace	occ`x'_hisclass	=	5	if 	occup`x'	=="telegraphist"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="turner"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="wheelwright"
replace	occ`x'_hisclass	=	10	if 	occup`x'	=="woodcutter"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="auditor"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="transport rider"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="bombardier"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="field cornet"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="general"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="craftsman"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="author"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="liquor merchant"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="wine merchant"
replace	occ`x'_hisclass	=	11	if 	occup`x'	=="boatswain"
replace	occ`x'_hisclass	=	11	if 	occup`x'	=="chief mate"
replace	occ`x'_hisclass	=	11	if 	occup`x'	=="ferryman"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="bookkeeper"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="stone mason"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="mill builder"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="road constructor"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="road-builder"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="cabinet maker"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="harbour master"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="sea-captain"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="commandant"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="pharmacist"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="deacon"
replace	occ`x'_hisclass	=	5	if 	occup`x'	=="chief clerk"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="master cooper"
replace	occ`x'_hisclass	=	8	if 	occup`x'	=="dairy farmer"
replace	occ`x'_hisclass	=	3	if 	occup`x'	=="port captain"
replace	occ`x'_hisclass	=	3	if 	occup`x'	=="shipping agent"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="medical doctor"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="economist"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="newspaper owner"
replace	occ`x'_hisclass	=	8	if 	occup`x'	=="farm owner"
replace	occ`x'_hisclass	=	8	if 	occup`x'	=="fruit farmer"
replace	occ`x'_hisclass	=	12	if 	occup`x'	=="farm labourer"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="diamond-cutter"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="superintendent"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="geologist"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="member of parliament"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="politician"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="local official"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="district councillor"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="councillor"
replace	occ`x'_hisclass	=	5	if 	occup`x'	=="paramount chief"
replace	occ`x'_hisclass	=	5	if 	occup`x'	=="prime minister"
replace	occ`x'_hisclass	=	5	if 	occup`x'	=="senator"
replace	occ`x'_hisclass	=	5	if 	occup`x'	=="State President"
replace	occ`x'_hisclass	=	5	if 	occup`x'	=="mayor"
replace	occ`x'_hisclass	=	5	if 	occup`x'	=="governor"
replace	occ`x'_hisclass	=	5	if 	occup`x'	=="commissioner"
replace	occ`x'_hisclass	=	5	if 	occup`x'	=="commissioner of commerce"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="guardian"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="bodyguard"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="harness-maker"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="hatmaker"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="principal"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="headmistress"
replace	occ`x'_hisclass	=	12	if 	occup`x'	=="stable boy"
replace	occ`x'_hisclass	=	11	if 	occup`x'	=="table servant"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="judge"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="advocate"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="jurist"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="magistrate"
replace	occ`x'_hisclass	=	11	if 	occup`x'	=="slave"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="law agent"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="magistrate's clerk"
replace	occ`x'_hisclass	=	8	if 	occup`x'	=="sheepfarmer"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="major"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="assistant surgeon"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="messenger of the court"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="ensign"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="digger"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="diamond digger"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="missionary"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="transport driver"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="transporter"
replace	occ`x'_hisclass	=	5	if 	occup`x'	=="town clerk"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="Boer commandant"
replace	occ`x'_hisclass	=	5	if 	occup`x'	=="assistant merchant"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="snuff dealer"
replace	occ`x'_hisclass	=	3	if 	occup`x'	=="overseer"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="chief detective"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="police horseman"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="peace officer"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="sheriff"
replace	occ`x'_hisclass	=	5	if 	occup`x'	=="prison warder"
replace	occ`x'_hisclass	=	5	if 	occup`x'	=="radio-omroeper"
replace	occ`x'_hisclass	=	5	if 	occup`x'	=="railway officer"
replace	occ`x'_hisclass	=	5	if 	occup`x'	=="railway official"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="sick comforter"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="saddle and harness maker"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="sail-maker"
replace	occ`x'_hisclass	=	1	if 	occup`x'	=="church secretary"
replace	occ`x'_hisclass	=	3	if 	occup`x'	=="ships captain"
replace	occ`x'_hisclass	=	3	if 	occup`x'	=="(sea-) captain"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="ship's cabin boy"
replace	occ`x'_hisclass	=	7	if 	occup`x'	=="cobbler"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="signal man"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="arquebusier"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="artillerist"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="century"
replace	occ`x'_hisclass	=	9	if 	occup`x'	=="dragoon"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="head surgeon"
replace	occ`x'_hisclass	=	6	if 	occup`x'	=="explosives expert"
replace	occ`x'_hisclass	=	6	if 	occup`x'	=="gold prospector"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="surveyor-general"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="lecturer"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="lumberman"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="professor"
replace	occ`x'_hisclass	=	11	if 	occup`x'	=="wigmaker"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="wholesale merchant"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="boardinghouse keeper"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="general dealer"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="head merchant"
replace	occ`x'_hisclass	=	4	if 	occup`x'	=="tavern-keeper"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="playwright"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="poet"
replace	occ`x'_hisclass	=	2	if 	occup`x'	=="editor"

}

forvalues x = 1/9 {

gen f_occ`x'_hisclass =.

replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="accountant"
replace	f_occ`x'_hisclass	=	-1	if 	f_occup`x'	=="apprentice"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="artist"
replace	f_occ`x'_hisclass	=	-1	if 	f_occup`x'	=="assistant"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="attorney"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="auctioneer"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="baker"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="bank manager"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="barber"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="blacksmith"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="brewer"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="brickmaker"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="butcher"
replace	f_occ`x'_hisclass	=	11	if 	f_occup`x'	=="button maker"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="captain"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="carpenter"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="chemist"
replace	f_occ`x'_hisclass	=	5	if 	f_occup`x'	=="clerk"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="clockmaker"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="coachman"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="colonel"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="confectioner"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="constable"
replace	f_occ`x'_hisclass	=	3	if 	f_occup`x'	=="contractor"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="cook"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="cooper"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="coppersmith"
replace	f_occ`x'_hisclass	=	3	if 	f_occup`x'	=="corporal"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="dentist"
replace	f_occ`x'_hisclass	=	-1	if 	f_occup`x'	=="dresser"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="electrician"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="engineer"
replace	f_occ`x'_hisclass	=	8	if 	f_occup`x'	=="farmer"
replace	f_occ`x'_hisclass	=	10	if 	f_occup`x'	=="fisherman"
replace	f_occ`x'_hisclass	=	12	if 	f_occup`x'	=="gardener"
replace	f_occ`x'_hisclass	=	8	if 	f_occup`x'	=="grazier"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="greengrocer"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="gunsmith"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="hairdresser"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="innkeeper"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="jeweller"
replace	f_occ`x'_hisclass	=	11	if 	f_occup`x'	=="labourer"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="lieutenant"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="locksmith"
replace	f_occ`x'_hisclass	=	3	if 	f_occup`x'	=="manager"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="mason"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="mattress maker"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="merchant"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="miller"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="miner"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="minister"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="musician"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="organist"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="painter"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="physician"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="policeman"
replace	f_occ`x'_hisclass	=	3	if 	f_occup`x'	=="postmaster"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="printer"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="publisher"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="saddler"
replace	f_occ`x'_hisclass	=	11	if 	f_occup`x'	=="sailor"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="sculptor"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="secretary"
replace	f_occ`x'_hisclass	=	3	if 	f_occup`x'	=="sergeant"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="shipwright"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="shopkeeper"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="silversmith"
replace	f_occ`x'_hisclass	=	-1	if 	f_occup`x'	=="smith"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="soldier"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="solicitor"
replace	f_occ`x'_hisclass	=	3	if 	f_occup`x'	=="steward"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="surgeon"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="surveyor"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="tailor"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="tanner"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="teacher"
replace	f_occ`x'_hisclass	=	5	if 	f_occup`x'	=="telegraphist"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="turner"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="wheelwright"
replace	f_occ`x'_hisclass	=	10	if 	f_occup`x'	=="woodcutter"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="auditor"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="transport rider"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="bombardier"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="field cornet"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="general"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="craftsman"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="author"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="liquor merchant"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="wine merchant"
replace	f_occ`x'_hisclass	=	11	if 	f_occup`x'	=="boatswain"
replace	f_occ`x'_hisclass	=	11	if 	f_occup`x'	=="chief mate"
replace	f_occ`x'_hisclass	=	11	if 	f_occup`x'	=="ferryman"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="bookkeeper"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="stone mason"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="mill builder"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="road constructor"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="road-builder"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="cabinet maker"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="harbour master"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="sea-captain"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="commandant"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="pharmacist"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="deacon"
replace	f_occ`x'_hisclass	=	5	if 	f_occup`x'	=="chief clerk"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="master cooper"
replace	f_occ`x'_hisclass	=	8	if 	f_occup`x'	=="dairy farmer"
replace	f_occ`x'_hisclass	=	3	if 	f_occup`x'	=="port captain"
replace	f_occ`x'_hisclass	=	3	if 	f_occup`x'	=="shipping agent"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="medical doctor"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="economist"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="newspaper owner"
replace	f_occ`x'_hisclass	=	8	if 	f_occup`x'	=="farm owner"
replace	f_occ`x'_hisclass	=	8	if 	f_occup`x'	=="fruit farmer"
replace	f_occ`x'_hisclass	=	12	if 	f_occup`x'	=="farm labourer"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="diamond-cutter"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="superintendent"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="geologist"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="member of parliament"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="politician"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="local official"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="district councillor"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="councillor"
replace	f_occ`x'_hisclass	=	5	if 	f_occup`x'	=="paramount chief"
replace	f_occ`x'_hisclass	=	5	if 	f_occup`x'	=="prime minister"
replace	f_occ`x'_hisclass	=	5	if 	f_occup`x'	=="senator"
replace	f_occ`x'_hisclass	=	5	if 	f_occup`x'	=="State President"
replace	f_occ`x'_hisclass	=	5	if 	f_occup`x'	=="mayor"
replace	f_occ`x'_hisclass	=	5	if 	f_occup`x'	=="governor"
replace	f_occ`x'_hisclass	=	5	if 	f_occup`x'	=="commissioner"
replace	f_occ`x'_hisclass	=	5	if 	f_occup`x'	=="commissioner of commerce"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="guardian"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="bodyguard"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="harness-maker"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="hatmaker"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="principal"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="headmistress"
replace	f_occ`x'_hisclass	=	12	if 	f_occup`x'	=="stable boy"
replace	f_occ`x'_hisclass	=	11	if 	f_occup`x'	=="table servant"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="judge"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="advocate"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="jurist"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="magistrate"
replace	f_occ`x'_hisclass	=	11	if 	f_occup`x'	=="slave"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="law agent"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="magistrate's clerk"
replace	f_occ`x'_hisclass	=	8	if 	f_occup`x'	=="sheepfarmer"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="major"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="assistant surgeon"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="messenger of the court"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="ensign"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="digger"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="diamond digger"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="missionary"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="transport driver"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="transporter"
replace	f_occ`x'_hisclass	=	5	if 	f_occup`x'	=="town clerk"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="Boer commandant"
replace	f_occ`x'_hisclass	=	5	if 	f_occup`x'	=="assistant merchant"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="snuff dealer"
replace	f_occ`x'_hisclass	=	3	if 	f_occup`x'	=="overseer"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="chief detective"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="police horseman"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="peace officer"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="sheriff"
replace	f_occ`x'_hisclass	=	5	if 	f_occup`x'	=="prison warder"
replace	f_occ`x'_hisclass	=	5	if 	f_occup`x'	=="radio-omroeper"
replace	f_occ`x'_hisclass	=	5	if 	f_occup`x'	=="railway officer"
replace	f_occ`x'_hisclass	=	5	if 	f_occup`x'	=="railway official"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="sick comforter"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="saddle and harness maker"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="sail-maker"
replace	f_occ`x'_hisclass	=	1	if 	f_occup`x'	=="church secretary"
replace	f_occ`x'_hisclass	=	3	if 	f_occup`x'	=="ships captain"
replace	f_occ`x'_hisclass	=	3	if 	f_occup`x'	=="(sea-) captain"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="ship's cabin boy"
replace	f_occ`x'_hisclass	=	7	if 	f_occup`x'	=="cobbler"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="signal man"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="arquebusier"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="artillerist"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="century"
replace	f_occ`x'_hisclass	=	9	if 	f_occup`x'	=="dragoon"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="head surgeon"
replace	f_occ`x'_hisclass	=	6	if 	f_occup`x'	=="explosives expert"
replace	f_occ`x'_hisclass	=	6	if 	f_occup`x'	=="gold prospector"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="surveyor-general"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="lecturer"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="lumberman"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="professor"
replace	f_occ`x'_hisclass	=	11	if 	f_occup`x'	=="wigmaker"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="wholesale merchant"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="boardinghouse keeper"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="general dealer"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="head merchant"
replace	f_occ`x'_hisclass	=	4	if 	f_occup`x'	=="tavern-keeper"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="playwright"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="poet"
replace	f_occ`x'_hisclass	=	2	if 	f_occup`x'	=="editor"

}
forvalues x = 1/6 {

gen gf_occ`x'_hisclass =.

replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="accountant"
replace	gf_occ`x'_hisclass	=	-1	if 	gf_occup`x'	=="apprentice"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="artist"
replace	gf_occ`x'_hisclass	=	-1	if 	gf_occup`x'	=="assistant"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="attorney"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="auctioneer"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="baker"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="bank manager"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="barber"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="blacksmith"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="brewer"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="brickmaker"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="butcher"
replace	gf_occ`x'_hisclass	=	11	if 	gf_occup`x'	=="button maker"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="captain"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="carpenter"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="chemist"
replace	gf_occ`x'_hisclass	=	5	if 	gf_occup`x'	=="clerk"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="clockmaker"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="coachman"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="colonel"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="confectioner"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="constable"
replace	gf_occ`x'_hisclass	=	3	if 	gf_occup`x'	=="contractor"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="cook"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="cooper"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="coppersmith"
replace	gf_occ`x'_hisclass	=	3	if 	gf_occup`x'	=="corporal"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="dentist"
replace	gf_occ`x'_hisclass	=	-1	if 	gf_occup`x'	=="dresser"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="electrician"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="engineer"
replace	gf_occ`x'_hisclass	=	8	if 	gf_occup`x'	=="farmer"
replace	gf_occ`x'_hisclass	=	10	if 	gf_occup`x'	=="fisherman"
replace	gf_occ`x'_hisclass	=	12	if 	gf_occup`x'	=="gardener"
replace	gf_occ`x'_hisclass	=	8	if 	gf_occup`x'	=="grazier"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="greengrocer"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="gunsmith"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="hairdresser"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="innkeeper"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="jeweller"
replace	gf_occ`x'_hisclass	=	11	if 	gf_occup`x'	=="labourer"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="lieutenant"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="locksmith"
replace	gf_occ`x'_hisclass	=	3	if 	gf_occup`x'	=="manager"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="mason"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="mattress maker"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="merchant"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="miller"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="miner"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="minister"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="musician"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="organist"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="painter"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="physician"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="policeman"
replace	gf_occ`x'_hisclass	=	3	if 	gf_occup`x'	=="postmaster"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="printer"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="publisher"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="saddler"
replace	gf_occ`x'_hisclass	=	11	if 	gf_occup`x'	=="sailor"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="sculptor"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="secretary"
replace	gf_occ`x'_hisclass	=	3	if 	gf_occup`x'	=="sergeant"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="shipwright"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="shopkeeper"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="silversmith"
replace	gf_occ`x'_hisclass	=	-1	if 	gf_occup`x'	=="smith"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="soldier"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="solicitor"
replace	gf_occ`x'_hisclass	=	3	if 	gf_occup`x'	=="steward"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="surgeon"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="surveyor"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="tailor"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="tanner"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="teacher"
replace	gf_occ`x'_hisclass	=	5	if 	gf_occup`x'	=="telegraphist"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="turner"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="wheelwright"
replace	gf_occ`x'_hisclass	=	10	if 	gf_occup`x'	=="woodcutter"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="auditor"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="transport rider"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="bombardier"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="field cornet"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="general"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="craftsman"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="author"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="liquor merchant"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="wine merchant"
replace	gf_occ`x'_hisclass	=	11	if 	gf_occup`x'	=="boatswain"
replace	gf_occ`x'_hisclass	=	11	if 	gf_occup`x'	=="chief mate"
replace	gf_occ`x'_hisclass	=	11	if 	gf_occup`x'	=="ferryman"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="bookkeeper"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="stone mason"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="mill builder"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="road constructor"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="road-builder"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="cabinet maker"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="harbour master"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="sea-captain"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="commandant"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="pharmacist"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="deacon"
replace	gf_occ`x'_hisclass	=	5	if 	gf_occup`x'	=="chief clerk"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="master cooper"
replace	gf_occ`x'_hisclass	=	8	if 	gf_occup`x'	=="dairy farmer"
replace	gf_occ`x'_hisclass	=	3	if 	gf_occup`x'	=="port captain"
replace	gf_occ`x'_hisclass	=	3	if 	gf_occup`x'	=="shipping agent"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="medical doctor"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="economist"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="newspaper owner"
replace	gf_occ`x'_hisclass	=	8	if 	gf_occup`x'	=="farm owner"
replace	gf_occ`x'_hisclass	=	8	if 	gf_occup`x'	=="fruit farmer"
replace	gf_occ`x'_hisclass	=	12	if 	gf_occup`x'	=="farm labourer"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="diamond-cutter"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="superintendent"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="geologist"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="member of parliament"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="politician"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="local official"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="district councillor"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="councillor"
replace	gf_occ`x'_hisclass	=	5	if 	gf_occup`x'	=="paramount chief"
replace	gf_occ`x'_hisclass	=	5	if 	gf_occup`x'	=="prime minister"
replace	gf_occ`x'_hisclass	=	5	if 	gf_occup`x'	=="senator"
replace	gf_occ`x'_hisclass	=	5	if 	gf_occup`x'	=="State President"
replace	gf_occ`x'_hisclass	=	5	if 	gf_occup`x'	=="mayor"
replace	gf_occ`x'_hisclass	=	5	if 	gf_occup`x'	=="governor"
replace	gf_occ`x'_hisclass	=	5	if 	gf_occup`x'	=="commissioner"
replace	gf_occ`x'_hisclass	=	5	if 	gf_occup`x'	=="commissioner of commerce"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="guardian"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="bodyguard"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="harness-maker"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="hatmaker"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="principal"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="headmistress"
replace	gf_occ`x'_hisclass	=	12	if 	gf_occup`x'	=="stable boy"
replace	gf_occ`x'_hisclass	=	11	if 	gf_occup`x'	=="table servant"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="judge"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="advocate"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="jurist"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="magistrate"
replace	gf_occ`x'_hisclass	=	11	if 	gf_occup`x'	=="slave"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="law agent"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="magistrate's clerk"
replace	gf_occ`x'_hisclass	=	8	if 	gf_occup`x'	=="sheepfarmer"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="major"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="assistant surgeon"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="messenger of the court"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="ensign"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="digger"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="diamond digger"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="missionary"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="transport driver"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="transporter"
replace	gf_occ`x'_hisclass	=	5	if 	gf_occup`x'	=="town clerk"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="Boer commandant"
replace	gf_occ`x'_hisclass	=	5	if 	gf_occup`x'	=="assistant merchant"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="snuff dealer"
replace	gf_occ`x'_hisclass	=	3	if 	gf_occup`x'	=="overseer"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="chief detective"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="police horseman"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="peace officer"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="sheriff"
replace	gf_occ`x'_hisclass	=	5	if 	gf_occup`x'	=="prison warder"
replace	gf_occ`x'_hisclass	=	5	if 	gf_occup`x'	=="radio-omroeper"
replace	gf_occ`x'_hisclass	=	5	if 	gf_occup`x'	=="railway officer"
replace	gf_occ`x'_hisclass	=	5	if 	gf_occup`x'	=="railway official"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="sick comforter"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="saddle and harness maker"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="sail-maker"
replace	gf_occ`x'_hisclass	=	1	if 	gf_occup`x'	=="church secretary"
replace	gf_occ`x'_hisclass	=	3	if 	gf_occup`x'	=="ships captain"
replace	gf_occ`x'_hisclass	=	3	if 	gf_occup`x'	=="(sea-) captain"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="ship's cabin boy"
replace	gf_occ`x'_hisclass	=	7	if 	gf_occup`x'	=="cobbler"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="signal man"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="arquebusier"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="artillerist"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="century"
replace	gf_occ`x'_hisclass	=	9	if 	gf_occup`x'	=="dragoon"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="head surgeon"
replace	gf_occ`x'_hisclass	=	6	if 	gf_occup`x'	=="explosives expert"
replace	gf_occ`x'_hisclass	=	6	if 	gf_occup`x'	=="gold prospector"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="surveyor-general"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="lecturer"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="lumberman"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="professor"
replace	gf_occ`x'_hisclass	=	11	if 	gf_occup`x'	=="wigmaker"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="wholesale merchant"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="boardinghouse keeper"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="general dealer"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="head merchant"
replace	gf_occ`x'_hisclass	=	4	if 	gf_occup`x'	=="tavern-keeper"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="playwright"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="poet"
replace	gf_occ`x'_hisclass	=	2	if 	gf_occup`x'	=="editor"

}
forvalues x = 1/6 {

gen ggf_occ`x'_hisclass =.

replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="accountant"
replace	ggf_occ`x'_hisclass	=	-1	if 	ggf_occup`x'	=="apprentice"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="artist"
replace	ggf_occ`x'_hisclass	=	-1	if 	ggf_occup`x'	=="assistant"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="attorney"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="auctioneer"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="baker"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="bank manager"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="barber"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="blacksmith"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="brewer"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="brickmaker"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="butcher"
replace	ggf_occ`x'_hisclass	=	11	if 	ggf_occup`x'	=="button maker"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="captain"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="carpenter"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="chemist"
replace	ggf_occ`x'_hisclass	=	5	if 	ggf_occup`x'	=="clerk"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="clockmaker"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="coachman"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="colonel"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="confectioner"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="constable"
replace	ggf_occ`x'_hisclass	=	3	if 	ggf_occup`x'	=="contractor"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="cook"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="cooper"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="coppersmith"
replace	ggf_occ`x'_hisclass	=	3	if 	ggf_occup`x'	=="corporal"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="dentist"
replace	ggf_occ`x'_hisclass	=	-1	if 	ggf_occup`x'	=="dresser"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="electrician"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="engineer"
replace	ggf_occ`x'_hisclass	=	8	if 	ggf_occup`x'	=="farmer"
replace	ggf_occ`x'_hisclass	=	10	if 	ggf_occup`x'	=="fisherman"
replace	ggf_occ`x'_hisclass	=	12	if 	ggf_occup`x'	=="gardener"
replace	ggf_occ`x'_hisclass	=	8	if 	ggf_occup`x'	=="grazier"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="greengrocer"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="gunsmith"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="hairdresser"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="innkeeper"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="jeweller"
replace	ggf_occ`x'_hisclass	=	11	if 	ggf_occup`x'	=="labourer"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="lieutenant"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="locksmith"
replace	ggf_occ`x'_hisclass	=	3	if 	ggf_occup`x'	=="manager"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="mason"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="mattress maker"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="merchant"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="miller"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="miner"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="minister"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="musician"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="organist"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="painter"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="physician"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="policeman"
replace	ggf_occ`x'_hisclass	=	3	if 	ggf_occup`x'	=="postmaster"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="printer"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="publisher"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="saddler"
replace	ggf_occ`x'_hisclass	=	11	if 	ggf_occup`x'	=="sailor"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="sculptor"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="secretary"
replace	ggf_occ`x'_hisclass	=	3	if 	ggf_occup`x'	=="sergeant"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="shipwright"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="shopkeeper"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="silversmith"
replace	ggf_occ`x'_hisclass	=	-1	if 	ggf_occup`x'	=="smith"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="soldier"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="solicitor"
replace	ggf_occ`x'_hisclass	=	3	if 	ggf_occup`x'	=="steward"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="surgeon"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="surveyor"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="tailor"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="tanner"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="teacher"
replace	ggf_occ`x'_hisclass	=	5	if 	ggf_occup`x'	=="telegraphist"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="turner"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="wheelwright"
replace	ggf_occ`x'_hisclass	=	10	if 	ggf_occup`x'	=="woodcutter"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="auditor"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="transport rider"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="bombardier"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="field cornet"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="general"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="craftsman"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="author"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="liquor merchant"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="wine merchant"
replace	ggf_occ`x'_hisclass	=	11	if 	ggf_occup`x'	=="boatswain"
replace	ggf_occ`x'_hisclass	=	11	if 	ggf_occup`x'	=="chief mate"
replace	ggf_occ`x'_hisclass	=	11	if 	ggf_occup`x'	=="ferryman"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="bookkeeper"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="stone mason"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="mill builder"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="road constructor"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="road-builder"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="cabinet maker"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="harbour master"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="sea-captain"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="commandant"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="pharmacist"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="deacon"
replace	ggf_occ`x'_hisclass	=	5	if 	ggf_occup`x'	=="chief clerk"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="master cooper"
replace	ggf_occ`x'_hisclass	=	8	if 	ggf_occup`x'	=="dairy farmer"
replace	ggf_occ`x'_hisclass	=	3	if 	ggf_occup`x'	=="port captain"
replace	ggf_occ`x'_hisclass	=	3	if 	ggf_occup`x'	=="shipping agent"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="medical doctor"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="economist"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="newspaper owner"
replace	ggf_occ`x'_hisclass	=	8	if 	ggf_occup`x'	=="farm owner"
replace	ggf_occ`x'_hisclass	=	8	if 	ggf_occup`x'	=="fruit farmer"
replace	ggf_occ`x'_hisclass	=	12	if 	ggf_occup`x'	=="farm labourer"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="diamond-cutter"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="superintendent"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="geologist"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="member of parliament"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="politician"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="local official"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="district councillor"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="councillor"
replace	ggf_occ`x'_hisclass	=	5	if 	ggf_occup`x'	=="paramount chief"
replace	ggf_occ`x'_hisclass	=	5	if 	ggf_occup`x'	=="prime minister"
replace	ggf_occ`x'_hisclass	=	5	if 	ggf_occup`x'	=="senator"
replace	ggf_occ`x'_hisclass	=	5	if 	ggf_occup`x'	=="State President"
replace	ggf_occ`x'_hisclass	=	5	if 	ggf_occup`x'	=="mayor"
replace	ggf_occ`x'_hisclass	=	5	if 	ggf_occup`x'	=="governor"
replace	ggf_occ`x'_hisclass	=	5	if 	ggf_occup`x'	=="commissioner"
replace	ggf_occ`x'_hisclass	=	5	if 	ggf_occup`x'	=="commissioner of commerce"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="guardian"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="bodyguard"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="harness-maker"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="hatmaker"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="principal"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="headmistress"
replace	ggf_occ`x'_hisclass	=	12	if 	ggf_occup`x'	=="stable boy"
replace	ggf_occ`x'_hisclass	=	11	if 	ggf_occup`x'	=="table servant"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="judge"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="advocate"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="jurist"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="magistrate"
replace	ggf_occ`x'_hisclass	=	11	if 	ggf_occup`x'	=="slave"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="law agent"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="magistrate's clerk"
replace	ggf_occ`x'_hisclass	=	8	if 	ggf_occup`x'	=="sheepfarmer"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="major"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="assistant surgeon"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="messenger of the court"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="ensign"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="digger"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="diamond digger"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="missionary"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="transport driver"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="transporter"
replace	ggf_occ`x'_hisclass	=	5	if 	ggf_occup`x'	=="town clerk"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="Boer commandant"
replace	ggf_occ`x'_hisclass	=	5	if 	ggf_occup`x'	=="assistant merchant"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="snuff dealer"
replace	ggf_occ`x'_hisclass	=	3	if 	ggf_occup`x'	=="overseer"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="chief detective"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="police horseman"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="peace officer"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="sheriff"
replace	ggf_occ`x'_hisclass	=	5	if 	ggf_occup`x'	=="prison warder"
replace	ggf_occ`x'_hisclass	=	5	if 	ggf_occup`x'	=="radio-omroeper"
replace	ggf_occ`x'_hisclass	=	5	if 	ggf_occup`x'	=="railway officer"
replace	ggf_occ`x'_hisclass	=	5	if 	ggf_occup`x'	=="railway official"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="sick comforter"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="saddle and harness maker"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="sail-maker"
replace	ggf_occ`x'_hisclass	=	1	if 	ggf_occup`x'	=="church secretary"
replace	ggf_occ`x'_hisclass	=	3	if 	ggf_occup`x'	=="ships captain"
replace	ggf_occ`x'_hisclass	=	3	if 	ggf_occup`x'	=="(sea-) captain"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="ship's cabin boy"
replace	ggf_occ`x'_hisclass	=	7	if 	ggf_occup`x'	=="cobbler"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="signal man"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="arquebusier"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="artillerist"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="century"
replace	ggf_occ`x'_hisclass	=	9	if 	ggf_occup`x'	=="dragoon"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="head surgeon"
replace	ggf_occ`x'_hisclass	=	6	if 	ggf_occup`x'	=="explosives expert"
replace	ggf_occ`x'_hisclass	=	6	if 	ggf_occup`x'	=="gold prospector"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="surveyor-general"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="lecturer"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="lumberman"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="professor"
replace	ggf_occ`x'_hisclass	=	11	if 	ggf_occup`x'	=="wigmaker"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="wholesale merchant"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="boardinghouse keeper"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="general dealer"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="head merchant"
replace	ggf_occ`x'_hisclass	=	4	if 	ggf_occup`x'	=="tavern-keeper"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="playwright"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="poet"
replace	ggf_occ`x'_hisclass	=	2	if 	ggf_occup`x'	=="editor"

}

***DROP ECONOMICALLY INACTIVE***

replace occ1_hisclass=. if occ1_hisclass <1
replace occ2_hisclass=. if occ2_hisclass <1
replace occ3_hisclass=. if occ3_hisclass <1
replace occ4_hisclass=. if occ4_hisclass <1
replace occ5_hisclass=. if occ5_hisclass <1
replace occ6_hisclass=. if occ6_hisclass <1
replace occ7_hisclass=. if occ7_hisclass <1
replace occ8_hisclass=. if occ8_hisclass <1
replace occ9_hisclass=. if occ9_hisclass <1

replace f_occ1_hisclass=. if f_occ1_hisclass <1
replace f_occ2_hisclass=. if f_occ2_hisclass <1
replace f_occ3_hisclass=. if f_occ3_hisclass <1
replace f_occ4_hisclass=. if f_occ4_hisclass <1
replace f_occ5_hisclass=. if f_occ5_hisclass <1
replace f_occ6_hisclass=. if f_occ6_hisclass <1
replace f_occ7_hisclass=. if f_occ7_hisclass <1
replace f_occ8_hisclass=. if f_occ8_hisclass <1
replace f_occ9_hisclass=. if f_occ9_hisclass <1

replace gf_occ1_hisclass=. if gf_occ1_hisclass <1
replace gf_occ2_hisclass=. if gf_occ2_hisclass <1
replace gf_occ3_hisclass=. if gf_occ3_hisclass <1
replace gf_occ4_hisclass=. if gf_occ4_hisclass <1
replace gf_occ5_hisclass=. if gf_occ5_hisclass <1
replace gf_occ6_hisclass=. if gf_occ6_hisclass <1

replace ggf_occ1_hisclass=. if ggf_occ1_hisclass <1
replace ggf_occ2_hisclass=. if ggf_occ2_hisclass <1
replace ggf_occ3_hisclass=. if ggf_occ3_hisclass <1
replace ggf_occ4_hisclass=. if ggf_occ4_hisclass <1
replace ggf_occ5_hisclass=. if ggf_occ5_hisclass <1
replace ggf_occ6_hisclass=. if ggf_occ6_hisclass <1


***GENERATE LAST ACHIEVED HISCLASS***

set rmsg on
qui {
    gen prelast = .
    gen last = .
    foreach v of varlist occ*_hisclass {
        qui replace prelast = last if !mi(`v')
        qui replace last = `v' if !mi(`v')
    }
}
set rmsg off

replace last = prelast if last == -1 & prelast != -1
drop prelast

rename last last_hc
 
set rmsg on
qui {
    gen prelast = .
    gen last = .
    foreach v of varlist f_occ*_hisclass {
        qui replace prelast = last if !mi(`v')
        qui replace last = `v' if !mi(`v')
    }
}
set rmsg off

replace last = prelast if last == -1 & prelast != -1
drop prelast

rename last f_last_hc

set rmsg on
qui {
    gen prelast = .
    gen last = .
    foreach v of varlist gf_occ*_hisclass {
        qui replace prelast = last if !mi(`v')
        qui replace last = `v' if !mi(`v')
    }
}
set rmsg off

replace last = prelast if last == -1 & prelast != -1
drop prelast

rename last gf_last_hc

set rmsg on
qui {
    gen prelast = .
    gen last = .
    foreach v of varlist ggf_occ*_hisclass {
        qui replace prelast = last if !mi(`v')
        qui replace last = `v' if !mi(`v')
    }
}
set rmsg off

replace last = prelast if last == -1 & prelast != -1
drop prelast

rename last ggf_last_hc

* GROUP HISCLASS

gen last_hcgroup = .
replace last_hcgroup = 1 if last_hc == 1 | last_hc ==2
replace last_hcgroup = 2 if last_hc == 3 | last_hc ==4 | last_hc == 5
replace last_hcgroup = 3 if last_hc == 6 | last_hc ==7
replace last_hcgroup = 4 if last_hc == 8
replace last_hcgroup = 5 if last_hc == 9 | last_hc ==10 | last_hc == 11
la val last_hcgroup class1

gen f_last_hcgroup = .
replace f_last_hcgroup = 1 if f_last_hc == 1 | f_last_hc ==2
replace f_last_hcgroup = 2 if f_last_hc == 3 | f_last_hc ==4 | f_last_hc == 5
replace f_last_hcgroup = 3 if f_last_hc == 6 | f_last_hc ==7
replace f_last_hcgroup = 4 if f_last_hc == 8
replace f_last_hcgroup = 5 if f_last_hc == 9 | f_last_hc ==10 | f_last_hc == 11
la val f_last_hcgroup class1

gen gf_last_hcgroup = .
replace gf_last_hcgroup = 1 if gf_last_hc == 1 | gf_last_hc ==2
replace gf_last_hcgroup = 2 if gf_last_hc == 3 | gf_last_hc ==4 | gf_last_hc == 5
replace gf_last_hcgroup = 3 if gf_last_hc == 6 | gf_last_hc ==7
replace gf_last_hcgroup = 4 if gf_last_hc == 8
replace gf_last_hcgroup = 5 if gf_last_hc == 9 | gf_last_hc ==10 | gf_last_hc == 11
la val gf_last_hcgroup class1

gen ggf_last_hcgroup = .
replace ggf_last_hcgroup = 1 if ggf_last_hc == 1 | ggf_last_hc ==2
replace ggf_last_hcgroup = 2 if ggf_last_hc == 3 | ggf_last_hc ==4 | ggf_last_hc == 5
replace ggf_last_hcgroup = 3 if ggf_last_hc == 6 | ggf_last_hc ==7
replace ggf_last_hcgroup = 4 if ggf_last_hc == 8
replace ggf_last_hcgroup = 5 if ggf_last_hc == 9 | ggf_last_hc ==10 | ggf_last_hc == 11
la val ggf_last_hcgroup class1

***GENERATE HIGHEST ACHIEVED HISCLASS***

gen hhc = min(occ1_hisclass, occ2_hisclass, ///
occ3_hisclass, occ4_hisclass, occ5_hisclass, ///
occ6_hisclass, occ7_hisclass, occ8_hisclass)
tab hhc

gen f_hhc = min(f_occ1_hisclass, f_occ2_hisclass, ///
f_occ3_hisclass, f_occ4_hisclass, f_occ5_hisclass, ///
f_occ6_hisclass, f_occ7_hisclass, f_occ8_hisclass)
tab f_hhc


gen gf_hhc = min(gf_occ1_hisclass, gf_occ2_hisclass, ///
gf_occ3_hisclass, gf_occ4_hisclass, gf_occ5_hisclass, ///
gf_occ6_hisclass)
tab gf_hhc

gen ggf_hhc = min(ggf_occ1_hisclass, ggf_occ2_hisclass, ///
ggf_occ3_hisclass, ggf_occ4_hisclass, ggf_occ5_hisclass, ///
ggf_occ6_hisclass)
tab ggf_hhc

gen hhcgroup = .
replace hhcgroup = 1 if hhc == 1 | hhc ==2
replace hhcgroup = 2 if hhc == 3 | hhc ==4 | hhc == 5
replace hhcgroup = 3 if hhc == 6 | hhc ==7
replace hhcgroup = 4 if hhc == 8
replace hhcgroup = 5 if hhc == 9 | hhc ==10 | hhc == 11
la val hhcgroup class1

gen f_hhcgroup = .
replace f_hhcgroup = 1 if f_hhc == 1 | f_hhc ==2
replace f_hhcgroup = 2 if f_hhc == 3 | f_hhc ==4 | f_hhc == 5
replace f_hhcgroup = 3 if f_hhc == 6 | f_hhc ==7
replace f_hhcgroup = 4 if f_hhc == 8
replace f_hhcgroup = 5 if f_hhc == 9 | f_hhc ==10 | f_hhc == 11
la val f_hhcgroup class1

gen gf_hhcgroup = .
replace gf_hhcgroup = 1 if gf_hhc == 1 | gf_hhc ==2
replace gf_hhcgroup = 2 if gf_hhc == 3 | gf_hhc ==4 | gf_hhc == 5
replace gf_hhcgroup = 3 if gf_hhc == 6 | gf_hhc ==7
replace gf_hhcgroup = 4 if gf_hhc == 8
replace gf_hhcgroup = 5 if gf_hhc == 9 | gf_hhc ==10 | gf_hhc == 11
la val gf_hhcgroup class1

gen ggf_hhcgroup = .
replace ggf_hhcgroup = 1 if ggf_hhc == 1 | ggf_hhc ==2
replace ggf_hhcgroup = 2 if ggf_hhc == 3 | ggf_hhc ==4 | ggf_hhc == 5
replace ggf_hhcgroup = 3 if ggf_hhc == 6 | ggf_hhc ==7
replace ggf_hhcgroup = 4 if ggf_hhc == 8
replace ggf_hhcgroup = 5 if ggf_hhc == 9 | ggf_hhc ==10 | ggf_hhc == 11
la val ggf_hhcgroup class1
