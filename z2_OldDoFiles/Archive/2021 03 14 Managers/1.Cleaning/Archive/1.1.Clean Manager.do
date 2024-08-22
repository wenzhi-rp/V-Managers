********************************************************************************
**                     Cleaning Manager with IDlseMHR                         **
**                              7 Nov, 2020                                   **
/*******************************************************************************

This do-file:

1. Identifies managers in AllSnapshot.dta using the list of managers' IDlse
in ManagerIDReports.dta and tag them as 1 using "Manager" dummy.

2. Adds ISOCodeHome variable to the dataset.

3. Extracts relevant manager characteristics and adds new variables, saving them
in a dta file MListChar.dta.

4. Merges MListChar.dta with the original dataset and generates new variables.

Input: ManagerIDReports.dta,AllSnapshotWC.dta, AllSnapshotBC.dta
Output: $Managersdta/AllSnapshotM.dta
*/

* directory
cd "$Managersdta"

*********************************************************************************
* 1. Identifying managers in the Original Dataset & adding manager IDlse
*********************************************************************************

* 1.a. creating Mlist

* using ManagerIDReports to create tempfile Mlist, which has IDlse of all
* employees who also happen to be a manager in given month.

use "$dta/ManagerIDReports.dta", clear

keep IDlseMHR YearMonth
rename IDlseMHR IDlse

duplicates drop IDlse YearMonth, force

* 1.b. I identify managers in AllSnapshot.dta using the tempfile.

drop if IDlse == . // 60 missing values, which is due to the missing values in IDlseMHR

save "$Managersdta/Temp/Mlist.dta", replace


********************************************************************************
* ADD TRANSFERS VARIABLES for MANAGERS
********************************************************************************

use "$dta/AllSnapshotWC.dta", clear
append using "$dta/AllSnapshotBC.dta"

* Imputed performance 
gen PRI = PR
label var PRI "Imputed PR score using VPA buckets"
replace PRI = 1 if VPA <=25 & (Year >2018 | PR==.)
replace PRI = 2 if VPA >25 & VPA<=75 & (Year >2018 | PR==.)
replace PRI = 3 if VPA >75 & VPA<=100 & (Year >2018 | PR==.)
replace PRI = 4 if VPA >100 & VPA<=115 & (Year >2018 | PR==.)
replace PRI = 5 if VPA >115 & Year >2018 & VPA!=.

*Pay Increase 
gsort IDlse YearMonth
gen PayIn = 1 if (IDlse == IDlse[_n-1] & Pay > Pay[_n-1] ) & Pay!=.
replace PayIn= 0 if PayIn==.  & Pay!=.
label var PayIn "Dummy, equals 1 in the month when Pay is greater than in the preceding"

* Country transfers 
gsort IDlse YearMonth
gen TransferCountry = 0 if Country!=. 
replace  TransferCountry = 1 if (IDlse == IDlse[_n-1] & Country != Country[_n-1] & Country!=.  )
label var  TransferCountry "Dummy, equals 1 in the month when Country is diff. than in the preceding"

gen z = TransferCountry
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & Country!=.
gen TransferCountryC = z 
drop z 
label var TransferCountryC "CUMSUM from dummy=1 in the month when Country is diff. than in the preceding"


* Promotion variables: PromWL OVERALL
gen z = PromWL
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 & PromWL!=.
replace z = 0 if z ==. & PromWL!=.
gen PromWLC = z 
drop z 

label var PromWLC "CUMSUM from dummy=1 in the month when WL is greater than in the preceding month"

* Promotion variables: PromSalaryGrade OVERALL
gen z = PromSalaryGrade
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1  & PromSalaryGrade!=.
replace z = 0 if z ==. & PromSalaryGrade!=.
gen PromSalaryGradeC = z 
drop z

label var PromSalaryGradeC "CUMSUM from dummy=1 in the month when SalaryGrade is higher in ranking than in the preceding month"

* "Promotion" variables: Change in Salary grade OVERALL 
gsort IDlse YearMonth
gen ChangeSalaryGrade = 0 & SalaryGrade !=.
replace  ChangeSalaryGrade = 1 if IDlse == IDlse[_n-1] & SalaryGrade != SalaryGrade[_n-1] & SalaryGrade !=.
label var ChangeSalaryGrade "Equals 1 when SalaryGrade is different than in the preceding month"

gen z = ChangeSalaryGrade
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & SubFunc !=.
gen ChangeSalaryGradeC = z 
drop z  

