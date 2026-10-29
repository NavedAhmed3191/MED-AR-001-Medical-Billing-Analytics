```sql
-- ============================================================
-- PROJECT: Medical Billing Denial & AR Analytics
-- MASTER SQL ANALYSIS
-- SECTION: AR AGING, PAYER & ESCALATION ANALYSIS
-- ============================================================
--
-- Purpose:
-- Cleaned and consolidated SQL queries from AR analysis.
--
-- Key SQL Concepts:
-- CTEs
-- ROW_NUMBER()
-- PARTITION BY
-- Window Functions
-- Aggregation
-- CASE Statements
-- COALESCE()
-- JOIN / LEFT JOIN
-- GROUP BY
-- ORDER BY
--
-- ============================================================


-- ============================================================
-- 01. AR AGING BY AGING BUCKET
-- Business Question:
-- How does AR aging vary across aging buckets?
-- Scope: Denied claims only
-- ============================================================

WITH latest_followup AS (

    SELECT
        claim_id,
        days_in_ar,

        ROW_NUMBER() OVER (
            PARTITION BY claim_id
            ORDER BY last_action_date DESC
        ) AS rn

    FROM ar_followup
),

payment_summary AS (

    SELECT
        claim_id,
        SUM(paid_amount) AS total_paid

    FROM payments

    GROUP BY claim_id
),

claim_summary AS (

    SELECT
        claim_id,
        MAX(allowed_amount) AS allowed_amount,
        MAX(claim_status) AS claim_status

    FROM claims

    GROUP BY claim_id
),

ar_data AS (

    SELECT
        lf.claim_id,
        lf.days_in_ar,
        cs.allowed_amount,
        COALESCE(ps.total_paid, 0) AS total_paid,

        CASE
            WHEN lf.days_in_ar BETWEEN 0 AND 30
                THEN '0-30 Days'

            WHEN lf.days_in_ar BETWEEN 31 AND 60
                THEN '31-60 Days'

            WHEN lf.days_in_ar BETWEEN 61 AND 90
                THEN '61-90 Days'

            WHEN lf.days_in_ar BETWEEN 91 AND 120
                THEN '91-120 Days'

            ELSE '120+ Days'
        END AS aging_bucket

    FROM latest_followup lf

    JOIN claim_summary cs
        ON lf.claim_id = cs.claim_id

    LEFT JOIN payment_summary ps
        ON cs.claim_id = ps.claim_id

    WHERE lf.rn = 1
      AND lf.days_in_ar >= 0
      AND cs.claim_status = 'Denied'
)

SELECT
    aging_bucket,
    COUNT(*) AS claim_count,

    ROUND(
        SUM(
            allowed_amount - total_paid
        )::NUMERIC,
        2
    ) AS outstanding_ar

FROM ar_data

GROUP BY aging_bucket

ORDER BY
    CASE aging_bucket
        WHEN '0-30 Days' THEN 1
        WHEN '31-60 Days' THEN 2
        WHEN '61-90 Days' THEN 3
        WHEN '91-120 Days' THEN 4
        WHEN '120+ Days' THEN 5
    END;


-- ============================================================
-- 02. AR AGING BY PAYER
-- Business Question:
-- How does AR aging vary by payer?
-- Scope: Denied claims only
-- ============================================================

WITH latest_followup AS (

    SELECT
        claim_id,
        days_in_ar,

        ROW_NUMBER() OVER (
            PARTITION BY claim_id
            ORDER BY last_action_date DESC
        ) AS rn

    FROM ar_followup
),

payment_summary AS (

    SELECT
        claim_id,
        SUM(paid_amount) AS total_paid

    FROM payments

    GROUP BY claim_id
),

claim_history AS (

    SELECT
        claim_id,
        MAX(allowed_amount) AS allowed_amount,
        MAX(claim_status) AS claim_status,
        MAX(payer_id) AS payer_id

    FROM claims

    GROUP BY claim_id
),

ar_data AS (

    SELECT
        lf.claim_id,
        ch.payer_id,
        lf.days_in_ar,
        ch.allowed_amount,
        COALESCE(ps.total_paid, 0) AS total_paid,

        CASE
            WHEN lf.days_in_ar BETWEEN 0 AND 30
                THEN '0-30 Days'

            WHEN lf.days_in_ar BETWEEN 31 AND 60
                THEN '31-60 Days'

            WHEN lf.days_in_ar BETWEEN 61 AND 90
                THEN '61-90 Days'

            WHEN lf.days_in_ar BETWEEN 91 AND 120
                THEN '91-120 Days'

            ELSE '120+ Days'
        END AS aging_bucket

    FROM latest_followup lf

    JOIN claim_history ch
        ON lf.claim_id = ch.claim_id

    LEFT JOIN payment_summary ps
        ON ch.claim_id = ps.claim_id

    WHERE lf.rn = 1
      AND lf.days_in_ar >= 0
      AND ch.claim_status = 'Denied'
)

SELECT
    COALESCE(payer_id, 'Unknown') AS payer_id,
    aging_bucket,
    COUNT(*) AS claim_count,

    ROUND(
        SUM(
            allowed_amount - total_paid
        )::NUMERIC,
        2
    ) AS outstanding_ar

FROM ar_data

GROUP BY
    payer_id,
    aging_bucket

ORDER BY
    payer_id,

    CASE aging_bucket
        WHEN '0-30 Days' THEN 1
        WHEN '31-60 Days' THEN 2
        WHEN '61-90 Days' THEN 3
        WHEN '91-120 Days' THEN 4
        WHEN '120+ Days' THEN 5
    END;


-- ============================================================
-- 03. 120+ DAYS AR BY PAYER
-- Business Question:
-- Which payers have the highest 120+ day outstanding AR?
-- Scope: Denied claims only
-- ============================================================

WITH latest_followup AS (

    SELECT
        claim_id,
        days_in_ar,

        ROW_NUMBER() OVER (
            PARTITION BY claim_id
            ORDER BY last_action_date DESC
        ) AS rn

    FROM ar_followup
),

payment_summary AS (

    SELECT
        claim_id,
        SUM(paid_amount) AS total_paid

    FROM payments

    GROUP BY claim_id
),

claim_history AS (

    SELECT
        claim_id,
        MAX(allowed_amount) AS allowed_amount,
        MAX(claim_status) AS claim_status,
        MAX(payer_id) AS payer_id

    FROM claims

    GROUP BY claim_id
)

SELECT
    COALESCE(ch.payer_id, 'Unknown') AS payer_id,
    COUNT(*) AS claim_count,

    ROUND(
        SUM(
            ch.allowed_amount
            - COALESCE(ps.total_paid, 0)
        )::NUMERIC,
        2
    ) AS outstanding_120_plus

FROM latest_followup lf

JOIN claim_history ch
    ON lf.claim_id = ch.claim_id

LEFT JOIN payment_summary ps
    ON ch.claim_id = ps.claim_id

WHERE lf.rn = 1
  AND lf.days_in_ar >= 120
  AND ch.claim_status = 'Denied'

GROUP BY ch.payer_id

ORDER BY outstanding_120_plus DESC;


-- ============================================================
-- 04. TOTAL OUTSTANDING AR BY PAYER
-- Business Question:
-- Which payers have the highest outstanding AR?
-- Scope: Denied claims only
-- ============================================================

WITH latest_followup AS (

    SELECT
        claim_id,
        days_in_ar,

        ROW_NUMBER() OVER (
            PARTITION BY claim_id
            ORDER BY last_action_date DESC
        ) AS rn

    FROM ar_followup
),

payment_summary AS (

    SELECT
        claim_id,
        SUM(paid_amount) AS total_paid

    FROM payments

    GROUP BY claim_id
),

claim_history AS (

    SELECT
        claim_id,
        MAX(allowed_amount) AS allowed_amount,
        MAX(claim_status) AS claim_status,
        MAX(payer_id) AS payer_id

    FROM claims

    GROUP BY claim_id
)

SELECT
    COALESCE(ch.payer_id, 'Unknown') AS payer_id,
    COUNT(*) AS claim_count,

    ROUND(
        SUM(
            ch.allowed_amount
            - COALESCE(ps.total_paid, 0)
        )::NUMERIC,
        2
    ) AS outstanding_ar

FROM latest_followup lf

JOIN claim_history ch
    ON lf.claim_id = ch.claim_id

LEFT JOIN payment_summary ps
    ON ch.claim_id = ps.claim_id

WHERE lf.rn = 1
  AND lf.days_in_ar >= 0
  AND ch.claim_status = 'Denied'

GROUP BY ch.payer_id

ORDER BY outstanding_ar DESC;


-- ============================================================
-- 05. OUTSTANDING AR BY ESCALATION STATUS
-- Business Question:
-- How much outstanding AR requires escalation?
-- Scope: Denied claims only
-- ============================================================

WITH latest_followup AS (

    SELECT
        claim_id,
        days_in_ar,
        escalation_required,

        ROW_NUMBER() OVER (
            PARTITION BY claim_id
            ORDER BY last_action_date DESC
        ) AS rn

    FROM ar_followup
),

payment_summary AS (

    SELECT
        claim_id,
        SUM(paid_amount) AS total_paid

    FROM payments

    GROUP BY claim_id
),

claim_history AS (

    SELECT
        claim_id,
        MAX(allowed_amount) AS allowed_amount,
        MAX(claim_status) AS claim_status,
        MAX(payer_id) AS payer_id

    FROM claims

    GROUP BY claim_id
)

SELECT

    CASE
        WHEN lf.escalation_required IS TRUE
            THEN 'Yes'

        WHEN lf.escalation_required IS FALSE
            THEN 'No'

        ELSE 'Unknown'
    END AS escalation_required,

    COUNT(*) AS claim_count,

    ROUND(
        SUM(
            ch.allowed_amount
            - COALESCE(ps.total_paid, 0)
        )::NUMERIC,
        2
    ) AS outstanding_ar

FROM latest_followup lf

JOIN claim_history ch
    ON lf.claim_id = ch.claim_id

LEFT JOIN payment_summary ps
    ON ch.claim_id = ps.claim_id

WHERE lf.rn = 1
  AND ch.claim_status = 'Denied'
  AND lf.days_in_ar >= 0

GROUP BY

    CASE
        WHEN lf.escalation_required IS TRUE
            THEN 'Yes'

        WHEN lf.escalation_required IS FALSE
            THEN 'No'

        ELSE 'Unknown'
    END

ORDER BY outstanding_ar DESC;


-- ============================================================
-- 06. CRITICAL ESCALATED DENIED CLAIMS
-- Business Question:
-- Which critical denied claims require escalation?
-- Scope: Denied claims with Critical priority
-- ============================================================

WITH latest_followup AS (

    SELECT
        claim_id,
        days_in_ar,
        escalation_required,
        priority,
        resolution,
        sla_compliant,

        ROW_NUMBER() OVER (
            PARTITION BY claim_id
            ORDER BY last_action_date DESC
        ) AS rn

    FROM ar_followup
),

payment_summary AS (

    SELECT
        claim_id,
        SUM(paid_amount) AS total_paid

    FROM payments

    GROUP BY claim_id
),

claim_history AS (

    SELECT
        claim_id,
        MAX(allowed_amount) AS allowed_amount,
        MAX(claim_status) AS claim_status,
        MAX(payer_id) AS payer_id

    FROM claims

    GROUP BY claim_id
)

SELECT
    lf.claim_id,
    COALESCE(ch.payer_id, 'Unknown') AS payer_id,
    lf.days_in_ar,
    lf.priority,
    lf.resolution,
    lf.sla_compliant,

    ROUND(
        (
            ch.allowed_amount
            - COALESCE(ps.total_paid, 0)
        )::NUMERIC,
        2
    ) AS outstanding_ar

FROM latest_followup lf

JOIN claim_history ch
    ON lf.claim_id = ch.claim_id

LEFT JOIN payment_summary ps
    ON ch.claim_id = ps.claim_id

WHERE lf.rn = 1
  AND ch.claim_status = 'Denied'
  AND lf.days_in_ar >= 0
  AND lf.escalation_required IS TRUE
  AND lf.priority = 'Critical'

ORDER BY outstanding_ar DESC;


-- ============================================================
-- 07. CRITICAL ESCALATED AR BY PAYER
-- Business Question:
-- Which payers have critical escalated outstanding AR?
-- Scope: Denied claims with Critical priority
-- ============================================================

WITH latest_followup AS (

    SELECT
        claim_id,
        days_in_ar,
        escalation_required,
        priority,

        ROW_NUMBER() OVER (
            PARTITION BY claim_id
            ORDER BY last_action_date DESC
        ) AS rn

    FROM ar_followup
),

payment_summary AS (

    SELECT
        claim_id,
        SUM(paid_amount) AS total_paid

    FROM payments

    GROUP BY claim_id
),

claim_history AS (

    SELECT
        claim_id,
        MAX(allowed_amount) AS allowed_amount,
        MAX(claim_status) AS claim_status,
        MAX(payer_id) AS payer_id

    FROM claims

    GROUP BY claim_id
)

SELECT
    COALESCE(ch.payer_id, 'Unknown') AS payer_id,

    COUNT(*) AS critical_escalation_claims,

    ROUND(
        SUM(
            ch.allowed_amount
            - COALESCE(ps.total_paid, 0)
        )::NUMERIC,
        2
    ) AS outstanding_ar

FROM latest_followup lf

JOIN claim_history ch
    ON lf.claim_id = ch.claim_id

LEFT JOIN payment_summary ps
    ON ch.claim_id = ps.claim_id

WHERE lf.rn = 1
  AND ch.claim_status = 'Denied'
  AND lf.days_in_ar >= 0
  AND lf.escalation_required IS TRUE
  AND lf.priority = 'Critical'

GROUP BY ch.payer_id

ORDER BY outstanding_ar DESC;


-- ============================================================
-- END OF AR AGING, PAYER & ESCALATION ANALYSIS
-- ============================================================
```
