********************************************************************************
* This do files conducts team level analysis at the month level - SYMMETRIC
********************************************************************************

use "$managersdta/Teams.dta" , clear 

*keep if Year>2013 // post sample only if using PromSG75

bys team: egen mSpan= min(SpanM)
*drop if mSpan == 1 

bys team: egen minK = min(KEi)
bys team: egen maxK = max(KEi)
count if minK <=-12 & maxK >=12 
count if minK <=-24 & maxK >=24 
count if minK <=-36 & maxK >=36

foreach var in FT Effective PromSG75 PromWL75  PromSG50 PromWL50 PromSG75v2015 PromWL75v2015  PromSG50v2015 PromWL50v2015{
global `var'  `var'LHPost `var'LLPost `var'HLPost `var'HHPost 
egen `var'Event = rowmax( `var'LHPost `var'LLPost `var'HLPost `var'HHPost ) 
gen `var'DEvent = `var'Event*Delta`var'
label var  `var'LHPost "Low to High"
label  var `var'LLPost "Low to Low"
label  var `var'HLPost "High to Low"
label var  `var'HHPost "High to High"
label var `var'Event "Event"
label var `var'DEvent "Event*Delta M. Talent"
label var Delta`var' "Delta M. Talent"
} 

foreach Label in FT Effective PromSG75 PromWL75  PromSG50 PromWL50 PromSG75v2015 PromWL75v2015  PromSG50v2015 PromWL50v2015{
foreach var in `Label'LH `Label'HH `Label'HL `Label'LL {
	gen `var'Pre = 1-`var'Post
	replace `var'Pre = 0 if `var'==. 
	replace `var'Pre = . if `Label'LH==. & `Label'LL ==. & `Label'HH ==. & `Label'HL ==. // missing for non-switchers
	
}
	label var  `Label'LHPre "Low to High"
	label var `Label'LLPre "Low to Low"
	label var `Label'HLPre "High to Low"
	label var  `Label'HHPre "High to High"
}

* Table: Prom. (salary) / Pay Growth / Pay (CV) /   Perf. Appraisals (CV)
* Table: exit firm / change team / join team /  job change same m 
* Table: ShareSameG ShareSameAge ShareSameNationality ShareSameOffice

* Define variable globals 
global perf  ShareChangeSalaryGrade  AvPayGrowth CVPay  CVVPA  
global move  ShareLeaver ShareTeamLeavers ShareTeamJoiners  ShareTransferSJ  
global homo  ShareSameG  ShareSameAge  ShareSameOffice ShareSameCountry F1ShareConnected F1ShareConnectedL F1ShareConnectedV // TO BE MODIFIED TO ALSO ADD ShareChangeOffice
global div TeamFracGender  TeamFracAge  TeamFracOffice  TeamFracCountry    
global job NewJob OldJob NewJobManager OldJobManager
global out  SpanM SharePromWL AvPay AvProductivityStd SDProductivityStd ShareExitTeam ShareLeaverVol ShareLeaverInv F1ShareTransferSJDiffM F3mShareTransferSJDiffM F6mShareTransferSJDiffM ShareOrg4 ShareFemale ShareSameNationality TeamFracNat

* note: cannot look at same nationality because 75% of obs has zero - there is very little variation 
* TeamEthFrac

global charsExitFirm  LeaverPermFemale LeaverPermAge20  LeaverPermEcon LeaverPermSci LeaverPermHum  LeaverPermNewHire LeaverPermTenure5 LeaverPermEarlyAge LeaverPermPayGrowth1yAbove1
global charsExitTeam ExitTeamFemale ExitTeamAge20  ExitTeamEcon ExitTeamSci ExitTeamHum  ExitTeamNewHire ExitTeamTenure5 ExitTeamEarlyAge ExitTeamPayGrowth1yAbove1
global charsJoinTeam  ChangeMFemale ChangeMAge20  ChangeMEcon ChangeMSci ChangeMHum  ChangeMNewHire ChangeMTenure5 ChangeMEarlyAge ChangeMPayGrowth1yAbove1
global charsChangeTeam F1ChangeMFemale F1ChangeMAge20  F1ChangeMEcon F1ChangeMSci F1ChangeMHum  F1ChangeMNewHire F1ChangeMTenure5 F1ChangeMEarlyAge F1ChangeMPayGrowth1yAbove1 

