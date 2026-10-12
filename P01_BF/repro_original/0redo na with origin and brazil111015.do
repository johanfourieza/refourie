*do -file to process the South African criminal records who were recorded by Gustave # in the Cape Town Archive, and 
*will be analyzed by Joerg Baten and Johan Fourie. Laura Rossouw has signed a form that she will only use it for her
*master seminar at Tuebingen Univ, so she may also analyse the data.

clear
*edit
**paste from Excel file book1800-
*save "g:\a\ha\from.dta"
*clear
*edit
**paste from Excel file book1
*save "g:\a\ha\early.dta"
*append using "g:\a\ha\from.dta"
*save "g:\a\na\na110421.dta", replace

cd "g:\a\na"
set mem 400m
use "na110421.dta", clear
replace knows="gissing" if knows=="Gissing"
g knowsage=0
replace knowsage=0 if knows=="gissing"
replace knowsage=1 if knows=="nie"
replace knowsage=. if knows~="gissing" & knows~="nie"
drop if name==""
*ren year cyear
*g byear=cyear-age
drop if name=="Slawe, Khoisan en ander wat aan die Kaap weens Kriminele klagte teen hulle gevonnis was (1700 - 1800)"
g eths=""
*definition eths: I checked whether convicts, bandiet, krygsgevangene etc were listed between the blacks, and as they were, I assigned "bl" (there was one exception for bandiet)
*but a more careful analysis of the names (and perhaps typical crimes) could lead to a refinement
replace eths="cn" if eth=="Chinees"
replace eths="eu" if eth=="Europees"
replace eths="bl" if eth=="Lyfeienis"
replace eths="bl" if eth=="apprentice"
replace eths="bl" if eth=="bandiet"
replace eths="bl" if eth=="banneling"
replace eths="bl" if eth=="convict"
replace eths="ko" if eth=="kiosan"
replace eths="ko" if eth=="koisan"
replace eths="bl" if eth=="krygsgevangene"
replace eths="bl" if eth=="lyfeienis"
replace eths="bl" if eth=="mardyker"
replace eths="ko" if eth=="nie-blank"
replace eths="ko" if eth=="nie-blank (khoikoi)"
replace eths="ko" if eth=="nie-blank/Koisan"
replace eths="bl" if eth=="slaaf"
replace eths="bl" if eth=="vryswarte"
replace eths="eu" if eth=="" & strpos(name,"van de Kaap")==0
*because their names and position withhin the file suggested that those 6 were Europeans
replace eths="bl" if eth=="" & strpos(name,"van de Kaap")>0
*because the naming "van de Kaap" was almost exclusively used for black, including probably those 2

replace eths="eu" if eth=="bandiet" & name=="Michiel van Wyk"

g slave=0
replace slave=1 if eth=="slaaf"
g lyfeienis=0
replace lyfeienis=1 if eth=="lyfeienis" | eth=="Lyfeienis"
g ko=0
replace ko=1 if eths=="ko"
g bl=0
replace bl=1 if eths=="bl"
g cn=0
replace cn=1 if eths=="cn"
g eu=0
replace eu=1 if eths=="eu"


g mult5=0
replace mult5=1 if age/5==floor(age/5)
g exactage=1
replace exactage=0 if mult==1
g agegr=.
replace agegr=23 if age>=23 & age<=32
replace agegr=33 if age>=33 & age<=42
replace agegr=43 if age>=43 & age<=52
replace agegr=53 if age>=53 & age<=62
replace agegr=63 if age>=63 & age<=72
g agegr23=agegr
replace agegr23=33 if agegr>23 & agegr~=.
g age23=0
replace age23=1 if agegr==23
g bdec=cyear-(agegr+5)
replace bdec=floor(bdec/10)*10
g halfc=floor(bdec/50)*50
*-----------------------------sex classification
g number=_n
g female=0
*in the following, I assigned female names as they seemed to fit, from a German-native speaker perspektive
*this should be counter-checked by 1 or 2 afrikaans or dutch-speaking persons (and some doubt cases could be researched)
*sometimes a month or day-of-week is used. I assumed this would be more common among male slaves.
*if names ended with an -a, I assumed a female, even for "Africa", which could also be males (sometimes it was positioned between male names)
replace female=1 if number==	7
replace female=1 if number==	353
replace female=1 if number==	357
replace female=1 if number==	363
replace female=1 if number==	364
replace female=1 if number==	383
replace female=1 if number==	466
replace female=1 if number==	492
replace female=1 if number==	493
replace female=1 if number==	495
replace female=1 if number==	497
replace female=1 if number==	500
replace female=1 if number==	509
replace female=1 if number==	546
replace female=1 if number==	577
replace female=1 if number==	578
replace female=1 if number==	579
replace female=1 if number==	580
replace female=1 if number==	597
replace female=1 if number==	598
replace female=1 if number==	613
replace female=1 if number==	665
replace female=1 if number==	676
replace female=1 if number==	685
replace female=1 if number==	700
replace female=1 if number==	732
replace female=1 if number==	733
replace female=1 if number==	735
replace female=1 if number==	736
replace female=1 if number==	737
replace female=1 if number==	779
replace female=1 if number==	781
replace female=1 if number==	782
replace female=1 if number==	783
replace female=1 if number==	784
replace female=1 if number==	785
replace female=1 if number==	786
replace female=1 if number==	787
replace female=1 if number==	788
replace female=1 if number==	789
replace female=1 if number==	792
replace female=1 if number==	813
replace female=1 if number==	833
replace female=1 if number==	835
replace female=1 if number==	841
replace female=1 if number==	844
replace female=1 if number==	845
replace female=1 if number==	869
replace female=1 if number==	875
replace female=1 if number==	876
replace female=1 if number==	877
replace female=1 if number==	900
replace female=1 if number==	901
replace female=1 if number==	902
replace female=1 if number==	903
replace female=1 if number==	904
replace female=1 if number==	913
replace female=1 if number==	914
replace female=1 if number==	962
replace female=1 if number==	976
replace female=1 if number==	995
replace female=1 if number==	996
replace female=1 if number==	1005
replace female=1 if number==	1006
replace female=1 if number==	1010
replace female=1 if number==	1011
replace female=1 if number==	1012
replace female=1 if number==	1013
replace female=1 if number==	1014
replace female=1 if number==	1018
replace female=1 if number==	1019
replace female=1 if number==	1030
replace female=1 if number==	1036
replace female=1 if number==	1037
replace female=1 if number==	1038
replace female=1 if number==	1039
replace female=1 if number==	1040
replace female=1 if number==	1041
replace female=1 if number==	1063
replace female=1 if number==	1066
replace female=1 if number==	1067
replace female=1 if number==	1068
replace female=1 if number==	1084
replace female=1 if number==	1092
replace female=1 if number==	1093
replace female=1 if number==	1094
replace female=1 if number==	1111
replace female=1 if number==	1160
replace female=1 if number==	1194
replace female=1 if number==	1203
replace female=1 if number==	1206
replace female=1 if number==	1218
replace female=1 if number==	1219
replace female=1 if number==	1220
replace female=1 if number==	1222
replace female=1 if number==	1230
replace female=1 if number==	1261
replace female=1 if number==	1269
replace female=1 if number==	1270
replace female=1 if number==	1273
replace female=1 if number==	1274
replace female=1 if number==	1289
replace female=1 if number==	1295
replace female=1 if number==	1308
replace female=1 if number==	1312
replace female=1 if number==	1317
replace female=1 if number==	1319
replace female=1 if number==	1320
replace female=1 if number==	1325
replace female=1 if number==	1348
replace female=1 if number==	1353
replace female=1 if number==	1370
replace female=1 if number==	1385
replace female=1 if number==	1389
replace female=1 if number==	1396
replace female=1 if number==	1400
replace female=1 if number==	1404
replace female=1 if number==	1409
replace female=1 if number==	1410
replace female=1 if number==	1411
replace female=1 if number==	1412
replace female=1 if number==	1414
replace female=1 if number==	1418
replace female=1 if number==	1419
replace female=1 if number==	1436
replace female=1 if number==	1485
replace female=1 if number==	1497
replace female=1 if number==	1528
replace female=1 if number==	1530
replace female=1 if number==	1537
replace female=1 if number==	1538
replace female=1 if number==	1559
replace female=1 if number==	1563
replace female=1 if number==	1574
replace female=1 if number==	1578
replace female=1 if number==	1583
replace female=1 if number==	1597
replace female=1 if number==	1602
replace female=1 if number==	1615
replace female=1 if number==	1618
replace female=1 if number==	1625
replace female=1 if number==	1655
replace female=1 if number==	1668
replace female=1 if number==	1669
replace female=1 if number==	1672
replace female=1 if number==	1673
replace female=1 if number==	1674
replace female=1 if number==	1676
replace female=1 if number==	1677
replace female=1 if number==	1678
replace female=1 if number==	1684
replace female=1 if number==	1690
replace female=1 if number==	1709
replace female=1 if number==	1710
replace female=1 if number==	1718
replace female=1 if number==	1720
replace female=1 if number==	1722
replace female=1 if number==	1729
replace female=1 if number==	1734
replace female=1 if number==	1743
replace female=1 if number==	1746
replace female=1 if number==	1753
replace female=1 if number==	1754
replace female=1 if number==	1755
replace female=1 if number==	1756
replace female=1 if number==	1767
replace female=1 if number==	1802
replace female=1 if number==	1806
replace female=1 if number==	1835
replace female=1 if number==	1878
replace female=1 if number==	1891
replace female=1 if number==	1892
replace female=1 if number==	1901
replace female=1 if number==	1921
replace female=1 if number==	1922
replace female=1 if number==	1923
replace female=1 if number==	1924
replace female=1 if number==	1926
replace female=1 if number==	1927
replace female=1 if number==	1928
replace female=1 if number==	1929
replace female=1 if number==	1935
replace female=1 if number==	1936
replace female=1 if number==	1944
replace female=1 if number==	1945
replace female=1 if number==	1966
replace female=1 if number==	1977
replace female=1 if number==	1986
replace female=1 if number==	2051
replace female=1 if number==	2054
replace female=1 if number==	2061
replace female=1 if number==	2062
replace female=1 if number==	2066
replace female=1 if number==	2093
replace female=1 if number==	2101
replace female=1 if number==	2128
replace female=1 if number==	2142
replace female=1 if number==	2156
replace female=1 if number==	2159
replace female=1 if number==	2172
replace female=1 if number==	2173
replace female=1 if number==	2184
replace female=1 if number==	2191
replace female=1 if number==	2201
replace female=1 if number==	2232
replace female=1 if number==	2233
replace female=1 if number==	2235
replace female=1 if number==	2236
replace female=1 if number==	2237
replace female=1 if number==	2238
replace female=1 if number==	2239
replace female=1 if number==	2240
replace female=1 if number==	2260
replace female=1 if number==	2265
replace female=1 if number==	2291
replace female=1 if number==	2298
replace female=1 if number==	2299
replace female=1 if number==	2300
replace female=1 if number==	2301
replace female=1 if number==	2322
replace female=1 if number==	2323
replace female=1 if number==	2340
replace female=1 if number==	2341
replace female=1 if number==	2342
replace female=1 if number==	2343
replace female=1 if number==	2344
replace female=1 if number==	2345
replace female=1 if number==	2346
replace female=1 if number==	2347
replace female=1 if number==	2354
replace female=1 if number==	2357
replace female=1 if number==	2358
replace female=1 if number==	2359
replace female=1 if number==	2368
replace female=1 if number==	2369
replace female=1 if number==	2391
replace female=1 if number==	2392
replace female=1 if number==	2393
replace female=1 if number==	2398
replace female=1 if number==	2402
replace female=1 if number==	2409
replace female=1 if number==	2413
replace female=1 if number==	2416
replace female=1 if number==	2419
replace female=1 if number==	2427
replace female=1 if number==	2432
replace female=1 if number==	2442
replace female=1 if number==	2446
replace female=1 if number==	2452
replace female=1 if number==	2462
replace female=1 if number==	2480
replace female=1 if number==	2488
replace female=1 if number==	2500
replace female=1 if number==	2502
replace female=1 if number==	2503
replace female=1 if number==	2509
replace female=1 if number==	2511
replace female=1 if number==	2519
replace female=1 if number==	2520
replace female=1 if number==	2531
replace female=1 if number==	2532
replace female=1 if number==	2533
replace female=1 if number==	2534
replace female=1 if number==	2535
replace female=1 if number==	2539
replace female=1 if number==	2541
replace female=1 if number==	2550
replace female=1 if number==	2554
replace female=1 if number==	2555
replace female=1 if number==	2557
replace female=1 if number==	2568
replace female=1 if number==	2576
replace female=1 if number==	2581
replace female=1 if number==	2582
replace female=1 if number==	2589
replace female=1 if number==	2593
replace female=1 if number==	2620
replace female=1 if number==	2642
replace female=1 if number==	2644
replace female=1 if number==	2645
replace female=1 if number==	2646
replace female=1 if number==	2651
replace female=1 if number==	2654
replace female=1 if number==	2663
replace female=1 if number==	2665
replace female=1 if number==	2669
replace female=1 if number==	2672
replace female=1 if number==	2676
replace female=1 if number==	2677
replace female=1 if number==	2679
replace female=1 if number==	2690
replace female=1 if number==	2691
replace female=1 if number==	2705
replace female=1 if number==	2706
replace female=1 if number==	2742
replace female=1 if number==	2744
replace female=1 if number==	2749
replace female=1 if number==	2751
replace female=1 if number==	2761
replace female=1 if number==	2764
replace female=1 if number==	2765
replace female=1 if number==	2772
replace female=1 if number==	2776
replace female=1 if number==	2777
replace female=1 if number==	2797
replace female=1 if number==	2798
replace female=1 if number==	2806
replace female=1 if number==	2808
replace female=1 if number==	2810
replace female=1 if number==	2812
replace female=1 if number==	2840
replace female=1 if number==	2846
replace female=1 if number==	2849
replace female=1 if number==	2865
replace female=1 if number==	2867
replace female=1 if number==	2878
replace female=1 if number==	2880
replace female=1 if number==	2897
replace female=1 if number==	2898
replace female=1 if number==	2900
replace female=1 if number==	2901
replace female=1 if number==	2903
replace female=1 if number==	2907

