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


