* [ENV] install ssc packages project-locally
sysdir set PLUS "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
net set ado PLUS
ssc install outreg2, replace
which outreg2
