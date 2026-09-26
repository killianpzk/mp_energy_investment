

* Replication file for "The Transmission of Monetary Policy Shocks"
* Silvia Miranda-Agrippino & Giovanni Ricco 


* Replicates the following:

*Table  1   p.11 Main Text	
*Table  2   p.13 Main Text
*Table  3   p.15 Main Text
*Table  E1  p.18 Appendix
*Table  E2  p.19 Appendix
*Table  E3  p.20 Appendix
*Table  E4  p.21 Appendix
*Table  E5  p.22 Appendix 

* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 

cd "/Users/smiranda/Dropbox/LocalProjectionIRFs/AEJ-Macro/Submission Mar 2020/DATA AND CODE FOR DATA EDITOR/DO NOT SHARE -- contains restricted access data/PAPER TABLES/Replicate Other Tables/"

clear

set more off



*load data
* see README tab in "Master Data File.xlsx" for datasheet content
import excel using "Data/Master Data File.xlsx", sheet("DATA2") firstrow


*find scheduled FOMC announcements
gen isSCHEDULEDFOMC = isFOMC & ~isUNSCHEDULED

*generate FF4 for schedued FOMC only
gen FF4s=FF4
replace FF4s=. if isSCHEDULEDFOMC==0





*Greenbook Sets

*full set
global GB_ALL gRGDP* gPGDP* UNEMPF0 iRGDP* iPGDP* iUNEMP*

*full set
global GB_ALL2 gRGDP* gPGDP* UNEMP* iRGDP* iPGDP* iUNEMP*

*Romers'
global GB_ROMERS gRGDPB1 gRGDPF0 gRGDPF1 gRGDPF2 gPGDPB1 gPGDPF0 gPGDPF1 gPGDPF2 UNEMPF0 iRGDP* iPGDP*

*h=previous quarter
global GB_B1 gRGDPB1 iRGDPB1 gPGDPB1 iPGDPB1 UNEMPB1 iUNEMPB1

*h=current quarter
global GB_F0 gRGDPF0 iRGDPF0 gPGDPF0 iPGDPF0 UNEMPF0 iUNEMPF0

*h=next quarter
global GB_F1 gRGDPF1 iRGDPF1 gPGDPF1 iPGDPF1 UNEMPF1 iUNEMPF1

*h=two quarters ahead
global GB_F2 gRGDPF2 iRGDPF2 gPGDPF2 iPGDPF2 UNEMPF2 iUNEMPF2

*greenbook at short horizons
global GBshort gRGDPB1 gRGDPF0 iRGDPF0 iRGDPF1 gPGDPB1 gPGDPF0 iPGDPF0 iPGDPF1 UNEMPF0 iUNEMPF0 iUNEMPF1 









* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 
* 	TABLE 1 Main Text
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 

qui reg FF4 $GB_ALL if year <=2009, robust
est store T1_A

qui reg FF4 $GB_B1 if year <=2009, robust 
est store T1_B

qui reg FF4 $GB_F0 if year <=2009, robust 
est store T1_C

qui reg FF4 $GB_F1 if year <=2009, robust 
est store T1_D

qui reg FF4 $GB_F2 if year <=2009, robust 
est store T1_E


esttab T1_* using Table1.txt, replace ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	stats(r2_a F p N, fmt(%9.3f %9.3f %9.3f %9.0g) ) ///
	prehead(Table 1 Main Text) ///
	starlevel(* 0.1 ** 0.05 *** 0.01) 
 
 
 
 
 
 
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 
* 	TABLE E.1 Appendix
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 


qui reg FF4 $GB_ALL if year <=2009, robust
est store T2_A

qui reg FF4 $GB_ROMERS if year <=2009, robust
est store T2_B

qui reg FF4 $GB_ALL2 if year <=2009, robust
est store T2_C

qui reg FF4 $GB_B1 if year <=2009, robust 
est store T2_D

qui reg FF4 $GB_F0 if year <=2009, robust 
est store T2_E

qui reg FF4 $GB_F1 if year <=2009, robust 
est store T2_F

qui reg FF4 $GB_F2 if year <=2009, robust 
est store T2_G

qui reg FF4 gRGDP* if year <=2009, robust 
est store T2_H

qui reg FF4 gPGDP* if year <=2009, robust 
est store T2_I

qui reg FF4 UNEMP* if year <=2009, robust 
est store T2_J

qui reg FF4 gRGDP* gPGDP* UNEMP* if year <=2009, robust 
est store T2_K

qui reg FF4 iRGDP* if year <=2009, robust 
est store T2_L

qui reg FF4 iPGDP* if year <=2009, robust 
est store T2_M

qui reg FF4 iUNEMP* if year <=2009, robust 
est store T2_N

