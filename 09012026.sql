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