generate female2 = 0
replace female2=1 if number==30
replace female2=1 if number== 52
replace female2=1 if number== 73
replace female2=1 if number== 171
replace female2=1 if number== 224
replace female2=1 if number== 267
replace female2=1 if number== 353
replace female2=1 if number== 357
replace female2=1 if number== 363
replace female2=1 if number== 364
replace female2=1 if number== 383
replace female2=1 if number== 386
replace female2=1 if number== 387
replace female2=1 if number== 388
replace female2=1 if number== 389
replace female2=1 if number== 390
replace female2=1 if number== 391
replace female2=1 if number== 392
replace female2=1 if number== 393
replace female2=1 if number== 394
replace female2=1 if number== 395
replace female2=1 if number== 396
replace female2=1 if number== 397
replace female2=1 if number== 398
replace female2=1 if number== 399
replace female2=1 if number== 400
replace female2=1 if number== 401
replace female2=1 if number== 402
replace female2=1 if number== 403
replace female2=1 if number== 404
replace female2=1 if number== 405
replace female2=1 if number== 406
replace female2=1 if number== 466
replace female2=1 if number== 479
replace female2=1 if number== 487
replace female2=1 if number==492
replace female2=1 if number==493
replace female2=1 if number==495
replace female2=1 if number==497
replace female2=1 if number==500
replace female2=1 if number== 509
replace female2=1 if number== 546
replace female2=1 if number== 577
replace female2=1 if number== 578
replace female2=1 if number== 579
replace female2=1 if number== 580
replace female2=1 if number== 597
replace female2=1 if number==598
replace female2=1 if number==613
replace female2=1 if number== 676
replace female2=1 if number== 685
replace female2=1 if number== 697
replace female2=1 if number==700
replace female2=1 if number== 719
replace female2=1 if number== 731
replace female2=1 if number== 776 
replace female2=1 if number== 813
replace female2=1 if number==814
replace female2=1 if number==815
replace female2=1 if number==816
replace female2=1 if number==817
replace female2=1 if number==818
replace female2=1 if number==819
replace female2=1 if number==820
replace female2=1 if number==821
replace female2=1 if number==822
replace female2=1 if number==823
replace female2=1 if number==824
replace female2=1 if number==825
replace female2=1 if number==826
replace female2=1 if number==827
replace female2=1 if number==828
replace female2=1 if number==829
replace female2=1 if number== 833
replace female2=1 if number==835
replace female2=1 if number== 844
replace female2=1 if number== 845
replace female2=1 if number== 875
replace female2=1 if number==876
replace female2=1 if number==877
replace female2=1 if number==880
replace female2=1 if number==881
replace female2=1 if number==882
replace female2=1 if number==894
replace female2=1 if number==895
replace female2=1 if number==896
replace female2=1 if number==897
replace female2=1 if number==898
replace female2=1 if number==899
replace female2=1 if number==900
replace female2=1 if number==901
replace female2=1 if number==902
replace female2=1 if number==903
replace female2=1 if number==904
replace female2=1 if number==913
replace female2=1 if number==914
replace female2=1 if number==976
replace female2=1 if number==1005
replace female2=1 if number==1010
replace female2=1 if number==1011
replace female2=1 if number==1012
replace female2=1 if number==1013
replace female2=1 if number==1014
replace female2=1 if number==1018
replace female2=1 if number==1019
replace female2=1 if number==1036
replace female2=1 if number==1037
replace female2=1 if number==1038
replace female2=1 if number==1039
replace female2=1 if number==1040
replace female2=1 if number==1041
replace female2=1 if number==1063
replace female2=1 if number==1066
replace female2=1 if number==1067
replace female2=1 if number==1068
replace female2=1 if number==1084
replace female2=1 if number==1092
replace female2=1 if number==1094
replace female2=1 if number==1093 
replace female2=1 if number==1094
replace female2=1 if number==1111
replace female2=1 if number==1142
replace female2=1 if number==1194
replace female2=1 if number==1203
replace female2=1 if number==1204
replace female2=1 if number==1218
replace female2=1 if number==1219
replace female2=1 if number==1220
replace female2=1 if number==1221
replace female2=1 if number==1222
replace female2=1 if number==1261
replace female2=1 if number==1270
replace female2=1 if number==1273
replace female2=1 if number==1289
replace female2=1 if number==1298
replace female2=1 if number==1308
replace female2=1 if number==1317
replace female2=1 if number==1320
replace female2=1 if number==1324
replace female2=1 if number==1329
replace female2=1 if number==1353
replace female2=1 if number==1370
replace female2=1 if number==1389
replace female2=1 if number==1400
replace female2=1 if number==1404
replace female2=1 if number==1418
replace female2=1 if number==1409
replace female2=1 if number==1410
replace female2=1 if number==1411
replace female2=1 if number==1412
replace female2=1 if number==1414
replace female2=1 if number==1419 
replace female2=1 if number==1436
replace female2=1 if number==1445
replace female2=1 if number==1469
replace female2=1 if number==1471
replace female2=1 if number==1485
replace female2=1 if number==1528
replace female2=1 if number==1529
replace female2=1 if number==1530
replace female2=1 if number==1558
replace female2=1 if number==1559
replace female2=1 if number==1563
replace female2=1 if number==1574
replace female2=1 if number==1578
replace female2=1 if number==1583
replace female2=1 if number==1597
replace female2=1 if number==1615
replace female2=1 if number==1618
replace female2=1 if number==1621
replace female2=1 if number==1625
replace female2=1 if number==1631
replace female2=1 if number==1664
replace female2=1 if number==1668
replace female2=1 if number==1669
replace female2=1 if number==1672
replace female2=1 if number==1673
replace female2=1 if number==1674
replace female2=1 if number==1676
replace female2=1 if number==1677
replace female2=1 if number==1678
replace female2=1 if number==1684
replace female2=1 if number==1690
replace female2=1 if number==1709
replace female2=1 if number==1718
replace female2=1 if number==1720
replace female2=1 if number==1729
replace female2=1 if number==1722
replace female2=1 if number==1734
replace female2=1 if number==1753
replace female2=1 if number==1754
replace female2=1 if number==1800
replace female2=1 if number==1801
replace female2=1 if number==1802
replace female2=1 if number==1812
replace female2=1 if number==1816
replace female2=1 if number==1823
replace female2=1 if number==1849
replace female2=1 if number==1877
replace female2=1 if number==1878
replace female2=1 if number==1892
replace female2=1 if number==1901
replace female2=1 if number==1913
replace female2=1 if number==1923
replace female2=1 if number==1924
replace female2=1 if number==1926
replace female2=1 if number==1927
replace female2=1 if number==1945
replace female2=1 if number==1966
replace female2=1 if number==1967
replace female2=1 if number==1972
replace female2=1 if number==1977
replace female2=1 if number==1986
replace female2=1 if number==1987
replace female2=1 if number==2051
replace female2=1 if number==2054
replace female2=1 if number==2062
replace female2=1 if number==2067
replace female2=1 if number==2093
replace female2=1 if number==2101
replace female2=1 if number==2118
replace female2=1 if number==2122
replace female2=1 if number==2124
replace female2=1 if number==2125
replace female2=1 if number==2142
replace female2=1 if number==2152
replace female2=1 if number==2156
replace female2=1 if number==2159
replace female2=1 if number==2162
replace female2=1 if number==2164
replace female2=1 if number==2172
replace female2=1 if number==2184
replace female2=1 if number==2191
replace female2=1 if number==2224
replace female2=1 if number==2232
replace female2=1 if number==2235
replace female2=1 if number==2236
replace female2=1 if number==2239
replace female2=1 if number==2240
replace female2=1 if number==2242
replace female2=1 if number==2255
replace female2=1 if number==2260
replace female2=1 if number==2279
replace female2=1 if number==2289
replace female2=1 if number==2322
replace female2=1 if number==2323
replace female2=1 if number==2341
replace female2=1 if number==2342
replace female2=1 if number==2343
replace female2=1 if number==2345
replace female2=1 if number==2346
replace female2=1 if number==2347
replace female2=1 if number==2362
replace female2=1 if number==2367
replace female2=1 if number==2389
replace female2=1 if number==2391
replace female2=1 if number==2392
replace female2=1 if number==2393
replace female2=1 if number==2409
replace female2=1 if number==2413
replace female2=1 if number==2416
replace female2=1 if number==2419
replace female2=1 if number==2427
replace female2=1 if number==2432
replace female2=1 if number==2462
replace female2=1 if number==2469
replace female2=1 if number==2480
replace female2=1 if number==2488
replace female2=1 if number==2502
replace female2=1 if number==2503
replace female2=1 if number==2516
replace female2=1 if number==2519
replace female2=1 if number==2520
replace female2=1 if number==2531
replace female2=1 if number==2532
replace female2=1 if number==2539
replace female2=1 if number==2550 
replace female2=1 if number==2552
replace female2=1 if number==2554
replace female2=1 if number==2555
replace female2=1 if number==2557
replace female2=1 if number==2559
replace female2=1 if number==2568
replace female2=1 if number==2589
replace female2=1 if number==2593
replace female2=1 if number==2640
replace female2=1 if number==2642
replace female2=1 if number==2643
replace female2=1 if number==2644
replace female2=1 if number==2645
replace female2=1 if number==2646
replace female2=1 if number==2653
replace female2=1 if number==2669
replace female2=1 if number==2672
replace female2=1 if number==2676
replace female2=1 if number==2679
replace female2=1 if number==2702
replace female2=1 if number==2705
replace female2=1 if number==2706
replace female2=1 if number==2743
replace female2=1 if number==2754
replace female2=1 if number==2761
replace female2=1 if number==2764
replace female2=1 if number==2765 
replace female2=1 if number==2772
replace female2=1 if number==2776
replace female2=1 if number==2777
replace female2=1 if number==2783
replace female2=1 if number==2792
replace female2=1 if number==2797
replace female2=1 if number==2798
replace female2=1 if number==2808
replace female2=1 if number==2810
replace female2=1 if number==2827
replace female2=1 if number==2838
replace female2=1 if number==2844
replace female2=1 if number==2878
replace female2=1 if number==2897
replace female2=1 if number==2900
replace female2=1 if number==2901
replace female2=1 if number==2903
replace female2=1 if number==2907

