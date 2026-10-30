-- =====================================================
-- DAY 01: CLAIM & DENIAL BASICS
-- =====================================================


-- 1. Overall Denial Rate
-- Business Question:
-- What percentage of all claims were denied?

SELECT
    COUNT(*) AS total_claims,
    COUNT(*) FILTER (WHERE claim_status = 'Denied') AS denied_claims,
    ROUND(
        COUNT(*) FILTER (WHERE claim_status = 'Denied') * 100.0
        / COUNT(*),
        2
    ) AS denial_rate
FROM claims;


-- 2. Total Denied Claims

SELECT
    COUNT(*) AS denied_claims
FROM claims
WHERE claim_status = 'Denied';


-- 3. Sample Denied Claims

SELECT
    claim_id,
    payer_id,
    provider_id,
    billed_amount,
    allowed_amount,
    paid_amount
FROM claims
WHERE claim_status = 'Denied'
LIMIT 10;


-- 4. Denied Claims Above $1,000

SELECT
    claim_id,
    payer_id,
    provider_id,
    billed_amount,
    allowed_amount,
    paid_amount
FROM claims
WHERE claim_status = 'Denied'
AND billed_amount > 1000;


-- 5. Denied Claims for PAY007 and PAY008

SELECT
    claim_id,
    payer_id,
    provider_id,
    billed_amount,
    allowed_amount,
    paid_amount
FROM claims
WHERE claim_status = 'Denied'
AND payer_id IN ('PAY007', 'PAY008');


-- 6. Highest-Billed Denied Claim

SELECT
    claim_id,
    payer_id,
    provider_id,
    billed_amount,
    allowed_amount,
    paid_amount
