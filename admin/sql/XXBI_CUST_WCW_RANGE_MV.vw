-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE MATERIALIZED VIEW APPS.XXBI_CUST_WCW_RANGE_MV
  REFRESH COMPLETE ON DEMAND
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_CUST_WCW_RANGE_MV.vw                          |
-- | Description :  MV for Customer WCW Range                          |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.0       17-Mar-2009   Sreekanth Rao    Initial version           |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT 
   lookup_code   id,
   meaning       value,
   to_number(substr(tag,1,instr(tag,'-',1,1)-1)) low_val,
   to_number(substr(tag,instr(tag,'-',1,1)+1)) high_val
FROM
   apps.fnd_lookup_values 
WHERE
    lookup_type = 'XXBI_CUST_WCW_RANGE'
AND nvl(enabled_flag,'N') = 'Y'
AND sysdate between nvl(start_date_active,sysdate-1) and nvl(end_date_active,sysdate+1)
/
SHOW ERRORS;
EXIT;