global controls  FuncM WLM AgeBandM CountryM Year
global cont SpanM c.TenureM##c.TenureM##i.FemaleM 

********************************************************************************
* TEAM LEVEL REGRESSIONS - month and team FE 
********************************************************************************

sort IDlseMHR YearMonth

eststo clear
local i = 1
	local Label FT //  PromSG75 FT 
foreach y in  $perf $move  $homo $div $job AvPay   {

/*mean `y' if e(sample)
mat coef=e(b)
local cmean = coef[1,1]
count if e(sample)
local N1 = r(N)
*/

eststo reg`i'FE:	reghdfe `y' `Label'Event `Label'DEvent  c.TenureM##c.TenureM##i.FemaleM if SpanM>1 & KEi<=36 & KEi>=-36, a(   team ) cluster(IDlseMHR)

local lbl : variable label `y'

estadd local Controls "Yes" , replace
estadd local TeamFE "Yes" , replace
su `y' if SpanM>1  & KEi<=-1 & KEi>=-36
estadd scalar cmean = r(mean)
su `y'  if SpanM>1 & KEi<=-1 & KEi>=-36
cap drop cmean`i'
gen cmean`i'= r(mean)
local i = `i' +1
}

* Note: when outcome is AvPay I can look at how the mean in pay increases relative to the coefficient of variation 
* Coeff on talent is  7455 and baseline mean is  54052 so 7455/ 54052 = 14% 
* So the increase in inequality 11% is similar to the increase in the average pay 

********************************************************************************  
* coefplot 
********************************************************************************

* SEPARATE GRAPHS 
************************************************************************

	local Label FT //   FT PromSG75
coefplot reg1FE  , levels(90) ///
keep(*DEvent) vertical recast(bar ) rescale(100)  ciopts(recast(rcap)) citop legend(off) ///
msymbol(d) mcolor(white) swapnames aseq scheme(burd5) barwidth(0.5)  addplot(scatter @b @at, ms(i) mlabel( @b) mlabpos(2) mlabcolor(black) mlabsize(medlarge)) format(%9.2g) ///
coeflabels(  reg1FE = "{bf:Share Promoted (monthly)}", labsize(medlarge)  ) ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span) ///
title("" " ", pos(12) span si(vlarge)) ytitle(Percentage points, size(medlarge)) yscale(range(0 0.2)) ylabel(0(0.05)0.2)
*ysize(6) xsize(8)  ytick(#6,grid glcolor(black)) scale(0.9) yscale(range(0 1.2)) ylabel(0(0.2)1.2) ytitle(Percentage points)
graph export  "$analysis/Results/8.Team/`Label'PromSym.png", replace

local Label FT //   FT PromSG75
coefplot  reg2FE  , levels(90) ///
keep(*DEvent) vertical recast(bar  )   addplot(scatter @b @at, ms(i) mlabel( @b) mlabpos(2) mlabcolor(black) mlabsize(medlarge)) format(%9.2g) rescale(100)  ciopts(recast(rcap)) citop legend(off) ///
msymbol(d) mcolor(white) swapnames aseq scheme(burd5) barwidth(0.5) ///
coeflabels(   reg2FE = "{bf:Average Monthly Pay Growth}", labsize(medlarge) ) ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span) ///
title("" " ", pos(12) span si(vlarge)) ytitle(Percentage points, size(medlarge)) yscale(range(0 0.2)) ylabel(0(0.05)0.2)
*ysize(6) xsize(8)  ytick(#6,grid glcolor(black)) scale(0.9) yscale(range(0 1.2)) ylabel(0(0.2)1.2) ytitle(Percentage points)
graph export  "$analysis/Results/8.Team/`Label'PaySym.png", replace
	
local Label FT //   FT PromSG75
coefplot (reg3FE,  ciopts(recast(rcap) ) )  , levels(90)  ///
keep(*DEvent) vertical recast(bar )  barwidth(0.5)  mlabel scheme(burd5) citop legend(off)  addplot(scatter @b @at, ms(i) mlabel( @b) mlabpos(2) mlabcolor(black) mlabsize(medlarge)) format(%9.2g) ///
msymbol(d) mcolor(white) swapnames aseq ///
coeflabels(  reg3FE = "{bf:Coefficient Variation in Pay}", labsize(medlarge) ) ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span) ///
title("" " ", pos(12) span si(vlarge)) yscale(range(0 0.04)) ylabel(0(0.01)0.04)
*ysize(6) xsize(8)  ytick(#6,grid glcolor(black)) scale(0.9) yscale(range(0 1.2)) ylabel(0(0.2)1.2) ytitle(Percentage points)
graph export  "$analysis/Results/8.Team/`Label'CVPaySym.png", replace

local Label FT //   FT PromSG75
coefplot reg5FE , levels(90) ///
keep(*DEvent) vertical recast(bar ) rescale(100)  ciopts(recast(rcap)) citop legend(off) ///
msymbol(d) mcolor(white) swapnames aseq scheme(burd5) barwidth(0.5)  format(%9.2g) addplot(scatter @b @at, ms(i) mlabel( @b) mlabpos(2) mlabcolor(black) mlabsize(medlarge)) ///
coeflabels(  reg5FE = "{bf:Exit Firm}" ,  labsize(medlarge)  ) ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span) ///
title("" " ", pos(12) span si(vlarge)) ytitle(Percentage points, size(medlarge))
*ysize(6) xsize(8)  ytick(#6,grid glcolor(black)) scale(0.9) yscale(range(0 1.2)) ylabel(0(0.2)1.2) ytitle(Percentage points)
graph export  "$analysis/Results/8.Team/`Label'ExitSym.png", replace

local Label FT //   FT PromSG75
coefplot  reg6FE  , levels(90) ///
keep(*DEvent) vertical recast(bar ) rescale(100)  ciopts(recast(rcap)) citop legend(off) ///
msymbol(d) mcolor(white) swapnames aseq scheme(burd5) barwidth(0.5)  format(%9.2g) addplot(scatter @b @at, ms(i) mlabel( @b) mlabpos(2) mlabcolor(black) mlabsize(medlarge)) ///
coeflabels(   reg6FE = "{bf:Job change, different team}" ,  labsize(medlarge) ) ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span) ///
title("" " ", pos(12) span si(vlarge)) ytitle(Percentage points, size(medlarge))  yscale(range(0 1.2)) ylabel(0(0.2)1.2)
*ysize(6) xsize(8)  ytick(#6,grid glcolor(black)) scale(0.9) ytitle(Percentage points)
graph export  "$analysis/Results/8.Team/`Label'DiffTeamSym.png", replace

local Label FT //   FT PromSG75
coefplot  reg8FE  , levels(90)  addplot(scatter @b @at, ms(i) mlabel( @b) mlabpos(2) mlabcolor(black) mlabsize(medlarge)) format(%9.2g) ///
keep(*DEvent) vertical recast(bar ) rescale(100)  ciopts(recast(rcap)) citop legend(off) ///
msymbol(d) mcolor(white) swapnames aseq scheme(burd5) barwidth(0.5) ///
coeflabels(   reg8FE = "{bf:Job change, same team}"  ,  labsize(medlarge) ) ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span) ///
title("" " ", pos(12) span si(vlarge)) ytitle(Percentage points ,  size(medlarge))
*ysize(6) xsize(8)  ytick(#6,grid glcolor(black)) scale(0.9) yscale(range(0 1.2)) ylabel(0(0.2)1.2) ytitle(Percentage points)
graph export  "$analysis/Results/8.Team/`Label'SameTeamSym.png", replace

local Label FT //   FT 
coefplot reg13FE  reg14FE reg15FE, levels(90) ///
keep(*DEvent) vertical recast(bar )   ciopts(recast(rcap)) citop legend(off) ///
msymbol(d) mcolor(white) swapnames aseq coeflabels(  reg13FE = "{bf: All moves}"  reg14FE = "{bf:Lateral moves}" reg15FE = "{bf:Promotions}" ) note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span) ///
title("Moves within manager's network" " ", pos(12) span si(vlarge)) yscale(range(-0.2 0.2)) ylabel(-0.2(0.1)0.2) rescale(100) ytitle(Percentage points)
graph export  "$analysis/Results/8.Team/`Label'NetworkSym.png", replace


