# RiskPrice: Underwriting & Premium Adequacy Intelligence

**A SQL underwriting decision-support system for detecting risk-pricing mismatches, prioritizing premium reviews, validating whether underwriting risk translates into claims behavior, and measuring the portfolio's customer risk composition.**

---

## Project Overview

Insurance pricing has one fundamental job:

> **Charge enough premium for the risk the business agrees to carry.**

That sounds straightforward.

Across thousands of policies, it becomes much harder.

A high-risk policy can remain underpriced because its premium was never adjusted as risk changed. A lower-risk customer can remain overpriced and become vulnerable to a more competitive offer elsewhere. Policies can sit in underwriting review queues without anyone seeing how large that backlog has become.

The financial problem is not simply whether premiums are high or low.

It is whether **premium and risk are aligned**.

RiskPrice analyzes a simulated insurance book of **3,000 policies** and connects underwriting scores, customer risk profiles, premium levels, and claims history to answer four questions:

> **Which policies appear underpriced for their risk?**

> **Which policies should be reviewed for a premium increase, reduction, or no change?**

> **Do higher underwriting risk scores actually correspond with different claims behavior?**

> **How much of the customer base sits in each risk segment?**

The result is a pricing and underwriting review layer designed to identify where human attention should go first.

---

# Business Problem

An insurer makes a pricing decision before it knows exactly what losses a policy will eventually generate.

That means pricing has to reflect expected risk.

Consider two policies:

```text
POLICY A

Risk Score:       0.86
Annual Premium:   $700
Claims History:   Elevated
```

```text
POLICY B

Risk Score:       0.34
Annual Premium:   $1,400
Claims History:   Limited
```

Neither example automatically proves that the premium is wrong.

Coverage, product type, limits, geography, and other rating variables may explain the difference.

But both represent situations worth reviewing.

Policy A may be carrying substantial risk without enough premium.

Policy B may be priced more aggressively than its observed risk indicators suggest.

Across one or two policies, an underwriter can investigate manually.

Across 3,000 policies, the business needs a systematic way to find the exceptions.

That is the purpose of this project.

---

# The Pricing Control Framework

```text
                    INSURANCE POLICY
                           |
              -------------------------
              |                       |
              ↓                       ↓
       UNDERWRITING RISK          PREMIUM
              |                       |
              -----------   -----------
                        |   |
                        ↓   ↓
                   RISK-PRICE
                    ALIGNMENT
                        |
           ---------------------------
           |            |            |
           ↓            ↓            ↓
       UNDERPRICED    ALIGNED     REVIEW FOR
         RISK                       REDUCTION
           |            |            |
           ---------------------------
                        |
                        ↓
                  CLAIMS HISTORY
                        |
                        ↓
                 PRICING REVIEW
```

The model does not attempt to replace actuarial pricing.

It creates a **screening and prioritization layer** around the information available in the dataset.

---

# Data Sources

Four datasets support the analysis.

## `policies.csv`

Contains the commercial terms of each policy.

Key fields include:

* Policy ID
* Customer ID
* Policy Type
* Premium Amount
* Coverage Amount
* Start Date
* End Date
* Underwriting Score

---

## `customers.csv`

Provides customer-level risk and demographic context.

Key information includes:

* Customer ID
* Risk Profile
* Age
* Gender
* Location
* Income Band

Customers are classified into:

* Low Risk
* Medium Risk
* High Risk

---

## `underwriting.csv`

Contains one underwriting record per policy.

Key fields include:

* Policy ID
* Credit Score
* Health Score
* Risk Score
* Approval Status

Underwriting decisions fall into:

* Approved
* Rejected
* Review

Because this dataset contains exactly one underwriting record per policy, it can be joined at policy grain without multiplying policy records.

---

## `claims.csv`

Provides historical claims activity.

Unlike underwriting data, claims have a **one-to-many relationship** with policies.

A policy can have:

```text
0 claims
1 claim
Multiple claims
```

That distinction determines how the analytical model must be built.

---

# Methodology

The project uses a **policy-first analytical model**.

Instead of joining raw claims directly into underwriting and pricing data, claims are consolidated first.

## Step 1: Aggregate Claims

Raw claim records are reduced to one claims profile per policy.

For each policy, the model calculates the actual claims measures needed downstream.

Conceptually:

```text
CLAIM 1 ─┐
CLAIM 2 ─┼──→ POLICY CLAIM PROFILE
CLAIM 3 ─┘
```

A policy with no claims contributes zero claims.

A policy with several claims still produces one policy-level record.

---

## Step 2: Build `#policy_risk`

The claims profile is combined with:

* Policy Premium
* Customer Risk Profile
* Underwriting Risk Score
* Credit Score
* Health Score
* Approval Status

