```sql
-- =====================================================
-- MEDICAL BILLING DENIAL & AR ANALYTICS
-- Project ID: MED-AR-001
-- =====================================================
-- DAY 02 — CONTINUATION
-- Appeal Timeliness, Outstanding AR & Payer Contribution
-- =====================================================


-- =====================================================
-- 14. APPEAL SUBMISSION STATUS
-- Business Question:
-- Were appeals submitted before the deadline?
-- =====================================================

SELECT
    claim_id,
    denial_category,
    appeal_deadline,
    appeal_submission_date,
    CASE
        WHEN appeal_submission_date IS NULL
            THEN 'Not Submitted'
        WHEN appeal_submission_date <= appeal_deadline
            THEN 'Timely'
        ELSE 'Late'
    END AS appeal_status
FROM denials
LIMIT 20;


-- =====================================================
-- 15. OVERALL APPEAL STATUS DISTRIBUTION
-- Business Question:
-- How many appeals were timely, late, or not submitted?
-- =====================================================

SELECT
    CASE
        WHEN appeal_submission_date IS NULL
            THEN 'Not Submitted'
        WHEN appeal_submission_date <= appeal_deadline
            THEN 'Timely'
        ELSE 'Late'
    END AS appeal_status,
    COUNT(*) AS denial_count
FROM denials
GROUP BY appeal_status
ORDER BY denial_count DESC;


-- =====================================================
-- 16. APPEAL SUMMARY
-- Business Question:
-- How many appeals were submitted and how many were late?
-- =====================================================

SELECT
    COUNT(*) FILTER (
        WHERE appeal_submission_date <= appeal_deadline
    ) AS timely_appeals,

    COUNT(*) FILTER (
        WHERE appeal_submission_date > appeal_deadline
    ) AS late_appeals,

    COUNT(*) FILTER (
        WHERE appeal_submission_date IS NOT NULL
    ) AS submitted_appeals
FROM denials;


-- =====================================================
-- 17. LATE APPEALS BY DENIAL CATEGORY
-- Business Question:
-- Which denial categories have the highest number
-- of late appeals?
-- =====================================================

SELECT
    denial_category,
    COUNT(*) AS late_appeal_count
FROM denials
WHERE appeal_submission_date IS NOT NULL
  AND appeal_submission_date > appeal_deadline
GROUP BY denial_category
ORDER BY late_appeal_count DESC;


-- =====================================================
-- 18. LATE-APPEAL RATE BY DENIAL CATEGORY
-- Business Question:
-- Which denial categories have the highest late-appeal rate?
--
-- Formula:
-- Late Appeals / Submitted Appeals × 100
-- =====================================================

SELECT
    denial_category,

    COUNT(*) FILTER (
        WHERE appeal_submission_date IS NOT NULL
    ) AS submitted_appeals,

    COUNT(*) FILTER (
        WHERE appeal_submission_date IS NOT NULL
          AND appeal_submission_date > appeal_deadline
    ) AS late_appeals,

    ROUND(
        COUNT(*) FILTER (
            WHERE appeal_submission_date IS NOT NULL
              AND appeal_submission_date > appeal_deadline
        ) * 100.0
        / NULLIF(
            COUNT(*) FILTER (
                WHERE appeal_submission_date IS NOT NULL
            ),
            0
        ),
        2
    ) AS late_appeal_rate

FROM denials
GROUP BY denial_category
ORDER BY late_appeal_rate DESC;


-- =====================================================
-- 19. TOTAL OUTSTANDING AR
-- Business Question:
-- How much allowed revenue remains unpaid across all claims?
-- =====================================================

SELECT
    ROUND(
        SUM(COALESCE(allowed_amount, 0))
        - SUM(COALESCE(paid_amount, 0)),
        2
    ) AS total_outstanding_ar
FROM claims;


-- =====================================================
-- 20. DENIED OUTSTANDING AR
-- Business Question:
-- How much outstanding AR is associated with denied claims?
-- =====================================================

SELECT
    ROUND(
        SUM(
            CASE
                WHEN claim_status = 'Denied'
                    THEN COALESCE(allowed_amount, 0)
                       - COALESCE(paid_amount, 0)
                ELSE 0
            END
        ),
        2
    ) AS denied_outstanding_ar
FROM claims;


-- =====================================================
-- 21. DENIED OUTSTANDING AR BY PAYER
-- Business Question:
-- Which payers have the highest denied outstanding AR?
-- =====================================================

SELECT
    COALESCE(payer_id, 'Unknown') AS payer_id,
    COUNT(*) AS payer_claims,

    ROUND(
        SUM(
            CASE
                WHEN claim_status = 'Denied'
                    THEN COALESCE(allowed_amount, 0)
                       - COALESCE(paid_amount, 0)
                ELSE 0
            END
        ),
        2
    ) AS denied_outstanding_ar

FROM claims
GROUP BY payer_id
ORDER BY denied_outstanding_ar DESC;


-- =====================================================
-- 22. PAYER SHARE OF TOTAL DENIED AR
-- Business Question:
-- What percentage of total denied AR is contributed
-- by each payer?
-- =====================================================

WITH payer_ar AS (

    SELECT
        COALESCE(payer_id, 'Unknown') AS payer_id,

        SUM(
            CASE
                WHEN claim_status = 'Denied'
                    THEN COALESCE(allowed_amount, 0)
                       - COALESCE(paid_amount, 0)
                ELSE 0
            END
        ) AS denied_outstanding_ar

    FROM claims
    GROUP BY payer_id
)

SELECT
    payer_id,

    ROUND(
        denied_outstanding_ar::numeric,
        2
    ) AS denied_outstanding_ar,

    ROUND(
        denied_outstanding_ar * 100.0
        / NULLIF(
            SUM(denied_outstanding_ar) OVER (),
            0
        ),
        2
    ) AS ar_share_percentage

FROM payer_ar
WHERE denied_outstanding_ar > 0
ORDER BY denied_outstanding_ar DESC;


-- =====================================================
-- 23. PAYER DENIED BILLED AMOUNT
-- Business Question:
-- Which payers have the highest total billed amount
-- associated with denied claims?
-- =====================================================

WITH payer_denials AS (

    SELECT
        COALESCE(payer_id, 'Unknown') AS payer_id,
        SUM(COALESCE(billed_amount, 0)) AS denied_billed_amount

    FROM claims

    WHERE claim_status = 'Denied'

    GROUP BY payer_id
)

SELECT
    payer_id,
    ROUND(denied_billed_amount::numeric, 2)
        AS denied_billed_amount

FROM payer_denials
ORDER BY denied_billed_amount DESC;


-- =====================================================
-- 24. PAYER SHARE OF TOTAL DENIED BILLED AMOUNT
-- Business Question:
-- What percentage of total denied billed dollars
-- comes from each payer?
-- =====================================================

WITH payer_denials AS (

    SELECT
        COALESCE(payer_id, 'Unknown') AS payer_id,
        SUM(COALESCE(billed_amount, 0)) AS denied_billed_amount

    FROM claims

    WHERE claim_status = 'Denied'

    GROUP BY payer_id
)

SELECT
    payer_id,

    ROUND(
        denied_billed_amount::numeric,
        2
    ) AS denied_billed_amount,

    ROUND(
        denied_billed_amount * 100.0
        / NULLIF(
            SUM(denied_billed_amount) OVER (),
            0
        ),
        2
    ) AS percentage_of_total

FROM payer_denials
ORDER BY percentage_of_total DESC;


-- =====================================================
-- END OF DAY 02 CONTINUATION
-- =====================================================
```
