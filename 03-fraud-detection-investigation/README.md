# Fraud Detection & Claims Investigation Analysis

Part 3 of a 4-part SQL portfolio built on a simulated insurance book of business. This piece is about giving an investigations team a short, ranked list instead of 3,000 claims to sift through by hand.

## Business problem

A fraud team can't manually review every claim that comes in, and it shouldn't have to. What it needs is a way to sort claims by how suspicious they look, and a sense of whether fraud is spread evenly across the business or concentrated somewhere specific. This script does both: it builds a watchlist of claims with strong anomaly signals, and it groups confirmed or flagged fraud cases by customer location to show where investigation effort might be best spent.

## Data source

This analysis pulls from four tables. claims.csv holds the claim record itself, including a fraud_flag that marks whether a claim has been confirmed or flagged as fraudulent. fraud_signals.csv holds a separate anomaly score, a network flag, and a stated fraud reason for each claim, produced by whatever fraud model or rules engine generated this data. policies.csv and customers.csv are only needed to trace a claim back to the customer's location for the geographic rollup.

Both claims.csv and fraud_signals.csv contain exactly 3,000 rows, and every claim_id in claims has a matching row in fraud_signals. That's a clean one-to-one relationship, which matters because it means the join in the first query doesn't need any of the aggregation work the other three scripts in this portfolio required.

## Methodology

Because the join here is already clean, the approach was mostly verification rather than restructuring. I checked the row counts on both tables, confirmed the one-to-one match between claims and fraud_signals, then ran both original queries as written to see whether the joins behaved the way they were supposed to.

## Analysis & error check

Both queries in the original script held up. Neither one relies on a view or a table where a policy or claim could get duplicated by a join, so there was no fan-out bug to fix here, unlike the loss ratio and underwriting scripts in this portfolio.

I did check the assumption that made the fraud concentration query safe, since it's the kind of thing that's easy to get wrong silently. Claims join to policies on policy_id, and policies join to customers on customer_id. As long as each claim points to exactly one policy and each policy points to exactly one customer, which is how this data is structured, that join can't create duplicate rows, so COUNT(*) in the location rollup is a genuine count of fraud cases, not an inflated one.

The main change I made was adding a couple of extra columns for context, claim_type and fraud_reason, so the watchlist gives an investigator more to go on than a bare claim ID and a score. That's a usability improvement rather than a bug fix.

## Insight

Checking the anomaly score directly against the 0.80 threshold used in this script shows that roughly 583 of the 3,000 claims in this dataset, close to one in five, carry an anomaly score at or above that line. That's a meaningfully large watchlist on its own, which says something about how this threshold is set. A 0.80 cutoff catching a fifth of all claims is either a genuinely high-fraud simulated environment, or a sign that 0.80 might be set a bit loose if the goal is a short, high-confidence list rather than a broad one.

Separately, the confirmed or flagged fraud_flag on claims sits at 299 out of 3,000 claims, right around 10 percent. Compared against the roughly 19 percent of claims that clear the 0.80 anomaly threshold, that gap is worth sitting with for a second. It suggests the anomaly score is catching a wider net of "worth a second look" claims than the number that eventually get formally flagged, which is exactly what an early-warning signal is supposed to do, but it also means the fraud team should expect a real gap between the watchlist size and the number that turn into confirmed cases.

## Recommendation

Treat the 0.80 anomaly threshold as a starting point, not a fixed rule. Given that it currently surfaces close to a fifth of all claims, it's worth testing a tighter threshold, say 0.90, to see how much that shrinks the list while still catching the claims that later get flagged. That keeps the watchlist usable for a team with limited investigation hours instead of turning into a list nobody has time to work through.

The location rollup should get folded into a recurring fraud operations report rather than run as a one-off. Geographic concentration is one of the more actionable fraud signals available here, since it can point to a specific regional issue, a compromised local network, or a data quality problem in how claims from one area get processed.

## Business impact

A ranked, reasonably sized watchlist means investigation hours go toward the claims most likely to be worth them, instead of getting spread thin across everything. Understanding the real relationship between anomaly scores and confirmed fraud flags, roughly twice as many claims clear the anomaly bar as end up flagged, helps set expectations correctly when this moves from a data exercise into an actual staffing conversation.

## What was done

I verified the join logic in both original queries and confirmed neither needed a structural fix, checked the claims-to-fraud_signals relationship is genuinely one-to-one, added supporting columns to the watchlist query for investigator usability, and pulled real numbers directly from the data to ground the fraud rate and anomaly rate discussion in something concrete rather than a guess.

## Tools used and how they helped

Written in T-SQL for SQL Server or Azure SQL. This script relies on straightforward inner joins rather than temp tables or views, since the underlying data doesn't have the one-to-many relationships that made temp tables necessary in the loss ratio and underwriting scripts. Aggregation with COUNT(*) and a GROUP BY on location does the geographic rollup in a single pass.

## Results

The watchlist query returns every claim with an anomaly score of 0.80 or higher, ranked from most suspicious to least, roughly 583 claims out of 3,000 based on the current data. The location rollup returns confirmed or flagged fraud cases grouped by customer location, ranked from highest concentration down, giving the investigations team a starting point for where to look first. The overall confirmed fraud rate in this dataset sits at about 10 percent of all claims.
