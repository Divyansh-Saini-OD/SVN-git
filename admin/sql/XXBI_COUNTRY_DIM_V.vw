SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE VIEW XXBI_COUNTRY_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_COUNTRY_DIM_V.vw                              |
-- | Description :  Country Dimension View                             |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       03-Apr-2007 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT distinct fct.country ID, fct.country VALUE
FROM xxcrm.xxbi_sales_leads_fct fct,
     XXBI_SALES_LEAD_REPS_FCT_MV fctmv
WHERE fctmv.sales_lead_id = fct.sales_lead_id
AND   fctmv.user_id = fnd_global.user_id;

/
SHOW ERRORS;
EXIT;