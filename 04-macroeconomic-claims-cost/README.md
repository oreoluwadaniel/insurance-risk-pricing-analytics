# MacroRisk: Economic Conditions & Claims Cost Intelligence

**A SQL insurance analytics project connecting claims costs with inflation, unemployment, and interest rates to support pricing reviews, reserve planning, and external risk monitoring.**

---

## Project Overview

Insurance claims costs are shaped by more than what happens inside an insurer's portfolio.

Repair costs change.

Replacement costs change.

Labor and services become more expensive.

Economic conditions shift.

If average claims costs rise from one year to the next, finance and actuarial teams need to understand whether the change is isolated to the portfolio or occurring alongside broader economic movement.

MacroRisk builds that external-risk view.

The project combines **3,000 insurance claims** with daily macroeconomic observations covering:

* Inflation
* Unemployment
* Interest Rates

and brings both datasets to the same annual grain before comparing them.

The objective is not to prove that economic conditions cause claims costs to change.

It is to answer a more practical business question:

> **Are changes in claims costs occurring alongside changes in the wider economic environment, and is the relationship important enough to investigate for future pricing and reserve decisions?**

---

# Business Problem

An insurer can price risk correctly today and still face higher claims costs tomorrow.

Consider a portfolio where average claim severity increases:

```text
Year 1 Average Claim:  $4,800
Year 2 Average Claim:  $5,200
Year 3 Average Claim:  $5,900
```

The immediate question is:

> **Why?**

The increase could reflect:

* Changes in the portfolio's risk mix
* Different types of claims
* Higher repair and replacement costs
* General inflation
* Changes in customer behavior
* Economic conditions
* A combination of several factors

Without external context, management sees the increase but cannot tell whether it is purely portfolio-specific or moving alongside the wider economy.

MacroRisk adds that context.

---

# The Economic Risk Framework

```text
                  ECONOMIC CONDITIONS
                         |
        -------------------------------------
        |                 |                 |
        ↓                 ↓                 ↓
    INFLATION        UNEMPLOYMENT      INTEREST RATES
        |                 |                 |
        ------------------|------------------
                           |
                           ↓
                  ECONOMIC ENVIRONMENT
                           |
                           ↓
                    CLAIMS EXPERIENCE
                           |
                           ↓
                 CLAIM COST MONITORING
                           |
              -------------------------
              |                       |
              ↓                       ↓
       RESERVE REVIEW           PRICING REVIEW
```

The analysis provides a monitoring layer between external economic conditions and internal claims performance.

---

# Business Questions

The project addresses four core questions.

### Claims Cost Trend

How is average claim amount changing from year to year?

### Inflation Context

Do years with higher average inflation also show different average claims costs?

### Broader Economic Context

How do unemployment and interest rates move alongside claims costs over the same period?

### Financial Planning Signal

Are the relationships strong and consistent enough to justify deeper analysis for pricing or reserve planning?

The SQL provides the comparison layer required to begin answering those questions correctly.

---

# Data Sources

Two datasets support the analysis.

## `claims.csv`

Contains **3,000 insurance claims**.

Key fields used include:

* Claim ID
* Claim Date
* Claim Amount

The claim date allows claims to be assigned to the appropriate reporting year.

At the annual level, the analysis calculates:

* Claim Count
* Average Claim Amount

---

## `macroeconomic.csv`

Contains daily economic observations covering the same general period as the claims data.

Key fields include:

* Date
* Inflation Rate
* Unemployment Rate
* Interest Rate

The important structural detail is the grain:

> **One economic observation per day**

That means a single year can contain roughly 365 macroeconomic records.

Claims and macroeconomic data therefore cannot be joined directly at year level without first accounting for that difference in grain.

---

# Methodology

The central principle behind this project is simple:

> **Compare like with like.**

If claims are being analyzed annually, the economic indicators they are compared against also need to represent annual conditions.

The analysis therefore aggregates each dataset independently before joining them.

---

## Step 1: Aggregate Claims by Year

Claims are summarized to annual level.

Conceptually:

```text
CLAIM 1 ─┐
CLAIM 2 ─┤
CLAIM 3 ─┤
   ...   ├──→ YEARLY CLAIM PROFILE
CLAIM N ─┘
```

For each year, the analysis calculates:

```text
Claim Count
Average Claim Amount
```

This produces the annual claims-cost view.

---

## Step 2: Aggregate Economic Conditions by Year

Daily macroeconomic observations are separately reduced to one annual record.

For each year:

```text
365 DAILY OBSERVATIONS
          |
          ↓
    YEARLY ECONOMIC PROFILE
          |
    -------------------
    |        |        |
    ↓        ↓        ↓
 Inflation  Unemployment  Interest Rate
 Average      Average        Average
```

The resulting yearly economic table contains:

* Average Inflation Rate
* Average Unemployment Rate
* Average Interest Rate

---

## Step 3: Match the Analytical Grain

Once both datasets have been reduced to annual grain:

