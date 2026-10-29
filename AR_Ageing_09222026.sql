-----------------------------How does AR aging vary across aging buckets?---------------------------

WITH latest_followup AS (
	Select
		claim_id,
		days_in_ar,
		row_number() 
			Over(partition by claim_id
			order by last_action_date desc) AS rn
	from ar_followup
),

Payment_summary AS (
	Select
		claim_id,
		sum(paid_amount) AS total_paid
	from payments
	group by claim_id
),

claims_summary AS (
	Select
		claim_id,
		max(allowed_amount) AS allowed_amount
	from claims
	group by claim_id
)

Select
		CASE
			When lf.days_in_ar between 0 and 30 then 'o-30 days'
			When lf.days_in_ar between 31 and 60 then '31-60 days'
			When lf.days_in_ar between 61 and 90 then '61-90 days'
			When lf.days_in_ar between 91 and 120 then '91-120 days'
			Else '120+ days'
		End AS ageing_bucket,
		count(*) AS claim_count,

		Round(
				Sum(
					cs.allowed_amount - coalesce (ps.total_paid, 0)) :: numeric,
				2) AS outstanding_amount
		from latest_followup lf
		Join claims_summary cs
		on lf.claim_id = cs.claim_id
		Left Join payment_summary ps
		on cs.claim_id = ps.claim_id

	Where lf.rn = 1
	And lf.days_in_ar > 0

	Group by 
		CASE
			When lf.days_in_ar between 0 and 30 then '0 to 30 days'
			When lf.days_in_ar between 31 and 60 then '31 to 60 days'
			When lf.days_in_ar between 61 and 90 then '61 to 90 days'
			When lf.days_in_ar between 91 and 120 then '91 to 120 days'
			Else '120+ days'
		End

	Order by
		CASE
			When Min(lf.days_in_ar) between 0 and 30 then 1
			When Min(lf.days_in_ar) between 31 and 60 then 2
			When Min(lf.days_in_ar) between 61 and 90 then 3
			When Min(lf.days_in_ar) between 91 and 120 then 4
			Else 5
		End;
		
		
		
--------------------------------------------------------------

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

claims_summary AS (
    SELECT
        claim_id,
        MAX(allowed_amount) AS allowed_amount
    FROM claims
    GROUP BY claim_id
),

ar_data AS (
    SELECT
        lf.claim_id,
        lf.days_in_ar,
        cs.allowed_amount,
        COALESCE(ps.total_paid, 0) AS total_paid,

        CASE
            WHEN lf.days_in_ar BETWEEN 0 AND 30 THEN '0-30 Days'
            WHEN lf.days_in_ar BETWEEN 31 AND 60 THEN '31-60 Days'
            WHEN lf.days_in_ar BETWEEN 61 AND 90 THEN '61-90 Days'
            WHEN lf.days_in_ar BETWEEN 91 AND 120 THEN '91-120 Days'
            ELSE '120+ Days'
        END AS aging_bucket

    FROM latest_followup lf

    JOIN claims_summary cs
        ON lf.claim_id = cs.claim_id

    LEFT JOIN payment_summary ps
        ON cs.claim_id = ps.claim_id

    WHERE lf.rn = 1
      AND lf.days_in_ar >= 0
)

SELECT
    aging_bucket,

    COUNT(*) AS claim_count,

    ROUND(
        SUM(allowed_amount - total_paid)::numeric,
        2
    ) AS outstanding_amount

FROM ar_data

GROUP BY aging_bucket

ORDER BY
    CASE aging_bucket
        WHEN '0-30 Days' THEN 1
        WHEN '31-60 Days' THEN 2
        WHEN '61-90 Days' THEN 3
        WHEN '91-120 Days' THEN 4
        WHEN '120+ Days' THEN 5
    END;


---------------------------------------------------------


WITH latest_followup AS (
	Select
		claim_id,
		days_in_ar,
		Row_Number() Over
		(
			partition by claim_id
			order by last_action_date desc
		) AS rn
	from ar_followup

		),
payment_summary AS (
		Select
			claim_id,
			sum(paid_amount) as total_paid
		from payments
		group by claim_id
		),
claim_summary AS (
		Select
			claim_id,
			max(allowed_amount) AS allowed_amount,
			max(claim_status) AS claim_status
		from claims
		group by claim_id
		),
