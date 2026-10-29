

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