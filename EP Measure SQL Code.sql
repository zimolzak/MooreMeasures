-- Title: Emergency Cancer Diagnosis eMeasure
-- Author: Paarth Kapadia
-- Up To Date: 02/2023

USE ORD_Singh_202001030D
--USE ORD_Khalaf_201811041D
GO

-- PARAMETER TABLE ================================================================================

-- Declare Parameter Variables
DECLARE @Search_Start DATETIME2
DECLARE @Search_Length_Months INT
DECLARE @Exclude_Length_Years INT
DECLARE @Lookback_Length_Days INT
DECLARE @CareHx_Length_Months INT

-- Set Parameter Variables
SET @Search_Start = '2016-01-01'
SET @Search_Length_Months = 60
SET @Exclude_Length_Years = -50
SET @Lookback_Length_Days = -30
SET @CareHx_Length_Months = 24

-- Create Parameter Table
IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_ParameterTable') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_ParameterTable
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_ParameterTable
(
	Search_Start DATETIME2
	,Search_Length_Months INT
	,Exclude_Length_Years INT
	,Lookback_Length_Days INT
	,CareHx_Length_Months INT
)

-- Insert Variables into Parameter Table
INSERT INTO Dflt._ppkt_CaP_2016to2020_ParameterTable
(
	Search_Start
	,Search_Length_Months
	,Exclude_Length_Years
	,Lookback_Length_Days
	,CareHx_Length_Months
)
VALUES
(
	@Search_Start
	,@Search_Length_Months
	,@Exclude_Length_Years
	,@Lookback_Length_Days
	,@CareHx_Length_Months
)
GO




-- PLANNED HOSPITALIZATION ICD-10-CM + ICD-10-PCS CODES TABLES ====================================

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_SETUP_PlannedHospitalization_ICD10CMCodes') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_SETUP_PlannedHospitalization_ICD10CMCodes
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_SETUP_PlannedHospitalization_ICD10CMCodes
(
	ICD10CMCode VARCHAR(50)
)

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_SETUP_PlannedHospitalization_ICD10PCSCodes') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_SETUP_PlannedHospitalization_ICD10PCSCodes
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_SETUP_PlannedHospitalization_ICD10PCSCodes
(
	ICD10PCSCode VARCHAR(50)
)

-- Compile codes
INSERT INTO Dflt._ppkt_CaP_2016to2020_SETUP_PlannedHospitalization_ICD10CMCodes
SELECT ex.[ICD-10-CM Code]
FROM Dflt._ppku_EncounterTypeICD_T1_Plan_T1_AlwaysPlannedConditions AS ex


INSERT INTO Dflt._ppkt_CaP_2016to2020_SETUP_PlannedHospitalization_ICD10PCSCodes
SELECT ex.[ICD-10-PCS CODE]
FROM Dflt._ppku_EncounterTypeICD_T1_Plan_T1_AlwaysPlannedProcedures AS ex

INSERT INTO Dflt._ppkt_CaP_2016to2020_SETUP_PlannedHospitalization_ICD10PCSCodes
SELECT ex.[ICD-10-PCS CODE]
FROM Dflt._ppku_EncounterTypeICD_T1_Plan_T1_SometimesPlannedProcedures AS ex

GO




-- ************************************************************************************************
-- INCLUSION
-- ************************************************************************************************

-- I.01.A ---------------------------------------------------------------------------------------- 

-- Set the search period
DECLARE @STEP01_SearchStart DATETIME2
DECLARE @STEP01_SearchEnd DATETIME2

SET @STEP01_SearchStart = (SELECT params.Search_Start FROM Dflt._ppkt_CaP_2016to2020_ParameterTable AS params)
SET @STEP01_SearchEnd = DATEADD(MONTH, (SELECT params.Search_Length_Months FROM Dflt._ppkt_CaP_2016to2020_ParameterTable AS params), (SELECT params.Search_Start FROM Dflt._ppkt_CaP_2016to2020_ParameterTable AS params))

PRINT CHAR(13) + CHAR(10) + 'Step 01 - Search Period Start: ' + CAST(@STEP01_SearchStart AS VARCHAR)
PRINT 'Step 01 - Search Period End: ' + CAST(@STEP01_SearchEnd AS VARCHAR)

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP01_Z') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP01_Z
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP01_Z
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer VARCHAR(100)
	,TypeOfEvent VARCHAR(50)
)

-- Get outpatient encounters with a diagnostic code associated with the cancer of study
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP01_Z
SELECT DISTINCT
	sp.PatientSSN
	,owl.PatientSID
	,owl.VisitSID
	,owl.VisitDateTime
	,'ZZZ NOT CAPTURED'
	,'ZZZ NOT CAPTURED'
	,'OUTPATIENT ENCOUNTER'
FROM 
	Src.Outpat_Workload AS owl INNER JOIN Src.Outpat_WorkloadVDiagnosis AS owld ON
	(
		owl.VisitSID = owld.VisitSID
	)
		INNER JOIN Src.SPatient_SPatient AS sp ON
		(	
			owl.PatientSID = sp.PatientSID
		)
			LEFT JOIN CDWWork.Dim.ICD10 AS icd10 ON
			(
				owld.ICD10SID = icd10.ICD10SID
			)
				LEFT JOIN CDWWork.Dim.ICD9 AS icd9 ON
				(
					owld.ICD9SID = icd9.ICD9SID
				)
-- <<<<!CANCER SELECTION ZONE START!>>>>
WHERE											
	(
		(
			--icd10.ICD10Code LIKE '%C18%' OR icd10.ICD10Code LIKE '%C19%' OR icd10.ICD10Code LIKE '%C20%'	-- COLORECTAL CANCER
			--OR
			--icd10.ICD10Code LIKE '%C34%'		-- LUNG CANCER
			--OR
			icd10.ICD10Code LIKE '%C61%'		-- PROSTATE CANCER
			--OR
			--icd10.ICD10Code LIKE '%C25%'		-- PANCREATIC CANCER
		)
		OR
		(
			--icd9.ICD9Code LIKE '153%' OR icd9.ICD9Code LIKE '154.0%' OR icd9.ICD9Code LIKE '154.1%'		-- COLORECTAL CANCER
			--OR
			--icd9.ICD9Code LIKE '162%'			-- LUNG CANCER
			--OR
			icd9.ICD9Code LIKE '185%'			-- PROSTATE CANCER
			--OR
			--icd9.ICD9Code LIKE '185%'			-- PANCREATIC CANCER
		)
	)
	AND
	owl.VisitDateTime BETWEEN
		@STEP01_SearchStart
		AND
		@STEP01_SearchEnd

-- Get inpatient encounters with a diagnostic code associated with the cancer of study
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP01_Z
SELECT DISTINCT
	sp.PatientSSN	
	,inp.PatientSID
	,inp.InpatientSID
	,inp.AdmitDateTime
	,'ZZZ NOT CAPTURED'
	,'ZZZ NOT CAPTURED'
	,'INPATIENT ENCOUNTER'
FROM 
	Src.Inpat_Inpatient AS inp INNER JOIN Src.Inpat_InpatientDiagnosis AS inpd ON
	(
		inp.InpatientSID = inpd.InpatientSID
	)
		INNER JOIN Src.SPatient_SPatient AS sp ON
		(	
			inp.PatientSID = sp.PatientSID
		)
			LEFT JOIN CDWWork.Dim.ICD10 AS icd10 ON
			(
				inpd.ICD10SID = icd10.ICD10SID
			)
				LEFT JOIN CDWWork.Dim.ICD9 AS icd9 ON
				(
					inpd.ICD9SID = icd9.ICD9SID
				)
