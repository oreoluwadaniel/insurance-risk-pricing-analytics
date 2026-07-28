/*=====================================================================
FRAUD DETECTION & CLAIMS INVESTIGATION ANALYSIS
Insurance Risk, Pricing & Profitability Project - Part 3 of 4
=====================================================================

Business question this script answers:
Where should the investigations team look first? Which claims carry the
strongest fraud signals, and which locations are producing a
disproportionate share of confirmed or flagged fraud cases?

Tables used: claims, fraud_signals, policies, customers
SQL dialect: T-SQL (Microsoft SQL Server / Azure SQL)

Data quality note: claims and fraud_signals both hold 3,000 rows, and
every claim_id in claims has exactly one matching row in fraud_signals.
That makes the join below a clean one-to-one match, so there is no
fan-out risk to correct here. Both queries in this script were already
logically sound in the original draft. They are included here with
light polish (extra columns for context, clearer ordering) rather than
structural fixes.
=====================================================================*/

/*---------------------------------------------------------------------
QUERY 1: Claims anomaly watchlist

Pulls every claim with an anomaly score above 0.80. This is a starting
list for investigators, not a fraud verdict. A high anomaly score means
a claim is worth a closer look, nothing more.
---------------------------------------------------------------------*/
SELECT
cl.claim_id,
cl.claim_amount,
cl.claim_type,
f.anomaly_score,
f.fraud_reason,
cl.fraud_flag
FROM claims cl
JOIN fraud_signals f ON cl.claim_id = f.claim_id
WHERE f.anomaly_score > 0.8
ORDER BY f.anomaly_score DESC;

/*---------------------------------------------------------------------
QUERY 2: Fraud concentration by location

Counts confirmed or flagged fraud cases (fraud_flag = 1) by the
customer's location. Each claim maps to exactly one policy, and each
policy to exactly one customer, so this join does not duplicate rows
and COUNT(*) here is a true count of fraud cases.
---------------------------------------------------------------------*/
SELECT
c.location,
COUNT(*) AS fraud_cases
FROM claims cl
JOIN policies p ON cl.policy_id = p.policy_id
JOIN customers c ON p.customer_id = c.customer_id
WHERE cl.fraud_flag = 1
GROUP BY c.location
ORDER BY fraud_cases DESC;
