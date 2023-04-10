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

-- External Reporting HubExpress

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

declare @start datetime set @start = dateadd(mm,datediff(mm,0,getdate())-13,0)
declare @end datetime set @end = dateadd(mm,datediff(mm,0,getdate())-1,0)

select
	request_month
	,drug_name
	,pa_volume as HE_PA_volume
	,appeal_volume as HE_Appeal_volume
	,count(case when is_monitoring = 'Service' then 'Serviced' else null end) as 'Serviced'
	,count(case when is_monitoring = 'Monitoring' then 'Monitored' else null end) as 'Monitored'
from pharma_mart.dbo.t_external_reporting_hubexpress
where drug_name in ('[brand name])
and request_month between @start and @end
group by
	request_month
	,drug_name
	,pa_volume
	,appeal_volume
