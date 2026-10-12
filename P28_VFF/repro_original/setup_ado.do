* P28_VFF S2: install user-written packages into a project-local ado tree
* (never into C:\Users\johanf\ado, which lies outside Fourie_ReplicateMe).
version 19
sysdir set PLUS     "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
sysdir
cap log close
log using setup_ado_versions.log, text replace
foreach p in estout moransi shp2dta spmap blindschemes {
    ssc install `p', replace
}
ado dir
foreach f in estout esttab moransi shp2dta spmap {
    which `f'
}
findfile scheme-plottig.scheme
log close