FROM claims
WHERE claim_status = 'Denied'
ORDER BY billed_amount DESC
LIMIT 1;
```sql
-- =====================================================
-- MEDICAL BILLING DENIAL & AR ANALYTICS
-- Project ID: MED-AR-001
-- =====================================================
-- DAY 02
-- Denial Category, Payer, Specialty & SLA Analysis
-- =====================================================


-- =====================================================
-- 1. DENIAL CATEGORY DISTRIBUTION
-- Business Question:
-- Which denial categories have the highest number of denials?
-- =====================================================

SELECT
    denial_category,
    COUNT(*) AS denial_count
FROM denials
GROUP BY denial_category
ORDER BY denial_count DESC;


-- =====================================================
-- 2. FINANCIAL IMPACT BY DENIAL CATEGORY
-- Business Question:
-- Which denial categories have the highest billed financial impact?
-- =====================================================

SELECT
    d.denial_category,
    COUNT(*) AS denial_count,
    ROUND(SUM(c.billed_amount)::numeric, 2) AS total_billed_amount,
    ROUND(AVG(c.billed_amount)::numeric, 2) AS avg_billed_amount
FROM denials d
JOIN claims c
    ON d.claim_id = c.claim_id
GROUP BY d.denial_category
ORDER BY total_billed_amount DESC;


-- =====================================================
-- 3. TOP 3 DENIAL CATEGORIES BY BILLED AMOUNT
-- Business Question:
-- Which denial categories contribute the most billed dollars?
-- =====================================================

SELECT
    d.denial_category,
    COUNT(*) AS denial_count,
    ROUND(SUM(c.billed_amount)::numeric, 2) AS total_billed_amount
FROM denials d
JOIN claims c
    ON d.claim_id = c.claim_id
GROUP BY d.denial_category
ORDER BY total_billed_amount DESC
LIMIT 3;


-- =====================================================
-- 4. DENIAL CATEGORY SHARE OF TOTAL BILLED AMOUNT
-- Business Question:
-- What percentage of total denied billed dollars
-- comes from each denial category?
-- =====================================================

SELECT
    d.denial_category,
    COUNT(*) AS denial_count,
    ROUND(SUM(c.billed_amount)::numeric, 2) AS total_billed_amount,
    ROUND(
        SUM(c.billed_amount) * 100.0 /
        SUM(SUM(c.billed_amount)) OVER (),
        2
    ) AS percentage_of_total
FROM denials d
JOIN claims c
    ON d.claim_id = c.claim_id
GROUP BY d.denial_category
ORDER BY total_billed_amount DESC;


-- =====================================================
-- 5. DENIAL RATE BY PAYER
-- Business Question:
-- Which payer has the highest denial rate?
-- =====================================================

SELECT
    payer_id,
    COUNT(*) AS total_claims,
    COUNT(*) FILTER (
        WHERE claim_status = 'Denied'
    ) AS total_denied_claims,
    ROUND(
        COUNT(*) FILTER (
            WHERE claim_status = 'Denied'
        ) * 100.0 / COUNT(*),
        2
    ) AS denial_rate_percentage
FROM claims
WHERE payer_id IS NOT NULL
GROUP BY payer_id
ORDER BY denial_rate_percentage DESC;


-- =====================================================
-- 6. DENIAL CATEGORY BY PAYER
-- Business Question:
-- What denial categories are driving denials for each payer?
-- =====================================================

SELECT
    c.payer_id,
    d.denial_category,
    COUNT(*) AS denial_count
FROM claims c
JOIN denials d
    ON c.claim_id = d.claim_id
WHERE c.payer_id IS NOT NULL
GROUP BY
    c.payer_id,
    d.denial_category
ORDER BY
    c.payer_id,
    denial_count DESC;


-- =====================================================
-- 7. POTENTIAL REVENUE RECOVERY
-- Business Question:
-- How much allowed amount remains unpaid on denied claims?
-- =====================================================

SELECT
    claim_id,
    payer_id,
    allowed_amount,
    paid_amount,
    COALESCE(allowed_amount, 0)
        - COALESCE(paid_amount, 0) AS potential_unpaid_amount
FROM claims
WHERE claim_status = 'Denied'
ORDER BY potential_unpaid_amount DESC
LIMIT 20;


-- =====================================================
-- 8. DENIAL DOLLARS BY DENIAL CODE
-- Business Question:
-- Which denial codes contribute the most to denied dollars?
-- =====================================================

SELECT
    d.denial_code,
    COUNT(*) AS denial_count,
    ROUND(SUM(c.allowed_amount)::numeric, 2) AS denial_dollars
FROM denials d
JOIN claims c
    ON d.claim_id = c.claim_id
GROUP BY d.denial_code
ORDER BY denial_dollars DESC;


-- =====================================================
-- 9. DENIED CLAIMS BY SPECIALTY
-- Business Question:
-- Which specialties experience the most denied claims?
-- =====================================================

SELECT
    p.specialty,
    COUNT(*) AS denied_claims
FROM claims c
JOIN providers p
    ON c.provider_id = p.provider_id
WHERE c.claim_status = 'Denied'
GROUP BY p.specialty
ORDER BY denied_claims DESC;


-- =====================================================
-- 10. DENIAL RATE BY SPECIALTY
-- Business Question:
-- Which specialties have the highest denial rate?
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
-- 11. SLA PERFORMANCE AT CLAIM LEVEL
-- Business Question:
-- Was each denial worked within the established SLA?
-- =====================================================

SELECT
    claim_id,
    denial_category,
    denial_date,
    follow_up_date,
    sla_days,
    (follow_up_date - denial_date) AS follow_up_days,
    CASE
        WHEN (follow_up_date - denial_date) <= sla_days
            THEN 'Compliant'
        ELSE 'Not Compliant'
    END AS sla_status
FROM denials
LIMIT 20;


-- =====================================================
-- 12. OVERALL SLA COMPLIANCE
-- Business Question:
-- What percentage of denials were worked within SLA?
-- =====================================================

SELECT
    COUNT(*) AS total_denials,
    COUNT(*) FILTER (
        WHERE (follow_up_date - denial_date) <= sla_days
    ) AS sla_compliant_denials,
    COUNT(*) FILTER (
        WHERE (follow_up_date - denial_date) > sla_days
    ) AS sla_missed_denials,
    ROUND(
        COUNT(*) FILTER (
            WHERE (follow_up_date - denial_date) <= sla_days
        ) * 100.0 / COUNT(*),
        2
    ) AS sla_compliance_rate,
    ROUND(
        COUNT(*) FILTER (
            WHERE (follow_up_date - denial_date) > sla_days
        ) * 100.0 / COUNT(*),
        2
    ) AS sla_miss_rate
FROM denials;


-- =====================================================
-- 13. SLA MISS RATE BY PAYER
-- Business Question:
-- Which payers have the highest SLA miss rate?
-- =====================================================

SELECT
    c.payer_id,
    COUNT(*) AS total_denials,
    COUNT(*) FILTER (
        WHERE (d.follow_up_date - d.denial_date) > d.sla_days
    ) AS sla_missed,
    ROUND(
        COUNT(*) FILTER (
            WHERE (d.follow_up_date - d.denial_date) > d.sla_days
        ) * 100.0 / COUNT(*),
        2
    ) AS sla_miss_rate
FROM denials d
JOIN claims c
    ON d.claim_id = c.claim_id
WHERE c.payer_id IS NOT NULL
GROUP BY c.payer_id
ORDER BY sla_miss_rate DESC;


-- =====================================================
-- END OF DAY 02 ANALYSIS
-- =====================================================
```

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
--What percentage of all claims were denied?

SELECT
    COUNT(*) AS total_claims,
    COUNT(*) FILTER (WHERE claim_status = 'Denied') AS denied_claims,
    ROUND(
        COUNT(*) FILTER (WHERE claim_status = 'Denied') * 100.0
        / COUNT(*),
        2
    ) AS denial_rate
FROM claims;

select count(*) as denied_claims
from claims
where claim_status = 'Denied';

select 
	claim_id,
	payer_id,
	provider_id,
	billed_amount,
	allowed_amount,
	paid_amount
from claims
where claim_status = 'Denied'
limit 10;

--Show denied claims where the billed amount is greater than $1,000.

select
	claim_id,
	payer_id,
	provider_id,
	billed_amount,
	allowed_amount,
	paid_amount
from claims
where claim_status = 'Denied'
and billed_amount > 1000;

--Show denied claims where the payer is either PAY007 or PAY008.

select
	claim_id,
	payer_id,
	provider_id,
	billed_amount,
	allowed_amount,
	paid_amount
from claims
where claim_status = 'Denied' and
payer_id in ('PAY007', 'PAY008');

--What are the highest-billed denied claims?

select
	claim_id,
	payer_id,
	provider_id,
	billed_amount,
	allowed_amount,
	paid_amount
