SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CRM_HRCRM_CM_SYNC_PKG
  -- +===================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
  -- +===================================================================================+
  -- |                                                                                   |
  -- | Name             :  XX_CRM_HRCRM_CM_SYNC_PKG                                      |
  -- | Description      :  This custom package is needed to maintain Oracle CRM resources|
  -- |                     synchronized with changes made to employees in Oracle HRMS    |
  -- |                                                                                   |
  -- |                                                                                   |
  -- |                                                                                   |
  -- | This package contains the following sub programs:                                 |
  -- | =================================================                                 |
  -- |Type         Name             Description                                          |
  -- |=========    ===========      =====================================================|
  -- |PROCEDURE    Main             This is the public procedure.The concurrent program  |
  -- |                              OD HR CRM Synchronization Program will call this     |
  -- |                              public procedure.                                    |
  -- |                                                                                   |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date        Author                       Remarks                         |
  -- |=======   ==========  ==========================   ================================|
  -- |Draft 1a  05-Sep-08   Gowri Nagarajan              Initial draft version           |
  -- +===================================================================================+

  AS

      -- +===================================================================+
      -- | Name  : MAIN                                                      |
      -- |                                                                   |
      -- | Description:       This is the public procedure.The concurrent    |
      -- |                    program OD HR CRM Synchronization Program      |
      -- |                    will call this public procedure                |
      -- |                                                                   |
      -- +===================================================================+

      PROCEDURE MAIN
                   (
                     x_errbuf           OUT   VARCHAR2
                   , x_retcode          OUT   NUMBER
                   );

  END XX_CRM_HRCRM_CM_SYNC_PKG;     /* Package Specification Ends */
/

SHOW ERRORS
EXIT;