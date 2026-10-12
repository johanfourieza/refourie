
*************************************************************************
*------------------------------------------------------------------------

*------------------------------------------------------------------------
*Start analysis
*------------------------------------------------------------------------

*------------------------------------------------------------------------

*========================================================================
*Date: May 2019

*MICRO METHOD 2 (slides)

*Database used (downloaded from ipums): ipumsi_00025.dta

*Unit of observation: individuals (by region of birth reported)

*Key variables: id_birth_all (region of birth of leader), bdec (birth decade)

*========================================================================
use "1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear  /* Final dataset, built in do file: "1_micro_all_primary_idbirth_datasetconstruction_20200511.do" */

tab bdec 
tab country if bdec==1950
keep if bdec==1950

edit geolev1 geolev2 admin_name  gis_code  if cntry_name=="Benin"
generate residence=.
format residence %12.0f
replace residence=geolev2 if cntry_name=="Benin"
replace residence=geolev1 if cntry_name=="Ghana"
replace residence=geolev1 if cntry_name=="Guinea"
replace residence=geolev2 if cntry_name=="Kenya"
replace residence=geolev1 if cntry_name=="Malawi"
replace residence=geolev2 if cntry_name=="Mali"
replace residence=geolev2 if cntry_name=="Senegal"
replace residence=geolev2 if cntry_name=="Sierra Leone"
replace residence=geolev1 if cntry_name=="Uganda"
replace residence=geolev1 if cntry_name=="Tanzania"
replace residence=geolev2 if cntry_name=="Zambia"

edit geolev1 geolev2 admin_name residence

collapse (mean) d_primary (count) nc=age , by(country residence)
save "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\collapsed_residence.dta"


*========================================================================
use "1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear  /* Final dataset, built in do file: "1_micro_all_primary_idbirth_datasetconstruction_20200511.do" */

tab bdec 
tab country if bdec==1950
keep if bdec==1950

edit geolev1 geolev2 admin_name 

edit geolev1 geolev2 admin_name residence

collapse (mean) d_primary (count) nc=age , by(country residence admin_name)
save "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\collapsed_residence.dta"
pwcorr d_primary
sort geolev1 geolev2 admin_name

tab d_primary d_birth_all
*you use a dummy for the years of rule (even without a lag)? So, again, for Amin, you would have a 1 for primary school completion of all individuals in Amin’s birth place (or ethnicity) during 1971 to 1979 and a 0 for all other time periods and all other birth regions. This would be the estimation that most closely approximates what existing studies are doing. We can then show that, once you include the human capital of those districts during earlier time periods, the results disappear (hopefully).

sum bdec age yr_birth if cntry_name=="Ghana"

pwcorr  d_birth d_birth_enter_in d_birth_bef_indep age  i_age_age   if bdec==1940, star(0.05)
pwcorr d_birth_enter_in d_birth_aft_indep d_birth_bef_indep, star(0.05)
pwcorr d_primary  d_birth   age  i_age_age  d_female d_christian  d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir cntry_code if bdec==1940, star(0.05)
 
*not suitability because it is not significant and it is captured with coordinates
corrtex d_primary  d_birth  d_ethnic age  i_age_age  d_female d_christian rural ///
  tse_r   railway_density  count_tribe slave_density    d_mission   ///
 d_centraliz d_capital dist_cap d_western if bdec==1940, file(correlation_primary) replace landscape  digits(2) 
 

******************************************* Table 2, coefficientes, no controls ***********************
* same reuslts clustered at tribe_co_1
*Nota: independence corresponds to r (independene achieved in region of birth) and this can differ from country fixed effcts. 

* (1) Region of birth of ALL leader
use "1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear  /* Final dataset, built in do file: "1_micro_all_primary_idbirth_datasetconstruction_20200511.do" */
drop d_birth
generate d_birth=	d_birth_all
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_ethnic_bef_indep=d_age_prim_bef*d_ethnic  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var  d_ethnic_bef_indep "interaction between ethnic region and age 6-13 before independence"

* (1) regressions
logit d_primary  d_birth     age  i_age_age  d_female  d_christian rural  i.cntry_code if d_birth_bef_indep !=., vce(cluster id_birth)
outreg2 using "2_micro.xls", replace tex     nocons    ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 0, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)     ///
	ctitle("d_primary") dec(2) ///
	drop(age i_age_age  d_female d_christian rural  ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap i.cntry_code)   ///
	sortvar(d_birth d_birth_bef_indep  d_age_prim_bef  d_birth_aft_indep  d_age_prim_aft   d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep ///
	 age  i_age_age  d_female  d_christian rural  ///
	d_mission  railway_density  tse_r d_western dist_cap d_capital  count_tribe slave_density  d_centraliz lon_id_bir lat_id_bir   i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	 
* (2) Region of birth of leader	
logit d_primary  d_birth   age  i_age_age  d_female d_christian rural ///
  tse_r   railway_density  count_tribe slave_density    d_mission   ///
 d_capital dist_cap d_western i.cntry_code if d_birth_bef_indep !=.,  vce(cluster id_birth) 
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust)) 
	 
* (3) 
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef  age  i_age_age  d_female  d_christian rural  i.cntry_code if d_birth_bef_indep !=., vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex    nocons    ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 0, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)     ///
	ctitle("d_primary") dec(2)  ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))


	 
* (4) 	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
tse_r  railway_density  count_tribe slave_density   d_mission   d_capital dist_cap  d_western i.cntry_code  if d_birth_bef_indep !=., vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	

	
	
******************************************* Table 2, CONTROLS coefficientes ***********************


* (1) Region of birth of ALL leader
use "1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear  /* Final dataset, built in do file: "1_micro_all_primary_idbirth_datasetconstruction_20200511.do" */
drop d_birth
generate d_birth=	d_birth_all
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

* (1) regressions
logit d_primary  d_birth     age  i_age_age  d_female  d_christian rural  i.cntry_code if d_birth_bef_indep !=., vce(cluster id_birth )
outreg2 using "2_micro.xls", replace tex     nocons    ///
	addtext(Constant, yes, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)     ///
	ctitle("d_primary") dec(2) ///
	drop(i.cntry_code)   ///
	sortvar(d_birth d_birth_bef_indep  d_age_prim_bef  d_birth_aft_indep  d_age_prim_aft   d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep ///
	 age  i_age_age  d_female  d_christian rural  ///
	d_mission  railway_density  tse_r d_western dist_cap d_capital  count_tribe slave_density  d_centraliz lon_id_bir lat_id_bir   i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	 
* (2) Region of birth of leader	
logit d_primary  d_birth   age  i_age_age  d_female d_christian rural ///
  tse_r   railway_density  count_tribe slave_density    d_mission   ///
 d_capital dist_cap d_western i.cntry_code if d_birth_bef_indep !=.,  vce(cluster id_birth) 
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)        ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust)) 
	 
* (3) 
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef  age  i_age_age  d_female  d_christian rural  i.cntry_code if d_birth_bef_indep !=., vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex    nocons    ///
	addtext(Constant, yes, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)     ///
	ctitle("d_primary") dec(2)  ///
	drop( i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))

* (4) 	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
tse_r  railway_density  count_tribe slave_density   d_mission   d_capital dist_cap  d_western i.cntry_code  if d_birth_bef_indep !=., vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)        ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	
******* Table 2, coefficientes, no controls --> drop migrants (suggested by referee)

* same reuslts clustered at tribe_co_1
*Nota: independence corresponds to r (independene achieved in region of birth) and this can differ from country fixed effcts. 
generate migrant=.
replace migrant=1 if id_birth!=
* (1) Region of birth of ALL leader
use "1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear  /* Final dataset, built in do file: "1_micro_all_primary_idbirth_datasetconstruction_20200511.do" */
drop d_birth
generate d_birth=	d_birth_all
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_ethnic_bef_indep=d_age_prim_bef*d_ethnic  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var  d_ethnic_bef_indep "interaction between ethnic region and age 6-13 before independence"

* (1) regressions
logit d_primary  d_birth     age  i_age_age  d_female  d_christian rural  i.cntry_code if d_birth_bef_indep !=., vce(cluster id_birth)
outreg2 using "2_micro.xls", replace tex     nocons    ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 0, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)     ///
	ctitle("d_primary") dec(2) ///
	drop(age i_age_age  d_female d_christian rural  ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap i.cntry_code)   ///
	sortvar(d_birth d_birth_bef_indep  d_age_prim_bef  d_birth_aft_indep  d_age_prim_aft   d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep ///
	 age  i_age_age  d_female  d_christian rural  ///
	d_mission  railway_density  tse_r d_western dist_cap d_capital  count_tribe slave_density  d_centraliz lon_id_bir lat_id_bir   i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	 
* (2) Region of birth of leader	
logit d_primary  d_birth   age  i_age_age  d_female d_christian rural ///
  tse_r   railway_density  count_tribe slave_density    d_mission   ///
 d_capital dist_cap d_western i.cntry_code if d_birth_bef_indep !=.,  vce(cluster id_birth) 
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust)) 
	 
