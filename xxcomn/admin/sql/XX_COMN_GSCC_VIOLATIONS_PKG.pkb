SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_COMN_GSCC_VIOLATIONS_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_COMN_GSCC_VIOLATIONS_PKG                                                      |
  -- |                                                                                            |
  -- |  Description:  Package created to provide GSCC Violations in Database Objects              |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         10/02/2018   Havish Kasina    Initial version                                  |
  -- +============================================================================================+
  
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  afterReport                                                                      |
  -- |                                                                                            |
  -- |  Description:  Common Report for XML bursting                                              |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  
FUNCTION beforeReport RETURN BOOLEAN
IS
BEGIN
   RETURN TRUE;
END beforeReport;

FUNCTION afterReport RETURN BOOLEAN
IS
  ln_request_id        NUMBER := 0;
  ln_count             NUMBER := 0;
BEGIN

  -- To get the GSCC Violations count
    SELECT  COUNT(1)
	  INTO  ln_count
      FROM  dba_dependencies dep
           ,dba_tables tab
     WHERE dep.referenced_type = 'TABLE'
       AND dep.referenced_owner IN ( SELECT oracle_username 
			                           FROM fnd_oracle_userid
                                      WHERE read_only_flag in ('A', 'B', 'E') )
       AND dep.owner IN ( SELECT oracle_username 
			                FROM fnd_oracle_userid
                           WHERE read_only_flag IN ('A', 'B', 'C', 'E', 'U') )
       AND NOT dep.referenced_name LIKE 'AQ$%'
       AND NOT dep.type IN ('UNDEFINED', 'SYNONYM')
       AND NOT ( dep.type = 'MATERIALIZED VIEW' AND EXISTS ( SELECT null 
			                                                   FROM dba_users
                                                               WHERE username = user
                                                                 AND editions_enabled = 'Y' ) )
       AND NOT ( dep.type = 'VIEW' 
			    AND dep.owner = dep.referenced_owner 
				AND dep.name  = substrb(dep.referenced_name, 1, 29)||'#' )
       AND NOT ( dep.type = 'TRIGGER' AND ( NOT EXISTS ( SELECT null 
			                                               FROM dba_editioning_views ev
                                                          WHERE ev.owner     = dep.referenced_owner
                                                            AND ev.view_name = substrb(dep.referenced_name, 1, 29)||'#' ) 
															OR (dep.owner, dep.name) IN ( SELECT owner, trigger_name 
															                                FROM dba_triggers
                                                                                           WHERE crossedition <> 'NO'
                                                                                              OR trigger_name like '%_WHO'
                                                                                              OR trigger_name like 'DR$%') ) )
       AND NOT EXISTS ( SELECT null 
			              FROM dba_queue_tables qt
                         WHERE qt.owner = dep.referenced_owner
                           AND qt.queue_table = dep.referenced_name )
       AND tab.owner = dep.referenced_owner
       AND tab.table_name = dep.referenced_name
       AND tab.temporary = 'N'
       AND tab.secondary = 'N'
       AND tab.iot_type IS null
       AND EXISTS ( SELECT null 
			          FROM user_synonyms
                     WHERE table_owner = dep.referenced_owner
                       AND table_name IN (dep.referenced_name, substrb(dep.referenced_name, 1, 29)||'#' ) );
		   
  P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
  fnd_file.put_line(fnd_file.log, 'OD: GSCC Violations Report for Database Objects Request ID: '||P_CONC_REQUEST_ID);
  
  IF P_CONC_REQUEST_ID > 0 AND ln_count > 0
  THEN
      fnd_file.put_line(fnd_file.log, 'Submitting : XML Publisher Report Bursting Program');
      ln_request_id := FND_REQUEST.SUBMIT_REQUEST('XDO',         --- Application short name
	                                              'XDOBURSTREP', --- Conc program short name
												  NULL, 
												  NULL, 
												  FALSE, 
												  'N', 
												  P_CONC_REQUEST_ID, 
												  'Y'
												 );
												  
	  IF ln_request_id > 0
      THEN
         COMMIT;
	     fnd_file.put_line(fnd_file.log,'Able to submit the XML Bursting Program to e-mail the output file');
      ELSE
         fnd_file.put_line(fnd_file.log,'Failed to submit the XML Bursting Program to e-mail the file - ' || SQLERRM);
      END IF;
  ELSE
      fnd_file.put_line(fnd_file.log,'Failed to submit the Report Program to generate the output file - ' || SQLERRM);
  END IF;
  RETURN(TRUE);
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Unable to submit burst request ' || SQLERRM);
END afterReport;
END XX_COMN_GSCC_VIOLATIONS_PKG;
/
SHOW ERRORS;