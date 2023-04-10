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

-- External Reporting Outcomes

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

declare @start datetime set @start = dateadd(mm,datediff(mm,0,getdate())-13,0)
declare @end datetime set @end = dateadd(mm,datediff(mm,0,getdate())-1,0)

select
	request_month
	,drug_name
	,drug_custom_name
	,user_type
	,revenue_source
	,form_name
	,lob
	,pharma_state
	,rejection_code
	,pa_type
	,count_pa_tat_creation_outcome
	,count_pa_tat_submission_outcome
	,sum_appeal_tat_creation_outcome
	,sum(pa_volume) as PA_Volume
	,sum(pa_approved_volume) as pa_approved_volume
	,sum(pa_denied_volume) as pa_denied_volume 
	,sum(pa_submitted_volume) as pa_submitted_volume
	,sum(pa_known_outcome_volume) as pa_known_outcome_volume
	,sum(pa_accessed_volume) as pa_accessed_volume
	,sum(case_approved_volume) as case_approved_volume
	,sum(case_denied_volume) as case_denied_volume
	,sum(case_known_outcome_volume) as case_known_outcome_volume
	,sum(appeal_volume) as appeal_volume
	,sum(appeal_approved_volume) as appeal_approved_volume
	,sum(appeal_submitted_volume) as appeal_submitted_volume
	,sum(appeal_known_outcome_volume) as appeal_known_outcome_volume
	,sum(case when he_program_interactions = 'PriorAuthPlus Shared Into HubExpress' then 1 else 0 end) as 'PA+ Shared Into HE'
	,sum(case when he_program_interactions = 'Continuity of Care Shared Into HubExpress' then 1 else 0 end) as 'CoC Shared Into HE'
	,sum(case when he_program_interactions = 'HubExpress Initiated Requests' then 1 else 0 end) as 'HE Initiated'
	,sum(case when he_program_interactions = 'PA Reach Shared Into HubExpress' then 1 else 0 end) as 'PAReach Shared Into HE'
from pharma_mart.dbo.t_external_reporting_outcomes 
where drug_name in ('[brand name]')
and request_month between @start and @end
group by
	request_month
	,drug_name
	,drug_custom_name
	,user_type
	,revenue_source 
	,form_name
	,lob
	,pharma_state
	,rejection_code
	,pa_type
	,count_pa_tat_creation_outcome
	,count_pa_tat_submission_outcome
	,sum_appeal_tat_creation_outcome
