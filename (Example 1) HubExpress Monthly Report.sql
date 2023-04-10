/*************************************************************************************************** 
**************************************************************************************************** 
TITLE:  HubExpress Monthly Reporting
AUTHOR:  sbarnes
DATE ADDED:  20220906
DESCRIPTION:  This code feeds a monthly repeating report for one of our clients to track their brands' performance.

MODIFIED
User		Date		Reason
****************************************************************************************************
****************************************************************************************************/

-- Access Rate

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

declare @start datetime set @start = dateadd(mm,datediff(mm,0,getdate())-13,0)
declare @end datetime set @end = dateadd(mm,datediff(mm,0,getdate())-1,0)

SELECT 
request_month AS 'Month',
drug_name,
COUNT (DISTINCT request_id_mask) AS 'PA Volume',
COUNT(DISTINCT CASE WHEN revenue_source_category ='Pharmacy' AND accessed_online = 1 THEN request_id_mask
WHEN revenue_source_category = 'Physician' THEN request_id_mask ELSE NULL END) AS 'Accessed'
SUM (sent_to_plan) AS 'Submitted',
SUM (known_outcome) AS 'Known Outcome',
SUM (approved) AS 'Approved',
lob,
pa_type AS 'PA Type',
rejection_code AS 'Reject Code',
revenue_source_category,
revenue_source
FROM pharma_mart..vw_tableau_product_reporting
WHERE request_month between @start and @end
and drug_name in ('[brand name]')
AND is_appeal = 0
GROUP BY request_month,drug_name,
revenue_source_category
ORDER BY 'Month', drug_name  
