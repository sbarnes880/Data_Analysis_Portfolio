/*************************************************************************************************** 
**************************************************************************************************** 
TITLE:  HubExpress Monthly Reporting
AUTHOR:  sbarnes
DATE ADDED:  20220906
DESCRIPTION:  This code feeds a monthly repeating report for one of our clients to track their brands' performance. HubExpress is the name of the product.

MODIFIED
User		Date		Reason
****************************************************************************************************
****************************************************************************************************/

-- Access Rate

set nocount on
set ansi_warnings off

declare @start datetime set @start = dateadd(mm,datediff(mm,0,getdate())-13,0) -- Set dates to grab a rolling 13 month period
declare @end datetime set @end = dateadd(mm,datediff(mm,0,getdate())-1,0)

select 
      request_month AS 'Month',
      drug_name,
      count (distinct request_id_mask) AS 'PA Volume',
      count (distinct case when revenue_source_category ='Pharmacy' and accessed_online = 1 then request_id_mask
      when revenue_source_category = 'Physician' then request_id_mask else null end) as 'Accessed'
      sum (sent_to_plan) as 'Submitted',
      sum (known_outcome) as 'Known Outcome',
      sum (approved) as 'Approved',
      lob,
      pa_type as 'PA Type',
      rejection_code as 'Reject Code',
      revenue_source_category,
      revenue_source
from pharma_mart..vw_tableau_product_reporting
where request_month between @start and @end
and drug_name in ('[brand name]')
and is_appeal = 0
group by 
      request_month,drug_name,
      revenue_source_category
order by
      'Month', 
      drug_name  
