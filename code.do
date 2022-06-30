clear all

********************************************************************************

import excel "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Price Index.xlsx", sheet("Data") cellrange(A3:C63)
ren (A B C) (Year cpi wpi)
gen year = real(Year)
drop Year
drop if year < 2000
order year, first
save "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Price Index.dta", replace

********************************************************************************

cd "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/Chemicals & chemical products"

import excel "Chemicals & chemical products.xlsx", sheet("Sheet2") firstrow clear
reshape long output_ input1_ input2_ input3_ input4_ input5_ input6_ input7_, i(CompanyName) j(year)
sort year CompanyName
ren (input1_ input2_ input3_ output_ input4_ input5_ input6_ input7_) (input1 input2 input3 output input4 input5 input6 input7)

encode CompanyName, gen(x)
ren CompanyName CompanyName_
ren x CompanyName

order CompanyName year output, first
xtset CompanyName year, yearly

foreach var of varlist output input1 input2 input3 input4 input5 input6 input7{
  *replace `var' = . if `var' == 0
}

misstable summarize output

drop if output == .
drop CompanyName_
misstable summarize

*egen min_val = min(input4)
*replace input4 = min_val if input4 == .
*drop min_val

/*
foreach var of varlist input1 input2 input3 input4 input6 input7{
  egen mean_val = mean(`var')
  replace `var' = mean_val if `var' == .
  drop mean_val
}
*/

sum
gsort year CompanyName
foreach var of varlist input1 input2 input3 input5 input6 input7{
  replace `var' = . if `var' < 0
  by year: egen min_`var' = min(`var')
}
replace output = . if output < 0

mi set mlong
mi register imputed output input1 input2 input3 input4 input5 input6 input7
mi impute mvn output input1 input2 input3 input4 input5 input6 input7 = year CompanyName, add(10) rseed (53421)

forvalues i = 1/9{
  drop if _mi_m == `i'
}

drop if _mi_miss == 1
gsort CompanyName year
replace _mi_m = 0 if _mi_m == 10
replace _mi_miss = 0 if _mi_miss == .
mi unset

drop mi_m mi_id mi_miss

gsort year CompanyName
by year: egen mean_out = mean(output)

foreach var of varlist input1 input2 input3 input5 input6 input7{
  by year: egen mean_`var' = mean(`var')
  replace `var' = min_`var' if `var' <= 0 & output < mean_out
  replace `var' = mean_`var' if `var' <= 0
  drop mean_`var' min_`var'
}
drop mean_out
sum

merge m:1 year using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Price Index.dta"
drop _merge
foreach var of varlist output input1 input2 input4 input5 input6{
  gen `var'_ = (`var'/wpi)*100
  drop `var'
  ren `var'_ `var'
}
gen input3_ = (input3/cpi)*100
gen input7_ = (input7/cpi)*100
drop input3 input7
ren (input3_ input7_) (input3 input7)

misstable summarize
xtset CompanyName year, yearly

tab year

by CompanyName: gen keep_val = 1 if F1.year == 2001 & F2.year == 2002 & F3.year == 2003 & F4.year == 2004 & F5.year == 2005 & F6.year == 2006 & F7.year == 2007 & F8.year == 2008 & F9.year == 2009 & F10.year == 2010 & F11.year == 2011 & F12.year == 2012 & F13.year == 2013 & F14.year == 2014 & F15.year == 2015 & F16.year == 2016 & F17.year == 2017 & F18.year == 2018 & F19.year == 2019 & F20.year == 2020
by CompanyName: replace keep_val = 1 if L1.keep_val == 1 | L2.keep_val == 1 | L3.keep_val == 1 | L4.keep_val == 1 | L5.keep_val == 1 | L6.keep_val == 1 | L7.keep_val == 1 | L8.keep_val == 1 | L9.keep_val == 1 | L10.keep_val == 1 | L11.keep_val == 1 | L12.keep_val == 1 | L13.keep_val == 1 | L14.keep_val == 1 | L15.keep_val == 1 | L16.keep_val == 1 | L17.keep_val == 1 | L18.keep_val == 1 | L19.keep_val == 1 | L20.keep_val == 1
export delimited output input1 input2 input3 input4 input5 input6 input7 using "99" if keep_val == 1, novarnames replace
export excel CompanyName year output input1 input2 input3 input4 input5 input6 input7 cpi wpi using "Chemicals & chemical products_" if keep_val == 1, firstrow(variables) replace
qui tab keep_val year if year == 2000
scalar n = r(N)

gsort year CompanyName
by year: egen tot = sum(output)
by year: egen tot1 = sum(output) if keep_val == 1

putexcel A1=("Year") using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
putexcel B1=("Chemicals & chemical products") using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
putexcel A24=("Observations") using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
putexcel B24=(n) using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
forvalues i = 2/22{
 scalar j = `i' + 1998
 qui sum tot if year == j
 scalar mean1 = r(mean)
 qui sum tot1 if year == j
 scalar mean2 = r(mean)
 scalar prop = (mean2/mean1)*100
 di ""
 di "Year " j ": Number of Observations " n
 di "Sales Proportion : " prop " %"
 putexcel A`i'=(j) using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
 putexcel B`i'=(prop) using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
}

drop if keep_val == .
xtset CompanyName year, yearly
reg output input1 input2 input3 input4 input5 input6 input7
foreach var of varlist output input1 input2 input3 input4 input5 input6 input7{
 gen l_`var' = log(`var')
}
reg l_output l_input1 l_input2 l_input3 l_input4 l_input5 l_input6 l_input7
drop keep_val tot tot1

********************************************************************************

cd "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/Construction materials"

import excel "Construction materials.xlsx", sheet("Sheet1") firstrow clear
reshape long input1_ input2_ input3_ output_ input4_ input5_ input6_ input7_, i(CompanyName) j(year)
sort year CompanyName
ren (input1_ input2_ input3_ output_ input4_ input5_ input6_ input7_) (input1 input2 input3 output input4 input5 input6 input7)

encode CompanyName, gen(x)
ren CompanyName CompanyName_
ren x CompanyName

order CompanyName year output, first
xtset CompanyName year, yearly

foreach var of varlist output input1 input2 input3 input4 input5 input6 input7{
  replace `var' = . if `var' == 0
}

misstable summarize output

drop if output == .
drop CompanyName_
misstable summarize

egen min_val = min(input5)
replace input5 = min_val if input5 == .
drop min_val

