/*=====================================================================
CLAIMS PERFORMANCE & LOSS RATIO ANALYSIS
Insurance Risk, Pricing & Profitability Project - Part 1 of 4
=====================================================================

Business question this script answers:
Is the premium we collect enough to cover what we pay out in claims,
and where in the book (which policies, which customers, which product
lines) is that not true?

Tables used: policies, claims
SQL dialect: T-SQL (Microsoft SQL Server / Azure SQL)
=====================================================================*/

-- Quick check before building anything on top of the raw tables
SELECT COUNT(*) AS policy_count FROM policies;
SELECT COUNT(*) AS claim_count FROM claims;

/*---------------------------------------------------------------------
STEP 1: Build a clean, policy-grain base table

A policy can carry more than one claim. Some policies in this book have
four separate claims against them. If you join policies straight to
claims and then try to total something that actually lives on the
policy record, like premium_amount, that value repeats once for every
claim tied to the policy, and any total built on top of it comes out
too high. The fix is to collapse claims down to one row per policy
first, and only then attach the premium.
---------------------------------------------------------------------*/

IF OBJECT_ID('tempdb..#policy_claims') IS NOT NULL DROP TABLE #policy_claims;

SELECT
policy_id,
COUNT(claim_id) AS claim_count,
SUM(settlement_amount) AS total_settled,
AVG(claim_amount) AS avg_claim_amount
INTO #policy_claims
FROM claims
GROUP BY policy_id;

IF OBJECT_ID('tempdb..#policy_financials') IS NOT NULL DROP TABLE #policy_financials;

SELECT
p.policy_id,
p.customer_id,
p.policy_type,
p.premium_amount,
ISNULL(pc.claim_count, 0) AS claim_count,
ISNULL(pc.total_settled, 0) AS total_settled,
pc.avg_claim_amount,
ISNULL(pc.total_settled, 0) * 1.0 / NULLIF(p.premium_amount, 0) AS loss_ratio
INTO #policy_financials
FROM policies p
LEFT JOIN #policy_claims pc
ON p.policy_id = pc.policy_id;

/*---------------------------------------------------------------------
QUERY 1: Policy-level loss ratio

A loss ratio above 1.0 means that policy has paid out more in claims
than it has taken in through premium so far. A loss ratio of 0 means
the policy has no claims on record yet, not that data is missing.
---------------------------------------------------------------------*/
SELECT
policy_id,
premium_amount,
total_settled,
claim_count,
loss_ratio
FROM #policy_financials
ORDER BY loss_ratio DESC;

/*---------------------------------------------------------------------
QUERY 2: Customer-level loss exposure

Rolls the policy-level numbers up to the customer. Because
#policy_financials already sits at one row per policy, summing premium
and settlements here is safe. A customer with three policies has their
premium counted three times, once per policy, and no more than that.
---------------------------------------------------------------------*/
SELECT
customer_id,
COUNT(policy_id) AS policy_count,
SUM(premium_amount) AS total_premium,
SUM(total_settled) AS total_claims,
SUM(total_settled) * 1.0 / NULLIF(SUM(premium_amount), 0) AS loss_ratio
FROM #policy_financials
GROUP BY customer_id
HAVING SUM(total_settled) > SUM(premium_amount)
ORDER BY loss_ratio DESC;

/*---------------------------------------------------------------------
QUERY 3: Portfolio oversight by policy type

Same logic, rolled up to product line instead of customer, so
management can see which lines of business are running hot on claims
relative to the premium they bring in.
---------------------------------------------------------------------*/
SELECT
policy_type,
COUNT(policy_id) AS policies,
SUM(premium_amount) AS total_premium,
SUM(total_settled) AS total_claims,
SUM(total_settled) * 1.0 / NULLIF(SUM(premium_amount), 0) AS loss_ratio
FROM #policy_financials
GROUP BY policy_type
ORDER BY loss_ratio DESC;
