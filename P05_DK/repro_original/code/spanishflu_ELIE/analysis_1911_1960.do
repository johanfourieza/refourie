use "/Volumes/Samsung_T5/LEAP_camp_data/census SA/census SA 1960/Stata Files/white60.dta",clear
g p=1
g urb= urb_rura ==1
ta urb
collapse (sum) p urb, by(age)
g y= 1960-age
scatter p y 




cd "/Volumes/Samsung_T5/LEAP_camp_data/census SA/census SA 1960/Stata Files"


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
	keep if region=="The Union of South Africa"
	
	g coh_h=1911-age_h
	g coh_l= 1911-age_l
	
	tostring coh_l, replace
	tostring coh_h, replace
	g cohort= coh_h +"-" +  coh_l
	
	keep  white_m white_f coh_h coh_l cohort
	rename  white_m   white_m_1911
	rename   white_f  white_f_1911
	save temp,replace
	
	
	
*census 1960
use "/Volumes/Samsung_T5/LEAP_camp_data/census SA/census SA 1960/Stata Files/white60.dta",clear

	g coh= 1960 - age
	g c=""
	replace c="	1907-1911	" if inrange(coh,	1907	,	1911	)
	replace c="	1902-1906	" if inrange(coh,	1902	,	1906	)
	replace c="	1897-1901	" if inrange(coh,	1897	,	1901	)
	replace c="	1892-1896	" if inrange(coh,	1892	,	1896	)
	replace c="	1887-1891	" if inrange(coh,	1887	,	1891	)
	replace c="	1882-1886	" if inrange(coh,	1882	,	1886	)
	replace c="	1877-1881	" if inrange(coh,	1877	,	1881	)
	replace c="	1872-1876	" if inrange(coh,	1872	,	1876	)
	replace c="	1867-1871	" if inrange(coh,	1867	,	1871	)
	replace c="	1862-1866	" if inrange(coh,	1862	,	1866	)
	replace c="	1857-1861	" if inrange(coh,	1857	,	1861	)
	replace c="	1852-1856	" if inrange(coh,	1852	,	1856	)
	replace c="	1847-1851	" if inrange(coh,	1847	,	1851	)
	replace c="	1842-1846	" if inrange(coh,	1842	,	1846	)
	replace c="	1837-1841	" if inrange(coh,	1837	,	1841	)
	replace c="	1832-1836	" if inrange(coh,	1832	,	1836	)
	replace c="	1827-1831	" if inrange(coh,	1827	,	1831	)
	replace c="	1822-1826	" if inrange(coh,	1822	,	1826	)

	tostring coh, gen(c__)
	replace c= c__ if inrange(coh,1912,1930)
	replace c=subinstr(c," ","",.)
	
	drop if c==""
	g white_m_1960= sex==1 
	g white_f_1960=sex==2
	collapse (sum) white_* , by(c)
	
	rename c cohort 
	
	merge 1:1 cohort using temp 
	drop _m
	
	foreach v of varlist white* {
	replace `v'=0 if `v'==.
	}
	*
	
	replace cohort= coh_l if coh_l==coh_h  & coh_h !=""
	g l= length(cohort)
	
	g co_num= cohort if l==4
	destring coh_h coh_l, replace force
	destring co_num, force replace
	replace co_num= coh_h + (coh_l-coh_h)/2 if l==9
	
	
	foreach v of varlist white* {
	replace `v'=`v'/5  if  l==9
	}
	*
	
	g surv_m_1960= white_m_1960/white_m_1911 -1
	g surv_f_1960= white_f_1960/white_f_1911 -1


scatter white_m_1911  co_num , sort || scatter surv_m_1960   co_num , sort yaxis(2)
scatter white_f_1911  co_num , sort || scatter surv_f_1960   co_num , sort yaxis(2)