label var ChangeSalaryGradeC "CUMSUM from dummy=1 in the month when SalaryGrade is different than in the preceding month"

* Demotion variables: DemotionSalaryGrade OVERALL
gen z = DemotionSalaryGrade
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1  & DemotionSalaryGrade!=.
replace z = 0 if z ==. & DemotionSalaryGrade!=.
gen DemotionSalaryGradeC= z 
drop z 
label var DemotionSalaryGradeC "CUMSUM from dummy=1 in the month when SalaryGrade is lower in ranking than in the preceding month"

* Job transfer variables: Job title | position change OVERALL
gsort IDlse YearMonth
gen TransferPTitle = 0 if PositionTitle!="" & EmployeeNum!=.
replace  TransferPTitle = 1 if (IDlse == IDlse[_n-1] & PositionTitle != PositionTitle[_n-1] & PositionTitle!=""  ) | (IDlse == IDlse[_n-1] & EmployeeNum != EmployeeNum[_n-1] & EmployeeNum!=.)
label var  TransferPTitle "Dummy, equals 1 in the month when either PositionTitle or EmployeeNum is diff. than in the preceding"

gen z = TransferPTitle
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & PositionTitle!="" & EmployeeNum!=.
gen TransferPTitleC = z 
drop z 

label var  TransferPTitleC "CUMSUM from dummy=1 in the month when either PositionTitle or EmployeeNum is diff. than in the preceding"

* Job transfer variables: Subfunction OVERALL
gsort IDlse YearMonth
gen TransferSubFunc = 0 & SubFunc !=.
replace  TransferSubFunc = 1 if IDlse == IDlse[_n-1] & SubFunc != SubFunc[_n-1] & SubFunc !=.
label var  TransferSubFunc "Dummy, equals 1 in the month when SubFunc is diff. than in the preceding"

gen z = TransferSubFunc
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & SubFunc !=.
gen TransferSubFuncC = z 
drop z 

label var  TransferSubFuncC "CUMSUM from dummy=1 in the month when SubFunc is diff. than in the preceding"

*Job transfer variables: Function OVERALL
gsort IDlse YearMonth
gen TransferFunc = 0 if Func !=.
replace  TransferFunc = 1 if IDlse == IDlse[_n-1] & Func != Func[_n-1]  & Func !=.
label var  TransferFunc "Dummy, equals 1 in the month when Func is diff. than in the preceding"

gen z = TransferFunc
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & Func !=.
gen  TransferFuncC = z 
drop z 
label var  TransferFuncC "CUMSUM from dummy=1 in the month when Func is diff. than in the preceding"

* Lateral sub func transfer (without promotion): Sub Function
gen TransferSubFuncLateral = 0 if PromSalaryGrade!=. & TransferSubFunc!=.
replace TransferSubFuncLateral  = 1 if TransferSubFunc  == 1 & PromSalaryGrade==0
label var  TransferSubFuncLateral "Dummy, equals 1 in the month when TransferSubFunc=1 but PromSalaryGrade=0"

gen z = TransferSubFuncLateral
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & SubFunc !=.
gen TransferSubFuncLateralC = z 
drop z 

label var  TransferSubFuncLateralC "CUMSUM from dummy=1 in the month when TransferSubFunc=1 but PromSalaryGrade=0"

* Lateral func transfer (without promotion): Function
gen TransferFuncLateral = 0 if PromSalaryGrade!=. & TransferFunc!=.
replace TransferFuncLateral  = 1 if TransferFunc  == 1 & PromSalaryGrade==0
label var  TransferFuncLateral "Dummy, equals 1 in the month when TransferFunc=1 but PromSalaryGrade=0"

gen z = TransferFuncLateral
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & Func !=.
gen TransferFuncLateralC = z 
drop z 

label var  TransferFuncLateralC "CUMSUM from dummy=1 in the month when TransferFunc=1 but PromSalaryGrade=0"

* Lateral Job Position Move (without promotion): Job title | position change 
gen TransferPTitleLateral = 0 if PromSalaryGrade!=. & TransferPTitle!=.
replace TransferPTitleLateral = 1 if TransferPTitle  == 1 & PromSalaryGrade==0
label var  TransferPTitleLateral "Dummy, equals 1 in the month when TransferPTitle=1 but PromSalaryGrade=0"

gen z = TransferPTitleLateral
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & TransferPTitle !=.
gen TransferPTitleLateralC = z 
drop z 
label var  TransferPTitleLateralC "CUMSUM from dummy=1 in the month when TransferPTitle=1 but PromSalaryGrade=0"