from claims
where claim_status = 'Denied'
order by billed_amount desc
limit 1;
select *
from denials;


select denial_category,
	count(*) as denial_count
	from denials
	group by denial_category
	order by denial_count desc;

--Which denial categories have the highest financial impact?

select
	d.denial_category,
	round(sum(c.billed_amount), 2) as total_billed_amount
	from denials d
	join claims c on d.claim_id = c.claim_id
	group by d.denial_category
	order by total_billed_amount desc;


    d.denial_category,
    COUNT(*) AS denial_count,
    ROUND(SUM(c.billed_amount), 2) AS total_billed_amount,
    ROUND(AVG(c.billed_amount), 2) AS avg_billed_amount
FROM denials d
JOIN claims c
    ON d.claim_id = c.claim_id
GROUP BY d.denial_category
ORDER BY avg_billed_amount DESC;

Select 
payer_id, Count(*) as total_claims
from claims
group by payer_id
order by total_claims desc;

SELECT
    d.denial_category,
    COUNT(*) AS denial_count,
    ROUND(SUM(c.billed_amount), 2) AS total_billed_amount
FROM denials d
JOIN claims c
    ON d.claim_id = c.claim_id
GROUP BY d.denial_category
ORDER BY total_billed_amount DESC
limit 3;


select
	d.denial_category,
	count(*) as denial_count,
	round(sum(c.billed_amount),2) as total_billed_amount,
	round(sum(c.billed_amount) * 100)/
	SUM(SUM(c.billed_amount)) OVER (),2) AS percentage_of_total
from denial d
join claim c on d.claim_id = c.claim_id
group by denial_category
order by total_billed_amount desc;

SELECT
    d.denial_category,
    COUNT(*) AS denial_count,
    ROUND(SUM(c.billed_amount), 2) AS total_billed_amount,
    ROUND(
        SUM(c.billed_amount) * 100.0 /
        SUM(SUM(c.billed_amount)) OVER (),
        2
    ) AS percentage_of_total
FROM denials d
JOIN claims c
    ON d.claim_id = c.claim_id
GROUP BY d.denial_category
ORDER BY total_billed_amount DESC;



select 
	claim_status,
	count(*) AS claim_count
from claims
group by claim_status
order by claim_count desc;


Select 
	count(*) as total_claims,
	count(*) filter(where claim_status = 'Denied') as total_denied_claims,
	Round(
			count(*) filter(Where claim_status = 'Denied') * 100.0/ count(*),
			2
			) AS denial_claims_percentage
From claims

SELECT
    COUNT(*) AS total_claims,
    COUNT(*) FILTER (WHERE claim_status = 'Denied') AS denied_claims,
    ROUND(
        COUNT(*) FILTER (WHERE claim_status = 'Denied') * 100.0
        / COUNT(*),
        2
    ) AS denial_rate_percentage
FROM claims;


--which payer is causing the most denial problems.

Select
	payer_id,
	count(*) AS total_claims,
	count(*) filter(where claim_status = 'Denied') as total_denied_claims,
	
	


Select payer_id,
	count(*) as total_claims,
	count(*) filter(where claim_status = 'Denied') as total_denied_claims,
	Round(
		count(*) filter(where claim_status = 'Denied') * 100.0 / count(*), 2
	) As denial_rate_percentage
from claims
group by payer_id
order by denial_rate_percentage;


-Denial Category distribution

Select denial_category,
	count(*) as total_denied_claims
	from denials
	group by denial_category
	order by total_denied_claims desc;

--Why does PAY007 have such a high denial rate?

Select
	c.payer_id, 
	d.denial_category, 
	count(*) as denial_count
	from claims c Join denials d
	on c.claim_id = d.claim_id
	where c.payer_id is not null
	group by 
		c.payer_id,
		d.denial_category
	order by
	c.payer_id,
	denial_count desc;
	
	

	SELECT
    c.payer_id,
    d.denial_category,
    COUNT(*) AS denial_count
FROM denials d
JOIN claims c
    ON d.claim_id = c.claim_id
	where c.payer_id is not null
GROUP BY
    c.payer_id,
    d.denial_category
ORDER BY
    c.payer_id,
    denial_count DESC;

--Which denial categories represent the greatest potential revenue recovery opportunity?

Select
	claim_id,
	payer_id,
	allowed_amount,
	paid_amount,
	coalesce(allowed_amount, 0) - coalesce(paid_amount, 0)
	As potential_unpaid_amount
from claims
Where claim_status = 'Denied'
limit 20;
-----------------------------How does AR aging vary across aging buckets?---------------------------

WITH latest_followup AS (
	Select
		claim_id,
		days_in_ar,
		row_number() 
			Over(partition by claim_id
			order by last_action_date desc) AS rn
	from ar_followup
),

Payment_summary AS (
	Select
		claim_id,
		sum(paid_amount) AS total_paid
	from payments
	group by claim_id
),

claims_summary AS (
	Select
		claim_id,
		max(allowed_amount) AS allowed_amount
	from claims
	group by claim_id
)