WHERE
	(
		(
			--icd10.ICD10Code LIKE '%C18%' OR icd10.ICD10Code LIKE '%C19%' OR icd10.ICD10Code LIKE '%C20%'		-- COLORECTAL CANCER
			--OR
			--icd10.ICD10Code LIKE '%C34%'		-- LUNG CANCER
			--OR
			icd10.ICD10Code LIKE '%C61%'		-- PROSTATE CANCER
			--OR
			--icd10.ICD10Code LIKE '%C25%'		-- PANCREATIC CANCER
		)
		OR
		(
			--icd9.ICD9Code LIKE '153%' OR icd9.ICD9Code LIKE '154.0%' OR icd9.ICD9Code LIKE '154.1%'		-- COLORECTAL CANCER
			--OR
			--icd9.ICD9Code LIKE '162%'			-- LUNG CANCER
			--OR
			icd9.ICD9Code LIKE '185%'			-- PROSTATE CANCER
			--OR
			--icd9.ICD9Code LIKE '185%'			-- PANCREATIC CANCER
		)
	)
	AND
	inp.AdmitDateTime BETWEEN
		@STEP01_SearchStart
		AND
		@STEP01_SearchEnd

-- Get cancer registry entries associated with the cancer of study
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP01_Z
SELECT DISTINCT
	sp.PatientSSN
	,reg.PatientSID
	,reg.OncologyPrimaryIEN
	,reg.DateDX
	,CONCAT(reg.Histologyicdo3X, ' OF THE ', reg.ICDOSite)
	,reg.StageGroupingajcc
	,'REGISTRY ENTRY'
FROM 
	Src.Oncology_Oncology_Primary_165_5 AS reg INNER JOIN Src.SPatient_SPatient AS sp ON
	(	
		reg.PatientSID = sp.PatientSID
	)
WHERE
	reg.DateDX BETWEEN 
		@STEP01_SearchStart
		AND
		@STEP01_SearchEnd
	AND
	(
		--(reg.SitegpX LIKE 'COLO%' OR reg.ICDOSite LIKE 'COLO%' OR reg.PrimarysiteX LIKE 'COLO%') OR (reg.SitegpX LIKE 'RECT%' OR reg.ICDOSite LIKE 'RECT%' OR reg.PrimarysiteX LIKE 'RECT%')
		--OR
		--(reg.SitegpX LIKE 'LUNG%' OR reg.ICDOSite LIKE 'LUNG%' OR reg.PrimarysiteX LIKE 'LUNG%')
		--OR
		(reg.SitegpX LIKE 'PROSTAT%' OR reg.ICDOSite LIKE 'PROSTAT%' OR reg.PrimarysiteX LIKE 'PROSTAT%')
		--OR
		--(reg.SitegpX LIKE 'PANCREA%' OR reg.ICDOSite LIKE 'PANCREA%' OR reg.PrimarysiteX LIKE 'PANCREA%')
	)
GO




-- I.02.A ---------------------------------------------------------------------------------------- 

-- Set the exclusion period 
DECLARE @STEP02_ExcludeStart DATETIME2
DECLARE @STEP02_ExcludeEnd DATETIME2

SET @STEP02_ExcludeStart = DATEADD(YEAR, (SELECT params.Exclude_Length_Years FROM Dflt._ppkt_CaP_2016to2020_ParameterTable AS params), (SELECT params.Search_Start FROM Dflt._ppkt_CaP_2016to2020_ParameterTable AS params))
SET @STEP02_ExcludeEnd = (SELECT params.Search_Start FROM Dflt._ppkt_CaP_2016to2020_ParameterTable AS params)

PRINT CHAR(13) + CHAR(10) + 'Step 02 - Exclusion Period Start: ' + CAST(@STEP02_ExcludeStart AS VARCHAR)
PRINT 'Step 02 - Exclusion Period End: ' + CAST(@STEP02_ExcludeEnd AS VARCHAR)

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP02_Z') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP02_Z
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP02_Z
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,TypeOfEvent VARCHAR(50)
)

-- Get outpatient encounters with a diagnostic code associated with the cancer of study
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP02_Z
SELECT DISTINCT
	sp.PatientSSN
	,owl.PatientSID
	,owl.VisitSID
	,owl.VisitDateTime
	,'OUTPATIENT ENCOUNTER'
FROM 
	Src.Outpat_Workload AS owl INNER JOIN Src.Outpat_WorkloadVDiagnosis AS owld ON
	(
		owl.VisitSID = owld.VisitSID
	)
		INNER JOIN Src.SPatient_SPatient AS sp ON
		(	
			owl.PatientSID = sp.PatientSID
		)
			LEFT JOIN CDWWork.Dim.ICD10 AS icd10 ON
			(
				owld.ICD10SID = icd10.ICD10SID
			)
				LEFT JOIN CDWWork.Dim.ICD9 AS icd9 ON
				(
					owld.ICD9SID = icd9.ICD9SID
				)
WHERE
	(
		(
			--icd10.ICD10Code LIKE '%C18%' OR icd10.ICD10Code LIKE '%C19%' OR icd10.ICD10Code LIKE '%C20%'		-- COLORECTAL CANCER
			--OR
			--icd10.ICD10Code LIKE '%C34%'		-- LUNG CANCER
			--OR
			icd10.ICD10Code LIKE '%C61%'		-- PROSTATE CANCER
			--OR
			--icd10.ICD10Code LIKE '%C25%'		-- PANCREATIC CANCER
		)
		OR
		(
			--icd9.ICD9Code LIKE '153%' OR icd9.ICD9Code LIKE '154.0%' OR icd9.ICD9Code LIKE '154.1%'		-- COLORECTAL CANCER
			--OR
			--icd9.ICD9Code LIKE '162%'			-- LUNG CANCER
			--OR
			icd9.ICD9Code LIKE '185%'			-- PROSTATE CANCER
			--OR
			--icd9.ICD9Code LIKE '185%'			-- PANCREATIC CANCER
		)
	)
	AND
	owl.VisitDateTime BETWEEN
		@STEP02_ExcludeStart
		AND
		@STEP02_ExcludeEnd
	AND
	owl.PatientSID IN
	(
		select t.PatientSID
		FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP01_Z AS t
	)

-- Get inpatient encounters with a diagnostic code associated with the cancer of study
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP02_Z
SELECT DISTINCT
	sp.PatientSSN	
	,inp.PatientSID
	,inp.InpatientSID
	,inp.AdmitDateTime
	,'INPATIENT ENCOUNTER'
FROM 
	Src.Inpat_Inpatient AS inp INNER JOIN Src.Inpat_InpatientDiagnosis AS inpd ON
	(
		inp.InpatientSID = inpd.InpatientSID
	)
		INNER JOIN Src.SPatient_SPatient AS sp ON
		(	
			inp.PatientSID = sp.PatientSID
		)
			LEFT JOIN CDWWork.Dim.ICD10 AS icd10 ON
			(
				inpd.ICD10SID = icd10.ICD10SID
			)
				LEFT JOIN CDWWork.Dim.ICD9 AS icd9 ON
				(
					inpd.ICD9SID = icd9.ICD9SID
				)
WHERE
	(
		(
			--icd10.ICD10Code LIKE '%C18%' OR icd10.ICD10Code LIKE '%C19%' OR icd10.ICD10Code LIKE '%C20%'		-- COLORECTAL CANCER
			--OR
			--icd10.ICD10Code LIKE '%C34%'		-- LUNG CANCER
			--OR
			icd10.ICD10Code LIKE '%C61%'		-- PROSTATE CANCER
			--OR
			--icd10.ICD10Code LIKE '%C25%'		-- PANCREATIC CANCER
		)
		OR
		(
			--icd9.ICD9Code LIKE '153%' OR icd9.ICD9Code LIKE '154.0%' OR icd9.ICD9Code LIKE '154.1%'		-- COLORECTAL CANCER
			--OR
			--icd9.ICD9Code LIKE '162%'			-- LUNG CANCER
			--OR
			icd9.ICD9Code LIKE '185%'			-- PROSTATE CANCER
			--OR
			--icd9.ICD9Code LIKE '185%'			-- PANCREATIC CANCER
		)
	)
	AND
	inp.AdmitDateTime BETWEEN
		@STEP02_ExcludeStart
		AND
		@STEP02_ExcludeEnd
	AND
	inp.PatientSID IN
	(
		select t.PatientSID
		FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP01_Z AS t
	)

