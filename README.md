# Insurance Risk, Pricing & Profitability Analytics

A SQL portfolio built on a simulated insurance book of business covering 3,000 policies, 3,000 claims, underwriting decisions, fraud signals, and daily macroeconomic data from 2018 onward.

The starting question behind all four projects here is the same one an insurance finance team actually asks: writing more policies isn't the same thing as running a profitable book. Premiums have to cover claims, risky policies have to be priced like risky policies, fraud has to get caught before it compounds, and it helps to know whether the wider economy is showing up in claims costs at all. Each project below tackles one piece of that question on its own, with its own script, its own write-up, and its own corrected logic where the original draft had a bug.

## How this repo is organized

Each numbered folder is a standalone project. You can open any one of them on its own, they don't depend on each other, and each has a SQL script plus a README covering the business problem, the data, the method, an honest error check, the insight, a recommendation, the business impact, what was done, the tools used, and the actual results.

01: Claims Performance & Loss Ratio Analysis
Is premium covering claims, at the policy level, the customer level, and the product-line level. Found and fixed a bug where premium was getting double-counted for any customer or product line where policies carried more than one claim.

02: Underwriting Risk, Pricing & Premium Review System
Does the premium being charged match the risk being taken on. Includes a mispricing screen, a rule-based premium review engine, and a risk-based claims comparison. Found and fixed two counting bugs where claim counts and customer counts were being inflated by rows left over from a LEFT JOIN.

03: Fraud Detection & Claims Investigation Analysis
A ranked watchlist of claims with strong fraud signals, plus a geographic view of where confirmed fraud is concentrated. Both original queries checked out logically, this write-up focuses on what the real numbers show, roughly 1 in 5 claims clears the anomaly threshold used here, against a confirmed fraud rate of about 10 percent.

04: Macroeconomic Conditions & Claims Cost Analysis
Whether inflation, unemployment, and interest rates show up in claims costs year over year. Found and fixed a join that was matching claims against daily economic data instead of yearly averages, which was quietly generating hundreds of duplicate rows per year.

## The data

Nine CSV files sit in the /data folder:

policies.csv, customers.csv, claims.csv, and underwriting.csv form the core of the book, one row per policy, one row per customer, one row per claim, and underwriting scores tied to each policy. fraud_signals.csv adds an anomaly score and stated fraud reason per claim. macroeconomic.csv has daily inflation, unemployment, and interest rate figures. payments.csv, behavioral.csv, and geospatial.csv are included for completeness but aren't used in these four scripts, they're there for anyone who wants to extend this portfolio with a payments-timing or behavioral-risk angle later.

All the data is simulated. No real customers, claims, or financial figures are represented here.

## A note on how this portfolio was built

Every SQL script in this repo started from a single working draft and was reviewed line by line against the actual data before being split into these four standalone pieces. Three real bugs came out of that review, all of them versions of the same underlying trap: joining a one-to-many relationship (policies to claims, or claims to daily economic data) and then aggregating a value that lives on the "one" side without collapsing the "many" side first. Each project's README walks through exactly where that happened, why it mattered, and how it was fixed, since the fix itself is a more useful thing to show than a clean query with no history behind it.
