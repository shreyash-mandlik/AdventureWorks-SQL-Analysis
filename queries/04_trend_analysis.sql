/* ================================================
   04 - Trend Analysis (MoM Growth + Cohort Retention)
   AdventureWorks PostgreSQL
   ================================================ */

/* ---- PART 1: Month-over-Month Revenue Growth ---- */

WITH monthly_revenue AS (
    SELECT
        EXTRACT(YEAR FROM orderdate)                   AS order_year,
        EXTRACT(MONTH FROM orderdate)                  AS order_month,
        DATE_TRUNC('month', orderdate)                 AS month_start,
        SUM(totaldue)                                  AS revenue,
        COUNT(salesorderid)                            AS order_count,
        COUNT(DISTINCT customerid)                     AS unique_customers
    FROM sales.salesorderheader
    WHERE status = 5
      AND onlineorderflag = TRUE
    GROUP BY order_year, order_month, month_start
),

mom_calc AS (
    SELECT
        order_year,
        order_month,
        month_start,
        revenue,
        order_count,
        unique_customers,
        LAG(revenue) OVER (ORDER BY month_start)       AS prev_month_revenue,
        LAG(order_count) OVER (ORDER BY month_start)   AS prev_month_orders
    FROM monthly_revenue
)

SELECT
    order_year                                         AS year,
    order_month                                        AS month,
    ROUND(revenue::NUMERIC, 2)                         AS revenue,
    order_count,
    unique_customers,
    ROUND(prev_month_revenue::NUMERIC, 2)              AS prev_month_revenue,
    ROUND(
        (revenue - prev_month_revenue)
        / NULLIF(prev_month_revenue, 0) * 100
    , 2)                                               AS mom_growth_pct,
    CASE
        WHEN prev_month_revenue IS NULL     THEN 'First Month'
        WHEN revenue > prev_month_revenue * 1.10 THEN 'Strong Growth'
        WHEN revenue > prev_month_revenue   THEN 'Growth'
        WHEN revenue = prev_month_revenue   THEN 'Flat'
        WHEN revenue < prev_month_revenue * 0.90 THEN 'Decline'
        ELSE 'Slight Decline'
    END                                                AS trend_label
FROM mom_calc
ORDER BY month_start;


/* ---- PART 2: Cohort Retention Analysis ---- */

WITH first_purchase AS (
    SELECT
        customerid,
        DATE_TRUNC('month', MIN(orderdate))            AS cohort_month
    FROM sales.salesorderheader
    WHERE status = 5
      AND onlineorderflag = TRUE
    GROUP BY customerid
),

customer_activity AS (
    SELECT
        o.customerid,
        f.cohort_month,
        DATE_TRUNC('month', o.orderdate)               AS order_month
    FROM sales.salesorderheader o
    JOIN first_purchase f ON o.customerid = f.customerid
    WHERE o.status = 5
      AND o.onlineorderflag = TRUE
),

cohort_data AS (
    SELECT
        cohort_month,
        order_month,
        COUNT(DISTINCT customerid)                     AS active_customers,
        DATE_PART(
            'month',
            AGE(order_month, cohort_month)
        )                                              AS month_number
    FROM customer_activity
    GROUP BY cohort_month, order_month
),

cohort_size AS (
    SELECT cohort_month, active_customers              AS total_customers
    FROM cohort_data
    WHERE month_number = 0
)

SELECT
    cd.cohort_month,
    cs.total_customers,
    cd.month_number,
    cd.active_customers,
    ROUND(
        cd.active_customers * 100.0
        / NULLIF(cs.total_customers, 0)
    , 1)                                               AS retention_pct
FROM cohort_data cd
JOIN cohort_size cs ON cd.cohort_month = cs.cohort_month
ORDER BY cd.cohort_month, cd.month_number;
