/*************************************************************************************************** 
**************************************************************************************************** 
TITLE:  J&J HubEx Monthly Reporting
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
--SUM (sent_to_plan) AS 'Submitted',
--SUM (known_outcome) AS 'Known Outcome',
--SUM (approved) AS 'Approved',
--lob,
--pa_type AS 'PA Type',
--rejection_code AS 'Reject Code',
--revenue_source_category,
--revenue_source
FROM pharma_mart..vw_tableau_product_reporting
WHERE request_month between @start and @end
and drug_name in ('Darzalex SubQ', 'Elmiron', 'Erleada', 'Invokana', 'Opsumit', 'Ponvory', 
					'Simponi', 'Spravato', 'Stelara', 'Symtuza', 'Tremfya', 'Uptravi', 'Xarelto')
AND is_appeal = 0
--AND pharma_client = 'Johnson'
GROUP BY request_month,drug_name,
revenue_source_category
ORDER BY 'Month', drug_name


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
where drug_name in ('Darzalex SubQ', 'Elmiron', 'Erleada', 'Invokana', 'Opsumit', 'Ponvory', 
					'Simponi', 'Spravato', 'Stelara', 'Symtuza', 'Tremfya', 'Uptravi', 'Xarelto')
and request_month between @start and @end
group by
	request_month
	,drug_name
	,pa_volume
	,appeal_volume
  
  
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
	,revenue_source -- for finding renewals
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
	,sum(pa_denied_volume) as pa_denied_volume -- for denial rate
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
where drug_name in ('Darzalex SubQ', 'Elmiron', 'Erleada', 'Invokana', 'Opsumit', 'Ponvory', 
					'Simponi', 'Spravato', 'Stelara', 'Symtuza', 'Tremfya', 'Uptravi', 'Xarelto')
and request_month between @start and @end
group by
	request_month
	,drug_name
	,drug_custom_name
	,user_type
	,revenue_source -- for finding renewals
	,form_name
	,lob
	,pharma_state
	,rejection_code
	,pa_type
	,count_pa_tat_creation_outcome
	,count_pa_tat_submission_outcome
	,sum_appeal_tat_creation_outcome
  
  
-- External Reporting Summary (Dispense Data)

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

declare @start datetime set @start = dateadd(mm,datediff(mm,0,getdate())-13,0)
declare @end datetime set @end = dateadd(mm,datediff(mm,0,getdate())-1,0)

select 
	request_month
	,drug_name
	,rfa
	,rfa_dispensed
	,rfa_rejected
	,nrx_pharmacy
	,nrx_physician
	,billable_pharmacy
	,billable_physician
from pharma_mart.dbo.t_external_reporting_summary
where drug_name in ('Darzalex', 'Elmiron', 'Erleada', 'Invokana', 'Opsumit', 'Ponvory', 
					'Simponi', 'Spravato', 'Stelara', 'Symtuza', 'Tremfya', 'Uptravi', 'Xarelto')
and request_month between @start and @end
group by
	request_month
	,drug_name
	,rfa
	,rfa_dispensed
	,rfa_rejected
	,nrx_pharmacy
	,nrx_physician
	,billable_pharmacy
	,billable_physician
  
  
  -- External Reporting Volume
  
  SET NOCOUNT ON
SET ANSI_WARNINGS OFF

declare @start datetime set @start = dateadd(mm,datediff(mm,0,getdate())-13,0)
declare @end datetime set @end = dateadd(mm,datediff(mm,0,getdate())-1,0)

select
	request_month
	,drug_name
	,ICD
	,sum(pa_volume) as PA_Vol
from pharma_mart.dbo.t_external_reporting_volume
where drug_name = 'simponi'
and request_month between @start and @end
group by
	request_month
	,drug_name
	,ICD
  
  
  -- TAT + Denial Reason
  
  SET NOCOUNT ON
SET ANSI_WARNINGS OFF

declare @start datetime set @start = dateadd(mm,datediff(mm,0,getdate())-13,0)
declare @end datetime set @end = dateadd(mm,datediff(mm,0,getdate())-1,0)

select
	request_month
	,drug_name
	,tat_days_creation_outcome
	,tat_days_creation_submission
	,tat_days_submission_outcome
	,denial_reason
	,count(request_id_mask) as PA_Vol
from pharma_mart..vw_tableau_product_reporting
where drug_name in ('Darzalex SubQ', 'Elmiron', 'Erleada', 'Invokana', 'Opsumit', 'Ponvory', 
					'Simponi', 'Spravato', 'Stelara', 'Symtuza', 'Tremfya', 'Uptravi', 'Xarelto')
and request_month between @start and @end
group by
	request_month
	,drug_name
	,tat_days_creation_outcome
	,tat_days_creation_submission
	,tat_days_submission_outcome
	,denial_reason
