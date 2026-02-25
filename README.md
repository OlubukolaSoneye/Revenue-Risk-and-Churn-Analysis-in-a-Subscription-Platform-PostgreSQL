## 📉 Customer Churn and Revenue Risk Analysis

## 📌 Project Overview
Subscription platforms depend on predictable recurring revenue. Customer churn directly threatens financial stability — particularly when high-value customers disengage silently before cancelling. This project uses PostgreSQL to analyse subscription behaviour, quantify revenue exposure, and identify the behavioural drivers behind churn. The goal is to move beyond descriptive reporting and produce commercially actionable retention insight.

## 🎯 Project Objectives
Quantify total recurring revenue and revenue currently at risk
Identify revenue concentration across the customer base 
Analyse churn rates by subscription plan
Evaluate behavioural differences between retained and churned customers
Test whether churn is driven by price or engagement
Deliver data-driven commercial recommendations


## 🗂️ Dataset Overview
The initial dataset contained 963 subscription customers with the following attributes:

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

## 🔧 Data Cleaning & Preparation
Before analysis, 50 customers had NULL subscription types. Further inspection of these rows revealed missing values across multiple columns including monthlycharges, userrating, and paymentmethod making the rows unreliable for further analysis. These 50 records were excluded from the analysis. Final working dataset: 913 customers. 

```sql
SELECT COUNT(*) AS null_subscription_customers
FROM customer_subscription
WHERE subscriptiontype IS NULL;

DELETE FROM customer_subscription
WHERE subscriptiontype = 'Unknown';
```

## 📊 Analysis
1. Executive Baseline Metrics
The first step establishes the commercial baseline: how much revenue exists, how much is exposed, and what the overall churn rate looks like.

```sql
SELECT 
    COUNT(*) AS total_customers,
    ROUND(AVG(churn::numeric) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(monthlycharges), 2) AS total_mrr,
    ROUND(SUM(CASE WHEN churn = 1 THEN monthlycharges ELSE 0 END), 2) AS mrr_at_risk
FROM customer_subscription;
```
Roughly 20% of recurring revenue is currently exposed, indicating moderate but strategically significant churn risk.

<p align="left">
  <img src="Screenshot 2026-02-25 at 16.49.14.png" width="400"/>
</p>

2. Revenue by Subscription Plan
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
Premium customers generate the highest revenue (£3,329.83) and therefore represent the largest absolute exposure (£668.87), making this segment strategically critical despite a moderate churn rate (16.82%). Basic shows the highest churn (18.77%) while still contributing meaningful revenue (£2,801.31), indicating elevated retention risk within a price-sensitive tier. Standard is the most stable segment, combining strong revenue (£2,715.06) with the lowest churn (16.38%).

<p align="left">
  <img src="Screenshot 2026-02-25 at 16.55.53.png" width="400"/>
</p>

3. Revenue Concentration
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

The top 20% of customers generate £2,642.11 in monthly revenue, with £633.82 attributable to churned users. This indicates that nearly 24% of high-value revenue has been lost, signalling concentrated financial risk within the most valuable segment.
<p align="left">
  <img src="Screenshot 2026-02-25 at 17.05.50.png" width="400"/>
</p>

4. Behavioural Drivers of Churn
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

Within the top revenue segment, churn correlates with lower engagement and higher support interaction, while satisfaction scores remain stable, indicating behavioural friction, not price or sentiment, as the primary driver.
<p align="left">
  <img src="Screenshot 2026-02-25 at 17.26.16.png" width="400"/>
</p>


5. Pricing vs Churn
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

Despite near-identical average pricing across plans, churn differs across the categories. Basic exhibits the highest churn rate, this suggests churn is not primarily price-driven.
<p align="left">
  <img src="Screenshot 2026-02-25 at 17.47.44.png" width="400"/>
</p>

## 💡 Commercial Recommendations
1. Prioritise high-value retention.
The top 20% of customers generate 37% of total revenue, with £690 already lost within this segment. Churned high-value customers exhibit materially lower engagement prior to exit, making weekly viewing hours a practical early-warning indicator. Monitoring sustained engagement decline allows for proactive intervention before revenue is lost.

2. Reduce operational friction.
Churned customers generate more support tickets than retained users, particularly within the Premium segment. Elevated service interaction suggests product or support friction is accelerating churn decisions. Improving resolution speed and implementing proactive support outreach may directly mitigate this risk.

3. Address Basic plan instability.
The Basic tier records the highest churn rate among core plans. While pricing differences are minimal, the elevated churn suggests perceived value or onboarding effectiveness may be weaker in this segment. Targeted investigation and value reinforcement are recommended.

## 🎯 Key Takeaway
Churn analysis should not be limited to counting customer exits. By weighting churn against revenue exposure, segmenting customers by value, and testing behavioural versus financial drivers, this project reframes churn as a revenue-risk problem rather than a volume metric.

The results indicate that churn is not primarily price-driven. Instead, declining engagement and increased support interaction are stronger predictors of exit. These signals are observable in advance, enabling proactive, revenue-focused retention strategies targeted where financial impact is greatest.

## Tools 
PostgreSQL, pgAdmin, SQL (Window Functions, Percentiles, Aggregations)  


