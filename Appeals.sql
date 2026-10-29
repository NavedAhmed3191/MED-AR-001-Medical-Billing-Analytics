--“Were appeals submitted before the deadline?

Select
	claim_id,
	denial_category,
	appeal_deadline,
	appeal_submission_date
from denials
limit 20;

Select
	claim_id,
	denial_category,
	appeal_deadline,
	appeal_submission_date,
	CASE
	When appeal_submission_date IS NULL 
	Then 'Not Submitted'

	When appeal_submission_date <= appeal_deadline
	then 'Timely'

	ElSE
		'Late'
	End as appeal_status
from denials
limit 20;



SELECT
    CASE
        WHEN appeal_submission_date IS NULL
            THEN 'Not Submitted'

        WHEN appeal_submission_date <= appeal_deadline
            THEN 'Timely'

        ELSE 'Late'
    END AS appeal_status,

    COUNT(*) AS denial_count

FROM denials

GROUP BY appeal_status
ORDER BY denial_count DESC;



SELECT
    COUNT(*) FILTER (
        WHERE appeal_submission_date <= appeal_deadline
    ) AS timely_appeals,

    COUNT(*) FILTER (
        WHERE appeal_submission_date > appeal_deadline
    ) AS late_appeals,

    COUNT(*) FILTER (
        WHERE appeal_submission_date IS NOT NULL
    ) AS submitted_appeals

FROM denials;



--Which denial categories have the highest late-appeal rate?

Select
	Count(*) AS late_appeal_count
from denials
Where appeal_submission_date IS NOT NULL
and appeal_submission_date > appeal_deadline;

Select
	denial_category,
	count(*) As late_appeal_count
from denials
where appeal_submission_date > appeal_deadline
group by denial_category
order by late_appeal_count desc;

Select
	denial_category,
	count(*) Filter(
			Where appeal_submission_date is NOT NULL
	) AS Submitted_appeals,
	Count(*) Filter (
			Where appeal_submission_date IS NOT NULL
			and appeal_submission_date > appeal_deadline
	) AS late_appeals,
	Round(
		Count(*) Filter (
			Where appeal_submission_date IS NOT NUll
			and appeal_submission_date > appeal_deadline
		) * 100.0/ Nullif (
					count(*) Filter (Where appeal_submission_date is NOT NUll),0)
	,2) AS late_appeal_rate
	
from denials
group by denial_category
order by late_appeal_rate desc;

