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
