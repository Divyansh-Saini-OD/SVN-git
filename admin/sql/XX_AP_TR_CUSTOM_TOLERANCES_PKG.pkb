CREATE OR REPLACE PACKAGE BODY XX_AP_TR_CUSTOM_TOLERANCES_PKG
AS
  -- +=================================================================================================================+
  -- |                  OFFICE DEPOT - PROJECT SIMPLIFY                                                                |
  -- |                                                                                                                 |
  -- +=================================================================================================================+
  -- | NAME :  XX_AP_TR_CUSTOM_TOLERANCES_PKG                                                                          |
  -- | DESCRIPTION : THIS PACKAGE IS USED TO UPDATE THE XX_AP_CUSTOM_TOLERANCES TABLE WHEN SUPPLIER SITE MERGE IS DONE |
  -- |  RICE : ****                                                                                                    |
  -- |CHANGE RECORD:                                                                                                   |
  -- |===============                                                                                                  |
  -- |VERSION   DATE              AUTHOR              REMARKS                                                          |
  -- |======   ==========        =============    =======================                                              |
  -- |1.0       01-AUG-2018       VIVEK KUMAR       INITIAL VERSION                                                    |
  -- +=================================================================================================================+
  PROCEDURE CUST_TOL_UPD(
      ERRBUF OUT VARCHAR2,
      RETCODE OUT VARCHAR2,
      P_VENDOR_ID_FROM      IN NUMBER,
      P_VENDOR_SITE_ID_FROM IN NUMBER,
      P_VENDOR_ID_TO        IN NUMBER
    --P_VENDOR_SITE_ID_TO   IN NUMBER DEFAULT NULL
	)
  AS
  
 CURSOR CUR_CUST_TOL_REC
 IS
	SELECT ASSA.VENDOR_ID,
           ASSA.VENDOR_SITE_ID
    FROM AP_SUPPLIER_SITES_ALL ASSA
    WHERE ASSA.ATTRIBUTE8 LIKE 'TR%'
    AND  (ASSA.INACTIVE_DATE IS NULL OR ASSA.INACTIVE_DATE<SYSDATE)
    AND   ASSA.VENDOR_ID       = P_VENDOR_ID_TO
  --AND   ASSA.VENDOR_SITE_ID  = NVL(P_VENDOR_SITE_ID_TO,ASSA.VENDOR_SITE_ID)
    AND   ASSA.ATTRIBUTE8 NOT LIKE 'TR-RTV-ADDR%'
    AND NOT EXISTS
      (SELECT 'X'
      FROM XX_AP_CUSTOM_TOLERANCES
      WHERE SUPPLIER_SITE_ID =ASSA.VENDOR_SITE_ID
      AND SUPPLIER_ID        =ASSA.VENDOR_ID
      );
   BEGIN
	FOR SUP IN CUR_CUST_TOL_REC
    LOOP
	  UPDATE XX_AP_CUSTOM_TOLERANCES
      SET   SUPPLIER_ID        = SUP.VENDOR_ID,
            SUPPLIER_SITE_ID   = SUP.VENDOR_SITE_ID
      WHERE SUPPLIER_ID        = P_VENDOR_ID_FROM
        AND SUPPLIER_SITE_ID   = P_VENDOR_SITE_ID_FROM;
		/*NVL(P_VENDOR_SITE_ID_FROM,(SELECT VENDOR_SITE_ID FROM AP_SUPPLIER_SITES_ALL WHERE VENDOR_ID = P_VENDOR_ID_FROM AND VENDOR_SITE_CODE = 
		 (SELECT VENDOR_SITE_CODE FROM AP_SUPPLIER_SITES_ALL WHERE VENDOR_SITE_ID = SUP.VENDOR_SITE_ID))
    	);*/
      END LOOP;
	  COMMIT;
	  ---FND_FILE.PUT_LINE(FND_FILE.LOG,'SUPPLIER_ID - '|| SUP.VENDOR_ID ||'SUPPLIER_SITE_ID - '|| SUP.VENDOR_ID);
     EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR WHILE UPDATE ...'|| SQLERRM);
  END CUST_TOL_UPD;
END XX_AP_TR_CUSTOM_TOLERANCES_PKG;
/
SHOW ERRORS;