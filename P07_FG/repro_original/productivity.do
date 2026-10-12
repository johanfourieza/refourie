*Fourie (2013) filename: slaveproductivity.dta

*Only consider farmers
drop if output == 0
gen ly = log(output)
drop if year == 1752
drop if year==1702 
drop if year==1678 
drop if year==1670
drop if year == 1762
drop if year==1705
drop if year == 1716
drop if year ==1688
drop if district==4 & year==1723
drop if district==0
drop if females==2

preserve

*Generate dummies for farmers
gen dsow = 0
replace dsow = 1 if wheatsown > 0 | ryesown > 0 | barleysown > 0
gen dherd = 0
replace dherd = 1 if cattle > 0 | sheep > 0
gen dviti = 0
replace dviti = 1 if vineyards > 0
gen dmulti = 0
replace dmulti = 1 if wheatsown > 0 | ryesown > 0 | barleysown > 0 & cattle > 0 | sheep > 0 & vineyards > 0

gen vherd = vcattle + vsheep + vhorses

*Creating the Khoe
gen cattlekhoe = 0

*Jacobus Botha of Swellendam in 1771 owned 250 cattle, 50 Khoe and 23 slaves (amongst others)
*We assume more intensive use of Khoesan on frontier (Swellendam)
replace cattlekhoe = vherd/47.5 if slaves==0 & district==4
replace cattlekhoe = vherd/57.5 if slaves>0 & slaves<6 & district==4
replace cattlekhoe = vherd/67.5 if slaves>5& district==4

replace cattlekhoe = vherd/95 if slaves==0 & district==3
replace cattlekhoe = vherd/115 if slaves>0 & slaves<6 & district==3
replace cattlekhoe = vherd/135 if slaves>5 & district==3

replace cattlekhoe = vherd/142.5 if slaves==0 & district==2
replace cattlekhoe = vherd/172.5 if slaves>0 & slaves<6 & district==2
replace cattlekhoe = vherd/202.5 if slaves>5 & district==2

tabstat cattlekhoe, by(slaves) stat(n sum)

*Slaveproductivity (wine)
gen labour = cattlekhoe + slavemales
gen labwprod = wine/labour
gen slawprod = wine/slavemales

*Slaveproductivity (grain)
gen grainreaped = wheatreaped + ryereaped + barleyreaped
gen labgprod = grainreaped/labour
gen slagprod = grainreaped/slavemales

*Table 2
tabstat slagprod if year==1741 & dsow==1 & vherd<1000 & dviti==0 & slavemales!=0, by(district) stat(mean n)
tabstat slagprod if year>=1719 & dsow==1 & vherd<1000 & dviti==0 & slavemales!=0, by(district) stat(mean n)

tabstat slawprod if year==1773 & dviti==1 & dsow!=1 & vherd<1000 & slavemales!=0, by(district) stat(mean n)
tabstat slawprod if year>=1719 & dviti==1 & dsow!=1 & vherd<1000 & slavemales!=0, by(district) stat(mean n)

*Farming specialisation
gen dmix = dsow + dviti
gen mix = 0
replace mix = 1 if dsow == 1 & dviti == 0 & dherd == 0
replace mix = 4 if dsow == 1 & dviti == 1 & dherd == 0
replace mix = 4 if dsow == 1 & dviti == 1 & dherd == 1
replace mix = 2 if dsow == 0 & dviti == 1 & dherd == 0
replace mix = 2 if dsow == 0 & dviti == 1 & dherd == 1
replace mix = 3 if dsow == 0 & dviti == 0 & dherd == 1
replace mix = 1 if dsow == 1 & dviti == 0 & dherd == 1

*Opgaafrolle descriptives
tabstat hhsize slavemales knechts horses cattle wine grainreaped if year>=1719, by(district) stat(n mean)

*Table 5
tabstat slagprod slawprod if year>=1719 & vherd<1000 & dmix!=0 & slavemales<6 & slaves!=0, by(district) stat (mean n)
tabstat slagprod slawprod if year>=1719 & vherd<1000 & dmix!=0 & slavemales>5, by(district) stat (mean n)

*Regressions
drop if year<1719

reg ly females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.district

eststo: quietly regress ly knechts slavemales
eststo: quietly regress ly females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters
eststo: quietly regress ly females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.district
eststo: quietly regress ly females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.district i.year
eststo: quietly regress ly females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters cattlekhoe i.district i.year
esttab using productivity1.csv, ar2

eststo clear

*Economies of scale
gen size = 0
replace size = 0 if slavemales == 0
replace size = 1 if slavemales > 0 & slavemales < 6
replace size = 2 if slavemales > 5 & slavemales < 11
replace size = 3 if slavemales > 10 & slavemales < 21
replace size = 4 if slavemales > 20

tabstat hhsize slavemales knechts horses cattle vineyards wheatreaped , by(size) stat(mean)

eststo: quietly regress ly females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.size i.district i.year
eststo: xi: quietly regress ly females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.size i.district i.year
eststo: xi: quietly regress ly females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.size i.district i.year i.size*slavemales
eststo: xi: quietly regress ly females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.size i.district i.year i.size*slavemales i.district*slavemales
eststo: xi: quietly regress ly females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.size i.district i.year i.size*slavemales i.district*slavemales cattlekhoe
esttab using productivity2.csv, ar2

eststo clear

*Economies of scope

tabstat hhsize slavemales knechts horses cattle vineyards wheatreaped , by(mix) stat(mean)

eststo: xi: quietly regress ly females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.size i.district i.year i.mix
eststo: xi: quietly regress ly females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.size i.district i.year i.mix i.mix*slavemales
eststo: xi: quietly regress ly females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.size i.district i.year i.mix i.mix*slavemales i.size*slavemales i.district*slavemales cattlekhoe

preserve

drop if mix==0

char mix[omit] 3

eststo: xi: quietly regress ly females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.size i.district i.year i.mix
eststo: xi: quietly regress ly females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.size i.district i.year i.mix i.mix*slavemales
eststo: xi: quietly regress ly females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.size i.district i.year i.mix i.mix*slavemales i.size*slavemales i.district*slavemales cattlekhoe
esttab using productivity3.csv, ar2

eststo clear

restore

*Profitability

preserve

drop if mix==0

char mix[omit] 3

eststo: xi: quietly regress output females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.size i.district i.year i.mix
eststo: xi: quietly regress output females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.size i.district i.year i.mix i.mix*slavemales
eststo: xi: quietly regress output females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.size i.district i.year i.mix i.mix*slavemales i.size*slavemales i.district*slavemales
eststo: xi: quietly regress output females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.size i.district i.year i.mix i.mix*slavemales i.size*slavemales i.district*slavemales cattlekhoe
esttab using productivity4.csv, ar2

eststo clear

restore

*Green Fourie

preserve

char mix[omit] 3

eststo: xi: regress output females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters
eststo: xi: regress output females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.district i.year i.mix i.mix*slavemales i.district*slavemales
eststo: xi: regress output females widow sons daughters knechts slavemales slavefemales slavesons slavedaughters i.district i.year i.mix i.mix*slavemales i.district*slavemales cattlekhoe
esttab using greenfourie.csv, ar2

eststo clear

restore
