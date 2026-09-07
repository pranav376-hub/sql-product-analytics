# 🧠 Task 2 — Interpretation Layer

**Owner:** Pranava Sharma K  
**Purpose:** Convert SQL output into analyst-grade business reasoning.

> **Rule:** the interpretation layer never invents database results. Replace `[LIVE RESULT]` placeholders with verified Metabase values before public publication.

---

## 🛒 E-commerce

### E1 — Activation Curve

**What the query does:** Measures the share of instrumented signup cohorts reaching a meaningful action within 7 days and the time required to activate.

**Pattern choice:** Customer-level first meaningful event followed by cohort aggregation. This prevents multiple actions from turning one customer into multiple activation records.

**Business interpretation:** `[LIVE RESULT — identify strongest/weakest mature cohort and activation-speed trend]`

**PM Action:** `[LIVE RESULT — name the affected cohort and one testable onboarding/traffic/page-speed hypothesis]`

**Caveat:** The event stream starts on 2026-04-19. Earlier signups are uninstrumented rather than inactive; the newest 1–2 cohorts may also be censored.

### E2 — Checkout Funnel

**What the query does:** Reduces each checkout session to its deepest observed step and compares progression by first-touch channel.

**Pattern choice:** `max(step_reached)` prevents funnel stages from exceeding previous stages.

**Business interpretation:** `[LIVE RESULT — identify the worst step and channel differential]`

**PM Action:** `[LIVE RESULT — assign the worst step to a session-recording / heatmap investigation]`

### E3 — Weekly Behavioural Retention

**What the query does:** Measures meaningful activity in signup-relative weeks 1–4.

**Pattern choice:** Relative `week_index`, not calendar-week joins, to avoid off-by-one cohort errors.

**Business interpretation:** `[LIVE RESULT — compare W1 vs W4 and identify whether the pattern is activation or habit formation]`

**PM Action:** `[LIVE RESULT — activation intervention if early retention is weak; habit/lifecycle intervention if later retention collapses]`

### E4 — PDP Engagement

**What the query does:** Finds products with high views but low add-to-cart performance relative to their category median.

**Pattern choice:** Category median is the benchmark; absolute ATC thresholds are not comparable across categories.

**Business interpretation:** `[LIVE RESULT — name the highest-priority SKUs and their gap vs category median]`

**PM Action:** `[LIVE RESULT — assign price, image/content, or stock hypothesis to the top flagged SKUs]`

### E5 — Cart Abandonment

**What the query does:** Segments ATC sessions by cart value, measures abandonment and estimates GMV left on the table.

**Pattern choice:** One row per ATC session before bucket aggregation makes the bucket totals additive.

**Business interpretation:** `[LIVE RESULT — identify the bucket contributing the largest abandoned GMV]`

**PM Action:** `[LIVE RESULT — prioritise checkout reliability for high-value leakage or shipping-threshold work for low-value leakage]`

---

## ☁️ SaaS

### S1 — MRR Movements

**What the query does:** Classifies historical MRR deltas into new, expansion, contraction, churn and reactivation and reconstructs ending MRR from the as-of snapshot.

**Pattern choice:** Account-level commercial grain with one consistent historical cutoff. Trial starts are excluded from MRR movement math.

**Business interpretation:** `[LIVE RESULT — largest positive and negative movement months and dominant bucket]`

**PM Action:** `[LIVE RESULT — cut the largest mover by account_type and plan]`

### S2 — Trial-to-Paid Conversion

**What the query does:** Tracks first trial per account and conversion within 14/30/60 days.

**Pattern choice:** Separates trial population from paid conversion events so $0 trial state is never mistaken for paid revenue.

**Business interpretation:** `[LIVE RESULT — identify the weakest mature cohort and conversion-speed pattern]`

**PM Action:** `[LIVE RESULT — qualify by source, plan, company size or country]`

### S3 — GRR / NRR

**What the query does:** Compares starting cohort MRR with the same accounts after 12 months and decomposes contraction, churn and expansion.

**Pattern choice:** Reconstructs historical account MRR rather than mixing current subscription snapshots and event deltas in one calculation.

**Business interpretation:** `[LIVE RESULT — state mature GRR/NRR and whether retention or expansion is the stronger story]`

**PM Action:** `[LIVE RESULT — retention programme when GRR is weak; customer-success / expansion investment when NRR is strongly above 100%]`

### S4 — Feature Adoption vs 90-Day Retention

**What the query does:** Compares 14-day feature adoption at account level with 90-day subscription survival.

**Pattern choice:** Feature usage is joined through `feature_id`, orphan users cannot be reliably attributed to accounts, and adoption is evaluated against a consistent eligible population.

**Business interpretation:** `[LIVE RESULT — identify the feature with the strongest lift and group sizes]`

**PM Action:** `[LIVE RESULT — discoverability push only when the lift is credible; otherwise deepen with intent-matched analysis]`

**Causal warning:** This is observational. Feature adopters may simply be more engaged.

### S5 — Expansion Revenue

**What the query does:** Separates expansion into seat additions, plan upgrades and add-ons.

**Pattern choice:** Directly uses documented `event_type` vocabulary and signed `mrr_delta`, then aggregates at account grain.

**Business interpretation:** `[LIVE RESULT — identify the dominant expansion vector and its share of total expansion MRR]`

**PM Action:** `[LIVE RESULT — seat-management UX, pricing-tier differentiation, or cross-sell discovery]`

---

# 🎯 Cross-domain executive readout

| Theme | E-commerce | SaaS |
|---|---|---|
| **Core question** | Are customers moving smoothly through a purchase journey? | Are accounts converting, retaining and expanding recurring value? |
| **Primary grain** | Session / customer | Account / subscription |
| **Main clock** | Minutes → weeks | Days → months |
| **Retention meaning** | Behavioural return | Revenue durability |
| **Best decision output** | UX / merchandising / checkout action | Pricing / onboarding / CS / expansion action |

The analytical skill that transfers across both domains is **metric discipline**: define the entity, denominator, time window and validation rule before trusting the result.
