# Insurance Risk, Pricing & Profitability Analytics

A SQL portfolio built around one question:

> **Is the insurance book making money for the risk it is taking?**

Four case studies use a simulated portfolio of **3,000 policies and 3,000 claims** to examine profitability, pricing, fraud triage and economic exposure.

Three of the four produced a working measurement. Two produced a negative result, and those are published as findings rather than quietly dropped.

## The four business questions

| Case study | Business question | Decision supported |
|---|---|---|
| [01. Claims Performance & Loss Ratio](01-claims-performance-loss-ratio/) | Are premiums covering claims exposure? | Identify weak products, customers and segments |
| [02. Underwriting & Pricing](02-underwriting-risk-pricing-engine/) | Does premium reflect the risk being accepted? | Flag policies for pricing or underwriting review |
| [03. Fraud Detection](03-fraud-detection-investigation/) | Which claims deserve investigation first? | Prioritise limited investigation capacity |
| [04. Macroeconomic Claims](04-macroeconomic-claims-cost/) | Are economic conditions changing claims costs? | Support pricing, reserving and planning discussions |

## Headline results

- **1,861 of 3,000 policies carry at least one claim**, 62.0% of the book. 1,827 policies settled more than they were charged.
- **Relative loss ratio ranks the lines Health, Life, Property, Auto**, weakest to strongest, across a narrow spread. Nothing here points at one problem product.
- **Premium does not track assessed risk.** Across the 1,901 policies with an underwriting record, the correlation between risk score and premium charged is **-0.037**.
- **Neither fraud signal ranks fraud.** The top 300 claims by anomaly score contain 32 flagged cases against the 27.8 a random draw would return. The network flag points slightly the wrong way.
- **No macroeconomic relationship is detectable**, and with seven annual observations none could be.

## The two join controls everything rests on

Before any measure was written, every join key was profiled. Two problems turned up, and either one would have produced a report that looked correct and was wrong throughout.

**1. Claims sit at a different grain from policies.** 3,000 claims spread across 1,861 distinct policies. Joining raw multiplies premium across every policy carrying more than one claim, and understates loss ratio in the direction that flatters the book.

**2. The supporting tables have duplicate keys that mask missing ones.**

| Table | Rows | Distinct keys | Missing from the book |
|---|---:|---:|---:|
| `underwriting.csv` | 3,000 | 1,901 policies | 1,099 policies |
| `fraud_signals.csv` | 3,000 | 1,879 claims | 1,121 claims |

Join either one raw and the result is exactly 3,000 rows against a 3,000-row parent. A row-count check passes. Meanwhile a third of the population has dropped out and duplicates have taken its place.

**Check distinct key counts, not row counts.** On this dataset the row count does not warn you.

## One portfolio, four decision layers

```text
                    INSURANCE BOOK
                         |
       +-----------------+------------------+
       |                 |                  |
    Premium            Risk              Claims
       |                 |                  |
       v                 v                  v
  Loss Ratio       Pricing Review     Fraud Signals
       |                 |                  |
       +-----------------+------------------+
                         |
                         v
                Portfolio Economics
                         |
                         v
                Management Decisions
                         ^
                         |
                 Economic Conditions
```

## Data

| File | Rows | Contents |
|---|---:|---|
| `policies.csv` | 3,000 | Policy, customer, type, premium, coverage, dates, underwriting score |
| `claims.csv` | 3,000 | Claim, policy, amount, date, type, fraud flag, settlement |
| `customers.csv` | 3,000 | Age, gender, location, income band, risk profile |
| `underwriting.csv` | 3,000 | Credit score, health score, risk score, approval status |
| `fraud_signals.csv` | 3,000 | Anomaly score, network flag, stated fraud reason |
| `payments.csv` | 3,000 | Premium paid, payment date, payment status |
| `geospatial.csv` | 3,000 | Crime rate, flood risk, weather severity by location |
| `behavioral.csv` | 3,000 | Activity score, device usage, engagement level |
| `macroeconomic.csv` | 3,000 | Daily inflation, unemployment and interest rates |

Claims are dated 2018 to 2024. The economic file runs January 2018 to March 2026.

## Stack

SQL. See [MODEL_NOTES.md](MODEL_NOTES.md) for the analytical model and the controls applied.

## Limitations

- The portfolio is simulated. Premium and settlement scales are not calibrated against each other, with settlements averaging about 15 times premium, so absolute loss ratios carry no real-world meaning and are used only for relative ranking.
- The pricing and fraud results are negative findings about this dataset. They do not establish that risk-based pricing or anomaly scoring fail in general.
- Fraud outputs are screening signals for human investigation, not findings of fraud.
- The analysis supports underwriting and portfolio review. It does not replace actuarial pricing, reserving or regulatory review.
