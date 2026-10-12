* S2 PATCHED RUN FILE (environment only; see PATCHES.md). Lines 44-104 of 1_micro_all_primary_idbirth_regression_analysis_220131.do, verbatim except the use statement.
version 16
clear all
set more off
local ado "./P23_MBF/repro_original/ado"
sysdir set PLUS "`ado'/plus"
sysdir set PERSONAL "`ado'/personal"
do "./tools/paths.do"
cd "./P23_MBF/repro_original/out_t2"
timer on 1
******************************************* Table 2, coefficientes, no controls ***********************
* same reuslts clustered at tribe_co_1
*Nota: independence corresponds to r (independene achieved in region of birth) and this can differ from country fixed effcts. 

* (1) Region of birth of ALL leader
use cntry_code cntry_name id_birth tribe_co_1 d_primary d_birth d_birth_all d_birth_coup d_birth_elite d_age_prim_bef d_ethnic age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_centraliz d_capital dist_cap d_western lat_id_bir lon_id_bir prim_in_plus2 prim_in_plus3 using "$DATA/P23_MBF/original/ld/1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear  /* Final dataset, built in do file: "1_micro_all_primary_idbirth_datasetconstruction_20200511.do" */
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
	


timer off 1
timer list 1