/*
foreach var of varlist input1 input2 input3 input4 input6 input7{
  egen mean_val = mean(`var')
  replace `var' = mean_val if `var' == .
  drop mean_val
}
*/

sum
gsort year CompanyName
foreach var of varlist input1 input2 input3 input4 input6 input7{
  by year: egen min_`var' = min(`var')
}

mi set mlong
mi register imputed output input1 input2 input3 input4 input5 input6 input7
mi impute mvn output input1 input2 input3 input4 input5 input6 input7 = year CompanyName, add(10) rseed (53421)

forvalues i = 1/9{
  drop if _mi_m == `i'
}

drop if _mi_miss == 1
gsort CompanyName year
replace _mi_m = 0 if _mi_m == 10
replace _mi_miss = 0 if _mi_miss == .
mi unset

drop mi_m mi_id mi_miss

gsort year CompanyName
by year: egen mean_out = mean(output)

foreach var of varlist input1 input2 input3 input4 input6 input7{
  by year: egen mean_`var' = mean(`var')
  replace `var' = min_`var' if `var' <= 0 & output < mean_out
  replace `var' = mean_`var' if `var' <= 0
  drop mean_`var' min_`var'
}
drop mean_out
sum

merge m:1 year using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Price Index.dta"
drop _merge
foreach var of varlist output input1 input2 input4 input5 input6{
  gen `var'_ = (`var'/wpi)*100
  drop `var'
  ren `var'_ `var'
}
gen input3_ = (input3/cpi)*100
gen input7_ = (input7/cpi)*100
drop input3 input7
ren (input3_ input7_) (input3 input7)

misstable summarize
xtset CompanyName year, yearly

tab year

by CompanyName: gen keep_val = 1 if F1.year == 2001 & F2.year == 2002 & F3.year == 2003 & F4.year == 2004 & F5.year == 2005 & F6.year == 2006 & F7.year == 2007 & F8.year == 2008 & F9.year == 2009 & F10.year == 2010 & F11.year == 2011 & F12.year == 2012 & F13.year == 2013 & F14.year == 2014 & F15.year == 2015 & F16.year == 2016 & F17.year == 2017 & F18.year == 2018 & F19.year == 2019 & F20.year == 2020
by CompanyName: replace keep_val = 1 if L1.keep_val == 1 | L2.keep_val == 1 | L3.keep_val == 1 | L4.keep_val == 1 | L5.keep_val == 1 | L6.keep_val == 1 | L7.keep_val == 1 | L8.keep_val == 1 | L9.keep_val == 1 | L10.keep_val == 1 | L11.keep_val == 1 | L12.keep_val == 1 | L13.keep_val == 1 | L14.keep_val == 1 | L15.keep_val == 1 | L16.keep_val == 1 | L17.keep_val == 1 | L18.keep_val == 1 | L19.keep_val == 1 | L20.keep_val == 1
export delimited output input1 input2 input3 input4 input5 input6 input7 using "99" if keep_val == 1, novarnames replace
export excel CompanyName year output input1 input2 input3 input4 input5 input6 input7 cpi wpi using "Construction materials_" if keep_val == 1, firstrow(variables) replace
qui tab keep_val year if year == 2000
scalar n = r(N)

gsort year CompanyName
by year: egen tot = sum(output)
by year: egen tot1 = sum(output) if keep_val == 1

putexcel C1=("Construction materials") using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
putexcel C24=(n) using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
forvalues i = 2/22{
 scalar j = `i' + 1998
 qui sum tot if year == j
 scalar mean1 = r(mean)
 qui sum tot1 if year == j
 scalar mean2 = r(mean)
 scalar prop = (mean2/mean1)*100
 di ""
 di "Year " j ": Number of Observations " n
 di "Sales Proportion : " prop " %"
 putexcel C`i'=(prop) using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
}

drop if keep_val == .
xtset CompanyName year, yearly
reg output input1 input2 input3 input4 input5 input6 input7
foreach var of varlist output input1 input2 input3 input4 input5 input6 input7{
 gen l_`var' = log(`var')
}
reg l_output l_input1 l_input2 l_input3 l_input4 l_input5 l_input6 l_input7
drop keep_val tot tot1

********************************************************************************

cd "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/Consumer goods"

import excel "Consumer goods.xlsx", sheet("Sheet1") firstrow clear
reshape long input1_ input2_ input3_ output_ input4_ input5_ input6_ input7_, i(CompanyName) j(year)
sort year CompanyName
ren (input1_ input2_ input3_ output_ input4_ input5_ input6_ input7_) (input1 input2 input3 output input4 input5 input6 input7)

encode CompanyName, gen(x)
ren CompanyName CompanyName_
ren x CompanyName

order CompanyName year output, first
xtset CompanyName year, yearly

foreach var of varlist output input1 input2 input3 input4 input5 input6 input7{
  replace `var' = . if `var' == 0
}

misstable summarize output

drop if output == .
drop CompanyName_
misstable summarize

egen min_val = min(input5)
replace input5 = min_val if input5 == .
drop min_val

/*
foreach var of varlist input1 input2 input3 input4 input6 input7{
  egen mean_val = mean(`var')
  replace `var' = mean_val if `var' == .
  drop mean_val
}
*/

sum
gsort year CompanyName
foreach var of varlist input1 input2 input3 input4 input6 input7{
  by year: egen min_`var' = min(`var')
}

mi set mlong
mi register imputed output input1 input2 input3 input4 input5 input6 input7
mi impute mvn output input1 input2 input3 input4 input5 input6 input7 = year CompanyName, add(10) rseed (53421)

forvalues i = 1/9{
  drop if _mi_m == `i'
}

drop if _mi_miss == 1
gsort CompanyName year
replace _mi_m = 0 if _mi_m == 10
replace _mi_miss = 0 if _mi_miss == .
mi unset

drop mi_m mi_id mi_miss

gsort year CompanyName
by year: egen mean_out = mean(output)

foreach var of varlist input1 input2 input3 input4 input6 input7{
  by year: egen mean_`var' = mean(`var')
  replace `var' = min_`var' if `var' <= 0 & output < mean_out
  replace `var' = mean_`var' if `var' <= 0
  drop mean_`var' min_`var'
}
drop mean_out
sum

