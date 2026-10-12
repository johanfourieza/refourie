* S2 environment: install SSC packages into project-local adopath
version 16
local ado "./P23_MBF/repro_original/ado"
sysdir set PLUS "`ado'/plus"
sysdir set PERSONAL "`ado'/personal"
cap mkdir "`ado'/plus"
cap mkdir "`ado'/personal"
ssc install outreg2, replace
which outreg2