qui reg FF4 iRGDP* iPGDP* iUNEMP* if year <=2009, robust 
est store T2_O


esttab T2_* using TableE1.txt, replace ///
	cells(b(star fmt(%9.3f)) t(par fmt(%9.2f))) ///
	stats(r2_a F p N, fmt(%9.3f %9.3f %9.3f %9.0g) ) ///
	prehead(Table E1 Appendix) ///
	starlevel(* 0.1 ** 0.05 *** 0.01) 
 
 
 
 
 
 
 
 
 
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 
* 	TABLE E.2 Appendix
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 


qui reg FF4s $GB_ALL if year <=2009, robust
est store T3_A

qui reg FF4s $GB_ROMERS if year <=2009, robust
est store T3_B

qui reg FF4s $GB_ALL2 if year <=2009, robust
est store T3_C

qui reg FF4s $GB_B1 if year <=2009, robust 
est store T3_D

qui reg FF4s $GB_F0 if year <=2009, robust 
est store T3_E

qui reg FF4s $GB_F1 if year <=2009, robust 
est store T3_F

qui reg FF4s $GB_F2 if year <=2009, robust 
est store T3_G

qui reg FF4s gRGDP* if year <=2009, robust 
est store T3_H

qui reg FF4s gPGDP* if year <=2009, robust 
est store T3_I

qui reg FF4s UNEMP* if year <=2009, robust 
est store T3_J

qui reg FF4s gRGDP* gPGDP* UNEMP* if year <=2009, robust 
est store T3_K

qui reg FF4s iRGDP* if year <=2009, robust 
est store T3_L

qui reg FF4s iPGDP* if year <=2009, robust 
est store T3_M

qui reg FF4s iUNEMP* if year <=2009, robust 
est store T3_N

qui reg FF4s iRGDP* iPGDP* iUNEMP* if year <=2009, robust 
est store T3_O


esttab T3_* using TableE2.txt, replace ///
	cells(b(star fmt(%9.3f)) t(par fmt(%9.2f))) ///
	stats(r2_a F p N, fmt(%9.3f %9.3f %9.3f %9.0g) ) ///
	prehead(Table E2 Appendix) ///
	starlevel(* 0.1 ** 0.05 *** 0.01) 
 
 
 
 
 
 
 
 
 
 
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 
* 	TABLE E.3 Appendix
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 


qui reg FF4s $GB_ALL if year <=2009 & year >=1994, robust
est store T4_A

qui reg FF4s $GB_ROMERS if year <=2009 & year >=1994, robust
est store T4_B

qui reg FF4s $GB_ALL2 if year <=2009 & year >=1994, robust
est store T4_C

qui reg FF4s $GB_B1 if year <=2009 & year >=1994, robust 
est store T4_D

qui reg FF4s $GB_F0 if year <=2009 & year >=1994, robust 
est store T4_E

qui reg FF4s $GB_F1 if year <=2009 & year >=1994, robust 
est store T4_F

qui reg FF4s $GB_F2 if year <=2009 & year >=1994, robust 
est store T4_G



esttab T4_* using TableE3.txt, replace ///
	cells(b(star fmt(%9.3f)) t(par fmt(%9.2f))) ///
	stats(r2_a F p N, fmt(%9.3f %9.3f %9.3f %9.0g) ) ///
	prehead(Table E3 Appendix) ///
	starlevel(* 0.1 ** 0.05 *** 0.01)  

 
 
 
 
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 
* 	TABLE E.4 Appendix
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 


qui reg FF4 gRGDP*, robust 
est store T5_A

qui reg FF4 gPGDP*, robust 
est store T5_B

qui reg FF4 UNEMP*, robust 
est store T5_C

qui reg FF4 gRGDP* gPGDP* UNEMP*, robust 
est store T5_D
 
qui reg FF4s gRGDP*, robust 
est store T5_E

qui reg FF4s gPGDP*, robust 
est store T5_F

qui reg FF4s UNEMP*, robust 
est store T5_G

qui reg FF4s gRGDP* gPGDP* UNEMP*, robust 
est store T5_H



esttab T5_* using TableE4.txt, replace ///
	cells(b(star fmt(%9.3f)) t(par fmt(%9.2f))) ///
	stats(r2_a F p N, fmt(%9.3f %9.3f %9.3f %9.0g) ) ///
	prehead(Table E4 Appendix) ///
	starlevel(* 0.1 ** 0.05 *** 0.01)  
 
 
 
 
 
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 
* 	TABLE E.5 Appendix
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 


qui reg FF4 iRGDP*, robust 
est store T6_A

qui reg FF4 iPGDP*, robust 
est store T6_B

qui reg FF4 iUNEMP*, robust 
est store T6_C

qui reg FF4 iRGDP* iPGDP* iUNEMP*, robust 
est store T6_D
 
