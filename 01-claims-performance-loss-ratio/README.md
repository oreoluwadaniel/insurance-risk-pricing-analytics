# Claims Performance & Loss Ratio Intelligence

A SQL insurance analytics system that shows where claims are consuming premium, which policies and customer relationships need review, and which product lines may have a pricing or underwriting problem.

The dataset is synthetic and contains **3,000 policies and 3,000 claims** across Auto, Property, Life, and Health insurance.

## The business questions

| Analysis | Question | Decision supported |
|---|---|---|
| **Policy performance** | Which policies have the highest claims exposure relative to premium? | Policy and underwriting review |
| **Customer exposure** | Which customer relationships generate more claims than their associated premium? | Account and risk review |
| **Product performance** | Which insurance lines have the weakest loss ratios? | Pricing and portfolio review |

The central metric is:

```text
Loss Ratio = Settled Claims ÷ Premium