```text
CLAIMS

2021 | Claim Count | Avg Claim Amount
2022 | Claim Count | Avg Claim Amount
2023 | Claim Count | Avg Claim Amount


MACROECONOMICS

2021 | Avg Inflation | Avg Unemployment | Avg Interest
2022 | Avg Inflation | Avg Unemployment | Avg Interest
2023 | Avg Inflation | Avg Unemployment | Avg Interest
```

they can be joined safely on:

```text
Year
```

producing:

```text
YEAR
CLAIM COUNT
AVERAGE CLAIM AMOUNT
AVERAGE INFLATION
AVERAGE UNEMPLOYMENT
AVERAGE INTEREST RATE
```

One year.

One row.

One comparable economic context.

---

# Critical Finding: The Original Join Created False Granularity

The most important issue discovered during review was not a syntax error.

The original SQL ran.

The problem was that it answered the question at the wrong analytical grain.

The original logic effectively joined:

```text
YEARLY CLAIMS
      ×
DAILY MACRO DATA
```

using the year extracted from each date.

That sounds reasonable until the row relationship is examined.

Suppose one year contains:

```text
500 Claims
365 Economic Observations
```

Matching every claim in that year against every daily macroeconomic observation can create:

```text
500 × 365 = 182,500
```

joined combinations before aggregation.

Those extra rows do not represent additional claims or additional economic events relevant to individual claims.

They are artifacts of the join.

---

# Why the Original Output Looked Convincing

This is what makes grain mismatch dangerous.

The original output could still contain:

* Valid years
* Real inflation values
* Real claim amounts
* Plausible averages
* No SQL errors

Nothing necessarily looked obviously broken.

The problem was analytical.

A yearly claim pattern was being repeated across daily economic observations.

The output appeared more detailed than the underlying relationship actually was.

That is **false granularity**.

More rows did not mean more information.

---

# The Fix: Aggregate Before Joining

The corrected model changes the order of operations.

### Original Pattern

```text
RAW CLAIMS
     |
     ↓
JOIN
     ↑
DAILY MACRO DATA
     |
     ↓
AGGREGATE
```

### Corrected Pattern

```text
RAW CLAIMS                    DAILY MACRO DATA
     |                               |
     ↓                               ↓
AGGREGATE                        AGGREGATE
BY YEAR                          BY YEAR
     |                               |
     ↓                               ↓
YEARLY CLAIMS ───────────── YEARLY ECONOMY
                    |
                    ↓
                  JOIN
                    |
                    ↓
             ANNUAL COMPARISON
```

This ensures each side of the join represents the same unit of analysis before they are combined.

---

# Why This Matters for Insurance Decisions

A bad join in an exploratory project is inconvenient.

A bad join in financial analysis is more serious because the result may influence decisions.

Suppose management sees an apparent relationship between:

> Rising inflation → Rising claims costs

and uses it to support a pricing adjustment.

If that relationship was created or distorted by duplicated observations, the business is making a pricing decision based on a SQL artifact rather than an economic signal.

The same applies to reserving.

MacroRisk therefore treats **grain validation as part of financial control**, not simply data cleaning.

---

# Economic Data Quality Observation

The macroeconomic dataset contains substantial short-term movement.

Inflation readings in the simulated data range from approximately:

> **3% to 15% within a single month.**

That is important when interpreting the analysis.

A single daily observation may not provide a useful representation of the broader economic environment the insurer operated in during that year.

Aggregating the economic data provides a more stable annual measure for this specific comparison.

It also highlights an important limitation:

> **This is simulated economic data and should not be interpreted as the behavior of actual historical macroeconomic indicators.**

The analytical method is the focus of the project.

---

# Interpreting the Results Correctly

This analysis is designed to identify **association**, not causation.

If the output shows:

```text
Inflation ↑
Claims Cost ↑
```

that does not prove:

```text
Inflation caused Claims Cost ↑
```

Several other factors could explain the movement.

For example:

* Different Policy Mix
* Higher Coverage Limits
* Changes in Claim Type
* Different Customer Risk Composition
* Geographic Exposure
* Catastrophic Events
* Changes in Settlement Practices

The correct interpretation is:

> **Claims costs and inflation moved together during the observed period, making the relationship worth further investigation.**

That is a defensible analytical conclusion.

---

# From Historical Reporting to Forward Planning

The real business value comes from moving beyond simply reporting what claims cost last year.

A stronger finance process looks like:

```text
HISTORICAL CLAIMS
        |
        ↓
CLAIMS COST TREND
        |
        +──────────── ECONOMIC CONDITIONS
        |                    |
        ↓                    ↓
      INTERNAL          EXTERNAL CONTEXT
          \                /
           \              /
            ↓            ↓
            FINANCIAL REVIEW
                   |
          ---------------------
          |                   |
          ↓                   ↓
     PRICING REVIEW      RESERVE REVIEW
```

The economic data does not replace internal claims analysis.

It adds another dimension to it.

---

# Business Recommendations

## 1. Add Economic Context to Annual Claims Reviews

The annual claims review should not show average claim cost in isolation.

At minimum, it should compare:

```text
Average Claim Amount
Average Inflation
Average Unemployment
Average Interest Rate
```

for the same reporting period.

This gives finance and actuarial teams external context when investigating material changes in claims severity.

---