* COMBINED GRAPHS 
********************************************************************************

coefplot (reg3FE,   ciopts(recast(rcap) ) ) (reg4FE, bcolor(red) ciopts(recast(rcap) lcolor(red)) )  , levels(90)  ///
keep(*DEvent) vertical recast(bar )     citop legend(off) ///
msymbol(d) mcolor(white) swapnames aseq  scheme(burd5) ///
coeflabels(  reg3FE = "{bf:Coeff. Var. Pay}" reg4FE = "{bf:Coeff. Var. Perf. App.}") ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span) ///
title("" " ", pos(12) span si(vlarge)) 
*ysize(6) xsize(8)  ytick(#6,grid glcolor(black)) scale(0.9) yscale(range(0 1.2)) ylabel(0(0.2)1.2) ytitle(Percentage points)
graph export  "$analysis/Results/8.Team/`Label'CVVPASym.png", replace

local Label FT //   FT PromSG75
coefplot reg5FE reg6FE  reg8FE , levels(90) ///
keep(*DEvent) vertical recast(bar ) rescale(100) barwidth(0.5)  format(%9.2g) addplot(scatter @b @at, ms(i) mlabel( @b) mlabpos(2) mlabcolor(black) mlabsize(medlarge)) ciopts(recast(rcap)) citop legend(off) ///
msymbol(d) mcolor(white) swapnames aseq scheme(burd5) ///
coeflabels(  reg5FE = "{bf:Exit Firm}"  reg6FE = "{bf:Job change, different team}" reg8FE = "{bf:Job change, same team}",  labsize(medlarge) ) ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span) ///
title("" " ", pos(12) span si(vlarge)) ytitle(Percentage points, size(medlarge))
*ysize(6) xsize(8)  ytick(#6,grid glcolor(black)) scale(0.9) yscale(range(0 1.2)) ylabel(0(0.2)1.2) ytitle(Percentage points)
graph export  "$analysis/Results/8.Team/`Label'MoveSym.png", replace
* job change different team 


local Label FT //   FT PromSG75
coefplot reg9FE  reg10FE reg11FE , levels(90) ///
keep(*DEvent) vertical recast(bar )   ciopts(recast(rcap)) citop legend(off) ///
msymbol(d) mcolor(white) swapnames aseq coeflabels(  reg9FE = "{bf: Same Gender}"  reg10FE = "{bf:Same Age Group}" reg11FE = "{bf:Same Office}"  ) note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span) ///
title(" " " ", pos(12) span si(vlarge)) 
graph export  "$analysis/Results/8.Team/`Label'HomoSym.png", replace

