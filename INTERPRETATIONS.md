# 🧠 Task 2 — Interpretation Layer

**Owner:** Pranava Sharma K  
**Purpose:** Convert SQL output into analyst-grade business reasoning.

> **Rule:** The interpretation layer reports only values verified from the submitted Metabase outputs. Cohort censoring and small sample sizes are called out where they materially affect the conclusion.

---

## 🛒 E-commerce

### E1 — Activation Curve

**What the query does:** Measures the share of instrumented signup cohorts reaching a meaningful action within 7 days and the time required to activate.

**Pattern choice:** Customer-level first meaningful event followed by cohort aggregation. This prevents multiple actions from turning one customer into multiple activation records.

**Business interpretation:** The strongest mature cohort is **May 18, 2026**, with **22%** of signups activating within 7 days (**169/780**). Among mature cohorts, activation then falls to **16% on May 25** and **13% on June 1**; the latest June 8 cohort is only **8.8%** but should be treated as censored. Median time-to-activation remains roughly **4,000–4,600 minutes** across the mature cohorts, so the main concern is a lower share of users activating rather than a clear slowdown among users who do activate.

**PM Action:** Investigate the post-May-18 activation decline by cohort and acquisition source, then compare onboarding completion, landing-page performance and page-speed signals. Treat June 8 as directional until its full 7-day window closes.

**Caveat:** The event stream starts on 2026-04-19. Earlier signups are uninstrumented rather than inactive; the newest cohort is also censored.

### E2 — Checkout Funnel

**What the query does:** Reduces each checkout session to its deepest observed step and compares progression by first-touch channel.

**Pattern choice:** `max(step_reached)` prevents funnel stages from exceeding previous stages.

**Business interpretation:** Checkout leakage is fairly consistent across channels: the address and shipping transitions lose only a few percentage points, while the full checkout-to-purchase path leaves roughly **13–15%** of sessions without a purchase. Organic has the largest absolute leakage because it has the highest checkout volume, while Affiliate has the weakest first-step progression.

**PM Action:** Investigate the checkout-to-purchase path using payment/error logs, session recordings and device/browser cuts; avoid assuming the issue is a single payment-step defect without diagnostic evidence.

### E3 — Weekly Behavioural Retention

**What the query does:** Measures meaningful activity in signup-relative weeks 1–4.

**Pattern choice:** Relative `week_index`, not calendar-week joins, to avoid off-by-one cohort errors.

**Business interpretation:** Across the mature cohorts shown, **W1 retention is roughly 25–36%**, while **W4 retention ranges from 36% for the April 13 cohort to 12% for the May 11 cohort**. The meaningful deterioration happens later in the customer lifecycle rather than at the initial return step, pointing more toward a **habit-formation / lifecycle engagement problem** than a pure activation problem. The zeroes for May 18 onward should not be treated as true retention failures where the W4 observation window is not yet complete.

**PM Action:** Focus on weeks 2–4 engagement: identify the behaviours shared by the strongest April cohorts, then test lifecycle prompts, recommendations or return-use cases before and around the point where W4 retention falls away.

**Caveat:** Recent cohorts are censored for later weeks; incomplete W4 windows are not equivalent to zero retention.

### E4 — PDP Engagement

**What the query does:** Finds products with high views but low add-to-cart performance relative to their category median.

**Pattern choice:** Category median is the benchmark; absolute ATC thresholds are not comparable across categories.

**Business interpretation:** **Suta Threads Velvet Kajal** is the highest-view flagged SKU (**4,334 views**) but has only a **6.0% ATC rate**, at about **17% of its category median**. **Indigo Lane Origins Longwear Eyeshadow Palette** is the next strongest priority (**2,644 views**, **5.8% ATC**, about **16% of category median**); the other top-view flagged SKUs also sit at roughly **16–22% of their category medians** despite substantial traffic. This makes the highest-volume, lowest-relative-engagement products the clearest merchandising opportunities.

**PM Action:** Audit the top flagged SKUs for price competitiveness, image/content quality, availability and variant friction, then run a targeted PDP test rather than changing the whole category at once.

**Caveat:** Low ATC performance is diagnostic, not causal; the SQL cannot by itself distinguish pricing, content, inventory or traffic-quality causes.

### E5 — Cart Abandonment

**What the query does:** Segments ATC sessions by cart value, measures abandonment and estimates GMV left on the table.

**Pattern choice:** One row per ATC session before bucket aggregation makes the bucket totals additive.

