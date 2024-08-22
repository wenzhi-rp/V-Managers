



*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? program 1. 
*?? for regressions that evaluate the effects of gaining a high-flyer mnager
*??   it first calculates \beta_{LtoH,s} - \beta_{LtoL,s} 
*??   and then aggregates the coefficients to the quarter level
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture program drop LH_minus_LL
program define LH_minus_LL
syntax, pre_window_len(real) post_window_len(real) outcome(string) event_prefix(string)
/*
This program takes four arguments as input.
The first one indicates the length of pre-event window.
The second one indicates the length of post-event window.
The third argument indicates the outcome variable in the regression.
The fourth argument indicates the identifier of the event.
*/
local test_pre_window_len  = mod(`pre_window_len', 3)
local test_post_window_len = mod(`post_window_len', 3)
if `test_pre_window_len'!=1 | `test_post_window_len'!=2 {
    display "Specified pre- and/or post-window lengths are not suitable for quarter aggregation."
    display "Program terminated."
    exit
}

/* 
I will take `pre_window_len'==34 and `post_window_len'==86 as an example 
    and present local values in the comments.
*/

*-- step 1. produce matrices to store the results 
local number_of_pre_quarters  = trunc(`pre_window_len'/3) + 1 // 12 
local number_of_post_quarters = trunc(`post_window_len'/3) + 1 // 29
local total_quarters          = `number_of_pre_quarters' + `number_of_post_quarters'

matrix coefficients_mat  = J(`total_quarters', 1, .)
matrix lower_bound_mat   = J(`total_quarters', 1, .)
matrix upper_bound_mat   = J(`total_quarters', 1, .)
matrix quarter_index_mat = J(`total_quarters', 1, .) 
    // all of them are 41 by 1 matrix to store the results for plotting the coefficients

*-- step 2. store those pre-event coefficients 
forvalues left_month_index = `pre_window_len'(-3)4 { 
    local quarter_index = `number_of_pre_quarters' - (`left_month_index'-1)/3 
        // 34 corresponds to 1, 31 corresponds to 2, ..., 4 corresponds to 11
    
    local middle_month_index = `left_month_index' - 1 // 33, 30, 27, ..., 3
    local right_month_index  = `left_month_index' - 2 // 32, 29, 26, ..., 2

    lincom ///
        ((`event_prefix'_LtoH_X_Pre`left_month_index' - `event_prefix'_LtoL_X_Pre`left_month_index') + ///
        (`event_prefix'_LtoH_X_Pre`middle_month_index' - `event_prefix'_LtoL_X_Pre`middle_month_index') + ///
        (`event_prefix'_LtoH_X_Pre`right_month_index' - `event_prefix'_LtoL_X_Pre`right_month_index')) / 3, level(95)
    
    matrix coefficients_mat[`quarter_index', 1]  = r(estimate)
    matrix lower_bound_mat[`quarter_index', 1]   = r(lb)
    matrix upper_bound_mat[`quarter_index', 1]   = r(ub)
    matrix quarter_index_mat[`quarter_index', 1] = -(`left_month_index'-1)/3 - 1 
        // 34 corresponds to -12, 31 corresponds to -11, ..., 4 corresponds to -2
}

*-- step 3. store the -1 period coefficients 
matrix coefficients_mat[`number_of_pre_quarters', 1]  = 0
matrix lower_bound_mat[`number_of_pre_quarters', 1]   = 0
matrix upper_bound_mat[`number_of_pre_quarters', 1]   = 0
matrix quarter_index_mat[`number_of_pre_quarters', 1] = -1 

*-- step 4. store the post-event coefficients 
* reset these macros to avoid contamination from the pre-event coefficients
local right_month_index  = 0 
local middle_month_index = 0 
local left_month_index   = 0
forvalues right_month_index = 2(3)`post_window_len' { 
    local quarter_index = (`right_month_index'-2)/3 + `number_of_pre_quarters' + 1
        // 2 corresponds to 13, 5 corresponds to 14, ..., 86 corresponds to 41
    
    local middle_month_index = `right_month_index' - 1 // 1, 4, 7, ..., 85
    local left_month_index   = `right_month_index' - 2 // 0, 3, 6, ..., 84 

    lincom ///
        ((`event_prefix'_LtoH_X_Post`right_month_index' - `event_prefix'_LtoL_X_Post`right_month_index') + ///
        (`event_prefix'_LtoH_X_Post`middle_month_index' - `event_prefix'_LtoL_X_Post`middle_month_index') + ///
        (`event_prefix'_LtoH_X_Post`left_month_index' - `event_prefix'_LtoL_X_Post`left_month_index')) / 3, level(95)
    
    matrix coefficients_mat[`quarter_index', 1]  = r(estimate)
    matrix lower_bound_mat[`quarter_index', 1]   = r(lb)
    matrix upper_bound_mat[`quarter_index', 1]   = r(ub)
    matrix quarter_index_mat[`quarter_index', 1] = (`right_month_index'-2)/3 
        // 2 corresponds to 0, 5 corresponds to 1, ..., 86 corresponds to 28 
}

*-- step 5. save the results 

capture drop quarter_index coefficients lower_bound upper_bound
matrix results = quarter_index_mat, coefficients_mat, lower_bound_mat, upper_bound_mat
matrix colnames results = quarter_index coefficients lower_bound upper_bound
svmat results, names(col)

end 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? program 2. 
*?? for regressions that evaluate the effects of gaining a high-flyer mnager
*??   it first calculates \beta_{LtoH,s} - \beta_{LtoL,s} 
*??   and then aggregates the coefficients to the quarter level
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture program drop LH_minus_LL_pretrend
program define LH_minus_LL_pretrend

syntax, pre_window_len(real) outcome(string) event_prefix(string)

local t = `pre_window_len'

macro drop jointF
local jointF "`event_prefix'_LtoL_X_Pre`t' - `event_prefix'_LtoH_X_Pre`t'" 

forvalues i = `t'(-1)2 {
	local jointF "`jointF' + `event_prefix'_LtoL_X_Pre`i' - `event_prefix'_LtoH_X_Pre`i'"
}

    //!! thus, the macro jointF contains an expression to calculate the joint siginificant of all pre-event periods 

capture drop jointF
lincom `jointF'
generate jointF =  (r(p)) 
    //!! the p-value is stored as a new variable

end 