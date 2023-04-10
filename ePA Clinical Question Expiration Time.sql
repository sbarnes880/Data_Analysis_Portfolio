/*************************************************************************************************** 
**************************************************************************************************** 
TITLE:  ePA Clinical Question Expiration Time
AUTHOR:  sbarnes
DATE ADDED:  20230321
DESCRIPTION:  How long are ePA clinical question sets available before expiration?
	      This pulls the date & time that the questions were received, and the date & time that the questions expired (if they expired).
              Formula for calculating # of hours: =((Questions_Exp_Date + Questions_Exp_Time) - (Questions_Rec_Date + Questions_Rec_Time)) * 24
MODIFIED
User		Date		Reason
****************************************************************************************************
****************************************************************************************************/

select 
	month
	,cast(epa_ques_resp as date) as Questions_Rec_Date
	,cast(epa_ques_resp as time) as Questions_Rec_Time
	,cast(left(field_value,10) as date) as Questions_Exp_Date
	,cast(left(right(field_value,len(field_value)-CHARINDEX('t',field_value)),8) as time) as Questions_Exp_Time
	,count(distinct m.request_id) as PA_Vol
from plan_pbm..t_monthly_reporting_data m
join epamotron_repl..epa_reporting_fields e on m.request_id=e.request_id
where m.drug_name = '[brand name]'
  and month between '20211001' and '20221201'
  and field_name = 'deadline_for_reply'
  and field_value <> 'no value'
group by
	month
	,epa_ques_resp
	,field_value
