# Analytical Model Notes

## Analysis flow

```text
Policy and claims data
        |
        v
Grain and join checks
        |
        v
Premium and exposure measures
        |
        +--> loss ratio
        +--> claim frequency
        +--> severity
        +--> pricing adequacy
        +--> fraud indicators
        |
        v
Segment and macro analysis
        |
        v
Underwriting decisions
```

## Critical control

Claims are at a different grain from policy records. Claims must be aggregated before being joined back to policy-level exposure. Joining raw claim rows directly to policy rows can multiply premium and distort loss ratios.

## Use of results

The analysis supports underwriting and portfolio review. It does not replace actuarial pricing, regulatory review, or a production fraud investigation.
