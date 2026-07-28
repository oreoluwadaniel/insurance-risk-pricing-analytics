# FraudWatch: Claims Investigation & Risk Triage

**A SQL fraud operations system for converting anomaly signals across 3,000 insurance claims into a ranked investigation queue, measuring fraud exposure, and identifying geographic concentrations that may require deeper investigation.**

---

## Project Overview

Fraud detection is only useful if someone can act on what gets detected.

An insurance company processing thousands of claims cannot investigate every case manually. Even if an automated system produces an anomaly score for every claim, investigators still face a practical problem:

> **Which claims should we investigate first?**

A second problem follows:

> **Are suspicious and flagged claims randomly distributed, or concentrated in particular parts of the business?**

FraudWatch addresses both.

The project connects claims with pre-existing fraud signals to create an investigation watchlist, then traces flagged fraud through policies and customers to identify geographic concentrations.

Across **3,000 claims**, the analysis found:

* **583 claims** with anomaly scores of `0.80` or higher
* **299 claims** carrying the dataset's fraud flag
* Approximately **19.4%** of claims entering the anomaly-based watchlist
* Approximately **10.0%** carrying the fraud flag

The important question is not simply how many suspicious claims exist.

It is how to turn those signals into a manageable investigation process.

---

# Business Problem

Fraud teams operate under a capacity constraint.

Suppose an insurer receives 3,000 claims.

Reviewing all 3,000 manually would waste investigation time on large numbers of ordinary claims.

But ignoring automated fraud signals creates the opposite problem: potentially suspicious cases move through the claims process without receiving appropriate scrutiny.

The business therefore needs to move from:

```text
3,000 CLAIMS
      ↓
Manual Review
      ↓
Too Much Investigation Work
```

to:

```text
3,000 CLAIMS
      ↓
Fraud Signals
      ↓
Risk Screening
      ↓
Ranked Watchlist
      ↓
Investigator Review
```

The SQL layer sits between automated detection and human investigation.

It does not determine whether fraud occurred.

It determines **which claims deserve investigation attention based on the available signals.**

---

# Business Questions

The project focuses on four operational questions.

### Investigation Priority

Which claims carry the strongest anomaly signals and should appear first in the investigation queue?

### Watchlist Size

How much of the total claims population crosses the current anomaly threshold?

### Signal vs. Fraud Flag

How does the number of claims identified by anomaly screening compare with the number carrying the dataset's fraud flag?

### Geographic Concentration

Where are fraud-flagged claims concentrated across the customer base?

Together, these turn fraud data into an operational investigation view rather than a collection of disconnected scores.

---

# Data Sources

Four datasets support the analysis.

## `claims.csv`

Contains the core claims record.

Key fields include:

* Claim ID
* Policy ID
* Claim Amount
* Claim Date
* Claim Type
* Settlement Amount
* Fraud Flag

The dataset contains **3,000 claims**.

---

## `fraud_signals.csv`

Contains the fraud indicators associated with each claim.

Key fields include:

* Claim ID
* Anomaly Score
* Network Flag
* Fraud Reason

There are also **3,000 fraud signal records**, with every claim represented in the fraud signal table.

That creates a clean:

```text
CLAIM
  ↕
FRAUD SIGNAL
```

**one-to-one relationship.**

This matters because no pre-aggregation is required before the two tables can be joined safely.

---

## `policies.csv`

Connects each claim to the policy under which it was submitted.

Its role in this project is primarily relational:

```text
Claim → Policy
```

---

## `customers.csv`

Connects the policy to the customer and provides the location used in the geographic fraud analysis.

The full relationship becomes:

```text
CLAIM
   ↓
POLICY
   ↓
CUSTOMER
   ↓
LOCATION
```

---

# Investigation Framework

FraudWatch separates **detection signals** from **investigation decisions**.

```text
                    CLAIM
                      |
          -------------------------
          |                       |
          ↓                       ↓
     CLAIM DETAILS           FRAUD SIGNALS
                                  |
                       -----------------------
                       |          |          |
                       ↓          ↓          ↓
                    ANOMALY    NETWORK     FRAUD
                     SCORE      FLAG       REASON
                       |
                       ↓
                 RISK SCREENING
                       |
                       ↓
               INVESTIGATION QUEUE
                       |
                       ↓
                 HUMAN REVIEW
```