merge m:1 year using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Price Index.dta"
drop _merge
foreach var of varlist output input1 input2 input4 input5 input6{
  gen `var'_ = (`var'/wpi)*100
  drop `var'
  ren `var'_ `var'
}
gen input3_ = (input3/cpi)*100
gen input7_ = (input7/cpi)*100
drop input3 input7
ren (input3_ input7_) (input3 input7)

misstable summarize
xtset CompanyName year, yearly

tab year

by CompanyName: gen keep_val = 1 if F1.year == 2001 & F2.year == 2002 & F3.year == 2003 & F4.year == 2004 & F5.year == 2005 & F6.year == 2006 & F7.year == 2007 & F8.year == 2008 & F9.year == 2009 & F10.year == 2010 & F11.year == 2011 & F12.year == 2012 & F13.year == 2013 & F14.year == 2014 & F15.year == 2015 & F16.year == 2016 & F17.year == 2017 & F18.year == 2018 & F19.year == 2019 & F20.year == 2020
by CompanyName: replace keep_val = 1 if L1.keep_val == 1 | L2.keep_val == 1 | L3.keep_val == 1 | L4.keep_val == 1 | L5.keep_val == 1 | L6.keep_val == 1 | L7.keep_val == 1 | L8.keep_val == 1 | L9.keep_val == 1 | L10.keep_val == 1 | L11.keep_val == 1 | L12.keep_val == 1 | L13.keep_val == 1 | L14.keep_val == 1 | L15.keep_val == 1 | L16.keep_val == 1 | L17.keep_val == 1 | L18.keep_val == 1 | L19.keep_val == 1 | L20.keep_val == 1
export delimited output input1 input2 input3 input4 input5 input6 input7 using "99" if keep_val == 1, novarnames replace
export excel CompanyName year output input1 input2 input3 input4 input5 input6 input7 cpi wpi using "Consumer goods_" if keep_val == 1, firstrow(variables) replace
qui tab keep_val year if year == 2000
scalar n = r(N)

gsort year CompanyName
by year: egen tot = sum(output)
by year: egen tot1 = sum(output) if keep_val == 1

putexcel D1=("Consumer goods") using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
putexcel D24=(n) using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
forvalues i = 2/22{
 scalar j = `i' + 1998
 qui sum tot if year == j
 scalar mean1 = r(mean)
 qui sum tot1 if year == j
 scalar mean2 = r(mean)
 scalar prop = (mean2/mean1)*100
 di ""
 di "Year " j ": Number of Observations " n
 di "Sales Proportion : " prop " %"
 putexcel D`i'=(prop) using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
}

drop if keep_val == .
xtset CompanyName year, yearly
reg output input1 input2 input3 input4 input5 input6 input7
foreach var of varlist output input1 input2 input3 input4 input5 input6 input7{
 gen l_`var' = log(`var')
}
reg l_output l_input1 l_input2 l_input3 l_input4 l_input5 l_input6 l_input7
drop keep_val tot tot1

********************************************************************************

cd "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/Food & agro-based products"

import excel "Food & agro-based products.xlsx", sheet("Sheet1") firstrow clear
reshape long input1_ input2_ input3_ output_ input4_ input5_ input6_ input7_, i(CompanyName) j(year)
sort year CompanyName
ren (input1_ input2_ input3_ output_ input4_ input5_ input6_ input7_) (input1 input2 input3 output input4 input5 input6 input7)

encode CompanyName, gen(x)
ren CompanyName CompanyName_
ren x CompanyName

order CompanyName year output, first
xtset CompanyName year, yearly

foreach var of varlist output input1 input2 input3 input4 input5 input6 input7{
  replace `var' = . if `var' == 0
}

misstable summarize output

drop if output == .
drop CompanyName_
misstable summarize

egen min_val = min(input5)
replace input5 = min_val if input5 == .
drop min_val

/*
foreach var of varlist input1 input2 input3 input4 input6 input7{
  egen mean_val = mean(`var')
  replace `var' = mean_val if `var' == .
  drop mean_val
}
*/

sum
gsort year CompanyName
foreach var of varlist input1 input2 input3 input4 input6 input7{
  by year: egen min_`var' = min(`var')
}

mi set mlong
mi register imputed output input1 input2 input3 input4 input5 input6 input7
mi impute mvn output input1 input2 input3 input4 input5 input6 input7 = year CompanyName, add(10) rseed (53421)

forvalues i = 1/9{
  drop if _mi_m == `i'
}

drop if _mi_miss == 1
gsort CompanyName year
replace _mi_m = 0 if _mi_m == 10
replace _mi_miss = 0 if _mi_miss == .
mi unset

drop mi_m mi_id mi_miss

gsort year CompanyName
by year: egen mean_out = mean(output)

foreach var of varlist input1 input2 input3 input4 input6 input7{
  by year: egen mean_`var' = mean(`var')
  replace `var' = min_`var' if `var' <= 0 & output < mean_out
  replace `var' = mean_`var' if `var' <= 0
  drop mean_`var' min_`var'
}
drop mean_out
sum

merge m:1 year using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Price Index.dta"
drop _merge
foreach var of varlist output input1 input2 input4 input5 input6{
  gen `var'_ = (`var'/wpi)*100
  drop `var'
  ren `var'_ `var'
}
gen input3_ = (input3/cpi)*100
gen input7_ = (input7/cpi)*100
drop input3 input7
ren (input3_ input7_) (input3 input7)

misstable summarize
xtset CompanyName year, yearly

tab year

by CompanyName: gen keep_val = 1 if F1.year == 2001 & F2.year == 2002 & F3.year == 2003 & F4.year == 2004 & F5.year == 2005 & F6.year == 2006 & F7.year == 2007 & F8.year == 2008 & F9.year == 2009 & F10.year == 2010 & F11.year == 2011 & F12.year == 2012 & F13.year == 2013 & F14.year == 2014 & F15.year == 2015 & F16.year == 2016 & F17.year == 2017 & F18.year == 2018 & F19.year == 2019 & F20.year == 2020
by CompanyName: replace keep_val = 1 if L1.keep_val == 1 | L2.keep_val == 1 | L3.keep_val == 1 | L4.keep_val == 1 | L5.keep_val == 1 | L6.keep_val == 1 | L7.keep_val == 1 | L8.keep_val == 1 | L9.keep_val == 1 | L10.keep_val == 1 | L11.keep_val == 1 | L12.keep_val == 1 | L13.keep_val == 1 | L14.keep_val == 1 | L15.keep_val == 1 | L16.keep_val == 1 | L17.keep_val == 1 | L18.keep_val == 1 | L19.keep_val == 1 | L20.keep_val == 1
export delimited output input1 input2 input3 input4 input5 input6 input7 using "99" if keep_val == 1, novarnames replace
export excel CompanyName year output input1 input2 input3 input4 input5 input6 input7 cpi wpi using "Food & agro-based products_" if keep_val == 1, firstrow(variables) replace
qui tab keep_val year if year == 2000
scalar n = r(N)