* Vertical Promotion: PromSalaryGrade without subfunc change  
gen PromSalaryGradeVertical = 0 if PromSalaryGrade!=. & TransferSubFunc!=.
replace PromSalaryGradeVertical  = 1 if TransferSubFunc  == 0 & PromSalaryGrade==1
label var  PromSalaryGradeVertical "Dummy, equals 1 in the month when PromSalaryGrade=1  but TransferSubFunc=0"

gen z = PromSalaryGradeVertical
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & PromSalaryGrade !=.
gen PromSalaryGradeVerticalC = z 
drop z 
label var  PromSalaryGradeVerticalC "CUMSUM from dummy=1 in the month when PromSalaryGrade=1  but TransferSubFunc=0"

* Lateral Promotion: PromSalaryGrade with subfunc change  
gen PromSalaryGradeLateral = 0 if PromSalaryGrade!=. & TransferSubFunc!=.
replace PromSalaryGradeLateral = 1 if PromSalaryGrade ==1 & TransferSubFunc ==1
label var  PromSalaryGradeLateral "Dummy, equals 1 in the month when PromSalaryGrade=1  but TransferSubFunc=1"

gen z = PromSalaryGradeLateral
by IDlse (YearMonth), sort: replace z = z[_n] +  z[_n-1] if _n>1 
replace z = 0 if z ==. & PromSalaryGrade !=.
gen PromSalaryGradeLateralC = z 
drop z 
label var  PromSalaryGradeLateralC "CUMSUM from dummy=1 in the month when PromSalaryGrade=1  but TransferSubFunc=1"

* Months in position
bys IDlse TransferPTitleC: egen MonthsPTitle =  count(YearMonth)
label var MonthsPTitle "Tot. Months in Position Title"
* Months in subfunction
bys IDlse TransferSubFuncC: egen MonthsSubFunc =  count(YearMonth)
label var MonthsSubFunc "Tot. Months in Sub Function"
* Months in WL
bys IDlse PromWLC: egen MonthsWL =  count(YearMonth)
label var MonthsWL "Tot. Months in WL"
* Months in salary grade
bys IDlse ChangeSalaryGradeC: egen MonthsSG =  count(YearMonth)
label var MonthsSG "Tot. Months in Salary Grade"
* Months in salary grade by promotion 
bys IDlse PromSalaryGradeC: egen MonthsPromSG =  count(YearMonth)
label var MonthsPromSG "Tot. Months in Salary Grade based on promotion categories"
* Time since last promotion 
bys IDlse PromSalaryGradeC: egen MonthsPromSGCum = rank(YearMonth)
label var MonthsPromSGCum "Time since last change in Salary Grade based on promotion categories"
* Time since last salary grade change
bys IDlse ChangeSalaryGradeC: egen MonthsSGCum = rank(YearMonth)
label var MonthsSGCum "Time since last change in Salary Grade"
* Months in firm
gen o = 1
bys IDlse (YearMonth), sort: gen TenureMonths = sum(o)
label var TenureMonths "Tot number of months in the firm up to current month"
drop o
* Time to promotion
sort IDlse YearMonth
bys IDlse PromSalaryGradeC (YearMonth), sort: egen TimetoProm = max(cond(PromSalaryGradeC[_n]!=PromSalaryGradeC[_n-1] & IDlse[_n] == IDlse[_n-1], MonthsPromSG[_n-1] ,.) )
replace TimetoProm = TenureMonths if PromSalaryGradeC==0 
replace TimetoProm = . if PromSalaryGradeC==. 
label var TimetoProm "Tot. Months in Salary Grade prior promotion"

sort IDlse YearMonth
bys IDlse ChangeSalaryGradeC (YearMonth), sort: egen TimetoChangeSG = max(cond(ChangeSalaryGradeC[_n]!=ChangeSalaryGradeC[_n-1] & IDlse[_n] == IDlse[_n-1], MonthsSG[_n-1] ,.) )
replace TimetoChangeSG = TenureMonths if ChangeSalaryGradeC==0
replace TimetoChangeSG = . if ChangeSalaryGradeC==.
label var TimetoChangeSG "Tot. Months in Salary Grade (SG) prior change in SG"

quietly bys IDlse YearMonth:  gen dup = cond(_N==1,0,_n)
drop if BC==1 & dup >0 // if duplicates, only keep WC 
drop dup