The anomaly score identifies claims worth reviewing.

It does not prove fraud.

That distinction is fundamental to how the results should be interpreted.

---

# Methodology

Unlike the previous insurance projects, this analysis did not require rebuilding the source model.

The joins were already structurally sound.

The work therefore focused on **verification, prioritization, and usability**.

---

## Step 1: Validate Claim Coverage

Before using the fraud signals, the analysis checks that:

* Claims contain 3,000 records
* Fraud signals contain 3,000 records
* Every claim has a corresponding fraud signal

This confirms that the fraud screening layer covers the full claims population represented in the dataset.

---

## Step 2: Verify Join Integrity

The first relationship is:

```text
claims
   ↓
fraud_signals
```

joined through `claim_id`.

Because the relationship is one-to-one, one claim remains one claim after the join.

This prevents the row multiplication problems identified elsewhere in the insurance portfolio.

---

## Step 3: Build the Investigation Watchlist

Claims with:

```text
Anomaly Score >= 0.80
```

are selected and ranked from highest anomaly score downward.

The output includes additional investigation context such as:

* Claim Type
* Anomaly Score
* Network Flag
* Fraud Reason

rather than returning only an ID and score.

This turns the output from a technical query result into a more useful investigation queue.

---

## Step 4: Measure Fraud Concentration

Fraud-flagged claims are traced through:

```text
Claim
  ↓
Policy
  ↓
Customer
  ↓
Location
```

and aggregated geographically.

The purpose is to determine whether flagged fraud appears evenly distributed or concentrated in particular locations.

---

# Data Integrity Review

One important outcome of this project is that the original analytical structure was already correct.

That is worth documenting.

Not every review needs to discover a bug.

The important question is whether the logic was actually tested.

---

## One Claim, One Fraud Signal

The claims and fraud signal tables both contain 3,000 rows, and the claim identifiers match one-to-one.

That means:

```text
1 Claim
   +
1 Fraud Signal
   =
1 Analytical Record
```

No claims aggregation is required before joining.

---

## Geographic Join Verified

The geographic analysis follows:

```text
claims.policy_id
        ↓
policies.policy_id

policies.customer_id
        ↓
customers.customer_id
```

Under the structure of this dataset, each claim points to one policy and each policy points to one customer.

The join therefore preserves claim grain.

As a result, using `COUNT(*)` in the location rollup represents an actual count of qualifying claim records rather than a count inflated by join fan-out.

---

# Investigation Usability Improvement

The main change was not a mathematical correction.

It was making the output more useful to the person expected to act on it.

A result like:

```text
CLM00192 | 0.94
```

tells an investigator very little.

The improved watchlist includes supporting context:

```text
Claim ID
Claim Type
Anomaly Score
Network Flag
Fraud Reason
```

Now the investigator receives both:

> **How suspicious does this claim appear?**

and:

> **What signal contributed context for the review?**

This reduces the gap between analytical output and operational use.

---

# Key Finding: The Watchlist Is Large

Using the current threshold:

```text
Anomaly Score >= 0.80
```

the model identifies approximately:

> **583 of 3,000 claims**

for investigation review.

That is approximately:

> **19.4% of the entire claims population.**

Or roughly:

> **1 in every 5 claims.**

That is a substantial review population.

If the objective is broad screening, that may be acceptable.

If the objective is a short queue for a small investigations team, it may be operationally expensive.

The threshold therefore needs to be evaluated against investigation capacity, not selected solely because `0.80` sounds like a high score.

---

# Fraud Flag Baseline

Separately, the dataset contains:

> **299 fraud-flagged claims out of 3,000**

or approximately:

> **10.0% of claims.**

This creates an important comparison:

```text
Anomaly Watchlist        Fraud Flag

583 claims               299 claims
19.4%                    ~10.0%
```

The anomaly threshold surfaces a considerably broader population than the fraud flag.

That does not automatically mean the anomaly model is generating too many false positives.

It means the two measures represent different stages or signals in the fraud process.

---

# Detection Is Not Confirmation