**Business interpretation:** The **₹5,000–₹14,999** bucket contributes the most abandoned GMV at **₹9,848,217.87**, about **40.7%** of the abandoned GMV across the five buckets shown. Its abandonment rate is only **20%**, lower than the cheaper buckets, but the much larger cart values make its absolute rupee impact highest; the **₹15,000+** bucket is the next-largest loss at about **₹5.88M**.

**PM Action:** Prioritize checkout reliability and payment/fulfilment friction for the **₹5,000+** customer journey, because a relatively modest abandonment rate can still create very large GMV leakage at high cart values.

---

## ☁️ SaaS

### S1 — MRR Movements

**What the query does:** Classifies historical MRR deltas into new, expansion, contraction, churn and reactivation and reconstructs ending MRR from the as-of snapshot.

**Pattern choice:** Account-level commercial grain with one consistent historical cutoff. Trial starts are excluded from MRR movement math.

**Business interpretation:** November 2022 produced the strongest net MRR increase at **$2,698.50**, driven mainly by **$2,770.21 new MRR**. No displayed month had negative net MRR, but churn became more material later, reaching **-$571.81 in February 2023**; January churn of **-$515.38** was fully offset by equal reactivation MRR.

**PM Action:** Segment the late-period churn by account type, normalized plan and signup cohort to identify where retention risk is concentrated.

### S2 — Trial-to-Paid Conversion

**What the query does:** Tracks first trial per account and conversion within 14/30/60 days.

**Pattern choice:** Separates trial population from paid conversion events so $0 trial state is never mistaken for paid revenue.

**Business interpretation:** The **August 5, 2024** cohort is the weakest observed cohort at **25% conversion by day 14**, while several other cohorts reach 50–100%. Among converted trials, median time-to-paid is consistently around **9–14 days**, suggesting the main issue is conversion incidence rather than a large delayed-conversion tail.

**PM Action:** Segment the weak cohort by acquisition source, trialed plan, company size and country; the cohort is small, so use it as a diagnostic signal rather than a definitive trend.

### S3 — GRR / NRR

**What the query does:** Compares starting cohort MRR with the same accounts after 12 months and decomposes contraction, churn and expansion.

**Pattern choice:** Reconstructs historical account MRR rather than mixing current subscription snapshots and event deltas in one calculation.

**Business interpretation:** Mature cohort outcomes vary substantially: June 2022 shows **100% GRR and 190.58% NRR**, while October 2022 falls to **54.07% GRR and 73.68% NRR**. The stronger cohorts demonstrate that expansion can materially offset contraction and churn, while weaker cohorts remain below 100% even after expansion is included.

**PM Action:** Compare strong and weak cohorts by account type, plan, seat changes and upgrade behaviour to identify repeatable retention and expansion motions.

### S4 — Feature Adoption vs 90-Day Retention

**What the query does:** Compares 14-day feature adoption at account level with 90-day subscription survival.

**Pattern choice:** Feature usage is joined through `feature_id`, and the analysis explicitly acknowledges that adopter/non-adopter differences are observational rather than causal.

**Business interpretation:** **CLI Tool** has the strongest observed retention lift at **+45.19 percentage points** (**75% vs 29% retention**), but only **4 accounts adopted** it versus **1,097 non-adopters**, so the estimate is highly sample-sensitive. **API Bulk Operations** shows a smaller but more informative **+23.08 pp lift** with **21 adopters**, making it the better candidate for validation; several features, including **Zapier Integration (-10.43 pp)** and **Bulk Export (-7.67 pp)**, are negatively associated with retention.

**PM Action:** Do not launch a broad discoverability push from the CLI result alone. Validate the positive association with larger adopter samples and intent-matched segmentation, prioritising API Bulk Operations as the more stable follow-up candidate.

**Causal warning:** This is observational. Feature adopters may simply be more engaged or systematically different from non-adopters.

### S5 — Expansion Revenue

**What the query does:** Separates expansion into seat additions, plan upgrades and add-ons.

**Pattern choice:** Directly uses documented `event_type` vocabulary and signed `mrr_delta`, then aggregates at account grain.

**Business interpretation:** Seat additions are the dominant expansion motion, generating **$7,662.00 (53.7%)** of total expansion MRR across 34 accounts. Plan upgrades contribute **$6,348.80 (44.5%)**, while add-ons contribute only **$261.80 (1.8%)**, making add-ons a comparatively minor expansion lever in this period.

**PM Action:** Prioritize frictionless seat-management and self-serve expansion UX, while treating add-on cross-sell as a secondary opportunity until stronger demand is demonstrated.

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
