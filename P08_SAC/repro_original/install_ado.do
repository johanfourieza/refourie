* [ENV] install ssc packages into the project-local PLUS (system ado path untouched)
sysdir set PLUS "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
ssc install estout, replace
ssc install cibar, replace
which estout
which cibar
ado describe