* (3) 
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef  age  i_age_age  d_female  d_christian rural  i.cntry_code if d_birth_bef_indep !=., vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex    nocons    ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 0, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)     ///
	ctitle("d_primary") dec(2)  ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))


	 
* (4) 	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
tse_r  railway_density  count_tribe slave_density   d_mission   d_capital dist_cap  d_western i.cntry_code  if d_birth_bef_indep !=., vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	
	
**** LPM	(suggested by referee)
	
	
* (1) Region of birth of ALL leader
use "1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear  /* Final dataset, built in do file: "1_micro_all_primary_idbirth_datasetconstruction_20200511.do" */
drop d_birth
generate d_birth=	d_birth_all
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_ethnic_bef_indep=d_age_prim_bef*d_ethnic  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var  d_ethnic_bef_indep "interaction between ethnic region and age 6-13 before independence"

* (1) regressions
reg d_primary  d_birth     age  i_age_age  d_female  d_christian rural  i.cntry_code if d_birth_bef_indep !=., vce(cluster id_birth)
outreg2 using "2_micro.xls", replace tex     nocons    ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 0, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)     ///
	ctitle("d_primary") dec(2) ///
	drop(age i_age_age  d_female d_christian rural  ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap i.cntry_code)   ///
	sortvar(d_birth d_birth_bef_indep  d_age_prim_bef  d_birth_aft_indep  d_age_prim_aft   d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep ///
	 age  i_age_age  d_female  d_christian rural  ///
	d_mission  railway_density  tse_r d_western dist_cap d_capital  count_tribe slave_density  d_centraliz lon_id_bir lat_id_bir   i.cntry_code) ///
	 addstat(Cluster, e(N_clust))
	 
* (2) Region of birth of leader	
reg d_primary  d_birth   age  i_age_age  d_female d_christian rural ///
  tse_r   railway_density  count_tribe slave_density    d_mission   ///
 d_capital dist_cap d_western i.cntry_code if d_birth_bef_indep !=.,  vce(cluster id_birth) 
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	 addstat(Cluster, e(N_clust)) 
	 
* (3) 
reg d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef  age  i_age_age  d_female  d_christian rural  i.cntry_code if d_birth_bef_indep !=., vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex    nocons    ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 0, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)     ///
	ctitle("d_primary") dec(2)  ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	 addstat(Cluster, e(N_clust))


	 
* (4) 	
reg d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
tse_r  railway_density  count_tribe slave_density   d_mission   d_capital dist_cap  d_western i.cntry_code  if d_birth_bef_indep !=., vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Cluster, e(N_clust))
	
	test d_birth  d_birth_bef_indep
	
sum d_primary if 	d_birth==1 & d_age_prim_bef==1 & d_birth_bef_indep !=.
	
******************************************* Table 3, coefficientes, + coup and elite, no controls ***********************
* same reuslts clustered at tribe_co_1

* Region of birth of ALL leader
use "1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear  /* Final dataset, built in do file: "1_micro_all_primary_idbirth_datasetconstruction_20200511.do" */
drop d_birth
generate d_birth=	d_birth_all
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_ethnic_bef_indep=d_age_prim_bef*d_ethnic  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var  d_ethnic_bef_indep "interaction between ethnic region and age 6-13 before independence"
	

* (5) 	(coup)	
* rename birth region
	drop d_birth d_birth_bef_indep
	generate d_birth=d_birth_coup
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"
		
	logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
	tse_r 	railway_density  count_tribe slave_density   d_mission   d_capital dist_cap  d_western i.cntry_code if  d_birth_coup!=.,  vce(cluster tribe_co_1)
	outreg2 using "2_micro.xls", replace tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1geo2,  Leaders, coup, Drop, -)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))	
	
		
* (6) 	(elite)
	drop d_birth d_birth_bef_indep
	generate d_birth=d_birth_elite 
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

	logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
	tse_r  railway_density  count_tribe slave_density   d_mission  d_capital dist_cap  d_western i.cntry_code  if d_birth_elite!=.,  vce(cluster tribe_co_1)
	outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1geo2,  Leaders, elite, Drop, -)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))	

*no independence years +2
* (7) 	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density    d_mission   d_centraliz d_capital dist_cap  d_western   i.cntry_code if prim_in_plus2!=1,  vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8,  Country FE, yes , Level, geo1geo2,  Drop, indep+2)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))	
*no independence years +3

* (8) 	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density   d_mission   d_centraliz d_capital dist_cap d_western   i.cntry_code if prim_in_plus3!=1,  vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes,  Controls ind, 5, Controls geo, 8,  Country FE, yes , Level, geo1geo2,  Drop, indep+3)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))	
	
	
	
********************************************************************************
** Robustness checks **
********************************************************************************

*ethnicity: Table 3, coefficientes, no controls ***********************
********************************************************************************

* (1) Region of birth of ALL leader
use "1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear  /* Final dataset, built in do file: "1_micro_all_primary_idbirth_datasetconstruction_20200511.do" */
drop d_birth
generate d_birth=	d_birth_all
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_ethnic_bef_indep=d_age_prim_bef*d_ethnic  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var  d_ethnic_bef_indep "interaction between ethnic region and age 6-13 before independence"

* (1) regressions
logit d_primary  d_ethnic     age  i_age_age  d_female  d_christian rural  i.cntry_code , vce(cluster id_birth )
outreg2 using "2_micro.xls", replace tex     nocons    ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 0, Country FE, yes, Level, geo1geo2, Leaders, all)     ///
	ctitle("d_primary") dec(2) ///
	drop(age i_age_age  d_female d_christian rural  ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap i.cntry_code)   ///
	sortvar(d_birth d_birth_bef_indep  d_age_prim_bef  d_birth_aft_indep  d_age_prim_aft   d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep ///
	 age  i_age_age  d_female  d_christian rural  ///
	d_mission  railway_density  tse_r d_western dist_cap d_capital  count_tribe slave_density  d_centraliz lon_id_bir lat_id_bir   i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	 
* (2) Region of birth of leader	
logit d_primary  d_ethnic   age  i_age_age  d_female d_christian rural ///
  tse_r   railway_density  count_tribe slave_density    d_mission   ///
 d_capital dist_cap d_western i.cntry_code ,  vce(cluster id_birth) 
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1geo2, Leaders, all)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust)) 
	 
* (3) 
logit d_primary d_ethnic   d_ethnic_bef_indep  d_age_prim_bef    age  i_age_age  d_female  d_christian rural  i.cntry_code , vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex    nocons    ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 0, Country FE, yes, Level, geo1geo2, Leaders, all)     ///
	ctitle("d_primary") dec(2)  ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))


* (4) 	
logit d_primary  d_ethnic   d_ethnic_bef_indep  d_age_prim_bef      age  i_age_age  d_female d_christian rural ///
tse_r  railway_density  count_tribe slave_density   d_mission   d_capital dist_cap  d_western i.cntry_code  , vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1geo2, Leaders, all)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	

	
	
	
******************************************* Table 3, coefficientes, + coup and elite, no controls ***********************

* Region of birth of ALL leader
use "1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear  /* Final dataset, built in do file: "1_micro_all_primary_idbirth_datasetconstruction_20200511.do" */
drop d_birth
generate d_birth=	d_birth_all
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_ethnic_bef_indep=d_age_prim_bef*d_ethnic  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var  d_ethnic_bef_indep "interaction between ethnic region and age 6-13 before independence"
	

* (5) 	(coup)	
* rename birth region
	drop d_birth d_birth_bef_indep
	generate d_birth=d_birth_coup
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"
		
	logit d_primary d_ethnic   d_ethnic_bef_indep   d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
	tse_r 	railway_density  count_tribe slave_density   d_mission   d_capital dist_cap  d_western i.cntry_code if  d_birth_coup!=.,  vce(cluster id_birth)
	outreg2 using "2_micro.xls", replace tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1geo2,  Leaders, coup, Drop, -)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))	
	
		
* (6) 	(elite)
	drop d_birth d_birth_bef_indep
	generate d_birth=d_birth_elite 
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

	logit d_primary  d_ethnic   d_ethnic_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
	tse_r  railway_density  count_tribe slave_density   d_mission  d_capital dist_cap  d_western i.cntry_code  if d_birth_elite!=.,  vce(cluster id_birth)
	outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1geo2,  Leaders, elite, Drop, -)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))	
	
	
	
	
	
	
	
	
	

