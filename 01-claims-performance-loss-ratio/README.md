# Claims Performance & Loss Ratio Intelligence

**A SQL portfolio analytics system for measuring claims exposure against premium, identifying loss-making policies and customer relationships, and detecting product lines where claims performance may require pricing or underwriting review.**

---

## Project Overview

Insurance growth is only valuable when the economics behind that growth work.

More policies create more premium.

They also create more exposure to claims.

A portfolio can therefore grow in customers, policies, and premium while becoming less financially attractive if claims costs rise faster than the premium supporting them.

The problem is that portfolio-level totals can hide where that deterioration is happening.

One policy may have already paid out substantially more than its premium.

One customer may hold several policies that look reasonable individually but become loss-heavy when their total relationship is evaluated.

An entire product line may generate significant premium while carrying a materially higher loss ratio than the rest of the portfolio.

This project builds a **claims performance and loss ratio intelligence layer** across a simulated insurance book containing **3,000 policies and 3,000 claims**.

It answers three connected questions:

> **Which policies are generating the greatest claims exposure relative to premium?**

> **Which customer relationships have claims costs exceeding the premium associated with their policies?**

> **Which insurance product lines show the weakest claims performance across the portfolio?**

The objective is not simply to calculate loss ratio.

It is to show **where claims pressure is concentrated and where deeper pricing or underwriting review should begin.**

---

# Business Problem

Premium volume is one of the easiest insurance metrics to celebrate.

But premium without claims context tells only half the financial story.

Consider two policies:

```text
POLICY A

Premium:           $4,000
Claims Settled:      $800
Loss Ratio:           20%
```

```text
POLICY B

Premium:           $4,000
Claims Settled:    $5,200
Loss Ratio:          130%
```

Both generated the same premium.

Their claims performance is completely different.

The same problem exists at higher levels of the portfolio.

A customer may hold several policies.

A product line may contain hundreds of policies.

A strong portfolio average can therefore hide pockets of significantly higher claims exposure.

Management needs the ability to move from:

```text
Portfolio
   ↓
Product Line
   ↓
Customer
   ↓
Policy
```

and identify exactly where claims are consuming the premium supporting the book.

---

# Business Questions

The analysis focuses on three levels of claims performance.

### Policy Level

Which individual policies have the highest claims-to-premium exposure?

### Customer Level

Which customer relationships have generated more settled claims than the premium associated with their policies?

### Product Level

Which insurance lines carry the highest overall loss ratios?

Together, these provide three different views of the same financial question:

> **Where is claims performance putting the greatest pressure on the insurance book?**

---

# Data Sources

The analysis uses two core datasets.

## `policies.csv`

Contains one row per insurance policy.

Key fields include:

* Policy ID
* Customer ID
* Policy Type
* Premium Amount
* Coverage Amount
* Policy Start Date
* Policy End Date
* Underwriting Score

The dataset covers **3,000 policies** across multiple insurance product lines, including:

* Auto
* Property
* Life
* Health

---

## `claims.csv`

Contains one row per claim.

Key fields include:

* Claim ID
* Policy ID
* Claim Amount
* Claim Date
* Claim Type
* Fraud Flag
* Settlement Amount

The dataset contains **3,000 individual claims**.

Importantly:

> **One policy can have zero, one, or multiple claims.**

Some policies have no claims.

Others have several.

One policy in the dataset carries four separate claim records.

That relationship is central to the analytical design of this project.

---

# Claims Performance Model

The project follows a simple financial relationship:

```text
                  PREMIUM
                     |
                     ↓
                  POLICY
                     |
                     ↓
                   CLAIMS
                     |
                     ↓
              SETTLEMENT COST
                     |
                     ↓
                 LOSS RATIO
                     |
          -------------------------
          |           |           |
          ↓           ↓           ↓
       POLICY      CUSTOMER     PRODUCT
       REVIEW       REVIEW       REVIEW
```