gsort year CompanyName
by year: egen tot = sum(output)
by year: egen tot1 = sum(output) if keep_val == 1

putexcel E1=("Food & agro-based products") using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
putexcel E24=(n) using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
forvalues i = 2/22{
 scalar j = `i' + 1998
 qui sum tot if year == j
 scalar mean1 = r(mean)
 qui sum tot1 if year == j
 scalar mean2 = r(mean)
 scalar prop = (mean2/mean1)*100
 di ""
 di "Year " j ": Number of Observations " n
 di "Sales Proportion : " prop " %"
 putexcel E`i'=(prop) using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
}

drop if keep_val == .
xtset CompanyName year, yearly
reg output input1 input2 input3 input4 input5 input6 input7
foreach var of varlist output input1 input2 input3 input4 input5 input6 input7{
 gen l_`var' = log(`var')
}
reg l_output l_input1 l_input2 l_input3 l_input4 l_input5 l_input6 l_input7
drop keep_val tot tot1

********************************************************************************

cd "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/Machinery"

import excel "Machinery.xlsx", sheet("Sheet1") firstrow clear
reshape long input1_ input2_ input3_ output_ input4_ input5_ input6_ input7_, i(CompanyName) j(year)
sort year CompanyName
ren (input1_ input2_ input3_ output_ input4_ input5_ input6_ input7_) (input1 input2 input3 output input4 input5 input6 input7)

encode CompanyName, gen(x)
ren CompanyName CompanyName_
ren x CompanyName

order CompanyName year output, first
xtset CompanyName year, yearly

foreach var of varlist output input1 input2 input3 input4 input5 input6 input7{
  replace `var' = . if `var' == 0
}

misstable summarize output

drop if output == .
drop CompanyName_
misstable summarize

egen min_val = min(input5)
replace input5 = min_val if input5 == .
drop min_val

/*
foreach var of varlist input1 input2 input3 input4 input6 input7{
  egen mean_val = mean(`var')
  replace `var' = mean_val if `var' == .
  drop mean_val
}
*/

sum
gsort year CompanyName
foreach var of varlist input1 input2 input3 input4 input6 input7{
  by year: egen min_`var' = min(`var')
}

mi set mlong
mi register imputed output input1 input2 input3 input4 input5 input6 input7
mi impute mvn output input1 input2 input3 input4 input5 input6 input7 = year CompanyName, add(10) rseed (53421)

forvalues i = 1/9{
  drop if _mi_m == `i'
}

drop if _mi_miss == 1
gsort CompanyName year
replace _mi_m = 0 if _mi_m == 10
replace _mi_miss = 0 if _mi_miss == .
mi unset

drop mi_m mi_id mi_miss

gsort year CompanyName
by year: egen mean_out = mean(output)

foreach var of varlist input1 input2 input3 input4 input6 input7{
  by year: egen mean_`var' = mean(`var')
  replace `var' = min_`var' if `var' <= 0 & output < mean_out
  replace `var' = mean_`var' if `var' <= 0
  drop mean_`var' min_`var'
}
drop mean_out
sum

merge m:1 year using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Price Index.dta"
drop _merge
foreach var of varlist output input1 input2 input4 input5 input6{
  gen `var'_ = (`var'/wpi)*100
  drop `var'
  ren `var'_ `var'
}
gen input3_ = (input3/cpi)*100
gen input7_ = (input7/cpi)*100
drop input3 input7
ren (input3_ input7_) (input3 input7)

misstable summarize
xtset CompanyName year, yearly

tab year

by CompanyName: gen keep_val = 1 if F1.year == 2001 & F2.year == 2002 & F3.year == 2003 & F4.year == 2004 & F5.year == 2005 & F6.year == 2006 & F7.year == 2007 & F8.year == 2008 & F9.year == 2009 & F10.year == 2010 & F11.year == 2011 & F12.year == 2012 & F13.year == 2013 & F14.year == 2014 & F15.year == 2015 & F16.year == 2016 & F17.year == 2017 & F18.year == 2018 & F19.year == 2019 & F20.year == 2020
by CompanyName: replace keep_val = 1 if L1.keep_val == 1 | L2.keep_val == 1 | L3.keep_val == 1 | L4.keep_val == 1 | L5.keep_val == 1 | L6.keep_val == 1 | L7.keep_val == 1 | L8.keep_val == 1 | L9.keep_val == 1 | L10.keep_val == 1 | L11.keep_val == 1 | L12.keep_val == 1 | L13.keep_val == 1 | L14.keep_val == 1 | L15.keep_val == 1 | L16.keep_val == 1 | L17.keep_val == 1 | L18.keep_val == 1 | L19.keep_val == 1 | L20.keep_val == 1
export delimited output input1 input2 input3 input4 input5 input6 input7 using "99" if keep_val == 1, novarnames replace
export excel CompanyName year output input1 input2 input3 input4 input5 input6 input7 cpi wpi using "Machinery_" if keep_val == 1, firstrow(variables) replace
qui tab keep_val year if year == 2000
scalar n = r(N)

gsort year CompanyName
by year: egen tot = sum(output)
by year: egen tot1 = sum(output) if keep_val == 1

putexcel F1=("Machinery") using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
putexcel F24=(n) using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
forvalues i = 2/22{
 scalar j = `i' + 1998
 qui sum tot if year == j
 scalar mean1 = r(mean)
 qui sum tot1 if year == j
 scalar mean2 = r(mean)
 scalar prop = (mean2/mean1)*100
 di ""
 di "Year " j ": Number of Observations " n
 di "Sales Proportion : " prop " %"
 putexcel F`i'=(prop) using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
}

drop if keep_val == .
xtset CompanyName year, yearly
reg output input1 input2 input3 input4 input5 input6 input7
foreach var of varlist output input1 input2 input3 input4 input5 input6 input7{
 gen l_`var' = log(`var')
}
reg l_output l_input1 l_input2 l_input3 l_input4 l_input5 l_input6 l_input7
drop keep_val tot tot1