*no independence years +2
* (7) 	
logit d_primary  d_ethnic   d_ethnic_bef_indep   d_age_prim_bef    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density    d_mission   d_centraliz d_capital dist_cap  d_western   i.cntry_code if prim_in_plus2!=1,  vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8,  Country FE, yes , Level, geo1geo2,  Drop, indep+2)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))	
*no independence years +3

* (8) 	
logit d_primary d_ethnic   d_ethnic_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density   d_mission   d_centraliz d_capital dist_cap d_western   i.cntry_code if prim_in_plus3!=1,  vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes,  Controls ind, 5, Controls geo, 8,  Country FE, yes , Level, geo1geo2,  Drop, indep+3)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))	
	
		
	
	
	
	
	
	
	
	
	
	
******************************************* Table 3, coefficientes, + coup and elite, no controls ***********************

* Region of birth of ALL leader
use "1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear  /* Final dataset, built in do file: "1_micro_all_primary_idbirth_datasetconstruction_20200511.do" */
drop d_birth
generate d_birth=	d_birth_all
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_ethnic_bef_indep=d_age_prim_bef*d_ethnic  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var  d_ethnic_bef_indep "interaction between ethnic region and age 6-13 before independence"
	

* (5) 	(coup)	
* rename birth region
	drop d_birth d_birth_bef_indep
	generate d_birth=d_birth_coup
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"
		
	logit d_primary  d_ethnic   d_ethnic_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
	tse_r 	railway_density  count_tribe slave_density   d_mission   d_capital dist_cap  d_western i.cntry_code if  d_birth_coup!=.,  vce(cluster id_birth)
	outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1geo2,  Leaders, coup)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))	
	
		
* (6) 	(elite)
	drop d_birth d_birth_bef_indep
	generate d_birth=d_birth_elite 
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

	logit d_primary  d_ethnic   d_ethnic_bef_indep   d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
	tse_r  railway_density  count_tribe slave_density   d_mission  d_capital dist_cap  d_western i.cntry_code  if d_birth_elite!=.,  vce(cluster id_birth)
	outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1geo2,  Leaders, elite)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))	


********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************


*** Table 3 (after column 4), geo1level, no controls (Appendix)

use "1_ipumsi_africa_birth_leaders_micro_geo_200527_final_geo1.dta", clear

	
* (1) Region of birth of ALL leader
*drop d_birth
generate d_birth=	d_birth_all
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	*generate d_ethnic_bef_indep=d_age_prim_bef*d_ethnic  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	*label var  d_ethnic_bef_indep "interaction between ethnic region and age 6-13 before independence"


* (1) regressions
logit d_primary  d_birth     age  i_age_age  d_female  d_christian rural  i.cntry_code , vce(cluster geo1birth )
outreg2 using "2_micro.xls", replace tex     nocons    ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 0, Country FE, yes, Level, geo1, Leaders, all)     ///
	ctitle("d_primary") dec(2) ///
	drop(age i_age_age  d_female d_christian rural  ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap i.cntry_code)   ///
	sortvar(d_birth d_birth_bef_indep  d_age_prim_bef  d_birth_aft_indep  d_age_prim_aft   d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep ///
	 age  i_age_age  d_female  d_christian rural  ///
	d_mission  railway_density  tse_r d_western dist_cap d_capital  count_tribe slave_density  d_centraliz lon_id_bir lat_id_bir   i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	 
* (2) Region of birth of leader	
logit d_primary  d_birth   age  i_age_age  d_female d_christian rural ///
  tse_r   railway_density  count_tribe slave_density    d_mission   ///
 d_capital dist_cap d_western i.cntry_code ,  vce(cluster geo1birth) 
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1, Leaders, all)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust)) 
	 
* (3) 
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef  age  i_age_age  d_female  d_christian rural  i.cntry_code , vce(cluster geo1birth)
outreg2 using "2_micro.xls", append tex    nocons    ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 0, Country FE, yes, Level, geo1geo2, Leaders, all)     ///
	ctitle("d_primary") dec(2)  ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
 
* (4) 	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
tse_r  railway_density  count_tribe slave_density   d_mission   d_capital dist_cap  d_western i.cntry_code  ,  vce(cluster geo1birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1, Leaders, all)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))	
	
* (5) 	(coup)	
* rename birth region
	drop d_birth d_birth_bef_indep
	generate d_birth=d_birth_coup
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"
		
	logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
	tse_r 	railway_density  count_tribe slave_density   d_mission   d_capital dist_cap  d_western i.cntry_code if  d_birth_coup!=.,  vce(cluster geo1birth)
	outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1,  Leaders, coup)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))	
	
		
* (6) 	(elite)
	drop d_birth d_birth_bef_indep
	generate d_birth=d_birth_elite 
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

	logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
	tse_r  railway_density  count_tribe slave_density   d_mission  d_capital dist_cap  d_western i.cntry_code  if d_birth_elite!=.,  vce(cluster geo1birth)
	outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1,  Leaders, elite)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))	
	

	
	
*********************************************************************************
*** Table A5
*********************************************************************************

	
use "1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear
	
* column (4) 
drop d_birth
generate d_birth=	d_birth_all
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

* (4) 	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
tse_r  railway_density  count_tribe slave_density   d_mission   d_capital dist_cap  d_western i.cntry_code  ,  vce(cluster id_birth)
outreg2 using "2_micro.xls", replace tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1geo2, Drop, "-")        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))	
	
	
*all, long term leaders, and plus minus 1 year
*no independence years +2

* (4) based on column (4) 
	drop d_birth d_birth_bef_indep

*drop d_birth
generate d_birth=	d_birth_all
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"	

logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
 tse_r   railway_density  count_tribe slave_density    d_mission   d_capital dist_cap  d_western   i.cntry_code if prim_in_plus2!=1,  vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes , Level, geo1geo2,  Drop, indep+2)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p),  cluster, e(N_clust))
*no independence years +3

* (4) 	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
tse_r  railway_density  count_tribe slave_density   d_mission   d_capital dist_cap d_western   i.cntry_code if prim_in_plus3!=1,  vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8,  Country FE, yes , Level, geo1geo2,  Drop, indep+3)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p),  cluster, e(N_clust))
	
*no capital
* (4) 	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
tse_r  railway_density  count_tribe slave_density    d_mission   d_capital dist_cap d_western   i.cntry_code  if  d_capital!=1,  vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8,  Country FE, yes, Level, geo1geo2,  Drop, capital)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep  d_age_prim_bef  d_birth_aft_indep  d_age_prim_aft   d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep ///
	age  i_age_age  d_female  d_christian rural  ///
	d_mission tse_r  d_western  railway_density   dist_cap  d_capital d_centraliz count_tribe slave_density lon_id_bir lat_id_bir  i.cntry_code) ///
	addstat(Pseudo R2, e(r2_p),  cluster, e(N_clust))
	
	
	
	
	
	
	
	
********************************************************************************

*Splitting the sample
			
******************************************* Basic table with controls *********

******************************************* Table 3, coefficientes, no controls ***********************




* (1) Region of birth of ALL leader
use "1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear  /* Final dataset, built in do file: "1_micro_all_primary_idbirth_datasetconstruction_20200511.do" */
drop d_birth
generate d_birth=	d_birth_all
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"
	
drop if d_age_prim_bef !=1
drop if d_birth==.
drop if d_birth_bef_indep==.
drop if d_primary==.
tab d_age_prim_bef 
drop if d_age_prim_bef==.

* (a1) 	
*reg d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef , vce(robust)
logit d_primary  d_birth   , vce(robust)
outreg2 using "2_micro.xls", replace tex   nocons   ///
	addtext(Constant, yes, Controls ind, 0, Controls geo, 0, Country FE, no, Level, geo1geo2, Leaders, all, Drop, -)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat()

* (a2) 	
*reg d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef , vce(robust)
logit d_primary  d_birth   age  i_age_age  d_female d_christian rural ///
  tse_r   railway_density  count_tribe slave_density    d_mission   ///
 dist_cap d_western i.cntry_code ,  vce(robust) 
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat()	
		
	
	
*  Region of birth of ALL leader
use "1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear  /* Final dataset, built in do file: "1_micro_all_primary_idbirth_datasetconstruction_20200511.do" */
drop d_birth
generate d_birth=	d_birth_all
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

** after
drop if d_age_prim_bef !=0
drop if d_birth==.
drop if d_birth_bef_indep==.
drop if d_primary==.
tab d_age_prim_bef 
drop if d_age_prim_bef==.

*reg d_primary  d_birth   , vce(robust)

* (a1) 	
*reg d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef , vce(robust)
logit d_primary  d_birth   , vce(robust)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 0, Controls geo, 0, Country FE, no, Level, geo1geo2, Leaders, all, Drop, -)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat()

