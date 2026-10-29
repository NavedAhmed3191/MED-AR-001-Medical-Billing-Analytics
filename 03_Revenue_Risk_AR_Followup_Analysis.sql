```sql
-- =====================================================
-- MEDICAL BILLING DENIAL & AR ANALYTICS
-- Project ID: MED-AR-001
-- =====================================================
-- DAY 03
-- Revenue Risk, High-Risk Denials & AR Follow-up Analysis
-- =====================================================


-- =====================================================
-- 1. TOTAL MONEY OUTSTANDING ON DENIED CLAIMS
-- Business Question:
-- How much money is currently outstanding on denied claims?
-- =====================================================

SELECT
    ROUND(
        SUM(COALESCE(allowed_amount, 0))
        - SUM(COALESCE(paid_amount, 0)),
        2
    ) AS denied_outstanding_ar
FROM claims
WHERE claim_status = 'Denied';


-- =====================================================
-- 2. DENIED AR BREAKDOWN
-- Business Question:
-- How much was allowed versus paid on denied claims?
-- =====================================================

SELECT
    ROUND(SUM(COALESCE(allowed_amount, 0)), 2)
        AS total_allowed,

    ROUND(SUM(COALESCE(paid_amount, 0)), 2)
        AS total_paid,

    ROUND(
        SUM(COALESCE(allowed_amount, 0))
        - SUM(COALESCE(paid_amount, 0)),
        2
    ) AS revenue_at_risk

FROM claims
WHERE claim_status = 'Denied';


-- =====================================================
-- 3. REVENUE AT RISK BY DENIAL CATEGORY
-- Business Question:
-- Which denial categories are responsible
-- for the outstanding financial risk?
-- =====================================================

SELECT
    d.denial_category,
    COUNT(*) AS denial_count,

    ROUND(
        SUM(
            COALESCE(c.allowed_amount, 0)
            - COALESCE(c.paid_amount, 0)
        ),
        2
    ) AS revenue_at_risk

FROM denials d
JOIN claims c
    ON d.claim_id = c.claim_id

WHERE c.claim_status = 'Denied'

GROUP BY d.denial_category
ORDER BY revenue_at_risk DESC;


-- =====================================================
-- 4. HIGH VOLUME + HIGH FINANCIAL IMPACT
-- Business Question:
-- Which denial categories have both high volume
-- and high financial impact?
-- =====================================================

SELECT
    d.denial_category,

    COUNT(*) AS total_denial_count,

    ROUND(
        SUM(
            COALESCE(c.allowed_amount, 0)
            - COALESCE(c.paid_amount, 0)
        ),
        2
    ) AS revenue_at_risk,

    ROUND(
        AVG(
            COALESCE(c.allowed_amount, 0)
            - COALESCE(c.paid_amount, 0)
        ),
        2
    ) AS avg_revenue_at_risk

FROM denials d
JOIN claims c
    ON c.claim_id = d.claim_id

WHERE c.claim_status = 'Denied'

GROUP BY d.denial_category
ORDER BY revenue_at_risk DESC;


-- =====================================================
-- 5. TOP 10 DENIED CLAIMS BY REVENUE AT RISK
-- Business Question:
-- Which individual denied claims have the highest
-- outstanding financial exposure?
-- =====================================================

SELECT
    c.claim_id,
    c.payer_id,
    c.provider_id,
    c.billed_amount,
    c.allowed_amount,
    c.paid_amount,

    ROUND(
        COALESCE(c.allowed_amount, 0)
        - COALESCE(c.paid_amount, 0),
        2
    ) AS revenue_at_risk

FROM claims c

WHERE c.claim_status = 'Denied'

ORDER BY revenue_at_risk DESC
LIMIT 10;


-- =====================================================
-- 6. INDIVIDUAL CLAIM DETAIL
-- Business Question:
-- What happened with a specific denied claim?
-- =====================================================

SELECT
    claim_id,
    denial_category,
    denial_code,
    follow_up_date,
    sla_days,
    sla_compliant,
    appeal_deadline,
    appeal_submission_date,
    appeal_timely
FROM denials
WHERE claim_id = 'CLM010171';


-- =====================================================
-- 7. HIGH-VALUE SLA-MISSED DENIED CLAIMS
-- Business Question:
-- How many denied claims have both high financial risk
-- and missed SLA?
--
-- High-value threshold for this project:
-- Revenue at Risk >= $2,000
-- =====================================================

SELECT
    COUNT(*) AS high_value_sla_missed_claims

FROM claims c
JOIN denials d
    ON c.claim_id = d.claim_id

WHERE c.claim_status = 'Denied'

  AND (
        COALESCE(c.allowed_amount, 0)
        - COALESCE(c.paid_amount, 0)
      ) >= 2000

  AND d.sla_compliant = FALSE;


-- =====================================================
-- 8. HIGH-VALUE SLA-MISSED CLAIM DETAILS
-- Business Question:
-- Which individual claims meet the high-risk criteria?
-- =====================================================

SELECT
    c.claim_id,
    c.payer_id,
    c.provider_id,

    ROUND(
        COALESCE(c.allowed_amount, 0)
        - COALESCE(c.paid_amount, 0),
        2
    ) AS revenue_at_risk,

    d.denial_category,
    d.sla_days,
    d.sla_compliant

FROM claims c
JOIN denials d
    ON c.claim_id = d.claim_id

WHERE c.claim_status = 'Denied'

  AND (
        COALESCE(c.allowed_amount, 0)
        - COALESCE(c.paid_amount, 0)
      ) >= 2000

  AND d.sla_compliant = FALSE

ORDER BY revenue_at_risk DESC;


-- =====================================================
-- 9. HIGH-PRIORITY CLAIMS BY PAYER
-- Business Question:
-- Which payers have the highest number of
-- high-priority claims?
--
-- High priority criteria:
-- Revenue at Risk >= $2,000
-- SLA = Missed
-- =====================================================

SELECT
    COALESCE(c.payer_id, 'Unknown') AS payer_id,

    COUNT(*) AS high_priority_claims,

    ROUND(
        SUM(
            COALESCE(c.allowed_amount, 0)
            - COALESCE(c.paid_amount, 0)
        ),
        2
    ) AS total_revenue_at_risk

FROM claims c
JOIN denials d
    ON c.claim_id = d.claim_id

WHERE c.claim_status = 'Denied'

  AND (
        COALESCE(c.allowed_amount, 0)
        - COALESCE(c.paid_amount, 0)
      ) >= 2000

  AND d.sla_compliant = FALSE

GROUP BY c.payer_id
ORDER BY total_revenue_at_risk DESC;


-- =====================================================
-- 10. SHARE OF HIGH-PRIORITY CLAIMS BY PAYER
-- Business Question:
-- What percentage of high-priority claims
-- belongs to each payer?
-- =====================================================

WITH high_priority AS (

    SELECT
        COALESCE(c.payer_id, 'Unknown') AS payer_id,
        COUNT(*) AS high_priority_claims

    FROM claims c
    JOIN denials d
        ON c.claim_id = d.claim_id

    WHERE c.claim_status = 'Denied'

      AND (
            COALESCE(c.allowed_amount, 0)
            - COALESCE(c.paid_amount, 0)
          ) >= 2000

      AND d.sla_compliant = FALSE

    GROUP BY c.payer_id
)

SELECT
    payer_id,
    high_priority_claims,

    ROUND(
        high_priority_claims * 100.0
        / SUM(high_priority_claims) OVER (),
        2
    ) AS share_of_high_priority_claims

FROM high_priority

ORDER BY share_of_high_priority_claims DESC;


-- =====================================================
-- 11. DENIAL RATE BY PROVIDER
-- Business Question:
-- Which providers have the highest denial rates?
-- =====================================================

SELECT
    c.provider_id,
    p.provider_name,
    p.specialty,

    COUNT(*) AS total_claims,

    COUNT(*) FILTER (
        WHERE c.claim_status = 'Denied'
    ) AS denied_claims,

    ROUND(
        COUNT(*) FILTER (
            WHERE c.claim_status = 'Denied'
        ) * 100.0 / COUNT(*),
        2
    ) AS denial_rate

FROM claims c
JOIN providers p
    ON c.provider_id = p.provider_id

GROUP BY
    c.provider_id,
    p.provider_name,
    p.specialty

ORDER BY denial_rate DESC;


-- =====================================================
-- 12. DENIAL RATE BY SPECIALTY
-- Business Question:
-- Which specialties experience the highest denial rates?
-- =====================================================

SELECT
    p.specialty,

    COUNT(*) AS total_claims,

    COUNT(*) FILTER (
        WHERE c.claim_status = 'Denied'
    ) AS denied_claims,

    ROUND(
        COUNT(*) FILTER (
            WHERE c.claim_status = 'Denied'
        ) * 100.0 / COUNT(*),
        2
    ) AS denial_rate

FROM claims c
JOIN providers p
    ON c.provider_id = p.provider_id

GROUP BY p.specialty

ORDER BY denial_rate DESC;


-- =====================================================
-- 13. LATE-APPEAL RATE BY DENIAL CATEGORY
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
-- AR FOLLOW-UP ANALYSIS
-- =====================================================


-- =====================================================
-- 14. CREATE AR FOLLOW-UP TABLE
-- =====================================================

CREATE TABLE ar_followup
(
    claim_id VARCHAR(30),
    denial_date DATE,
    follow_up_date DATE,
    last_action_date DATE,
    sla_days INTEGER,
    sla_compliant BOOLEAN,
    resolution VARCHAR(50),
    days_in_ar INTEGER,
    escalation_required BOOLEAN,
    priority VARCHAR(20)
);


-- =====================================================
-- 15. AR FOLLOW-UP DATA CHECK
-- =====================================================

SELECT *
FROM ar_followup
LIMIT 10;


-- =====================================================
-- 16. AR FOLLOW-UP ROW COUNT
-- =====================================================

SELECT
    COUNT(*) AS total_rows
FROM ar_followup;


-- =====================================================
-- 17. AR AGING RANGE
-- Business Question:
-- What is the minimum, maximum and average
-- number of days claims remain in AR?
-- =====================================================

SELECT
    MIN(days_in_ar) AS min_days_in_ar,
    MAX(days_in_ar) AS max_days_in_ar,
    ROUND(AVG(days_in_ar), 2) AS avg_days_in_ar
FROM ar_followup;


-- =====================================================
-- 18. NEGATIVE DAYS IN AR DATA QUALITY CHECK
-- Business Question:
-- Are there records where Days in AR is negative?
-- =====================================================

SELECT
    claim_id,
    denial_date,
    follow_up_date,
    last_action_date,
    days_in_ar,
    resolution,
    priority

FROM ar_followup

WHERE days_in_ar < 0

ORDER BY days_in_ar;


-- =====================================================
-- 19. VALIDATE NEGATIVE DAYS IN AR
-- Business Question:
-- How does recorded Days in AR compare with
-- calculated days?
-- =====================================================

SELECT
    claim_id,
    denial_date,
    follow_up_date,
    last_action_date,
    days_in_ar,

    (last_action_date - denial_date)
        AS calculated_days

FROM ar_followup

WHERE days_in_ar < 0

ORDER BY days_in_ar

LIMIT 20;


-- =====================================================
-- 20. LAST ACTION DATE COMPLETENESS
-- Business Question:
-- How many AR records have a missing last action date?
-- =====================================================

SELECT
    COUNT(*) AS total_claims,

    COUNT(*) FILTER (
        WHERE last_action_date IS NULL
    ) AS missing_last_action,

    COUNT(*) FILTER (
        WHERE last_action_date IS NOT NULL
    ) AS available_last_action

FROM ar_followup;


-- =====================================================
-- 21. CALCULATED AR DURATION
-- Business Question:
-- What is the actual calculated duration from denial
-- to the latest action?
-- =====================================================

SELECT
    MIN(last_action_date - denial_date)
        AS min_calculated_days,

    MAX(last_action_date - denial_date)
        AS max_calculated_days,

    ROUND(
        AVG(last_action_date - denial_date),
        2
    ) AS avg_calculated_days

FROM ar_followup

WHERE last_action_date IS NOT NULL;


-- =====================================================
-- 22. AR RESOLUTION DISTRIBUTION
-- Business Question:
-- How many claims are Pending, Resolved,
-- Appealed, Reprocessed or Written Off?
-- =====================================================

SELECT
    resolution,
    COUNT(*) AS claim_count

FROM ar_followup

GROUP BY resolution

ORDER BY claim_count DESC;


-- =====================================================
-- 23. RESOLUTION DATE RANGE
-- Business Question:
-- What is the date range of activity for each resolution?
-- =====================================================

SELECT
    resolution,
    COUNT(*) AS claim_count,

    MIN(denial_date) AS earliest_denial,
    MAX(denial_date) AS latest_denial,

    MIN(last_action_date) AS earliest_action,
    MAX(last_action_date) AS latest_action

FROM ar_followup

GROUP BY resolution

ORDER BY claim_count DESC;


-- =====================================================
-- 24. AR DAYS BY RESOLUTION
-- Business Question:
-- Which resolution types have the longest AR duration?
-- =====================================================

SELECT
    resolution,
    COUNT(*) AS total_claims,

    ROUND(SUM(days_in_ar), 2)
        AS total_days_in_ar,

    ROUND(AVG(days_in_ar), 2)
        AS avg_days_in_ar

FROM ar_followup

GROUP BY resolution

ORDER BY avg_days_in_ar DESC;


-- =====================================================
-- 25. PAYMENT DATA QUALITY CHECK
-- Business Question:
-- How many payment records and unique claims exist?
-- =====================================================

SELECT
    COUNT(*) AS total_payment_rows,
    COUNT(DISTINCT claim_id) AS unique_claims

FROM payments;


-- =====================================================
-- 26. CLAIMS WITH MULTIPLE PAYMENT RECORDS
-- Business Question:
-- Are there claims with multiple payment transactions?
-- =====================================================

SELECT
    claim_id,
    COUNT(*) AS payment_records

FROM payments

GROUP BY claim_id

HAVING COUNT(*) > 1

ORDER BY payment_records DESC;


-- =====================================================
-- 27. PAYMENT SUMMARY BY CLAIM
-- Business Question:
-- What is the total payment amount per claim?
-- =====================================================

SELECT
    claim_id,
    SUM(paid_amount) AS total_paid

FROM payments

GROUP BY claim_id;


-- =====================================================
-- 28. FOLLOW-UP DATA QUALITY CHECK
-- Business Question:
-- Are there duplicate follow-up records for claims?
-- =====================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT claim_id) AS unique_claims

FROM ar_followup;


SELECT
    claim_id,
    COUNT(*) AS followup_records

FROM ar_followup

GROUP BY claim_id

HAVING COUNT(*) > 1

ORDER BY followup_records DESC;


-- =====================================================
-- 29. DUPLICATE FOLLOW-UP RECORD DETAILS
-- =====================================================

SELECT
    claim_id,
    denial_date,
    follow_up_date,
    last_action_date,
    sla_days,
    sla_compliant,
    resolution,
    days_in_ar,
    escalation_required,
    priority

FROM ar_followup

WHERE claim_id IN (

    SELECT claim_id

    FROM ar_followup

    GROUP BY claim_id

    HAVING COUNT(*) > 1
)

ORDER BY claim_id, follow_up_date;


-- =====================================================
-- 30. LATEST FOLLOW-UP RECORD PER CLAIM
-- Business Question:
-- Which is the latest AR status for each claim?
-- =====================================================

WITH ranked_followup AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY claim_id
            ORDER BY last_action_date DESC
        ) AS rn

    FROM ar_followup
)

SELECT
    claim_id,
    denial_date,
    follow_up_date,
    last_action_date,
    resolution,
    days_in_ar,
    escalation_required,
    priority

FROM ranked_followup

WHERE rn = 1

ORDER BY claim_id;


-- =====================================================
-- 31. PAYMENT SUMMARY CTE
-- Purpose:
-- Avoid duplicate amounts when a claim has
-- multiple payment records.
-- =====================================================

WITH payment_summary AS (

    SELECT
        claim_id,
        SUM(paid_amount) AS total_paid

    FROM payments

    GROUP BY claim_id
)

SELECT
    claim_id,
    total_paid

FROM payment_summary;


-- =====================================================
-- 32. OUTSTANDING AR BY LATEST RESOLUTION
-- Business Question:
-- How much outstanding AR exists under each
-- current resolution status?
-- =====================================================

WITH latest_followup AS (

    SELECT
        *,
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

claims_summary AS (

    SELECT
        claim_id,
        MAX(allowed_amount) AS allowed_amount

    FROM claims

    GROUP BY claim_id
)

SELECT
    lf.resolution,

    COUNT(*) AS claim_count,

    ROUND(
        SUM(
            cs.allowed_amount
            - COALESCE(ps.total_paid, 0)
        )::numeric,
        2
    ) AS outstanding_amount,

    ROUND(
        AVG(
            cs.allowed_amount
            - COALESCE(ps.total_paid, 0)
        )::numeric,
        2
    ) AS avg_outstanding_per_claim

FROM latest_followup lf

JOIN claims_summary cs
    ON lf.claim_id = cs.claim_id

LEFT JOIN payment_summary ps
    ON cs.claim_id = ps.claim_id

WHERE lf.rn = 1

GROUP BY lf.resolution

ORDER BY outstanding_amount DESC;


-- =====================================================
-- 33. OUTSTANDING AR BY PAYER
-- Business Question:
-- Which payers have the highest outstanding AR
-- and average AR aging?
-- =====================================================

WITH latest_followup AS (

    SELECT
        *,
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

claims_summary AS (

    SELECT
        claim_id,
        MAX(allowed_amount) AS allowed_amount,
        MAX(payer_id) AS payer_id

    FROM claims

    GROUP BY claim_id
)

SELECT
    COALESCE(cs.payer_id, 'Unknown') AS payer_id,

    COUNT(*) AS claim_count,

    ROUND(
        AVG(lf.days_in_ar)::numeric,
        2
    ) AS avg_days_in_ar,

    ROUND(
        SUM(
            cs.allowed_amount
            - COALESCE(ps.total_paid, 0)
        )::numeric,
        2
    ) AS outstanding_amount

FROM latest_followup lf

JOIN claims_summary cs
    ON lf.claim_id = cs.claim_id

LEFT JOIN payment_summary ps
    ON cs.claim_id = ps.claim_id

WHERE lf.rn = 1

GROUP BY cs.payer_id

ORDER BY outstanding_amount DESC;


-- =====================================================
-- 34. OUTSTANDING AR BY DENIAL CATEGORY
-- Business Question:
-- Which denial categories have the highest
-- outstanding AR and longest AR duration?
-- =====================================================

WITH latest_followup AS (

    SELECT
        *,
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

claims_summary AS (

    SELECT
        claim_id,
        MAX(allowed_amount) AS allowed_amount

    FROM claims

    GROUP BY claim_id
)

SELECT
    d.denial_category,

    COUNT(DISTINCT d.claim_id) AS claim_count,

    ROUND(
        AVG(lf.days_in_ar)::numeric,
        2
    ) AS avg_days_in_ar,

    ROUND(
        SUM(
            cs.allowed_amount
            - COALESCE(ps.total_paid, 0)
        )::numeric,
        2
    ) AS outstanding_amount

FROM denials d

JOIN claims_summary cs
    ON d.claim_id = cs.claim_id

JOIN latest_followup lf
    ON d.claim_id = lf.claim_id
   AND lf.rn = 1

LEFT JOIN payment_summary ps
    ON d.claim_id = ps.claim_id

GROUP BY d.denial_category

ORDER BY outstanding_amount DESC;


-- =====================================================
-- END OF DAY 03 ANALYSIS
-- =====================================================
```
