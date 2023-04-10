/*************************************************************************************************** 
**************************************************************************************************** 
TITLE:  Team Output Tableau Dashboard
AUTHOR:  sbarnes
DATE ADDED:  20220810
DESCRIPTION:  This code feeds our team's Output Dashboard in Tableau. This dashboard summarizes each team member's current workload. It lists the number of assigned
cases, each case's category, whether the case originated in Salesforce or Jira, and how long each case as been open for each employee.
The dashboard also shows trends in case volume, time committment, and label usage. We used this dashboard during weekly standups to evaluate everyone's bandwidth. It
was used on a daily basis by individuals to track progress and prioritize tasks.

MODIFIED
User		Date		Reason
****************************************************************************************************
****************************************************************************************************/

--Create a staging table and get your Salesforce data
    drop table if exists #output
        select
            cast('SalesForce' as varchar(20)) as datasource,
            c.casenumber,
            c.CreatedDate as created_date,
            c.lastmodifieddate as updated_date,
            c.closeddate as resolution_date,
            cast(case 
                when d.[Full Name] is not null then d.[Full Name] 
                when c.Case_Owner_Name__c = 'Pharma Analytics Queue' then null
                else c.Case_Owner_Name__c end as varchar(255)) as assignee,
            c.created_by__c as reporter,
            left(c.case_owner_email__c, charindex('@',c.case_owner_email__c)-1) as assignee_username,
            d.Supervisor as assignee_supervisor,
            c.Reason,
            cast(NULL as varchar(40)) as parent_status,
            c.Status,
            c.business_reason__c,
            c.description,
            c.subject,
            c.Days_Until_Due__c,
            c.Case_ID_18__c as hyperlink_ref,
            a.name as account_nam,
            cast(null as varchar(50)) as board_group,
            cast(null as varchar(20)) as pharma_team,
            cast(null as varchar(20)) as priority,
            cast(null as varchar(255)) as labels,
            cast(null as int) as story_points,
            cast(null as int) as project_id
        into #output
        from salesforce_repl.dbo.[Case] c
            left join salesforce_repl.dbo.Account a on c.AccountId = a.Account_ID_18__c
            left join pharma.dbo.directory_allcmm d on left(c.case_owner_email__c, charindex('@',c.case_owner_email__c)-1) = d.username
        where c.Type = 'Analytics'
            and c.vertical__c = 'Pharma'
            and c.CreatedDate >= '20210101'
            and c.reason <> 'Projections'
----Add in your JIRA data
    insert into #output
        select
            'JIRA' as datasource,
            i.issuenum,
            i.created,
            i.updated,
            i.resolutiondate,
            case when u2.[Full Name] is not null then u2.[Full Name] else u2.lower_user_name end as assignee,
            case when u1.[Full Name] is not null then u1.[Full Name] else u1.lower_user_name end as reporter,
            case when u2.[lower_user_name] is not null then u2.lower_user_name else i.assignee end as assignee_username,
            NULL as supervisor,
            NULL as reason,
            NULL as parent_status,
            s.pname as issue_status,
            NULL as business_reason,
            i.description,
            i.summary,
            NULL as days_until_due,
            p.pkey + '-' + cast(i.issuenum as varchar(10)) as hyperlink_ref,
            --NULL as case_id_18,
            NULL as pharma_account,
            case 
                when p.pname = 'Pharma/Upstream Analytics' then 'Upstream Analytics'
                else t.pharma_team end as board_group,
            NULL as pharma_team,
            i.priority,
            NULL as labels, 
            t2.story_points,
            p.id as project_id
        from jira_repl.dbo.jiraissue i
            join jira_repl.dbo.issuestatus s on i.issuestatus = s.id
            join jira_repl.dbo.project p on i.project = p.id
            left join   (select u.user_key, u.lower_user_name, d.[Full Name]
                        from jira_repl.dbo.app_user u
                            left join pharma.dbo.directory_allcmm d on u.lower_user_name = d.Username) u1 on i.reporter = u1.user_key
            left join   (select u.user_key, u.lower_user_name, d.[Full Name]
                        from jira_repl.dbo.app_user u
                            left join pharma.dbo.directory_allcmm d on u.lower_user_name = d.Username) u2 on i.assignee = u2.user_key
            left join (  select v.issue, cast(o.customvalue as varchar(50)) as pharma_team
                    from jira_repl.dbo.customfieldvalue v
                        join jira_repl.dbo.customfieldoption o on v.stringvalue = o.id
                    where v.customfield = 18652) t on i.id = t.issue
            left join (  select v.issue, v.numbervalue as story_points
                    from jira_repl.dbo.customfieldvalue v
                    where v.customfield = 10006) t2 on i.id = t2.issue
        where p.pname in (
            'Pharma Analytics',
            'Pharma/Upstream Analytics'
            )
            and created >= '20210101'
