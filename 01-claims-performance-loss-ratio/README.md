# Claims Performance & Loss Ratio Analysis

Part 1 of a 4-part SQL portfolio built on a simulated insurance book of business. This piece looks at one core question: is the premium coming in enough to cover what's going out in claims.

## Business problem

Selling more policies feels like progress, but it only means something if the premium collected actually covers the claims that come with it. A book can grow every quarter and still be quietly losing money if claims are running ahead of premium on the wrong policies, the wrong customers, or an entire product line.

This script answers three practical questions that an underwriting or finance team would ask on a normal Monday: which individual policies have paid out more in claims than they've collected in premium, which customers are a net loss across their whole relationship with the company, and which product lines (auto, property, life, health) are the least profitable once claims are taken into account.

## Data source

The data is a simulated insurance dataset covering 3,000 policies and 3,000 individual claim records. Two tables matter for this analysis:

policies.csv holds one row per policy: policy ID, customer ID, policy type, premium amount, coverage amount, start and end dates, and an underwriting score. claims.csv holds one row per claim: claim ID, the policy it belongs to, claim amount, claim date, claim type, a fraud flag, and the settlement amount actually paid out.

A policy is not guaranteed to have exactly one claim. Some have none. Others have several, one policy in the sample data has four separate claims against it. That detail turns out to matter a lot for how this script is written.

## Methodology

I started by checking row counts on both tables to confirm the data loaded properly before building anything on top of it. That's a habit worth keeping, it takes two seconds and catches a bad import before it wastes an afternoon.

From there, the approach was to build a clean base layer at the policy level first, then roll that layer up twice: once by customer, once by product line. Claims get aggregated down to one row per policy (total settled, claim count, average claim size) before they're ever joined to the premium amount sitting on the policy record. That ordering is the whole trick to getting this right, and it's explained in detail in the next section.

## Analysis & error check

The original script built one wide view that joined policies to claims directly, then joined customers and underwriting data on top of that, all at once. That view had a real problem: because a policy can have more than one claim, joining policies to claims directly means the policy's premium amount gets repeated once for every claim on that policy. Sum that premium up at the customer or policy-type level and you're no longer looking at real premium collected, you're looking at premium collected plus a bunch of extra copies of it, more copies for customers who happened to file more claims.

Concretely, in the original script's customer loss exposure query and its policy-type oversight query, SUM(premium_amount) was being calculated on a table where premium had already been duplicated by the claims join. That inflates the premium side of the loss ratio and makes claims performance look better than it actually is, worse for a customer with three claims than for one with a single claim, purely because of how the join fanned out, not because of anything real about their risk.

The fix is the aggregate-then-join pattern used in the script above: collapse claims to one row per policy first (#policy_claims), then join that single row back to the policy record (#policy_financials). Once you're at one row per policy, summing premium at the customer or product-type level is safe because each policy's premium only appears once no matter how many claims it has.

I also fixed a smaller issue while I was in there. The original loss ratio calculation left policies with zero claims showing a blank value instead of a proper 0, because SUM() over no rows returns NULL, not zero. A blank loss ratio reads like missing data. A policy with genuinely no claims should show a loss ratio of exactly 0, so I wrapped the settlement total in ISNULL() to make that distinction clear.

## Insight

Once the aggregation is done correctly, the three queries in this script give three different lenses on the same underlying problem. The policy-level query surfaces individual outliers, the specific policies where claims have already outpaced premium. The customer-level query catches something the policy view can miss: a customer who is fine on each individual policy but who becomes a net loss once you add up everything they hold with the company. The product-type rollup answers the highest-level version of the question, whether an entire line of business (say, auto versus property) is running a healthier loss ratio than another.

None of these numbers are meant to shock anyone into action on their own. A high loss ratio on one policy might be a single bad year. A pattern across a whole product line is a different story, and that's the level where this script earns its keep.

## Recommendation

Any policy or customer that this script flags with a loss ratio over 1.0 should go on a pricing and underwriting review list, not get auto-flagged as a loss. Some of that is legitimate insurance risk playing out exactly as expected. The value here is turning "which policies should we look at" from a gut-feel question into a short, ranked list.

At the product-type level, whichever line comes out with the weakest loss ratio deserves a closer look at its pricing model and underwriting criteria specifically, rather than a blanket premium increase across the whole book.

## Business impact

Run consistently, this kind of query turns loss ratio monitoring from a quarterly surprise into an ongoing check. Catching a mispriced product line or a handful of consistently unprofitable customer relationships early is the difference between a small pricing correction and a much larger one after a year of losses have already piled up.

## What was done

I reviewed the original script, found the premium double-counting bug in two of the three rollups, and rebuilt the whole thing around a policy-grain base table that avoids the problem at the source instead of patching around it. I also fixed the NULL-versus-zero loss ratio issue for claim-free policies. All three original business questions (policy loss ratio, customer loss exposure, product-type oversight) are preserved, they just run on a corrected foundation now.

## Tools used and how they helped

This is written in T-SQL, targeting SQL Server or Azure SQL, matching the dialect of the original script. Temp tables (#policy_claims, #policy_financials) do the heavy lifting here instead of a single nested view, mainly because building the aggregation in two clear steps makes the fan-out bug easy to spot and explain, rather than burying it inside one large multi-join view. NULLIF() guards every division against a divide-by-zero error on a policy with no premium recorded, and ISNULL() turns a missing claims total into a proper zero.

## Results

The corrected script produces three ranked outputs: policies ordered by loss ratio from worst to best, customers whose total settlements exceed their total premium, and product types ranked by overall loss ratio. Each one is now built on premium and claims totals that are counted exactly once per policy, so the numbers reflect real financial exposure rather than an artifact of how many claims happened to attach to a given policy.