* (a2) 	
*reg d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef , vce(robust)
logit d_primary  d_birth   age  i_age_age  d_female d_christian rural ///
  tse_r   railway_density  count_tribe slave_density    d_mission   ///
 dist_cap d_western i.cntry_code ,  vce(robust) 
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 8, Country FE, yes, Level, geo1geo2, Leaders, all, Drop, -)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat()	
		
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
********************************************************************************

*Geo1level
			
******************************************* Basic table with controls **********

*** Table 3 (after column 4), geo1level, yes controls (Appendix)

* (1) Region of birth of ALL leader
use "1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear  /* Final dataset, built in do file: "1_micro_all_primary_idbirth_datasetconstruction_20200511.do" */
drop d_birth
generate d_birth=	d_birth_all
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_ethnic_bef_indep=d_age_prim_bef*d_ethnic  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var  d_ethnic_bef_indep "interaction between ethnic region and age 6-13 before independence"

* (1) regressions
logit d_primary  d_birth     age  i_age_age  d_female  d_christian rural  i.cntry_code , vce(cluster id_birth )
outreg2 using "2_micro.xls", replace tex     nocons    ///
	addtext(Constant, yes, Country FE, yes, Level, geo1geo2, Leaders, all)     ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	 
* (2) Region of birth of leader	
logit d_primary  d_birth   age  i_age_age  d_female d_christian rural ///
  tse_r   railway_density  count_tribe slave_density    d_mission   ///
 d_capital dist_cap d_western i.cntry_code ,  vce(cluster id_birth) 
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Country FE, yes, Level, geo1geo2, Leaders, all)        ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust)) 
	 
* (3) 
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef  age  i_age_age  d_female  d_christian rural  i.cntry_code , vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex    nocons    ///
	addtext(Constant, yes, Country FE, yes, Level, geo1geo2, Leaders, all)     ///
	ctitle("d_primary") dec(2)  ///
	drop( i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	 
* (4) 	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
tse_r  railway_density  count_tribe slave_density   d_mission   d_capital dist_cap  d_western i.cntry_code  ,  vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Country FE, yes, Level, geo1geo2, Leaders, all)        ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	
* (5) 	(coup)	
* rename birth region
	drop d_birth d_birth_bef_indep
	generate d_birth=d_birth_coup
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"
		
	logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
	tse_r 	railway_density  count_tribe slave_density   d_mission   d_capital dist_cap  d_western i.cntry_code if  d_birth_coup!=.,  vce(cluster id_birth)
	outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes,  Country FE, yes, Level, geo1geo2,  Leaders, coup)        ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))	
	
		
* (6) 	(elite)
	drop d_birth d_birth_bef_indep
	generate d_birth=d_birth_elite 
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

	logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural ///
	tse_r  railway_density  count_tribe slave_density   d_mission  d_capital dist_cap  d_western i.cntry_code  if d_birth_elite!=.,  vce(cluster id_birth)
	outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Country FE, yes, Level, geo1geo2,  Leaders, elite)        ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))	
	


	


********************************************************************************
*Create some variables for the regression: 

use "1_ipumsi_africa_birth_leaders_micro_geo_200527_final_geo1.dta", clear

generate d_birth=d_birth_all
*rename d_ethnic d_eth_2
*rename d_eth_tot d_ethnic
* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
generate d_birth_bef_indep=d_age_prim_bef*d_birth_all  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/

*generate d_birth_aft_indep=d_birth_all*d_age_prim_aft 
*generate d_ethnic_aft_indep=d_eth_tot*d_age_prim_aft


logit d_primary  d_birth     age  i_age_age  d_female  d_christian rural  i.cntry_code , vce(cluster geo1birth)
outreg2 using "2_micro.xls", replace tex     nocons    ///
	addtext(Constant, yes, Controls ind, 4, Controls geo, 0, Country FE, yes, Level, geo1, Leaders, all)     ///
	ctitle("d_primary") dec(2) ///
	drop(age i_age_age  d_female d_christian rural  ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap i.cntry_code)   ///
	sortvar(d_birth d_birth_bef_indep  d_age_prim_bef  d_birth_aft_indep  d_age_prim_aft   d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep ///
	 age  i_age_age  d_female  d_christian rural  ///
	d_mission  railway_density  tse_r d_western dist_cap d_capital  count_tribe slave_density  d_centraliz lon_id_bir lat_id_bir   i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	 
* (2) Region of birth of leader	
logit d_primary  d_birth   age  i_age_age  d_female d_christian rural ///
  tse_r   railway_density  count_tribe slave_density    d_mission   ///
 d_centraliz d_capital dist_cap d_western i.cntry_code ,  vce(cluster geo1birth) 
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 9, Country FE, yes, Level, geo1, Leaders, all)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust)) 
	 
* (3) 
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef  age  i_age_age  d_female  d_christian rural  i.cntry_code , vce(cluster geo1birth)
outreg2 using "2_micro.xls", append tex    nocons    ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 0, Country FE, yes, Level, geo1, Leaders, all)     ///
	ctitle("d_primary") dec(2)  ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
* (4) 	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density   d_mission   d_centraliz d_capital dist_cap  d_western i.cntry_code  ,  vce(cluster geo1birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 9, Country FE, yes, Level, geo1, Leaders, all)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))


* (6: geo1birth) 
	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density   d_mission   d_centraliz d_capital dist_cap  d_western i.cntry_code , /// drop countries with only geo1
 vce(cluster geo1birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 9, Country FE, yes, Level, geo1, Leaders, all)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	
* (5) long-term leaders (> 2 years)	
* rename birth region
	drop d_birth d_birth_bef_indep
	generate d_birth=d_birth_long
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"
	

logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density   d_mission   d_centraliz d_capital dist_cap  d_western i.cntry_code , /// 
 vce(cluster geo1birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 9, Country FE, yes, Level, geo1, Leaders, >2years)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	
	
* (5) long-term leaders (> 2 years)	
* rename birth region
	drop d_birth d_birth_bef_indep
	generate d_birth=short_term
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"
	

logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density   d_mission   d_centraliz d_capital dist_cap  d_western i.cntry_code , /// 
 vce(cluster geo1birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 9, Country FE, yes, Level, geo1, Leaders, >2years)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	

* (5) 	(coup)	
* rename birth region
	drop d_birth d_birth_bef_indep
	generate d_birth=d_birth_coup
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"

	logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density   d_mission   d_centraliz d_capital dist_cap  d_western i.cntry_code if d_birth_coup!=. , /// 
 vce(cluster geo1birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 9, Country FE, yes, Level, geo1, Leaders, coup)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	
	
* (6) 	(no coup)
drop d_birth d_birth_bef_indep
generate d_birth=	d_birth_all
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"
	

logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density   d_mission   d_centraliz d_capital dist_cap  d_western i.cntry_code , /// 
 vce(cluster geo1birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 9, Country FE, yes, Level, geo1, Leaders, no coup)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))
	
* (6) 	(elite)
drop d_birth d_birth_bef_indep
generate d_birth=	d_birth_elite 
	* Create interaction variables "d_age_prim_bef" with "d_birth_all" and "d_ethnic!:
	generate d_birth_bef_indep=d_age_prim_bef*d_birth  /*you belong to cohort with age that could have completed primary and belong to same region of leader*/
	label var d_birth_bef_indep "interaction between birth region and age 6-13 before independence"	

logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density   d_mission   d_centraliz d_capital dist_cap  d_western i.cntry_code if d_birth_elite!=. , /// 
 vce(cluster geo1birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 9, Country FE, yes, Level, geo1, Leaders, elite)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), cluster, e(N_clust))	
	
	
	
	
	
	
	
	
	
******************************ethnic	
*(1)
logit d_primary d_ethnic   age  i_age_age  d_female  d_christian rural  i.cntry_code, vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex  nocons ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 0, Country FE, yes, Leaders, all)     ///
	ctitle("d_primary") dec(2)   ///
		drop(age i_age_age  d_female d_christian rural  ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap i.cntry_code)   ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
*(2)	
logit d_primary d_ethnic  age  i_age_age  d_female d_christian rural ///
tse_r   railway_density  count_tribe slave_density  d_mission   d_centraliz d_capital dist_cap  d_western i.cntry_code,  vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex  nocons    ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 9, Country FE, yes, Leaders, all)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))	
*(3)
logit d_primary d_ethnic   d_ethnic_bef_indep  d_age_prim_bef  age  i_age_age  d_female  d_christian  rural i.cntry_code, vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 0, Country FE, yes, Leaders, all)     ///
	ctitle("d_primary") dec(2)   ///
		drop(age i_age_age  d_female d_christian rural  ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap i.cntry_code)   ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