generate female3=female2
 
replace female3=0 if number==386
replace female3=0 if number==387 
replace female3=0 if number==388
replace female3=0 if number==389 
replace female3=0 if number==390
replace female3=0 if number==391 
replace female3=0 if number==392
replace female3=0 if number==393 
replace female3=0 if number==394
replace female3=0 if number==395 
replace female3=0 if number==396
replace female3=0 if number==397 
replace female3=0 if number==398
replace female3=0 if number==399 
replace female3=0 if number==400
replace female3=0 if number==401 
replace female3=0 if number==402
replace female3=0 if number==403 
replace female3=0 if number==404
replace female3=0 if number==405
 
replace female3=0 if number==880
replace female3=0 if number==881
replace female3=0 if number==894
replace female3=0 if number==895
replace female3=0 if number==896
replace female3=0 if number==897
replace female3=0 if number==898

replace female3=0 if number==1557
replace female3=0 if number==2388
replace female3=0 if number==828

replace female3=0 if number==813
replace female3=0 if number==814
replace female3=0 if number==815
replace female3=0 if number==816
replace female3=0 if number==817
replace female3=0 if number==818
replace female3=0 if number==819
replace female3=0 if number==820
replace female3=0 if number==821
replace female3=0 if number==822
replace female3=0 if number==823
replace female3=0 if number==824
replace female3=0 if number==825
replace female3=0 if number==826
replace female3=0 if number==827
replace female3=0 if number==1220
replace female3=0 if number==1203
replace female3=0 if number==1324
replace female3=0 if number==1468
replace female3=0 if number==2642
replace female3=0 if number==1329