********************************************************************************
* Spell variables 
********************************************************************************

sort IDlse YearMonth

* Spell
bys IDlse (YearMonth) , sort : gen ChangeM =  (IDlseMHR[_n] != IDlseMHR[_n-1] & IDlse[_n] ==  IDlse[_n-1])
label var ChangeM "Dummy, equals 1 in the month when IDlseMHR is different compared to the preceding" 
sort IDlse YearMonth
by IDlse (YearMonth) , sort : gen Spell = sum(ChangeM)
replace Spell = Spell + 1 
label var Spell "Employee spell w. Manager"

sort IDlse YearMonth
bys IDlse Spell : egen SpellStart = min(YearMonth)
label var SpellStart  "Start month of employee spell w. Manager"
format SpellStart %tm
bys IDlse Spell : egen SpellEnd = max(YearMonth)
label var SpellEnd  "End month of employee spell w. Manager"
format SpellEnd %tm

forval i= 1(1)6{
gen PostSpell`i'year  = SpellEnd + 12*`i'
format PostSpell`i'year %tm
label var  PostSpell`i'year "`i' year(s) post employee-manager spell" 

gen PostSpell`i'month  = SpellEnd + `i'
format PostSpell`i'month %tm
label var  PostSpell`i'month "`i' month(s) post employee-manager spell" 
}

forval i= 1(1)6{
gen PreSpell`i'year  = SpellStart - 12*`i'
format PreSpell`i'year %tm
label var  PreSpell`i'year "`i' year(s) pre employee-manager spell" 

gen PreSpell`i'month  = SpellStart - `i'
format PreSpell`i'month %tm
label var  PreSpell`i'month "`i' month(s) pre employee-manager spell" 
}

merge 1:1 IDlse YearMonth using "$Managersdta/Temp/Mlist.dta"

drop if _merge == 2 // 12,956 unmatched obs. from ManagerIDReports.dta.

* the matched individuals are managers. I tag them generating a dummy Manager.

gen Manager = 0
replace Manager = 1 if _merge == 3
label var Manager "=1 if employee also appears as a manager in the same monthly snapshot"

drop _merge

* 1.d. saving as AllSnapshotM.dta
compress
save "$Managersdta/AllSnapshotM.dta",replace

*********************************************************************************
* Adding ISOCodeHome, ISOCode for home countries.
*********************************************************************************

* use AllSnapshotM.dta if it is not loaded or loaded but changed
* Note: I add 'if' clause to avoid wasting time to load already existing data.
* But I do not delete the code as it might be necessary to run this section separately.

if "`c(filename)'" != "$Managersdta/AllSnapshotM.dta" | `c(changed)' == 1 {
use "$Managersdta/AllSnapshotM.dta", clear
}

* Extracting "ISOCode", ISOCode for working Countries (Country),
* to generate "ISOCodeHome" variable.
keep CountryS ISOCode
duplicates drop CountryS, force

rename CountryS HomeCountryS
rename ISOCode ISOCodeHome

* Saving
save "$Managersdta/Temp/isocode.dta",replace

* Merging with the original data.

use "$Managersdta/AllSnapshotM.dta", clear

replace HomeCountryS = "Palestine"  if HomeCountryS== "Palestinian Territory Occupied"

merge m:1 HomeCountryS using "$Managersdta/Temp/isocode.dta"
drop if _merge==2
drop _merge HomeCountryS

order ISOCodeHome, a(HomeCountry)

* Updating AllSnapshotM.dta
compress
save "$Managersdta/AllSnapshotM.dta",replace

********************************************************************************
* Preparing Manager Characteristics tempfile to merge with AllSnapshotM.dta
* MANAGER-YM LEVEL CHARACTERISTICS 
********************************************************************************

* use AllSnapshotM.dta if it is not loaded or loaded but changed
if "`c(filename)'" != "$Managersdta/AllSnapshotM.dta" | `c(changed)' == 1 {
use "$Managersdta/AllSnapshotM.dta", clear
}

*Dropping non-manager employees and unnecessary variables

keep if Manager ==1