The distinction between these numbers matters.

An anomaly score indicates that a claim looks unusual according to whatever detection process generated the score.

A fraud flag represents a separate field in the claims data.

Without additional information about how `fraud_flag` was generated, its timing, and whether it represents confirmed investigation outcomes, the analysis should not treat it automatically as a perfect ground-truth label.

What the data does support is this:

```text
3,000 Claims
      |
      ↓
583 Cross Anomaly Threshold
      |
      ↓
Broader Investigation Population


3,000 Claims
      |
      ↓
299 Carry Fraud Flag
      |
      ↓
Separate Fraud-Flagged Population
```

Understanding how much those two groups overlap would be an important next validation step.

---

# Why Threshold Selection Matters

A fraud threshold creates a trade-off.

Lower the threshold:

```text
More Claims Flagged
        ↓
Potentially More Suspicious Cases Captured
        ↓
More Investigation Work
```

Raise the threshold:

```text
Fewer Claims Flagged
        ↓
Smaller Investigation Queue
        ↓
Potentially Greater Risk of Missing Relevant Cases
```

There is no universally correct threshold.

The right threshold depends on factors such as:

* Investigation Capacity
* Cost of Manual Review
* Cost of Missed Fraud
* Signal Precision
* Fraud Prevalence
* Claim Value
* Risk Appetite

The current `0.80` threshold should therefore be treated as an operating assumption to evaluate, not a permanent business rule.

---

# Geographic Fraud Intelligence

The second output identifies locations with the highest concentration of fraud-flagged claims.

This adds another layer to investigation prioritization.

Instead of asking only:

> **Which claim looks suspicious?**

the business can also ask:

> **Where are flagged cases appearing most frequently?**

Repeated concentration in one area may justify further investigation into:

* Regional Claims Patterns
* Provider or Repair Networks
* Agent or Broker Activity
* Customer Networks
* Local Processing Practices
* Data Quality Issues

The SQL identifies concentration.

It does not establish the cause of that concentration.

That requires further investigation.

---

# From Fraud Scores to Investigation Operations

The analysis supports a simple triage workflow:

```text
ALL CLAIMS
    |
    ↓
FRAUD SIGNALS
    |
    ↓
ANOMALY SCREEN
    |
    ↓
RANKED WATCHLIST
    |
    ↓
INVESTIGATOR REVIEW
    |
    ↓
INVESTIGATION OUTCOME
    |
    ↓
FEEDBACK INTO FRAUD CONTROLS
```

The final step is especially important in a production system.

Investigation outcomes should eventually feed back into threshold evaluation and model monitoring.

Otherwise the business keeps generating fraud scores without learning whether those scores actually help investigators find fraud.

---

# Business Recommendations

## 1. Replace a Single Watchlist With Investigation Tiers

A flat list of 583 claims may still be too broad.

A stronger operational design would divide claims into priority tiers.

For example:

```text
CRITICAL
Highest anomaly signals
Immediate review

HIGH
Strong signals
Priority queue

MODERATE
Requires additional evidence

LOW
Routine claims processing
```

The exact thresholds should be determined from validated investigation outcomes rather than chosen arbitrarily.

This would make staffing and case allocation more practical.

---

## 2. Validate the `0.80` Threshold

Before adopting `0.80` operationally, compare it with alternative thresholds such as `0.90`.

The business question is not:

> **Which threshold produces the highest-looking score?**

It is:

> **Which threshold gives investigators the strongest workable queue without excluding too many relevant cases?**

That requires comparing threshold performance against actual investigation outcomes.

---

## 3. Measure Watchlist-to-Fraud-Flag Overlap

The next analytical step should determine:

```text
Of the 583 anomaly-screened claims,
how many also carry fraud_flag?
```

That produces a much stronger view of how the two fraud indicators relate.

A production version could then measure metrics such as:

* Flag Rate by Anomaly Band
* Investigation Yield
* False Positive Rate
* Precision
* Recall

provided a reliable confirmed-fraud outcome exists.

---

## 4. Prioritize by Exposure, Not Score Alone

Anomaly score tells the team how unusual a claim appears.

It does not tell them the financial exposure.

A production prioritization system should combine fraud signals with claim value.