qui reg FF4s iRGDP*, robust 
est store T6_E

qui reg FF4s iPGDP*, robust 
est store T6_F

qui reg FF4s iUNEMP*, robust 
est store T6_G

qui reg FF4s iRGDP* iPGDP* iUNEMP*, robust 
est store T6_H



esttab T6_* using TableE5.txt, replace ///
	cells(b(star fmt(%9.3f)) t(par fmt(%9.2f))) ///
	stats(r2_a F p N, fmt(%9.3f %9.3f %9.3f %9.0g) ) ///
	prehead(Table E5 Appendix) ///
	starlevel(* 0.1 ** 0.05 *** 0.01)  
 
 
 

 
 
 
 

* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 
*
* MONTHLY AGGREGATION								
*
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 


* store in list for monthly aggregation
global D_IVlist FF4 FF4s 		// daily


gen time =year*100+month
levelsof time, local(timelist) 

* sum observations within month
foreach var of varlist $D_IVlist {

	gen M_`var'=.
	
	
	foreach t of local timelist {
	
		qui su `var' if time==`t'
		
		replace M_`var' = r(sum) if time==`t'

	}
}


* drop time duplicates
sort time, stable
qui by time:  gen timedoubles = cond(_N==1,0,_n)

drop if timedoubles >1

* drop unnecessary variables
keep time M_*

* NOTE: up to here time only has entries for months in year in which FOMC occurs
* 		missing months will be added automatically as a result of the merge happening below

gen isFOMCmonth=1

* NOTE: when loading the other monthly variables isFOMCmonth will have nans in 
* 		months without FOMC meetings and will serve as identifier for the AR regressions


/*
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 

VARIABLES IN FILE (All @ Monthly Frequency)

M_FF4	 : FF4 at all HF dates
M_FF4s   : FF4 at scheduled FOMC only

*/


* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 
* LOAD OTHER DATA

*store temporary data file
tempfile tempdata
save tempdata, replace


*import monthly factors
import excel using "Data/Factors.xlsx", sheet("data") firstrow clear

*merge with previous data
merge 1:1 time using tempdata
drop _merge

*store temporary data file
save tempdata, replace



*load other instruments: Gertler & Karadi, Narrative, MPI WP version
import excel using "Data/Other Instruments.xlsx", sheet("data") firstrow clear

*merge with previous data
merge 1:1 time using tempdata
drop _merge

*store temporary data file
save tempdata, replace


* order by date
sort time, stable
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 



*add zeros in months without FOMC meetings
global M_IVlist M_FF4 M_FF4s 	// monthly 

foreach var of varlist $M_IVlist {

	replace `var'=0 if `var'==. & time <=200912 & time >= 199001
}




*set time dimension
gen timeline = tm(1979m1) + _n - 1
format timeline %tm

tsset timeline, monthly 

* NOTE: at this point the dataset is monthly and runs from Jan 1979 to Dec 2014
* 		surprises and candidate IV have zeros in months without FOMC




* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 


global TAB_IVlist1 M_FF4 M_FF4s
global TAB_IVlist2 FF4GK MPN


* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 
* 	TABLE 3 Main Text
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 
foreach var of varlist $TAB_IVlist1 {

		qui reg `var' L(1/1).`var' L.f* if time >199001 & time<=200912, robust
		test L.f1=L.f2=L.f3=L.f4=L.f5=L.f6=L.f7=L.f8=L.f9=L.f10=0
		est store states_`var'
}

foreach var of varlist $TAB_IVlist2 {

		qui reg `var' L(1/1).`var' L.f* if time >=199001, robust
		test L.f1=L.f2=L.f3=L.f4=L.f5=L.f6=L.f7=L.f8=L.f9=L.f10=0
		est store states_`var'
}


esttab states_* using Table3.txt, replace ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	stats(r2_a F p N, fmt(%9.3f %9.3f %9.3f %9.0g) ) ///
	prehead(Table 3 Main Text) ///
	starlevel(* 0.1 ** 0.05 *** 0.01) 
	
	
	


	

* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 
* 	TABLE 2 Main Text
* .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . 

qui reg MPN L(1/4).MPN if isFOMCmonth==1 & time>=199001, robust
est store AR_MPN


global TAB_IVlist M_FF4 M_FF4s FF4GK 
drop if time < 199001 | time > 200912

foreach var of varlist $TAB_IVlist {

		qui reg `var' L(1/4).`var' if isFOMCmonth==1, robust
		est store AR_`var'
}



esttab AR* using Table2.txt, replace ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	stats(r2_a F p N, fmt(%9.3f %9.3f %9.3f %9.0g) ) ///
	prehead(Table 2 Main Text) ///
	starlevel(* 0.1 ** 0.05 *** 0.01) 
	
	
	