Select
		CASE
			When lf.days_in_ar between 0 and 30 then 'o-30 days'
			When lf.days_in_ar between 31 and 60 then '31-60 days'
			When lf.days_in_ar between 61 and 90 then '61-90 days'
			When lf.days_in_ar between 91 and 120 then '91-120 days'
			Else '120+ days'
		End AS ageing_bucket,
		count(*) AS claim_count,

		Round(
				Sum(
					cs.allowed_amount - coalesce (ps.total_paid, 0)) :: numeric,
				2) AS outstanding_amount
		from latest_followup lf
		Join claims_summary cs
		on lf.claim_id = cs.claim_id
		Left Join payment_summary ps
		on cs.claim_id = ps.claim_id

	Where lf.rn = 1
	And lf.days_in_ar > 0

	Group by 
		CASE
			When lf.days_in_ar between 0 and 30 then '0 to 30 days'
			When lf.days_in_ar between 31 and 60 then '31 to 60 days'
			When lf.days_in_ar between 61 and 90 then '61 to 90 days'
			When lf.days_in_ar between 91 and 120 then '91 to 120 days'
			Else '120+ days'
		End

	Order by
		CASE
			When Min(lf.days_in_ar) between 0 and 30 then 1
			When Min(lf.days_in_ar) between 31 and 60 then 2
			When Min(lf.days_in_ar) between 61 and 90 then 3
			When Min(lf.days_in_ar) between 91 and 120 then 4
			Else 5
		End;
		
		
		
--------------------------------------------------------------

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

claims_summary AS (
    SELECT
        claim_id,
        MAX(allowed_amount) AS allowed_amount
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
            WHEN lf.days_in_ar BETWEEN 0 AND 30 THEN '0-30 Days'
            WHEN lf.days_in_ar BETWEEN 31 AND 60 THEN '31-60 Days'
            WHEN lf.days_in_ar BETWEEN 61 AND 90 THEN '61-90 Days'
            WHEN lf.days_in_ar BETWEEN 91 AND 120 THEN '91-120 Days'
            ELSE '120+ Days'
        END AS aging_bucket

    FROM latest_followup lf

    JOIN claims_summary cs
        ON lf.claim_id = cs.claim_id

    LEFT JOIN payment_summary ps
        ON cs.claim_id = ps.claim_id

    WHERE lf.rn = 1
      AND lf.days_in_ar >= 0
)

SELECT
    aging_bucket,

    COUNT(*) AS claim_count,

    ROUND(
        SUM(allowed_amount - total_paid)::numeric,
        2
    ) AS outstanding_amount

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


---------------------------------------------------------


WITH latest_followup AS (
	Select
		claim_id,
		days_in_ar,
		Row_Number() Over
		(
			partition by claim_id
			order by last_action_date desc
		) AS rn
	from ar_followup

		),
payment_summary AS (
		Select
			claim_id,
			sum(paid_amount) as total_paid
		from payments
		group by claim_id
		),
claim_summary AS (
		Select
			claim_id,
			max(allowed_amount) AS allowed_amount,
			max(claim_status) AS claim_status
		from claims
		group by claim_id
		),
ar_data AS (
		Select 
			lf.claim_id,
			lf.days_in_ar,
			cs.allowed_amount,
			Coalesce(ps.total_paid, 0) AS total_paid,

		CASE
			When lf.days_in_ar Between 0 And 30
			then '0-30 days'
			when lf.days_in_ar between 31 And 60
			then '31 to 60 days'
			When lf.days_in_ar Between 61 And 90
			then '61 to 90 days'
			When lf.days_in_ar Between 91 And 120
			then '91 to 120 days'
			Else
			'120+ days'
			End AS ageing_bucket
		from latest_followup lf
		join claim_summary cs
		on lf.claim_id = cs.claim_id
		Left Join payment_summary ps
		on cs.claim_id = ps.claim_id

		Where lf.rn = 1
		And lf.days_in_ar >= 0
		And cs.claim_status = 'Denied'
		)

		Select ageing_bucket,
		count(*) AS claim_count,
		Round (
				Sum(allowed_amount - total_paid) :: numeric,2) AS outstanding_amount
		From ar_data
		group by ageing_bucket
		order by 
			case ageing_bucket
				When '0-30 days' Then 1
				When '31-60 days' Then 2
				When '61 - 90 days' Then 3
				When '91-120 days' Then 4
				When '120+ days' Then 5
			End;
			
-------------------------------------------------------------------------------------------

--How does AR aging vary by payer and denial category?


With latest_followup AS (
	Select
		claim_id,
		days_in_ar,
		Row_number() Over(
				partition by claim_id
				order by last_action_date desc
			) AS rn
		from ar_followup
),

payment_summary AS (
		Select
			claim_id,
			sum(paid_amount) AS total_paid
		from payments
		group by claim_id

),

claim_history AS (
	Select
		claim_id,
		max(allowed_amount) AS allowed_amount,
		max(claim_status) AS claim_status,
		max(payer_id) AS payer_id
	from claims
	group by claim_id
),

