-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE FORCE VIEW XXBI_LEAD_STATE_DIM_V                 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_LEAD_STATE_DIM_V.vw                           |
-- | Description :  State Dimension View                               |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       10-Mar-2009 Indra Varada       Initial draft version     |
-- |1.1       29-Mar-2010 Luis Mazuera       New fast refresh MV's     | 
-- +===================================================================+
AS 
SELECT distinct lk.lookup_code ID, lk.meaning VALUE
FROM fnd_lookup_values lk,
     XXBI_SALES_LEADS_FCT_MV fct,
     XXBI_GROUP_MBR_INFO_V h
WHERE fct.state = lk.lookup_code
AND  fct.resource_id = h.resource_id
AND fct.role_id = h.role_id
AND fct.group_id = h.group_id
AND   lk.lookup_type = 'US_STATE'
AND   lk.enabled_flag = 'Y'
UNION ALL
SELECT 'XX' ID, 'Not Available' VALUE
FROM DUAL;

/
SHOW ERRORS;
EXIT;