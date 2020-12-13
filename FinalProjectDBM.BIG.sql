-- 1. Identifying which diseases have the highest Return Rate (might need to use diagnosis in future if not rn)
SELECT b.`Diagnosis Name` AS 'Name of Diagnosis', SUM(a.R30) AS 'Readmission Times in 30 days', SUM(a.R30)/COUNT(a.R30) AS 'Readmission Rate 30'
FROM fact_table a
JOIN dim_diagnosis b
	ON a.DiagnosisKey = b.DiagnosisKey 
WHERE b.`Diagnosis Name` IS NOT NULL
GROUP BY b.`Diagnosis Name`
ORDER BY SUM(a.R30)/COUNT(a.R30) DESC;

-- 2.
SELECT b.`Diagnosis Name` AS 'Name of Diagnosis', SUM(a.R60) AS 'Readmission Times in 60 days', SUM(a.R60)/COUNT(a.R60) AS 'Readmission Rate 60 Days', ROUND(AVG(b.NumberOfDaysStayed), 2) As 'Number of Days Stayed'
FROM fact_table a
JOIN dim_diagnosis b
	ON a.DiagnosisKey = b.DiagnosisKey 
WHERE b.`Diagnosis Name` IS NOT NULL
GROUP BY b.`Diagnosis Name`
ORDER BY SUM(a.R60)/COUNT(a.R60) DESC;

-- 3. Readmission Rate Over 60 Day Period, Grouped by Age 
SELECT c.`Age Group`, SUM(a.R30)/COUNT(a.R30) AS 'Readmission Rate 30 Days', SUM(a.R60)/COUNT(a.R60) AS 'Readmission Rate 60 Days', COUNT(c.`Age Group`) AS 'Population in Age Bin', AVG(b.NumberOfDaysStayed)
FROM fact_table a 
JOIN dim_diagnosis b
	ON b.DiagnosisKey = a.DiagnosisKey
JOIN dim_patient c
	ON a.PatientKey = c.PatientKey
GROUP BY c.`Age Group`
ORDER BY SUM(a.R30)/COUNT(a.R30) DESC;

-- 4. Readmission Rate and Morbidity Rate  
WITH c AS (
	SELECT PatientAge, PatientKey,
		CASE 
			WHEN LENGTH(Death) > 2 THEN 1
			WHEN LENGTH(Death) = 2 THEN 0
			ELSE NULL
        END AS 'Death_Bin'
	FROM dim_patient
	)
SELECT a.`Diagnosis Name`, ROUND(AVG(c.PatientAge),2) AS 'Average Patient Age', SUM(c.Death_Bin) AS 'Total Deaths',  COUNT(c.Death_Bin) AS 'Total Cases',AVG(c.Death_Bin) AS 'Morbidity Rate', SUM(b.R30)/COUNT(b.R30) AS 'Readmission Rate 30 Days', SUM(b.R60)/COUNT(b.R60) AS 'Readmission Rate 60 Days'
FROM c
JOIN fact_table AS b 
	ON c.PatientKey = b.PatientKey
JOIN dim_diagnosis AS a
	ON a.DiagnosisKey = b.DiagnosisKey
WHERE a.`Diagnosis Name` IS NOT NULL
GROUP BY a.`Diagnosis Name`
ORDER BY AVG(c.Death_Bin) DESC;


-- 5 Readmission Rate by Provider 
WITH a AS (
	SELECT a.PatientKey, a.R30, b.`Provider Name`, a.R60
	FROM fact_table a, dim_provider b
	WHERE a.ProviderKey = b.ProviderKey
    )
SELECT a.`Provider Name`, SUM(a.R30)/COUNT(a.R30) AS 'Readmission Rate 30 days', 
	SUM(a.R60)/COUNT(a.R60) AS 'Readmission Rate 60 days', ROUND(AVG(b.PatientAge),2) AS 'Average Age', 
	COUNT(a.PatientKey) AS 'Sample of Patients'
FROM a 
JOIN dim_patient as b
	ON a.PatientKey = b.PatientKey
GROUP BY a.`Provider Name`
HAVING COUNT(a.PatientKey) > 150
ORDER BY SUM(a.R30)/COUNT(a.R30) DESC;