For example:

```text
HIGH ANOMALY + HIGH CLAIM VALUE
              ↓
        HIGH PRIORITY
```

may deserve more immediate attention than:

```text
HIGH ANOMALY + LOW CLAIM VALUE
```

depending on the insurer's investigation strategy.

This turns fraud detection into **risk-based case prioritization** rather than score sorting.

---

## 5. Monitor Geographic Concentration

The geographic rollup should become a recurring fraud operations metric.

Locations showing persistent concentration can then be investigated against other dimensions such as:

* Claim Type
* Fraud Reason
* Policy Type
* Network Flag
* Claim Amount

The goal is to move from:

> **Fraud is high here**

to:

> **What specifically is driving the concentration here?**

---

# Business Value

FraudWatch creates value by improving how limited investigation resources are allocated.

## Investigation Efficiency

Instead of reviewing 3,000 claims equally, investigators receive a ranked population based on existing fraud signals.

## Financial Risk Prioritization

The framework can be extended to combine anomaly strength with claim exposure so investigation effort follows potential financial impact.

## Fraud Pattern Visibility

Geographic aggregation helps identify where flagged claims are concentrated rather than treating every claim as an isolated incident.

## Threshold Governance

Showing that the current threshold captures approximately 19.4% of all claims forces an important operational question:

> **Can the investigation team realistically work this queue?**

That connects analytics directly to staffing and investigation capacity.

---

# What Was Built

The final analysis includes:

* Fraud Signal Validation
* Claim-to-Signal Relationship Verification
* Anomaly-Based Claims Watchlist
* Risk Ranking
* Claim-Type Context
* Fraud-Reason Context
* Network Flag Visibility
* Fraud-Flag Baseline Analysis
* Geographic Fraud Concentration
* Investigation Prioritization Framework

Unlike Parts 1 and 2, no structural fan-out bug had to be corrected.

The original joins were verified against the underlying relationships and found to preserve the correct analytical grain.

---

# Tools & Techniques

### T-SQL

The project targets SQL Server and Azure SQL.

### `INNER JOIN`

Used where every qualifying claim requires a corresponding fraud signal or related policy/customer record.

Because the relationships were verified before analysis, these joins preserve claim-level grain.

### `WHERE`

Applies the anomaly threshold used to create the investigation watchlist.

### `ORDER BY`

Ranks claims from highest anomaly score downward so the output functions as a priority queue rather than an unordered list.

### `GROUP BY`

Aggregates fraud-flagged claims by customer location to surface geographic concentration.

### `COUNT(*)`

Used safely in the geographic analysis after verifying that each qualifying analytical row represents one claim.

---

# Skills Demonstrated

This project demonstrates proficiency in:

* SQL
* T-SQL
* Insurance Fraud Analytics
* Claims Analytics
* Anomaly Detection Analysis
* Fraud Investigation Prioritization
* Risk Triage
* Fraud Operations
* Geographic Risk Analysis
* Threshold Analysis
* Data Relationship Validation
* Analytical Grain Validation
* KPI Development
* Operational Decision Support
* Data-to-Action Translation

---

# Results

FraudWatch converts the insurance claims dataset into two primary operational outputs.

### Investigation Watchlist

Approximately **583 of 3,000 claims**, or **19.4%**, cross the current anomaly threshold of `0.80`.

Claims are ranked from highest anomaly score downward and accompanied by supporting investigation context.

### Geographic Fraud View

Claims carrying the fraud flag are grouped by customer location and ranked by concentration, providing an additional dimension for allocating investigative attention.

Across the complete dataset:

> **583 claims cross the anomaly threshold.**

> **299 claims carry the fraud flag.**

> **Approximately 1 in 5 claims enters the anomaly-based watchlist.**

> **Approximately 1 in 10 claims carries the dataset's fraud flag.**

Those numbers reveal the central operational challenge of the project:

The business does not simply need fraud detection.

It needs a system for deciding **which signals deserve scarce investigation time first**.

The result is a **claims investigation and fraud triage system** that transforms raw anomaly signals into a prioritized review process while preserving an important distinction:

> **A suspicious claim is a reason to investigate, not proof of fraud.**