ar_data AS (
		Select 
			lf.claim_id,
			lf.days_in_ar,
			cs.allowed_amount,
			Coalesce(ps.total_paid, 0) AS total_paid,

		CASE
			When lf.days_in_ar Between 0 And 30
			then '0-30 days'
			when lf.days_in_ar between 31 And 60
			then '31 to 60 days'
			When lf.days_in_ar Between 61 And 90
			then '61 to 90 days'
			When lf.days_in_ar Between 91 And 120
			then '91 to 120 days'
			Else
			'120+ days'
			End AS ageing_bucket
		from latest_followup lf
		join claim_summary cs
		on lf.claim_id = cs.claim_id
		Left Join payment_summary ps
		on cs.claim_id = ps.claim_id

		Where lf.rn = 1
		And lf.days_in_ar >= 0
		And cs.claim_status = 'Denied'
		)

		Select ageing_bucket,
		count(*) AS claim_count,
		Round (
				Sum(allowed_amount - total_paid) :: numeric,2) AS outstanding_amount
		From ar_data
		group by ageing_bucket
		order by 
			case ageing_bucket
				When '0-30 days' Then 1
				When '31-60 days' Then 2
				When '61 - 90 days' Then 3
				When '91-120 days' Then 4
				When '120+ days' Then 5
			End;
			
-------------------------------------------------------------------------------------------

--How does AR aging vary by payer and denial category?


With latest_followup AS (
	Select
		claim_id,
		days_in_ar,
		Row_number() Over(
				partition by claim_id
				order by last_action_date desc
			) AS rn
		from ar_followup
),

payment_summary AS (
		Select
			claim_id,
			sum(paid_amount) AS total_paid
		from payments
		group by claim_id

),

claim_history AS (
	Select
		claim_id,
		max(allowed_amount) AS allowed_amount,
		max(claim_status) AS claim_status,
		max(payer_id) AS payer_id
	from claims
	group by claim_id
),

ar_data AS  (
	Select
		lf.claim_id,
		ch.payer_id,
		lf.days_in_ar,
		ch.allowed_amount,
		coalesce(ps.total_paid, 0) AS total_paid,

	CASE
		When lf.days_in_ar between 0 And 30
		 Then '0-30 days'
		When lf.days_in_ar between 31 And 60
			Then '31-60 days'
		when lf.days_in_ar between 61 And 90
			Then '61-90 days'
		When lf.days_in_ar between 91 and 120
			Then '91-120 days'
		Else
			'120+ days'
		End as ageing_bucket

	From latest_followup lf
	Join claim_history ch
	ON lf.claim_id = ch.claim_id
	Left Join payment_summary ps
	On ch.claim_id = ps.claim_id
	Where lf.rn = 1
	And lf.days_in_ar >=0
	And ch.claim_status = 'Denied'
	)

	Select
		payer_id,
		ageing_bucket,
		count(*) AS claim_count,

		Round(
				Sum(allowed_amount - total_paid) ::numeric ,2) AS outstanding_amount
	from ar_data
	group by
		payer_id,
		ageing_bucket
	order by
		payer_id,
		CASE ageing_bucket
		WHEN '0-30 Days' THEN 1
        WHEN '31-60 Days' THEN 2
        WHEN '61-90 Days' THEN 3
        WHEN '91-120 Days' THEN 4
        WHEN '120+ Days' THEN 5
    END;

---------------------------------------------------------------------------
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
    ) AS outstanding_120_plus

FROM latest_followup lf

JOIN claim_history ch
    ON lf.claim_id = ch.claim_id

LEFT JOIN payment_summary ps
    ON ch.claim_id = ps.claim_id

WHERE lf.rn = 1
  AND lf.days_in_ar >= 120
  AND ch.claim_status = 'Denied'

GROUP BY ch.payer_id

ORDER BY outstanding_120_plus DESC;


-------------------------------------------------------

WITH latest_followup  AS 
(

	Select
		claim_id,
		days_in_ar,
		row_number() Over(
						partition by claim_id
						order by last_action_date desc
						) AS rn
	from ar_followup
),

payment_summary AS (
	Select
		claim_id,
		sum(paid_amount) AS total_paid	
	from payments
	group by claim_id
),

claim_history AS (
	Select
		claim_id,
		max(allowed_amount) AS allowed_amount,
		max(claim_status) AS claim_status,
		max(payer_id) AS payer_id
	from claims
	group by claim_id
)

Select
	coalesce (ch.payer_id, 'unknown') as payer_id,
	count(*) AS claim_count,
	Round(
			sum(
				ch.allowed_amount - coalesce (ps.total_paid, 0))::numeric,
			2
			) AS outstanding_120_plus
	from latest_followup lf
	join claim_history ch
	on lf.claim_id = ch.claim_id
	left join payment_summary ps
	on ch.claim_id = ps.claim_id

	Where lf.rn = 1
		And lf.days_in_ar >= 120
		And ch.claim_status = 'Denied'
		group by ch.payer_id
		order by outstanding_120_plus desc;

