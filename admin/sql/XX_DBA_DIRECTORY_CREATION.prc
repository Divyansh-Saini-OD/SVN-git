SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Table Script to create the following object                              |
-- |             Table  : XX_AR_OPSTECH_BILL_ALL                              |
-- |                      OPS TECH Customer Processed Information details     |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     05-SEPT-2018 Aniket Jadhav        Initial version               |
-- |                                                                          |
-- +==========================================================================+  
DECLARE
  lc_dba_path VARCHAR2(500) := NULL;
  l_str       varchar2(500) := null;
  l_str_arc    VARCHAR2(500) := NULL;
BEGIN

  SELECT '/app/ebs/ct'
    || lower(applications_system_name)
    ||'/xxfin/'
  INTO lc_dba_path
  FROM fnd_product_groups;
  --execute immediate
  l_str := 'CREATE DIRECTORY XXFIN_OPSTECH AS '''||lc_dba_path ||'outbound'''; 
  execute immediate l_str;
  
  l_str_arc := 'CREATE DIRECTORY XXFIN_OPSTECH_ARC AS '''||lc_dba_path ||'archive/outbound'''; 
  execute immediate l_str_arc;
  
EXCEPTION
WHEN OTHERS THEN
  NULL;
end; 
/