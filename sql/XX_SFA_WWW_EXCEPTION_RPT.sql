-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_SFA_WWW_EXCEPTION_RPT.sql                        |
-- | Description      :I2043 Leads_from_WWW_and_Jmillennia                 |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      15-Feb-2008 David Woods        Initial version                |
-- +=======================================================================+

SET LINESIZE 132
SET PAGESIZE 999
SET HEAD ON
COL EXCEPTION_ID	         HEA 'EXCEPTION|ID'
COL SOURCE_SYSTEM_REF	 FOR A10 HEA 'SOURCE|SYSTEM REF'
COL LOAD_DATE            FOR A09 HEA 'LOAD DATE'
COL STAGING_TABLE_NAME	 FOR A25 HEA 'TABLE|NAME'
COL STAGING_COLUMN_NAME  FOR A20 HEA 'COLUMN|NAME'
COL STAGING_COLUMN_VALUE FOR A10 HEA 'COLUMN|VALUE'
COL ORACLE_ERROR_MSG     FOR A40 HEA 'ERROR MESSAGE'
COL BATCH_ID           NEW_VALUE BATCHID     noprint
COL SOURCE_SYSTEM_CODE NEW_VALUE SYSTEM_CODE noprint
COL LOG_DATE           NEW_VALUE LOGDATE     noprint
COL PACKAGE_NAME       NEW_VALUE PACK_NAME   noprint
COL PROCEDURE_NAME     NEW_VALUE PROC_NAME   noprint

Break on report

Ttitle left -
'Batch ID: '  BATCHID skip 1 -
'System code: ' SYSTEM_CODE skip 1 -
'log date: ' LOGDATE skip 1 -
'package name: ' PACK_NAME skip 1 -
'procedure name: ' PROC_NAME skip 2

Select BATCH_ID       
      ,SOURCE_SYSTEM_CODE 
      ,LOG_DATE        
      ,PACKAGE_NAME      
      ,PROCEDURE_NAME  
      ,EXCEPTION_ID	
      ,SOURCE_SYSTEM_REF
      ,LOAD_DATE
      ,STAGING_TABLE_NAME	
      ,STAGING_COLUMN_NAME
      ,STAGING_COLUMN_VALUE	
      ,ORACLE_ERROR_MSG
from XXCRM.XX_SFA_WWW_VALIDATE_EXCEPTIONS
order by SOURCE_SYSTEM_REF;