*(4)	
logit d_primary d_ethnic   d_ethnic_bef_indep d_age_prim_bef   age  i_age_age  d_female d_christian rural  tse_r   railway_density  ///
count_tribe slave_density  d_mission   d_centraliz d_capital dist_cap  d_western i.cntry_code,  vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex   nocons    ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 9, Country FE, yes, Leaders, all)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep  d_age_prim_bef  d_birth_aft_indep  d_age_prim_aft   d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep ///
	age  i_age_age  d_female  d_christian rural  ///
	d_mission  railway_density  tse_r d_western dist_cap d_capital  count_tribe slave_density  d_centraliz lon_id_bir lat_id_bir   i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))	

	 *************************
	 *(5)
logit d_primary d_birth  d_birth_bef_indep  d_age_prim_bef  d_ethnic   d_ethnic_bef_indep   age  i_age_age  d_female  d_christian  rural i.cntry_code, vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 0, Country FE, yes)     ///
	ctitle("d_primary") dec(2)   ///
		drop(age i_age_age  d_female d_christian rural  ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap i.cntry_code)   ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
*(6)	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef  d_ethnic   d_ethnic_bef_indep   age  i_age_age  d_female d_christian rural  tse_r   railway_density  ///
count_tribe slave_density  d_mission   d_centraliz d_capital dist_cap  d_western i.cntry_code,  vce(cluster id_birth)
outreg2 using "2_micro.xls", append tex   nocons    ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 9, Country FE, yes)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep  d_age_prim_bef  d_birth_aft_indep  d_age_prim_aft   d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep ///
	age  i_age_age  d_female  d_christian rural  ///
	d_mission  railway_density  tse_r d_western dist_cap d_capital  count_tribe slave_density  d_centraliz lon_id_bir lat_id_bir   i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))		 
	 


 ******************************************* Basic table with odds ratio  ***********************REDO!

 
 compare d_birth_bef_indep  d_birth_aft_indep if bdec==1940 
 
 
 * (4) 	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density   d_mission   d_centraliz d_capital dist_cap  d_western i.cntry_code,  vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", replace tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 9, Country FE, yes)        ///
	ctitle("d_primary") dec(2) ///
	addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
 
 logit d_primary  d_birth  d_birth_aft_indep  d_age_prim_aft    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density   d_mission   d_centraliz d_capital dist_cap  d_western i.cntry_code,  vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex   nocons ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 9, Country FE, yes)        ///
	ctitle("d_primary") dec(2) ///
	addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
 
 
  * (1) Region of birth of leader

logit d_primary  d_birth     age  i_age_age  d_female  d_christian rural  i.cntry_code, vce(cluster tribe_co_1)
outreg2 using "2_micro_oddsratio.xls", replace tex     nocons    ///
	addtext(Constant, yes, Controls ind, 4, Controls geo, 0, Country FE, yes)     ///
	ctitle("d_primary") dec(2) ///
	drop(age i_age_age  d_female d_christian rural  ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap i.cntry_code)   ///
	sortvar(d_birth d_birth_bef_indep  d_age_prim_bef  d_birth_aft_indep  d_age_prim_aft   d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep ///
	 age  i_age_age  d_female  d_christian rural  ///
	d_mission  railway_density  tse_r d_western dist_cap d_capital  count_tribe slave_density  d_centraliz lon_id_bir lat_id_bir   i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	 
* (2) Region of birth of leader	
logit d_primary  d_birth   age  i_age_age  d_female d_christian rural ///
  tse_r   railway_density  count_tribe slave_density    d_mission   ///
 d_centraliz d_capital dist_cap d_western i.cntry_code,  vce(cluster tribe_co_1) 
outreg2 using "2_micro_oddsratio.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 9, Country FE, yes)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust)) 
	 
	 
* (3) 
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef  age  i_age_age  d_female  d_christian rural  i.cntry_code, vce(cluster tribe_co_1)
outreg2 using "2_micro_oddsratio.xls", append tex    nocons    ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 0, Country FE, yes)     ///
	ctitle("d_primary") dec(2)  ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
* (4) 	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density   d_mission   d_centraliz d_capital dist_cap  d_western i.cntry_code,  vce(cluster tribe_co_1)
outreg2 using "2_micro_oddsratio.xls", append tex   nocons   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 9, Country FE, yes)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
    d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
******************************ethnic	
*(1)
logit d_primary d_ethnic   age  i_age_age  d_female  d_christian rural  i.cntry_code,or vce(cluster tribe_co_1)
outreg2 using "2_micro_oddsratio.xls", append tex  nocons  eform  ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 0, Country FE, yes)     ///
	ctitle("d_primary") dec(2)   ///
		drop(age i_age_age  d_female d_christian rural  ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap i.cntry_code)   ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
*(2)	
logit d_primary d_ethnic  age  i_age_age  d_female d_christian rural ///
tse_r   railway_density  count_tribe slave_density  d_mission   d_centraliz d_capital dist_cap  d_western i.cntry_code,or  vce(cluster tribe_co_1)
outreg2 using "2_micro_oddsratio.xls", append tex  nocons  eform    ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 9, Country FE, yes)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))	
*(3)
logit d_primary d_ethnic   d_ethnic_bef_indep  d_age_prim_bef  age  i_age_age  d_female  d_christian  rural i.cntry_code,or vce(cluster tribe_co_1)
outreg2 using "2_micro_oddsratio.xls", append tex   nocons  eform   ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 0, Country FE, yes)     ///
	ctitle("d_primary") dec(2)   ///
		drop(age i_age_age  d_female d_christian rural  ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap i.cntry_code)   ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
*(4)	
logit d_primary d_ethnic   d_ethnic_bef_indep d_age_prim_bef   age  i_age_age  d_female d_christian rural  tse_r   railway_density  ///
count_tribe slave_density  d_mission   d_centraliz d_capital dist_cap  d_western i.cntry_code, or vce(cluster tribe_co_1)
outreg2 using "2_micro_oddsratio.xls", append tex   nocons  eform    ///
	addtext(Constant, yes, Controls ind, 5, Controls geo, 9, Country FE, yes)        ///
	ctitle("d_primary") dec(2) ///
	drop(age  i_age_age  d_female d_christian rural ///
	   d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep  d_age_prim_bef  d_birth_aft_indep  d_age_prim_aft   d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep ///
	age  i_age_age  d_female  d_christian rural  ///
	d_mission  railway_density  tse_r d_western dist_cap d_capital  count_tribe slave_density  d_centraliz lon_id_bir lat_id_bir   i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))	
 
 
 
 
 
 
 
 
 
 
 
 
					
					
 ******************************************* Basic table with controls ***********************

 ****************
 * Birth region *
 ****************

 * (1) Region of birth of leader

logit d_primary  d_birth     age  i_age_age  d_female  d_christian rural  i.cntry_code, vce(cluster tribe_co_1)
outreg2 using "2_micro_controls.xls", replace tex     nocons    ///
	addtext(Constant, yes, Country FE, yes, Drop, 0)     ///
	ctitle("d_primary") dec(2) drop( i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep  d_age_prim_bef  d_birth_aft_indep  d_age_prim_aft   d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep ///
	age  i_age_age  d_female  d_christian rural  ///
	d_mission tse_r d_western  railway_density   dist_cap  d_capital d_centraliz count_tribe slave_density lon_id_bir lat_id_bir  i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	 
* (2) Region of birth of leader	
logit d_primary  d_birth   age  i_age_age  d_female d_christian rural ///
  tse_r   railway_density  count_tribe slave_density   d_mission   ///
 d_centraliz d_capital dist_cap  d_western  i.cntry_code,  vce(cluster tribe_co_1) 
outreg2 using "2_micro_controls.xls", append tex   nocons   ///
	addtext(Constant, yes,  Country FE, yes, Drop, 0)        ///
	ctitle("d_primary") dec(2) ///
	drop(i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust)) 
* (3) 
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef  age  i_age_age  d_female  d_christian rural  i.cntry_code, vce(cluster tribe_co_1)
outreg2 using "2_micro_controls.xls", append tex    nocons    ///
	addtext(Constant, yes,  Country FE, yes, Drop, 0)     ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code)  ///	
    addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
* (4) 	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density  d_mission   d_centraliz d_capital dist_cap d_western  i.cntry_code,  vce(cluster tribe_co_1)
outreg2 using "2_micro_controls.xls", append tex   nocons   ///
	addtext(Constant, yes,  Country FE, yes, Drop, 0)        ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code) ///
	addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
*no independence years +2
* (4) 	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density    d_mission   d_centraliz d_capital dist_cap  d_western   i.cntry_code if prim_in_plus2!=1,  vce(cluster tribe_co_1)
outreg2 using "2_micro_controls.xls", append tex   nocons   ///
	addtext(Constant, yes,  Country FE, yes , Drop, indep+2)        ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code) ///
	addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