Claims are first consolidated at policy level before any premium comparison occurs.

That ordering prevents one of the most dangerous errors in insurance aggregation: **duplicating premium because one policy has multiple claims.**

---

# Core Metric: Loss Ratio

The primary metric is:

```text
Loss Ratio
=
Total Claims Settled
────────────────────
Total Premium
```

For example:

```text
Premium:          $10,000
Claims Settled:    $7,500

Loss Ratio = 0.75
```

or **75%**.

A higher ratio means more of the premium associated with the policy or portfolio segment has been consumed by settled claims.

A ratio above `1.0` means:

```text
Settled Claims > Premium
```

for the scope being measured.

That makes it a useful **review signal**, but not automatic proof that a policy, customer, or product is commercially unprofitable.

The available data does not include the full expense structure needed to calculate underwriting profit, such as acquisition costs, operating expenses, commissions, reserves, or reinsurance.

This project therefore measures **claims performance and premium adequacy signals**, not complete insurance profitability.

---

# Methodology

The analysis is deliberately built at the lowest reliable financial grain first.

## Step 1: Validate the Source Tables

Before calculating any insurance KPI, the script confirms that the policy and claims datasets loaded correctly.

This provides a basic control before downstream financial calculations begin.

---

## Step 2: Aggregate Claims to Policy Level

Claims are first consolidated into:

`#policy_claims`

For each policy, the model calculates:

* Number of Claims
* Total Settlement Amount
* Average Claim Size

The result is:

```text
Many Claim Records
        ↓
One Policy Claims Record
```

This establishes one row per policy before premium enters the calculation.

---

## Step 3: Build Policy Financials

The aggregated claims layer is then joined to the policy table to create:

`#policy_financials`

This combines:

* Policy Premium
* Coverage
* Product Type
* Customer
* Claim Count
* Total Settlement
* Average Claim Size
* Loss Ratio

Because claims were already aggregated, every policy premium appears exactly once.

---

## Step 4: Analyze Three Levels of Exposure

The policy financial layer is then used for:

```text
POLICY PERFORMANCE
        ↓
Which policies carry the highest loss ratios?


CUSTOMER EXPOSURE
        ↓
Which customer relationships generate the greatest claims pressure?


PRODUCT-LINE PERFORMANCE
        ↓
Which insurance products carry the highest overall loss ratios?
```

This creates a consistent financial foundation across all three levels.

---

# Critical Finding: Premium Was Being Double-Counted

The most important issue identified during review was not a syntax error.

The original SQL ran.

The problem was that its financial totals could be wrong.

The original model joined:

```text
POLICIES
    |
    ↓
CLAIMS
```

before aggregating premium.

That is unsafe because the relationship is one-to-many.

Consider one policy:

```text
Policy ID:        P1001
Premium:          $4,000
```

with three claims:

```text
Claim 1
Claim 2
Claim 3
```

A direct join produces:

```text
P1001 | $4,000 | Claim 1
P1001 | $4,000 | Claim 2
P1001 | $4,000 | Claim 3
```

The policy still generated only:

```text
$4,000
```

of premium.

But:

```sql
SUM(premium_amount)
```

on the joined dataset returns:

```text
$12,000
```

The premium has been counted three times.

---

# Why This Matters

This is not a cosmetic data issue.

It changes the business conclusion.

Suppose the three claims produced:

```text
Total Settlements: $5,000
Actual Premium:    $4,000
```

The correct loss ratio is:

```text
$5,000 / $4,000 = 1.25
```

or **125%**.

The policy has generated settled claims exceeding its premium.

Using the duplicated premium:

```text
$5,000 / $12,000 = 0.417
```

or approximately **41.7%**.

The exact same policy can therefore appear relatively healthy instead of claims-heavy purely because of a join error.

That is why analytical grain matters in financial SQL.

---

# Correction: Aggregate First, Join Second

The corrected model reverses the order.

Instead of:

```text
POLICIES
    ↓
CLAIMS
    ↓
AGGREGATE
```

the project uses:

```text
CLAIMS
    ↓
AGGREGATE BY POLICY
    ↓
ONE CLAIMS RECORD PER POLICY
    ↓
JOIN TO POLICIES
```

The resulting structure is:

```text
Policy ID | Premium | Claim Count | Total Settlement
-----------------------------------------------------
P1001     | $4,000  |      3      | $5,000
```

Now premium appears once regardless of whether the policy has:

* 0 claims
* 1 claim
* 4 claims
* 20 claims

That makes customer and product-level aggregation financially consistent.

---

# Second Correction: No Claims Should Mean Zero Claims

The original calculation also produced `NULL` loss ratios for policies without claims.

But:

```text
No Claims ≠ Missing Claims Data
```

If a policy has premium but no recorded claims, the claims total for this analysis is zero.

The corrected logic uses `ISNULL()` so a claim-free policy returns:

```text
Total Settlement = 0
Loss Ratio        = 0
```

rather than a blank value that could be mistaken for missing information.

`NULLIF()` is also used to protect the calculation where premium is zero.

---

# Policy-Level Claims Intelligence

The first output ranks policies by loss ratio.

This surfaces policies where claims have consumed the greatest share of premium.

A high-loss-ratio policy becomes a candidate for investigation into factors such as:

* Claims History
* Underwriting Score
* Coverage Structure
* Pricing Adequacy
* Renewal Terms

The purpose is not to automatically penalize a policy after one bad claim.

Insurance exists specifically because losses occur.

The purpose is to make unusual or sustained claims exposure visible.

---

# Customer-Level Exposure

Policy-level analysis can miss an important commercial pattern.

One customer may hold multiple policies.

Individually, none may appear extreme.

Together, the relationship may carry significantly greater claims exposure.

The customer-level analysis aggregates:

```text
All Customer Policies
        +
All Associated Premium
        +
All Associated Settlements
        ↓
Customer Claims Performance
```

This helps identify customer relationships where total settlements exceed total premium across the policies represented in the dataset.

That gives underwriting and account teams a broader view than reviewing policies independently.

---

# Product-Line Claims Performance

The highest management-level view compares performance across:

* Auto
* Property
* Life
* Health

For each product type, the analysis evaluates total premium against total settled claims.

This helps answer:

> **Are claims pressures isolated to individual policies, or concentrated across an entire insurance product?**

That distinction changes the response.

One unusual policy may require individual review.

A product line consistently carrying weaker claims performance may require investigation into:

* Pricing Assumptions
* Underwriting Criteria
* Coverage Terms
* Claims Severity
* Customer Mix

That is a portfolio problem rather than an isolated claim problem.

---

# From Monitoring to Action

The outputs support a review hierarchy:

```text
HIGH LOSS RATIO
      |
      ↓
Isolated Policy?
      |
      ├── YES → Policy Review
      |
      ↓ NO
Customer Pattern?
      |
      ├── YES → Customer / Account Review
      |
      ↓ NO
Product Pattern?
      |
      └── YES → Pricing & Underwriting Review
```

This prevents every high ratio from being treated as the same problem.

---

# Business Recommendations

## 1. Create a Loss Ratio Review Queue

Policies and customers where settled claims exceed premium should move into a structured review queue.

That review should consider the wider underwriting context before any decision is made.

The metric identifies where to investigate.

It should not make the underwriting decision itself.

---

## 2. Review Product Lines Separately

If one insurance line consistently produces a higher loss ratio than the rest of the portfolio, investigate that product specifically.

A portfolio-wide premium increase would be a weak response if the claims problem is concentrated in one line.

The review should examine:

* Pricing
* Coverage
* Underwriting Criteria
* Claims Severity
* Risk Mix

at product level.

---

## 3. Track Claims Performance Over Time

The current analysis provides a portfolio performance view from the available records.

A production version should extend this into periodic monitoring.

For example:

```text
Monthly Loss Ratio
      ↓
Quarterly Trend
      ↓
Product Movement
      ↓
Customer / Policy Drill-Down
```

This would help identify deterioration earlier instead of discovering it after substantial claims exposure has accumulated.

---

## 4. Add Full Underwriting Economics

Loss ratio is only one component of insurance profitability.

A stronger profitability model should eventually include:

* Acquisition Costs
* Commissions
* Operating Expenses
* Claims Handling Costs
* Reinsurance
* Reserves

That would allow the analysis to progress from:

> **Claims Performance**

to:

> **Underwriting Profitability**

---

# Business Value

The project provides value at three levels.

## Portfolio Visibility

Management can see whether claims exposure is concentrated in particular policies, customers, or products instead of relying only on portfolio totals.

## Pricing & Underwriting Prioritization

Teams receive a ranked starting point for reviewing areas where claims have consumed unusually high amounts of premium.

## Financial Accuracy

Correcting the one-to-many join problem prevents duplicated premium from making loss ratios appear artificially stronger.

That last point is critical.

Bad financial reporting does not always produce obviously absurd numbers.

Sometimes it produces believable numbers that lead to the wrong decision.

This project specifically protects against that failure mode.

---

# What Was Built

The final analysis includes:

* Policy-Level Claims Aggregation
* Policy-Level Loss Ratio Analysis
* Customer Claims Exposure Analysis
* Product-Line Loss Ratio Analysis
* Claim Count per Policy
* Average Claim Size
* Claim-Free Policy Handling
* Divide-by-Zero Protection
* One-to-Many Join Correction
* Ranked Review Outputs

All three original business questions remain intact, but they now operate on a corrected policy-grain financial model.

---

# Tools & Techniques

### T-SQL

The project targets SQL Server and Azure SQL.

### Temporary Tables

`#policy_claims` and `#policy_financials` separate claims aggregation from policy-level financial analysis.

This makes the analytical grain explicit and prevents premium duplication.

### `GROUP BY`

Aggregates multiple claim records into one policy-level claims profile.

### `ISNULL()`

Converts legitimate no-claim cases into zero instead of leaving misleading blank values.

### `NULLIF()`

Protects financial ratios against division by zero.

### Aggregate-Then-Join Pattern

The most important modeling technique in the project.

One-to-many claims data is consolidated before being joined to policy-level financial values.

This ensures premium is counted exactly once per policy.

---

# Skills Demonstrated

This project demonstrates proficiency in:

* SQL
* T-SQL
* Insurance Analytics
* Claims Analytics
* Loss Ratio Analysis
* Portfolio Performance Analysis
* Financial Analytics
* Insurance Risk Analysis
* Data Modeling
* One-to-Many Relationship Management
* Analytical Grain Control
* SQL Debugging
* Financial Metric Validation
* KPI Development
* Data Quality Handling
* Business Decision Support

---

# Results

The completed system produces three decision-ready views of claims performance:

### Policy View

Ranks policies by claims exposure relative to premium and surfaces individual policies requiring closer review.

### Customer View

Identifies customer relationships where total settled claims exceed the total premium associated with their policies.

### Product View

Compares loss ratios across insurance product lines to identify where claims pressure is concentrated at portfolio level.

More importantly, the analysis corrects a structural issue that could materially change those conclusions.

Premium is no longer duplicated when a policy has multiple claims.

Claim-free policies correctly report zero claims exposure instead of appearing as missing data.

The final model therefore provides a financially consistent foundation for answering:

> **Where are claims consuming premium?**

> **Is the problem isolated to individual policies or customers?**

> **Is claims pressure concentrated in a particular product line?**

> **And where should underwriting or pricing teams investigate first?**

The result is not simply a loss ratio calculation.

It is a **claims performance monitoring and portfolio review system** designed to help an insurer identify where claims exposure is putting pressure on the book, while preserving the analytical grain required for those decisions to be trusted.