save "na110421a.dta", replace
*------------------------all
collapse (mean) mult5 (count) nc=age, by(agegr23 bdec eths)
g abcc=125-125*mult5
replace abcc=125-125*(((mult5-0.2)*1.25)+0.2) if agegr==23
g nc2=nc
collapse (mean) abcc (sum) nc [aw=nc2], by(bdec eths)
drop if nc<10
drop if bdec==.
edit
drop nc
reshape wide abcc, i(eths) j(bdec)
edit
*--------------males2 only
use na110421a.dta, clear
collapse (mean) mult5 (count) nc=age if female2==0, by(agegr23 bdec eths)
g abcc=125-125*mult5
replace abcc=125-125*(((mult5-0.2)*1.25)+0.2) if agegr==23
g nc2=nc
collapse (mean) abcc (sum) nc [aw=nc2], by(bdec eths)
drop if nc<10
drop if bdec==.
edi
drop nc 
reshape wide abcc, i(eths) j(bdec)
edit
*--------------females only
use na110421a.dta, clear
collapse (mean) mult5 (count) nc=age if female2==1, by(agegr23 bdec eths)
g abcc=125-125*mult5
replace abcc=125-125*(((mult5-0.2)*1.25)+0.2) if agegr==23
g nc2=nc
collapse (mean) abcc (sum) nc [aw=nc2], by(bdec eths)
drop if nc<10
drop if bdec==.
edi
drop nc 
reshape wide abcc, i(eths) j(bdec)
edit
*--------------males2 only, assuming all unstated ages as 30
use na110421a.dta, clear
replace mult5=1 if age==.
replace age=30 if age==.
replace agegr=23 if age>=23 & age<=32
replace bdec=cyear-(agegr+5) if bdec==.
replace bdec=floor(bdec/10)*10
replace agegr23=1 if age==30
collapse (mean) mult5 (count) nc=age if female2==0, by(agegr23 bdec eths)
g abcc=125-125*mult5
replace abcc=125-125*(((mult5-0.2)*1.25)+0.2) if agegr==23
g nc2=nc
collapse (mean) abcc (sum) nc [aw=nc2], by(bdec eths)
drop if nc<10
drop if bdec==.
edi
drop nc 
reshape wide abcc, i(eths) j(bdec)
edit
*-----------------------
use na110421a.dta, clear
set more off
*edit if eu==0 & bl~=1 & ko~=1& cn~=1& slave~=1& lyfeienis ~=1
xi: logit exactage bl ko cn slave lyfeienis female2 age23 i.bdec




************************************************************************
*Laura: Crime and punishment
************************************************************************