to create one reusable analytical table:

`#policy_risk`

The grain remains:

> **One row per policy**

This becomes the source for all four analytical outputs.

---

## Step 3: Detect Risk-Pricing Misalignment

Policies with combinations of elevated risk and comparatively weak premium are surfaced for review.

The objective is not to declare:

> **"This premium is definitely wrong."**

It is to identify:

> **"This policy's risk-price relationship deserves closer examination."**

That distinction matters.

A production insurance pricing model would require more variables and actuarial assumptions than are available in this dataset.

---

## Step 4: Build the Premium Review Engine

The model translates risk and premium conditions into a simple review decision.

Possible outputs include:

```text
INCREASE PREMIUM
REDUCE PREMIUM
KEEP PREMIUM
CHECK DATA
```

This converts raw underwriting information into an operational queue that pricing teams can review.

---

## Step 5: Validate Risk Against Claims Behavior

Risk scores become more useful when compared with observed outcomes.

The project therefore examines claims activity across underwriting risk levels.

The question is:

> **Do policies classified as riskier actually exhibit different claims behavior in this dataset?**

This provides a basic validation layer between predicted underwriting risk and observed claims experience.

---

## Step 6: Measure Customer Risk Composition

Finally, customers are grouped by risk profile to show how the customer base is distributed across:

* Low Risk
* Medium Risk
* High Risk

This provides portfolio-level context for underwriting exposure.

---

# Critical Finding 1: A Row Count Was Being Reported as a Claim Count

The original risk-versus-claims query used:

```sql
COUNT(*)
```

after policies had been connected to claims through a `LEFT JOIN`.

The output was labelled:

```text
claims_count
```

But that is not necessarily what `COUNT(*)` measures.

Consider a policy with no claims.

A `LEFT JOIN` preserves the policy:

```text
Policy P001 | Claim NULL
```

That is still one row.

So:

```sql
COUNT(*)
```

returns:

```text
1
```

even though the actual number of claims is:

```text
0
```

The result was a subtle overstatement of claims activity.

---

# Why the Error Matters

Suppose a risk band contains:

```text
100 policies
40 policies with claims
60 policies with no claims
```

If the analysis counts joined rows instead of actual claims, those 60 claim-free policies still contribute rows.

The resulting metric can make a lower-claims risk group appear more claims-active than it really is.

That undermines the exact comparison the query is supposed to make:

> **Does claims activity increase with underwriting risk?**

---

# Correction: Count Claims, Not Rows

Claims are now aggregated at policy level before the risk analysis begins.

The risk comparison uses the genuine per-policy claim count.

A policy with:

```text
3 claims → contributes 3
```

A policy with:

```text
0 claims → contributes 0
```

The metric now represents claims rather than the physical number of rows created by a join.

---

# Critical Finding 2: Policies Were Being Counted as Customers

The customer risk segmentation contained a similar problem.

The original query used:

```sql
COUNT(*)
```

and labelled the result as the number of customers.

But the underlying data was at policy grain.

One customer can own multiple policies.

For example:

```text
CUSTOMER 101
    |
    ├── Auto Policy
    ├── Property Policy
    └── Life Policy
```

At policy grain:

```text
Customer 101
Customer 101
Customer 101
```

creates three rows.

But there is still only:

```text
1 customer
```

Using row count would therefore make risk segments containing multi-policy customers appear larger than they really are.

---

# Correction: Count the Business Entity

The corrected analysis uses:

```sql
COUNT(DISTINCT customer_id)
```

This ensures that:

> **Customer Count = Actual Unique Customers**

rather than:

> **Customer Count = Number of Policy Rows**

It is a small SQL change with a significant analytical consequence.

Risk appetite decisions should be based on the actual customer population, not the number of policy records those customers happen to hold.

---

# Critical Finding 3: Data Quality Checks Should Come Before Pricing Decisions

The premium review engine uses `CASE` logic to classify policies.

The original version placed the missing-data condition after the pricing rules.

SQL's `NULL` behavior meant the logic still produced the expected result because comparisons involving missing values evaluated as unknown and eventually reached the fallback condition.

But that is fragile logic.

The corrected structure evaluates missing information first:

```text
DATA COMPLETE?
      |
  ----|----
  |       |
 NO      YES
  |       |
  ↓       ↓
CHECK   APPLY PRICING RULES
```

This makes the business rule explicit:

> **Do not issue a pricing recommendation when the information required to support that recommendation is incomplete.**

---

# Portfolio Risk Exposure

One of the strongest portfolio-level findings comes directly from the underwriting data.

Approximately:

> **23% of policies have an underwriting risk score of 0.80 or higher.**

That means close to one quarter of the portfolio sits in an elevated risk-score range.

