* Environment: install user-written packages into the project-local ado path (not the system ado folder)
sysdir set PLUS "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
ssc install descogini, replace
ssc install egenmore, replace
ado dir
which descogini
which _gxtile
