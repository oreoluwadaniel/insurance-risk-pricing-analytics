# MacroRisk: Economic Conditions & Claims Cost Intelligence

A SQL insurance analytics project that connects claims costs with inflation, unemployment, and interest rates to give pricing and finance teams external context for claims-cost reviews.

The project uses **3,000 synthetic insurance claims** and daily economic observations. The analysis brings both datasets to the same annual grain before comparing them.

The central question is:

> **Are changes in claims costs occurring alongside changes in the wider economic environment?**

This does not attempt to prove causation. It creates a reliable analytical foundation for deciding whether the relationship deserves deeper investigation.

---

## Business problem

Claims costs can increase for several reasons:

- Changes in portfolio mix
- Changes in claim types
- Higher repair or replacement costs
- General inflation
- Customer behavior
- Broader economic conditions

Looking only at internal claims data makes it difficult to separate portfolio movement from external conditions.

MacroRisk adds that external context.

```text
Claims Data
     ↓
Annual Claims Profile
     +
Economic Data
     ↓
Annual Economic Profile
     ↓
Common-Grain Join
     ↓
Claims Cost vs. Economic Context
     ↓
Pricing / Reserve Review
