-- Pull relevant fields from demographic table for numerator

IF (OBJECT_ID('Dflt._ppko_CRC_2019_PREMASTER_TABLE_01') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppko_CRC_2019_PREMASTER_TABLE_01
	END

CREATE TABLE Dflt._ppko_CRC_2019_PREMASTER_TABLE_01
(
	PatientSSN VARCHAR(100)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosticEventDateTime DATE
	,DiagnosisEventLocation VARCHAR(200)
	,TypeOfCancer VARCHAR(300)
	,StageOfCancer INT
	,TypeOfDiagnosisEvent VARCHAR(50)
	,ECEventSID BIGINT
	,EmergencyEventDate DATE
	,EmergencyEventLocation VARCHAR(200)
	,TypeOfEmergencyEvent VARCHAR(50)
	,EP INT
	,HasPCPBeforeCutOff INT
	,HasPCPAfterCutOff INT
	,DeathDateTime DATETIME2
	,PatientSex INT
	,PatientAge INT
	,PatientRace INT
	,DiagnosisSta3n INT
)

INSERT INTO Dflt._ppko_CRC_2019_PREMASTER_TABLE_01
SELECT DISTINCT
	SUBSTRING(a.PatientSSN, 2, 9)
	,a.PatientSID
	,a.DiagnosisEventSID
	,a.DiagnosticEventDateTime
	,a.DiagnosisEventLocation
	,a.TypeOfCancer
	,CASE
		WHEN a.StageOfCancer IS NULL THEN 0
		WHEN a.StageOfCancer = 'I' THEN 1
		WHEN a.StageOfCancer = 'II' THEN 2
		WHEN a.StageOfCancer = 'III' THEN 3
		WHEN a.StageOfCancer = 'IV' THEN 4
		ELSE 0
	 END
	,a.TypeOfDiagnosisEvent 
	,a.ECEventSID 
	,a.EmergencyEventDate 
	,a.EmergencyEventLocation 
	,a.TypeOfEmergencyEvent 
	,a.EP 
	,a.HasPCPBeforeCutOff
	,a.HasPCPAfterCutOff 
	,a.DeathDateTime 
	,a.PatientSex
	,a.PatientAge
	,a.PatientRace
	,a.DiagnosisSta3n
FROM Dflt._ppkprd_CRC_2019t_OUTPUT_TABLE AS a
WHERE a.TypeOfDiagnosisEvent = 'REGISTRY ENTRY'


-- Select for only 1 record per SSN (mainly filtering people w/ multiple stages or dates recorded for their cancer) for numerator

IF (OBJECT_ID('Dflt._ppko_CRC_2019_PREMASTER_TABLE_02') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppko_CRC_2019_PREMASTER_TABLE_02
	END

CREATE TABLE Dflt._ppko_CRC_2019_PREMASTER_TABLE_02
(
	PatientSSN VARCHAR(100)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosticEventDateTime DATE
	,DiagnosisEventLocation VARCHAR(200)
	,TypeOfCancer VARCHAR(300)
	,StageOfCancer INT
	,TypeOfDiagnosisEvent VARCHAR(50)
	,ECEventSID BIGINT
	,EmergencyEventDate DATE
	,EmergencyEventLocation VARCHAR(200)
	,TypeOfEmergencyEvent VARCHAR(50)
	,EP INT
	,HasPCPBeforeCutOff INT
	,HasPCPAfterCutOff INT
	,DeathDateTime DATETIME2
	,PatientSex INT
	,PatientAge INT
	,PatientRace INT
	,DiagnosisSta3n INT
)

INSERT INTO Dflt._ppko_CRC_2019_PREMASTER_TABLE_02
SELECT * FROM Dflt._ppko_CRC_2019_PREMASTER_TABLE_01 AS a
WHERE
	a.DiagnosticEventDateTime = (SELECT TOP 1 x.DiagnosticEventDateTime FROM Dflt._ppko_CRC_2019_PREMASTER_TABLE_01 AS x WHERE x.PatientSSN = a.PatientSSN ORDER BY x.DiagnosticEventDateTime ASC)
	AND
	a.StageOfCancer = (SELECT TOP 1 x.StageOfCancer FROM Dflt._ppko_CRC_2019_PREMASTER_TABLE_01 AS x WHERE x.PatientSSN = a.PatientSSN ORDER BY x.StageOfCancer DESC)


-- Add all Encounters following dx

IF (OBJECT_ID('Dflt._ppko_CRC_2019_PREMASTER_TABLE_03') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppko_CRC_2019_PREMASTER_TABLE_03
	END

CREATE TABLE Dflt._ppko_CRC_2019_PREMASTER_TABLE_03
(
	PatientSSN VARCHAR(100)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosticEventDateTime DATE
	,DiagnosisEventLocation VARCHAR(200)
	,TypeOfCancer VARCHAR(300)
	,StageOfCancer INT
	,TypeOfDiagnosisEvent VARCHAR(50)
	,ECEventSID BIGINT
	,EmergencyEventDate DATE
	,EmergencyEventLocation VARCHAR(200)
	,TypeOfEmergencyEvent VARCHAR(50)
	,EP INT
	,HasPCPBeforeCutOff INT
	,HasPCPAfterCutOff INT
	,DeathDateTime DATETIME2
	,PatientSex INT
	,PatientAge INT
	,PatientRace INT
	,DiagnosisSta3n INT
	,EncounterSID BIGINT
	,EncounterDateTime DATETIME2
)

INSERT INTO Dflt._ppko_CRC_2019_PREMASTER_TABLE_03
SELECT DISTINCT
	x.*
	,inp.InpatientSID
	,inp.AdmitDateTime
FROM Src.Inpat_Inpatient AS inp RIGHT JOIN Dflt._ppko_CRC_2019_PREMASTER_TABLE_02 AS x ON inp.PatientSID = x.PatientSID
WHERE inp.AdmitDateTime >= x.DiagnosticEventDateTime

INSERT INTO Dflt._ppko_CRC_2019_PREMASTER_TABLE_03
SELECT DISTINCT
	x.*
	,oup.VisitSID
	,oup.VisitDateTime
FROM Src.Outpat_Workload AS oup RIGHT JOIN Dflt._ppko_CRC_2019_PREMASTER_TABLE_02 AS x ON oup.PatientSID = x.PatientSID
WHERE oup.VisitDateTime >= x.DiagnosticEventDateTime


-- Select for only the most recent encounter

IF (OBJECT_ID('Dflt._ppko_CRC_2019_PREMASTER_TABLE_04') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppko_CRC_2019_PREMASTER_TABLE_04
	END

CREATE TABLE Dflt._ppko_CRC_2019_PREMASTER_TABLE_04
(
	PatientSSN VARCHAR(100)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosticEventDateTime DATE
	,DiagnosisEventLocation VARCHAR(200)
	,TypeOfCancer VARCHAR(300)
	,StageOfCancer INT
	,TypeOfDiagnosisEvent VARCHAR(50)
	,ECEventSID BIGINT
	,EmergencyEventDate DATE
	,EmergencyEventLocation VARCHAR(200)
	,TypeOfEmergencyEvent VARCHAR(50)
	,EP INT
	,HasPCPBeforeCutOff INT
	,HasPCPAfterCutOff INT
	,DeathDateTime DATETIME2
	,PatientSex INT
	,PatientAge INT
	,PatientRace INT
	,DiagnosisSta3n INT
	,LatestEncounterSID BIGINT
	,LatestEncounterDateTime DATETIME2
)

INSERT INTO Dflt._ppko_CRC_2019_PREMASTER_TABLE_04
SELECT DISTINCT a.*
FROM Dflt._ppko_CRC_2019_PREMASTER_TABLE_03 AS a WHERE
a.EncounterSID IS NULL
OR
a.EncounterSID =
(
	SELECT TOP 1 x.EncounterSID
	FROM Dflt._ppko_CRC_2019_PREMASTER_TABLE_03 AS x
	WHERE a.PatientSSN = x.PatientSSN
	ORDER BY x.EncounterDateTime DESC
)


-- Add status flags

IF (OBJECT_ID('Dflt._ppko_CRC_2019_MASTER_TABLE') IS NOT NULL)
	BEGIN
		DROP TABLE Dflt._ppko_CRC_2019_MASTER_TABLE
	END

CREATE TABLE Dflt._ppko_CRC_2019_MASTER_TABLE
(
	PatientSSN VARCHAR(100)
	,PatientSID BIGINT
	,DiagnosisEventSID BIGINT
	,DiagnosticEventDateTime DATE
	,DiagnosisEventLocation VARCHAR(200)
	,TypeOfCancer VARCHAR(300)
	,StageOfCancer INT
	,TypeOfDiagnosisEvent VARCHAR(50)
	,ECEventSID BIGINT
	,EmergencyEventDate DATE
	,EmergencyEventLocation VARCHAR(200)
	,TypeOfEmergencyEvent VARCHAR(50)
	,EP INT
	,HasPCPBeforeCutOff INT
	,HasPCPAfterCutOff INT
	,DeathDateTime DATETIME2
	,PatientSex INT
	,PatientAge INT
	,PatientRace INT
	,DiagnosisSta3n INT
	,Time90 INT
	,Time180 INT
	,Time365 INT
	,DeathStatus90 INT
	,DeathStatus180 INT
	,DeathStatus365 INT
)

INSERT INTO Dflt._ppko_CRC_2019_MASTER_TABLE
SELECT
	CONCAT('''', a.PatientSSN, '''')
	,a.PatientSID
	,a.DiagnosisEventSID
	,a.DiagnosticEventDateTime
	,a.DiagnosisEventLocation
	,a.TypeOfCancer
	,a.StageOfCancer
	,a.TypeOfDiagnosisEvent
	,a.ECEventSID
	,a.EmergencyEventDate
	,a.EmergencyEventLocation
	,a.TypeOfEmergencyEvent
	,a.EP
	,a.HasPCPBeforeCutOff
	,a.HasPCPAfterCutOff
	,a.DeathDateTime
	,a.PatientSex
	,a.PatientAge
	,a.PatientRace
	,a.DiagnosisSta3n
	,CASE
		WHEN DATEDIFF(DAY, a.DiagnosticEventDateTime, a.LatestEncounterDateTime) < 90 THEN DATEDIFF(DAY, a.DiagnosticEventDateTime, a.LatestEncounterDateTime)
		ELSE 90
	 END
	,CASE
		WHEN DATEDIFF(DAY, a.DiagnosticEventDateTime, a.LatestEncounterDateTime) < 180 THEN DATEDIFF(DAY, a.DiagnosticEventDateTime, a.LatestEncounterDateTime)
		ELSE 180
	 END
	,CASE
		WHEN DATEDIFF(DAY, a.DiagnosticEventDateTime, a.LatestEncounterDateTime) < 365 THEN DATEDIFF(DAY, a.DiagnosticEventDateTime, a.LatestEncounterDateTime)
		ELSE 365
	 END
	-- 90 day status
	,CASE
		WHEN a.DeathDateTime IS NULL THEN 0
		WHEN a.DeathDateTime BETWEEN a.DiagnosticEventDateTime AND DATEADD(DAY, 90, DiagnosticEventDateTime) THEN 1
		ELSE 0
	 END
	-- 180 day status
	,CASE
		WHEN a.DeathDateTime IS NULL THEN 0
		WHEN a.DeathDateTime BETWEEN a.DiagnosticEventDateTime AND DATEADD(DAY, 180, DiagnosticEventDateTime) THEN 1
		ELSE 0
	 END
	-- 365 day status
	,CASE
		WHEN a.DeathDateTime IS NULL THEN 0
		WHEN a.DeathDateTime BETWEEN a.DiagnosticEventDateTime AND DATEADD(DAY, 365, DiagnosticEventDateTime) THEN 1
		ELSE 0
	 END
FROM Dflt._ppko_CRC_2019_PREMASTER_TABLE_04 AS a

SELECT * FROM Dflt._ppko_CRC_2019_MASTER_TABLE