*no independence years +3

* (4) 	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density   d_mission   d_centraliz d_capital dist_cap d_western   i.cntry_code if prim_in_plus3!=1,  vce(cluster tribe_co_1)
outreg2 using "2_micro_controls.xls", append tex   nocons   ///
	addtext(Constant, yes,  Country FE, yes , Drop, indep+3)        ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code) ///
	addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
*no capital
* (4) 	
logit d_primary  d_birth  d_birth_bef_indep  d_age_prim_bef    age  i_age_age  d_female d_christian rural tse_r   ///
 railway_density  count_tribe slave_density    d_mission   d_centraliz d_capital dist_cap d_western   i.cntry_code  if  d_capital!=1,  vce(cluster tribe_co_1)
outreg2 using "2_micro_controls.xls", append tex   nocons   ///
	addtext(Constant, yes,  Country FE, yes, Drop, capital)        ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code) ///
		sortvar(d_birth d_birth_bef_indep  d_age_prim_bef  d_birth_aft_indep  d_age_prim_aft   d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep ///
	age  i_age_age  d_female  d_christian rural  ///
	d_mission tse_r  d_western  railway_density   dist_cap  d_capital d_centraliz count_tribe slave_density lon_id_bir lat_id_bir  i.cntry_code) ///
	addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))


	
******************************ethnic	
*(1)
logit d_primary d_ethnic   age  i_age_age  d_female  d_christian rural  i.cntry_code, vce(cluster tribe_co_1)
outreg2 using "2_micro_controls.xls", append tex  nocons ///
	addtext(Constant, yes, Country FE, yes, Drop, 0)     ///
	ctitle("d_primary") dec(2) drop(  i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
*(2)	
logit d_primary d_ethnic  age  i_age_age  d_female d_christian rural tse_r   railway_density  count_tribe slave_density  ///
  d_mission   d_centraliz d_capital dist_cap  d_western   i.cntry_code,  vce(cluster tribe_co_1)
outreg2 using "2_micro_controls.xls", append tex  nocons    ///
	addtext(Constant, yes,  Country FE, yes, Drop, 0)        ///
	ctitle("d_primary") dec(2) ///
	drop(i.cntry_code)  ///
	addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))	
*(3)
logit d_primary d_ethnic   d_ethnic_bef_indep  d_age_prim_bef  age  i_age_age  d_female  d_christian  rural i.cntry_code, vce(cluster tribe_co_1)
outreg2 using "2_micro_controls.xls", append tex   nocons   ///
	addtext(Constant, yes,  Country FE, yes, Drop, 0)     ///
	ctitle("d_primary") dec(2) drop( i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
*(4)	
logit d_primary d_ethnic   d_ethnic_bef_indep d_age_prim_bef   age  i_age_age  d_female d_christian rural  tse_r   railway_density  ///
count_tribe slave_density    d_mission   d_centraliz d_capital dist_cap d_western  i.cntry_code,  vce(cluster tribe_co_1)
outreg2 using "2_micro_controls.xls", append tex   nocons    ///
	addtext(Constant, yes,  Country FE, yes, Drop, 0)        ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))	

*(4)	no independence +2
logit d_primary d_ethnic   d_ethnic_bef_indep d_age_prim_bef   age  i_age_age  d_female d_christian rural  tse_r   railway_density  ///
count_tribe slave_density   d_mission   d_centraliz d_capital dist_cap  d_western   i.cntry_code if prim_in_plus2!=1,  vce(cluster tribe_co_1)
outreg2 using "2_micro_controls.xls", append tex   nocons    ///
	addtext(Constant, yes, Country FE, yes, Drop, indep+2)        ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))	

*(4)	no independence +3
logit d_primary d_ethnic   d_ethnic_bef_indep d_age_prim_bef   age  i_age_age  d_female d_christian rural  tse_r   railway_density  ///
count_tribe slave_density    d_mission   d_centraliz d_capital dist_cap d_western  i.cntry_code if prim_in_plus3!=1,  vce(cluster tribe_co_1)
outreg2 using "2_micro_controls.xls", append tex   nocons    ///
	addtext(Constant, yes, Country FE, yes, Drop, indep+3)        ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code)  ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))	
*(4)	no capital
logit d_primary d_ethnic   d_ethnic_bef_indep d_age_prim_bef   age  i_age_age  d_female d_christian rural  tse_r   railway_density  ///
count_tribe slave_density  d_mission   d_centraliz  dist_cap d_western   i.cntry_code if  d_capital!=1,  vce(cluster tribe_co_1)
outreg2 using "2_micro_controls.xls", append tex   nocons    ///
	addtext(Constant, yes,  Country FE, yes, Drop, capital)        ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code)  ///
		sortvar(d_birth d_birth_bef_indep  d_age_prim_bef  d_birth_aft_indep  d_age_prim_aft   d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep ///
	age  i_age_age  d_female  d_christian rural  ///
	d_mission tse_r d_western  railway_density   dist_cap  d_capital d_centraliz count_tribe slave_density lon_id_bir lat_id_bir  i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))	
					


	
	
	
	
	
	***************quita suitability en las siguientes!! las siguientes regresiones no están metidas en el paper
	

	
*******  (1) With controls in outreg  ************
*eform después de tex	u or depsués de regreion

