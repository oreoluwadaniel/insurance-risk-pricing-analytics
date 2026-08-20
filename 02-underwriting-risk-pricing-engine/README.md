# RiskPrice: Underwriting & Premium Adequacy Intelligence

A SQL underwriting analysis that tests whether the premium charged has any relationship to the risk underwriting assessed, and prioritises policies for pricing review.

The dataset is synthetic and contains **3,000 policies** across Auto, Property, Life and Health, with **3,000 underwriting rows covering 1,901 distinct policies**.

## The business problem

Insurance pricing balances two things:

```text
Risk accepted  ->  Premium charged
```

When those two drift apart, the book grows and the economics worsen at the same time. The policies that need a pricing review are the ones where the risk assessed and the price charged disagree.

## The join problem that comes first

`underwriting.csv` holds 3,000 rows and **1,901 distinct policy IDs**.

Join it to the 3,000-row policy table and the result is 3,000 rows. A row-count check passes. It should not:

- 1,099 policies have no underwriting record and drop out of the analysis entirely.
- 1,099 duplicate rows take their place and are counted twice.

The row count is identical before and after, so nothing warns you. This analysis deduplicates on `policy_id` and reports the coverage gap instead of hiding it.

```text
underwriting  ->  count distinct policy_id  ->  deduplicate  ->  join  ->  report coverage
```

## What the analysis found

**Premium does not track assessed risk.** Across the 1,901 policies that have an underwriting record, the correlation between the underwriting risk score and the premium charged is **-0.037**.

That is not a weak relationship. It is no relationship, and it is very slightly the wrong way round. Whatever set the price on this book, it was not the risk assessment.

Supporting results:

- Splitting the book into risk-score quartiles produces average premiums of 2,591, 2,700, 2,558 and 2,499 from lowest risk to highest. The highest-risk quartile pays the least.
- Claim frequency across the same quartiles runs 0.94, 1.04, 1.04 and 1.02 claims per policy. The risk score does not predict claims either.
- Approval status across the 3,000 underwriting rows splits **1,044 rejected, 980 in review and 976 approved**. A third of the pipeline sits in a manual review queue.

## What a decision maker should take from it

Two things need attention before anything else in this book:

1. **The pricing link is broken.** A risk score that does not move price and does not predict claims is a control that exists on paper. Either the score needs rebuilding or the pricing rules need to start using it.
2. **1,099 policies have no underwriting record**, whether because none was created or because it was lost. Either way, more than a third of the book has no assessment attached to it.

## Method

1. Count distinct keys in `underwriting.csv` before joining anything.
2. Deduplicate on `policy_id` and record how many policies have no underwriting record.
3. Correlate risk score against premium charged and against subsequent claim frequency.
4. Band the book by risk score quartile and compare average premium and claim frequency across bands.
5. Rank policies by the gap between assessed risk and price charged for pricing review.

## Files

- `underwriting_pricing_engine.sql` — the full analysis
- `../data/policies.csv`, `../data/underwriting.csv`, `../data/claims.csv`

## Limitations

- The portfolio is simulated. The absence of a risk-to-price relationship is a property of this generated dataset, not evidence about how insurers price.
- 1,099 of 3,000 policies have no underwriting record, so the pricing test runs on the 1,901 that do.
- Premium and settlement scales in this book are not calibrated against each other, so loss ratios are used for ranking only.
- The analysis supports underwriting review. It does not replace actuarial pricing or regulatory review.