This does not mean 23% of the portfolio is mispriced.

It means the high-risk population is large enough that risk-pricing alignment should be monitored systematically rather than handled as an occasional exception review.

---

# Underwriting Decision Distribution

The underwriting decision mix is also notable.

The portfolio is distributed roughly evenly across:

```text
APPROVED
REJECTED
REVIEW
```

with each representing approximately one third of policies.

The important operational signal is the size of the `Review` population.

If roughly one third of policies require review, that category is not an edge case.

It represents a major underwriting workflow.

In a real insurance operation, that would justify investigating:

* Why policies enter Review
* Average time spent in Review
* Review-to-Approval Rate
* Review-to-Rejection Rate
* Whether particular products dominate the queue
* Whether review capacity is creating underwriting delays

The available dataset supports identifying the size of the group, but not diagnosing those workflow questions without additional process data.

---

# Mispricing Intelligence

The mispricing screen focuses attention on policies where risk and premium appear poorly aligned.

The most commercially important case is:

```text
HIGH RISK
    +
RELATIVELY LOW PREMIUM
    ↓
UNDERPRICING REVIEW
```

Why?

Because pricing risk too low creates asymmetric downside.

The insurer collects limited premium while retaining potentially greater claims exposure.

But the opposite direction matters too:

```text
LOWER RISK
    +
RELATIVELY HIGH PREMIUM
    ↓
PRICING / RETENTION REVIEW
```

A lower-risk customer may be commercially attractive to competitors.

Overpricing that risk may protect short-term premium while weakening retention or competitiveness.

RiskPrice therefore treats pricing adequacy as a **two-sided problem**:

> Protect against underpricing risk.

and:

> Avoid charging more than the available risk indicators appear to justify without further review.

---

# Claims-Based Risk Validation

Underwriting scores represent expected risk.

Claims represent observed outcomes.

The analysis compares the two.

```text
UNDERWRITING
Expected Risk
      |
      ↓
RISK SCORE
      |
      ↓
CLAIMS HISTORY
      |
      ↓
Observed Behavior
```

This is useful because a risk model should eventually be evaluated against what actually happens.

If high-risk groups consistently produce greater claims activity, the segmentation may be capturing meaningful differences.

If claims behavior looks similar across every risk band, the business should investigate whether:

* Risk Scores Are Discriminating Effectively
* Claims Measures Are Appropriate
* Important Rating Variables Are Missing
* Risk Thresholds Need Review

The SQL does not establish actuarial model validity.

It provides a first diagnostic view of whether expected and observed risk appear aligned.

---

# Premium Review Engine

The rule-based engine converts policy information into a plain-language review action.

```text
                   POLICY
                      |
                      ↓
                DATA COMPLETE?
                  /       \
                NO         YES
                |           |
                ↓           ↓
              CHECK     RISK + PREMIUM
                            |
             --------------------------------
             |              |               |
             ↓              ↓               ↓
          INCREASE        KEEP           REDUCE
           REVIEW         REVIEW          REVIEW
```

The output creates a repeatable screening process across the full policy book.

It does not automatically reprice policies.

That distinction is important.

Actual premium setting may require:

* Coverage Limits
* Deductibles
* Expected Loss
* Expense Load
* Reinsurance Cost
* Product Rating Factors
* Regulatory Constraints
* Geographic Exposure
* Actuarial Pricing Models

Those variables are not all available here.

The engine should therefore be interpreted as a **premium review system**, not an automated insurance pricing model.

---

# Customer Risk Segmentation

Customer-level segmentation answers a different question from policy-level underwriting.

A policy has a risk score.

A customer may have several policies.

The corrected customer view counts unique people across:

* Low Risk
* Medium Risk
* High Risk

This provides a cleaner view of portfolio composition.

For management, that matters because the concentration of the customer base across risk bands can inform discussions around:

* Risk Appetite
* Portfolio Mix
* Underwriting Strategy
* Customer Acquisition
* Capital Planning

The current analysis provides the segmentation layer needed for those conversations without pretending that customer counts alone determine capital requirements.

---

# Business Recommendations

## 1. Make Risk-Pricing Misalignment a Recurring Review

With approximately 23% of policies carrying risk scores of `0.80+`, elevated underwriting risk is not rare enough to manage through occasional manual checks.

The mispricing screen should be run on a regular review cycle.

The goal is to detect:

```text
Risk Changes
      ↓
Pricing Misalignment
      ↓
Review
      ↓
Pricing / Underwriting Decision
```

before claims experience becomes the first signal that pricing was inadequate.

---

## 2. Investigate the Underwriting Review Queue

Roughly one third of policies fall into `Review`.

That deserves separate operational analysis.