logit d_primary  d_birth     age  i_age_age  d_female  d_christian   i.cntry_code, vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", replace tex        ///
	addtext(Controls ind, 4, Controls geo, 0, Country FE, yes)     ///
	ctitle("d_primary") dec(2) drop(i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep d_birth_aft_indep  d_birth_enter_in share_yrs_birth  d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic  d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
logit d_primary  d_birth   age  i_age_age  d_female d_christian  ///
d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   ///
 d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code,  vce(cluster tribe_co_1) 
outreg2 using "2_micro.xls", append tex      ///
	addtext(Controls ind, 4, Controls geo, 12, Country FE, yes)        ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep d_birth_aft_indep  d_birth_enter_in share_yrs_birth  d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
*-----	

logit d_primary  d_birth_bef_indep  d_birth_aft_indep  d_birth_enter_in share_yrs_birth   age  i_age_age  d_female  d_christian   i.cntry_code, vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex       ///
	addtext(Controls ind, 4, Controls geo, 0, Country FE, yes)     ///
	ctitle("d_primary") dec(2) drop( i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep d_birth_aft_indep  d_birth_enter_in share_yrs_birth  d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
logit d_primary d_birth_bef_indep d_birth_aft_indep d_birth_enter_in share_yrs_birth    age  i_age_age  d_female d_christian d_western  tse_r   ///
 railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code,  vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex     ///
	addtext(Controls ind, 4, Controls geo, 12, Country FE, yes)        ///
	ctitle("d_primary") dec(2) ///
	drop(i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep d_birth_aft_indep  d_birth_enter_in share_yrs_birth  d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
	
	
* Now add d_ethnicity: d_lead_eth 
	
logit d_primary d_ethnic age  i_age_age  d_female  d_christian   i.cntry_code, vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex     ///
	addtext(Controls ind, 4, Controls geo, 0, Country FE, yes)     ///
	ctitle("d_primary") dec(2) drop( i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep d_birth_aft_indep  d_birth_enter_in share_yrs_birth  d_ethnic ///
	d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic  d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
logit d_primary d_ethnic   age  i_age_age  d_female d_christian d_western  tse_r   railway_density  count_tribe slave_density  ///
suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code,  vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex      ///
	addtext(Controls ind, 4, Controls geo, 12, Country FE, yes)        ///
	ctitle("d_primary") dec(2) ///
	drop(i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep d_birth_aft_indep  d_birth_enter_in share_yrs_birth  d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
*-----	

logit d_primary  d_ethnic_bef_indep d_ethnic_aft_indep  d_eth_enter_in share_yrs_ethnic   age  i_age_age  d_female  d_christian   i.cntry_code, vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex      ///
	addtext(Controls ind, 4, Controls geo, 0, Country FE, yes)     ///
	ctitle("d_primary") dec(2) drop(  i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep d_birth_aft_indep  d_birth_enter_in share_yrs_birth  d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
logit d_primary  d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic    age  i_age_age  d_female d_christian d_western  tse_r   railway_density  ///
count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code,  vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex       ///
	addtext(Controls ind, 4, Controls geo, 12, Country FE, yes)        ///
	ctitle("d_primary") dec(2) ///
	drop(i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep d_birth_aft_indep  d_birth_enter_in share_yrs_birth  d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	

	
	
	
*******  (1) With controls iand without capital ************
*eform después de tex	u or depsués de regreion

logit d_primary  d_birth     age  i_age_age  d_female  d_christian   i.cntry_code if d_capital!=1, vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", replace tex        ///
	addtext(Controls ind, 4, Controls geo, 0, Country FE, yes)     ///
	ctitle("d_primary") dec(2) drop(i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep d_birth_aft_indep  d_birth_enter_in share_yrs_birth  d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic  d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
logit d_primary  d_birth   age  i_age_age  d_female d_christian  ///
d_western  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   ///
 d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code if d_capital!=1,  vce(cluster tribe_co_1) 
outreg2 using "2_micro.xls", append tex      ///
	addtext(Controls ind, 4, Controls geo, 12, Country FE, yes)        ///
	ctitle("d_primary") dec(2) ///
	drop( i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep d_birth_aft_indep  d_birth_enter_in share_yrs_birth  d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
*-----	

logit d_primary  d_birth_bef_indep  d_birth_aft_indep  d_birth_enter_in share_yrs_birth   age  i_age_age  d_female  d_christian   i.cntry_code if d_capital!=1, vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex       ///
	addtext(Controls ind, 4, Controls geo, 0, Country FE, yes)     ///
	ctitle("d_primary") dec(2) drop( i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep d_birth_aft_indep  d_birth_enter_in share_yrs_birth  d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
logit d_primary d_birth_bef_indep d_birth_aft_indep d_birth_enter_in share_yrs_birth    age  i_age_age  d_female d_christian d_western  tse_r   ///
 railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code if d_capital!=1,  vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex     ///
	addtext(Controls ind, 4, Controls geo, 12, Country FE, yes)        ///
	ctitle("d_primary") dec(2) ///
	drop(i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep d_birth_aft_indep  d_birth_enter_in share_yrs_birth  d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
	
	
* Now add d_ethnicity: d_lead_eth 
	
logit d_primary d_ethnic age  i_age_age  d_female  d_christian   i.cntry_code if d_capital!=1, vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex     ///
	addtext(Controls ind, 4, Controls geo, 0, Country FE, yes)     ///
	ctitle("d_primary") dec(2) drop( i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep d_birth_aft_indep  d_birth_enter_in share_yrs_birth  d_ethnic ///
	d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic  d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
logit d_primary d_ethnic   age  i_age_age  d_female d_christian d_western  tse_r   railway_density  count_tribe slave_density  ///
suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code if d_capital!=1,  vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex      ///
	addtext(Controls ind, 4, Controls geo, 12, Country FE, yes)        ///
	ctitle("d_primary") dec(2) ///
	drop(i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep d_birth_aft_indep  d_birth_enter_in share_yrs_birth  d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
*-----	

logit d_primary  d_ethnic_bef_indep d_ethnic_aft_indep  d_eth_enter_in share_yrs_ethnic   age  i_age_age  d_female  d_christian   i.cntry_code if d_capital!=1, vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex      ///
	addtext(Controls ind, 4, Controls geo, 0, Country FE, yes)     ///
	ctitle("d_primary") dec(2) drop(  i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep d_birth_aft_indep  d_birth_enter_in share_yrs_birth  d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
logit d_primary  d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic    age  i_age_age  d_female d_christian d_western  tse_r   railway_density  ///
count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap  lat_id_bir lon_id_bir i.cntry_code if d_capital!=1,  vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex       ///
	addtext(Controls ind, 4, Controls geo, 12, Country FE, yes)        ///
	ctitle("d_primary") dec(2) ///
	drop(i.cntry_code)  ///
	sortvar(d_birth d_birth_bef_indep d_birth_aft_indep  d_birth_enter_in share_yrs_birth  d_ethnic  d_ethnic_bef_indep d_ethnic_aft_indep d_eth_enter_in share_yrs_ethnic ///
	d_western tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	 addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))	
	
	
	
*************** Western Africa **************

pwcorr d_primary  d_birth_enter_in  d_birth_enter_out d_birth_bef_indep age  i_age_age  d_female  d_christian d_france  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap if region=="Western Africa"

* (1) Region of birth of leader
logit d_primary  d_birth_enter_in  d_birth_enter_out d_birth_bef_indep age  i_age_age  d_female  d_christian  i.cntry_code if region=="Western Africa", vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", replace tex       ///
	addtext(Controls, 0, Region FE, yes)        ///
	title ("Western Africa") ctitle("d_primary") dec(2) drop(i.cntry_code)  ///
	sortvar(d_birth_bef_indep    d_ethnic_bef_indep  d_birth_enter_in  d_birth_enter_out share_years_leader  d_eth_enter_in d_eth_enter_out e_share_years_leader   age  i_age_age  d_female  d_christian d_france  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	nocons addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))

	* (1+c) Region of birth of leader
logit d_primary  d_birth_enter_in  d_birth_enter_out d_birth_bef_indep age  i_age_age  d_female  d_christian d_france  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap i.cntry_code if region=="Western Africa", vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex       ///
	addtext(Controls, 0, Region FE, yes)        ///
	title ("Western Africa") ctitle("d_primary") dec(2) drop(i.cntry_code)  ///
		sortvar(d_birth_bef_indep    d_ethnic_bef_indep  d_birth_enter_in  d_birth_enter_out share_years_leader  d_eth_enter_in d_eth_enter_out e_share_years_leader   age  i_age_age  d_female  d_christian d_france  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	nocons addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))

* (2) Region of birth of leader	
logit d_primary share_years_leader d_birth_enter_out  d_birth_bef_indep age  i_age_age  d_female  d_christian  i.cntry_code if region=="Western Africa", vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex       ///
	addtext(Controls, 0, Region FE, yes)        ///
	title ("Western Africa") ctitle("d_primary") dec(2) drop(i.cntry_code)  ///
		sortvar(d_birth_bef_indep    d_ethnic_bef_indep  d_birth_enter_in  d_birth_enter_out share_years_leader  d_eth_enter_in d_eth_enter_out e_share_years_leader   age  i_age_age  d_female  d_christian d_france  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	nocons addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))	
	
* (2+c) Region of birth of leader	
logit d_primary share_years_leader d_birth_enter_out  d_birth_bef_indep age  i_age_age  d_female  d_christian d_france  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap i.cntry_code if region=="Western Africa", vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append tex       ///
	addtext(Controls, 0, Region FE, yes)        ///
	title ("Western Africa") ctitle("d_primary") dec(2) drop(i.cntry_code)  ///
			sortvar(d_birth_bef_indep    d_ethnic_bef_indep  d_birth_enter_in  d_birth_enter_out share_years_leader  d_eth_enter_in d_eth_enter_out e_share_years_leader   age  i_age_age  d_female  d_christian d_france  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	nocons addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))	
	

* (3) Region of birth of leader

logit d_primary d_eth_enter_in  d_eth_enter_out   d_ethnic_bef_indep   age  i_age_age  d_female  d_christian   i.cntry_code if region=="Western Africa", vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append       ///
	tex addtext( Controls, 0, Region FE, yes)  ///
	title ("Western Africa") ctitle("d_primary") dec(2) drop(i.cntry_code)   ///   
		sortvar(d_birth_bef_indep    d_ethnic_bef_indep  d_birth_enter_in  d_birth_enter_out share_years_leader  d_eth_enter_in d_eth_enter_out e_share_years_leader   age  i_age_age  d_female  d_christian d_france  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
nocons addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))

* (3+c) Region of birth of leader

logit d_primary d_eth_enter_in  d_eth_enter_out   d_ethnic_bef_indep   age  i_age_age  d_female  d_christian d_france  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap i.cntry_code if region=="Western Africa", vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append       ///
	tex addtext( Controls, 0, Region FE, yes)  ///
	title ("Western Africa") ctitle("d_primary") dec(2) drop(i.cntry_code)   ///   
		sortvar(d_birth_bef_indep    d_ethnic_bef_indep  d_birth_enter_in  d_birth_enter_out share_years_leader  d_eth_enter_in d_eth_enter_out e_share_years_leader   age  i_age_age  d_female  d_christian d_france  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
nocons addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))

* (4)  Now add d_ethnicity: d_lead_eth 
logit d_primary  e_share_years_leader   d_eth_enter_out   d_ethnic_bef_indep   age  i_age_age  d_female  d_christian   i.cntry_code if region=="Western Africa", vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append       ///
	tex addtext( Controls, 0, Region FE, yes)  ///
	title ("Western Africa") ctitle("d_primary") dec(2) drop(i.cntry_code)   ///   
		sortvar(d_birth_bef_indep    d_ethnic_bef_indep  d_birth_enter_in  d_birth_enter_out share_years_leader  d_eth_enter_in d_eth_enter_out e_share_years_leader   age  i_age_age  d_female  d_christian d_france  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	nocons addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))
	
* (4+c)  Now add d_ethnicity: d_lead_eth 
logit d_primary  e_share_years_leader   d_eth_enter_out   d_ethnic_bef_indep   age  i_age_age  d_female  d_christian   d_france  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap i.cntry_code if region=="Western Africa", vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append       ///
	tex addtext( Controls, 0, Region FE, yes)  ///
	title ("Western Africa") ctitle("d_primary") dec(2) drop(i.cntry_code)   ///   
		sortvar(d_birth_bef_indep    d_ethnic_bef_indep  d_birth_enter_in  d_birth_enter_out share_years_leader  d_eth_enter_in d_eth_enter_out e_share_years_leader   age  i_age_age  d_female  d_christian d_france  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code) ///
	nocons addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))	

	
		
**************Eastern Africa *************

* (1) 
logit d_primary d_birth_enter i_d_age_prim_befd_birth_all d_age_prim_aft ///
	age  i_age_age  d_female  d_christian  ///
	lon_id_bir lat_id_bir  i.cntry_code ///
	if region=="Eastern Africa", vce(cluster tribe_co_1) 
outreg2 using "micro.xls", replace    ///
	tex  addtext(Controls, 0, Region FE, yes)        ///
	title ("Eastern Africa") ctitle("d_primary") dec(2) drop(i.cntry_code)  ///
	sortvar(d_birth_enter i_d_age_prim_befd_birth_all  d_birth_all  i_d_age_prim_aftd_birth_all i_d_age_prim_befd_birth_all d_age_prim_bef d_lead_eth i_d_age_prim_befd_lead_eth) ///
	nocons addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))

* (2)  Now add d_ethnicity: d_lead_eth 
logit d_primary d_birth_enter i_d_age_prim_befd_birth_all  d_age_prim_aft d_lead_eth  /// 
	age  i_age_age  d_female  d_christian   /// 
	lon_id_bir lat_id_bir  i.cntry_code    /// 
	if region=="Eastern Africa", vce(cluster tribe_co_1)	
outreg2 using "micro.xls", append         ///
	tex addtext( Controls, 0, Region FE, yes)  ///
	ctitle("d_primary") dec(2) drop(i.cntry_code)   ///   
	sortvar(d_birth_enter i_d_age_prim_befd_birth_all d_birth_all  i_d_age_prim_aftd_birth_all i_d_age_prim_befd_birth_all d_age_prim_bef d_lead_eth i_d_age_prim_befd_lead_eth)    ///
	nocons addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))  
 
