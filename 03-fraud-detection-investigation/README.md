# FraudWatch: Claims Investigation & Risk Triage

A SQL fraud operations system that turns claim-level anomaly signals into a **ranked investigation queue**, measures fraud exposure, and identifies geographic concentrations that may require further investigation.

The dataset contains **3,000 synthetic insurance claims**.

The system is designed around one operational question:

> **Which claims should investigators look at first?**

## The business problem

An insurer cannot investigate every claim with the same level of effort.

FraudWatch uses existing fraud signals to narrow the claims population into a manageable review queue.

```text
3,000 Claims
     ↓
Fraud Signals
     ↓
Anomaly Screening
     ↓
Risk Ranking
     ↓
Investigation Watchlist
     ↓
Human Review