A useful next project would measure:

* Review Volume
* Review Age
* Decision Time
* Approval Rate
* Rejection Rate
* Product Mix
* Risk Score Distribution

A large review queue may be appropriate.

It may also indicate that underwriting rules are sending too many borderline cases into manual processing.

The current data cannot determine which explanation is correct.

---

## 3. Monitor Expected Risk Against Actual Claims

Risk segmentation should not remain disconnected from claims performance.

A recurring validation report should compare:

```text
Risk Score
    ↓
Claim Frequency
    ↓
Claim Severity
    ↓
Loss Experience
```

over time.

That creates a feedback loop between underwriting expectations and actual portfolio behavior.

---

## 4. Separate Screening From Pricing Authority

The SQL output should determine:

> **Which policies require attention?**

It should not determine:

> **What exact premium should be charged?**

That second decision requires a fuller actuarial pricing framework.

Keeping those responsibilities separate makes the system useful without overstating what the available data can support.

---

# Business Value

RiskPrice creates value across four areas.

## Pricing Discipline

Policies where premium appears weak relative to risk become visible before poor claims performance is the only warning signal.

## Underwriting Prioritization

Underwriters receive a structured review population instead of searching thousands of policies manually.

## Portfolio Risk Visibility

Management can see how much of the policy book sits in elevated underwriting risk bands and how customers are distributed across risk profiles.

## Risk Validation

Claims history provides an observed-outcome layer for checking whether underwriting risk categories correspond with materially different behavior.

Together, these move the business from:

> **"What premium are we charging?"**

to:

> **"Does the price make sense for the risk we are accepting?"**

---

# What Was Built

The completed analysis includes:

* Policy-Level Risk Model
* Claims Aggregation Layer
* Risk-Pricing Misalignment Screen
* Premium Review Engine
* Risk Score vs. Claims Analysis
* Customer Risk Segmentation
* Underwriting Decision Analysis
* High-Risk Portfolio Exposure
* Corrected Claim Counting
* Corrected Customer Counting
* Missing-Data Safeguards

All four analytical outputs operate from a single policy-grain model to maintain consistent logic across the project.

---

# Tools & Techniques

### T-SQL

The analysis targets SQL Server and Azure SQL.

### `#policy_risk`

A reusable temporary table consolidates premium, underwriting, customer risk, and aggregated claims information at one row per policy.

### Pre-Aggregation

Claims are consolidated before joining to the analytical model, preventing one-to-many relationships from distorting downstream metrics.

### `COUNT(DISTINCT ...)`

Used when the business question requires actual unique customers rather than policy-level rows.

### `CASE`

Powers the premium review engine and converts analytical conditions into business-readable actions.

### Conditional Aggregation

Supports portfolio comparisons across risk and underwriting categories.

### Analytical Grain Control

Policy, claim, and customer counts are deliberately separated so each KPI measures the entity its label claims to represent.

---

# Skills Demonstrated

This project demonstrates proficiency in:

* SQL
* T-SQL
* Insurance Analytics
* Underwriting Analytics
* Insurance Pricing Analytics
* Risk Segmentation
* Premium Adequacy Screening
* Claims Analysis
* Portfolio Risk Analysis
* Customer Risk Analysis
* Rule-Based Decision Systems
* Data Modeling
* Analytical Grain Management
* SQL Debugging
* KPI Validation
* Decision Support

---

# Results

RiskPrice delivers four core decision outputs from the insurance book.

### Mispricing Watchlist

Surfaces policies where premium and underwriting risk appear materially misaligned and prioritizes them for review.

### Premium Review Engine

Classifies policies into clear review actions:

```text
Increase
Reduce
Keep
Check
```

without presenting the rules as a replacement for actuarial pricing.

### Risk vs. Claims Intelligence

Compares underwriting risk with genuine claims activity after correcting the original row-counting problem.

### Customer Risk Composition

Measures the actual number of unique customers across risk segments instead of incorrectly treating policy rows as people.

The underlying portfolio also surfaces two important management signals:

> **Approximately 23% of policies carry underwriting risk scores of 0.80 or higher.**

and:

> **Approved, Rejected, and Review decisions each account for roughly one third of underwriting records.**

Together, the analysis provides a structured way to answer:

> **Where does premium appear weak relative to risk?**

> **Which policies deserve pricing review first?**

> **Does observed claims behavior support the underwriting risk segmentation?**

> **How much of the portfolio sits in elevated risk bands?**

> **And how large is the customer population represented by each risk profile?**

The result is not an automated pricing model.

It is a **risk-pricing control and underwriting review system** built to help an insurer find pricing exceptions, prioritize review work, and test whether the risk being accepted is reflected in both premium and subsequent claims behavior.
