# Insurance Risk, Pricing & Profitability Analytics

A SQL portfolio built around one question:

> **Is the insurance book making money for the risk it is taking?**

Four case studies use a simulated portfolio of **3,000 policies and 3,000 claims** to examine profitability, pricing, fraud, and economic exposure.

The work is designed around decisions an insurance finance, underwriting, claims, or risk team would actually need to make.

## The four business questions

| Case study | Business question | Decision supported |
|---|---|---|
| [01. Claims Performance & Loss Ratio](01-claims-loss-ratio/) | Are premiums covering claims exposure? | Identify weak products, customers, and segments |
| [02. Underwriting & Pricing](02-underwriting-pricing/) | Does premium reflect the risk being accepted? | Flag policies for pricing or underwriting review |
| [03. Fraud Detection](03-fraud-detection/) | Which claims deserve investigation first? | Prioritize limited investigation capacity |
| [04. Macroeconomic Claims](04-macroeconomic-claims/) | Are economic conditions changing claims costs? | Support pricing, reserving, and planning discussions |

## One portfolio, four decision layers

```text
                    INSURANCE BOOK
                         |
       +-----------------+------------------+
       |                 |                  |
    Premium            Risk              Claims
       |                 |                  |
       v                 v                  v
  Loss Ratio       Pricing Review     Fraud Signals
       |                 |                  |
       +-----------------+------------------+
                         |
                         v
                Portfolio Economics
                         |
                         v
                Management Decisions
                         ^
                         |
                 Economic Conditions