-- Get cancer registry entries with the cancer of study
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP02_Z
SELECT DISTINCT
	sp.PatientSSN
	,reg.PatientSID
	,reg.OncologyPrimaryIEN
	,reg.DateDX
	,'REGISTRY ENTRY'
FROM 
	Src.Oncology_Oncology_Primary_165_5 AS reg INNER JOIN Src.SPatient_SPatient AS sp ON
	(	
		reg.PatientSID = sp.PatientSID
	)
WHERE
	reg.DateDX BETWEEN 
		@STEP02_ExcludeStart
		AND
		@STEP02_ExcludeEnd
	AND
	(
		--(reg.SitegpX LIKE 'COLO%' OR reg.ICDOSite LIKE 'COLO%' OR reg.PrimarysiteX LIKE 'COLO%') OR (reg.SitegpX LIKE 'RECT%' OR reg.ICDOSite LIKE 'RECT%' OR reg.PrimarysiteX LIKE 'RECT%')
		--OR
		--(reg.SitegpX LIKE 'LUNG%' OR reg.ICDOSite LIKE 'LUNG%' OR reg.PrimarysiteX LIKE 'LUNG%')
		--OR
		(reg.SitegpX LIKE 'PROSTAT%' OR reg.ICDOSite LIKE 'PROSTAT%' OR reg.PrimarysiteX LIKE 'PROSTAT%')
		--OR
		--(reg.SitegpX LIKE 'PANCREA%' OR reg.ICDOSite LIKE 'PANCREA%' OR reg.PrimarysiteX LIKE 'PANCREA%')
	)
	AND
	reg.PatientSID IN
	(
		select t.PatientSID
		FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP01_Z AS t
	)
-- <<<<!CANCER SELECTION ZONE END!>>>>
GO




-- I.03.A ----------------------------------------------------------------------------------------

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP03_A') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP03_A
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP03_A
(
	PatientSSN VARCHAR(10)
)

-- Get SSNs of patients in the search period that had cancer records in the exclusion period
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP03_A
SELECT DISTINCT srch.PatientSSN
FROM
	Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP01_Z AS srch INNER JOIN Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP02_Z AS exc ON
	(
		srch.PatientSSN = exc.PatientSSN
	)




-- I.03.B ---------------------------------------------------------------------------------------- 

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP03_Z') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP03_Z
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP03_Z
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer VARCHAR(100)
	,TypeOfEvent VARCHAR(50)
)


/* Get cancer records from search period that don't belong to the list
of patients identified in iSTEP 03 PART A */
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP03_Z
SELECT DISTINCT
	srch.PatientSSN
	,srch.PatientSID
	,srch.DiagnosisEventSID
	,srch.DiagnosisEventDateTime
	,srch.HistologyOfCancer
	,srch.StageOfCancer
	,srch.TypeOfEvent
FROM
	Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP01_Z AS srch
WHERE
	srch.PatientSSN NOT IN
	(
		SELECT t.PatientSSN
		FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP03_A AS t
	)

GO




-- I.04.A ---------------------------------------------------------------------------------------- 

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_A') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_A
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_A
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer VARCHAR(100)
	,TypeOfEvent VARCHAR(50)
)

-- Get all registry diagnosis events from iSTEP 03 PART Z
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_A
SELECT DISTINCT
	dx.PatientSSN
	,dx.PatientSID
	,dx.DiagnosisEventSID
	,dx.DiagnosisEventDateTime
	,dx.HistologyOfCancer
	,dx.StageOfCancer
	,dx.TypeOfEvent
FROM
	Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP03_Z AS dx
WHERE dx.TypeOfEvent = 'REGISTRY ENTRY'




-- I.04.B ----------------------------------------------------------------------------------------

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_B') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_B
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_B
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer VARCHAR(100)
	,TypeOfEvent VARCHAR(50)
)

/* Get all first-time ICD occurence diagnosis events from iSTEP 03
PART Z for patients not in iSTEP 04 PART A */
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_B
SELECT DISTINCT
	dx.PatientSSN
	,dx.PatientSID
	,dx.DiagnosisEventSID
	,dx.DiagnosisEventDateTime
	,dx.HistologyOfCancer
	,dx.StageOfCancer
	,dx.TypeOfEvent
FROM
	Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP03_Z AS dx
WHERE
	dx.PatientSSN NOT IN
	(
		SELECT t.PatientSSN
		FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_A AS t
	)




-- I.04.C ----------------------------------------------------------------------------------------

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_Z') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_Z
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_Z
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer VARCHAR(100)
	,TypeOfEvent VARCHAR(50)
)

-- For each patient, get the earliest diagnosis event from STEP 04 PART A
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_Z
SELECT DISTINCT
	reg_dx.PatientSSN
	,reg_dx.PatientSID
	,reg_dx.DiagnosisEventSID
	,reg_dx.DiagnosisEventDateTime
	,reg_dx.HistologyOfCancer
	,reg_dx.StageOfCancer
	,reg_dx.TypeOfEvent
FROM
	Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_A AS reg_dx
WHERE
	reg_dx.DiagnosisEventDateTime = 
	(
		SELECT TOP 1 t.DiagnosisEventDateTime
		FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_A AS t
		WHERE reg_dx.PatientSSN = t.PatientSSN
		ORDER BY t.DiagnosisEventDateTime ASC
	)

-- For each patient, get the earliest diagnosis event from STEP 04 PART B
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_Z
SELECT DISTINCT
	icd_dx.PatientSSN
	,icd_dx.PatientSID
	,icd_dx.DiagnosisEventSID
	,icd_dx.DiagnosisEventDateTime
	,icd_dx.HistologyOfCancer
	,icd_dx.StageOfCancer
	,icd_dx.TypeOfEvent
FROM
	Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_B AS icd_dx
WHERE
	icd_dx.DiagnosisEventDateTime = 
	(
		SELECT TOP 1 t.DiagnosisEventDateTime
		FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_B AS t
		WHERE icd_dx.PatientSSN = t.PatientSSN
		ORDER BY t.DiagnosisEventDateTime ASC
	)

GO




-- I.05.A ----------------------------------------------------------------------------------------

-- Set the emergency care (EC) search period 
DECLARE @STEP05_SearchStart DATETIME2
DECLARE @STEP05_SearchEnd DATETIME2

SET @STEP05_SearchStart = DATEADD(DAY, (SELECT params.Lookback_Length_Days FROM Dflt._ppkt_CaP_2016to2020_ParameterTable AS params), (SELECT params.Search_Start FROM Dflt._ppkt_CaP_2016to2020_ParameterTable AS params))
SET @STEP05_SearchEnd = DATEADD(MONTH, (SELECT params.Search_Length_Months FROM Dflt._ppkt_CaP_2016to2020_ParameterTable AS params), (SELECT params.Search_Start FROM Dflt._ppkt_CaP_2016to2020_ParameterTable AS params))

PRINT CHAR(13) + CHAR(10) + 'Step 05 - Emergency Care Search Period Start: ' + CAST(@STEP05_SearchStart AS VARCHAR)
PRINT 'Step 05 - Emergency Care Search Period End: ' + CAST(@STEP05_SearchEnd AS VARCHAR)

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_A') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_A
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_A
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,ECEventSID BIGINT
	,ECEventDateTime DATETIME2
	,TypeOfEvent VARCHAR(50)
)

