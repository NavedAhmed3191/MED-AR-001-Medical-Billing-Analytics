--Which denial codes contribute the most to denied dollars?

Select * from denials
limit 2

select * from claims
limit 2

Select
	d.claim_id,
	d.denial_code,
	c.claim_status,
	c.allowed_amount
from denials d Join claims c
on d.claim_id = c.claim_id
limit 20;

Select
	d.denial_code,
	count(*) as denial_count,
	round(sum(c.allowed_amount),2) as denial_dollars
from denials d
join claims c
on d.claim_id = c.claim_id
group by d.denial_code
order by denial_dollars desc;


--Which specialties experience the most denials?

Select
	c.claim_id,
	c.provider_id,
	c.claim_status,
	p.specialty
from claims c Join providers p
on c.provider_id = p.provider_id
Where c.claim_status = 'Denied'
limit 20;


Select
	p.specialty,
	count(*) as denied_claims
from claims c
join providers p
on c.provider_id = p.provider_id
Where c.claim_status = 'Denied'
group by p.specialty
order by denied_claims desc
limit 20;

--Denial rates by specialty

Select
	p.specialty,
	count(*) as denied_claims,
	sum(
		CASE
		When c.claim_status = 'Denied' Then 1
		ELSE 0
		END
	) AS denied_claims,
	Round(Sum
	(
	Case 
		When c.claim_status = 'Denied' then 1
		Else 0
		End
		) * 100.0/ count(*),2 ) AS denial_rate
from claims c
Join providers p
on c.provider_id = p.provider_id
group by p.specialty
order by denial_rate desc;


--Was the denial worked within the established SLA?


Select
	claim_id,
	denial_category,
	denial_date,
	follow_up_date,
	SLA_days
	SLA_complaint
from denials
limit 20;

Select
	claim_id,
	denial_category,
	denial_date,
	follow_up_date,
	SLA_days,
	(follow_up_date - denial_date) as follow_up_days
from denials
limit 20;


Select
	claim_id,
	denial_category,
	denial_date,
	follow_up_date,
	SLA_days,
	(follow_up_date - denial_date) as follow_up_days,
	CASE
		
		When (follow_up_date - denial_date) <= SLA_days
				then 'complaint'
				else 'not complaint'
				End as sla_status
from denials
limit 20;


Select count(*) as total_denials
from denials

Select count(*) as complaint_denials
from denials
where (follow_up_date - denial_date) <= SLA_days


--What % of denials were worked outside SLA / which payers have the highest SLA-miss rate?

Select
	c.payer_id,
	d.claim_id,
	d.sla_days,
	(d.follow_up_date - d.denial_date) as follow_up_days
from denials d Join claims c
on c.claim_id = d.claim_id
limit 20;


Select
	c.payer_id,
	count(*) as total_denials,
	sum (
		Case
			When(d.follow_up_date - d.denial_date) > sla_days
			then 1
			else 0
			End
	) AS sla_missed
from denials d Join claims c
on d.claim_id = c.claim_id
group by c.payer_id
order by sla_missed desc;


Select
	c.payer_id,
	count(*) as total_denial,
	sum(
		CASE
		When (d.follow_up_date - d.denial_date) > d.SLA_days
		then 1
		else 0
		End
	) AS sla_missed,
	round(
		sum(
			case
			when(d.follow_up_date - d.denial_date) > d.SLA_days
			then 1
			else 0
			End
		) * 100.0 / count(*),2
		) as SLA_miss_rate
from denials d Join claims c
on d.claim_id = c.claim_id
group by c.payer_id
order by SLA_miss_rate desc;