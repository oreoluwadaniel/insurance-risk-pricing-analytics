# Macroeconomic Conditions & Claims Cost Analysis

Part 4 of a 4-part SQL portfolio built on a simulated insurance book of business. This piece steps outside the policy data to ask whether the wider economy shows up in claims costs.

## Business problem

Claims don't happen in a vacuum. Inflation pushes up the cost of repairs and replacements, unemployment can change how often people file claims, and interest rates affect the broader financial environment a business operates in. Finance and actuarial teams want to know whether any of that shows up in the claims data itself, since it feeds into how reserves get set and how pricing gets adjusted for the year ahead.

This script compares average claim size, year by year, against average inflation, unemployment, and interest rates for that same year.

## Data source

Two tables feed this analysis. claims.csv gives the claim amount and claim date for each of 3,000 claims. macroeconomic.csv gives daily readings, 365 rows per year, for inflation rate, unemployment rate, and interest rate, covering the same period the claims data spans.

That daily grain in the macroeconomic table is the detail that mattered most in reviewing this script, and it's the reason the original query needed a real fix rather than a small tweak.

## Methodology

The approach here is to bring both datasets down to the same level of detail, one row per year, before comparing them. Claims already aggregate cleanly to a yearly average. The macroeconomic data needed to be aggregated first too, since comparing daily rates against yearly claim averages was mixing two different grains of data in the same join.

## Analysis & error check

The original query joined claims to macroeconomic data using YEAR(claim_date) = YEAR(m.date), then grouped the result by m.inflation_rate, the exact daily rate. Since macroeconomic data here is recorded daily, that join matched every single claim in a given year against all 365 daily rows for that year. The result set looked detailed, dozens of distinct inflation rate values with claim averages next to each one, but what it actually showed was the same yearly claim average copied out 365 times, once for each day's rate it happened to land next to. Grouping by a specific daily rate that has no real relationship to an individual claim's actual settlement isn't a meaningful comparison, it just multiplies the row count and creates an illusion of granularity that isn't backed by anything real.

The fix aggregates macroeconomic data down to one row per year first (#macro_yearly), averaging inflation, unemployment, and interest rate across all 365 days in that year, then joins that single yearly row to the yearly claims average. That turns a join that used to produce hundreds of misleading rows per year into one honest row per year.

## Insight

The macroeconomic data in this project moves quite a bit day to day. Inflation readings in the sample data range from roughly 3 percent to 15 percent within a single month, which is a wide daily swing for what's usually a slow-moving indicator in the real world. That volatility is exactly why averaging to a yearly figure before comparing against claims matters here. A single day's inflation reading is closer to noise than signal, and the original query was effectively picking one noisy data point per claim and calling it a trend.

The real question, whether claims cost trends upward alongside yearly inflation, unemployment, or interest rates, is answered by running the corrected query against a live copy of this data. It's built to surface that relationship cleanly now instead of drowning it in duplicate rows.

## Recommendation

Run this corrected query as part of an annual reserve-setting or pricing review, comparing the current year's average claim size against that year's average inflation and unemployment figures. If a real relationship shows up across a few years of data, it's worth folding an economic adjustment factor into pricing models rather than treating every year's claims trend as purely internal to the business.

Whatever the result, treat it as an association to investigate further, not a proven cause. A handful of years of data and a handful of economic indicators isn't enough on its own to claim that inflation causes claims to rise. It's a reasonable starting hypothesis worth testing with more rigorous methods if the pattern looks strong.

## Business impact

Getting this join right protects the business from acting on a false trend. A join that fans out 365 times per year can accidentally make a flat relationship look like a strong one, or the reverse, simply because of how many duplicate rows land at different points along the x-axis. Fixing it means any pricing or reserving decision built on this analysis rests on a real yearly comparison instead of an artifact of the join.

## What was done

I traced the row-count mismatch between claims and macroeconomic data back to its source, identified that the daily grain of the macroeconomic table was fanning out the join, and rebuilt the query around a yearly aggregation step that removes the problem before the join happens rather than trying to filter or deduplicate after the fact.

## Tools used and how they helped

Written in T-SQL for SQL Server or Azure SQL. A temp table (#macro_yearly) does the grain-matching work, aggregating 365 daily rows down to one yearly row using AVG() across inflation, unemployment, and interest rate. YEAR() extracts the year from both the claim date and the macro date so the two datasets line up on the same key.

## Results

The corrected script returns one row per year, showing claim count, average claim amount, and average inflation, unemployment, and interest rate for that year, side by side. That's a clean, honest yearly comparison instead of the several-hundred-rows-per-year output the original join was silently producing.
