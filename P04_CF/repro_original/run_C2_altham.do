* [ENV] run_C2_altham.do: lines 167-168 and 180-365 verbatim (self-contained: hard-coded frequencies); lines 170-178 fail on cleared data, see run_C1
version 15
clear all
sysdir set PLUS "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
do "`c(pwd)'/../../tools/paths.do"
global D "$DATA/P04_CF/original/CF Mobility/Data"
clear
set matsize 300
/* Read in the frequencies for tables p and q,
together with the character labels (father and son)
for columns and rows
*/
input str4 father str4 son p q
"1. w" "1. w" 432 684
"2. f" "1. w" 286 614
"3. s" "1. w" 104 176
"4. u" "1. w" 55 86
"1. w" "2. f" 257 270
"2. f" "2. f" 2170 2187
"3. s" "2. f" 147 92
"4. u" "2. f" 223 189
"1. w" "3. s" 70 126
"2. f" "3. s" 143 244
"3. s" "3. s" 139 132
"4. u" "3. s" 33 45
"1. w" "4. u" 35 17
"2. f" "4. u" 209 100
"3. s" "4. u" 30 7
"4. u" "4. u" 137 55
end

/* Change r and s below to reflect the dimensions of
your tables
*/

gen r=4
gen s=4
table son father [fw=p], row col
table son father [fw=q], row col
quietly generate logp=log(p)
quietly generate logq=log(q)
quietly generate logpq=log(p/q)
quietly encode father, gen(F)
quietly encode son, gen(S)
quietly anova logp F S
quietly gen dpi=sqrt(e(rss)*4*r*s)
display "d(P,I)=" dpi

quietly xi: glm p i.father i.son, f(poisson)
quietly gen g2p=e(deviance)
quietly gen g2pdf=e(df)
quietly gen g2probp=1-chi2(g2pdf,g2p)
display "G2=" g2p
display "degrees of freedom=" g2pdf
display "probability [H0: d(P,I)=0]=" g2probp
quietly anova logq F S
quietly gen dqi=sqrt(e(rss)*4*r*s)
display "d(Q,I)=" dqi
quietly xi: glm q i.father i.son, f(poisson)
quietly gen g2q=e(deviance)
quietly gen g2qdf=e(df)
quietly gen g2probq=1-chi2(g2qdf,g2q)
display "G2=" g2q
display "degrees of freedom=" g2qdf
display "probability [H0: d(Q,I)=0]=" g2probq
quietly anova logpq F S
quietly gen dpq=sqrt(e(rss)*4*r*s)
display "d(P,Q)=" dpq
quietly expand 2
quietly gen pq=p if _n < r*s+1
quietly gen str1 table="p" if _n < r*s+1
quietly replace pq=q if _n > r*s
quietly replace table="q" if _n > r*s
quietly xi: glm pq i.son i.father i.table i.son*i.father i.son*i.table i.father*i.table, f(poisson)
quietly gen g2pq=e(deviance)
quietly gen g2pqdf=e(df)
quietly gen g2probpq=1-chi2(g2pqdf,g2pq)
display "G2=" g2pq
display "degrees of freedom=" g2pqdf
display "probability [H0: d(P,Q)=0]=" g2probpq
/* Input the row totals for table p which we want
the new table qn to mimic
*/
gen rt = .
tokenize 1541 4140 2110 1208
qui forval i = 1/4 {
replace rt = `i' if S == `i'
}
/* Input the column totals for table p which we want
the new table qn to mimic
*/
gen ct = .
tokenize 682 5498 1875 944
qui forval i = 1/4 {
replace ct = `i' if F == `i'
}

replace rt=rt*2
replace ct=ct*2
mstdize q rt ct , by(S F) g(qn) center format(%9.0f)
replace qn=qn/2
/* Display the new table qn with the same
row and column totals as the original table p
*/
table son father [pw=qn], row col center format(%9.0f)

********************************************************************************
/* Quasi-independence measures */
********************************************************************************
clear
set matsize 300
/* Read in the frequencies for tables p and q again,
together with the character labels (father and son)
for columns and rows
*/
input str4 father str4 son p q
"1. w" "1. w" 432 684
"2. f" "1. w" 286 614
"3. s" "1. w" 104 176
"4. u" "1. w" 55 86
"1. w" "2. f" 257 270
"2. f" "2. f" 2170 2187
"3. s" "2. f" 147 92
"4. u" "2. f" 223 189
"1. w" "3. s" 70 126
"2. f" "3. s" 143 244
"3. s" "3. s" 139 132
"4. u" "3. s" 33 45
"1. w" "4. u" 35 17
"2. f" "4. u" 209 100
"3. s" "4. u" 30 7
"4. u" "4. u" 137 55
end

/* Change r and s below to reflect the dimensions of
your tables
*/
gen r=4
gen s=4
table son father [fw=p], row col
table son father [fw=q], row col
quietly generate logp=log(p)
quietly generate logq=log(q)
quietly generate logpq=log(p/q)
quietly encode father, gen(F)
quietly encode son, gen(S)

/* Generate a variable with a unique value
for each diagonal element, and another value
for all other elements
*/
gen ind = 5
qui forval i = 1/4 {
replace ind = F if F == S
}
/* Perform the same analysis as previously, but
include the variable that distinguishes the
diagonal elements from the off-diagonal elements
*/
quietly anova logp F S ind
quietly gen dpi=sqrt(e(rss)*4*r*s)
display "d(P,I)=" dpi
quietly xi: glm p i.father i.son i.ind, f(poisson)
quietly gen g2p=e(deviance)
quietly gen g2pdf=e(df)
quietly gen g2probp=1-chi2(g2pdf,g2p)
display "G2=" g2p
display "degrees of freedom=" g2pdf
display "probability [H0: d(P,I)=0]=" g2probp
quietly anova logq F S ind
quietly gen dqi=sqrt(e(rss)*4*r*s)
display "d(Q,I)=" dqi
quietly xi: glm q i.father i.son i.ind, f(poisson)
quietly gen g2q=e(deviance)
quietly gen g2qdf=e(df)
quietly gen g2probq=1-chi2(g2qdf,g2q)
display "G2=" g2q
display "degrees of freedom=" g2qdf
display "probability [H0: d(Q,I)=0]=" g2probq
quietly anova logpq F S ind
quietly gen dpq=sqrt(e(rss)*4*r*s)
display "d(P,Q)=" dpq
quietly expand 2
quietly gen pq=p if _n < r*s+1
quietly gen str1 table="p" if _n < r*s+1
quietly replace pq=q if _n > r*s
quietly replace table="q" if _n > r*s
quietly xi: glm pq i.son i.father i.table i.ind i.son*i.father i.son*i.table i.father*i.table i.ind*i.son i.ind*i.father i.ind*i.table, f(poisson)
quietly gen g2pq=e(deviance)
quietly gen g2pqdf=e(df)
quietly gen g2probpq=1-chi2(g2pqdf,g2pq)
display "G2=" g2pq
display "degrees of freedom=" g2pqdf
display "probability [H0: d(P,Q)=0]=" g2probpq