*some refinement of the data
replace pun = "decapitated" in 7
replace crime = "dronkenskap&openbarewangedrag" in 48
replace crime = "sodomie" in 62
replace crime = "sedisie" in 74
replace crime = "sedisie" in 75
replace crime = "sedisie" in 76
replace crime = "sedisie" in 82
replace crime = "sedisie" in 83
replace crime = "sodomie" in 90
replace pun = "verdrink" in 90
replace pun ="vanprokureursrolgeskrap" in 106
replace pun ="geledebraak" in 146
replace crime ="belaster" in 160
replace pun ="geledebraak" in 168
replace pun ="decapitated" in 184
replace pun ="geledebraak" in 208
replace pun ="geledebraak" in 246
replace pun ="geledebraak" in 247
replace crime ="sodomie" in 250
replace crime ="verkragting" in 257
replace crime ="sedisie" in 275
replace crime ="sedisie" in 277
replace crime ="sedisie" in 280
replace pun = "verdrink" in 284
replace pun = "geledebraak" in 309
replace pun = "geledebraak,metwarmtangop8plekkegeknyp" in 325
replace pun = "geledebraak" in 333
replace pun = "geledebraak" in 338
replace pun = "geledebraak" in 341
replace pun = "geledebraak" in 349
replace pun = "geledebraak" in 350
replace pun = "geledebraak" in 352
replace pun = "geledebraak" in 358
replace pun = "geledebraak,decapitated" in 359
replace pun = "regterhand afgekap, geblaker, lyk op wiel uitgestal" in 360
replace crime = "vals beskuldiging" in 377
replace crime = "medepligtigheid" in 382
replace crime = "medeprigtigheid" in 386
replace crime = "vals beskuldiging" in 394
replace pun = "geledebraak,metwarmtangop8plekkegeknyp" in 416
replace crime = "aandranding,dros,diefstal" in 451
replace pun = "Geraadbraak en onthoof, knuppel, mes en byl uitgestal" in 455
replace crime ="aanranding,dros,diefstal" in 456
replace crime ="verleen hulp aan drosters" in 464
replace pun= "aanskou drosters se straf" in 464
replace crime = "dros,medepligtige aan moord" in 476
replace crime = "medepligtige aan moord" in 478
replace pun = "verbrand" in 508
replace crime = "dros,medepligtige aan moord" in 578
replace crime = "dros,medepligtige aan moord" in 579
replace crime = "medepligtige in diefstal" in 593
replace crime = "medepligtige aan moord" in 616
replace pun = "verbrand" in 624
replace pun = "verbrand" in 629
replace crime = "hulp aan drosters en moordenaars" in 661
replace pun = "vleis met gloeiende tang uit liggaam geruk terwyl sy geledebraak word, kop op pen geplaas" in 675
replace crime = "verswyg moord wat hy gesien het" in 679
replace pun = "lewendig gespit" in 707
replace crime = "theft/dros" in 699
replace crime = "theft/dros" in 700
replace crime = "theft/dros" in 701
replace crime = "medepligtige aan moord" in 720
replace crime = "aanranding,dros,diefstal" in 724
replace crime = "help slaaf ontsnap uit tronk" in 727
replace crime = "medepligtige aan moord" in 731
replace crime = "medepligtige aan moord" in 749
replace pun = "metwarmtangop8plekkegeknyp,liggaamopspitgeplaas" in 765
replace crime = "medepligtige aan moord" in 791
replace pun = "gevierendeel, ingewande verbrand, gehang" in 806
replace crime = "dreig eienaar met 'n mes" in 813
replace crime = "poging tot verkragting" in 821
replace crime = "medepligtige in diefstal" in 844
replace crime = "aanranding,dros,diefstal" in 853
replace pun = "decapitated,metwarmtangop8plekkegeknyp" in 866
replace pun = "kry houe op sitvlak met roede" in 882
replace crime = "poging tot verkragting" in 896
replace pun = "metwarmtangop8plekkegeknyp,liggaamopspitgeplaas" in 897
replace pun = "kry houe op sitvlak met roede" in 901
replace pun = "verbrand" in 907
replace crime = "medepligtige aan moord" in 940
replace crime = "verset teen eienaar" in 960
replace crime = "medepligtige aan moord" in 985
replace crime = "medepligtige aan moord" in 1017
replace crime = "medepligtige aan moord" in 1021
replace pun = "decapitatedenkopoppengestel" in 1031
replace pun = "lewendig op spit geplaas" in 1063
replace crime = "medepligtige aan moord" in 1067
replace crime = "verset teen eienaar" in 1075
replace pun = "lewendig op spit geplaas" in 1076
replace pun = "lewendig op spit geplaas" in 1077
replace crime = "medepligtige aan diefstal" in 1083
replace pun = "gevierendeel, ingewande verbrand, gehang" in 1094
replace crime = "verset teen eienaar" in 1114
replace crime = "theft/moord" in 1153
replace pun = "kry houe op sitvlak met roede" in 1163
replace crime ="vervalsing" in 1165
replace crime = "oenbare geweld" in 1167
replace pun = "verblind,verban" in 1169
replace pun = "gevangenisstraf" in 1181
replace pun = "gevangenisstraf" in 1182
replace pun = "langdurige detensie" in 1183
replace pun = "kettings" in 1185
replace crime = "aanranding" in 1189
replace crime = "complottering" in 1235
replace crime = "kwetsing" in 1238
replace crime = "complottering" in 1240
replace crime = "complottering" in 1241
replace crime = "complottering" in 1242
replace crime = "complottering" in 1243
replace crime = "complottering" in 1244
replace crime = "complottering" in 1245
replace crime = "complottering" in 1246
replace crime = "complottering" in 1247
replace crime = "complottering" in 1248
replace crime = "complottering" in 1249
replace crime = "complottering" in 1250
replace crime = "manslag" in 1251
replace crime = "kwetsing" in 1252
replace crime = "geweldpleging" in 1254
replace crime = "manslag" in 1255
replace crime = "aanranding" in 1256
replace crime = "brandstigting" in 1258
replace crime = "brandstigting" in 1259
replace crime = "brandstigting" in 1260
replace crime = "veediefstal" in 1263
replace crime = "veediefstal" in 1264
replace crime = "veediefstal" in 1265
replace crime = "veediefstal" in 1266
replace crime = "kwetsing" in 1271
replace crime = "aanranding" in 1274
replace crime = "sodomie" in 1275
replace crime = "kwetsing" in 1276
replace crime = "complottering" in 1277
replace crime = "fraud" in 1278
replace crime = "theft/mishandeling" in 1281
replace crime = "theft/mishandeling" in 1282
replace pun = "geledebraak" in 1284
replace crime = "sodomie" in 1285
replace crime = "geweld" in 1288
replace pun = "confined" in 1295
replace crime = "kwaksalwery" in 1302
replace crime = "manslag" in 1312
replace crime = "sodomie" in 1313
replace crime = "verkragting" in 1315
replace crime = "aanranding" in 1334
replace crime = "veediefstal" in 1342
replace crime = "verwaarlosing van kind" in 1347
replace crime = "veediefstal" in 1348
replace crime = "geweld" in 1349
replace crime = "aanranding" in 1355
replace pun = "flogged" in 1362
replace pun = "flogged" in 1363
replace pun = "confined" in 1368
replace crime = "geweld" in 1386
replace crime = "geweld" in 1387
replace pun = "gepronk" in 1390
replace crime = "complottering" in 1391
replace crime = "dronkenskap" in 1395
replace pun = "flogged" in 1404
replace pun = "gepronk" in 1406
replace pun = "gepronk" in 1407
replace pun = "gekondimneerd" in 1409
replace pun = "flogged" in 1415
replace crime = "vervalsing" in 1416
replace crime = "complottering" in 1425
replace crime = "complottering" in 1426
replace crime = "complottering" in 1427
replace pun = "gelaarsd" in 1428
replace pun = "to Majesty for further investigation" in 1432
replace pun = "gepronk" in 1482
replace pun = "gepronk" in 1485
replace pun = "gepronk" in 1490
replace pun = "kry houe op sitvlak met roede" in 1496
replace pun = "kry houe op sitvlak met roede" in 1497
replace pun = "flogged" in 1504
replace pun = "flogged" in 1505
replace pun = "flogged" in 1506
replace pun = "flogged" in 1507
replace pun = "flogged" in 1508
replace pun = "flogged" in 1509
replace pun = "flogged" in 1510
replace pun = "flogged" in 1511
replace pun = "flogged" in 1512
replace crime = "poging tot moord" in 1520
replace pun = "flogged" in 1530
replace crime = "medepligtige" in 1531
replace crime = "medepligtige" in 1532
replace crime = "medepligtige" in 1535
replace crime = "medepligtige" in 1536
replace crime = "aggression" in 1538
replace crime = "verkragting" in 1539
replace crime = "aanranding" in 1540 
replace pun = "boete" in 1540
replace crime = "violence" in 1541
replace crime = "violence" in 1542
replace pun = "gepronk" in 1543
replace crime ="vervalsing/bedrog" in 1550
replace crime ="vervalsing/bedrog" in 1552
replace crime ="vervalsing/bedrog" in 1553
replace crime = "verleiding en schaaiking van minderjarige meisies" in 1551
replace pun = "afgeschlagt" in 1563
replace crime = "vervalsing/bedrog" in 1571
replace crime = "valse beskuldiging" in 1573
replace crime = "valse beskuldiging" in 1574
replace crime = "brandstigting" in 1577
replace pun = "confined" in 1596
replace crime = "veediefstal" in 1598
replace crime = "aanranding" in 1603
replace pun = "gepronk" in 1603
replace crime = "veediefstal" in 1608
replace crime = "veediefstal" in 1609
replace crime = "veediefstal" in 1610
replace crime = "medepligtige" in 1613
replace crime = "medepligtige" in 1614
replace crime = "sodomie" in 1622
replace crime = "verkragting" in 1626
replace pun = "bannished" in 1628
replace crime = "owerspel" in 1629
replace crime = "owerspel" in 1630
replace crime = "aanranding" in 1634
replace crime = "medepligtige in diefstal" in 1635
replace crime = "manslag" in 1639
replace crime = "manslag" in 1641
replace crime = "manslag" in 1645
replace pun = "gepronk" in 1642
replace crime = "veediefstal" in 1643 
replace crime = "veediefstal" in 1644
replace crime = "veediefstal" in 1685
replace crime = "aanranding" in 1689
replace crime = "complottering" in 1697
replace crime = "complottering" in 1698
replace crime = "complottering" in 1699
replace crime = "complottering" in 1759
replace crime = "complottering" in 1760
replace crime = "complottering" in 2701
replace crime = "complottering" in 2702
replace crime = "complottering" in 2703
replace crime = "complottering" in 2704
replace crime = "complottering" in 2705
replace crime = "aanranding" in 1761
replace crime = "aanranding" in 1762
replace crime = "aanranding" in 2077
replace crime = "aanranding" in 2737
replace crime = "geweldpleging" in 1744
replace crime = "geweldpleging" in 1745
replace crime = "geweldpleging" in 1746
replace crime = "geweldpleging" in 1747
replace crime = "geweldpleging" in 1748
replace crime = "medepligtigheid" in 1700
replace crime = "medepligtigheid" in 1721
replace crime = "medepligtigheid" in 1742
replace crime = "medepligtigheid" in 1743
replace crime = "medepligtigheid" in 1784
replace crime = "medepligtigheid" in 2108
replace crime = "medepligtigheid" in 2363
replace crime = "medepligtigheid" in 2554
replace crime = "medepligtigheid" in 2614
replace crime = "medepligtigheid" in 2643
replace crime = "medepligtigheid" in 2644
replace crime = "medepligtigheid" in 2645
replace crime = "medepligtigheid" in 2652
replace crime = "medepligtigheid" in 2727
replace crime = "medepligtigheid" in 2839
replace crime = "medepligtigheid" in 2840
replace crime = "medepligtigheid" in 2874
replace crime = "medepligtigheid" in 2875
replace crime = "medepligtigheid" in 2876
replace crime = "medepligtigheid" in 2877
replace crime = "medepligtigheid" in 2878
replace crime = "medepligtigheid" in 2879
replace crime = "medepligtigheid" in 2028
replace crime = "vals beskuldiging" in 1709
replace crime = "vals beskuldiging" in 1722
replace crime = "aanskou geeseling" in 1717
replace crime = "ontvoering" in 1730
replace crime = "ontvoering" in 1731
replace crime = "vervalsing/bedrog" in 1734
replace crime = "sodomie" in 1735
replace crime = "sodomie" in 2157
replace crime = "sodomie" in 2359
replace crime = "sodomie" in 2736
replace crime = "sodomie" in 2857
replace crime = "verkragting" in 1757
replace crime = "verkragting" in 2228
replace crime = "verkragting" in 2439
replace crime = "verkragting" in 2463
replace crime = "verkragting" in 2512
replace crime = "verkragting" in 2621
replace crime = "verkragting" in 2627
replace crime = "verkragting" in 2684
replace crime = "verkragting" in 2864
replace crime = "verkragting" in 2890
replace crime = "veediefstal" in 1763
replace crime = "veediefstal" in 1777
replace crime = "veediefstal" in 1778
replace crime = "veediefstal" in 1807
replace crime = "veediefstal" in 1808 
replace crime = "veediefstal" in 1836
replace crime = "veediefstal" in 1879
replace crime = "veediefstal" in 1880
replace crime = "veediefstal" in 1908
replace crime = "veediefstal" in 1909
replace crime = "veediefstal" in 1910
replace crime = "veediefstal" in 1911
replace crime = "veediefstal" in 1912
replace crime = "kinder mishandeling" in 1800
replace crime = "kinder mishandeling" in 1801
replace pun = "strafoefeninge" in 1805
replace crime = "mishandeling van vrou" in 1809
replace crime = "mishandeling van vrou" in 2330
replace crime = "mishandeling van vrou" in 2110
replace crime = "oortreding van vonnis" in 1810
replace crime = "forcibly resisting officer" in 1812
replace crime = "poisoning" in 1822
replace crime = "rondswerwing" in 1885
replace crime = "brandstigting" in 1891
replace crime = "brandstigting" in 2000
replace crime = "brandstigting" in 2039
replace crime = "brandstigting" in 2358
replace crime = "brandstigting" in 2847
replace crime = "brandstigting" in 2906
replace crime = "pogging tot moord" in 2038
replace crime = "pogging tot moord" in 2107
replace crime = "pogging tot moord" in 2109
replace crime = "pogging tot moord" in 2267
replace crime = "pogging tot moord" in 2335
replace crime = "pogging tot moord" in 2384
replace crime = "pogging tot moord" in 1952
replace crime = "vlug" in 2068
replace crime = "vlug" in 2069
replace crime = "vlug" in 2151
replace pun = "getransporteer na New South Wales" in 2084
replace pun = "getransporteer na New South Wales" in 2280
replace pun = "getransporteer na New South Wales" in 2293
replace pun = "getransporteer na New South Wales" in 2364
replace crime = "dronkenskap" in 2103
replace crime = "dronkenskap" in 2181
replace crime = "dronkenskap" in 2244
replace crime = "dronkenskap" in 2350
replace crime = "guilty of exceeding the measure of justifiable Defence" in 2194
replace crime = "verleiding" in 2204
replace crime = "concealment of gunpowder" in 2256
replace crime = "neglecting his duties" in 2332
replace crime = "mishandeling/moord" in 2369
replace crime = "meineed" in 2380
replace crime = "meineed" in 2536
replace crime = "mishandeling" in 2381
replace crime = "mishandeling" in 2611
replace crime = "mishandeling" in 2612
replace crime = "mishandeling" in 2640
replace crime = "mishandeling" in 2777
replace crime = "mishandeling" in 2888
replace crime = "kwetsing & mishandeling" in 2489
replace crime = "kwetsing & mishandeling" in 2891
replace crime = "violation of bannishment" in 2493
replace pun = "detensie" in 2501
replace pun = "detensie" in 2502
replace pun = "detensie" in 2503
replace pun = "detensie" in 2505
replace pun = "detensie" in 2567
replace pun = "detensie" in 2666
replace pun = "detensie" in 2674
replace pun = "detensie" in 2501
replace pun = "detensie" in 2723
replace pun = "detensie" in 2765
replace pun = "detensie" in 2779
replace pun = "detensie" in 2827
replace pun = "detensie" in 2829
replace pun = "detensie" in 2902
replace pun = "detensie" in 2905
replace pun = "detensie" in 1747
replace pun = "detensie" in 1748
replace pun = "detensie" in 2704
replace pun = "detensie" in 2705
replace crime = "inbraak" in 2534
replace crime = "poging tot verkragting" in 2590
replace crime = "intolerable persecution, scandalous oppression, perversion" in 2607
replace crime = "falsifying escape of convict" in 2608
replace crime = "manslag" in 2714
replace crime = "drossing" in 2766
replace crime = "drossing" in 2791
replace crime = "bloedskande" in 2825
replace crime = "bloedskande" in 2826
replace pun = "kostes" in 2839
replace pun = "kostes" in 2840
replace crime = "theft/drossing" in 2851
replace crime = "theft/drossing" in 2852
replace crime = "theft/drossing" in 2853

