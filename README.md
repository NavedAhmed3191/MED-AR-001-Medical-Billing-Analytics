Medical Billing Denial & Accounts Receivable Analytics

Project ID: MED-AR-001
Domain: US Healthcare / Medical Billing
Tools: PostgreSQL, Power BI, DAX

Project Overview

This project analyzes medical billing claims, insurance denials, payments, and accounts receivable (AR) to identify revenue risks and opportunities to improve revenue-cycle operations.

SQL was used for data analysis and validation, while Power BI was used to create an interactive dashboard and summarize business findings.

Business Problem

Denied claims, delayed payments, and outstanding receivables can affect cash flow and increase billing follow-up work. This project examines denial patterns, payer performance, AR aging, and appeal timeliness to identify areas for improvement.

Tools and Technologies

PostgreSQL — SQL queries, joins, aggregations, and validation

Power BI — KPI cards, charts, and dashboard reporting

DAX — measures and reporting calculations

Data analysis — denial trends, payer comparisons, and data-quality checks

Key Findings

Analyzed a cleaned claims dataset containing approximately 15,000 claims.

Identified 2,891 denial records across 12 denial categories.

Authorization was the highest-volume denial category, with 387 denial records.

Behavioral Health had 736 denials among 2,996 claims, approximately a 24.57% denial rate.

Identified 20 claims with missing payer IDs for investigation.

Analyzed accounts receivable aging and appeal timeliness.

The Average Days in AR card displays 14.23 based on 2,832 valid corrected records.

Counts can differ depending on table grain, distinct-count logic, relationships, and report filters. KPI figures should be reconciled before final publication.

Business Recommendations

Investigate authorization-related denials and strengthen authorization checks.

Review payer-specific denial patterns.

Investigate claims with missing payer identifiers.

Prioritize older outstanding receivables for follow-up.

Monitor appeal submission timeliness and pending appeals.

Track denial trends to evaluate corrective actions.

Data Quality Considerations

The analysis includes checks for missing payer IDs, denial records, appeal timeliness, dates, and corrected AR days. Missing information should be investigated rather than changed without supporting evidence.

Project Deliverables

SQL-based analysis and validation

Power BI Executive Dashboard

Final Analysis Summary page

Business recommendations

Data-quality observations

Disclaimer

This is a portfolio project using non-production data. It does not represent actual patient records or verified financial outcomes.
## Power BI Dashboard

![Executive Dashboard](Executive%20Dashboard.png)

## Final Analysis Summary

## Tools & Technologies

- **PostgreSQL:** Data storage, querying, and analysis
- **SQL:** Data validation, joins, aggregations, and denial analysis
- **Power BI:** Interactive dashboards and data visualization
- **DAX:** KPI measures and business calculations
- **Power Query:** Data preparation and transformation

![Final Analysis Summary](Final%20Analysis%20Summary-2.png)