* MANAGERS CHARS 
 global Mvariables BC HomeCountry ISOCodeHome Country CountryS ISOCode Cluster Market PositionTitle StandardJob StandardJobCode Func SubFunc Female WL WLSalaryGrade AgeBand Tenure EmpType LeaverType LeaverInv LeaverVol LeaverPerm LeaverTemp SalaryGrade SalaryGradeC  SalaryGradeOrder PromWL PromWLSalaryGrade PromSalaryGrade DemotionSalaryGrade Pay Benefit Bonus Package PR PRI PRSnapshot VPA PayIn  TransferCountry TransferCountryC PromWLC PromSalaryGradeC DemotionSalaryGradeC TransferPTitle TransferPTitleC TransferSubFunc  TransferSubFuncC TransferFunc TransferFuncC TransferSubFuncLateral TransferSubFuncLateralC TransferFuncLateral TransferFuncLateralC  TransferPTitleLateral TransferPTitleLateralC PromSalaryGradeVertical PromSalaryGradeVerticalC PromSalaryGradeLateral  PromSalaryGradeLateralC MonthsPTitle MonthsSubFunc MonthsPromSG MonthsWL MonthsSG MonthsSGCum  MonthsPromSGCum ChangeSalaryGrade ChangeSalaryGradeC TimetoChangeSG TimetoProm

keep IDlse YearMonth Year $Mvariables

/*tab BC // most managers are WC
         BC |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |  1,801,889       99.26       99.26
          1 |     13,493        0.74      100.00
------------+-----------------------------------
      Total |  1,815,382      100.00
*/

*Generating additional variables for managers only
********************************************************************************

* Generating Round IA info
gen IA = 1 if EmpType >=3 & EmpType <=7
replace IA =0 if IA==.
by IDlse (YearMonth), sort: gen RoundIA1 = (Country != Country[_n-1] & _n > 1 & IA==1)
by IDlse (YearMonth), sort: gen RoundIA2 = (IA[_n] & _n==1)
gen RoundIA = RoundIA1 + RoundIA2
by IDlse (YearMonth), sort: gen RoundIAcum = sum(RoundIA)
drop IA RoundIA1 RoundIA2 RoundIA
rename RoundIAcum RoundIA

*Renaming variables

* Specific cases
rename IDlse IDlseMHR

foreach var in $Mvariables  {
rename `var' `var'M
}

* Compressing and saving MListChar
compress
save "$Managersdta/Temp/MListChar.dta", replace

********************************************************************************
* Merging AllSnapshotM with Mchar 
********************************************************************************

* Adding MListchar variables by merging the file with AllSnapshotM.dta

* use AllSnapshotM.dta if it is not loaded or loaded but changed
if "`c(filename)'" != "$Managersdta/AllSnapshotM.dta" | `c(changed)' == 1 {
use "$Managersdta/AllSnapshotM.dta", clear
}
merge m:1 IDlseMHR YearMonth using "$Managersdta/Temp/MListChar.dta"
drop if _merge ==2 
drop _merge
compress
save "$Managersdta/AllSnapshotM.dta", replace 


********************************************************************************
* Preparing Manager Characteristics tempfile to merge with AllSnapshotM.dta
* MANAGER-SPELL LEVEL CHARACTERISTICS 
********************************************************************************

* Generating PRE & POST vars of the below to construct pre and post indicators of MQ
************************************************************************************

* use AllSnapshotM.dta if it is not loaded or loaded but changed
if "`c(filename)'" != "$Managersdta/AllSnapshotM.dta" | `c(changed)' == 1 {
use "$Managersdta/AllSnapshotM.dta", clear
}

gen o = 1 
egen ID = group(IDlse IDlseMHR Spell)
drop if ID ==.
collapse o , by(IDlseMHR SpellStart SpellEnd ID PostSpell1year PostSpell2year PostSpell3year PostSpell4year PostSpell5year PostSpell6year PreSpell1year PreSpell2year PreSpell3year PreSpell4year PreSpell5year PreSpell6year PostSpell1month PostSpell2month PostSpell3month PostSpell4month PostSpell5month PostSpell6month PreSpell1month PreSpell2month PreSpell3month PreSpell4month PreSpell5month PreSpell6month)

rename  IDlseMHR IDlse // want to look at what happens to the manager 
isid ID
drop o

* to split sample for joinby
egen Ind = cut(ID), group(40)
replace Ind = Ind+1
compress
save "$temp/SpellTimeM.dta", replace // dataset at spell level 


