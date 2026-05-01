/* ================================================
   03 - Customer Segmentation (RFM)
   AdventureWorks PostgreSQL
   ================================================ */

WITH rfm_base AS (
    SELECT
        customerid,
        DATE_PART('day', NOW() - MAX(orderdate))      AS recency_days,
        COUNT(salesorderid)                            AS frequency,
        SUM(totaldue)                                  AS monetary
    FROM sales.salesorderheader
    WHERE onlineorderflag = TRUE
      AND status = 5
    GROUP BY customerid
),

rfm_scores AS (
    SELECT
        customerid,
        recency_days,
        frequency,
        ROUND(monetary::NUMERIC, 2)                    AS monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC)     AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)         AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)          AS m_score
    FROM rfm_base
),

rfm_segments AS (
    SELECT
        customerid,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        CONCAT(r_score, f_score, m_score)              AS rfm_combo,
        (r_score + f_score + m_score)                  AS rfm_total,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
                THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3
                THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2
                THEN 'New Customers'
            WHEN r_score <= 2 AND f_score >= 3
                THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2
                THEN 'Lost'
            ELSE 'Potential Loyalists'
        END                                            AS segment
    FROM rfm_scores
)

/* Summary by segment */
SELECT
    segment,
    COUNT(customerid)                                  AS customer_count,
    ROUND(AVG(monetary)::NUMERIC, 2)                   AS avg_spend,
    ROUND(AVG(frequency::FLOAT)::NUMERIC, 1)           AS avg_orders,
    ROUND(AVG(recency_days)::NUMERIC, 0)               AS avg_recency_days
FROM rfm_segments
GROUP BY segment
ORDER BY avg_spend DESC;


/* Individual customer view */
/*CREATE VIEW rfm_segments_view AS
WITH rfm_base AS (
    SELECT
        customerid,
        DATE_PART('day', NOW() - MAX(orderdate))      AS recency_days,
        COUNT(salesorderid)                            AS frequency,
        SUM(totaldue)                                  AS monetary
    FROM sales.salesorderheader
    WHERE onlineorderflag = TRUE
      AND status = 5
    GROUP BY customerid
),
rfm_scores AS (
    SELECT
        customerid,
        recency_days,
        frequency,
        ROUND(monetary::NUMERIC, 2)                    AS monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC)     AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)         AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)          AS m_score
    FROM rfm_base
)
SELECT
    customerid,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score)              AS rfm_combo,
    (r_score + f_score + m_score)                  AS rfm_total,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
            THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3
            THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2
            THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 3
            THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2
            THEN 'Lost'
        ELSE 'Potential Loyalists'
    END                                            AS segment
FROM rfm_scores;
*/
-- Individual customer view
SELECT * FROM rfm_segments_view ORDER BY rfm_total DESC;

-- Segment summary
SELECT segment, COUNT(*), ROUND(AVG(monetary)) AS avg_monetary
FROM rfm_segments_view
GROUP BY segment
ORDER BY avg_monetary DESC;
