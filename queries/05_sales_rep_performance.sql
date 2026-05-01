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


-- 1. How many orders have a salesperson assigned?
SELECT COUNT(*) 
FROM sales.salesorderheader 
WHERE status = 5 
AND salespersonid IS NOT NULL;

-- 2. Do the salesperson IDs actually match between tables?
SELECT COUNT(*)
FROM sales.salesorderheader soh
JOIN sales.salesperson sp ON soh.salespersonid = sp.businessentityid
WHERE soh.status = 5;

-- 3. Check what status values actually exist
SELECT status, COUNT(*) 
FROM sales.salesorderheader 
GROUP BY status 
ORDER BY status;

SELECT COUNT(*)
FROM sales.salesorderheader soh
JOIN sales.salesperson sp ON soh.salespersonid = sp.businessentityid
JOIN humanresources.employee e ON sp.businessentityid = e.businessentityid
JOIN person.person p ON e.businessentityid = p.businessentityid
WHERE soh.status = 5
AND soh.salespersonid IS NOT NULL;

SELECT COUNT(*)
FROM sales.salesorderheader soh
JOIN sales.salesperson sp ON soh.salespersonid = sp.businessentityid
JOIN person.person p ON sp.businessentityid = p.businessentityid
WHERE soh.status = 5
AND soh.salespersonid IS NOT NULL;

-- Check what's actually in person.person for these salesperson IDs
SELECT sp.businessentityid, p.*
FROM sales.salesperson sp
JOIN person.person p ON sp.businessentityid = p.businessentityid
LIMIT 5;

-- If that returns 0, check person.person directly
SELECT businessentityid, firstname, lastname, persontype
FROM person.person
WHERE persontype = 'SP'  -- SP = SalesPerson
LIMIT 5;

-- Also check what businessentityids exist in salesperson
SELECT businessentityid FROM sales.salesperson LIMIT 10;

-- See what persontype values exist
SELECT persontype, COUNT(*) 
FROM person.person 
GROUP BY persontype;

-- Check if salesperson IDs exist at all in person.person
SELECT * 
FROM person.person 
WHERE businessentityid IN (274, 275, 276, 277, 278)
LIMIT 5;

-- Check person.businessentity table (the root ID table)
SELECT * 
FROM person.businessentity 
WHERE businessentityid IN (274, 275, 276, 277, 278)
LIMIT 5;

-- How many rows are actually in person.person?
SELECT COUNT(*) FROM person.person;

-- What IDs exist in person.person?
SELECT MIN(businessentityid), MAX(businessentityid) 
FROM person.person;

SELECT COUNT(*) FROM person.person;        -- should be ~19,972
SELECT COUNT(*) FROM sales.salesperson;    -- should be ~17
SELECT COUNT(*) FROM sales.salesorderheader; -- should be ~31,465