ar_data AS  (
	Select
		lf.claim_id,
		ch.payer_id,
		lf.days_in_ar,
		ch.allowed_amount,
		coalesce(ps.total_paid, 0) AS total_paid,

	CASE
		When lf.days_in_ar between 0 And 30
		 Then '0-30 days'
		When lf.days_in_ar between 31 And 60
			Then '31-60 days'
		when lf.days_in_ar between 61 And 90
			Then '61-90 days'
		When lf.days_in_ar between 91 and 120
			Then '91-120 days'
		Else
			'120+ days'
		End as ageing_bucket

	From latest_followup lf
	Join claim_history ch
	ON lf.claim_id = ch.claim_id
	Left Join payment_summary ps
	On ch.claim_id = ps.claim_id
	Where lf.rn = 1
	And lf.days_in_ar >=0
	And ch.claim_status = 'Denied'
	)

	Select
		payer_id,
		ageing_bucket,
		count(*) AS claim_count,

		Round(
				Sum(allowed_amount - total_paid) ::numeric ,2) AS outstanding_amount
	from ar_data
	group by
		payer_id,
		ageing_bucket
	order by
		payer_id,
		CASE ageing_bucket
		WHEN '0-30 Days' THEN 1
        WHEN '31-60 Days' THEN 2
        WHEN '61-90 Days' THEN 3
        WHEN '91-120 Days' THEN 4
        WHEN '120+ Days' THEN 5
    END;

---------------------------------------------------------------------------
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
        )::numeric,
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


-------------------------------------------------------

WITH latest_followup  AS 
(

	Select
		claim_id,
		days_in_ar,
		row_number() Over(
						partition by claim_id
						order by last_action_date desc
						) AS rn
	from ar_followup
),

payment_summary AS (
	Select
		claim_id,
		sum(paid_amount) AS total_paid	
	from payments
	group by claim_id
),

claim_history AS (
	Select
		claim_id,
		max(allowed_amount) AS allowed_amount,
		max(claim_status) AS claim_status,
		max(payer_id) AS payer_id
	from claims
	group by claim_id
)

Select
	coalesce (ch.payer_id, 'unknown') as payer_id,
	count(*) AS claim_count,
	Round(
			sum(
				ch.allowed_amount - coalesce (ps.total_paid, 0))::numeric,
			2
			) AS outstanding_120_plus
	from latest_followup lf
	join claim_history ch
	on lf.claim_id = ch.claim_id
	left join payment_summary ps
	on ch.claim_id = ps.claim_id

	Where lf.rn = 1
		And lf.days_in_ar >= 120
		And ch.claim_status = 'Denied'
		group by ch.payer_id
		order by outstanding_120_plus desc;



Select
	Round(Sum(Coalesce(allowed_amount,0)) - Sum(Coalesce(paid_amount,0)),2)
	as total_outstanding_ar
From claims;

Select
	Round (
		Sum(
			CASE
				When claim_status = 'Denied'
				then Coalesce(allowed_amount,0) - coalesce(paid_amount, 0)
				Else 0
			End	
		),2
	) AS denied_outstanding_ar

From claims;

--Which payer has the highest outstanding AR?

Select
	payer_id,
	count(*) AS Payer_claims,
	Round(
		Sum(
			Case
				When claim_status = 'Denied'
				Then Coalesce (allowed_amount, 0) - (Coalesce (paid_amount, 0))
				Else 0
			End
		),
		2
	) As denied_outstanding_ar

from claims
group by payer_id
order by denied_outstanding_ar desc


--What percentage of total denied AR is contributed by each payer?

WITH payer_ar AS (
    SELECT
        payer_id,
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
)

SELECT
    payer_id,
    denied_outstanding_ar,
    ROUND(
        denied_outstanding_ar * 100.0
        / SUM(denied_outstanding_ar) OVER (),
        2
    ) AS ar_share_percentage
FROM payer_ar
ORDER BY denied_outstanding_ar DESC;




WITH denied_claims AS 
(
	Select *
	from claims
	Where claim_status = 'Denied'
	
)

Select *
from denied_claims;

With payer_denials AS
(
	Select payer_id,
	sum(billed_amount) as denied_billed_amount
	from claims
	Where claim_status = 'Denied'
	group by payer_id
	order by denied_billed_amount desc
)

Select * 
from payer_denials

With payer_denials AS 
(
	Select payer_id,
	sum(billed_amount) as denied_billed_amount
	from claims
	Where claim_status = 'Denied'
	group by payer_id
)

Select
	payer_id,
	denied_billed_amount,
	Round(
		denied_billed_amount 
		/ Sum(denied_billed_amount) over() * 100.0,
		2
	) AS percentage_of_total
from payer_denials
order by percentage_of_total desc;

WITH payer_denials AS 
(
    SELECT
        payer_id,
        SUM(billed_amount) AS denied_billed_amount
    FROM claims
    WHERE claim_status = 'Denied'
    GROUP BY payer_id
)

SELECT
    payer_id,
    denied_billed_amount,
    SUM(denied_billed_amount) OVER() AS total_denied_amount
FROM payer_denials;
--How much money is currently outstanding on denied claims?

Select
	sum(c.allowed_amount) As total_allowed,
	sum(c.paid_amount) AS total_paid
from claims c
where c.claim_status = 'Denied';

Select
	round(
		sum(
			Coalesce(c.allowed_amount, 0) - Coalesce(c.paid_amount, 0)) 
			,2) AS revenue_at_risk
from claims c
where c.claim_status = 'Denied';

--Which denial categories are responsible for that risk?"

Select
	d.denial_category,
	count(*) as total_count,
	Round(
		sum(
		Coalesce(c.allowed_amount, 0) - Coalesce(c.paid_amount, 0))
	,2) AS revenue_at_risk
