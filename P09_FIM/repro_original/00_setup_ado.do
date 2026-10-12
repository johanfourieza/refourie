* P09_FIM S2: install ssc packages into the project-local adopath (environment only)
* Run from P09_FIM/repro_original/logs
clear all
set more off
net set ado "../ado"
adopath ++ "../ado"
capture noisily ssc install estout, replace
capture noisily ssc install coefplot, replace
which estout
which eststo
which coefplot