local Label FT //   FT 
coefplot reg13FE  reg14FE reg15FE, levels(90) ///
keep(*DEvent) vertical recast(bar )   ciopts(recast(rcap)) citop legend(off) ///
msymbol(d) mcolor(white) swapnames aseq coeflabels(  reg13FE = "{bf: All moves}"  reg14FE = "{bf:Lateral moves}" reg15FE = "{bf:Promotions}" ) note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span) ///
title("Moves within manager's network" " ", pos(12) span si(vlarge)) yscale(range(-0.2 0.2)) ylabel(-0.2(0.1)0.2) rescale(100) ytitle(Percentage points)
graph export  "$analysis/Results/8.Team/`Label'NetworkSym.png", replace

local Label FT //   FT 
coefplot     reg16FE reg17FE   reg18FE , levels(90) ///
keep(*DEvent) vertical recast(bar )   ciopts(recast(rcap)) citop legend(off) ///
msymbol(d) mcolor(white) swapnames aseq ///
coeflabels(  reg16FE = "{bf:Gender Diversity}"  reg17FE = "{bf:Age Diversity}" reg18FE = "{bf:Office Diversity}"  ) ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span) ///
title("" " ", pos(12) span si(vlarge)) 
*ysize(6) xsize(8)  ytick(#6,grid glcolor(black)) scale(0.9) yscale(range(0 1.2)) ylabel(0(0.2)1.2) ytitle(Percentage points)
graph export  "$analysis/Results/8.Team/`Label'DivSym.png", replace

local Label FT //   FT 
coefplot     reg19FE reg20FE    , levels(90) ///
keep(*DEvent) vertical recast(bar )   ciopts(recast(rcap)) citop legend(off) ///
msymbol(d) mcolor(white) swapnames aseq ///
coeflabels(  reg19FE = "{bf:Share Jobs created}"  reg20FE = "{bf:Share Jobs Destroyed}"  ) ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span) ///
title("" " ", pos(12) span si(vlarge)) 
*ysize(6) xsize(8)  ytick(#6,grid glcolor(black)) scale(0.9) yscale(range(0 1.2)) ylabel(0(0.2)1.2) ytitle(Percentage points)
graph export  "$analysis/Results/8.Team/`Label'NewJobSym.png", replace

********************************************************************************
* TABLES TO EXPORT 
********************************************************************************

local Label FT //   FT 
* Table: Prom. (salary) / Pay Growth / Productivity / Pay (CV) /  Productivity (CV) / Perf. Appraisals (CV)
esttab reg1FE reg2FE reg3FE reg4FE  using "$analysis/Results/8.Team/`Label'PerfSym.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE cmean N r2, labels("Controls" "Team FE" "\hline Baseline Mean" "N" "R-squared" ) )  interaction("$\times$ ")  nobaselevels  keep(*Event ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Controls include:  tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. The baseline mean is taken in the 36 months before the transition. ///
"\end{tablenotes}") replace