forval sample = 1/40{

use "$temp/SpellTimeM.dta", clear    
keep if Ind == `sample'
joinby IDlse using  "$Managersdta/AllSnapshotM.dta" 

* these are the MQ variables
local prepost Pay Bonus PR PRI PRSnapshot VPA TimetoProm TimetoChangeSG PromSalaryGradeC ChangeSalaryGradeC MonthsPromSGCum MonthsSGCum TransferSubFuncC TransferFuncC TransferPTitleC MonthsSubFunc   MonthsWL TransferCountryC 

local post LeaverInv LeaverVol LeaverPerm

foreach var in  `prepost' {
	forval i= 1(1)2{
bys ID: egen `var'PostS`i'y  = max(cond(YearMonth == PostSpell`i'year, `var', .))
label var  `var'PostS`i'y  "`var' `i' year(s) post spell" 
 
bys ID: egen `var'PostS`i'm  = max(cond(YearMonth == PostSpell`i'month, `var', .)) 
label var  `var'PostS`i'm  "`var' `i' month(s) post spell" 

bys ID: egen `var'PreS`i'y  = max(cond(YearMonth == PreSpell`i'year, `var', .)) 
label var  `var'PreS`i'y  "`var' `i' year(s) pre spell" 

bys ID: egen `var'PreS`i'm  = max(cond(YearMonth == PreSpell`i'month, `var', .)) 
label var  `var'PreS`i'm  "`var' `i' month(s) pre spell" 


}
}

foreach var in  `post' {
	forval i= 1(1)2{
bys ID: egen `var'PostS`i'y  = max(cond(YearMonth == PostSpell`i'year, `var', .)) 
label var  `var'PostS`i'y  "`var' `i' year(s) post spell" 

bys ID: egen `var'PostS`i'm  = max(cond(YearMonth == PostSpell`i'month, `var', .)) 
label var  `var'PostS`i'm  "`var' `i' month(s) post spell" 

}
}

 local MSpell PayPostS*y PayPostS*m PayPreS*y PayPreS*m BonusPostS*y BonusPostS*m BonusPreS*y BonusPreS*m PRPostS*y PRPostS*m PRPreS*y PRPreS*m  PRIPostS*y PRIPostS*m PRIPreS*y PRIPreS*m  PRSnapshotPostS*y PRSnapshotPostS*m PRSnapshotPreS*y PRSnapshotPreS*m  VPAPostS*y VPAPostS*m VPAPreS*y VPAPreS*m PromSalaryGradeCPostS*y PromSalaryGradeCPostS*m PromSalaryGradeCPreS*y PromSalaryGradeCPreS*m   ChangeSalaryGradeCPostS*y ChangeSalaryGradeCPostS*m ChangeSalaryGradeCPreS*y ChangeSalaryGradeCPreS*m  MonthsPromSGCumPostS*y MonthsPromSGCumPostS*m MonthsPromSGCumPreS*y MonthsPromSGCumPreS*m MonthsSGCumPostS*y MonthsSGCumPostS*m MonthsSGCumPreS*y MonthsSGCumPreS*m  TransferSubFuncCPostS*y TransferSubFuncCPostS*m TransferSubFuncCPreS*y TransferSubFuncCPreS*m  TransferFuncCPostS*y TransferFuncCPostS*m TransferFuncCPreS*y TransferFuncCPreS*m  TransferPTitleCPostS*y TransferPTitleCPostS*m TransferPTitleCPreS*y TransferPTitleCPreS*m MonthsSubFuncPostS*y MonthsSubFuncPostS*m MonthsSubFuncPreS*y MonthsSubFuncPreS*m  MonthsWLPostS*y MonthsWLPostS*m MonthsWLPreS*y MonthsWLPreS*m    TransferCountryCPostS*y TransferCountryCPostS*m TransferCountryCPreS*y TransferCountryCPreS*m TimetoPromPostS*y TimetoPromPostS*m TimetoPromPreS*y TimetoPromPreS*m TimetoChangeSGPostS*y TimetoChangeSGPostS*m TimetoChangeSGPreS*y TimetoChangeSGPreS*m  LeaverInvPostS*y LeaverInvPostS*m LeaverVolPostS*y LeaverVolPostS*m   LeaverPermPostS*y LeaverPermPostS*m

foreach v of var `MSpell' {
 local l`v' : variable label `v'
 if `"`l`v''"' == "" {
 local l`v' "`v'"
}
}


keep `MSpell' ID
compress 
collapse `MSpell', by(ID) fast 

foreach v of var `MSpell' {
 label var `v' "`l`v''"
}

* Compressing and saving MSpellChar
compress
save "$Managersdta/Temp/MSpellChar`sample'.dta", replace
}

