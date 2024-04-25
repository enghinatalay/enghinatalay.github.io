set scheme s1color
cap ssc install freduse 
cap ssc install grc1leg 
import excel using r-hicp-data.xlsx, clear   cellrange(A4:P320) firstrow  
/* Read in data, downloaded from the HICP homepage: https://www.bls.gov/cpi/research-series/r-hicp-home.htm */
ren Year year
ren Month month
save rhicp, replace

freduse CPIAUCSL CPILFESL CP0000USM086NEST CUSR0000SEHC01 , clear 
 /* Read in remaining data from FRED */
ren CPIAUCSL cpi
ren CPILFESL cpi_lfe
ren CP0000USM086NEST hcpi
ren CUSR0000SEHC01 oerus  
gen year=year(daten)
gen month=month(daten)
merge 1:1 year month using rhicp
foreach var of varlist *cpi* oer* AllItemsLessFoodandEnergy AllItems {
 	gen `var'_yoy=log(`var'/`var'[_n-12])
}
/* Try to strip out oer from CPI. I understand that the CPI series, to see how well this matches HICP.
I understand that the HICP series are not seasonally adjusted, but given that I am looking at year-over-year-over-year
growth rates this should not matter too much */
gen cpi_ex_oer_yoy=(cpi_yoy- oerus_yoy*0.268)/(1-0.268)  
/* I know that the weights are time-varying, but I do not believe this to be the cause of the discrepancy, as the weights only change by a couple of percent within the last couple years */
gen cpi_lfe_ex_oer_yoy=(cpi_lfe_yoy- oerus_yoy*0.336)/(1-0.336)
format daten %dN/Y

line cpi_yoy cpi_ex_oer_yoy  AllItems_yoy daten if year(daten)>=2019, ytitle("") legend(lab(1 "CPI") lab(2 "CPI Ex OER") lab(3 "Harmonized CPI") row(1) region(lwidth(none))) xtitle("")  subtitle("Headline Year-over-Year Inflation", pos(11)) lpattern(solid dash longdash shortdash) ylabel(-0.01(0.01).10, angle(0) grid) xlabel(,grid)
graph save "headline_hicp.gph", replace
line cpi_lfe_yoy cpi_lfe_ex_oer_yoy AllItemsLessFoodandEnergy_yoy daten if year(daten)>=2019, ytitle("") legend(lab(1 "CPI") lab(2 "CPI Ex OER") lab(3 "Harmonized CPI") row(1) region(lwidth(none)))  xtitle("") subtitle("Core Year-over-Year Inflation", pos(11)) lpattern(solid dash longdash  shortdash) ylabel(-0.01(0.01).10, angle(0) grid) xlabel(,grid)
graph save "core_hicp.gph", replace
grc1leg  headline_hicp.gph core_hicp.gph, legendfrom( headline_hicp.gph )
graph export hicp_comparison.png, replace