* Table: exit firm / change team / join team /  job change same m / job change diff m 
esttab   reg5FE reg6FE reg7FE reg8FE using "$analysis/Results/8.Team/`Label'MoveSym.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE cmean N r2, labels("Controls" "Team FE" "\hline Baseline Mean" "N" "R-squared" ) )  interaction("$\times$ ")  nobaselevels  keep(*Event ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Controls include:  tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. The baseline mean is taken in the 36 months before the transition. ///
"\end{tablenotes}") replace

* Table: ShareSameG ShareSameNationality ShareSameAge ShareSameOffice
esttab  reg9FE reg10FE reg11FE reg12FE reg13FE  using "$analysis/Results/8.Team/`Label'CompSym.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE cmean N r2, labels("Controls" "Team FE" "\hline Baseline Mean" "N" "R-squared" ) )  interaction("$\times$ ")  nobaselevels  keep(*Event ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Controls include:  tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. The baseline mean is taken in the 36 months before the transition. ///
"\end{tablenotes}") replace

* Table: TeamFracGender  TeamFracAge  TeamFracNat TeamFracOffice  TeamFracCountry 
esttab  reg14FE reg15FE reg16FE reg17FE   using "$analysis/Results/8.Team/`Label'DivSym.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE cmean N r2, labels("Controls" "Team FE" "\hline Baseline Mean" "N" "R-squared" ) )  interaction("$\times$ ")  nobaselevels  keep(*Event ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Controls include:  tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. The baseline mean is taken in the 36 months before the transition. ///
"\end{tablenotes}") replace

* ADDITIONAL CHECKS: Does it matter the timing of exit? run separately for 1,2,3 years after
********************************************************************************
	local Label FT //  PromSG75 FT 
reghdfe ShareLeaver `Label'Event `Label'DEvent  c.TenureM##c.TenureM##i.FemaleM if SpanM>1 & KEi<=12 & KEi>=-12, a(   team ) cluster(IDlseMHR)
reghdfe ShareLeaver `Label'Event `Label'DEvent  c.TenureM##c.TenureM##i.FemaleM if SpanM>1 & KEi<=24 & KEi>=-24, a(   team ) cluster(IDlseMHR)
reghdfe ShareLeaver `Label'Event `Label'DEvent  c.TenureM##c.TenureM##i.FemaleM if SpanM>1 & KEi<=36 & KEi>=-36, a(   team ) cluster(IDlseMHR)

********************************************************************************
* CROSS SECTION PRE
********************************************************************************

eststo clear
local i = 1
		local Label FT //  PromSG75
