# FraudWatch: Claims Investigation & Risk Triage

A SQL fraud triage analysis built to answer one operational question, and to check its own answer before handing it to anyone.

> **Which claims should investigators look at first?**

The dataset contains **3,000 synthetic insurance claims** and **3,000 fraud signal rows covering 1,879 distinct claims**.

## The business problem

An insurer cannot investigate every claim with the same effort. Triage exists to point limited investigation capacity at the claims most likely to be fraudulent.

The intended flow:

```text
3,000 claims
     |
     v
fraud signals (anomaly score, network flag, stated reason)
     |
     v
risk ranking
     |
     v
investigation queue
     |
     v
human review
```

A queue like that is only worth building if the signals underneath it concentrate fraud. That is a testable claim, so it was tested.

## The join check that comes first

`fraud_signals.csv` holds 3,000 rows and **1,879 distinct claim IDs**. Joined raw to the 3,000-row claims table it returns 3,000 rows, so a row-count check passes while 1,121 claims silently drop out and 1,121 duplicates take their place.

Every figure below is calculated after deduplicating on `claim_id`, across the 1,879 claims that carry a signal row.

## What the analysis found

**The base rate.** 174 of those 1,879 claims are flagged, **9.26%**. Across the full claims file, 299 of 3,000 claims carry a fraud flag, 9.97%, attached to roughly 11.44M of settlement value.

**Neither signal ranks fraud.**

| Triage rule | Claims | Flagged | Fraud rate | Against the 9.26% base |
|---|---:|---:|---:|---|
| Top 300 by anomaly score | 300 | 32 (27.8 expected at random) | 10.67% | Four extra cases |
| Network flag set | 925 | 83 | 8.97% | Below base |
| Network flag not set | 954 | 91 | 9.54% | Above base |
| High anomaly score and network flag | 236 | 23 | 9.75% | No meaningful lift |

Ranking 1,879 claims by anomaly score and taking the top 300 finds 32 fraudulent claims. Drawing 300 at random finds about 28. Four extra cases out of 300 reviews is not a triage system.

The network flag points slightly the wrong way: claims carrying it are marginally **less** likely to be fraudulent than claims without it.

**The stated reason does not narrow anything either.** Across the deduplicated signals the reasons split almost evenly: Duplicate Claim 500, Fake Identity 483, Suspicious Pattern 449, Inflated Amount 447. Four categories at roughly a quarter each cannot prioritise a queue.

**The network flag sits on 49.2% of claims.** A signal present on half the population is not a signal about that population.

## What a decision maker should take from it

**Do not build the investigation queue on these signals.** A ranked queue with no lift is worse than no queue, because it looks like prioritisation. Investigators work down it believing the top is enriched, and it is a random sample with numbers printed beside it.

The useful next steps are to rebuild the score against confirmed investigation outcomes, or to replace it with explicit rules that can each be tested on their own.

## Method

1. Count distinct claim IDs in `fraud_signals.csv` before joining. 3,000 rows, 1,879 distinct claims.
2. Deduplicate on `claim_id` and establish the base fraud rate across the tested population.
3. Rank by anomaly score, then measure how many flagged cases fall in the top N against the number a random draw of the same size would return.
4. Compare fraud rates with and without the network flag.
5. Test the two signals combined.
6. Compare the distribution of stated fraud reasons.

## Files

- `fraud_detection_analysis.sql` — the full analysis
- `../data/claims.csv`, `../data/fraud_signals.csv`, `../data/geospatial.csv`

## Limitations

- The portfolio is simulated. The absence of signal is a property of this generated dataset and says nothing about whether anomaly scoring works in production.
- A fraud flag here is a screening output, not a confirmed fraud.
- 1,121 of 3,000 claims have no fraud signal row after deduplication, so the ranking tests run on the 1,879 that do.
- Lift is measured against the base rate in the tested population. This is not a precision and recall evaluation against confirmed investigation outcomes, because this dataset contains none.
