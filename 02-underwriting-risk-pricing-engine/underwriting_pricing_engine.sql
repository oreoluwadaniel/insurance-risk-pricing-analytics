/*=====================================================================
UNDERWRITING RISK, PRICING & PREMIUM REVIEW SYSTEM
Insurance Risk, Pricing & Profitability Project - Part 2 of 4
=====================================================================

Business question this script answers:
Are we pricing risk correctly? Which policies look underpriced given how
risky they are, which ones look overpriced given how safe they are, and
what does claims behavior actually look like across risk bands?

Tables used: policies, customers, underwriting, claims
SQL dialect: T-SQL (Microsoft SQL Server / Azure SQL)
=====================================================================*/

/*---------------------------------------------------------------------
STEP 1: Collapse claims to one row per policy first

Same reasoning as in Part 1: a policy can have several claims, so any
claims-based number has to be aggregated to the policy level before it
gets joined to anything else. Otherwise counts and sums come out
inflated for policies with more than one claim.
---------------------------------------------------------------------*/

IF OBJECT_ID('tempdb..#policy_claims2') IS NOT NULL DROP TABLE #policy_claims2;

SELECT
policy_id,
COUNT(claim_id) AS claim_count,
SUM(settlement_amount) AS total_settled,
AVG(claim_amount) AS avg_claim_amount
INTO #policy_claims2
FROM claims
GROUP BY policy_id;

/*---------------------------------------------------------------------
STEP 2: Build the policy-grain risk table

underwriting.csv has exactly one row per policy, so joining it straight
to policies is safe and does not need any pre-aggregation.
---------------------------------------------------------------------*/

IF OBJECT_ID('tempdb..#policy_risk') IS NOT NULL DROP TABLE #policy_risk;

SELECT
p.policy_id,
p.customer_id,
p.premium_amount,
c.risk_profile,
u.risk_score,
u.credit_score,
u.health_score,
ISNULL(pc.claim_count, 0) AS claim_count,
ISNULL(pc.total_settled, 0) AS total_settled,
pc.avg_claim_amount
INTO #policy_risk
FROM policies p
LEFT JOIN customers c ON p.customer_id = c.customer_id
LEFT JOIN underwriting u ON p.policy_id = u.policy_id
LEFT JOIN #policy_claims2 pc ON p.policy_id = pc.policy_id;

/*---------------------------------------------------------------------
QUERY 1: Policy mispricing screen

Flags policies where the underwriting risk score is high (above 0.70)
but the premium being charged is still low (under $1,000). These look
like cases where the price has not caught up with the risk, and they
are worth a manual pricing review rather than an automatic relabel.
---------------------------------------------------------------------*/
SELECT
policy_id,
risk_score,
premium_amount,
total_settled
FROM #policy_risk
WHERE risk_score > 0.7
AND premium_amount < 1000
ORDER BY risk_score DESC;

/*---------------------------------------------------------------------
QUERY 2: Premium review engine

A simple rule-based flag meant to shortlist policies for a human
pricing review, not an actuarial premium calculation:

Increase Premium -> settlements already exceed the premium collected
Reduce Premium -> risk score is comfortably low (under 0.30)
Check -> risk score is missing and needs a data fix
Keep Same -> everything else

The missing-data check now runs first. In the original script it sat
after the increase and reduce checks, which happened to still work
because SQL treats a comparison against NULL as unknown rather than
true, but putting the data-quality check first makes the logic easier
to read and safer to extend later.
---------------------------------------------------------------------*/
SELECT
policy_id,
risk_score,
total_settled,
premium_amount,
CASE
WHEN risk_score IS NULL THEN 'Check - missing risk score'
WHEN total_settled > premium_amount THEN 'Increase Premium'
WHEN risk_score < 0.3 THEN 'Reduce Premium'
ELSE 'Keep Same'
END AS pricing_decision
FROM #policy_risk;

/*---------------------------------------------------------------------
QUERY 3: Risk score vs claim behavior

For each risk score in the book, how many claims came from policies at
that score, and how big were those claims on average. claims_count
sums the real per-policy claim_count from #policy_claims2, instead of
counting every row in a joined table. That distinction matters here
because a policy with no claims still shows up as one row after a
LEFT JOIN, and counting that row as a "claim" would overstate how many
claims actually happened.
---------------------------------------------------------------------*/
SELECT
risk_score,
SUM(claim_count) AS claims_count,
AVG(avg_claim_amount) AS avg_claim
FROM #policy_risk
WHERE risk_score IS NOT NULL
GROUP BY risk_score
ORDER BY risk_score;

/*---------------------------------------------------------------------
QUERY 4: Customer risk profile segmentation

customers is counted with COUNT(DISTINCT customer_id) because a
customer can hold more than one policy. Counting rows instead of
distinct customers would let a customer with three policies show up as
three separate "customers," which overstates the size of each risk
segment.
---------------------------------------------------------------------*/
SELECT
risk_profile,
COUNT(DISTINCT customer_id) AS customers,
COUNT(policy_id) AS policies,
AVG(total_settled) AS avg_claim_per_policy
FROM #policy_risk
GROUP BY risk_profile
ORDER BY avg_claim_per_policy DESC;
