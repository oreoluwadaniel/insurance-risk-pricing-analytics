/*=====================================================================
MACROECONOMIC CONDITIONS & CLAIMS COST ANALYSIS
Insurance Risk, Pricing & Profitability Project - Part 4 of 4
=====================================================================

Business question this script answers:
Do claims get more expensive when the broader economy is under more
pressure? This compares inflation, unemployment, and interest rates
against average claim size, year by year.

Tables used: claims, macroeconomic
SQL dialect: T-SQL (Microsoft SQL Server / Azure SQL)

Bug found in the original script: the macroeconomic table in this
project is recorded daily, 365 rows for a single year, not yearly. The
original query joined claims to macroeconomic data on
YEAR(claim_date) = YEAR(m.date) directly, then grouped by the exact
daily inflation_rate value. That means every claim in a given year got
joined against all 365 daily rows for that year, and the results were
grouped by whichever specific daily rate happened to be attached. The
output looked like a detailed trend across many different inflation
levels, but it was really the same handful of yearly claim averages
copied out over and over next to whatever daily rate they landed next
to. The fix below aggregates macroeconomic data down to one row per
year first, then joins that single yearly row to claims, so each year
is only compared once.
=====================================================================*/

IF OBJECT_ID('tempdb..#macro_yearly') IS NOT NULL DROP TABLE #macro_yearly;

SELECT
YEAR(date) AS claim_year,
AVG(inflation_rate) AS avg_inflation_rate,
AVG(unemployment_rate) AS avg_unemployment_rate,
AVG(interest_rate) AS avg_interest_rate
INTO #macro_yearly
FROM macroeconomic
GROUP BY YEAR(date);

/*---------------------------------------------------------------------
QUERY 1: Yearly claims cost vs economic conditions

One row per year, with average claim amount sitting next to that
year's average inflation, unemployment, and interest rate. This shows
association, not causation. Plenty of other things move claim costs
too, and a handful of years is not enough data to prove a economic
driver on its own.
---------------------------------------------------------------------*/
SELECT
YEAR(cl.claim_date) AS claim_year,
COUNT(cl.claim_id) AS claims_count,
AVG(cl.claim_amount) AS avg_claim_amount,
m.avg_inflation_rate,
m.avg_unemployment_rate,
m.avg_interest_rate
FROM claims cl
JOIN #macro_yearly m ON YEAR(cl.claim_date) = m.claim_year
GROUP BY
YEAR(cl.claim_date),
m.avg_inflation_rate,
m.avg_unemployment_rate,
m.avg_interest_rate
ORDER BY claim_year;
