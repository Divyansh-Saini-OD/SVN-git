SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +==========================================================================+
-- |                  Office Depot - Project Optimize                         |
-- |                       CompuCom-OfficeDepot	                              |
-- +==========================================================================+
-- | Script to create the Database Directory path                             |
-- | File  : XXFIN_IMS_GL_DB_DIR_CREATION.prc                              	  |
-- |                      												      |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     07-Apr-2021  Amit Kumar	        Initial version               |
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
  l_str := 'CREATE DIRECTORY XXFIN_IMS_GL_IN AS '''||lc_dba_path ||'ftp/in/gl'''; 
  execute immediate l_str;
  
  l_str_arc := 'CREATE DIRECTORY XXFIN_IMS_GL_ARCHIVE AS '''||lc_dba_path ||'archive/inbound'''; 
  execute immediate l_str_arc;
  
EXCEPTION
WHEN OTHERS THEN
  NULL;
end; 
/