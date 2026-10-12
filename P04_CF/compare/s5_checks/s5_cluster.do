* S5 C4 / C1 / duplicates: Table 11 with father-clustered SEs. Run from $DATA/P04_CF/compare/_scratch_s5 (A6: data root on D:).
version 15
clear all
set more off
do "./tools/paths.do"
use "$DATA/P04_CF/original/CF Mobility/Data/CF_mobility_replication_data_anonymized.dta", clear
merge 1:1 id using "clusters.dta", assert(match) nogen
decode share, gen(sh_str)
gen share_true = real(sh_str)
* check: true share = % of fathers in class within period
bysort period: egen np = count(id)
bysort period f_occ_group_last: egen nc = count(id)
gen sh_chk = round(100*nc/np, .01)
count if abs(sh_chk - share_true) > .006
char period [omit] 1
* Model 1 (published) conventional vs clustered
xi: logit mobility_last i.period i.origin i.f_gen i.first_son i.prov
est store m1
xi: logit mobility_last i.period i.origin i.f_gen i.first_son i.prov, vce(cluster clus_n)
est store m1c
* Published Model 2 (= Model 1 + father's class)
xi: logit mobility_last i.period i.origin i.f_gen i.first_son i.prov i.f_occ_group_last
est store m2
xi: logit mobility_last i.period i.origin i.f_gen i.first_son i.prov i.f_occ_group_last, vce(cluster clus_n)
est store m2c
* Model 3 as coded (share = label code)
xi: logit mobility_last i.period i.origin i.f_gen i.first_son i.prov share i.f_occ_group_last
est store m3
xi: logit mobility_last i.period i.origin i.f_gen i.first_son i.prov share i.f_occ_group_last, vce(cluster clus_n)
est store m3c
* Model 3 with true share, clustered
xi: logit mobility_last i.period i.origin i.f_gen i.first_son i.prov share_true i.f_occ_group_last, vce(cluster clus_n)
est store m3tc
* Duplicates dropped (159 second records), Model 1 and Model 3 as coded
xi: logit mobility_last i.period i.origin i.f_gen i.first_son i.prov if dupflag==0
est store m1d
xi: logit mobility_last i.period i.origin i.f_gen i.first_son i.prov share i.f_occ_group_last if dupflag==0
est store m3d
estimates table m1 m1c m2 m2c m3 m3c m3tc m1d m3d, eform b(%9.4f) p(%9.4f) keep(_Iperiod_2 _Iperiod_3 _Iperiod_4 _If_gen_1 share share_true _If_occ_gro_2 _If_occ_gro_3 _If_occ_gro_4)
* Relative risks (C3): modified Poisson, Model 1 and Model 3 as coded, clustered
xi: glm mobility_last i.period i.origin i.f_gen i.first_son i.prov, family(poisson) link(log) vce(cluster clus_n) eform
est store rr1
xi: glm mobility_last i.period i.origin i.f_gen i.first_son i.prov share i.f_occ_group_last, family(poisson) link(log) vce(cluster clus_n) eform
est store rr3
estimates table rr1 rr3, eform b(%9.4f) p(%9.4f) keep(_Iperiod_2 _Iperiod_3 _Iperiod_4 _If_gen_1 share)
summarize mobility_last
