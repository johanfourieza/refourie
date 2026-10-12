*Descriptives

*Occupations

preserve

drop if region=="."

cibar wage, over1(regiondum)

estimates clear

eststo: quietly reg lwage afrikaans if age>18 & repeatlast==0 & (regiondum==5 | regiondum==9)
eststo: quietly reg lwage afrikaans age height weight married if age>18 & repeatlast==0
eststo: quietly reg lwage afrikaans age height weight married ib6.hisco ib5.regiondum if age>18 & repeatlast==0
eststo: quietly reg lwage afrikaans age height weight married ib6.hisco ib5.regiondum i.eyear  if age>18 & repeatlast==0
eststo: quietly reg lwage afrikaans age height weight married jewish catholic blue tattoo chestdiff black swim shoot ride ib6.hisco ib5.regiondum i.eyear  if age>18 & repeatlast==0
estout using fgm.txt, cells(b(star fmt(3)) t(par fmt(2))) stats(r2 N)

estimates clear