***********************************************************************************
*Laura: tidying up of crime variable
**********************************************************************************
replace crime = "aandadig op moord" in 120
replace crime = "aanranding,dros,diefstal" in 451
replace crime = "dronkenskap" in 1201
replace crime = "dronkenskap" in 1202
replace crime = "geweldpleging" in 1538
replace crime = "poging tot moord" in 1782
replace crime = "drossing" in 1212
replace crime = "drossing" in 1224
replace crime = "bedrog" in 1278
replace crime = "geweldpleging" in 1288
replace crime = "geweldpleging" in 1349
replace crime = "geweldpleging" in 1386
replace crime = "geweldpleging" in 1387
replace crime = "medepligtige in diefstal" in 1083
replace crime = "medepligtigheid" in 1531
replace crime = "medepligtigheid" in 1532
replace crime = "medepligtigheid" in 1535
replace crime = "medepligtigheid" in 1536
replace crime = "medepligtigheid" in 1613
replace crime = "medepligtigheid" in 1614
replace crime = "medepligtige aan moord" in 126
replace crime = "medepligtigheid" in 386
replace crime = "theft" in 1354
replace crime = "geweldadig" in 1167
replace crime = "other criminalities"  if crime == "other/ criminalities"
replace crime = "other criminalities"  if crime == "other/criminalities"
replace crime = "poging tot moord" if crime == "pogging tot moord"
replace crime = "moord" if crime == "murder"
replace crime = "geweldpleging" if crime == "geweldadig"
replace crime = "afskeep van pligte" if crime == "neglecting his duties"
replace crime = "onskuldig" if crime == "not guilty"
replace crime = "vergiftiging" if crime == "poisoning"
replace crime = "theft" if crime == "stealing"
replace crime = "theft/ bedrog" if crime == "theft/bedrog"
replace crime = "theft/ inbraak" if crime == "theft/inbraak"
replace crime = "theft/ inbraak" if crime == "theft / inbraak"
replace crime = "theft/drossing" if crime == "theft/dros"
replace crime = "aanranding/drossing" if crime == "aanranding en drossing"
replace crime = "aanranding/moord" if crime == "aanranding en moord"
replace crime = "aanranding/drossing/diefstal" if crime == "aanranding,dros,diefstal"
replace crime = "theft/ geweldpleging" if crime == "theft/violence"
replace crime = "theft/ geweldpleging" if crime == "theft/ violence"
replace crime = "vals beskuldiging" if crime == "valse beskuldiging"
replace crime = "geweldadigheid" if crime == "violence"


*tidying up of pun variable
replace pun = "bannished" if pun == "banned"
replace pun = "flogged" if pun=="gelaarsd"
replace pun = "flogged" if pun == "gelaarst"
replace pun = "flogged, bannished" if pun == "flogged, verban"
replace pun = "flogged, bannished" if pun == "flogging, banned"
replace pun = "flogged, kettings" if pun == "flogging, kettings"
replace pun = "flogged" if pun == "flogging"
replace pun = "flogged, labour" if pun == "flogging, labour"
replace pun = "other punishment" if pun == "other punishments"
replace pun = "bannished" if pun == "verban"
replace pun = "vrygelaat" if pun == "vrygestel"
replace pun = "condemned" if pun == "gekondimneerd"
replace pun = "gepronk, labour" if pun == "gepronk, arbied"
replace pun ="banned, labour" if pun == "labour, banned"
replace pun = "lewendig gespit" if pun == "lewendig op spit geplaas"
replace pun = "decapitated" if pun == "onthoof"

/*"Other criminalities", here I replaced observations who have "other criminalities"
as their crime value, with the name of a crime which most likely fits the persons punishment
and ethnicity:*/

 /*for instance, for someone of European ethnicity, who were punished by bannishment: the majority of 
 these prisoners were found guilty of complottering, thus */
 
replace crime = "complottering" if crime == "other criminalities" & pun == "bannished" & eths == "eu"
replace crime = "theft/ bedrog" if crime == "other criminalities" & pun == "condemned" & eths == "eu"
replace crime = "moord" if crime == "other criminalities" & pun == "confined" & eths == "eu"
replace crime = "theft" if crime == "other criminalities" & pun == "flogged" & eths == "eu"
replace crime = "theft" if crime == "other criminalities" & pun == "flogged, bannished" & eths == "eu"
replace crime = "theft" if crime == "other criminalities" & pun == "flogged, labour" & eths == "eu"
replace crime = "theft" if crime == "other criminalities" & pun == "flogged, other" & eths == "eu"
replace crime = "theft/ geweldpleging" if crime == "other criminalities" & pun == "gepronk, verban" & eths == "eu"
replace crime = "theft/mishandeling" if crime == "other criminalities" & pun == "gevangenisstraf" & eths == "eu"
replace crime = "moord" if crime == "other criminalities" & pun == "hanged" & eths == "eu"
replace crime = "theft" if crime == "other criminalities" & pun == "labour" & eths == "eu"
replace crime = "complottering" if crime == "other criminalities" & pun == "bannished" & eths == "eu"
replace crime = "complottering" if crime == "other criminalities" & pun == "verblind,verban" & eths == "eu"
replace crime = "sodomie" if crime == "other criminalities" & pun == "verdrink" & eths == "eu"
replace crime = "moord" if crime == "other criminalities" & pun == "voortvlugtig" & eths == "eu"
replace crime = "theft" if crime == "other criminalities" & pun == "labour, kettings" & eths == "eu"

replace crime = "theft/ geweldpleging" if crime == "other criminalities" & pun == "detensie" & eths == "ko"
replace crime = "theft" if crime == "other criminalities" & pun == "flogged" & eths == "ko"
replace crime = "veediefstal" if crime == "other criminalities" & pun == "flogged, bannished" & eths == "ko"
replace crime = "theft" if crime == "other criminalities" & pun == "flogged, labour" & eths == "ko"
replace crime = "moord" if crime == "other criminalities" & pun == "geledebraak" & eths == "ko"
replace crime = "veediefstal" if crime == "other criminalities" & pun == "gepronk" & eths == "ko"
replace crime = "veediefstal" if crime == "other criminalities" & pun == "gepronk, other" & eths == "ko"
replace crime = "veediefstal" if crime == "other criminalities" & pun == "gevangenisstraf" & eths == "ko"
replace crime = "moord" if crime == "other criminalities" & pun == "hanged" & eths == "ko"
replace crime = "geweldadigheid" if crime == "other criminalities" & pun == "labour" & eths == "ko"

replace crime = "theft" if crime == "other criminalities" & pun == "flogged" & eths == "cn"

