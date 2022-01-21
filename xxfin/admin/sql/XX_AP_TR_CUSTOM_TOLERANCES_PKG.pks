CREATE OR REPLACE PACKAGE XX_AP_TR_CUSTOM_TOLERANCES_PKG
AS
  -- +=================================================================================================================+
  -- |                  OFFICE DEPOT - PROJECT SIMPLIFY                                                                |
  -- |                                                                                                                 |
  -- +=================================================================================================================+
  -- | NAME :  XX_AP_CUSTOM_TOLERANCES.PKS                                                                             |
  -- | DESCRIPTION : THIS PACKAGE IS USED TO UDPATE THE  XX_AP_CUSTOM_TOLERANCES TABLE WHEN SUPPLIER SITE MERGE IS DONE|
  -- |  RICE : ****                                                                                                    |
  -- |CHANGE RECORD:                                                                                                   |
  -- |===============                                                                                                  |
  -- |VERSION   DATE              AUTHOR              REMARKS                                                          |
  -- |======   ==========     =============     =======================                                                |
  -- |1.0       01-AUG-2018     VIVEK KUMAR       INITIAL VERSION                                                      |
  -- +=================================================================================================================+
  PROCEDURE CUST_TOL_UPD(
                         ERRBUF OUT VARCHAR2,
                         RETCODE OUT VARCHAR2,
                         P_VENDOR_ID_FROM      IN NUMBER,
                         P_VENDOR_SITE_ID_FROM IN NUMBER,
                         P_VENDOR_ID_TO        IN NUMBER
                       --P_VENDOR_SITE_ID_TO   IN NUMBER DEFAULT NULL
					   );
END XX_AP_TR_CUSTOM_TOLERANCES_PKG;
/
SHOW ERRORS;