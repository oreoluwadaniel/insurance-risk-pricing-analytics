# MacroRisk: Economic Conditions & Claims Cost Intelligence

A SQL analysis that puts claims cost next to inflation, unemployment and interest rates, so pricing and finance teams can see whether external conditions explain what the book is doing.

The project uses **3,000 synthetic insurance claims** dated 2018 to 2024 and **3,000 daily economic observations**, brought to a common annual grain before anything is compared.

> **Are changes in claims cost happening alongside changes in the wider economy?**

This does not attempt to prove causation. It builds the comparison properly and then reports what the comparison shows, including when the answer is nothing.

## Business problem

Claims costs move for several reasons at once:

- Changes in portfolio mix
- Changes in claim types
- Higher repair or replacement costs
- General inflation
- Customer behaviour
- Broader economic conditions

Internal claims data alone cannot separate portfolio movement from external conditions. MacroRisk adds the external context.

```text
claims data                 economic data
     |                            |
     v                            v
annual claims profile      annual economic profile
     |                            |
     +------------+---------------+
                  |
                  v
          common-grain join
                  |
                  v
   claims cost vs economic context
                  |
                  v
        pricing / reserve review
```

## The grain problem

Claims are dated events. Economic observations are daily readings. Joining them directly compares one claim against one day's inflation rate, which measures nothing.

Both sides are aggregated to annual grain first. Claims become a yearly count and average cost. Economic series become yearly means. Only then are they joined.

## What the analysis found

| Year | Claims | Avg claim | Avg settled | Inflation | Unemployment | Interest |
|---|---:|---:|---:|---:|---:|---:|
| 2018 | 421 | 50,456 | 38,960 | 8.13 | 7.00 | 5.21 |
| 2019 | 445 | 50,769 | 41,144 | 7.97 | 7.14 | 5.16 |
| 2020 | 431 | 52,830 | 40,091 | 8.34 | 7.00 | 5.35 |
| 2021 | 418 | 49,177 | 41,321 | 8.15 | 6.97 | 5.14 |
| 2022 | 430 | 49,759 | 40,352 | 7.90 | 7.07 | 5.33 |
| 2023 | 434 | 49,923 | 40,394 | 8.14 | 7.00 | 5.38 |
| 2024 | 421 | 53,600 | 38,242 | 8.02 | 6.85 | 5.24 |

**There is nothing here to explain.**

- Claims volume is flat. Seven years running between 418 and 445 with no trend.
- Average claim cost moves within a narrow band, from 49,177 to 53,600, with no direction.
- Inflation sits between 7.90 and 8.34 across the whole period. Unemployment between 6.85 and 7.14. Interest between 5.14 and 5.38.

The correlations confirm it:

| Pair | r | p |
|---|---:|---:|
| Average claim cost vs inflation | 0.247 | 0.59 |
| Average claim cost vs unemployment | -0.511 | 0.24 |
| Average claim cost vs interest rate | 0.174 | 0.71 |

None is close to significance. With seven annual observations the test has almost no power anyway, which is the more important point: **seven data points cannot establish a macroeconomic relationship even if one exists.**

## What a decision maker should take from it

The honest output is that this book gives no evidence either way. Both series are effectively flat over the period, so there is no movement for the other to explain.

The pipeline is the deliverable here. It brings two differently grained sources to a common grain, joins them correctly, and reports a null result rather than mining seven points until something crosses 0.05.

## Method

1. Aggregate claims to annual grain: count, average claim amount, average settled amount.
2. Aggregate daily economic observations to annual means.
3. Join on year across the seven years both sources cover.
4. Correlate claims cost against each economic series and report the p-value alongside r.
5. State the power limitation created by seven observations.

## Files

- `macro_claims_cost_analysis.sql` — the full analysis
- `../data/claims.csv`, `../data/macroeconomic.csv`

## Limitations

- The portfolio and the economic series are both simulated, and neither carries a trend.
- Seven annual observations cannot support a claim about a macroeconomic relationship. Any correlation found on this many points would need a longer series before it meant anything.
- Correlation at annual grain would not establish causation even with a longer series and a real trend.
- The economic file covers January 2018 to March 2026. The comparison uses the seven complete years that overlap the claims data.
