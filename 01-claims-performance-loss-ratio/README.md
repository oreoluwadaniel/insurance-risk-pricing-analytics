# Claims Performance & Loss Ratio Intelligence

A SQL insurance analysis that shows where claims are consuming premium, which policies and customers need review, and which product lines carry the weakest economics.

The dataset is synthetic and contains **3,000 policies and 3,000 claims** across Auto, Property, Life and Health.

## The business questions

| Analysis | Question | Decision supported |
|---|---|---|
| Policy performance | Which policies have the highest claims exposure relative to premium? | Policy and underwriting review |
| Customer exposure | Which customer relationships generate more claims than their associated premium? | Account and risk review |
| Product performance | Which insurance lines have the weakest loss ratios? | Pricing and portfolio review |

The central metric is:

```text
Loss Ratio = Settled Claims / Premium
```

## The control that has to come first

Claims sit at a different grain from policies. 3,000 claims spread across 1,861 distinct policies, so a policy with three claims appears three times.

Joining raw claim rows onto policy rows multiplies that policy's premium by three. Every loss ratio downstream is then understated, and understated in the direction that makes the book look healthy.

```text
claims  ->  aggregate to one row per policy  ->  join to policy exposure
```

That aggregation happens before any measure is calculated. Nothing in this analysis joins claims to policies at raw grain.

## What the analysis found

| Product line | Policies | Relative loss ratio | Rank |
|---|---:|---:|---|
| Health | 768 | 16.19 | Weakest |
| Life | 735 | 15.63 | |
| Property | 735 | 15.34 | |
| Auto | 762 | 15.03 | Strongest |

**Read those figures as a ranking, not as loss ratios.**

Premium and settlement values in this simulated book are not calibrated against each other. Settlements average about 15 times premium, which no real insurer would survive. The numbers are useful for comparing one line against another and for nothing else. This repository states that rather than publishing a 1,554% loss ratio as though it meant something.

Other results:

- **1,861 of 3,000 policies carry at least one claim**, 62.0% of the book. The other 1,139 have none.
- **1,827 policies settled more than they were charged.**
- The spread across the four product lines is narrow, from 15.03 to 16.19. That is a finding in itself: nothing in this portfolio points at one product as the problem.

## Method

1. Profile the join keys. Count distinct policy IDs in claims before joining anything.
2. Aggregate claims to one row per policy: settled amount, claim count, severity.
3. Left join the aggregate back to policies, so the 1,139 policies with no claims stay in the book at a zero.
4. Calculate loss ratio, claim frequency and severity at policy, customer and product-line grain.
5. Rank product lines relative to each other and state the calibration limit.

## Files

- `loss_ratio_analysis.sql` — the full analysis
- `../data/policies.csv`, `../data/claims.csv`, `../data/customers.csv`

## Limitations

- The portfolio is simulated. Premium and settlement scales are not calibrated to each other, so absolute loss ratios have no real-world meaning.
- The analysis supports portfolio and underwriting review. It does not replace actuarial pricing or reserving.
- Loss ratio is calculated on settled amounts. It carries no view of reserves, reinsurance recoveries or expenses.
