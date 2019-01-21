-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                                                                          |
-- +==========================================================================+
-- | Name : XX_PA_PROJ_EJM_DATA_V                                             |
-- | Description :  Create view to pull out data from SQL Server through      |                                                                      |
-- |                DB Link.                                                  | 
-- | Requires OD_COUNTRY_DEFAULTS and PA_RESPONSBILITY_ID to be setup.        |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     01-Jan-2008  Daniel Ligas         Initial version               |
-- | V1.1     19-Feb-2009  Daniel Ligas         Shift buisness logic to source|
-- |                                            system.                       |
-- +==========================================================================+

   SET SHOW         OFF
   SET VERIFY       OFF
   SET ECHO         OFF
   SET TAB          OFF
   SET FEEDBACK     ON

   CREATE OR REPLACE FORCE VIEW XX_PA_PROJ_EJM_DATA_V
AS
SELECT E."PANEx" panex, E."ProjectID" projectid,
       T.project_id templateid, E."Template" template_num,
       O.organization_id projorgid, E."ProjOrg" proj_org,
       E."ProjName" projname, E."ProjLongName" projlongname, E."ProjDescr" projdescr,
       E."StartDate" startdate, E."CompletionDate" completiondate,
       E."CountryID" countryid,
       OU.organization_id org_id,
       E."Expenses" expenses, E."Capital" capital,
       R.application_id,
       R.responsibility_id
  FROM XX_PA_PROJ_EJM_DATA E
       LEFT JOIN PA.PA_PROJECTS_ALL T
            ON T.segment1 = E."Template"
               AND template_flag = 'Y'
       LEFT JOIN APPS.hr_all_organization_units O
            ON O.name = E."ProjOrg"
       LEFT JOIN APPS.xx_fin_translatevalues V
            ON V.source_value1 = LTRIM(RTRIM(E."CountryID"))
       JOIN APPS.xx_fin_translatedefinition D
            ON D.translate_id = V.translate_id
               AND D.translation_name = 'OD_COUNTRY_DEFAULTS'
       JOIN APPS.hr_operating_units OU
            ON OU.name = V.target_value2
       JOIN APPS.fnd_lookup_values_vl L
            ON L.lookup_code = OU.name
               AND L.lookup_type = 'PA_RESPONSBILITY_ID'
               AND (L.end_date_active >= sysdate or L.end_date_active IS NULL)
               AND L.enabled_flag = 'Y'
       LEFT JOIN APPS.FND_RESPONSIBILITY_TL R
            ON R.responsibility_name = L.meaning
;

   SHOW ERROR