-- 6. ESRD and AVG PCP Visits PRevious 6 Months -- R.30 and R.60
SELECT b.MDCRStatus as 'ESRD Status', SUM(a.PCPVisit)/COUNT(a.PCPVisit) AS 'Avg. PCP Visits Previous 6 Months', SUM(a.R30)/COUNT(a.R30) AS 'Readmission Rate 30 days', SUM(a.R60)/COUNT(a.R60) AS 'Readmission Rate 60 days'
FROM fact_table a
JOIN dim_patient b
	ON a.PatientKey = b.PatientKey
GROUP BY b.MDCRStatus;


-- 7. Regional Readmission
WITH b AS (
	SELECT PatientAge, PatientKey, `Total Population`,
		CASE 
			WHEN LENGTH(Death) > 2 THEN 1
			WHEN LENGTH(Death) = 2 THEN 0
        END AS 'Death_Bin'
	FROM dim_patient
    )
SELECT SUM(a.R30)/COUNT(a.R30) AS 'Readmission Rate 30 Days', SUM(a.R60)/COUNT(a.R60) AS 'Readmission Rate 60 Days', b.`Total Population`, SUM(a.PCPVisit)/COUNT(a.PCPVisit) AS 'Avg. PCP Visits Previous 6 Months', AVG(b.Death_Bin) AS 'Morbidity Rate'
FROM b
JOIN fact_table a
	ON a.PatientKey = b.PatientKey 
JOIN dim_location c
	ON a.LocationKey = c.LocationKey
WHERE b.`Total Population` IS NOT NULL
GROUP BY b.`Total Population`
ORDER BY SUM(a.R30)/COUNT(a.R30) DESC;


-- 8 Examining Benefits vs No Benefits Type and Its relationship to Hospital visits or meetings with PCP
WITH a AS (
	SELECT PatientAge, PatientKey,
		(CASE 
			WHEN LENGTH(Death) > 2 THEN 1
			WHEN LENGTH(Death) = 2 THEN 0
			ELSE NULL
        END) AS 'Death_Bin',
        (CASE 
			WHEN LENGTH(BenefitsType) > 0 THEN 1
			ELSE 0
        END) AS 'Benefit_Bin'
	FROM dim_patient
	)
SELECT  a.Benefit_Bin AS 'Benefits 1-Yes 0-No ', AVG(a.Death_Bin) AS 'Morbidity Rate', ROUND(AVG(a.PatientAge), 2) AS 'Average Patient Age', 
		SUM(b.PCPVisit)/COUNT(b.PCPVisit) AS 'Avg. PCP Visits Previous 6 Months'
FROM a
JOIN fact_table b
	ON b.PatientKey = a.PatientKey
JOIN dim_diagnosis c
	ON c.DiagnosisKey = b.DiagnosisKey
WHERE a.PatientAge BETWEEN 40 AND 60
GROUP BY a.Benefit_Bin;


-- 9 Diagnosis MDCR and Death Rate
WITH a AS (
	SELECT PatientAge, PatientKey, MDCRStatus,
		CASE 
			WHEN LENGTH(Death) > 2 THEN 1
			WHEN LENGTH(Death) = 2 THEN 0
			ELSE NULL
        END AS 'Death_Bin'
	FROM dim_patient
	)
SELECT a.MDCRStatus AS 'ESRD', SUM(a.Death_Bin)/COUNT(a.Death_Bin) AS 'Morbidity Rate'
FROM a
GROUP BY a.MDCRStatus
ORDER BY SUM(a.Death_Bin)/COUNT(a.Death_Bin) DESC;


-- 10 PCP, Disease
SELECT a.`Diagnosis Name`, SUM(b.PCPVisit)/COUNT(b.PCPVisit) AS 'Avg. PCP Visits Previous 6 Months', COUNT(b.PCPVisit) AS 'Total Claims for Provider'
FROM dim_diagnosis a, fact_table b
WHERE a.DiagnosisKey = b.DiagnosisKey AND `Diagnosis Name` IS NOT NULL
GROUP BY a.`Diagnosis Name`
ORDER BY SUM(b.PCPVisit)/COUNT(b.PCPVisit) DESC;