-- Get all inpatient visits that fall under the Emergency Care (EC) search period
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_A
SELECT DISTINCT
	sp.PatientSSN
	,inp.PatientSID
	,inp.InpatientSID
	,inp.AdmitDateTime
	,'Hospitalization'
FROM
	Src.Inpat_Inpatient AS inp INNER JOIN Src.SPatient_SPatient AS sp ON
	(
		inp.PatientSID = sp.PatientSID
	)
WHERE
	inp.AdmitDateTime BETWEEN
		@STEP05_SearchStart
		AND
		@STEP05_SearchEnd
	AND
	sp.PatientSSN IN
	(
		SELECT t.PatientSSN
		FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_Z AS t
	)




-- I.05.B ----------------------------------------------------------------------------------------

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_B') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_B
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_B
(
	PatientSSN VARCHAR(10)
	,ECEventSID BIGINT
)

-- Select all Emergency Care events with a ICD-10-CM code implying planned admission
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_B
SELECT DISTINCT
	ec.PatientSSN
	,ec.ECEventSID
FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_A AS ec INNER JOIN Src.Inpat_InpatientDiagnosis AS inpd ON 
	(
		ec.ECEventSID = inpd.InpatientSID
	)
		INNER JOIN CDWWork.Dim.ICD10 AS icd10 ON
		(
			inpd.ICD10SID = icd10.ICD10SID
		)
WHERE
	REPLACE(icd10.ICD10Code, '.', '') IN 
		(
			SELECT t.ICD10CMCode
			FROM Dflt._ppkt_CaP_2016to2020_SETUP_PlannedHospitalization_ICD10CMCodes AS t
		)

-- Select all Emergency Care events with a ICD-10-PCS code implying planned admission
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_B
SELECT DISTINCT
	ec.PatientSSN
	,ec.ECEventSID
FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_A AS ec INNER JOIN Src.Inpat_InpatientICDProcedure AS inpip ON 
	(
		ec.ECEventSID = inpip.InpatientSID
	)
		INNER JOIN CDWWork.Dim.ICD10Procedure AS icd10p ON
		(
			inpip.ICD10ProcedureSID = icd10p.ICD10ProcedureSID
		)
WHERE
	REPLACE(icd10p.ICD10ProcedureCode, '.', '') IN 
		(
			SELECT t.ICD10PCSCode
			FROM Dflt._ppkt_CaP_2016to2020_SETUP_PlannedHospitalization_ICD10PCSCodes AS t
		)




-- I.05.C ----------------------------------------------------------------------------------------

-- Create tables 
IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_C') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_C
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_C
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,ECEventSID BIGINT
	,ECEventDateTime DATETIME2
	,ECEventEndDateTime DATETIME2
	,TypeOfEvent VARCHAR(50)
)


-- Get ED encounter records from search period
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_C
SELECT DISTINCT
	sp.PatientSSN
	,edl.PatientSID
	,edl.VisitSID
	,edl.PatientArrivalDateTime
	,edl.DispositionDateTime
	,'ED Visit'
FROM Src.EDIS_EDISLog AS edl INNER JOIN Src.SPatient_SPatient AS sp ON
	(
		edl.PatientSID = sp.PatientSID
	)
WHERE 
	edl.PatientArrivalDateTime BETWEEN
		@STEP05_SearchStart
		AND
		@STEP05_SearchEnd
	AND
	edl.VisitSID != -1
	AND
	sp.PatientSSN IN
	(
		SELECT t.PatientSSN
		FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_Z AS t
	)





-- I.05.D ----------------------------------------------------------------------------------------

-- Create tables 
IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_D') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_D
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_D
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,InpSID BIGINT
	,InpDateTime DATETIME2
)


-- Get inpatient encounter records in relevant period
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_D
SELECT DISTINCT
	sp.PatientSSN
	,inp.PatientSID
	,inp.InpatientSID
	,inp.AdmitDateTime
FROM Src.Inpat_Inpatient AS inp INNER JOIN Src.SPatient_SPatient AS sp ON
	(
		inp.PatientSID = sp.PatientSID
	)
WHERE 
	inp.AdmitDateTime BETWEEN
		@STEP05_SearchStart
		AND
		@STEP05_SearchEnd
	AND
	inp.InpatientSID != -1
	AND
	sp.PatientSSN IN
	(
		SELECT t.PatientSSN
		FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_Z AS t
	)




-- I.05.E ----------------------------------------------------------------------------------------

-- Create tables 
IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_E') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_E
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_E
(
	ECEventSID BIGINT
)


-- Get records from STEP05_C that are followed by records from STEP05_D
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_E
SELECT DISTINCT
	prev.ECEventSID
FROM
	Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_C AS prev INNER JOIN Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_D AS ex_inp ON
	(
		prev.PatientSID = ex_inp.PatientSID
		AND
		ex_inp.InpDateTime BETWEEN
			prev.ECEventEndDateTime
			AND
			DATEADD(HOUR, 24, prev.ECEventEndDateTime)
	)




-- I.05.F ----------------------------------------------------------------------------------------

-- Create tables 
IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_F') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_F
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_F
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,ECEventSID BIGINT
	,ECEventDateTime DATETIME2
	,ECEventEndDateTime DATETIME2
	,TypeOfEvent VARCHAR(50)
)


-- Get records from STEP05_C that aren't in STEP05_E
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_F
SELECT DISTINCT
	prev.PatientSSN
	,prev.PatientSID
	,prev.ECEventSID
	,prev.ECEventDateTime
	,prev.ECEventEndDateTime
	,prev.TypeOfEvent
FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_C AS prev
WHERE
	prev.ECEventSID NOT IN 
	(
		SELECT t.ECEventSID
		FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_E AS t
	)




-- I.05.G ----------------------------------------------------------------------------------------

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_Z') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_Z
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_Z
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,ECEventSID BIGINT
	,ECEventDateTime DATETIME2
	,TypeOfEvent VARCHAR(50)
)

/* Select all Emergency Care events in iSTEP 05 PART A that were not
identified as being planned in iSTEP 05 PART B */
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_Z
SELECT DISTINCT
	ec.PatientSSN
	,ec.PatientSID
	,ec.ECEventSID
	,ec.ECEventDateTime
	,ec.TypeOfEvent
FROM
	Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_A AS ec
WHERE
	ec.ECEventSID NOT IN
	(
		SELECT pec.ECEventSID
		FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_B AS pec
	)

INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_Z
SELECT DISTINCT
	ec.PatientSSN
	,ec.PatientSID
	,ec.ECEventSID
	,ec.ECEventDateTime
	,ec.TypeOfEvent
FROM
	Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_F AS ec

GO




-- I.06.A ----------------------------------------------------------------------------------------

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP06_A') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP06_A
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP06_A
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer VARCHAR(100)
	,DiagnosisTypeOfEvent VARCHAR(50)
	,ECEventSID BIGINT
	,ECEventDateTime DATETIME2
	,ECTypeOfEvent VARCHAR(50)
)

/* Select dyads of Emergency Care events and Diagnosis Events such
that the Emergency Care precedes the Diagnosis Event by at most 30
days (and by at least 0 days; i.e., on the day of). */
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP06_A
SELECT DISTINCT
	dx.PatientSSN
	,dx.PatientSID
	,dx.DiagnosisEventSID
	,dx.DiagnosisEventDateTime
	,dx.HistologyOfCancer
	,dx.StageOfCancer
	,dx.TypeOfEvent
	,ec.ECEventSID
	,ec.ECEventDateTime
	,ec.TypeOfEvent
FROM
	Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_Z AS dx INNER JOIN Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_Z AS ec ON
	(
		dx.PatientSSN = ec.PatientSSN
		AND
		ec.ECEventDateTime BETWEEN
			DATEADD(DAY, (SELECT params.Lookback_Length_Days FROM Dflt._ppkt_CaP_2016to2020_ParameterTable AS params), dx.DiagnosisEventDateTime)
			AND
			dx.DiagnosisEventDateTime
	)




