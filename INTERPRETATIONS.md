# 🧠 Task 2 — Interpretation Layer

**Owner:** Pranava Sharma K  
**Purpose:** Convert SQL output into analyst-grade business reasoning.

> **Rule:** the interpretation layer never invents database results. Replace `[LIVE RESULT]` placeholders with verified Metabase values before public publication.

---

## 🛒 E-commerce

### E1 — Activation Curve

**What the query does:** Measures the share of instrumented signup cohorts reaching a meaningful action within 7 days and the time required to activate.

**Pattern choice:** Customer-level first meaningful event followed by cohort aggregation. This prevents multiple actions from turning one customer into multiple activation records.

**Business interpretation:** [LIVE RESULT — identify strongest/weakest mature cohort and activation-speed trend]

**PM Action:** [LIVE RESULT — name the affected cohort and one testable onboarding/traffic/page-speed hypothesis]

**Caveat:** The event stream starts on 2026-04-19. Earlier signups are uninstrumented rather than inactive; the newest 1–2 cohorts may also be censored.

### E2 — Checkout Funnel

**What the query does:** Reduces each checkout session to its deepest observed step and compares progression by first-touch channel.

**Pattern choice:** `max(step_reached)` prevents funnel stages from exceeding previous stages.

**Business interpretation:** Checkout leakage is fairly consistent across channels: the address and shipping transitions each lose roughly 1–4% of sessions, while the cumulative checkout-to-purchase loss is about 13–15%. Organic has the largest absolute leakage because it has the highest checkout volume; affiliate has the highest initial address-step drop at 4.2%.

**PM Action:** Use session recordings, payment/error logs and device/browser cuts to investigate the full checkout-to-purchase path, with an initial focus on affiliate traffic quality and any final-step payment friction.

### E3 — Weekly Behavioural Retention

**What the query does:** Measures meaningful activity in signup-relative weeks 1–4.

**Pattern choice:** Relative `week_index`, not calendar-week joins, to avoid off-by-one cohort errors.

**Business interpretation:** [LIVE RESULT — compare W1 vs W4 and identify whether the pattern is activation or habit formation]

**PM Action:** [LIVE RESULT — activation intervention if early retention is weak; habit/lifecycle intervention if later retention collapses]

### E4 — PDP Engagement

**What the query does:** Finds products with high views but low add-to-cart performance relative to their category median.

**Pattern choice:** Category median is the benchmark; absolute ATC thresholds are not comparable across categories.

**Business interpretation:** [LIVE RESULT — name the highest-priority SKUs and their gap vs category median]

**PM Action:** [LIVE RESULT — assign price, image/content, or stock hypothesis to the top flagged SKUs]

### E5 — Cart Abandonment

**What the query does:** Segments ATC sessions by cart value, measures abandonment and estimates GMV left on the table.

**Pattern choice:** One row per ATC session before bucket aggregation makes the bucket totals additive.

**Business interpretation:** [LIVE RESULT — identify the bucket contributing the largest abandoned GMV]

**PM Action:** [LIVE RESULT — prioritise checkout reliability for high-value leakage or shipping-threshold work for low-value leakage]

---

## ☁️ SaaS

### S1 — MRR Movements

**What the query does:** Classifies historical MRR deltas into new, expansion, contraction, churn and reactivation and reconstructs ending MRR from the as-of snapshot.

**Pattern choice:** Account-level commercial grain with one consistent historical cutoff. Trial starts are excluded from MRR movement math.

**Business interpretation:** November 2022 has the strongest net MRR increase at $2,698.50, driven mainly by $2,770.21 of new MRR plus $56.48 expansion. No displayed month has negative net MRR, but churn becomes materially larger late in the period, reaching -$571.81 in February 2023; January's -$515.38 churn is exactly offset by $515.38 of reactivation.

**PM Action:** Segment the November growth and January–February churn by account_type and normalized plan to determine whether the movement is broad-based or concentrated in a specific customer segment.

### S2 — Trial-to-Paid Conversion

**What the query does:** Tracks first trial per account and conversion within 14/30/60 days.

**Pattern choice:** Separates trial population from paid conversion events so $0 trial state is never mistaken for paid revenue.

**Business interpretation:** The August 5, 2024 trial cohort is the weakest observed cohort at 25% conversion by day 14 (1 of 4 accounts), while the other displayed cohorts range from 33.3% to 100%. For converted trials, median time-to-paid is consistently about 9–14 days, suggesting the main issue is conversion incidence rather than a large delayed-conversion tail.

**PM Action:** Segment the August 5 cohort by acquisition source, trialed plan, company size and country to separate acquisition-quality effects from onboarding, product or pricing friction. Because the cohort contains only four trials, treat the result as a diagnostic signal rather than a statistically stable trend.

### S3 — GRR / NRR

**What the query does:** Compares starting cohort MRR with the same accounts after 12 months and decomposes contraction, churn and expansion.

**Pattern choice:** Reconstructs historical account MRR rather than mixing current subscription snapshots and event deltas in one calculation.

**Business interpretation:** Among the mature cohorts shown, June 2022 is the strongest example with 100.0% GRR and 190.58% NRR, while October 2022 is the weakest at 54.07% GRR and 73.68% NRR. Strong cohorts can materially lift NRR through expansion, but the October cohort shows that expansion cannot compensate for weak gross retention when contraction and churn are large.

**PM Action:** Compare the strong June/September cohorts with the weak October/November cohorts by account type, plan, seat changes and upgrade behaviour, then prioritize retention work where GRR is weak and replicate expansion motions where NRR is sustained above 100%.

### S4 — Feature Adoption vs 90-Day Retention

**What the query does:** Compares 14-day feature adoption at account level with 90-day subscription survival.

**Pattern choice:** Feature usage is joined through `feature_id`, orphan users cannot be reliably attributed to accounts, and adoption is evaluated against a consistent eligible population.

**Business interpretation:** [LIVE RESULT — identify the feature with the strongest lift and group sizes]

**PM Action:** [LIVE RESULT — discoverability push only when the lift is credible; otherwise deepen with intent-matched analysis]

**Causal warning:** This is observational. Feature adopters may simply be more engaged.

### S5 — Expansion Revenue

**What the query does:** Separates expansion into seat additions, plan upgrades and add-ons.

**Pattern choice:** Directly uses documented `event_type` vocabulary and signed `mrr_delta`, then aggregates at account grain.

**Business interpretation:** Seat additions are the dominant expansion motion, generating $7,662.00 (53.7%) of total expansion MRR across 34 accounts. Plan upgrades contribute $6,348.80 (44.5%), while add-ons contribute only $261.80 (1.8%).

**PM Action:** Prioritize frictionless seat-management and self-serve seat-addition flows, with clear incremental pricing. Treat add-on cross-sell as a secondary opportunity until additional demand evidence supports investment.

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
