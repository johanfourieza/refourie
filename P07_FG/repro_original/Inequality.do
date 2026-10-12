generate group1 = 0
replace group1 = 1 if slaves==0
generate group2 = 0
replace group2 = 1 if slaves>0 & slaves < 6
generate group3 = 0
replace group3 = 1 if slaves>5 & slaves < 16
generate group4 = 0
replace group4 = 1 if slaves>15
