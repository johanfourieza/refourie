* E4: project-local ado path; install estout (eststo/esttab) from SSC for productivity.do
sysdir set PLUS "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
ssc install estout, replace
which esttab