use "$Managersdta/Temp/MSpellChar1.dta", clear 
forval i=2(1)40{
append using "$Managersdta/Temp/MSpellChar`i'.dta"
}
compress
save "$Managersdta/Temp/MSpellChar.dta", replace
 
********************************************************************************
* Merging AllSnapshotM with Mchar 
********************************************************************************

* Adding MSpellchar variables by merging the file with AllSnapshotM.dta

* use AllSnapshotM.dta if it is not loaded or loaded but changed
if "`c(filename)'" != "$Managersdta/AllSnapshotM.dta" | `c(changed)' == 1 {
use "$Managersdta/AllSnapshotM.dta", clear
}

egen ID = group(IDlse IDlseMHR Spell)

merge m:1 ID using "$Managersdta/Temp/MSpellChar.dta"
keep if _merge !=2
drop _merge 

isid IDlse YearMonth
compress
save "$Managersdta/AllSnapshotM.dta", replace 


********************************************************************************
* Preparing Employee Characteristics tempfile to merge with AllSnapshotM.dta
* EMPLOYEE-SPELL LEVEL CHARACTERISTICS 
********************************************************************************

* use AllSnapshotM.dta if it is not loaded or loaded but changed
if "`c(filename)'" != "$Managersdta/AllSnapshotM.dta" | `c(changed)' == 1 {
use "$Managersdta/AllSnapshotM.dta", clear
}

cap drop o
gen o = 1 
collapse o , by(IDlse SpellStart SpellEnd ID PostSpell1year PostSpell2year PostSpell3year PostSpell4year PostSpell5year PostSpell6year PreSpell1year PreSpell2year PreSpell3year PreSpell4year PreSpell5year PreSpell6year PostSpell1month PostSpell2month PostSpell3month PostSpell4month PostSpell5month PostSpell6month PreSpell1month PreSpell2month PreSpell3month PreSpell4month PreSpell5month PreSpell6month)

drop if ID ==.
isid ID
drop o
egen Ind = cut(ID), group(40)
replace Ind = Ind+1
compress
compress
save "$temp/SpellTimeE.dta", replace // dataset at spell level 

forval sample = 1/40{

use "$temp/SpellTimeE.dta", clear    
keep if Ind == `sample'
joinby IDlse using  "$Managersdta/AllSnapshotM.dta" 

* Generate spell level variables for employee 

* these are the EQ variables
local prepost Pay Bonus PR PRI PRSnapshot VPA TimetoProm TimetoChangeSG PromSalaryGradeC ChangeSalaryGradeC MonthsPromSGCum MonthsSGCum TransferSubFuncC TransferFuncC TransferPTitleC MonthsSubFunc   MonthsWL TransferCountryC
local post LeaverInv LeaverVol LeaverPerm

foreach var in  `prepost' {
	forval i= 1(1)2{
bys ID: egen `var'PostS`i'yE  = max(cond(YearMonth == PostSpell`i'year, `var', .))
label var  `var'PostS`i'yE  "`var' `i' year(s) post spell" 
 
bys ID: egen `var'PostS`i'mE  = max(cond(YearMonth == PostSpell`i'month, `var', .)) 
label var  `var'PostS`i'mE  "`var' `i' month(s) post spell" 

bys ID: egen `var'PreS`i'yE  = max(cond(YearMonth == PreSpell`i'year, `var', .)) 
label var  `var'PreS`i'yE  "`var' `i' year(s) pre spell" 

bys ID: egen `var'PreS`i'mE  = max(cond(YearMonth == PreSpell`i'month, `var', .)) 
label var  `var'PreS`i'mE  "`var' `i' month(s) pre spell" 

}
}

