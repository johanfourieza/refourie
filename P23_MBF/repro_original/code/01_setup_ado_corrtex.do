version 16
local ado "./P23_MBF/repro_original/ado"
sysdir set PLUS "`ado'/plus"
sysdir set PERSONAL "`ado'/personal"
ssc install corrtex, replace
which corrtex
which outreg2
