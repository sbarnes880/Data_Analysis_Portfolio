/*************************************************************************************************** 
**************************************************************************************************** 
TITLE:  Generic Loan Info Query
AUTHOR:  sbarnes
DATE ADDED:  20240501
DESCRIPTION:  Here I am using CTEs and a series of left joins to gather a large amount of general information for small business loans given by
Accion Opportunity Fund to our customers. This query serves as a starting-point for pulling a variety of loan data. It's a good example of use of CTEs,
joins, subqueries, CASE statements, COALESCE statements, and some aggregations.

****************************************************************************************************
****************************************************************************************************/


WITH DPD_1 AS (
	SELECT
		LDTB.[Acct Ref No]
		,parent_loans.[First Acct Ref No]
		,SUM(
			CASE
				WHEN LDTB.[Eff Days Past Due] = 30 THEN 1
			ELSE 0
		END
		) AS [# Occurrences 30 DPD]
		,SUM(
			CASE
				WHEN LDTB.[Eff Days Past Due] = 60 THEN 1
			ELSE 0
		END
		) AS [# Occurrences 60 DPD]
	FROM
		[DataMart].[dbo].[Loan Daily Trial Balance] AS LDTB
	LEFT JOIN
		[DataMart].[dbo].[Loans - w Restructures] AS parent_loans
			ON LDTB.[Acct Ref No] = parent_loans.[Current Acct Ref No]
	WHERE
		LDTB.[Date of Trial Balance] >= '20140701'
	GROUP BY
		LDTB.[Acct Ref No]
		,parent_loans.[First Acct Ref No]
),

DPD AS (
	SELECT
		DPD_1.[First Acct Ref No] AS [Acct Ref No]
		,SUM([# Occurrences 30 DPD]) AS [# Occurrences 30 DPD]
		,SUM([# Occurrences 60 DPD]) AS [# Occurrences 60 DPD]
	FROM DPD_1
	GROUP BY
		DPD_1.[First Acct Ref No]
)

SELECT 
    L.[First Note Loan Open Date]
    ,L.[First Note Input GL Date]
    ,L.[First Note Loan Amount]
    ,L.[Segment 2022]
    ,L.[Sub Segment 2022]
    ,L.[ChargeOff Date]
    ,L.[ChargeOff Amount]
    ,L.[Current Loan Number]
    ,L.[First Acct Ref No]
    ,L.[Current Acct Ref No]
    ,L.[CIF No]
    ,par_loans.[Origination Fees]
	,CASE
		WHEN L.[Loan Status] = 'CLOSED'
			AND L.[ChargeOff Flag] = 'FALSE'
			AND (
				L.[Status Detail] NOT LIKE '%SETTLEMENT%'
				OR L.[Status Detail] IS NULL
			)
				THEN 1
		ELSE 0
	END AS [Payoff Indicator]
	,COALESCE(L.[ChargeOff Date], L.[Loan Closed Date]) AS [Derived Loan Closed Date]
	,LP.[Total Principal Paid]
    ,L.[Open Scorecard]
    ,C.[Business County - Current]
    ,C.[Business State - Current]
    ,C.[Business City - Current]
	,C.[Business Zip - Current]
    ,C.[Product Service Description - Current]
    ,COALESCE(
        CLO_FICO.[Fico_Score__c]
        ,L.[Old Loan Credit Score]
    ) AS [FICO/Credit Score]
	,CASE
		WHEN COALESCE(L.[Old Loan Credit Score], CLO_FICO.[Fico_Score__c]) = 0
			OR COALESCE(L.[Old Loan Credit Score], CLO_FICO.[Fico_Score__c]) IS NULL
			OR COALESCE(L.[Old Loan Credit Score], CLO_FICO.[Fico_Score__c]) = ''
		THEN '5: NO FICO'
		WHEN COALESCE(L.[Old Loan Credit Score], CLO_FICO.[Fico_Score__c]) <= 600
		THEN '1: <=600'
		WHEN COALESCE(L.[Old Loan Credit Score], CLO_FICO.[Fico_Score__c]) BETWEEN 601 AND 660
		THEN '2: 600-660'
		WHEN COALESCE(L.[Old Loan Credit Score], CLO_FICO.[Fico_Score__c]) BETWEEN 661 AND 720
		THEN '3: 661-720'
		WHEN COALESCE(L.[Old Loan Credit Score], CLO_FICO.[Fico_Score__c]) BETWEEN 721 AND 850
		THEN '4: 720+'
		ELSE '5: NO FICO'
	END AS [FICO Bucket]
    ,CASE 
        WHEN C.[Veteran Owned] = 1
            THEN 'Yes'
        WHEN C.[Veteran Owned] = 0
            THEN 'No'
        ELSE 'Unknown'
    END AS [Veteran Status]
    ,IM_1.[Ethnicity] AS [Race/Ethnicity]
    ,IM_1.[Gender]
    ,IM_1.[Income Level] AS [Borrower Income Level]
    ,IM.[Jobs Created]
    ,IM.[Jobs Retained]
    ,IM.[Full Time Employees]
    ,IM.[Part Time Employees]
    ,IM.[Number of Employees]
    ,NLS_Demo.[userdef20] AS [LGBTQ+]
	 ,CASE
        WHEN [Current Loan Number] LIKE 'APP-%' THEN Acct.[Previous_Year_Gross_Annual_Sale_Verified__c]
        ELSE L.[Avg Monthly Revenue] * 12
    END AS [Annual Revenue]
    ,COALESCE(
        (Acct.[Previous_Year_Gross_Annual_Sale_Verified__c] / 12)
        ,L.[Avg Monthly Revenue]
    ) AS [Avg Monthly Revenue]
    ,COALESCE(
        Acct.[AGI__c]
        ,TRY_CONVERT(int, L.[AGI Loan])
        ,OMD.[Borrower AGI]
    ) AS [AGI]
    ,COALESCE(
        CLO_Contact.[Number_of_People_in_Household__c]
        ,L.[People In Home]
        ,OMD.[# of People in Household]
    ) AS [# of People in Household]
    ,LEFT(
        COALESCE(
            CLO_NAICS.[Name] 
            ,C.[NAICS Code - Current]
        )
        ,4
    ) AS [NAICS-4 Code]
    ,naics4_desc.[naics17_desc] AS [NAICS-4 Description]
	,COALESCE(
        CLO_NAICS.[Name] 
        ,C.[NAICS Code - Current]
    ) AS [NAICS-6 Code]
    ,naics6_desc.[naics17_desc] AS [NAICS-6 Description]
	,CASE
		WHEN
			(TRIM(UPPER(L.[Loss Reserve Program])) NOT IN ('NOT ELIGIBLE', 'DENIED')
					OR TRIM(UPPER(L.[Loss Reserve Program])) IS NOT NULL
			)
			AND 
				L.[Cal Cap num] NOT IN ('NOT ELIGIBLE', 'NOT ELIGIBILE', 'NOT EIGIBLE', 'NOT ELLIGIBLE', 'UNKNOWN', ' UNKNOWN', 'NOT ENROLLED', 'UNENROLLED', 'CLIENT PAID', 'NOT ENROLLED DUE TO ALEKS ERROR', 'REJECTED', 'WITHDRAWN', 'N/A')
				OR L.[Cal Cap num] IS NULL
		THEN L.[Loss Reserve Program]
	 END AS [Loss Reserve Program]
    ,L.[Cal Cap Num]
    ,par_loans.[First Interest Rate]
    ,par_loans.[First Loan Term]
    ,par_loans.[Current Maturity Date] AS [Maturity Date]
	,DPD.[# Occurrences 30 DPD]
	,DPD.[# Occurrences 60 DPD]
FROM
    [DataMart].[dbo].[Loans] AS L
LEFT JOIN (
    SELECT 
        [First Acct Ref No]
        ,[Current Interest Rate] AS [First Interest Rate]
        ,CASE
            WHEN [Term Type] = 'DAYS' THEN ROUND(CAST(SUBSTRING([Term], 1, CHARINDEX('/', [Term]) - 1) AS INT) / 30.5, 0)
            ELSE CAST(SUBSTRING([Term], 1, CHARINDEX('/', [Term]) - 1) AS INT)
            END
        AS [First Loan Term] 
        ,[Loan Fees Code 600] AS [Origination Fees]
        ,[Current Maturity Date]
    FROM 
        DataMart.dbo.[Loans - w Restructures]
    WHERE 
        [First Acct Ref No] = [Current Acct Ref No]
) AS par_loans
    ON L.[First Acct Ref No] = par_loans.[First Acct Ref No]
LEFT JOIN 
    [DataMart].[dbo].[Contacts] AS C
    ON L.[CIF No] = C.[cifno]
LEFT JOIN
    [CDATA].[SF-CLS-Prod].[genesis__Applications__c] AS Apps
    ON L.[Current Loan Number] = Apps.[Name]
LEFT JOIN
    [CDATA].[SF-CLS-Prod].[Account] AS Acct
    ON Apps.[genesis__Account__c] = Acct.[Id]
LEFT JOIN
    [DataMapping].[dbo].[clcommon__Industry_Classification_Code__c] AS CLO_NAICS
    ON Acct.[clcommon__Industry_Classification_Code__c] = CLO_NAICS.[Id]
LEFT JOIN 
    DataMapping.dbo.NAICS_Descriptions AS naics6_desc
    ON COALESCE(CLO_NAICS.[Name], C.[NAICS Code - Current]) = naics6_desc.[naics17_code]
LEFT JOIN 
    DataMapping.dbo.NAICS_Descriptions AS naics4_desc
    ON LEFT(COALESCE(CLO_NAICS.[Name], C.[NAICS Code - Current]), 4) = naics4_desc.[naics17_code]
LEFT JOIN (
	SELECT
		[AccountId],
		MAX([Number_of_People_in_Household__c]) AS [Number_of_People_in_Household__c],
		MIN([CreatedDate]) AS [Min CreatedDate]
	FROM
		[CDATA].[SF-CLS-Prod].[Contact]
	GROUP BY
		[AccountId]
) AS CLO_Contact
    ON Apps.[merchant_account__c] = CLO_Contact.[Accountid]
LEFT JOIN (
	SELECT
		[Acct Ref No]
		,SUM([Payment Amount]) AS [Total Principal Paid]
	FROM
		[DataMart].[dbo].[Loan Payments]
	WHERE
		[NSF Flag] = 0
		AND [Payment Description] IN (
			'P+I Principal Payment'
			,'Principal Payment'
			,'Principal Balloon Payment'
			,'Principal Reduction'
		)
	GROUP BY
		[Acct Ref No]
) AS LP
	ON L.[Current Acct Ref No] = LP.[Acct Ref No]
LEFT JOIN
    [CDATA].[SF-CLS-Prod].[Experian_Credit_Report__c] AS CLO_FICO
    ON Apps.[Hard_Pull_Experian_Report__c] = CLO_FICO.[Id]
LEFT JOIN (
    SELECT
            *
    FROM
        [DataMapping].[dbo].[Impact Metric with AutoIncome]
    WHERE
        [Recent Account] = 1
) AS IM
    ON L.[CIF No] = IM.[Cif No]
LEFT JOIN (
    SELECT 
        [Acct Ref No],
        [Cif No] AS [CIF No (IM_1)],
        [Ethnicity - Composite] AS [Ethnicity],
        [Gender - Composite] AS [Gender],
        [Borrower Income Level - Composite] AS [Income Level]
    FROM 
        [DataMapping].[dbo].[ImpactMetricWithAutoIncome_FutureState]
) AS [IM_1] 
    ON ([L].[First Acct Ref No] = [IM_1].[Acct Ref No])
LEFT JOIN
    [DataMapping].[dbo].[Ops Missing Data] AS OMD
    ON L.[Current Loan Number] = OMD.[Loan Number]
LEFT JOIN
    [NLS].[dbo].[cif_demographics] AS NLS_Demo
    ON L.[CIF No] = NLS_Demo.[cifno]
LEFT JOIN 
	DPD
		ON L.[First Acct Ref No] = DPD.[Acct Ref No]
