## 📉 Customer Lifecycle & Revenue Risk Analysis
### PostgreSQL | Subscription Analytics | Commercial Insight


> **Tools:** PostgreSQL · pgAdmin · SQL (Window Functions, Percentiles, Aggregations)  
> **Dataset:** 963 subscription customers  
> **Focus:** Churn quantification, revenue concentration, behavioural diagnostics


## 📌 Project Overview

Subscription platforms depend on predictable recurring revenue. Customer churn directly threatens financial stability — particularly when high-value customers disengage silently before cancelling.

This project uses PostgreSQL to analyse subscription behaviour, quantify revenue exposure, and identify the behavioural drivers behind churn. The goal is to move beyond descriptive reporting and produce commercially actionable retention insight.

> 📸 **Screenshot suggestion:** Add a cover image showing your pgAdmin workspace or a summary of key results — save as `images/project-cover.png`

---

## 🎯 Project Objectives

- Quantify total recurring revenue and revenue currently at risk
- Identify revenue concentration across the customer base
- Analyse churn rates by subscription plan
- Evaluate behavioural differences between retained and churned customers
- Test whether churn is driven by price or engagement
- Deliver data-driven commercial recommendations

---

## 🗂️ Dataset Overview

The dataset contains **963 subscription customers** with the following attributes:

| Column | Description |
|---|---|
| `customerid` | Unique customer identifier |
| `accountage` | Duration of the customer relationship |
| `monthlycharges` | Monthly subscription fee |
| `totalcharges` | Cumulative charges to date |
| `subscriptiontype` | Plan tier: Basic, Standard, or Premium |
| `paymentmethod` | Payment method on file |
| `viewinghoursperweek` | Weekly platform engagement |
| `averageviewingduration` | Average session length per view |
| `supportticketspermonth` | Monthly support interactions |
| `userrating` | Customer satisfaction rating |
| `churn` | Target variable — `0` = retained, `1` = churned |

---

## 🔧 Data Cleaning & Preparation

Before analysis, 50 customers had `NULL` subscription types. These were standardised to preserve categorical integrity across all segmentation queries.

```sql
UPDATE customer_subscription
SET subscriptiontype = 'Unknown'
WHERE subscriptiontype IS NULL;
```

> 📸 **Screenshot suggestion:** Show the pgAdmin query result confirming `50 rows affected` — save as `images/data-cleaning.png`

---

## 📊 Analysis

### 1️⃣ Executive Baseline Metrics

The first step establishes the commercial baseline: how much revenue exists, how much is exposed, and what the overall churn rate looks like.

```sql
SELECT 
    COUNT(*) AS total_customers,
    ROUND(AVG(churn::numeric) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(monthlycharges), 2) AS total_mrr,
    ROUND(SUM(CASE WHEN churn = 1 THEN monthlycharges ELSE 0 END), 2) AS mrr_at_risk
FROM customer_subscription;
```

**Results**

| Metric | Value |
|---|---|
| Total Customers | 963 |
| Churn Rate | 17.55% |
| Total Monthly Revenue (MRR) | £9,357 |
| Revenue at Risk | £1,878 |

Approximately **20% of recurring revenue** is currently exposed to churn — a material financial risk requiring a structured retention response.

> 📸 **Screenshot suggestion:** Show the query output table in pgAdmin — save as `images/baseline-metrics.png`

---

### 2️⃣ Revenue by Subscription Plan

Breaking down churn and revenue by plan reveals where retention investment will have the greatest impact.

```sql
SELECT 
    subscriptiontype,
    COUNT(*) AS customers,
    ROUND(AVG(churn::numeric) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(monthlycharges), 2) AS revenue,
    ROUND(SUM(CASE WHEN churn = 1 THEN monthlycharges ELSE 0 END), 2) AS revenue_at_risk
FROM customer_subscription
GROUP BY subscriptiontype
ORDER BY revenue DESC;
```

**Key Insights**

- **Premium** generates the highest total revenue and carries the largest absolute revenue exposure
- **Basic** shows the highest churn rate among core plans
- **Standard** is the most stable plan by churn behaviour
- **Unknown** (null records) shows the highest churn — a data quality risk worth investigating

> 📸 **Screenshot suggestion:** Show the full results table in pgAdmin with all plan rows visible — save as `images/plan-breakdown.png`

---

### 3️⃣ Revenue Concentration — Pareto Analysis

Understanding whether revenue is concentrated among a small group of customers determines how targeted retention strategies should be.

```sql
SELECT 
    COUNT(*) AS top_20pct_customers,
    ROUND(SUM(monthlycharges), 2) AS revenue_from_top,
    ROUND(
        SUM(monthlycharges) /
        (SELECT SUM(monthlycharges) FROM customer_subscription) * 100,
        2
    ) AS revenue_share_pct
FROM (
    SELECT monthlycharges
    FROM customer_subscription
    WHERE monthlycharges IS NOT NULL
    ORDER BY monthlycharges DESC
    LIMIT (
        SELECT CEIL(COUNT(*) * 0.2)
        FROM customer_subscription
        WHERE monthlycharges IS NOT NULL
    )
) AS top_customers;
```