from denials d join claims c
on d.claim_id = c.claim_id
group by denial_category
order by revenue_at_risk desc;



--Which denial categories have high volume AND high financial impact?

Select
	d.denial_category,
	count(*) AS total_denial_count,
	Round(
			Sum(
			Coalesce(c.allowed_amount,0) - Coalesce(c.paid_amount, 0)
			)
			,2) AS revenue_at_risk,
	Round(
			Avg(
			Coalesce(c.allowed_amount, 0) - Coalesce(c.paid_amount, 0)
			),2) AS avg_revenue_at_risk
From denials d join claims c
on c.claim_id = d.claim_id
group by denial_category
order by revenue_at_risk desc;


Select
	c.claim_id,
	c.payer_id,
	c.provider_id,
	c.billed_amount,
	c.allowed_amount,
	c.paid_amount,
	Round(
		Coalesce(c.allowed_amount, 0) - Coalesce (c.paid_amount, 0)
	,2) AS revenue_at_risk
from denials d join claims c
on c.claim_id = d.claim_id
where claim_status = 'Denied'
order by revenue_at_risk desc
limit 10;


Select
	d.claim_id,
	d.denial_category,
	d.denial_code,
	d.follow_up_date,
	d.SLA_days,
	d.sla_compliant,
	d.appeal_deadline,
	d.appeal_submission_date,
	d.appeal_timely
from denials d
where d.claim_id = 'CLM010171';

--How many denied claims have both a high financial risk and missed SLA?
--high-value" for our project as revenue at risk ≥ $2,000.

Select
	count(*) as high_value_sla_missed_claims
from claims c join denials d
on c.claim_id = d.claim_id
where c.claim_status = 'Denied'
and 
	(
	Coalesce(c.allowed_amount , 0) - Coalesce(c.paid_amount, 0)) 
	>= 2000
and d.sla_compliant = 'False';

SELECT c.claim_id,
COUNT(*) AS high_value_sla_missed_claims
FROM claims c
JOIN denials d
    ON c.claim_id = d.claim_id
WHERE c.claim_status = 'Denied'
  AND (COALESCE(c.allowed_amount, 0)
       - COALESCE(c.paid_amount, 0)) >= 2000
  AND d.sla_compliant = 'FALSE'
  group by c.claim_id;


--Which payer has the most high-priority claims?

Select
	c.payer_id,
	count(*) as high_priority_claims,
	Round(
		Sum(
		Coalesce(c.allowed_amount, 0) - coalesce(c.paid_amount, 0))
	,2) AS total_revenue_at_risk
from claims c join denials d
on c.claim_id = d.claim_id
where c.claim_status = 'Denied'
And (
		Coalesce(c.allowed_amount, 0) - coalesce(c.paid_amount, 0)
	) >= 2000
And d.sla_compliant = 'FALSE'
Group by c.payer_id
order by total_revenue_at_risk desc;


SELECT
    c.payer_id,
    COUNT(*) AS high_priority_claims,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS share_of_high_priority_claims
FROM claims c
JOIN denials d
    ON c.claim_id = d.claim_id
WHERE c.claim_status = 'Denied'
  AND (
        COALESCE(c.allowed_amount, 0)
        - COALESCE(c.paid_amount, 0)
      ) >= 2000
  AND d.sla_compliant = 'FALSE'
GROUP BY c.payer_id
ORDER BY share_of_high_priority_claims DESC;

--Which providers have the highest denial rates?

Select
	c.provider_id,
	p.provider_name,
	p.specialty,
	count(*) AS total_claims,
	count(*) Filter(
		Where c.claim_status = 'Denied'
	) AS denied_claims,
	Round(
			count(*) Filter (Where c.claim_status = 'Denied') * 100.0 / Count(*),
			2) AS denial_rate
from claims c
Join providers p
on c.provider_id = p.provider_id
group by c.provider_id,
		p.provider_name,
		p.specialty
order by denial_rate desc;

--Which specialties experience the most denials?

Select
	p.specialty,
	count(*) AS total_claims,
	count(*) Filter (Where c.claim_status = 'Denied') AS denied_claims,
	Round(
			count(*) Filter(Where c.claim_status = 'Denied') * 100.0 / Count(*) ,2)
			AS denial_rate
from claims c Join providers p
on c.provider_id = p.provider_id
group by p.specialty
order by denial_rate desc;


--Which denial categories have the highest late-appeal rate?

Select
	d.denial_category,
	count(*) AS submitted_appeals,
	count(*) Filter (Where d.appeal_timely = '0') AS
	late_appeals,
	Round(
		Count(*) Filter (Where d.appeal_timely = '0') * 100.0 / Count(*),
	2) AS late_appeal_rate
from denials d
Where d.appeal_timely IN ('1', '0')
group by d.denial_category
order by late_appeal_rate desc;


---------------------------AR Followup------------------------------------

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

Select
	* from ar_followup
	limit 10;

select Count(*) as total_rows
from ar_followup;

Select
	Min(days_in_ar) as min_days_in_ar,
	max(days_in_ar) as max_days_in_ar,
	Round(AVG(days_in_ar),2) as avg_days_in_ar
from ar_followup;

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


SELECT
    claim_id,
    denial_date,
    follow_up_date,
    last_action_date,
    days_in_ar,
    (last_action_date - denial_date) AS calculated_days
