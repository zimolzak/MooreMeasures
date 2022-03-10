USE [ORD_Singh_202001030D]

SELECT TOP 11
	  --[PatientSSN]
      --,[DiagnosticEventDateTime]
      --,[DiagnosisEventLocation]
      --,[TypeOfCancer]
      --,[StageOfCancer]
      --,[TypeOfDiagnosisEvent]
      --,[DeathDateTime]
      [PatientSex]
      ,[PatientAge]
      ,[PatientRace]
  FROM [Dflt].[_ppko_CRC_2019d_DEMOGRAPHIC_TABLE]

select top 11 
[PatientSSN]
      ,[DiagnosticEventDateTime]
      ,[DiagnosisEventLocation]
      ,[TypeOfCancer]
      ,[StageOfCancer]
      ,[TypeOfDiagnosisEvent]
	 from
[Dflt].[_ppko_CRC_2019d_OUTPUT_TABLE]


SELECT TOP 11
--[PatientSSN]
      --,[DiagnosticEventDateTime]
      --,[DiagnosisEventLocation]
      --,[TypeOfCancer]
      --,[StageOfCancer]
      --,[TypeOfDiagnosisEvent]
      --,[EmergencyEventDate]
      --,[EmergencyEventLocation]
      --,[TypeOfEmergencyEvent]
      --,[DeathDateTime]
      [PatientSex]
      ,[PatientAge]
      ,[PatientRace]
  FROM [ORD_Singh_202001030D].[Dflt].[_ppko_CRC_2019n_DEMOGRAPHIC_TABLE]

select count(*) from [Dflt].[_ppko_CRC_2019d_DEMOGRAPHIC_TABLE] --2375

select count(*) FROM [Dflt].[_ppko_CRC_2019n_DEMOGRAPHIC_TABLE]  --572

select count(*) as n, patientsex
FROM [Dflt].[_ppko_CRC_2019n_DEMOGRAPHIC_TABLE]
group by PatientSex
/*
n	patientsex
24	F
548	M
*/

select count(*) as n, [PatientRace]
FROM [Dflt].[_ppko_CRC_2019n_DEMOGRAPHIC_TABLE]
group by [PatientRace]
/*
n	PatientRace
113	BLACK
41	HISPANIC
26	OTHER
392	WHITE, NOT HISPANIC
*/

select count(*) as n, patientsex FROM [Dflt].[_ppko_CRC_2019d_DEMOGRAPHIC_TABLE] group by PatientSex
/*
n	patientsex
112	F
2263	M
*/

select count(*) as n, PatientRace FROM [Dflt].[_ppko_CRC_2019d_DEMOGRAPHIC_TABLE] group by PatientRace
/*
n	PatientRace
114	OTHER
148	HISPANIC
1619	WHITE, NOT HISPANIC
494	BLACK
*/
