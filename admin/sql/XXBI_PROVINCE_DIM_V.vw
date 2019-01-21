SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE VIEW XXBI_LEAD_PROVINCE_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_LEAD_PROVINCE_DIM_V.vw                        |
-- | Description :  Province Dimension View                            |
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
SELECT distinct lk.lookup_code ID, lk.meaning VALUE
FROM fnd_lookup_values lk,
     xxcrm.xxbi_sales_leads_fct fct,
     XXBI_SALES_LEAD_REPS_FCT_MV fctmv
WHERE fct.state = lk.lookup_code
AND   fctmv.sales_lead_id = fct.sales_lead_id
AND   fctmv.user_id = fnd_global.user_id
AND   lk.lookup_type = 'CA_PROVINCE'
AND   lk.enabled_flag = 'Y';

/
SHOW ERRORS;
EXIT;