-- I.06.B ----------------------------------------------------------------------------------------

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP06_Z') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP06_Z
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP06_Z
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer VARCHAR(100)
	,DiagnosisTypeOfEvent VARCHAR(50)
	,ECEventSID BIGINT
	,ECEventDateTime DATETIME2
	,ECTypeOfEvent VARCHAR(50)
)

-- For each patient, select the dyad with the latest emergency care event from iSTEP 06 PART A
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP06_Z
SELECT DISTINCT
	ecdx.PatientSSN
	,ecdx.PatientSID
	,ecdx.DiagnosisEventSID
	,ecdx.DiagnosisEventDateTime
	,ecdx.HistologyOfCancer
	,ecdx.StageOfCancer
	,ecdx.DiagnosisTypeOfEvent
	,ecdx.ECEventSID
	,ecdx.ECEventDateTime
	,ecdx.ECTypeOfEvent
FROM
	Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP06_A AS ecdx
WHERE
	ecdx.ECEventDateTime = 
	(
		SELECT TOP 1 t.ECEventDateTime
		FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP06_A AS t
		WHERE ecdx.PatientSSN = t.PatientSSN
		ORDER BY t.ECEventDateTime DESC, t.ECTypeOfEvent DESC
	)
	AND
	ecdx.ECEventSID = 
	(
		SELECT TOP 1 t.ECEventSID
		FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP06_A AS t
		WHERE ecdx.PatientSSN = t.PatientSSN
		ORDER BY t.ECEventDateTime DESC, t.ECTypeOfEvent DESC
	)

GO




-- I.07 ----------------------------------------------------------------------------------------

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_FINAL') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_FINAL
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_FINAL
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer VARCHAR(100)
	,DiagnosisTypeOfEvent VARCHAR(50)
	,ECEventSID BIGINT
	,ECEventDateTime DATETIME2
	,ECTypeOfEvent VARCHAR(50)
	,EP INT
)

-- Save records after the inclusion steps
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_FINAL
SELECT DISTINCT
	prev.PatientSSN
	,prev.PatientSID
	,prev.DiagnosisEventSID
	,prev.DiagnosisEventDateTime
	,prev.HistologyOfCancer
	,prev.StageOfCancer
	,prev.DiagnosisTypeOfEvent
	,prev.ECEventSID
	,prev.ECEventDateTime
	,prev.ECTypeOfEvent
	,1
FROM
	Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP06_Z AS prev

-- Save records after the inclusion steps
INSERT INTO Dflt._ppkt_CaP_2016to2020_INCLUSION_FINAL
SELECT DISTINCT
	prev.PatientSSN
	,prev.PatientSID
	,prev.DiagnosisEventSID
	,prev.DiagnosisEventDateTime
	,prev.HistologyOfCancer
	,prev.StageOfCancer
	,prev.TypeOfEvent
	,-1
	,NULL
	,NULL
	,0
FROM
	Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_Z AS prev
WHERE
	prev.DiagnosisEventDateTime NOT IN
	(
		SELECT x.DiagnosisEventDateTime
		FROM Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP06_Z AS x
		WHERE x.PatientSSN = prev.PatientSSN
	)

GO




-- ************************************************************************************************
-- EXCLUSION
-- ************************************************************************************************

-- II.01.A ----------------------------------------------------------------------------------------

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_A') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_A
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_A
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer VARCHAR(100)
	,DiagnosisTypeOfEvent VARCHAR(50)
	,HistoricalEventSID BIGINT
	,HistoricalEventDateTime DATETIME2
	,HistoricalTypeOfEvent VARCHAR(50)
)

-- Get all historical outpatient records for patients
INSERT INTO Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_A
SELECT DISTINCT
	inc.PatientSSN
	,inc.PatientSID
	,inc.DiagnosisEventSID
	,inc.DiagnosisEventDateTime
	,inc.HistologyOfCancer
	,inc.StageOfCancer
	,inc.DiagnosisTypeOfEvent
	,owl.VisitSID
	,owl.VisitDateTime
	,'PCP'
FROM
	Dflt._ppkt_CaP_2016to2020_INCLUSION_FINAL AS inc INNER JOIN Src.SPatient_SPatient AS sp ON
	(
		inc.PatientSSN = sp.PatientSSN
		AND
		sp.PatientSID != -1
	)
		INNER JOIN Src.Outpat_Workload AS owl ON
		(
			sp.PatientSID = owl.PatientSID
			AND
			owl.PatientSID != -1
		)
			INNER JOIN CDWWork.Dim.StopCode AS stopcode1 ON
			(
				owl.PrimaryStopCodeSID = stopcode1.StopCodeSID
			)
				INNER JOIN CDWWork.Dim.StopCode AS stopcode2 ON
				(
					owl.PrimaryStopCodeSID = stopcode2.StopCodeSID
				)
WHERE
	(
		(
			--PCP Stop Codes
			stopcode1.StopCode IN
			(
				--156		-- Home-Based Primary Care - Psychologist
				--,157	-- Home-Based Primary Care - Psychiatrist
				--,170	-- Hospital-Based Home Care???????????????????????????????????????????????????????????????????????????????????????????????????????????????????
				--,171	-- Home-Based Primary Care - RN or LPN
				--,172	-- Hospital-Based Home Care (extender)???????????????????????????????????????????????????????????????????????????????????????????????????????????????????
				--,173	-- Home-Based Primary Care - Social Worker
				--,174	-- Home-Based Primary Care - Therapist
				--,175	-- Home-Based Primary Care - Dietician
				--,176	-- Home-Based Primary Care - Clinical Pharmacist
				--,177	-- Home-Based Primary Care - Other
				--,178	-- Home-Based Primary Care - Telephone
				301	-- General Internal Medicine
				,322	-- Women's Clinic/Comprehensive Woman's Primary Clinic
				,323	-- Primary Care Medicine
				--,338	-- Telephone Primary Care !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!EXCLUDE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				,348	-- Primary Care Group/Shared Appointment
				,350	-- Geripact/Geriatric Primary Care					
				,531	-- Mental Health Primary Care (Indivdual)
				,534	-- Mental Health Integrated Care (Individual)
				,539	-- Mental Health Integrated Care (Group)
				--,634	-- Can't find????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
			)
			OR
			ISNULL(stopcode2.StopCode, 0) IN
			(
				--156	-- Home-Based Primary Care - Psychologist
				--,157	-- Home-Based Primary Care - Psychiatrist
				--,170	-- Hospital-Based Home Care???????????????????????????????????????????????????????????????????????????????????????????????????????????????????
				--,171	-- Home-Based Primary Care - RN or LPN
				--,172	-- Hospital-Based Home Care (extender)???????????????????????????????????????????????????????????????????????????????????????????????????????????????????
				--,173	-- Home-Based Primary Care - Social Worker
				--,174	-- Home-Based Primary Care - Therapist
				--,175	-- Home-Based Primary Care - Dietician
				--,176	-- Home-Based Primary Care - Clinical Pharmacist
				--,177	-- Home-Based Primary Care - Other
				--,178	-- Home-Based Primary Care - Telephone
				301	-- General Internal Medicine
				,322	-- Women's Clinic/Comprehensive Woman's Primary Clinic
				,323	-- Primary Care Medicine
				--,338	-- Telephone Primary Care !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!EXCLUDE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				,348	-- Primary Care Group/Shared Appointment
				,350	-- Geripact/Geriatric Primary Care
				,531	-- Mental Health Primary Care (Indivdual)
				,534	-- Mental Health Integrated Care (Individual)
				,539	-- Mental Health Integrated Care (Group)				
				--,634	-- Can't find????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
			)		
		)
		AND 
		ISNULL(stopcode2.StopCode, 0) NOT IN 
		(
			107		-- EKG
			,115	-- Ultrasound
			,152	-- Angiogram Catherization
			,311	-- Cardiac Implantable Electronic Devices
			,321	-- GI Endoscopy
			,328	-- Medical/Surgery Day Unit
			,329	-- Medical Procedure Unit
			,333	-- Cardiac Catherization
			,334	-- Cardiac Stress Test
			,430	-- Cysto Room in Urology Clinic
			,435	-- Surgical Procedure Unit
			,474	-- Research
			,999	-- Don't know????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
		)
	)
	AND
	(
		(inc.EP = 0 AND owl.VisitDateTime < inc.DiagnosisEventDateTime)
		OR
		(inc.EP = 1 AND owl.VisitDateTime < inc.ECEventDateTime)
	)


