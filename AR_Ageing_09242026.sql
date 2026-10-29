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