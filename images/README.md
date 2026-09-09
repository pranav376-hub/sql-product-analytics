# 🖼️ Portfolio Image Guide

This folder is intentionally limited to **relevant portfolio evidence**. Do not add generic stock images or unrelated dashboard screenshots.

## Required / recommended images

### 1. `ecom_er_diagram.png`
**Source:** Already included from Task 1.

**Use:** README → **Data Model → E-commerce relationship model**

**Purpose:** Demonstrates schema understanding and the relationship structure inherited from Task 1.

---

### 2. `saas_er_diagram.png`
**Source:** Included in this repository.

**Use:** README → **Data Model → SaaS relationship model**

**Purpose:** Makes the account → users → subscriptions → events → features architecture immediately visible.

---

### 3. `e2_checkout_funnel.png`
**Capture from Metabase:** Query **E2 — Checkout Funnel Drop-off by Entry Channel**.

**The screenshot should show:**
- Query/card title
- Channel dimension
- Begin checkout → address → shipping → payment → purchased counts
- The relevant filter/date range
- Result table or chart clearly readable

**Use:** README → E-commerce evidence and Notion case study.

**Why this image matters:** It is the strongest visual proof that the funnel is being analysed at session grain and that the step counts are monotonic.

---

### 4. `e3_cohort_retention.png`
**Capture from Metabase:** Query **E3 — Cohort Retention Curve**.

**The screenshot should show:**
- Cohort week
- Cohort size
- W1–W4 retained counts/rates
- Enough rows to show different cohort behaviour

**Use:** README → E-commerce evidence and Notion case study.

**Why this image matters:** It visually demonstrates cohort analysis, relative-week logic and retention maturity/censoring.

---

### 5. `s1_mrr_movements.png`
**Capture from Metabase:** Query **S1 — Monthly MRR Movement Decomposition**.

**The screenshot should show:**
- Month
- New MRR
- Expansion MRR
- Contraction MRR
- Churn MRR
- Reactivation MRR
- Net New MRR
- Ending MRR

**Use:** README → SaaS evidence and Notion case study.

**Why this image matters:** Recruiters can immediately see that the project goes beyond behavioural analytics into recurring-revenue economics.

---

### 6. `s3_grr_nrr.png`
**Capture from Metabase:** Query **S3 — GRR / NRR by Cohort**.

**The screenshot should show:**
- Cohort month
- Starting MRR
- Retained MRR after 12 months
- Expansion / contraction / churn
- GRR
- NRR

**Use:** README → SaaS evidence and Notion case study.

**Why this image matters:** This is the strongest B2B SaaS portfolio visual because it shows revenue retention rather than only user activity.

---

### 7. `s5_expansion_revenue.png`
**Capture from Metabase:** Query **S5 — Expansion Revenue**.

**The screenshot should show:**
- `seats_added`
- `plan_upgrade`
- `addon`
- Expansion event counts
- Accounts expanded
- Expansion MRR total
- Expansion MRR per account

**Use:** README → SaaS evidence / case study.

**Why this image matters:** It connects product behaviour to a monetisation decision: where expansion actually comes from.

---