FROM ar_followup
WHERE days_in_ar < 0
ORDER BY days_in_ar
LIMIT 20;

Select
	count(*) AS total_claims,
	count(*) Filter (Where last_action_date IS NULL) AS missing_last_action,
	count(*) Filter (Where last_action_date IS NOT NULL) AS available_last_action
from ar_followup;


SELECT
    MIN(last_action_date - denial_date) AS min_calculated_days,
    MAX(last_action_date - denial_date) AS max_calculated_days,
    ROUND(AVG(last_action_date - denial_date), 2) AS avg_calculated_days
FROM ar_followup
WHERE last_action_date IS NOT NULL;

SELECT
    resolution,
    COUNT(*) AS claim_count
FROM ar_followup
GROUP BY resolution
ORDER BY claim_count DESC;

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

-----------------------------How does AR aging vary across aging buckets?---------------------------

WITH latest_followup AS (
	Select
		claim_id,
		days_in_ar,
		row_number() 
			Over(partition by claim_id
			order by last_action_date desc) AS rn
	from ar_followup
),

Payment_summary AS (
	Select
		claim_id,
		sum(paid_amount) AS total_paid
	from payments
	group by claim_id
),

claims_summary AS (
	Select
		claim_id,
		max(allowed_amount) AS allowed_amount
	from claims
	group by claim_id
)

Select
		CASE
			When lf.days_in_ar between 0 and 30 then 'o-30 days'
			When lf.days_in_ar between 31 and 60 then '31-60 days'
			When lf.days_in_ar between 61 and 90 then '61-90 days'
			When lf.days_in_ar between 91 and 120 then '91-120 days'
			Else '120+ days'
		End AS ageing_bucket,
		count(*) AS claim_count,

		Round(
				Sum(
					cs.allowed_amount - coalesce (ps.total_paid, 0)) :: numeric,
				2) AS outstanding_amount
		from latest_followup lf
		Join claims_summary cs
		on lf.claim_id = cs.claim_id
		Left Join payment_summary ps
		on cs.claim_id = ps.claim_id

	Where lf.rn = 1
	And lf.days_in_ar > 0

	Group by 
		CASE
			When lf.days_in_ar between 0 and 30 then '0 to 30 days'
			When lf.days_in_ar between 31 and 60 then '31 to 60 days'
			When lf.days_in_ar between 61 and 90 then '61 to 90 days'
			When lf.days_in_ar between 91 and 120 then '91 to 120 days'
			Else '120+ days'
		End

	Order by
		CASE
			When Min(lf.days_in_ar) between 0 and 30 then 1
			When Min(lf.days_in_ar) between 31 and 60 then 2
			When Min(lf.days_in_ar) between 61 and 90 then 3
			When Min(lf.days_in_ar) between 91 and 120 then 4
			Else 5
		End;
		
		
		
--------------------------------------------------------------

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

claims_summary AS (
    SELECT
        claim_id,
        MAX(allowed_amount) AS allowed_amount
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
            WHEN lf.days_in_ar BETWEEN 0 AND 30 THEN '0-30 Days'
            WHEN lf.days_in_ar BETWEEN 31 AND 60 THEN '31-60 Days'
            WHEN lf.days_in_ar BETWEEN 61 AND 90 THEN '61-90 Days'
            WHEN lf.days_in_ar BETWEEN 91 AND 120 THEN '91-120 Days'
            ELSE '120+ Days'
        END AS aging_bucket

    FROM latest_followup lf

    JOIN claims_summary cs
        ON lf.claim_id = cs.claim_id

    LEFT JOIN payment_summary ps
        ON cs.claim_id = ps.claim_id

    WHERE lf.rn = 1
      AND lf.days_in_ar >= 0
)

SELECT
    aging_bucket,

    COUNT(*) AS claim_count,

    ROUND(
        SUM(allowed_amount - total_paid)::numeric,
        2
    ) AS outstanding_amount

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


---------------------------------------------------------


WITH latest_followup AS (
	Select
		claim_id,
		days_in_ar,
		Row_Number() Over
		(
			partition by claim_id
			order by last_action_date desc
		) AS rn
	from ar_followup

		),
payment_summary AS (
		Select
			claim_id,
			sum(paid_amount) as total_paid
		from payments
		group by claim_id
		),
claim_summary AS (
		Select
			claim_id,
			max(allowed_amount) AS allowed_amount,
			max(claim_status) AS claim_status
		from claims
		group by claim_id
		),
ar_data AS (
		Select 
			lf.claim_id,
			lf.days_in_ar,
			cs.allowed_amount,
			Coalesce(ps.total_paid, 0) AS total_paid,

		CASE
			When lf.days_in_ar Between 0 And 30
			then '0-30 days'
			when lf.days_in_ar between 31 And 60
			then '31 to 60 days'
			When lf.days_in_ar Between 61 And 90
			then '61 to 90 days'
			When lf.days_in_ar Between 91 And 120
			then '91 to 120 days'
			Else
			'120+ days'
			End AS ageing_bucket
		from latest_followup lf
		join claim_summary cs
		on lf.claim_id = cs.claim_id
		Left Join payment_summary ps
		on cs.claim_id = ps.claim_id

		Where lf.rn = 1
		And lf.days_in_ar >= 0
		And cs.claim_status = 'Denied'
		)

		Select ageing_bucket,
		count(*) AS claim_count,
		Round (
				Sum(allowed_amount - total_paid) :: numeric,2) AS outstanding_amount
		From ar_data
		group by ageing_bucket
		order by 
			case ageing_bucket
				When '0-30 days' Then 1
				When '31-60 days' Then 2
				When '61 - 90 days' Then 3
				When '91-120 days' Then 4
				When '120+ days' Then 5
			End;
			