foreach y in   $perf $move $homo $div $out {
	
eststo reg`i':	reghdfe `y' Delta`Label' $cont if SpanM>1 & Year>2013 & KEi<=-6 & KEi >=-36,  cluster(IDlseMHR) a( $controls )
local lbl : variable label `y'
estadd local Controls "Yes" , replace
estadd local TeamFE "No" , replace
estadd ysumm 
local i = `i' +1

}

esttab reg1 reg2 reg3 reg4  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) ) 

esttab reg5 reg6 reg7 reg8 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) ) 

esttab  reg9 reg10 reg11 reg12  ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) ) 

esttab reg13 reg14 ,   label star(* 0.10 ** 0.05 *** 0.01) se r2 s(Controls TeamFE ymean N r2 diff1 pvalue1 diff2 pvalue2, labels("Controls" "Team FE" "Mean" "\hline N" "R-squared" "LtoH - LtoL" "p-value:" "HtoL - HtoH" "p-value:" ) ) 

********************************************************************************
* TABLES TO EXPORT 
********************************************************************************

local Label FT  // PromSG75

esttab reg1 reg2 reg3 reg4  using "$analysis/Results/8.Team/Pre`Label'PerfSym.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2 , labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" ) )  interaction("$\times$ ")  nobaselevels  keep( Delta* ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch. Controls include: function, country and year FE, manager's age group and work level, team size, tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

esttab  reg5 reg6 reg7 reg8 using "$analysis/Results/8.Team/Pre`Label'MoveSym.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2 , labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" ) )  interaction("$\times$ ")  nobaselevels  keep( Delta* ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch.  Controls include: function, country and year FE, manager's age group and work level, team size, tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

esttab reg9 reg10 reg11 reg12 reg13 using "$analysis/Results/8.Team/Pre`Label'CompSym.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2 , labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" ) )  interaction("$\times$ ")  nobaselevels  keep( Delta* ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch.  Controls include: function, country and year FE, manager's age group and work level, team size, tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

esttab reg14 reg15 reg16 reg17  using "$analysis/Results/8.Team/Pre`Label'DivSym.tex",  label star(* 0.10 ** 0.05 *** 0.01) se r2 ///
s(Controls TeamFE ymean N r2 , labels("Controls" "Team FE" "\hline Mean" "N" "R-squared" ) )  interaction("$\times$ ")  nobaselevels  keep( Delta* ) ///
nofloat nonotes postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
Notes. An observation is a team-month. Sample restricted to observations between 6 and 36 months before the manager switch.  Controls include: function, country and year FE, manager's age group and work level, team size, tenure and tenure squared of manager interacted with gender. Standard errors clustered at the manager level. ///
"\end{tablenotes}") replace

********************************************************************************
* PROFILES OF LEAVERS AND JOINERS 
********************************************************************************

eststo clear
local Label  PromSG75 // FT, PromSG75 

global charsCoef Female Age20 MBA Econ Sci Hum  NewHire Tenure5 EarlyAge  PayGrowth1yAbove1 // Age30 Age40 Age50  PayGrowth1yAbove0 

foreach y in Age30 Age40 Age50 $charsCoef $charsExitFirm $charsExitTeam $charsJoinTeam $charsChangeTeam {

eststo `y':	reghdfe `y' `Label'Event `Label'DEvent  c.TenureM##c.TenureM##i.FemaleM if SpanM>1 & Year>2013 & KEi<=36 & KEi>=-36, a(   team ) cluster(IDlseMHR)

local lbl : variable label `y'

estadd local Controls "Yes" , replace
estadd local TeamFE "Yes" , replace
estadd ysumm 

}

local Label  PromSG75 // FT, PromSG75

coefplot $charsCoef, keep(*DEvent) ci(90) xline(0 ,lpattern(solid) lcolor(black))  scheme(white_tableau)  aseq swapnames legend(off) ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span size(small)) ///
 headings(Female = "{bf:Demographics}" NewHire = "{bf:Characteristics on the job}" , labgap(0)) title("Team Composition")
graph export "$analysis/Results/8.Team/`Label'Composition.png", replace 
graph save "$analysis/Results/8.Team/`Label'Composition.gph", replace 