********************************************************************************


cd "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/Metals & metal products"

import excel "Metals & metal products.xlsx", sheet("Sheet1") firstrow clear
reshape long input1_ input2_ input3_ output_ input4_ input5_ input6_ input7_, i(CompanyName) j(year)
sort year CompanyName
ren (input1_ input2_ input3_ output_ input4_ input5_ input6_ input7_) (input1 input2 input3 output input4 input5 input6 input7)

encode CompanyName, gen(x)
ren CompanyName CompanyName_
ren x CompanyName

order CompanyName year output, first
xtset CompanyName year, yearly

foreach var of varlist output input1 input2 input3 input4 input5 input6 input7{
  replace `var' = . if `var' == 0
}

misstable summarize output

drop if output == .
drop CompanyName_
misstable summarize

egen min_val = min(input5)
replace input5 = min_val if input5 == .
drop min_val

/*
foreach var of varlist input1 input2 input3 input4 input6 input7{
  egen mean_val = mean(`var')
  replace `var' = mean_val if `var' == .
  drop mean_val
}
*/

sum
gsort year CompanyName
foreach var of varlist input1 input2 input3 input4 input6 input7{
  by year: egen min_`var' = min(`var')
}

mi set mlong
mi register imputed output input1 input2 input3 input4 input5 input6 input7
mi impute mvn output input1 input2 input3 input4 input5 input6 input7 = year CompanyName, add(10) rseed (53421)

forvalues i = 1/9{
  drop if _mi_m == `i'
}

drop if _mi_miss == 1
gsort CompanyName year
replace _mi_m = 0 if _mi_m == 10
replace _mi_miss = 0 if _mi_miss == .
mi unset

drop mi_m mi_id mi_miss

gsort year CompanyName
by year: egen mean_out = mean(output)

foreach var of varlist input1 input2 input3 input4 input6 input7{
  by year: egen mean_`var' = mean(`var')
  replace `var' = min_`var' if `var' <= 0 & output < mean_out
  replace `var' = mean_`var' if `var' <= 0
  drop mean_`var' min_`var'
}
drop mean_out
sum

merge m:1 year using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Price Index.dta"
drop _merge
foreach var of varlist output input1 input2 input4 input5 input6{
  gen `var'_ = (`var'/wpi)*100
  drop `var'
  ren `var'_ `var'
}
gen input3_ = (input3/cpi)*100
gen input7_ = (input7/cpi)*100
drop input3 input7
ren (input3_ input7_) (input3 input7)

misstable summarize
xtset CompanyName year, yearly

tab year

by CompanyName: gen keep_val = 1 if F1.year == 2001 & F2.year == 2002 & F3.year == 2003 & F4.year == 2004 & F5.year == 2005 & F6.year == 2006 & F7.year == 2007 & F8.year == 2008 & F9.year == 2009 & F10.year == 2010 & F11.year == 2011 & F12.year == 2012 & F13.year == 2013 & F14.year == 2014 & F15.year == 2015 & F16.year == 2016 & F17.year == 2017 & F18.year == 2018 & F19.year == 2019 & F20.year == 2020
by CompanyName: replace keep_val = 1 if L1.keep_val == 1 | L2.keep_val == 1 | L3.keep_val == 1 | L4.keep_val == 1 | L5.keep_val == 1 | L6.keep_val == 1 | L7.keep_val == 1 | L8.keep_val == 1 | L9.keep_val == 1 | L10.keep_val == 1 | L11.keep_val == 1 | L12.keep_val == 1 | L13.keep_val == 1 | L14.keep_val == 1 | L15.keep_val == 1 | L16.keep_val == 1 | L17.keep_val == 1 | L18.keep_val == 1 | L19.keep_val == 1 | L20.keep_val == 1
export delimited output input1 input2 input3 input4 input5 input6 input7 using "99" if keep_val == 1, novarnames replace
export excel CompanyName year output input1 input2 input3 input4 input5 input6 input7 cpi wpi using "Metals & metal products_" if keep_val == 1, firstrow(variables) replace
qui tab keep_val year if year == 2000
scalar n = r(N)

gsort year CompanyName
by year: egen tot = sum(output)
by year: egen tot1 = sum(output) if keep_val == 1

putexcel G1=("Metals & metal products") using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
putexcel G24=(n) using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
forvalues i = 2/22{
 scalar j = `i' + 1998
 qui sum tot if year == j
 scalar mean1 = r(mean)
 qui sum tot1 if year == j
 scalar mean2 = r(mean)
 scalar prop = (mean2/mean1)*100
 di ""
 di "Year " j ": Number of Observations " n
 di "Sales Proportion : " prop " %"
 putexcel G`i'=(prop) using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
}

drop if keep_val == .
xtset CompanyName year, yearly
reg output input1 input2 input3 input4 input5 input6 input7
foreach var of varlist output input1 input2 input3 input4 input5 input6 input7{
 gen l_`var' = log(`var')
}
reg l_output l_input1 l_input2 l_input3 l_input4 l_input5 l_input6 l_input7
drop keep_val tot tot1

********************************************************************************


cd "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/Textiles"

import excel "Textiles.xlsx", sheet("Sheet1") firstrow clear
reshape long input1_ input2_ input3_ output_ input4_ input5_ input6_ input7_, i(CompanyName) j(year)
sort year CompanyName
ren (input1_ input2_ input3_ output_ input4_ input5_ input6_ input7_) (input1 input2 input3 output input4 input5 input6 input7)

encode CompanyName, gen(x)
ren CompanyName CompanyName_
ren x CompanyName

order CompanyName year output, first
xtset CompanyName year, yearly

foreach var of varlist output input1 input2 input3 input4 input5 input6 input7{
  replace `var' = . if `var' == 0
}

misstable summarize output

drop if output == .
drop CompanyName_
misstable summarize

egen min_val = min(input5)
replace input5 = min_val if input5 == .
drop min_val

/*
foreach var of varlist input1 input2 input3 input4 input6 input7{
  egen mean_val = mean(`var')
  replace `var' = mean_val if `var' == .
  drop mean_val
}
*/

sum
gsort year CompanyName
foreach var of varlist input1 input2 input3 input4 input6 input7{
  by year: egen min_`var' = min(`var')
}

mi set mlong
mi register imputed output input1 input2 input3 input4 input5 input6 input7
mi impute mvn output input1 input2 input3 input4 input5 input6 input7 = year CompanyName, add(10) rseed (53421)