**Finding:** The top 20% of customers generate **37% of total revenue**.

While not a classic 80/20 split, this moderate concentration still means retaining high-value customers has a disproportionate effect on overall MRR stability. A 5% reduction in churn within this segment would recover approximately £35/month — with compounding effect over tenure.

> 📸 **Screenshot suggestion:** Show the query result with `top_20pct_customers`, `revenue_from_top`, and `revenue_share_pct` columns — save as `images/pareto-analysis.png`

---

### 4️⃣ High-Value Revenue at Risk

Isolating churn within the top 20% revenue segment quantifies the strategic exposure more precisely.

| Metric | Value |
|---|---|
| Revenue from top 20% | £2,793 |
| Revenue at risk within segment | £690 |
| Share of high-value revenue exposed | ~25% |

One in four pounds generated by the most valuable customers is currently at risk. This is not evenly distributed churn — it is a concentrated and preventable loss.

> 📸 **Screenshot suggestion:** Show the query filtering customers above the 80th percentile of `monthlycharges` with the at-risk revenue calculation — save as `images/high-value-risk.png`

---

### 5️⃣ Behavioural Drivers of Churn

Using the 80th percentile of `monthlycharges` as the high-value threshold, this query compares engagement and friction metrics between retained and churned customers.

```sql
SELECT 
    churn,
    ROUND(AVG(viewinghoursperweek), 2) AS avg_viewing,
    ROUND(AVG(supportticketspermonth), 2) AS avg_support,
    ROUND(AVG(userrating), 2) AS avg_rating
FROM customer_subscription
WHERE monthlycharges >= (
    SELECT percentile_cont(0.8) 
    WITHIN GROUP (ORDER BY monthlycharges)
    FROM customer_subscription
)
GROUP BY churn;
```

**Results**

| Metric | Retained | Churned |
|---|---|---|
| Avg Viewing Hours / Week | 21.58 | 16.66 |
| Avg Support Tickets / Month | 4.25 | 4.84 |
| Avg User Rating | 3.06 | 3.21 |

**Interpretation**

- Churned customers show **23% lower engagement** — disengagement precedes cancellation
- Churned customers raise **more support tickets** — operational friction increases exit likelihood
- User ratings show **no meaningful difference** — satisfaction scores alone are not reliable churn predictors

> 📸 **Screenshot suggestion:** Show the side-by-side results for `churn = 0` and `churn = 1` in pgAdmin — save as `images/behavioural-analysis.png`

---

### 6️⃣ Pricing vs Churn

Testing whether price is the primary churn driver by comparing average charges and churn rates across plans.

```sql
SELECT 
    subscriptiontype,
    ROUND(AVG(monthlycharges), 2) AS avg_price,
    ROUND(AVG(churn::numeric) * 100, 2) AS churn_rate
FROM customer_subscription
GROUP BY subscriptiontype
ORDER BY avg_price DESC;
```

**Finding:** Price variation across plans is minimal, yet churn rates differ meaningfully between segments.

Churn is **not primarily price-driven**. Engagement decline and support friction are stronger predictors of customer exit than monthly charge levels.

> 📸 **Screenshot suggestion:** Show the results table with `avg_price` and `churn_rate` side by side across all plans — save as `images/pricing-vs-churn.png`

---

## 💡 Commercial Recommendations

| Priority | Action |
|---|---|
| 🔴 High | Implement proactive outreach for high-value customers showing engagement decline |
| 🔴 High | Track weekly viewing hours as an early churn signal — intervene before cancellation |
| 🟡 Medium | Reduce support ticket resolution time in the Premium segment |
| 🟡 Medium | Investigate root causes of elevated Basic plan churn |
| 🟢 Low | Develop content and loyalty incentives to re-engage at-risk users |

---

## 🎯 Key Takeaways

This project demonstrates how structured SQL analysis can move beyond descriptive reporting to deliver commercially grounded insight:

- **Revenue-weighted churn analysis** — not all churners cost the same
- **Customer segmentation logic** — identifying where risk is actually concentrated
- **Behavioural diagnostics** — engagement and friction outperform pricing as churn predictors
- **Retention prioritisation** — directing effort where financial impact is highest

---

## 🗂️ Repository Structure

```
├── README.md
├── sql/
│   ├── 01_baseline_metrics.sql
│   ├── 02_revenue_by_plan.sql
│   ├── 03_pareto_analysis.sql
│   ├── 04_high_value_risk.sql
│   ├── 05_behavioural_drivers.sql
│   └── 06_pricing_vs_churn.sql
└── images/
    ├── project-cover.png
    ├── data-cleaning.png
    ├── baseline-metrics.png
    ├── plan-breakdown.png
    ├── pareto-analysis.png
    ├── high-value-risk.png
    ├── behavioural-analysis.png
    └── pricing-vs-churn.png
