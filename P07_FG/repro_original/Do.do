*Green Fourie (2013)

drop if year == 1752 | year==1702 | year==1678 | year==1670

gen ly = log(output)

reg ly slavemales knechts widow females sons daughters

preserve

keep if slavemales < 6

reg ly slavemales knechts widow females sons daughters

restore

preserve

keep if slavemales > 5 & slavemales < 11
reg ly slavemales knechts widow females sons daughters

restore

preserve

keep if slavemales > 10 & slavemales < 16
reg ly slavemales knechts widow females sons daughters

restore

preserve

keep if slavemales > 15
reg ly slavemales knechts widow females sons daughters

restore
