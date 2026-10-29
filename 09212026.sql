Select
	resolution,
	count(*) as total_claims,
	round(sum(days_in_ar),2) AS total_days_in_ar,
	round(avg(days_in_ar),2) AS avg_days_in_ar
from ar_followup
group by resolution
order by total_claims desc;



Select
	a.resolution,
	count(*) AS total_claims,
	Round(sum(c.allowed_amount - coalesce(p.paid_amount, 0)) :: numeric ,2) AS outstanding_amount,
	Round(avg(c.allowed_amount - coalesce(p.paid_amount, 0)) :: numeric ,2) AS avg_outstanding_amount
	from ar_followup a Join claims c
	on a.claim_id = c.claim_id
	Left Join payments p
	on c.claim_id = p.claim_id
	group by a.resolution
	order by outstanding_amount desc;


Select
	count(*) AS total_payment_rows,
	count(distinct claim_id) as unique_claims
from payments;


Select
	claim_id,
	count(*) AS payment_records
from payments
group by claim_id
having count(*) > 1
order by payment_records desc;


Select
	claim_id,
	sum(paid_amount) AS total_paid
from payments
group by claim_id;


WITH payment_summary AS (
	Select
		claim_id,
		sum(paid_amount) AS total_paid
	from payments
	group by claim_id
)

Select
	a.resolution,
	count(*) AS total_claims,
	Round(Sum(c.allowed_amount - coalesce (ps.total_paid, 0)) :: numeric, 2) AS outstanding_amount,
	ROUND(
        AVG(
            c.allowed_amount - COALESCE(ps.total_paid, 0)
        )::numeric,
        2
    ) AS avg_outstanding_amount
	
	from ar_followup a 
	Join claims c
	on a.claim_id = c.claim_id
	Left Join payment_summary ps
	on c.claim_id = ps.claim_id
	group by a.resolution
	order by outstanding_amount desc;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT claim_id) AS unique_claims
FROM ar_followup;

Select
	claim_id,
	count(*) AS followup_records
from ar_followup
group by claim_id
having count(*) > 1
order by followup_records desc;

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


WITH ranked_followup AS 
(
	Select
		*,
		row_number() Over(partition by claim_id
		order by last_action_date desc) AS rn 
	from ar_followup
)

Select
	claim_id,
	denial_date,
	follow_up_date,
	last_action_date,
	resolution,
	days_in_ar,
	escalation_required,
	priority
from ranked_followup
where rn = 1
order by claim_id;

----------------------------------------------------------


WITH latest_followup AS (
	Select
		*,
		row_number() Over(partition by claim_id
		order by last_action_date desc) AS rn
	from ar_followup
),

payment_summary AS (
	Select
		claim_id,
		sum(paid_amount) AS total_paid
	from payments
	group by claim_id
)

Select
	lf.resolution,
	count(*) AS claim_count,
	Round(
		Sum(c.allowed_amount - coalesce(ps.total_paid,0)) :: numeric ,2) AS outstanding_amount,
	Round(
		Avg(c.allowed_amount - coalesce (ps.total_paid, 0)) :: numeric ,2) AS avg_outstanding_per_claim
from latest_followup lf
join claims c 
on lf.claim_id = c.claim_id
Left Join payment_summary ps
on c.claim_id = ps.claim_id
Where lf.rn = 1
group by lf.resolution
order by outstanding_amount desc;



SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT claim_id) AS unique_claims
FROM claims;


Select
	claim_id,
	count(*) AS claim_records
from claims
group by claim_id
having count(*) > 1
order by claim_records desc;


SELECT
    c.claim_id,
    COUNT(*) AS claim_rows,
    COUNT(DISTINCT c.allowed_amount) AS different_allowed_amounts
FROM claims c
WHERE c.claim_id IN (
    SELECT claim_id
    FROM ar_followup
    GROUP BY claim_id
    HAVING COUNT(*) > 1
)
GROUP BY c.claim_id
HAVING COUNT(*) > 1
ORDER BY c.claim_id;



-------------------------



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
            cs.allowed_amount - COALESCE(ps.total_paid, 0)
        )::numeric,
        2
    ) AS outstanding_amount,
    ROUND(
        AVG(
            cs.allowed_amount - COALESCE(ps.total_paid, 0)
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



--------------------------------------------------------------


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
    cs.payer_id,
    COUNT(*) AS claim_count,
    ROUND(AVG(lf.days_in_ar)::numeric, 2) AS avg_days_in_ar,
    ROUND(
        SUM(
            cs.allowed_amount - COALESCE(ps.total_paid, 0)
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


------------------------------------------------

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