foreach var in  `post' {
	forval i= 1(1)2{
bys ID: egen `var'PostS`i'yE  = max(cond(YearMonth == PostSpell`i'year, `var', .)) 
label var  `var'PostS`i'yE  "`var' `i' year(s) post spell" 

bys ID: egen `var'PostS`i'mE  = max(cond(YearMonth == PostSpell`i'month, `var', .)) 
label var  `var'PostS`i'mE  "`var' `i' month(s) post spell" 

}
}


 local ESpell PayPostS*yE PayPostS*mE PayPreS*yE PayPreS*mE BonusPostS*yE BonusPostS*mE BonusPreS*yE BonusPreS*mE PRPostS*yE PRPostS*mE PRPreS*yE PRPreS*mE  PRIPostS*yE PRIPostS*mE PRIPreS*yE PRIPreS*mE  PRSnapshotPostS*yE PRSnapshotPostS*mE PRSnapshotPreS*yE PRSnapshotPreS*mE  VPAPostS*yE VPAPostS*mE VPAPreS*yE VPAPreS*mE PromSalaryGradeCPostS*yE PromSalaryGradeCPostS*mE PromSalaryGradeCPreS*yE PromSalaryGradeCPreS*mE   ChangeSalaryGradeCPostS*yE ChangeSalaryGradeCPostS*mE ChangeSalaryGradeCPreS*yE ChangeSalaryGradeCPreS*mE  MonthsPromSGCumPostS*yE MonthsPromSGCumPostS*mE MonthsPromSGCumPreS*yE MonthsPromSGCumPreS*mE MonthsSGCumPostS*yE MonthsSGCumPostS*mE MonthsSGCumPreS*yE MonthsSGCumPreS*mE  TransferSubFuncCPostS*yE TransferSubFuncCPostS*mE TransferSubFuncCPreS*yE TransferSubFuncCPreS*mE  TransferFuncCPostS*yE TransferFuncCPostS*mE TransferFuncCPreS*yE TransferFuncCPreS*mE  TransferPTitleCPostS*yE TransferPTitleCPostS*mE TransferPTitleCPreS*yE TransferPTitleCPreS*mE MonthsSubFuncPostS*yE MonthsSubFuncPostS*mE MonthsSubFuncPreS*yE MonthsSubFuncPreS*mE  MonthsWLPostS*yE MonthsWLPostS*mE MonthsWLPreS*yE MonthsWLPreS*mE    TransferCountryCPostS*yE TransferCountryCPostS*mE TransferCountryCPreS*yE TransferCountryCPreS*mE TimetoPromPostS*yE TimetoPromPostS*mE TimetoPromPreS*yE TimetoPromPreS*mE TimetoChangeSGPostS*yE TimetoChangeSGPostS*mE TimetoChangeSGPreS*yE TimetoChangeSGPreS*mE  LeaverInvPostS*yE LeaverInvPostS*mE LeaverVolPostS*yE LeaverVolPostS*mE   LeaverPermPostS*yE LeaverPermPostS*mE

compress
collapse `ESpell', by(ID) fast
* Compressing and saving ESpellChar
compress
save "$Managersdta/Temp/ESpellChar`sample'.dta", replace

} 

use "$Managersdta/Temp/ESpellChar1.dta", clear 
forval i=2(1)40{
append using "$Managersdta/Temp/ESpellChar`i'.dta"
}
compress
save "$Managersdta/Temp/ESpellChar.dta", replace

********************************************************************************
* Merging AllSnapshotM with Echar 
********************************************************************************

* Adding MSpellchar variables by merging the file with AllSnapshotM.dta

* use AllSnapshotM.dta if it is not loaded or loaded but changed
if "`c(filename)'" != "$Managersdta/AllSnapshotM.dta" | `c(changed)' == 1 {
use "$Managersdta/AllSnapshotM.dta", clear
}

*egen ID = group(IDlse IDlseMHR Spell)

merge m:1 ID using "$Managersdta/Temp/ESpellChar.dta"
keep if _merge !=2
drop _merge 

isid IDlse YearMonth
compress
save "$Managersdta/AllSnapshotM.dta", replace 

*********************************************************************************
* Generating additional variables & modifying some variables
*********************************************************************************

* number of direct reports
bys YearMonth IDlseMHR: gen NoReportees = _N // number of direct reports
replace NoReportees =. if IDlseMHR==.
order NoReportees, a(IDlseMHR)
label var NoReportees "No. of employees reporting to same manager in current month"

* Country Size
bysort YearMonth Country: egen CountrySize = count(IDlse) // no. of employees by country and month
label var CountrySize "No. of employees in each country and month"

* Office
distinct Office 
distinct Country 
quietly bys Office: gen dup_location = cond(_N==1,0,_n)
bys Country YearMonth: egen OfficeNum = count(Office) if (dup_location ==0 & Office !=. | dup_location ==1 & Office !=.)
drop dup_location 
label var OfficeNum "No. of offices in each Country and Month"

* Additional variables useful for the analysis
egen CountryYM = group(Country YearMonth)
egen IDlseMHRYM = group(IDlseMHR YearMonth)
decode HomeCountryM, gen(HomeCountrySM)
order HomeCountrySM, a(HomeCountryM)

* Compressing and saving in AllSnapshotM.dta.
compress
save "$Managersdta/AllSnapshotM.dta",replace


