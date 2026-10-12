* P23_MBF S6: test inversion of card §4A steps 1-7 (used by 01_t2_inference.do and 03_sensitivities_t2.do).
* The fit command, cluster variable and weight variable are read from the globals FITCUR, CLUSCUR and WVARCUR.
* Requires Stata matrices R1..R6 (hypothesis rows) and INFO (rhat, s_h, offset) for the current fit.
* A grid point whose restricted refit fails after recovery R1 is unsupported (card §4A "Failure and recovery"):
* it is excluded from the evaluation set and counted; the refit does not depend on B, so a failure is cached and
* not recomputed (DEVIATIONS D8).
mata:
mata set matastrict off
EV = J(0, 6, .)          // h, r, p, conv, B, stage (1 grid, 2 bisection, 3 tail)
FAILK = J(0, 1, "")

real scalar sb_eval(real scalar h, real scalar r, real scalar B, real scalar stage)
{
	external real matrix EV
	external string colvector FAILK
	real scalar off, p, conv, fh
	string scalar key
	off = st_matrix("INFO")[h, 3]
	key = sprintf("%s|%s|%g|%21.17g", st_global("FITCUR"), st_global("CLUSCUR"), h, r)
	if (rows(FAILK) & anyof(FAILK, key)) {
		p = .; conv = 0
	}
	else {
		stata(sprintf("quietly sb_test, rmat(R%g) r(%21.0g) clus(%s) fitcmd(%s) wvar(%s) b(%g) recover",
		      h, off + r, st_global("CLUSCUR"), st_global("FITCUR"), st_global("WVARCUR"), B))
		p = st_numscalar("r(p)"); conv = st_numscalar("r(conv)")
		if (conv==0 | p>=.) {
			p = .
			FAILK = FAILK \ key
		}
	}
	EV = EV \ (h, r, p, conv, B, stage)
	// progress log (aggregate p-values only) on D:
	fh = fopen(st_global("SCR") + "/progress_" + st_global("PROGTAG") + ".txt", "a")
	fput(fh, sprintf("%s h=%g r=%21.17g p=%g conv=%g B=%g stage=%g", c("current_time"), h, r, p, conv, B, stage))
	fclose(fh)
	return(p)
}

// returns segments (lo, hi, lo_resolved, hi_resolved); FL = (n_unsupported, cn_status, n_evals)
// cn_status (h >= 5 only): 1 inside the open band, 0 not inside, -1 undecidable; . for h < 5
real matrix sb_invert(real scalar h, real scalar B, real rowvector FL)
{
	real scalar rhat, s, astar, band, k, i, lo, hi, pm, it, mid, nuns, anyout, allres, cn, nev
	real colvector pts, p, acc, ext, o, sup
	real matrix seg, BIS
	rhat = st_matrix("INFO")[h,1]; s = st_matrix("INFO")[h,2]
	astar = 0.05/6; band = 0.5*ln(1.32)
	nuns = 0; anyout = 0; allres = 1; nev = 0
	// step 1: evaluation set
	pts = 0 \ rhat
	for (k=1; k<=24; k++) pts = pts \ rhat + k*s/2 \ rhat - k*s/2 \ rhat + (k-.5)*s/2 \ rhat - (k-.5)*s/2
	if (h>=5) pts = pts \ -band \ band
	pts = uniqrows(pts)
	p = J(rows(pts), 1, .)
	for (i=1; i<=rows(pts); i++) p[i] = sb_eval(h, pts[i], B, 1)
	nev = rows(pts)
	// step 3: tails, judged on the outermost supported point of each side
	sup = selectindex(p :< .)
	if (rows(sup)) {
		if (p[sup[1]] >= astar) {
			ext = J(0,1,.)
			for (k=25; k<=48; k++) ext = ext \ rhat - k*s/2 \ rhat - (k-.5)*s/2
			for (i=1; i<=rows(ext); i++) {
				pts = pts \ ext[i]
				p = p \ sb_eval(h, ext[i], B, 3)
			}
			nev = nev + rows(ext)
		}
		if (p[sup[rows(sup)]] >= astar) {
			ext = J(0,1,.)
			for (k=25; k<=48; k++) ext = ext \ rhat + k*s/2 \ rhat + (k-.5)*s/2
			for (i=1; i<=rows(ext); i++) {
				pts = pts \ ext[i]
				p = p \ sb_eval(h, ext[i], B, 3)
			}
			nev = nev + rows(ext)
		}
	}
	nuns = sum(p :>= .)
	// unsupported points are excluded from the set
	o = order(pts, 1); pts = pts[o]; p = p[o]
	sup = selectindex(p :< .)
	pts = pts[sup]; p = p[sup]
	if (rows(pts)==0) {
		FL = (nuns, (h>=5 ? -1 : .), nev)
		return(J(0,4,.))
	}
	acc = p :>= astar
	anyout = sum(acc :& (abs(pts) :>= band)) > 0
	// step 2: bisection between adjacent accepted/rejected supported points
	BIS = J(rows(pts)-1, 2, .)
	for (i=1; i<rows(pts); i++) {
		if (acc[i]==acc[i+1]) continue
		lo = acc[i]? pts[i] : pts[i+1]
		hi = acc[i]? pts[i+1] : pts[i]
		it = 0
		while (abs(hi-lo) >= 1e-3*s & it < 30) {
			mid = (lo+hi)/2
			pm = sb_eval(h, mid, B, 2)
			nev++
			if (pm >= .) {
				nuns++
				break
			}
			if (pm >= astar) {
				lo = mid
				if (abs(mid) >= band) anyout = 1
			}
			else hi = mid
			it++
		}
		BIS[i,] = (lo, abs(hi-lo) < 1e-3*s)
	}
	// step 4: segments = runs of accepted supported points
	seg = J(0, 4, .)
	i = 1
	while (i <= rows(pts)) {
		if (!acc[i]) {
			i++
			continue
		}
		k = i
		while (k < rows(pts) & acc[k+1]) k++
		seg = seg \ ((i==1? pts[1] : BIS[i-1,1]), (k==rows(pts)? pts[k] : BIS[k,1]),
		             (i==1? 0 : BIS[i-1,2]), (k==rows(pts)? 0 : BIS[k,2]))
		i = k + 1
	}
	// step 6: credible-null condition for h5, h6
	cn = .
	if (h>=5) {
		if (anyout) cn = 0
		else {
			allres = (nuns==0)
			for (i=1; i<=rows(seg); i++) {
				if (seg[i,3]==0 | seg[i,4]==0 | abs(seg[i,1])>=band | abs(seg[i,2])>=band) allres = 0
			}
			cn = (allres ? 1 : -1)
		}
	}
	FL = (nuns, cn, nev)
	return(seg)
}
end
