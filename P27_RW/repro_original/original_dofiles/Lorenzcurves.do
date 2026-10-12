*Lorenz curves for Cape Colony products

capture log close
clear
set mem 100m
set more off
use "C:\Documents and Settings\johanf\My Documents\Navorsing 1 Aug\Economic History\PhD Utrecht\1. Wealth in the Cape economy\statadata.dta", clear
log using lorenzcurves, replace

* Lorenz curves for vigades - beesten
glcurve  slaves if vigade == 1720, gl(gl1) p(p1) lorenz nograph
glcurve  slaves if vigade == 1740, gl(gl2) p(p2) lorenz nograph
glcurve  slaves if vigade == 1760, gl(gl3) p(p3) lorenz nograph
glcurve  slaves if vigade == 1780, gl(gl4) p(p4) lorenz nograph
glcurve  slaves if vigade == 1800, gl(gl5) p(p5) lorenz nograph

twoway (scatter gl1 p1, c(l) sort m(i)) (scatter gl2 p2, c(l) sort m(i)) (scatter gl3 p3, c(l) sort m(i)) (scatter gl4 p4, c(l) sort m(i)) (scatter gl5 p5, c(l) sort m(i)), legend(label(1 "1720") label(2 "1740") label(3 "1760") label(4 "1780") label(5 "1800"))

