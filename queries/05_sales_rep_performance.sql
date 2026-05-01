/* ================================================
   05 - Sales Rep Performance
   AdventureWorks PostgreSQL
   ================================================ */

/* Q1: Revenue & orders per sales rep (leaderboard) */
SELECT
    CONCAT(p.firstname, ' ', p.lastname)               AS sales_rep,
    st.name                                            AS territory,
    COUNT(soh.salesorderid)                            AS total_orders,
    ROUND(SUM(soh.totaldue)::NUMERIC, 2)               AS total_revenue,
    ROUND(AVG(soh.totaldue)::NUMERIC, 2)               AS avg_order_value,
    RANK() OVER (
        ORDER BY SUM(soh.totaldue) DESC
    )                                                  AS revenue_rank
FROM sales.salesorderheader soh
JOIN sales.salesperson sp
    ON soh.salespersonid = sp.businessentityid
JOIN humanresources.employee e
    ON sp.businessentityid = e.businessentityid
JOIN person.person p
    ON e.businessentityid = p.businessentityid
JOIN sales.salesterritory st
    ON soh.territoryid = st.territoryid
WHERE soh.status = 5
  AND soh.salespersonid IS NOT NULL                    -- ✅ exclude online orders
GROUP BY p.firstname, p.lastname, st.name
ORDER BY total_revenue DESC;


/* Q2: Sales rep performance vs territory average */
WITH rep_revenue AS (
    SELECT
        CONCAT(p.firstname, ' ', p.lastname)           AS sales_rep,
        st.name                                        AS territory,
        ROUND(SUM(soh.totaldue)::NUMERIC, 2)           AS rep_revenue
    FROM sales.salesorderheader soh
    JOIN sales.salesperson sp
        ON soh.salespersonid = sp.businessentityid
    JOIN humanresources.employee e
        ON sp.businessentityid = e.businessentityid
    JOIN person.person p                               -- ✅ fixed
        ON e.businessentityid = p.businessentityid
    JOIN sales.salesterritory st
        ON soh.territoryid = st.territoryid
    WHERE soh.status = 5
      AND soh.salespersonid IS NOT NULL                -- ✅ exclude online orders
    GROUP BY p.firstname, p.lastname, st.name
)
SELECT
    sales_rep,
    territory,
    rep_revenue,
    ROUND(AVG(rep_revenue) OVER (
        PARTITION BY territory
    )::NUMERIC, 2)                                     AS territory_avg,
    ROUND(
        (rep_revenue - AVG(rep_revenue) OVER (
            PARTITION BY territory)
        )::NUMERIC, 2
    )                                                  AS vs_territory_avg,
    CASE
        WHEN rep_revenue > AVG(rep_revenue) OVER (PARTITION BY territory)
            THEN 'Above Average'
        ELSE 'Below Average'
    END                                                AS performance_flag
FROM rep_revenue
ORDER BY territory, rep_revenue DESC;


/* Q3: YoY growth per sales rep */
WITH yearly AS (
    SELECT
        CONCAT(p.firstname, ' ', p.lastname)           AS sales_rep,
        EXTRACT(YEAR FROM soh.orderdate)               AS order_year,
        ROUND(SUM(soh.totaldue)::NUMERIC, 2)           AS annual_revenue
    FROM sales.salesorderheader soh
    JOIN sales.salesperson sp
        ON soh.salespersonid = sp.businessentityid
    JOIN humanresources.employee e
        ON sp.businessentityid = e.businessentityid
    JOIN person.person p                               -- ✅ fixed
        ON e.businessentityid = p.businessentityid
    WHERE soh.status = 5
      AND soh.salespersonid IS NOT NULL                -- ✅ exclude online orders
    GROUP BY p.firstname, p.lastname, order_year
)
SELECT
    sales_rep,
    order_year,
    annual_revenue,
    LAG(annual_revenue) OVER (
        PARTITION BY sales_rep ORDER BY order_year
    )                                                  AS prev_year_revenue,
    ROUND(
        (annual_revenue - LAG(annual_revenue) OVER (
            PARTITION BY sales_rep ORDER BY order_year)
        ) * 100.0
        / NULLIF(LAG(annual_revenue) OVER (
            PARTITION BY sales_rep ORDER BY order_year), 0)
    , 2)                                               AS yoy_growth_pct
FROM yearly
ORDER BY sales_rep, order_year;




