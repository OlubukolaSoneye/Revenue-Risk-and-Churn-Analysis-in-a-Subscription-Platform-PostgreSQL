SELECT COUNT(*) FROM customer_subscription;

SELECT 
    COUNT(*) AS total_customers,
    ROUND(AVG(churn::numeric) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(monthlycharges), 2) AS total_mrr,
    ROUND(SUM(CASE WHEN churn = 1 THEN monthlycharges ELSE 0 END), 2) AS mrr_at_risk
FROM customer_subscription;

SELECT 
    subscriptiontype,
    COUNT(*) AS customers,
    ROUND(AVG(churn::numeric) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(monthlycharges), 2) AS revenue,
    ROUND(SUM(CASE WHEN churn = 1 THEN monthlycharges ELSE 0 END), 2) AS revenue_at_risk
FROM customer_subscription
GROUP BY subscriptiontype
ORDER BY revenue DESC; 

SELECT *
FROM customer_subscription
WHERE subscriptiontype IS NULL;

UPDATE customer_subscription
SET subscriptiontype = 'Unknown'
WHERE subscriptiontype IS NULL;

SELECT 
    subscriptiontype,
    COUNT(*) AS customers,
    ROUND(AVG(churn::numeric) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(monthlycharges), 2) AS revenue,
    ROUND(SUM(CASE WHEN churn = 1 THEN monthlycharges ELSE 0 END), 2) AS revenue_at_risk
FROM customer_subscription
GROUP BY subscriptiontype
ORDER BY revenue DESC;

WITH revenue_rank AS (
    SELECT 
        customerid,
        monthlycharges,
        SUM(monthlycharges) OVER () AS total_revenue,
        RANK() OVER (ORDER BY monthlycharges DESC) AS revenue_rank
    FROM customer_subscription
)

WITH revenue_rank AS (
    SELECT 
        customerid,
        monthlycharges,
        SUM(monthlycharges) OVER () AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY monthlycharges DESC) AS rn
    FROM customer_subscription
    WHERE monthlycharges IS NOT NULL
),
cutoff AS (
    SELECT CEIL(COUNT(*) * 0.2)::int AS top_n
    FROM revenue_rank
)

SELECT COUNT(*) FROM customer_subscription;

WITH revenue_rank AS (
    SELECT 
        customerid,
        monthlycharges,
        SUM(monthlycharges) OVER () AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY monthlycharges DESC) AS rn
    FROM customer_subscription
    WHERE monthlycharges IS NOT NULL
)
SELECT 
    COUNT(*) AS top_20pct_customers,
    ROUND(SUM(monthlycharges), 2) AS revenue_from_top,
    ROUND(MAX(total_revenue), 2) AS total_revenue,
    ROUND(SUM(monthlycharges) / MAX(total_revenue) * 100, 2) AS revenue_share_pct
FROM revenue_rank
WHERE rn <= (
    SELECT CEIL(COUNT(*) * 0.2)
    FROM customer_subscription
);  

SELECT 
    COUNT(*) AS top_20pct_customers,
    ROUND(SUM(monthlycharges), 2) AS revenue_from_top,
    ROUND(SUM(CASE WHEN churn = 1 THEN monthlycharges ELSE 0 END), 2) AS top_revenue_at_risk
FROM (
    SELECT *
    FROM customer_subscription
    WHERE monthlycharges IS NOT NULL
    ORDER BY monthlycharges DESC
    LIMIT (
        SELECT CEIL(COUNT(*) * 0.2)
        FROM customer_subscription
        WHERE monthlycharges IS NOT NULL
    )
) AS top_customers; 

SELECT 
    subscriptiontype,
    AVG(viewinghoursperweek) AS avg_viewing_hours,
    AVG(supportticketspermonth) AS avg_support_tickets,
    AVG(watchlistsize) AS avg_watchlist_size,
    AVG(userrating) AS avg_rating
FROM customer_subscription
WHERE monthlycharges >= (
    SELECT percentile_cont(0.8) 
    WITHIN GROUP (ORDER BY monthlycharges)
    FROM customer_subscription
)
GROUP BY subscriptiontype;  

SELECT 
    churn,
    ROUND(AVG(viewinghoursperweek),2) AS avg_viewing,
    ROUND(AVG(supportticketspermonth),2) AS avg_support,
    ROUND(AVG(userrating),2) AS avg_rating
FROM customer_subscription
WHERE monthlycharges >= (
    SELECT percentile_cont(0.8) 
    WITHIN GROUP (ORDER BY monthlycharges)
    FROM customer_subscription
)
GROUP BY churn; 

SELECT 
    ROUND(AVG(monthlycharges),2) AS avg_price,
    ROUND(AVG(churn::numeric)*100,2) AS churn_rate
FROM customer_subscription
GROUP BY subscriptiontype
ORDER BY avg_price DESC; 