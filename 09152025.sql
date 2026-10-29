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