coefplot $charsChangeTeam , keep(*DEvent) ci(90) xline(0 ,lpattern(solid) lcolor(black))  scheme(white_tableau)  aseq swapnames legend(off) ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span size(small)) ///
 headings(F1ChangeMFemale = "{bf:Demographics}" F1ChangeMNewHire = "{bf:Characteristics on the job}" , labgap(0)) title("Team Switchers")
graph export "$analysis/Results/8.Team/`Label'ChangeTeam.png", replace 
graph save "$analysis/Results/8.Team/`Label'ChangeTeam.gph", replace 

coefplot $charsExitFirm , keep(*DEvent) ci(90) xline(0 ,lpattern(solid) lcolor(black))  scheme(white_tableau)  aseq swapnames legend(off) ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span size(small)) ///
 headings(LeaverPermFemale = "{bf:Demographics}" LeaverPermNewHire = "{bf:Characteristics on the job}" , labgap(0)) title("Firm Leavers")
graph export "$analysis/Results/8.Team/`Label'ExitFirm.png", replace 
graph save "$analysis/Results/8.Team/`Label'ExitFirm.gph", replace 

coefplot $charsJoinTeam , keep(*DEvent) ci(90) xline(0 ,lpattern(solid) lcolor(black))  scheme(white_tableau)  aseq swapnames legend(off) ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span size(small)) ///
 headings(ChangeMFemale = "{bf:Demographics}" ChangeMNewHire = "{bf:Characteristics on the job}" , labgap(0)) title("Team Joiners")
graph export "$analysis/Results/8.Team/`Label'JoinTeam.png", replace 
graph save "$analysis/Results/8.Team/`Label'JoinTeam.gph", replace 

coefplot $charsExitTeam , keep(*DEvent) ci(90) xline(0 ,lpattern(solid) lcolor(black))  scheme(white_tableau)  aseq swapnames legend(off) ///
note("Notes. An observation is a team-month. Controls include: team fixed effects, tenure and tenure squared of" "manager interacted with gender. Standard errors clustered at the manager level." "Reporting 90% confidence intervals.", span size(small)) ///
 headings(ExitTeamFemale = "{bf:Demographics}" ExitTeamNewHire = "{bf:Characteristics on the job}" , labgap(0)) title("Team Leavers")
graph export "$analysis/Results/8.Team/`Label'ExitTeam.png", replace 
graph save "$analysis/Results/8.Team/`Label'ExitTeam.gph", replace 

//////////////////////////////////////////////////////////////////////////////// 
* NEW & OLD JOB
////////////////////////////////////////////////////////////////////////////////

*use  "$managersdta/AllSnapshotMCultureMType.dta", clear 

merge m:1 Office SubFuncS StandardJob YearMonth using "$managersdta/NewOldJobs.dta" , keepusing(NewJob OldJob)
drop _merge 

*do "$analysis/DoFiles/4.Event/4.0.TWFEPrep" // only consider first event as with new did estimators 

merge m:1 StandardJob  YearMonth IDlseMHR Office  using "$managersdta/NewOldJobsManager.dta", keepusing(NewJobManager OldJobManager)
drop _merge

* other variables TransferInternalSJLLC  TransferInternalSJSameMLLC  TransferInternalSJDiffMLLC TransferInternalSJC  TransferInternalSJSameMC  TransferInternalSJDiffMC   
label var ELLPost "Post E\textsubscript{LL}"
label var ELHPost "Post E\textsubscript{LH}"
label var EHLPost "Post E\textsubscript{HL}"
label var EHHPost "Post E\textsubscript{HH}"
eststo clear 
foreach v in NewJob OldJob NewJobManager OldJobManager  {
local lbl : variable label `v'
mean `v' if IDlseMHR!=. 
mat coef=e(b)
local cmean = coef[1,1]
count if  `v' !=. & IDlseMHR!=. 
local N1 = r(N)
eststo: reghdfe `v' ELLPost ELHPost EHLPost EHHPost c.Tenure##c.Tenure c.TenureM##c.TenureM TeamSize , a( AgeBand CountryYM AgeBandM IDlseMHR IDlse) cluster(IDlseMHR)
test  ELHPost = ELLPost
estadd scalar pvalue1 = r(p)
test  EHLPost = EHHPost
estadd scalar pvalue2 = r(p)
estadd scalar cmean = `cmean'
estadd scalar N1 = `N1'
}


