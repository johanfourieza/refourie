*census 1911
import excel "/Volumes/Samsung_T5/LEAP_camp_data/census SA/Census 1911.xlsx", sheet("Ages- Areas Combined") firstrow clear


	keep age -mixed_f

	g region= age if  ///
		age== "Cape Of Good Hope"  || ///
		age=="Natal"  || ///
		age=="Orange Free State"  || ///
		age=="The Union of South Africa"  || ///
		age=="Transvaal" 

	replace region=region[_n-1] if region ==""
	keep if age!=""
	
	foreach v of varlist total white_m white_f black_m black_f mixed_m mixed_f{
	destring `v', force replace
	}
	drop if total==.
	
	replace age="0" if age=="Under 1 Year"
	
	replace age="0, 4" if age=="Under 5"

	replace age= proper(age)
	
	replace age= "60, 64"  if age=="60, 59"
	
	drop if age=="0"|age=="1"|age=="2"|age=="3"|age=="4"


	
	g age_l= substr(age,1,2)
	g age_h= substr(age,-2,2)
	replace age_l=subinstr(age_l, ",","",.)
	replace age_h=subinstr(age_h, ",","",.)
	replace age_h=age_l if age_h=="" 
	destring age_l  age_h, replace force
	keep if age_l!=. & age_h!=.
	*keep if region=="The Union of South Africa"
	
	g coh_h=1911-age_h
	g coh_l= 1911-age_l
	
	tostring coh_l, replace
	tostring coh_h, replace
	g cohort= coh_h +"-" +  coh_l
	
	keep  region white_m white_f coh_h coh_l cohort
	rename  white_m   white_m_1911
	rename   white_f  white_f_1911
	save temp,replace
	


*census 1911

cd "/Volumes/Samsung_T5/LEAP_camp_data"
import excel "/Volumes/Samsung_T5/LEAP_camp_data/census SA/census1936/Table 7.xlsx", firstrow sheet(totalonly) clear 

rename B sex
rename ProvinceandDistrict province
keep if sex=="M"|sex=="F"

foreach v of varlist a* {
destring `v', replace force
}
reshape long  a, i(province sex) j(age)
rename a value 
keep province sex age value
*tostring age, gen(age_g) 

replace province= proper(province)
replace province= subinstr(province," ","",.)
keep if province=="Total:TranskeianTerritories" | province=="Total:Cape(Ex-CludingTrans-KeianTerritories)"



collapse (sum)  value, by(age) 

g yob= 1936-age

scatter value yob if age <=20 , sort xline( 1910 1920 1930)

replace age = 0 if inrange(age,0,4)
replace age = 5 if inrange(age,5,9)
replace age = 10 if inrange(age,10,14)
replace age = 15 if inrange(age,15,19)
replace age = 20 if inrange(age,20,24)

collapse (sum)  value, by(age) 
g cohort_l= 1936- age 
g cohort_h= 1936- (age+4)
sssss

replace age = age+2
g yob= 1936-age


scatter value yob , sort xline( 1910 1920 1930)