replace crime = "theft" if crime == "other criminalities" & pun == "condemned" & eths == "bl"
replace crime = "theft" if crime == "other criminalities" & pun == "flogged" & eths == "bl"
replace crime = "theft" if crime == "other criminalities" & pun == "flogged, bannished" & eths == "bl"
replace crime = "theft/drossing" if crime == "other criminalities" & pun == "flogged, kettings" & eths == "bl"
replace crime = "theft" if crime == "other criminalities" & pun == "flogged, labour" & eths == "bl"
replace crime = "moord" if crime == "other criminalities" & pun == "geledebraak" & eths == "bl"
replace crime = "theft/ geweldpleging" if crime == "other criminalities" & pun == "gepronk" & eths == "bl"
replace crime = "theft/other" if crime == "other criminalities" & pun == "gepronk, other" & eths == "bl"
replace crime = "theft/other" if crime == "other criminalities" & pun == "gepronk, verban" & eths == "bl"
replace crime = "moord" if crime == "other criminalities" & pun == "geradbraak" & eths == "bl"
replace crime = "drossing" if crime == "other criminalities" & pun == "kettings" & eths == "bl"


/*generate crimedegree : the value of which is determined by the degree and nature of the crime, and the seriousness
of the punishment for a certain crime (use pundegree as an indication, but still use own discression). One being the least violent crime, and 5 being the most*/

generate pundegree = .
replace pundegree = 0 if pun == "vrygelaat"
replace pundegree = 0 if pun == "no punishment"
replace pundegree = 1 if pun == "boete"
replace pundegree = 1 if pun == "kostes"

replace pundegree = 2 if pun == "detensie"
replace pundegree = 2 if pun == "discharged"
replace pundegree= 2 if pun == "aanskou drosters se straf"
replace pundegree = 2 if pun == "gevangenisstraf"
replace pundegree = 2 if pun == "kry houe op sitvlak met roede"
replace pundegree = 2 if pun == "labour"
replace pundegree = 2 if pun == "labour, kettings"
replace pundegree = 2 if pun == "langdurige detensie"
replace pundegree = 2 if pun == "strafoefeninge"
replace pundegree = 2 if pun == "vanprokureursrolgeskrap"


replace pundegree = 3 if pun=="bannished"
replace pundegree = 3 if pun=="bannished to slave lodge"
replace pundegree = 3 if pun=="condemned"
replace pundegree = 3 if pun=="confined"
replace pundegree = 3 if pun=="flogged"
replace pundegree = 3 if pun=="flogged, bannished"
replace pundegree = 3 if pun=="flogged, geklonken"
replace pundegree = 3 if pun=="flogged, kettings"
replace pundegree = 3 if pun=="flogged, kostes"
replace pundegree = 3 if pun=="flogged, labour"
replace pundegree = 3 if pun=="flogged, other"
replace pundegree = 3 if pun=="flogged, slave lodge"
replace pundegree = 3 if pun=="geklonken"
replace pundegree = 3 if pun=="banned, labour"
replace pundegree = 3 if pun=="gepronk"
replace pundegree = 3 if pun=="gepronk, labour"
replace pundegree = 3 if pun=="gepronk, verban"
replace pundegree = 3 if pun=="gepronk, arbeid"
replace pundegree = 3 if pun=="gepronk, other"
replace pundegree = 3 if pun=="getransporteer na New South Wales"
replace pundegree = 3 if pun == "kettings"
replace pundegree = 3 if pun == "to Majesty for further investigation"
replace pundegree = 3 if pun == "verblind,verban"


replace pundegree = 4 if pun=="gefusilleer"
replace pundegree = 4 if pun == "decapitated"
replace pundegree = 4 if pun == "geledebraak"
replace pundegree = 4 if pun == "geradbraak"
replace pundegree = 4 if pun == "hanged"
replace pundegree = 4 if pun == "onbekend"
replace pundegree = 4 if pun == "verbrand"
replace pundegree = 4 if pun == "verdrink"
replace pundegree = 4 if pun == "verwurg"
replace pundegree = 4 if pun == "voortvlugtig"

replace pundegree = 5 if pun == "regterhand afgekap, geblaker, lyk op wiel uitgestal"
replace pundegree = 5 if pun == "Geraadbraak en onthoof, knuppel, mes en byl uitgestal"
replace pundegree = 5 if pun == "decapitated,metwarmtangop8plekkegeknyp"
replace pundegree = 5 if pun == "decapitatedenkopoppengestel"
replace pundegree = 5 if pun == "geledebraak,decapitated"
replace pundegree = 5 if pun == "geledebraak,metwarmtangop8plekkegeknyp"
replace pundegree = 5 if pun == "vleis met gloeiende tang uit liggaam geruk terwyl sy geledebraak word, kop op pen geplaas"
replace pundegree = 5 if pun == "lewendig gespit"
replace pundegree = 5 if pun == "metwarmtangop8plekkegeknyp,liggaamopspitgeplaas"
replace pundegree = 5 if pun == "vleis met gloeiende tang uit liggaam geruk"
replace pundegree = 5 if pun == "gevierendeel, ingewande verbrand, gehang"

label define pungree 0 "set free" 1 "financial punishment" 2 "imprisonment,non-violent punishment" 3 "punishment which causes bodily or psychological harm" 4 "punishment which causes serious bodily harm or death" 5 "punishment which includes death and humiliation or pain"
label values pundegree pungree

gen crimedegree = .

replace crimedegree = 0 if crime == "onskuldig"

replace crimedegree = 1 if crime =="aanskou geeseling"
replace crimedegree = 1 if crime == "bedrog"
replace crimedegree = 1 if crime == "belaster"
replace crimedegree = 1 if crime == "discharged"
replace crimedegree = 1 if crime == "falsifying escape of convict"
replace crimedegree = 1 if crime == "help slaaf ontsnap uit tronk"
replace crimedegree = 1 if crime == "meineed"
replace crimedegree = 1 if crime == "owerspel"
replace crimedegree = 1 if crime == "rondswerwing"
replace crimedegree = 1 if crime == "verleen hulp aan drosters"
replace crimedegree = 1 if crime == "verswyg moord wat hy gesien het"


replace crimedegree = 2 if crime =="afskeep van pligte"
replace crimedegree = 2 if crime == "bloedskande"
replace crimedegree = 2 if crime == "drossing"
replace crimedegree = 2 if crime == "manslag"
replace crimedegree = 2 if crime == "medepligtige in diefstal"
replace crimedegree = 2 if crime == "oortreding van vonnis"
replace crimedegree = 2 if crime == "sedisie"
replace crimedegree = 2 if crime == "vals beskuldiging"
replace crimedegree = 2 if crime == "verleiding"
replace crimedegree = 2 if crime == "verset teen eienaar"


replace crimedegree = 3 if crime == "dronkenskap"
replace crimedegree = 3 if crime == "dronkenskap&openbarewangedrag"
replace crimedegree = 3 if crime == "aandadig op moord"
replace crimedegree = 3 if crime == "aanranding"
replace crimedegree = 3 if crime == "complottering"
replace crimedegree = 3 if crime == "concealment of gunpowder"
replace crimedegree = 3 if crime == "dreig eienaar met 'n mes"
replace crimedegree = 3 if crime == "dros / resistance"
replace crimedegree = 3 if crime == "forcibly resisting officer"
replace crimedegree = 3 if crime == "guilty of exceeding the measure of justifiable Defence"
replace crimedegree = 3 if crime == "inbraak"
replace crimedegree = 3 if crime == "kwaksalwery"
replace crimedegree = 3 if crime == "kwetsing"
replace crimedegree = 3 if crime == "medepligtigheid"
replace crimedegree = 3 if crime == "mishandeling"
replace crimedegree = 3 if crime == "mishandeling van vrou"
replace crimedegree = 3 if crime == "molestering" 
replace crimedegree = 3 if crime == "muitery"
replace crimedegree = 3 if crime == "ontvoering"
replace crimedegree = 3 if crime == "theft"
replace crimedegree = 3 if crime == "theft/ bedrog"
replace crimedegree = 3 if crime == "theft/ inbraak"
replace crimedegree = 3 if crime == "theft/drossing"
replace crimedegree = 3 if crime == "theft/other"
replace crimedegree = 3 if crime == "veediefstal"
replace crimedegree = 3 if crime == "verleiding en schaaiking van minderjarige meisies"
replace crimedegree = 3 if crime == "vervalsing"
replace crimedegree = 3 if crime == "kinder mishandeling"
replace crimedegree = 3 if crime == "vervalsing/bedrog"
replace crimedegree = 3 if crime == "verwaarlosing van kind"
replace crimedegree = 3 if crime == "violation of bannishment"
replace crimedegree = 3 if crime == "vlug"