forvalues i = 1/9{
  drop if _mi_m == `i'
}

drop if _mi_miss == 1
gsort CompanyName year
replace _mi_m = 0 if _mi_m == 10
replace _mi_miss = 0 if _mi_miss == .
mi unset

drop mi_m mi_id mi_miss

gsort year CompanyName
by year: egen mean_out = mean(output)

foreach var of varlist input1 input2 input3 input4 input6 input7{
  by year: egen mean_`var' = mean(`var')
  replace `var' = min_`var' if `var' <= 0 & output < mean_out
  replace `var' = mean_`var' if `var' <= 0
  drop mean_`var' min_`var'
}
drop mean_out
sum

merge m:1 year using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Price Index.dta"
drop _merge
foreach var of varlist output input1 input2 input4 input5 input6{
  gen `var'_ = (`var'/wpi)*100
  drop `var'
  ren `var'_ `var'
}
gen input3_ = (input3/cpi)*100
gen input7_ = (input7/cpi)*100
drop input3 input7
ren (input3_ input7_) (input3 input7)

misstable summarize
xtset CompanyName year, yearly

tab year

by CompanyName: gen keep_val = 1 if F1.year == 2001 & F2.year == 2002 & F3.year == 2003 & F4.year == 2004 & F5.year == 2005 & F6.year == 2006 & F7.year == 2007 & F8.year == 2008 & F9.year == 2009 & F10.year == 2010 & F11.year == 2011 & F12.year == 2012 & F13.year == 2013 & F14.year == 2014 & F15.year == 2015 & F16.year == 2016 & F17.year == 2017 & F18.year == 2018 & F19.year == 2019 & F20.year == 2020
by CompanyName: replace keep_val = 1 if L1.keep_val == 1 | L2.keep_val == 1 | L3.keep_val == 1 | L4.keep_val == 1 | L5.keep_val == 1 | L6.keep_val == 1 | L7.keep_val == 1 | L8.keep_val == 1 | L9.keep_val == 1 | L10.keep_val == 1 | L11.keep_val == 1 | L12.keep_val == 1 | L13.keep_val == 1 | L14.keep_val == 1 | L15.keep_val == 1 | L16.keep_val == 1 | L17.keep_val == 1 | L18.keep_val == 1 | L19.keep_val == 1 | L20.keep_val == 1
export delimited output input1 input2 input3 input4 input5 input6 input7 using "99" if keep_val == 1, novarnames replace
export excel CompanyName year output input1 input2 input3 input4 input5 input6 input7 cpi wpi using "Textiles_" if keep_val == 1, firstrow(variables) replace
qui tab keep_val year if year == 2000
scalar n = r(N)

gsort year CompanyName
by year: egen tot = sum(output)
by year: egen tot1 = sum(output) if keep_val == 1

putexcel H1=("Textiles") using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
putexcel H24=(n) using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
forvalues i = 2/22{
 scalar j = `i' + 1998
 qui sum tot if year == j
 scalar mean1 = r(mean)
 qui sum tot1 if year == j
 scalar mean2 = r(mean)
 scalar prop = (mean2/mean1)*100
 di ""
 di "Year " j ": Number of Observations " n
 di "Sales Proportion : " prop " %"
 putexcel H`i'=(prop) using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
}

drop if keep_val == .
xtset CompanyName year, yearly
reg output input1 input2 input3 input4 input5 input6 input7
foreach var of varlist output input1 input2 input3 input4 input5 input6 input7{
 gen l_`var' = log(`var')
}
reg l_output l_input1 l_input2 l_input3 l_input4 l_input5 l_input6 l_input7
drop keep_val tot tot1

********************************************************************************


cd "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/Transport equipment"

import excel "Transport equipment.xlsx", sheet("Sheet1") firstrow clear
reshape long input1_ input2_ input3_ output_ input4_ input5_ input6_ input7_, i(CompanyName) j(year)
sort year CompanyName
ren (input1_ input2_ input3_ output_ input4_ input5_ input6_ input7_) (input1 input2 input3 output input4 input5 input6 input7)

encode CompanyName, gen(x)
ren CompanyName CompanyName_
ren x CompanyName

order CompanyName year output, first
xtset CompanyName year, yearly

foreach var of varlist output input1 input2 input3 input4 input5 input6 input7{
  replace `var' = . if `var' == 0
}

misstable summarize output

drop if output == .
drop CompanyName_
misstable summarize

egen min_val = min(input5)
replace input5 = min_val if input5 == .
drop min_val

/*
foreach var of varlist input1 input2 input3 input4 input6 input7{
  egen mean_val = mean(`var')
  replace `var' = mean_val if `var' == .
  drop mean_val
}
*/

sum
gsort year CompanyName
foreach var of varlist input1 input2 input3 input4 input6 input7{
  by year: egen min_`var' = min(`var')
}

mi set mlong
mi register imputed output input1 input2 input3 input4 input5 input6 input7
mi impute mvn output input1 input2 input3 input4 input5 input6 input7 = year CompanyName, add(10) rseed (53421)

forvalues i = 1/9{
  drop if _mi_m == `i'
}

drop if _mi_miss == 1
gsort CompanyName year
replace _mi_m = 0 if _mi_m == 10
replace _mi_miss = 0 if _mi_miss == .
mi unset

drop mi_m mi_id mi_miss

gsort year CompanyName
by year: egen mean_out = mean(output)

foreach var of varlist input1 input2 input3 input4 input6 input7{
  by year: egen mean_`var' = mean(`var')
  replace `var' = min_`var' if `var' <= 0 & output < mean_out
  replace `var' = mean_`var' if `var' <= 0
  drop mean_`var' min_`var'
}
drop mean_out
sum

merge m:1 year using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Price Index.dta"
drop _merge
foreach var of varlist output input1 input2 input4 input5 input6{
  gen `var'_ = (`var'/wpi)*100
  drop `var'
  ren `var'_ `var'
}
gen input3_ = (input3/cpi)*100
gen input7_ = (input7/cpi)*100
drop input3 input7
ren (input3_ input7_) (input3 input7)

misstable summarize
xtset CompanyName year, yearly

tab year