-------------------------------------------------------------------------------------------

--How does AR aging vary by payer and denial category?


With latest_followup AS (
	Select
		claim_id,
		days_in_ar,
		Row_number() Over(
				partition by claim_id
				order by last_action_date desc
			) AS rn
		from ar_followup
),

payment_summary AS (
		Select
			claim_id,
			sum(paid_amount) AS total_paid
		from payments
		group by claim_id

),

claim_history AS (
	Select
		claim_id,
		max(allowed_amount) AS allowed_amount,
		max(claim_status) AS claim_status,
		max(payer_id) AS payer_id
	from claims
	group by claim_id
),

ar_data AS  (
	Select
		lf.claim_id,
		ch.payer_id,
		lf.days_in_ar,
		ch.allowed_amount,
		coalesce(ps.total_paid, 0) AS total_paid,

	CASE
		When lf.days_in_ar between 0 And 30
		 Then '0-30 days'
		When lf.days_in_ar between 31 And 60
			Then '31-60 days'
		when lf.days_in_ar between 61 And 90
			Then '61-90 days'
		When lf.days_in_ar between 91 and 120
			Then '91-120 days'
		Else
			'120+ days'
		End as ageing_bucket

	From latest_followup lf
	Join claim_history ch
	ON lf.claim_id = ch.claim_id
	Left Join payment_summary ps
	On ch.claim_id = ps.claim_id
	Where lf.rn = 1
	And lf.days_in_ar >=0
	And ch.claim_status = 'Denied'
	)

	Select
		payer_id,
		ageing_bucket,
		count(*) AS claim_count,

		Round(
				Sum(allowed_amount - total_paid) ::numeric ,2) AS outstanding_amount
	from ar_data
	group by
		payer_id,
		ageing_bucket
	order by
		payer_id,
		CASE ageing_bucket
		WHEN '0-30 Days' THEN 1
        WHEN '31-60 Days' THEN 2
        WHEN '61-90 Days' THEN 3
        WHEN '91-120 Days' THEN 4
        WHEN '120+ Days' THEN 5
    END;

---------------------------------------------------------------------------
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
        )::numeric,
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


-------------------------------------------------------

WITH latest_followup  AS 
(

	Select
		claim_id,
		days_in_ar,
		row_number() Over(
						partition by claim_id
						order by last_action_date desc
						) AS rn
	from ar_followup
),

payment_summary AS (
	Select
		claim_id,
		sum(paid_amount) AS total_paid	
	from payments
	group by claim_id
),

claim_history AS (
	Select
		claim_id,
		max(allowed_amount) AS allowed_amount,
		max(claim_status) AS claim_status,
		max(payer_id) AS payer_id
	from claims
	group by claim_id
)

Select
	coalesce (ch.payer_id, 'unknown') as payer_id,
	count(*) AS claim_count,
	Round(
			sum(
				ch.allowed_amount - coalesce (ps.total_paid, 0))::numeric,
			2
			) AS outstanding_120_plus
	from latest_followup lf
	join claim_history ch
	on lf.claim_id = ch.claim_id
	left join payment_summary ps
	on ch.claim_id = ps.claim_id

	Where lf.rn = 1
		And lf.days_in_ar >= 120
		And ch.claim_status = 'Denied'
		group by ch.payer_id
		order by outstanding_120_plus desc;
-----------------

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
        )::numeric,
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



----------------------------------------------------

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
    CASE
        WHEN lf.escalation_required IS TRUE THEN 'Yes'
        WHEN lf.escalation_required IS FALSE THEN 'No'
        ELSE 'Unknown'
    END AS escalation_required,

    COUNT(*) AS claim_count,

    ROUND(
        SUM(
            ch.allowed_amount
            - COALESCE(ps.total_paid, 0)
        )::numeric,
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
        WHEN lf.escalation_required IS TRUE THEN 'Yes'
        WHEN lf.escalation_required IS FALSE THEN 'No'
        ELSE 'Unknown'
    END

ORDER BY outstanding_ar DESC;

-----------------------------------------------------------------


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
    ch.payer_id,
    lf.days_in_ar,
    lf.priority,
    lf.resolution,
    lf.sla_compliant,

    ROUND(
        (
            ch.allowed_amount
            - COALESCE(ps.total_paid, 0)
        )::numeric,
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


---------------------------------------------

SELECT
    claim_id,
    payer_id,
    allowed_amount,
    claim_status
FROM claims
WHERE claim_id = 'CLM009946';

---------------------------------------------------


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
    COALESCE(ch.payer_id, 'Unknown') AS payer_id,
    COUNT(*) AS critical_escalation_claims,
    ROUND(
        SUM(
            ch.allowed_amount
            - COALESCE(ps.total_paid, 0)
        )::numeric,
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













