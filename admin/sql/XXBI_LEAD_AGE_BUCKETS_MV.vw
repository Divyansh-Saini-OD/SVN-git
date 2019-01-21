SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE MATERIALIZED VIEW APPS.XXBI_LEAD_AGE_BUCKETS_MV
  REFRESH COMPLETE ON DEMAND
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_OPPTY_AGE_BUCKETS_MV.vw                       |
-- | Description :  MV for Opportunity Age Buckets                     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.1       23-Apr-2009   Luis mazuera     added date columns        |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT 
   lookup_code   id,
   meaning       value,
   to_number(substr(tag,1,instr(tag,'-',1,1)-1)) low_val,
   to_number(substr(tag,instr(tag,'-',1,1)+1)) high_val,
   sysdate - to_number(substr(tag,1,instr(tag,'-',1,1)-1)) low_val_date,
   sysdate - to_number(substr(tag,instr(tag,'-',1,1)+1)) high_val_date
FROM
   apps.fnd_lookup_values 
WHERE
    lookup_type = 'XXBI_LEAD_AGE_BUCKET'
AND nvl(enabled_flag,'N') = 'Y'
AND sysdate between nvl(start_date_active,sysdate-1) and nvl(end_date_active,sysdate+1);
/
SHOW ERRORS;
EXIT; 