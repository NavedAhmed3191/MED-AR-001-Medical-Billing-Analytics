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
