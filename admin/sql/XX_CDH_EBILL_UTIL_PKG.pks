SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- XX_CDH_EBILL_UTIL_PKG.pks
CREATE OR REPLACE PACKAGE XX_CDH_EBILL_UTIL_PKG

 -- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- |                         WIPRO/Office Depot                                |
  -- +===========================================================================+
  -- | Name        : XX_CDH_EBILL_UTIL_PKG                                         |
  -- | Description :                                                             |
  -- | This package provides utility procedures for ebilling.                    |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author        Remarks                                 |
  -- |======== =========== ============= ========================================|
  -- |DRAFT 1A 17-MAY-2010 Lokesh        Initial draft version                   |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- +===========================================================================+

AS


  FUNCTION getApplicationName(Appl_id number)
    RETURN varchar2;
    
    
  FUNCTION getUserName(User_id1 number)
    RETURN varchar2;
    
  FUNCTION getRespName(resp_id number)
    RETURN varchar2;
    
  FUNCTION getParamValue(paramName varchar2)
    RETURN varchar2; 
  
  FUNCTION getParamDesc(parameter_name VARCHAR2)
    RETURN VARCHAR2;  
    
    
 END XX_CDH_EBILL_UTIL_PKG;

/ 
SHOW ERRORS;