--Update your Pharma Team
    update o
        set pharma_team = case
        --First, assign based on board group (Jira grouping)
            when board_group = 'Data Ops Team' then 'Reporting Team'
            when board_group = 'Reporting Team' then 'Reporting Team'
            when board_group = 'SDP Team' then 'SDP Team'
            when board_group = 'Pharma Analytics - Human Supported PA' then 'Product Team'
            when board_group = 'Pharma Analytics - Self Service PA' then 'Product Team'
            when board_group = 'Upstream Analytics' then 'Product Team'
        --Second, assign based on supervior (SF grouping)
            when assignee_supervisor = 'Andrew Sims' or assignee = 'Andrew Sims' then 'Reporting Team'
            when assignee_supervisor = 'Alicia Croft' or assignee = 'Alicia Croft'then 'SDP Team'
            when assignee_supervisor = 'Patrick Tadolini' or assignee = 'Patrick Tadolini' then 'Product Team'
        --Third, queue defaults to Reporting Team
            when assignee in ('Pharma Analytics Queue', 'Pharma Analytics: NPI Overlap Queue') then 'Reporting Team'
        --Fourth, unknown/unassigned
            else 'Unassigned'
        end
    from #output o
--Get a list of your labels
    drop table if exists #labels_data
        select
            o.CaseNumber,
            p.id as project_id,
            l.label
        into #labels_data
        from #output o
            join jira_repl.dbo.jiraissue j on o.CaseNumber = j.issuenum and o.project_id = j.project
            join jira_repl.dbo.project p on j.project = p.id
            join jira_repl.dbo.label l on j.id = l.issue
        where datasource = 'JIRA'
            and p.pname in (
            'Pharma Analytics',
            'Pharma/Upstream Analytics'
            )
            
    drop table if exists #labels_output
        SELECT DISTINCT l2.project_id,l2.CaseNumber, 
            SUBSTRING(
                (
                    SELECT ','+l1.label  AS [text()]
                    FROM #labels_data l1
                    WHERE l1.CaseNumber = l2.CaseNumber
                        AND l1.project_id = l2.project_id
                    ORDER BY l1.CaseNumber
                    FOR XML PATH (''), TYPE
                ).value('text()[1]','nvarchar(max)'), 2, 1000) Label
        into #labels_output
        FROM #labels_data l2
    update o
        set labels = l.Label
    from #output o
        join #labels_output l on o.CaseNumber = l.CaseNumber
            and o.project_id = l.project_id
--Align your statuses 
    drop table if exists #status
        create table #status (
            current_status varchar(40),
            updated_status varchar(40),
            parent_status varchar(40)
            )
    insert into #status (current_status, updated_status, parent_status)
        values
            --Icebox
                ('Backlog',                     'Backlog',                  'Icebox'),
                ('Icebox',                      'Backlog',                  'Icebox'),
                ('New',                         'Backlog',                  'Icebox'),
                ('On Hold',                     'On Hold',                  'Icebox'),
            --Priority
                ('Escalated',                   'Priority',                 'Priority'),
                ('On Deck',                     'Priority',                 'Priority'), 
                ('Selected for Development',    'Priority',                 'Priority'), 
            --In Progress
                ('In Progress',                 'In Progress',              'In Progress'),
                ('Long Term Project',           'Long Term Project',        'In Progress'),
            --In Review
                ('Awaiting QA',                 'External Review',          'In Review'),
                ('Code Review',                 'Code Review',              'In Review'),
                ('External Review',             'External Review',          'In Review'),
                ('Internal Review',             'Internal Review',          'In Review'),
                ('Pending Approval',            'External Review',          'In Review'),
                ('Account Management',          'Account Management',       'In Review'),
                ('Tableau Review',              'Tableau Review',           'In Review'),
                ('Privacy Review',              'Tableau Review',           'In Review'),
            --Complete
                ('Approved',                    'Done',                     'Complete'),
                ('Cancelled',                   'Discard',                  'Complete'),
                ('Closed',                      'Done',                     'Complete'),
                ('Discard',                     'Discard',                  'Complete'),
                ('Done',                        'Done',                     'Complete')
                ;
        update o
            set status = s.updated_status,
                parent_status = s.parent_status
        from #output o
            join #status s on o.status = s.current_status