by CompanyName: gen keep_val = 1 if F1.year == 2001 & F2.year == 2002 & F3.year == 2003 & F4.year == 2004 & F5.year == 2005 & F6.year == 2006 & F7.year == 2007 & F8.year == 2008 & F9.year == 2009 & F10.year == 2010 & F11.year == 2011 & F12.year == 2012 & F13.year == 2013 & F14.year == 2014 & F15.year == 2015 & F16.year == 2016 & F17.year == 2017 & F18.year == 2018 & F19.year == 2019 & F20.year == 2020
by CompanyName: replace keep_val = 1 if L1.keep_val == 1 | L2.keep_val == 1 | L3.keep_val == 1 | L4.keep_val == 1 | L5.keep_val == 1 | L6.keep_val == 1 | L7.keep_val == 1 | L8.keep_val == 1 | L9.keep_val == 1 | L10.keep_val == 1 | L11.keep_val == 1 | L12.keep_val == 1 | L13.keep_val == 1 | L14.keep_val == 1 | L15.keep_val == 1 | L16.keep_val == 1 | L17.keep_val == 1 | L18.keep_val == 1 | L19.keep_val == 1 | L20.keep_val == 1
export delimited output input1 input2 input3 input4 input5 input6 input7 using "99" if keep_val == 1, novarnames replace
export excel CompanyName year output input1 input2 input3 input4 input5 input6 input7 cpi wpi using "Transport equipment_" if keep_val == 1, firstrow(variables) replace
qui tab keep_val year if year == 2000
scalar n = r(N)

gsort year CompanyName
by year: egen tot = sum(output)
by year: egen tot1 = sum(output) if keep_val == 1

putexcel I1=("Transport equipment") using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
putexcel I24=(n) using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
forvalues i = 2/22{
 scalar j = `i' + 1998
 qui sum tot if year == j
 scalar mean1 = r(mean)
 qui sum tot1 if year == j
 scalar mean2 = r(mean)
 scalar prop = (mean2/mean1)*100
 di ""
 di "Year " j ": Number of Observations " n
 di "Sales Proportion : " prop " %"
 putexcel I`i'=(prop) using "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/results.xlsx", modify
}

drop if keep_val == .
xtset CompanyName year, yearly
reg output input1 input2 input3 input4 input5 input6 input7
foreach var of varlist output input1 input2 input3 input4 input5 input6 input7{
 gen l_`var' = log(`var')
}
reg l_output l_input1 l_input2 l_input3 l_input4 l_input5 l_input6 l_input7
drop keep_val tot tot1

********************************************************************************

/*
gen keep_vals = .
forvalues i = 1/10{
  scalar y1 = 1998 + (2*`i')
  scalar y2 = y1 + 1
  scalar y3 = y1 + 2
  by CompanyName: gen keep_val = 1 if L1.year == y2 & L2.year == y1
  by CompanyName: replace keep_val = 1 if F1.keep_val == 1 | F2.keep_val == 1
  di ""
  di "File `i'"
  tab keep_val year
  export delimited output input1 input2 input3 input4 input5 input6 input7 using "`i'" if keep_val == 1, novarnames replace
  replace keep_vals = 1 if keep_val == 1
  drop keep_val
}

gen keep_vals = .
forvalues i = 1/10{
  scalar y1 = 1998 + (2*`i')
  scalar y2 = y1 + 1
  scalar y3 = y1 + 2
  by CompanyName: gen keep_val = 1 if L1.year == y2 & L2.year == y1
  by CompanyName: replace keep_val = 1 if F1.keep_val == 1 | F2.keep_val == 1
  di ""
  di "File `i'"
  tab keep_val year
  export delimited output input1 input2 input3 input4 input5 input6 input7 using "`i'" if keep_val == 1, novarnames replace
  replace keep_vals = 1 if keep_val == 1
  drop keep_val
}

gsort year CompanyName
by year: egen tot = sum(output)
by year: egen tot1 = sum(output) if keep_vals == 1

forvalues i = 2000/2020{
 qui sum tot if year == `i'
 scalar mean1 = r(mean)
 qui sum tot1 if year == `i'
 scalar mean2 = r(mean)
 scalar prop = (mean2/mean1)*100
 di ""
 di "Year `i'"
 di "Sales Proportion : " prop " %"
}
*/

/*
forvalues i = 2000/2020{
  *cd "/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data/Chemicals & chemical products/`i'"
  export delimited output input1 input2 input3 input4 input5 input6 input7 using "`i'" if year == `i', novarnames replace
}
*/

/*
forvalues i = 2000/2020{
  di ""
  di "Year `i'" 
  misstable summarize if year == `i'
}
*/

/*
forvalues i = 1/7{
  scalar y1 = 1997 + (3*`i')
  scalar y2 = y1 + 1
  scalar y3 = y1 + 2
  by CompanyName: gen keep_val = 1 if L1.year == y2 & L2.year == y1
  by CompanyName: replace keep_val = 1 if F1.keep_val == 1 | F2.keep_val == 1
  tab keep_val year
  export delimited output input1 input2 input3 input4 input5 input6 input7 using "`i'" if keep_val == 1, novarnames replace
  drop keep_val
}
*/

/*
forvalues i = 2000/2020{
  egen x`i' = count(year) if year == `i'
  qui sum x`i'
  scalar n`i' = r(mean)
  drop x`i'
}
*/

/*
gen x = 1 if output == .
replace x = 0 if x == .
by CompanyName: egen miss = total(x)
drop if miss == 21
tab year
drop miss x

gen x = 1 if Incorporation > year
replace x = 0 if x == .
by CompanyName: egen miss = total(x)
drop if miss > 1
tab year
drop miss x
*/

/*
mdesc output input1 input2 input3 input4 input5 input6 input7
mi set mlong
mi misstable summarize output input1 input2 input3 input4 input5 input6 input7
mi misstable patterns output input1 input2 input3 input4 input5 input6 input7
*/

/*
gsort year -output
drop if year == 2000
tab year
*by year: keep if _n > _N - 122
*tab year
*/

/*
* Method 1
mipolate output year, by(CompanyName) gen(foutput)
mipolate output year, by(CompanyName) gen(boutput) backward
replace output = foutput if missing(output) & foutput==boutput
*/

/*
* Method 2
by CompanyName: replace output = (L1.output + F1.output)/2 if (L1.output != 0 & F1.output != 0) & output == .
by CompanyName: replace output = L1.output if output == .
misstable summarize output
*/

