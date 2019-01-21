SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- XXOD_ACTIVATE_PARTY.pks
CREATE OR REPLACE PACKAGE XXOD_ACTIVATE_PARTY

 -- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- |                         WIPRO/Office Depot                                |
  -- +===========================================================================+
  -- | Name        : XXOD_ACTIVATE_PARTY                                         |
  -- | Description :                                                             |
  -- | This package provides api's to be run from concurrent program.            |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author        Remarks                                 |
  -- |======== =========== ============= ========================================|
  -- |DRAFT 1A 10-JUNE-2010 Lokesh        Initial draft version                  |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- +===========================================================================+

AS


  PROCEDURE UpdatePartyStatus(errbuf out VARCHAR2, retcode out NUMBER,p_update_flag varchar2);  
    
    
 END XXOD_ACTIVATE_PARTY;

/ 
SHOW ERRORS;