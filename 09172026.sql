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