/*
* Method 3
mi register imputed output input1 input2 input3 input4 input5 input6 input7
mi impute mvn output input1 input2 input3 input4 input5 input6 input7 = year CompanyName, add(10) rseed (53421)

forvalues i = 1/9{
  drop if _mi_m == `i'
}

forvalues i = 1/2{
  di "Table `i'"
  tab year if _mi_m == `i'
}
*/

/*
* Method 4
mi xtset, clear
mi reshape wide output input1 input2 input3 input4 input5 input6 input7, i(CompanyName) j(year)
mi register imputed output2000 input12000 input22000 input32000 input42000 input52000 input62000 input72000 output2001 input12001 input22001 input32001 input42001 input52001 input62001 input72001 output2002 input12002 input22002 input32002 input42002 input52002 input62002 input72002 output2003 input12003 input22003 input32003 input42003 input52003 input62003 input72003 output2004 input12004 input22004 input32004 input42004 input52004 input62004 input72004 output2005 input12005 input22005 input32005 input42005 input52005 input62005 input72005 output2006 input12006 input22006 input32006 input42006 input52006 input62006 input72006 output2007 input12007 input22007 input32007 input42007 input52007 input62007 input72007 output2008 input12008 input22008 input32008 input42008 input52008 input62008 input72008 output2009 input12009 input22009 input32009 input42009 input52009 input62009 input72009 output2010 input12010 input22010 input32010 input42010 input52010 input62010 input72010 output2011 input12011 input22011 input32011 input42011 input52011 input62011 input72011 output2012 input12012 input22012 input32012 input42012 input52012 input62012 input72012 output2013 input12013 input22013 input32013 input42013 input52013 input62013 input72013 output2014 input12014 input22014 input32014 input42014 input52014 input62014 input72014 output2015 input12015 input22015 input32015 input42015 input52015 input62015 input72015 output2016 input12016 input22016 input32016 input42016 input52016 input62016 input72016 output2017 input12017 input22017 input32017 input42017 input52017 input62017 input72017 output2018 input12018 input22018 input32018 input42018 input52018 input62018 input72018 output2019 input12019 input22019 input32019 input42019 input52019 input62019 input72019 output2020 input12020 input22020 input32020 input42020 input52020 input62020 input72020
*mi misstable summarize
mi impute mvn output2000 input12000 input22000 input32000 input42000 input52000 input62000 input72000 output2001 input12001 input22001 input32001 input42001 input52001 input62001 input72001 output2002 input12002 input22002 input32002 input42002 input52002 input62002 input72002 output2003 input12003 input22003 input32003 input42003 input52003 input62003 input72003 output2004 input12004 input22004 input32004 input42004 input52004 input62004 input72004 output2005 input12005 input22005 input32005 input42005 input52005 input62005 input72005 output2006 input12006 input22006 input32006 input42006 input52006 input62006 input72006 output2007 input12007 input22007 input32007 input42007 input52007 input62007 input72007 output2008 input12008 input22008 input32008 input42008 input52008 input62008 input72008 output2009 input12009 input22009 input32009 input42009 input52009 input62009 input72009 output2010 input12010 input22010 input32010 input42010 input52010 input62010 input72010 output2011 input12011 input22011 input32011 input42011 input52011 input62011 input72011 output2012 input12012 input22012 input32012 input42012 input52012 input62012 input72012 output2013 input12013 input22013 input32013 input42013 input52013 input62013 input72013 output2014 input12014 input22014 input32014 input42014 input52014 input62014 input72014 output2015 input12015 input22015 input32015 input42015 input52015 input62015 input72015 output2016 input12016 input22016 input32016 input42016 input52016 input62016 input72016 output2017 input12017 input22017 input32017 input42017 input52017 input62017 input72017 output2018 input12018 input22018 input32018 input42018 input52018 input62018 input72018 output2019 input12019 input22019 input32019 input42019 input52019 input62019 input72019 output2020 input12020 input22020 input32020 input42020 input52020 input62020 input72020 = CompanyName, add(10)
*/

/*
* Method 5
/*
mi xtset, clear
mi reshape wide output input1 input2 input3 input4 input5 input6 input7, i(CompanyName) j(year)
mi register imputed output2000 output2001 output2002 output2003 output2004 output2005 output2006 output2007 output2008 output2009 output2010 output2011 output2012 output2013 output2014 output2015 output2016 output2017 output2018 output2019 output2020
mi misstable summarize
mi impute mvn output2000 output2001 output2002 output2003 output2004 output2005 output2006 output2007 output2008 output2009 output2010 output2011 output2012 output2013 output2014 output2015 output2016 output2017 output2018 output2019 output2020 = input12000 input22000 input32000 input42000 input52000 input62000 input72000 input12001 input22001 input32001 input42001 input52001 input62001 input72001 input12002 input22002 input32002 input42002 input52002 input62002 input72002 input12003 input22003 input32003 input42003 input52003 input62003 input72003 input12004 input22004 input32004 input42004 input52004 input62004 input72004 input12005 input22005 input32005 input42005 input52005 input62005 input72005 input12006 input22006 input32006 input42006 input52006 input62006 input72006 input12007 input22007 input32007 input42007 input52007 input62007 input72007 input12008 input22008 input32008 input42008 input52008 input62008 input72008 input12009 input22009 input32009 input42009 input52009 input62009 input72009 input12010 input22010 input32010 input42010 input52010 input62010 input72010 input12011 input22011 input32011 input42011 input52011 input62011 input72011 input12012 input22012 input32012 input42012 input52012 input62012 input72012 input12013 input22013 input32013 input42013 input52013 input62013 input72013 input12014 input22014 input32014 input42014 input52014 input62014 input72014 input12015 input22015 input32015 input42015 input52015 input62015 input72015 input12016 input22016 input32016 input42016 input52016 input62016 input72016 input12017 input22017 input32017 input42017 input52017 input62017 input72017 input12018 input22018 input32018 input42018 input52018 input62018 input72018 input12019 input22019 input32019 input42019 input52019 input62019 input72019 input12020 input22020 input32020 input42020 input52020 input62020 input72020 CompanyName, add(10)
*/
tab year
mi register imputed output
mi impute mvn output = input1 input2 input3 input4 input5 input6 input7 year CompanyName, add(10) rseed (53421)
tab year if _mi_m == 10
*/

/*
drop _mi_miss _mi_m _mi_id
export excel using "Chemicals & chemical products_", firstrow(variables) replace
drop CompanyName year
export delimited using "EG1-dta", novarnames replace
*/