* (3) Now add many other controls (maybe six or so)

logit d_primary d_birth_enter i_d_age_prim_befd_birth_all d_age_prim_aft  d_lead_eth        ///
	age  i_age_age  d_female  d_christian        ///
	d_france  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir i.cntry_code        ///
	if region=="Eastern Africa", vce(cluster tribe_co_1) 	
outreg2 using "micro.xls", append         ///
	tex  addtext( Controls, 0, Region FE, yes)    ///
	ctitle("d_primary") dec(2) drop(i.cntry_code)    /// 
	sortvar(d_birth_enter i_d_age_prim_befd_birth_all 	d_birth_all  i_d_age_prim_aftd_birth_all i_d_age_prim_befd_birth_all	 d_age_prim_bef d_lead_eth i_d_age_prim_befd_lead_eth)   ///
	nocons addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))

* (4) 
logit d_primary d_birth_all i_d_age_prim_aftd_birth_all d_age_prim_aft      ///
	age  i_age_age  d_female  d_christian        ///
	lon_id_bir lat_id_bir  i.cntry_code      ///
	if region=="Eastern Africa", vce(cluster tribe_co_1)
outreg2 using "micro.xls", append tex        ///
	addtext(Controls, 0, Region FE, yes)        ///
	ctitle("d_primary") dec(2) drop(i.cntry_code)  ///
	sortvar(d_birth_enter  i_d_age_prim_befd_birth_all d_birth_all  i_d_age_prim_aftd_birth_all i_d_age_prim_befd_birth_all d_age_prim_bef d_lead_eth i_d_age_prim_befd_lead_eth) ///
	nocons addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))

* (5)  Now add d_ethnicity: d_lead_eth 
logit d_primary d_birth_all i_d_age_prim_aftd_birth_all d_age_prim_aft d_lead_eth      ///
	age  i_age_age  d_female  d_christian       ///
	lon_id_bir lat_id_bir i.cntry_code  ///
	if region=="Eastern Africa", vce(cluster tribe_co_1)
outreg2 using "micro.xls", append         ///
	tex addtext( Controls, 0, Region FE, yes)  ///
	ctitle("d_primary") dec(2) drop(i.cntry_code)   ///   
	sortvar(d_birth_enter i_d_age_prim_befd_birth_all d_birth_all i_d_age_prim_aftd_birth_all i_d_age_prim_befd_birth_all d_age_prim_bef d_lead_eth i_d_age_prim_befd_lead_eth)    ///
	nocons addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))  
 
* (6) Now add many other controls (maybe six or so)
logit d_primary d_birth_all i_d_age_prim_aftd_birth_all d_age_prim_aft  d_lead_eth      ///
	age  i_age_age  d_female  d_christian      ///
	d_france  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission   d_centraliz d_capital dist_cap lon_id_bir lat_id_bir  i.cntry_code     ///
	if region=="Eastern Africa", vce(cluster tribe_co_1)
outreg2 using "micro.xls", append  ///
	tex addtext( Controls, 0, Region FE, yes)    ///
	ctitle("d_primary") dec(2) drop(i.cntry_code)    /// 
	sortvar(d_birth_enter  i_d_age_prim_befd_birth_all 	d_birth_all i_d_age_prim_aftd_birth_all i_d_age_prim_befd_birth_all	 d_age_prim_bef d_lead_eth i_d_age_prim_befd_lead_eth)   ///
	nocons addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))	
	
	
	
	
	
	
	
	
	
	
*work on ethnic variable!!!!	
	
 
 * (3) Now add int_birthplace*ind (and remove d_ethnicity) but keep the controls
logit d_primary  d_birth_enter   age  i_age_age  d_female d_christian  d_france  tse_r   railway_density count_tribe slave_density  suit_cerea  d_mission  d_centraliz d_capital dist_cap lon_id_bir lat_id_bir i.cntry_code, vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append  ///
	tex addtext(Controls, 0, Region FE, yes)  ctitle("d_primary") dec(2) drop(i.geolev1) ///
	sortvar(d_birth_enter  d_birth_all i_d_age_prim_befd_birth_all	 d_age_prim_bef d_lead_eth i_d_age_prim_befd_lead_eth) ///
	nocons addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))

	
* (4) Now remove d_birthplace and int_birthplace*ind but include d_ethnicity and Int_ethnicity*ind and keep controls
logit d_primary   d_lead_eth   i_d_age_prim_aftd_lead_eth   age  i_age_age  d_female d_christian  d_france  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission     d_centraliz d_capital dist_cap lon_id_bir lat_id_bir i.cntry_code, vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append  ///
tex addtext(Controls, 0, Region FE, yes)  ctitle("d_primary") dec(2) drop(i.geolev1)  sortvar(d_birth_enter  d_birth_all i_d_age_prim_befd_birth_all	 d_age_prim_bef d_lead_eth i_d_age_prim_befd_lead_eth)  nocons addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust))

* (6) Now include everything plus six or eight main controls
logit d_primary  d_birth_enter  i_d_age_prim_befd_birth_all	   d_lead_eth   i_d_age_prim_aftd_lead_eth   age  i_age_age  d_female d_christian  d_france  tse_r   railway_density  count_tribe slave_density  suit_cerea  d_mission  d_centraliz d_capital dist_cap lon_id_bir lat_id_bir i.cntry_code, /// 
  vce(cluster tribe_co_1)
outreg2 using "2_micro.xls", append  ///
 tex addtext( Controls, 0, Region FE, yes)  ctitle("d_primary") dec(2) drop(i.geolev1)   sortvar(d_birth_enter  	d_birth_all i_d_age_prim_befd_birth_all	 d_age_prim_bef d_lead_eth i_d_age_prim_befd_lead_eth) nocons addstat(Pseudo R2, e(r2_p), id_birth, e(N_clust)) 
 

collapse (count) geolev2 , by(parent)

*replace d_birth_all=1 if  /*Maurice Kouandete id_birth== 20426 */
*replace d_birth_all=1 if  /*Tahirou Congacou	id_birth==20464	*/
*replace d_birth_all=1 if  /*Yusufu Lule	id_birth==80076*/


*----------------------------------------------------------------------------------------------------------------------------------------------
*----------------------------------------------------------------------------------------------------------------------------------------------
*----------------------------------------------------------------------------------------------------------------------------------------------

* End regression section (STOP) *
    
*----------------------------------------------------------------------------------------------------------------------------------------------
*----------------------------------------------------------------------------------------------------------------------------------------------

