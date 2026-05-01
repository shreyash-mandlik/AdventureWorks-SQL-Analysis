/* ================================================
   01 - Revenue KPIs
   AdventureWorks PostgreSQL
   ================================================ */

/* Q1: Total revenue by year */
SELECT
    EXTRACT(YEAR FROM orderdate)          AS order_year,
    ROUND(SUM(totaldue)::NUMERIC, 2)      AS total_revenue,
    COUNT(salesorderid)                   AS total_orders,
    COUNT(DISTINCT customerid)            AS unique_customers,
    ROUND(AVG(totaldue)::NUMERIC, 2)      AS avg_order_value
FROM sales.salesorderheader
WHERE status = 5
GROUP BY order_year
ORDER BY order_year;


/* Q2: Monthly revenue breakdown */
SELECT
    EXTRACT(YEAR FROM orderdate)          AS order_year,
    EXTRACT(MONTH FROM orderdate)         AS order_month,
    ROUND(SUM(totaldue)::NUMERIC, 2)      AS monthly_revenue,
    COUNT(salesorderid)                   AS order_count
FROM sales.salesorderheader
WHERE status = 5
GROUP BY order_year, order_month
ORDER BY order_year, order_month;


/* Q3: Revenue by region/territory */
SELECT
    st.name                               AS territory,
    st.countryregioncode                  AS country,
    ROUND(SUM(soh.totaldue)::NUMERIC, 2)  AS total_revenue,
    COUNT(soh.salesorderid)               AS total_orders,
    ROUND(
        SUM(soh.totaldue) * 100.0
        / SUM(SUM(soh.totaldue)) OVER ()
    , 2)                                  AS revenue_pct
FROM sales.salesorderheader soh
JOIN sales.salesterritory st
    ON soh.territoryid = st.territoryid
WHERE soh.status = 5
GROUP BY st.name, st.countryregioncode
ORDER BY total_revenue DESC;


/* Q4: Online vs In-store revenue split */
SELECT
    CASE WHEN onlineorderflag = TRUE
        THEN 'Online' ELSE 'In-Store'
    END                                   AS channel,
    ROUND(SUM(totaldue)::NUMERIC, 2)      AS total_revenue,
    COUNT(salesorderid)                   AS total_orders,
    ROUND(AVG(totaldue)::NUMERIC, 2)      AS avg_order_value
FROM sales.salesorderheader
WHERE status = 5
GROUP BY onlineorderflag
ORDER BY total_revenue DESC;
