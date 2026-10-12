*Fourie Green (2013) filename: missingpeople.dta

*Only consider farmers
drop if output == 0
gen ly = log(output)
drop if year == 1752 | year==1702 | year==1678 | year==1670 | year == 1762 | year==1705 | year == 1716 | year ==1688
drop if district==4 & year==1723
drop if district==0

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
tabstat labwprod slawprod if wine!=0, by(district)
tabstat labwprod slawprod if year==1773 & dviti==1 & slaves!=0, by(district) stat(mean n)

*(grain)
gen grainreaped = wheatreaped + ryereaped + barleyreaped
gen labgprod = grainreaped/labour
gen slagprod = grainreaped/slavemales

*Table 2
tabstat slagprod labgprod if year>=1719 & vherd<1000 & dviti==0 & dsow!=0 & slavemales!=0, by(district) stat (mean n)

*Table 3
tabstat slawprod labwprod if year>=1719 & vherd<1000 & dsow==0 & dviti!=0 & slavemales!=0, by(district) stat (mean n)

*Table 4 - mixed farming
gen dmix = dsow + dviti
tabstat slagprod labgprod slawprod labwprod if year>=1719 & vherd<1000 & dmix!=0 & slavemales!=0, by(district) stat (mean n)

*Table 5
tabstat slagprod labgprod slawprod labwprod if year>=1719 & vherd<1000 & dmix!=0 & slavemales<6 & slaves!=0, by(district) stat (mean n)
tabstat slagprod labgprod slawprod labwprod if year>=1719 & vherd<1000 & dmix!=0 & slavemales>5, by(district) stat (mean n)