-- II.01.B ----------------------------------------------------------------------------------------

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_Z1') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_Z1
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_Z1
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer VARCHAR(100)
	,DiagnosisTypeOfEvent VARCHAR(50)
	,HistoricalEventSID BIGINT
	,HistoricalEventDateTime DATETIME2
	,HistoricalTypeOfEvent VARCHAR(50)
	,DxHxDelta INT
)

-- For each patient, get the earliest historical event from eSTEP 01 PART A
INSERT INTO Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_Z1
SELECT DISTINCT
	hx.*
	,DATEDIFF(MONTH, hx.HistoricalEventDateTime, hx.DiagnosisEventDateTime)
FROM
	Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_A AS hx
WHERE
	hx.HistoricalEventDateTime = 
	(
		SELECT TOP 1 t.HistoricalEventDateTime
		FROM Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_A AS t
		WHERE hx.PatientSSN = t.PatientSSN
		ORDER BY t.HistoricalEventDateTime ASC
	)


-- II.01.C ----------------------------------------------------------------------------------------

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_Z2') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_Z2
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_Z2
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer VARCHAR(100)
	,DiagnosisTypeOfEvent VARCHAR(50)
	,HistoricalEventSID BIGINT
	,HistoricalEventDateTime DATETIME2
	,HistoricalTypeOfEvent VARCHAR(50)
	,DxHxDelta INT
)

-- For each patient, get the latest historical event from eSTEP 01 PART A
INSERT INTO Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_Z2
SELECT DISTINCT
	hx.*
	,DATEDIFF(MONTH, hx.HistoricalEventDateTime, hx.DiagnosisEventDateTime)
FROM
	Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_A AS hx
WHERE
	hx.HistoricalEventDateTime = 
	(
		SELECT TOP 1 t.HistoricalEventDateTime
		FROM Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_A AS t
		WHERE hx.PatientSSN = t.PatientSSN
		ORDER BY t.HistoricalEventDateTime DESC
	)

GO


-- II.02.A ----------------------------------------------------------------------------------------

-- Set the emergency care (EC) search period 
DECLARE @STEP02_CareHxThreshold INT

SET @STEP02_CareHxThreshold = (SELECT params.CareHx_Length_Months FROM Dflt._ppkt_CaP_2016to2020_ParameterTable AS params)

PRINT CHAR(13) + CHAR(10) + 'eStep 02 - Minimum Care History Threshold: ' + CAST(@STEP02_CareHxThreshold AS VARCHAR)

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_A') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_A
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_A
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer VARCHAR(100)
	,DiagnosisTypeOfEvent VARCHAR(50)
	,ECEventSID BIGINT
	,ECEventDateTime DATETIME2
	,ECTypeOfEvent VARCHAR(50)
	,EP INT
	,HasPCPBeforeCutOff INT
)

/* Select records from the Inclusion steps that have an in-system medical history > the 
threshold as deteremined by the date of their earliest PCP encounter. */
INSERT INTO Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_A
SELECT DISTINCT
	prev.PatientSSN
	,prev.PatientSID
	,prev.DiagnosisEventSID
	,prev.DiagnosisEventDateTime
	,prev.HistologyOfCancer
	,prev.StageOfCancer
	,prev.DiagnosisTypeOfEvent
	,prev.ECEventSID
	,prev.ECEventDateTime
	,prev.ECTypeOfEvent
	,prev.EP
	,CASE
		WHEN ehx.DxHxDelta > @STEP02_CareHxThreshold THEN 1
		ELSE 0
	 END
FROM
	Dflt._ppkt_CaP_2016to2020_INCLUSION_FINAL AS prev INNER JOIN Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_Z1 AS ehx ON
	(
		prev.PatientSSN = ehx.PatientSSN
		AND
		prev.DiagnosisEventSID = ehx.DiagnosisEventSID
	)


-- II.02.B ----------------------------------------------------------------------------------------

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_B') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_B
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_B
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer VARCHAR(100)
	,DiagnosisTypeOfEvent VARCHAR(50)
	,ECEventSID BIGINT
	,ECEventDateTime DATETIME2
	,ECTypeOfEvent VARCHAR(50)
	,EP INT
	,HasPCPBeforeCutOff INT
	,HasPCPAfterCutOff INT
)

/* Select records from the Inclusion steps that have a PCP encounter 
that has occured within the threshold lookback period prior to their diagnosis date*/
INSERT INTO Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_B
SELECT DISTINCT
	prev.PatientSSN
	,prev.PatientSID
	,prev.DiagnosisEventSID
	,prev.DiagnosisEventDateTime
	,prev.HistologyOfCancer
	,prev.StageOfCancer
	,prev.DiagnosisTypeOfEvent
	,prev.ECEventSID
	,prev.ECEventDateTime
	,prev.ECTypeOfEvent
	,prev.EP
	,prev.HasPCPBeforeCutOff
	,CASE
		WHEN ehx.DxHxDelta < @STEP02_CareHxThreshold THEN 1
		ELSE 0
	 END
FROM
	Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_A AS prev INNER JOIN Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_Z2 AS ehx ON
	(
		prev.PatientSSN = ehx.PatientSSN
		AND
		prev.DiagnosisEventSID = ehx.DiagnosisEventSID
	)


GO


-- II.02.C ----------------------------------------------------------------------------------------

SELECT DISTINCT
	PatientSSN
	,COUNT(HistoricalEventDateTime) AS HistoricalEventsLastYear
INTO
	#LastYear
FROM
	Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_A AS a
WHERE
	a.HistoricalEventDateTime BETWEEN DATEADD(YEAR, -1, a.DiagnosisEventDateTime) AND a.DiagnosisEventDateTime
GROUP BY
	PatientSSN
ORDER BY
	HistoricalEventsLastYear

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_C') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_C
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_C
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer VARCHAR(100)
	,DiagnosisTypeOfEvent VARCHAR(50)
	,ECEventSID BIGINT
	,ECEventDateTime DATETIME2
	,ECTypeOfEvent VARCHAR(50)
	,EP INT
	,HasPCPBeforeCutOff INT
	,HasPCPAfterCutOff INT
	,HasPCPLastYear INT
)

INSERT INTO Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_C
SELECT DISTINCT
	prev.PatientSSN
	,prev.PatientSID
	,prev.DiagnosisEventSID
	,prev.DiagnosisEventDateTime
	,prev.HistologyOfCancer
	,prev.StageOfCancer
	,prev.DiagnosisTypeOfEvent
	,prev.ECEventSID
	,prev.ECEventDateTime
	,prev.ECTypeOfEvent
	,prev.EP
	,prev.HasPCPBeforeCutOff
	,prev.HasPCPAfterCutOff
	,1
FROM
	Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_B AS prev