replace crimedegree = 4 if crime == "aanranding/drossing"
replace crimedegree = 4 if crime == "aanranding/drossing/diefstal"
replace crimedegree = 4 if crime == "brandstigting"
replace crimedegree = 4 if crime == "dros,medepligtige aan moord"
replace crimedegree = 4 if crime == "geweldadigheid"
replace crimedegree = 4 if crime == "geweldpleging"
replace crimedegree = 4 if crime == "hoogverraad"
replace crimedegree = 4 if crime == "hulp aan drosters en moordenaars"
replace crimedegree = 4 if crime == "intolerable persecution, scandalous oppression, perversion"
replace crimedegree = 4 if crime == "kwetsing & mishandeling"
replace crimedegree = 4 if crime == "medepligtige aan moord"
replace crimedegree = 4 if crime == "other criminalities"
replace crimedegree = 4 if crime == "poging tot verkragting"
replace crimedegree = 4 if crime == "sodomie"
replace crimedegree = 4 if crime == "theft/ geweldpleging"
replace crimedegree = 4 if crime == "theft/ resistance"
replace crimedegree = 4 if crime == "theft/mishandeling"
replace crimedegree = 4 if crime == "verkragting"



replace crimedegree = 5 if crime == "aanranding/moord"
replace crimedegree = 5 if crime == "mishandeling/moord"
replace crimedegree = 5 if crime == "moord" 
replace crimedegree = 5 if crime == "poging tot moord"
replace crimedegree = 5 if crime == "theft/moord"
replace crimedegree = 5 if crime == "vergiftiging"

/*determining crimedegree requires some discression, as prisoners of the various "eths" are punished differently. So crimes are judged according to
both the nature of the crime and the highest pundegree, if that makes sense*/

g cdec=floor(cyear/10)*10
g crime_tough=0
replace crime_tough=1 if crimedegree==4 | crimedegree==5
ta cdec crime_tough
g pun_xtough=0
replace pun_xtough=1 if pundegree==4 | pundegree==5
ta cdec pun_xtough

save "g:\a\na\na110503.dta", replace 
use "g:\a\na\na110503.dta", clear
collapse (count) nc=age (mean) crime_tough , by(cdec  eu)
drop if nc<10
drop nc
reshape wide crime_tough, i(eu) j(cdec)
edit
use "na110503.dta", clear
collapse (count) nc=age (mean) pun_xtough , by(cdec  eu)
drop if nc<10
drop nc
ren pun_xtough px
reshape wide px, i(eu) j(cdec)
edit

use "g:\a\na\na110503.dta", clear
do g:\a\na\origin2.do

clear
set mem 600m
use "g:\a\na\bf110611.dta", clear
g bco=origindum
replace bco="in" if bco=="India" | bco=="Ceylon" | origin=="Pondieberg"
replace bco="mz" if bco=="Mozambique" | bco=="Madagascar" | bco=="Mauritius" | origin=="Mauritz" 
replace bco="cn" if bco=="China" | cn
replace bco="id" if bco=="Indonesia" | origin=="Boeton" | origin=="Bourbon" | origin=="Bouton" 
replace bco="ko" if ko
replace bco="za" if bco=="Cape" | origin=="Kust" | origin=="Cust" |origin=="Westcoast"
replace bco="" if length(bco)>2
replace bco="oth_bl" if bl & bco==""
replace bco="eur" if eu
tab bco, gen (bco_)
ren bco_1 b_cn
ren bco_2 b_eur
ren bco_3 b_id
ren bco_4 b_in
ren bco_5 b_kobc
ren bco_6 b_mz
ren bco_7 b_oth_bl
ren bco_8 b_za

capture drop bcohort
g bcohort=""
replace bcohort="early" if bdec<=1740
replace bcohort="middle" if bdec>=1750 & bdec<=1780
replace bcohort="post1790" if bdec>=1790 & bdec~=.
tab bcohort, gen (bcohort_)
ren bcohort_1 bd_early
ren bcohort_3 bd_post1790
ren bcohort_2 bd_middle

g eu_early=0
replace eu_early=1 if b_eur & bd_early
g bcoh=.
replace bcoh=1 if bcohort=="early"
replace bcoh=2 if bcohort=="middle"
replace bcoh=3 if bcohort=="post1790"

g	eur_early	 =0
g	eur_mid	 =0
g	eur_post	 =0
g	id_early	 =0
g	id_mid	 =0
g	in_early	 =0
g	in_mid	 =0
g	ko_early	 =0
g	ko_mid	 =0
g	ko_post	 =0
g	mz_mid	 =0
g	mz_post	 =0
g	otb_early	 =0
g	otb_mid	 =0
g	otb_post	 =0			
g	za_mid	 =0			
g	za_post	 =0			

						
replace 	eur_early	 =1 if bco=="eur" & bcoh==	1
replace 	eur_mid	 =1 if bco=="eur" & bcoh==	2
replace 	eur_post	 =1 if bco=="eur" & bcoh==	3
replace 	id_early	 =1 if bco=="id" & bcoh==	1
replace 	id_mid	 =1 if bco=="id" & bcoh==	2 | (bco=="id" & bcoh==	3)
replace 	in_early	 =1 if bco=="in" & bcoh==	1
replace 	in_mid	 =1 if bco=="in" & bcoh==	2 | (bco=="in" & bcoh==	3)
replace 	ko_early	 =1 if bco=="ko" & bcoh==	1
replace 	ko_mid	 =1 if bco=="ko" & bcoh==	2
replace 	ko_post	 =1 if bco=="ko" & bcoh==	3
replace 	mz_mid	 =1 if bco=="mz" & bcoh==	2
replace 	mz_post	 =1 if bco=="mz" & bcoh==	3
replace 	otb_early	 =1 if bco=="oth_bl" & bcoh==	1 | (bco=="za" & bcoh==	1) | (bco=="mz" & bcoh==	1) 
replace 	otb_mid	 =1 if bco=="oth_bl" & bcoh==	2
replace 	otb_post	 =1 if bco=="oth_bl" & bcoh==	3
replace 	za_mid	 =1 if bco=="za" & bcoh==	2
replace 	za_post	 =1 if bco=="za" & bcoh==	3


save g:\a\na\na110702.dta, replace
*-------------------
clear
set mem 500m
set more off
use g:\a\na\na110702.dta,clear
set more off
*it might be better to include the "oth_bl category, because otherwise the case numbers would look extremely small
xi: logit exactage female2 age23 i.bdec b_cn-b_oth_bl if age>22 & age<83  & bdec>=1650 & cyear~=.
mfx compute
outreg2 using na1, mfx ctitle(numerate) nor2 addstat(Pseudo R2, e(r2_p)) addnote(Put your notes here.) word replace seeout noas pvalue
*xi: logit exactage female2 age23 bd_middle bd_post1790 b_id b_in b_oth_bl if age>22 & age<83  & bdec>=1650 & (b_mz | b_id | b_oth_bl | b_in) & cyear~=.
*mfx compute
*outreg2 using na2, mfx ctitle(numerate) nor2 addstat(Pseudo R2, e(r2_p)) addnote(Put your notes here.) word replace seeout pvalue
xi: logit exactage female2 age23 eur_early-za_post if age>22 & age<83  & cyear~=.
mfx compute
outreg2 using na3, mfx ctitle(numerate) nor2 addstat(Pseudo R2, e(r2_p)) addnote(Put your notes here.) word replace seeout noas pvalue
*constant are chinese here
*and finally the linear prob model in order to obtain a constant:
xi: reg exactage female2 age23 eur_early-za_post if age>22 & age<83  & cyear~=.
outreg2 using na3, ctitle(numerate) addnote(Put your notes here.) word replace seeout noas pvalue  stnum(replace coef=coef*125)
*constant are chinese here


xi: reg exactage female2 age23 eur_early-za_post if age>22 & age<83  & cyear~=., r
estimates store m1
outreg2 using numeracy, ctitle(numerate) nor2 word append seeout


*this is just to check whether the constant in fact refers to Chinese only
ta bco if eur_early	==0 & ///
eur_mid		==0 & ///
eur_post		==0 & ///
id_early		==0 & ///
id_mid		==0 & ///
in_early		==0 & ///
in_mid		==0 & ///
ko_early		==0 & ///
ko_mid		==0 & ///
ko_post		==0 & ///
mz_mid		==0 & ///
mz_post		==0 & ///
otb_early		==0 & ///
otb_mid		==0 & ///
otb_post		==0 & ///
za_mid		==0 & ///
za_post		==0 & age>22 & age~=. & cyear~=.


*------------this is for preparing the dummy variable interacting birth country and birth cohort
use g:\a\na\na110702.dta, clear
collapse (count) nc=age if age>22 & age<83, by(bco bcoh)
drop if nc<27
*edit
*reshape wide nc, i(bco) j(bcoh)

use "G:\a\hb\br300407.dta", clear
ta mult5 if slave & africa==0 & age>22 & age<83
ta mult5 if africa==1 & age>22 & age<83
disp 125-125*0.5184
*60.2 (N=326)
disp 125-125*0.3310
*83.6 (N=429)
*the ABCC is relatively high due to the urban nature of the criminal sample, but it is remarkable that Brazilian
*born slaves had 23% more basic numeracy than African born slaves in mid-19th C Brazil