## 2. Monitor Claims Inflation Separately

General inflation and insurance claims inflation are not necessarily the same thing.

A stronger production system should calculate the insurer's own claims-cost growth rate:

```text
Current Year Average Claim
            vs.
Previous Year Average Claim
```

and compare that movement with relevant economic indicators.

If general inflation rises 5% while average claims costs rise 15%, the remaining difference deserves investigation rather than being attributed automatically to inflation.

---

## 3. Segment Before Changing Pricing

A portfolio-wide average can hide where claims inflation is actually coming from.

Before adjusting premiums based on economic conditions, the analysis should be extended across dimensions such as:

* Policy Type
* Claim Type
* Geography
* Risk Segment

For example:

```text
AUTO CLAIMS       +12%
PROPERTY CLAIMS    +4%
LIFE CLAIMS        +2%
```

would tell a very different pricing story from:

```text
ALL CLAIMS         +6%
```

The more actionable question is not simply:

> **Are claims costs rising?**

It is:

> **Which parts of the book are driving the increase?**

---

## 4. Treat Macroeconomic Relationships as Monitoring Signals

Inflation, unemployment, and interest rates should initially function as contextual indicators.

If a consistent relationship appears across several years, that finding can justify more rigorous statistical analysis before economic assumptions are incorporated into pricing or reserving models.

The SQL layer identifies where deeper modeling may be worthwhile.

---

## 5. Improve the Economic Dataset Before Production Use

A real implementation should replace simulated macroeconomic observations with authoritative economic data and select indicators relevant to the insurer's actual markets and product lines.

Depending on the portfolio, more useful indicators might include:

* Repair Cost Indices
* Medical Cost Inflation
* Construction Costs
* Vehicle Parts Prices
* Wage Inflation
* Property Values

General macroeconomic indicators provide context.

Industry-specific cost drivers may provide stronger explanatory value.

---

# Business Value

MacroRisk creates value primarily by improving the context behind financial decisions.

## Pricing Intelligence

Claims-cost movement can be evaluated alongside external economic conditions before pricing changes are considered.

## Reserve Planning

Finance and actuarial teams gain an additional signal for understanding whether historical claims severity is changing alongside the broader economic environment.

## External Risk Visibility

Claims performance is no longer viewed entirely as an internal portfolio phenomenon.

## Analytical Reliability

Correcting the grain mismatch prevents duplicated daily observations from creating misleading relationships that could influence pricing or reserving decisions.

The biggest contribution of the project is therefore not simply another KPI.

It is making sure the business is comparing the right numbers before using them to make financial decisions.

---

# What Was Built

The completed analysis includes:

* Annual Claims Aggregation
* Claims Count by Year
* Average Claim Amount by Year
* Annual Inflation Aggregation
* Annual Unemployment Aggregation
* Annual Interest Rate Aggregation
* Claims-to-Economy Comparison
* Grain Validation
* Fan-Out Correction
* External Risk Monitoring Framework

The original daily-to-yearly join was rebuilt around a common analytical grain so each reporting year appears once in the final output.

---

# Tools & Techniques

### T-SQL

The analysis targets SQL Server and Azure SQL.

### `#macro_yearly`

A temporary table reduces daily macroeconomic observations to annual averages before they are joined to claims.

### `AVG()`

Used to calculate annual averages for:

* Claim Amount
* Inflation
* Unemployment
* Interest Rates

### `COUNT()`

Measures claims volume for each reporting year alongside average severity.

### `YEAR()`

Extracts a common annual key from claim dates and macroeconomic dates.

### Pre-Aggregation

The central modeling technique in this project.

Both sides of the analysis are brought to the same grain before joining, preventing daily macroeconomic observations from multiplying annual claims records.

---

# Skills Demonstrated

This project demonstrates proficiency in:

* SQL
* T-SQL
* Insurance Analytics
* Claims Cost Analysis
* Macroeconomic Analysis
* Financial Analytics
* Pricing Analytics
* Reserve Planning Support
* Time-Based Aggregation
* Data Grain Management
* SQL Join Validation
* Fan-Out Detection
* Data Modeling
* Trend Analysis
* Analytical QA
* Business Decision Support

---

# Results

MacroRisk produces a clean annual economic and claims-cost reporting layer.

For each year, the final output returns:

```text
Year
Claim Count
Average Claim Amount
Average Inflation Rate
Average Unemployment Rate
Average Interest Rate
```

Instead of hundreds of apparent economic comparisons within the same year, each reporting period now has **one claims profile matched with one annual economic profile**.

The major technical correction was removing the daily-to-yearly join mismatch that caused claims to be repeatedly matched against daily macroeconomic observations.

The major business improvement is more important:

> **Finance and actuarial teams now have a defensible way to compare claims-cost movement with the economic environment before using that relationship to support pricing or reserve decisions.**

The analysis does not claim that inflation, unemployment, or interest rates cause changes in claims costs.

It establishes the correct analytical foundation for determining whether those relationships exist strongly enough to investigate further.

That makes MacroRisk the external-risk layer of the insurance portfolio: connecting what is happening **inside the claims book** with what is changing **outside the business**.