WHERE
	prev.PatientSSN IN (SELECT t.PatientSSN FROM #LastYear AS t)

INSERT INTO Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_C
SELECT DISTINCT
	prev.PatientSSN
	,prev.PatientSID
	,prev.DiagnosisEventSID
	,prev.DiagnosisEventDateTime
	,prev.HistologyOfCancer
	,prev.StageOfCancer
	,prev.DiagnosisTypeOfEvent
	,prev.ECEventSID
	,prev.ECEventDateTime
	,prev.ECTypeOfEvent
	,prev.EP
	,prev.HasPCPBeforeCutOff
	,prev.HasPCPAfterCutOff
	,0
FROM
	Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_B AS prev
WHERE
	prev.PatientSSN NOT IN (SELECT t.PatientSSN FROM #LastYear AS t)

DROP TABLE #LastYear


GO


-- II.02.C ----------------------------------------------------------------------------------------

SELECT DISTINCT
	PatientSSN
	,COUNT(HistoricalEventDateTime) AS HistoricalEventsOneYearAgo
INTO
	#OneYearAgo
FROM
	Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_A AS a
WHERE
	a.HistoricalEventDateTime BETWEEN DATEADD(YEAR, -2, a.DiagnosisEventDateTime) AND DATEADD(YEAR, -1, a.DiagnosisEventDateTime)
GROUP BY
	PatientSSN
ORDER BY
	HistoricalEventsOneYearAgo

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_Z') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_Z
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_Z
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer VARCHAR(100)
	,DiagnosisTypeOfEvent VARCHAR(50)
	,ECEventSID BIGINT
	,ECEventDateTime DATETIME2
	,ECTypeOfEvent VARCHAR(50)
	,EP INT
	,HasPCPBeforeCutOff INT
	,HasPCPAfterCutOff INT
	,HasPCPLastYear INT
	,HasPCPOneYearAgo INT
)

INSERT INTO Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_Z
SELECT DISTINCT
	prev.PatientSSN
	,prev.PatientSID
	,prev.DiagnosisEventSID
	,prev.DiagnosisEventDateTime
	,prev.HistologyOfCancer
	,prev.StageOfCancer
	,prev.DiagnosisTypeOfEvent
	,prev.ECEventSID
	,prev.ECEventDateTime
	,prev.ECTypeOfEvent
	,prev.EP
	,prev.HasPCPBeforeCutOff
	,prev.HasPCPAfterCutOff
	,prev.HasPCPLastYear
	,1
FROM
	Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_C AS prev
WHERE
	prev.PatientSSN IN (SELECT t.PatientSSN FROM #OneYearAgo AS t)

INSERT INTO Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_Z
SELECT DISTINCT
	prev.PatientSSN
	,prev.PatientSID
	,prev.DiagnosisEventSID
	,prev.DiagnosisEventDateTime
	,prev.HistologyOfCancer
	,prev.StageOfCancer
	,prev.DiagnosisTypeOfEvent
	,prev.ECEventSID
	,prev.ECEventDateTime
	,prev.ECTypeOfEvent
	,prev.EP
	,prev.HasPCPBeforeCutOff
	,prev.HasPCPAfterCutOff
	,prev.HasPCPLastYear
	,0
FROM
	Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_C AS prev
WHERE
	prev.PatientSSN NOT IN (SELECT t.PatientSSN FROM #OneYearAgo AS t)

DROP TABLE #OneYearAgo


GO



-- II.03 ----------------------------------------------------------------------------------------

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_EXCLUSION_FINAL') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_FINAL
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_FINAL
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer VARCHAR(100)
	,DiagnosisTypeOfEvent VARCHAR(50)
	,ECEventSID BIGINT
	,ECEventDateTime DATETIME2
	,ECTypeOfEvent VARCHAR(50)
	,EP INT
	,HasPCPBeforeCutOff INT
	,HasPCPAfterCutOff INT
	,HasPCPLastYear INT
	,HasPCPOneYearAgo INT
)

-- Save records after exclusion steps
INSERT INTO Dflt._ppkt_CaP_2016to2020_EXCLUSION_FINAL
SELECT DISTINCT
	exc.PatientSSN
	,exc.PatientSID
	,exc.DiagnosisEventSID
	,exc.DiagnosisEventDateTime
	,exc.HistologyOfCancer
	,exc.StageOfCancer
	,exc.DiagnosisTypeOfEvent
	,exc.ECEventSID
	,exc.ECEventDateTime
	,exc.ECTypeOfEvent
	,exc.EP
	,exc.HasPCPBeforeCutOff
	,exc.HasPCPAfterCutOff
	,exc.HasPCPLastYear
	,exc.HasPCPOneYearAgo
FROM Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_Z AS exc

GO




-- ************************************************************************************************
-- OUTPUT
-- ************************************************************************************************

-- REFORMAT OUTPUT
-- ================================================================================================

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_REFORMAT_01') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_REFORMAT_01
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_REFORMAT_01
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer INT
	,DiagnosisTypeOfEvent VARCHAR(50)
	,ECEventSID BIGINT
	,ECEventDateTime DATETIME2
	,ECTypeOfEvent VARCHAR(50)
	,EP INT
	,HasPCPBeforeCutOff INT
	,HasPCPAfterCutOff INT
	,HasPCPLastYear INT
	,HasPCPOneYearAgo INT
)

INSERT INTO Dflt._ppkt_CaP_2016to2020_REFORMAT_01
SELECT DISTINCT
	exc.PatientSSN
	,exc.PatientSID
	,exc.DiagnosisEventSID
	,exc.DiagnosisEventDateTime
	,exc.HistologyOfCancer
	,CASE
		WHEN exc.StageOfCancer IS NULL THEN -1
		WHEN exc.StageOfCancer = 'I' THEN 1
		WHEN exc.StageOfCancer = 'II' THEN 2
		WHEN exc.StageOfCancer = 'III' THEN 3
		WHEN exc.StageOfCancer = 'IV' THEN 4
		ELSE -1
	 END
	,exc.DiagnosisTypeOfEvent
	,exc.ECEventSID
	,exc.ECEventDateTime
	,exc.ECTypeOfEvent
	,exc.EP
	,exc.HasPCPBeforeCutOff
	,exc.HasPCPAfterCutOff
	,exc.HasPCPLastYear
	,exc.HasPCPOneYearAgo
FROM Dflt._ppkt_CaP_2016to2020_EXCLUSION_FINAL AS exc
WHERE exc.DiagnosisTypeOfEvent = 'REGISTRY ENTRY'

GO


IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_REFORMAT_02') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_REFORMAT_02
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_REFORMAT_02
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer INT
	,ECEventSID BIGINT
	,ECEventDateTime DATETIME2
	,ECTypeOfEvent VARCHAR(50)
	,EP INT
	,HasPCPBeforeCutOff INT
	,HasPCPAfterCutOff INT
	,HasPCPLastYear INT
	,HasPCPOneYearAgo INT
)

INSERT INTO Dflt._ppkt_CaP_2016to2020_REFORMAT_02
SELECT DISTINCT
	exc.PatientSSN
	,exc.PatientSID
	,exc.DiagnosisEventSID
	,exc.DiagnosisEventDateTime
	,exc.HistologyOfCancer
	,exc.StageOfCancer
	,exc.ECEventSID
	,exc.ECEventDateTime
	,exc.ECTypeOfEvent
	,exc.EP
	,exc.HasPCPBeforeCutOff
	,exc.HasPCPAfterCutOff
	,exc.HasPCPLastYear
	,exc.HasPCPOneYearAgo
FROM Dflt._ppkt_CaP_2016to2020_REFORMAT_01 AS exc
WHERE
	exc.StageOfCancer = (SELECT TOP 1 t.StageOfCancer
						FROM Dflt._ppkt_CaP_2016to2020_REFORMAT_01 AS t
						WHERE t.PatientSSN = exc.PatientSSN AND t.DiagnosisEventDateTime = exc.DiagnosisEventDateTime
						ORDER BY t.StageOfCancer DESC)

GO


IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_REFORMAT_03') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_REFORMAT_03
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_REFORMAT_03
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer INT
	,ECEventSID BIGINT
	,ECEventDateTime DATETIME2
	,ECTypeOfEvent VARCHAR(50)
	,EP INT
	,HasPCPBeforeCutOff INT
	,HasPCPAfterCutOff INT
	,HasPCPLastYear INT
	,HasPCPOneYearAgo INT
)

INSERT INTO Dflt._ppkt_CaP_2016to2020_REFORMAT_03
SELECT DISTINCT
	exc.PatientSSN
	,exc.PatientSID
	,exc.DiagnosisEventSID
	,exc.DiagnosisEventDateTime
	,exc.HistologyOfCancer
	,exc.StageOfCancer
	,exc.ECEventSID
	,exc.ECEventDateTime
	,exc.ECTypeOfEvent
	,exc.EP
	,exc.HasPCPBeforeCutOff
	,exc.HasPCPAfterCutOff
	,exc.HasPCPLastYear
	,exc.HasPCPOneYearAgo
FROM Dflt._ppkt_CaP_2016to2020_REFORMAT_02 AS exc
WHERE
	exc.DiagnosisEventSID = (SELECT TOP 1 t.DiagnosisEventSID
							FROM Dflt._ppkt_CaP_2016to2020_REFORMAT_01 AS t
							WHERE t.PatientSSN = exc.PatientSSN AND t.DiagnosisEventDateTime = exc.DiagnosisEventDateTime
							ORDER BY t.StageOfCancer DESC)

GO


IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_REFORMAT_04') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_REFORMAT_04
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_REFORMAT_04
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,CDWDiagnosisSetting VARCHAR(50)
	,HistologyOfCancer VARCHAR(300)
	,StageOfCancer INT
	,ECEventSID BIGINT
	,ECEventDateTime DATETIME2
	,ECTypeOfEvent VARCHAR(50)
	,EP INT
	,HasPCPBeforeCutOff INT
	,HasPCPAfterCutOff INT
	,HasPCPLastYear INT
	,HasPCPOneYearAgo INT
)

INSERT INTO Dflt._ppkt_CaP_2016to2020_REFORMAT_04
SELECT DISTINCT
	a.PatientSSN
	,a.PatientSID
	,a.DiagnosisEventSID
	,a.DiagnosisEventDateTime
	,'Intra-Emergency'
	,a.HistologyOfCancer
	,a.StageOfCancer
	,a.ECEventSID
	,a.ECEventDateTime
	,a.ECTypeOfEvent
	,a.EP
	,a.HasPCPBeforeCutOff
	,a.HasPCPAfterCutOff
	,a.HasPCPLastYear
	,a.HasPCPOneYearAgo
FROM Dflt._ppkt_CaP_2016to2020_REFORMAT_03 AS a INNER JOIN Src.Inpat_Inpatient AS b ON a.ECEventSID = b.InpatientSID
WHERE ECEventSID != -1 AND a.DiagnosisEventDateTime BETWEEN b.AdmitDateTime AND b.DischargeDateTime

INSERT INTO Dflt._ppkt_CaP_2016to2020_REFORMAT_04
SELECT DISTINCT
	a.PatientSSN
	,a.PatientSID
	,a.DiagnosisEventSID
	,a.DiagnosisEventDateTime
	,'Intra-Emergency'
	,a.HistologyOfCancer
	,a.StageOfCancer
	,a.ECEventSID
	,a.ECEventDateTime
	,a.ECTypeOfEvent
	,a.EP
	,a.HasPCPBeforeCutOff
	,a.HasPCPAfterCutOff
	,a.HasPCPLastYear
	,a.HasPCPOneYearAgo
FROM Dflt._ppkt_CaP_2016to2020_REFORMAT_03 AS a INNER JOIN Src.EDIS_EDISLog AS b ON a.ECEventSID = b.VisitSID
WHERE ECEventSID != -1 AND a.DiagnosisEventDateTime BETWEEN b.PatientArrivalDateTime AND b.PatientDepartureDateTime

INSERT INTO Dflt._ppkt_CaP_2016to2020_REFORMAT_04
SELECT DISTINCT
	a.PatientSSN
	,a.PatientSID
	,a.DiagnosisEventSID
	,a.DiagnosisEventDateTime
	,'Post-Emergency'
	,a.HistologyOfCancer
	,a.StageOfCancer
	,a.ECEventSID
	,a.ECEventDateTime
	,a.ECTypeOfEvent
	,a.EP
	,a.HasPCPBeforeCutOff
	,a.HasPCPAfterCutOff
	,a.HasPCPLastYear
	,a.HasPCPOneYearAgo
FROM Dflt._ppkt_CaP_2016to2020_REFORMAT_03 AS a
WHERE a.PatientSSN NOT IN (SELECT t.PatientSSN FROM Dflt._ppkt_CaP_2016to2020_REFORMAT_04 AS t)

GO


-- SAVE OUTPUT
-- ================================================================================================

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_OUTPUT_01_CORE') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_OUTPUT_01_CORE
	END

CREATE TABLE Dflt._ppkt_CaP_2016to2020_OUTPUT_01_CORE
(
	PatientSSN VARCHAR(10)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosisEventDateTime DATETIME2
	,DiagnosisTypeOfEvent VARCHAR(50)
	,StageOfCancer INT
	,HistologyOfCancer VARCHAR(300)
	,ECEventSID BIGINT
	,ECEventDateTime DATETIME2
	,ECTypeOfEvent VARCHAR(50)
	,EP INT
	,HasPCPBeforeCutOff INT
	,HasPCPAfterCutOff INT
	,HasPCPLastYear INT
	,HasPCPOneYearAgo INT
)

INSERT INTO Dflt._ppkt_CaP_2016to2020_OUTPUT_01_CORE
SELECT DISTINCT
	a.PatientSSN
	,a.PatientSID
	,a.DiagnosisEventSID
	,a.DiagnosisEventDateTime
	,a.CDWDiagnosisSetting
	,a.StageOfCancer
	,a.HistologyOfCancer
	,a.ECEventSID
	,a.ECEventDateTime
	,a.ECTypeOfEvent
	,a.EP
	,a.HasPCPBeforeCutOff
	,a.HasPCPAfterCutOff
	,a.HasPCPLastYear
	,a.HasPCPOneYearAgo
FROM Dflt._ppkt_CaP_2016to2020_REFORMAT_04 AS a

GO


-- DELETE TABLES
-- ================================================================================================

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_ParameterTable') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_ParameterTable
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_SETUP_PlannedHospitalization_ICD10CMCodes') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_SETUP_PlannedHospitalization_ICD10CMCodes
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_SETUP_PlannedHospitalization_ICD10PCSCodes') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_SETUP_PlannedHospitalization_ICD10PCSCodes
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP01_Z') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP01_Z
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP02_Z') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP02_Z
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP03_A') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP03_A
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP03_Z') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP03_Z
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_A') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_A
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_B') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_B
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_Z') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP04_Z
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_A') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_A
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_B') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_B
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_C') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_C
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_D') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_D
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_E') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_E
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_F') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_F
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_Z') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP05_Z
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP06_A') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP06_A
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP06_Z') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_STEP06_Z
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_INCLUSION_FINAL') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_INCLUSION_FINAL
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_A') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_A
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_Z1') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_Z1
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_Z2') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP01_Z2
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_A') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_A
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_B') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_B
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_C') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_C
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_Z') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_STEP02_Z
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_EXCLUSION_FINAL') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_EXCLUSION_FINAL
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_REFORMAT_01') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_REFORMAT_01
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_REFORMAT_02') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_REFORMAT_02
	END

IF (OBJECT_ID('Dflt._ppkt_CaP_2016to2020_REFORMAT_04') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppkt_CaP_2016to2020_REFORMAT_04
	END