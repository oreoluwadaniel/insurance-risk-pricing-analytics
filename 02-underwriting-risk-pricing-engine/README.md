# Underwriting Risk, Pricing & Premium Review System

Part 2 of a 4-part SQL portfolio built on a simulated insurance book of business. This piece asks whether the price being charged actually matches the risk being taken on.

## Business problem

Underwriting and pricing are supposed to move together. A policy with a high risk score should carry a premium that reflects that risk, and a policy with a genuinely low risk score is a candidate for a more competitive price before a competitor undercuts it. When those two things drift apart, silently, one policy at a time, the business either leaks money on underpriced risk or loses customers it should be keeping by overpricing safe ones.

This script gives underwriting and pricing teams four practical views: a screen for policies priced too low given their risk, a simple rule-based flag for which policies deserve a premium increase or decrease, a look at whether claims actually behave differently across risk bands, and a segmentation of the customer base by risk profile.

## Data source

Four tables feed this analysis, all built around a simulated book of 3,000 policies. policies.csv gives the premium and customer link. customers.csv gives each customer's risk profile (Low, Medium, or High Risk) along with age, gender, location, and income band. underwriting.csv holds one row per policy, with a credit score, health score, risk score, and an approval status (Approved, Rejected, or Review). claims.csv supplies the claims history that gets checked against all of it.

Because underwriting.csv has exactly one row per policy, it joins cleanly with no risk of duplication. Claims are a different story, since a policy can carry more than one, and that distinction shapes how the whole script is built.

## Methodology

The approach mirrors Part 1: aggregate claims down to one row per policy before joining anything else to it. From there, a single policy-grain table (#policy_risk) brings together premium, risk score, credit and health scores, risk profile, and claims history, one row per policy, no duplicates. All four queries in this script run off that one table.

## Analysis & error check

Two real issues showed up while going through the original queries.

The first is a labeling problem in the "risk score and claim behavior" query. The original counted COUNT(*) off a view where policies were joined to claims with a LEFT JOIN, and called the result claims_count. The trouble is that a policy with zero claims still produces one row in a LEFT JOIN, just with the claim fields left blank. Counting that row as if it were a claim inflates the claim count for every risk score, especially lower risk scores where more policies genuinely have no claims at all. The fix sums the real per-policy claim count computed during aggregation, so a policy with no claims contributes a zero, not a phantom one.

The second issue is the same mislabeling, one level up, in the customer risk profile segmentation query. The original used COUNT(*) and called it customers, but a customer can hold more than one policy, so that count was really counting policy-level rows, not distinct people. A risk segment full of customers who each hold two or three policies would look artificially larger than it actually is. The fix swaps that for COUNT(DISTINCT customer_id), so the customer count in each risk segment means what it says.

Beyond those two fixes, I reordered the CASE logic in the premium review engine so the missing-data check runs first instead of last. The original logic still worked, SQL treats a comparison against NULL as unknown rather than true, so it fell through to the check condition either way, but leading with the data-quality check is clearer to read and less risky if someone edits the logic later without noticing the NULL handling buried at the bottom.

## Insight

Two figures from the underwriting data are worth calling out directly, since they hold regardless of how the claims side plays out. Roughly 23 percent of policies in this book carry an underwriting risk score of 0.80 or higher, meaning close to a quarter of the portfolio sits in a risk band that deserves particular attention to pricing. On the decision side, the approval status split across the book is close to even across all three outcomes, Approved, Rejected, and Review each account for roughly a third of policies. That's not a small edge case sitting in the underwriting queue, it's a genuinely large chunk of the book waiting on a decision, and it's worth asking why the Review pile is that big rather than treating it as background noise.

The mispricing screen and the risk-versus-claims comparison are where this script does its real work, and the exact counts will shift as the book changes, so they're built to be run rather than quoted as a fixed number here. What matters is that both queries now measure real risk-adjusted pricing signals instead of an inflated claim count.

## Recommendation

Pull the output of the mispricing screen (high risk score, low premium) into the next underwriting review cycle as a standing report rather than a one-time check. Given that close to a quarter of the book sits above the 0.80 risk threshold, this isn't a rare event worth a manual glance now and then, it's a recurring check that belongs in a regular pricing review.

The Review-status backlog is worth a separate look outside of this script. A third of the book sitting in an undecided state is either a sign of a genuinely cautious underwriting process or a bottleneck worth investigating.

## Business impact

Matching premium to risk more consistently protects margin on the policies that are actually risky, and keeps pricing competitive on the ones that aren't. The customer risk segmentation, once counted correctly, gives a fair view of how big each risk band really is, which matters for anyone setting risk appetite or capital reserves off these numbers.

## What was done

I reviewed all four original queries, fixed the two claim-counting and customer-counting bugs described above, reordered the premium review engine's CASE logic for clarity, and rebuilt the whole thing around a single clean policy-grain base table so none of the four queries carry the fan-out risk that the original wide view had.

## Tools used and how they helped

Written in T-SQL for SQL Server or Azure SQL, matching the rest of this portfolio. A temp table (#policy_risk) holds the clean, deduplicated base data that all four queries share, so the fix only had to happen once rather than four separate times. COUNT(DISTINCT ...) does the real work of correcting the customer-counting bug, and a CASE statement drives the plain-language pricing recommendation without needing a separate lookup table.

## Results

The corrected script delivers four outputs: a ranked mispricing watchlist, a plain pricing decision (increase, reduce, keep, or check) for every policy, a genuine claims-count-by-risk-score comparison instead of an inflated one, and a customer risk segmentation that counts actual people instead of policy rows. Two verified facts from the underlying data anchor the story: about 23 percent of policies carry a risk score of 0.80 or above, and underwriting decisions split almost evenly across Approved, Rejected, and Review.
