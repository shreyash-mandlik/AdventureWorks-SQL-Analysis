/* ================================================
   02 - Product Analysis
   AdventureWorks PostgreSQL
   ================================================ */

/* Q1: Top 10 products by revenue */
SELECT
    p.name                                                                      AS product_name,
    pc.name                                                                     AS category,
    ROUND(SUM(sod.unitprice * (1 - sod.unitpricediscount) * sod.orderqty)::NUMERIC, 2) AS total_revenue,
    SUM(sod.orderqty)                                                           AS units_sold,
    RANK() OVER (
        ORDER BY SUM(sod.unitprice * (1 - sod.unitpricediscount) * sod.orderqty) DESC
    )                                                                           AS revenue_rank
FROM sales.salesorderdetail sod
JOIN production.product p
    ON sod.productid = p.productid
JOIN production.productsubcategory ps
    ON p.productsubcategoryid = ps.productsubcategoryid
JOIN production.productcategory pc
    ON ps.productcategoryid = pc.productcategoryid
JOIN sales.salesorderheader soh
    ON sod.salesorderid = soh.salesorderid
WHERE soh.status = 5
GROUP BY p.name, pc.name
ORDER BY total_revenue DESC
LIMIT 10;


/* Q2: Revenue by product category + % contribution */
SELECT
    pc.name                                                                              AS category,
    ROUND(SUM(sod.unitprice * (1 - sod.unitpricediscount) * sod.orderqty)::NUMERIC, 2) AS category_revenue,
    ROUND(
        SUM(sod.unitprice * (1 - sod.unitpricediscount) * sod.orderqty) * 100.0
        / SUM(SUM(sod.unitprice * (1 - sod.unitpricediscount) * sod.orderqty)) OVER ()
    , 2)                                                                                AS revenue_pct
FROM sales.salesorderdetail sod
JOIN production.product p
    ON sod.productid = p.productid
JOIN production.productsubcategory ps
    ON p.productsubcategoryid = ps.productsubcategoryid
JOIN production.productcategory pc
    ON ps.productcategoryid = pc.productcategoryid
JOIN sales.salesorderheader soh
    ON sod.salesorderid = soh.salesorderid
WHERE soh.status = 5
GROUP BY pc.name
ORDER BY category_revenue DESC;

/* CTE*/
WITH line_totals AS (
    SELECT
        pc.name                                                         AS category,
        sod.unitprice * (1 - sod.unitpricediscount) * sod.orderqty    AS line_total
    FROM sales.salesorderdetail sod
    JOIN production.product p        ON sod.productid = p.productid
    JOIN production.productsubcategory ps ON p.productsubcategoryid = ps.productsubcategoryid
    JOIN production.productcategory pc    ON ps.productcategoryid = pc.productcategoryid
    JOIN sales.salesorderheader soh       ON sod.salesorderid = soh.salesorderid
    WHERE soh.status = 5
)
SELECT
    category,
    ROUND(SUM(line_total)::NUMERIC, 2)                                          AS category_revenue,
    ROUND(SUM(line_total) * 100.0 / SUM(SUM(line_total)) OVER (), 2)           AS revenue_pct
FROM line_totals
GROUP BY category
ORDER BY category_revenue DESC;


/* Q3: Dead inventory — products with zero sales in last 12 months */
SELECT
    p.productid,
    p.name                                AS product_name,
    p.listprice,
    p.sellstartdate
FROM production.product p
WHERE p.productid NOT IN (
    SELECT DISTINCT sod.productid
    FROM sales.salesorderdetail sod
    JOIN sales.salesorderheader soh
        ON sod.salesorderid = soh.salesorderid
    WHERE soh.orderdate >= NOW() - INTERVAL '12 months'
      AND soh.status = 5
)
AND p.sellenddate IS NULL
ORDER BY p.listprice DESC;
