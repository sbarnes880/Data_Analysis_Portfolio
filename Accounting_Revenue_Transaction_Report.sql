SELECT
	ISNULL(current_month.[CM Acct Ref No], prior_month.[PM Acct Ref No]) AS [Acct Ref No]
	,[CM Date of Trial Balance]
	,[PM Date of Trial Balance]
	,R.[Segment 2022]
	,R.[Sub Segment 2022]
	,R.[Open Scorecard]
	,current_month.[CM Participation Percent]
	,current_month.[CM Participation Start Date]
	,current_month.[On Book CM GL Interest Balance]
	,current_month.[On Book CM GL Fees Balance]
	,prior_month.[PM Participation Percent]
	,prior_month.[PM Participation Start Date]
	--Accounting NetSuite field called "Class"
	--Any participated loan is 39, any loan owned 100% by AOF is 30
	,CASE
		WHEN [Current Particpation Start Date] IS NOT NULL
		THEN 39
		ELSE 30
	END AS [CM NetSuite Class]
	,CASE
		WHEN [Current Particpation Start Date] IS NOT NULL
		THEN 39
		ELSE 30
	END AS [PM NetSuite Class]
	,prior_month.[On Book PM GL Interest Balance]
	,prior_month.[On Book PM GL Fees Balance]
	,ISNULL(current_month.[On Book CM GL Interest Balance], 0) - ISNULL(prior_month.[On Book PM GL Interest Balance], 0) AS [On Book GL Interest Accrual]
	,ISNULL(current_month.[On Book CM GL Fees Balance], 0) - ISNULL(prior_month.[On Book PM GL Fees Balance], 0) AS [On Book GL Fees Accrual]
FROM (
	SELECT 
		[Acct Ref No] AS [CM Acct Ref No]
		,[Date of Trial Balance] AS [CM Date of Trial Balance]
		,[Current Particpation Start Date] AS [CM Participation Start Date]
		,[Current Particpation Percent] AS [CM Participation Percent]
		,[GL  Outstanding $ Interest] AS [CM GL Interest Balance]
		,[GL  Outstanding $ Fees] + [GL  Outstanding $ Late Fees] AS [CM GL Fees Balance]
		,CASE
			WHEN [Current Particpation Percent] IS NOT NULL
			THEN ((100 - [Current Particpation Percent]) / 100.0) * [GL  Outstanding $ Interest]
			ELSE [GL  Outstanding $ Interest]
		END AS [On Book CM GL Interest Balance]	
		,[GL  Outstanding $ Fees] + [GL  Outstanding $ Late Fees] AS [On Book CM GL Fees Balance]
	FROM
		[DataMart].[dbo].[Loan Daily Trial Balance]
	WHERE
		[Date of Trial Balance] = <Parameters.Date Filter>
	) current_month
FULL OUTER JOIN (
	SELECT 
		[Acct Ref No] AS [PM Acct Ref No]
		,[Date of Trial Balance] AS [PM Date of Trial Balance]
		,[Current Particpation Start Date] AS [PM Participation Start Date]
		,[Current Particpation Percent] AS [PM Participation Percent]
		,[GL  Outstanding $ Interest] AS [PM GL Interest Balance]
		,[GL  Outstanding $ Fees] + [GL  Outstanding $ Late Fees] AS [PM GL Fees Balance]
		,CASE
			WHEN [Current Particpation Percent] IS NOT NULL
			THEN ((100 - [Current Particpation Percent]) / 100.0) * [GL  Outstanding $ Interest]
			ELSE [GL  Outstanding $ Interest]
		END AS [On Book PM GL Interest Balance]
		,[GL  Outstanding $ Fees] + [GL  Outstanding $ Late Fees] AS [On Book PM GL Fees Balance]
	FROM
		[DataMart].[dbo].[Loan Daily Trial Balance]
	WHERE
		[Date of Trial Balance] = EOMONTH(<Parameters.Date Filter>, -1)
	) prior_month
		ON current_month.[CM Acct Ref No] = prior_month.[PM Acct Ref No]
LEFT JOIN
	[DataMart].[dbo].[Loans - w Restructures] R
		ON ISNULL(current_month.[CM Acct Ref No], prior_month.[PM Acct Ref No]) = R.[Current Acct Ref No]
