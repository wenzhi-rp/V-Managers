* Analysis of TIME USE DATA 
* Weekly data over 2019 entire year, random sample of 2000 employees spanning multiple work levels, gender, age, countries and functions 

* From the calendar data, I do not know who reports to who, so I cannot track the behavior of the worker, but I can track the behavior of the manager. I can look on average how do high flighrs spend their time differently from the rest of the managers. 

* managerial talent interpretation: the results are actually consistent with manager selection rather than training: different time use behavior + accumulate experience (tenure) differently


use "$managersdta/timeuse.dta", clear 
* this data contains WL2 managers, taking the weekly annual average for each variable over 2019 


global list workweek_span  meeting_hours meeting_hours_with_manager meeting_hours_external meeting_hours_manager  working_hours_email_hours   emails_sent total_focus_hours  open_1_hour_block  multitasking_meeting_hours

bys HF2: su  $list 

foreach v in $list {
		reg `v' HF2 if WL==2, robust
}


* New codes to generate the table

use "$managersdta/timeuse.dta", clear 

label variable meeting_hours_with_manager "Meeting hours 1-1 with reportees"

generate meeting_hours_internal = meeting_hours- meeting_hours_with_manager - meeting_hours_external

label variable meeting_hours_internal "Meeting hours internal"


global list2 workweek_span  meeting_hours meeting_hours_with_manager meeting_hours_internal meeting_hours_external emails_sent total_focus_hours  open_1_hour_block  multitasking_meeting_hours

balancetable HF2 $list2 if WL==2 ///
    using "${analysis}/Results/0.New/TimeUseBalanceTable.tex", ///
    replace /// 
    pvalues varlabels vce(robust)  ///
    nolines nonumbers ///
    ctitles("Not High Flyer" "High Flyer" "Difference") ///
    prehead("\begin{tabular}{l*{3}{c}} \hline\hline ") ///
    posthead("\hline \\") ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
    "Notes. This dataset documents how high- and low-flyer managers use their time differently. The original dataset is at weekly frequency spanning over the entire 2019, and contains a random sample of 2000 employees from multiple work levels, gender, age, countries and functions. All variables are the average across all weeks in a year. The table shows the mean and standard deviations (in parentheses) for high- and low-flyer managers and p-values for the difference in means. p-valuses are calculated using robust standard errors." "\end{tablenotes}")
/* Because there is no way to identify management chain using individual identifiers, I can only compare behavior in time use between different managers (those whose work level is 2).  */
balancetable HF2 $list2 if WL==2 ///
    using "${analysis}/Results/0.New/TimeUseBalanceTable_nostars.tex", ///
    replace /// 
    pvalues varlabels vce(robust)  ///
    nolines nonumbers nostars ///
    ctitles("Not High Flyer" "High Flyer" "Difference") ///
    prehead("\begin{tabular}{l*{3}{c}} \hline\hline ") ///
    posthead("\hline \\") ///
    postfoot("\hline" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item" ///
    "Notes. This dataset documents how high- and low-flyer managers use their time differently. The original dataset is at weekly frequency spanning over the entire 2019, and contains a random sample of 2000 employees from multiple work levels, gender, age, countries and functions. Because there is no way to identify management chain using individual identifiers, I can only compare behavior in time use between different managers (those whose work level is 2). All variables are the average across all weeks in a year. The table shows the mean and standard deviations (in parentheses) for high- and low-flyer managers and p-values for the difference in means. p-valuses are calculated using robust standard errors." "\end{tablenotes}")









