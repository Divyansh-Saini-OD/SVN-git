-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE VIEW XXBI_CUST_REVENUE_BAND_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_CUST_REVENUE_BAND_DIM_V.vw                    |
-- | Description :  Customer Revenue Band Dim                          |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       10-Mar-2009 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT f_usage.descriptive_flex_context_code || '-' || f_v.flex_value ID,
       f_usage.descriptive_flex_context_code || '::' || f_vtl.description value
FROM   
FND_DESCR_FLEX_COLUMN_USAGES f_usage
,FND_FLEX_VALUES_tl f_vtl
, FND_FLEX_VALUES f_v 
WHERE f_usage.flex_value_set_id = f_v.flex_value_set_id
AND  f_vtl.flex_value_id = f_v.flex_value_id
AND f_usage.descriptive_flex_context_code IN ('US','CA')
AND f_usage.descriptive_flexfield_name='HZ_PARTIES' 
AND f_usage.application_column_name = 'ATTRIBUTE24'
AND f_v.enabled_flag = 'Y'
UNION ALL
SELECT 'XX' id, 'Not Available' value
FROM DUAL

/
SHOW ERRORS;
EXIT;