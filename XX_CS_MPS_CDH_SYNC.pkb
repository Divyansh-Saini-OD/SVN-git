Create or Replace
PACKAGE BODY XX_CS_MPS_CDH_SYNC AS
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- +=========================================================================================+
-- | Name    : XX_CS_MPS_CDH_SYNC                                                            |
-- |                                                                                         |
-- | Description      : Customer SHIP TO updates                                             |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |1.0       20-MAR-13        Raj Jagarlamudi        Initial draft version                  |
-- |2.0       28-MAY-14        Arun Gannarapu         added logic to set the date            |
-- |                                                  seq_update_date defect 27293           |
-- |3.0       03-NOV-15        Havish Kasina          Removed the schema references in the   |
-- |                                                  existing code as per R12.2 Retrofit    |
-- |4.0       18-JAN-17		   Poonam Gupta			  Defect#40649 - Added variable clearing |
-- |												  for loop, derive shipto exception      |
-- |												  capture in logs	
-- | 5.0      06-JUN-18        Veera Reddy			  Defect#42090 -(Unable to Sync the      |
-- |                                                  Customer address for some of the 
-- |												  Devices) Increased size of substr      |
-- |                                                  size from 1,10 to 1,45 in Procedures   |
-- |                                                  ADD_SHIP_TO and UPDATE_SHIP_TO 	     |
-- +=========================================================================================+

gc_err_msg      varchar2(2000);

PROCEDURE Log_Exception ( p_error_location     IN  VARCHAR2
                         ,p_error_message_code IN  VARCHAR2
                         ,p_error_msg          IN  VARCHAR2
                         ,p_object_id          IN  VARCHAR2)
IS

  ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error
     (
      p_return_code             => FND_API.G_RET_STS_ERROR
     ,p_msg_count               => 1
     ,p_application_name        => 'XX_CRM'
     ,p_program_type            => 'Customer Support Custom Events'
     ,p_program_name            => 'XX_CS_CUSTOM_EVENT_PKG'
     ,p_program_id              => P_OBJECT_ID
     ,p_module_name             => 'MPS'
     ,p_error_location          => p_error_location
     ,p_error_message_code      => p_error_message_code
     ,p_error_message           => p_error_msg
     ,p_error_message_severity  => 'MAJOR'
     ,p_error_status            => 'ACTIVE'
     ,p_created_by              => ln_user_id
     ,p_last_updated_by         => ln_user_id
     ,p_last_update_login       => ln_login
     );

END Log_Exception;
/******************************************************************************/
PROCEDURE ADD_SHIP_TO AS
CURSOR C1 IS
SELECT DISTINCT ROWID,
                PARTY_ID,
                SITE_ADDRESS_1,
                SITE_ADDRESS_2,
                SITE_CITY,
                SITE_STATE,
                SITE_ZIP_CODE
FROM XX_CS_MPS_DEVICE_B
WHERE SHIP_SITE_ID IS NULL
AND SITE_ADDRESS_1 IS NOT NULL;

C1_REC            C1%ROWTYPE;
LN_SHIP_SITE_ID   NUMBER;
LC_SHIP_SEQ       VARCHAR2(5);

BEGIN
    BEGIN
      OPEN C1;
      LOOP
      FETCH C1 INTO C1_REC;
      EXIT WHEN C1%NOTFOUND;

       BEGIN
		 LN_SHIP_SITE_ID := NULL; 	-- Added for Defect#40649
		 LC_SHIP_SEQ := NULL;  		-- Added for Defect#40649
         SELECT  DISTINCT HCS.SITE_USE_ID ,
                SUBSTR(HCSA.ORIG_SYSTEM_REFERENCE,10,5)
          INTO LN_SHIP_SITE_ID, LC_SHIP_SEQ
          FROM HZ_CUST_ACCOUNTS HCA
             , HZ_CUST_SITE_USES_ALL HCS
             , HZ_CUST_ACCT_SITES_ALL HCSA
             , HZ_PARTY_SITES HPS
             , HZ_LOCATIONS HL
         WHERE HCA.PARTY_ID                  = C1_REC.PARTY_ID
           AND HCA.CUST_ACCOUNT_ID           = HCSA.CUST_ACCOUNT_ID
           AND HCSA.CUST_ACCT_SITE_ID        = HCS.CUST_ACCT_SITE_ID
           AND HCSA.PARTY_SITE_ID            = HPS.PARTY_SITE_ID
           AND HPS.LOCATION_ID               = HL.LOCATION_ID
          AND HCS.STATUS                     = 'A'
           AND HCS.SITE_USE_CODE             = 'SHIP_TO'
           AND SUBSTR(HZ_TRANS_PKG.WRAddress_Cleanse(HL.ADDRESS1,'US','Address','Address','STAGE'),1,45) =
             SUBSTR(HZ_TRANS_PKG.WRAddress_Cleanse(C1_REC.SITE_ADDRESS_1,'US','Address','Address','STAGE'),1,45)
            AND SUBSTR(HZ_TRANS_PKG.WRAddress_Cleanse(HL.ADDRESS2,'US','Address','Address','STAGE'),1,45) =
             SUBSTR(HZ_TRANS_PKG.WRAddress_Cleanse(C1_REC.SITE_ADDRESS_2,'US','Address','Address','STAGE'),1,45)
           AND UPPER(HL.CITY)   = UPPER(C1_REC.SITE_CITY)
           AND UPPER(HL.STATE)  = UPPER(C1_REC.SITE_STATE)
           AND SUBSTR(HL.POSTAL_CODE,1,5) = SUBSTR(C1_REC.SITE_ZIP_CODE,1,5)
           AND HCSA.ORIG_SYSTEM_REFERENCE NOT LIKE '%00001-A0'
           AND ROWNUM < 2;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
		     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error ADDING SHIP-TO-SEQ - No Data Found in XX_CS_MPS_CDH_SYNC.ADD_SHIP_TO - Major Block FOR PARTY :'||C1_REC.PARTY_ID||', ADDRESS :'||c1_rec.site_address_1); -- Added for Defect #40649
            -- SELECT WITHOUT ADDRESS2
             BEGIN
                SELECT  DISTINCT HCS.SITE_USE_ID,
                 SUBSTR(HCSA.ORIG_SYSTEM_REFERENCE,10,5)
                  INTO LN_SHIP_SITE_ID, LC_SHIP_SEQ
                  FROM HZ_CUST_ACCOUNTS HCA
                     , HZ_CUST_SITE_USES_ALL HCS
                     , HZ_CUST_ACCT_SITES_ALL HCSA
                     , HZ_PARTY_SITES HPS
                     , HZ_LOCATIONS HL
                 WHERE HCA.PARTY_ID                  = C1_REC.PARTY_ID
                   AND HCA.CUST_ACCOUNT_ID           = HCSA.CUST_ACCOUNT_ID
                   AND HCSA.CUST_ACCT_SITE_ID        = HCS.CUST_ACCT_SITE_ID
                   AND HCSA.PARTY_SITE_ID            = HPS.PARTY_SITE_ID
                   AND HPS.LOCATION_ID               = HL.LOCATION_ID
                  AND HCS.STATUS                     = 'A'
                   AND HCS.SITE_USE_CODE             = 'SHIP_TO'
                   AND SUBSTR(HZ_TRANS_PKG.WRAddress_Cleanse(HL.ADDRESS1,'US','Address','Address','STAGE'),1,45) =
                     SUBSTR(HZ_TRANS_PKG.WRAddress_Cleanse(C1_REC.SITE_ADDRESS_1,'US','Address','Address','STAGE'),1,45)
                   AND UPPER(HL.CITY)   = UPPER(C1_REC.SITE_CITY)
                   AND UPPER(HL.STATE)  = UPPER(C1_REC.SITE_STATE)
                   AND SUBSTR(HL.POSTAL_CODE,1,5) = SUBSTR(C1_REC.SITE_ZIP_CODE,1,5)
                   AND HCSA.ORIG_SYSTEM_REFERENCE NOT LIKE '%00001-A0'
                   AND ROWNUM < 2;
              EXCEPTION
				WHEN NO_DATA_FOUND THEN
				FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error ADDING SHIP-TO-SEQ - No Data Found in XX_CS_MPS_CDH_SYNC.ADD_SHIP_TO - Minor Block FOR PARTY :'||C1_REC.PARTY_ID||', ADDRESS :'||c1_rec.site_address_1); -- Added for Defect #40649
				FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----------------------------------------'); -- Added for Defect#40649
                WHEN OTHERS THEN
				 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error ADDING SHIP-TO-SEQ - When Others - in XX_CS_MPS_CDH_SYNC.ADD_SHIP_TO - Minor Block FOR PARTY :'||C1_REC.PARTY_ID||', ADDRESS :'||c1_rec.site_address_1||chr(10)||'Error :'||SQLERRM); -- Added for Defect#40649
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----------------------------------------'); -- Added for Defect#40649
				 gc_err_msg    := 'error selecting ship-to for party '||c1_rec.party_id||' address '||c1_rec.site_address_1;
                 Log_Exception ( p_error_location     =>  'XX_CS_MPS_CDH_SYNC.ADD_SHIP_TO'
                                ,p_error_message_code =>   'XX_CS_0001_UNEXPECTED_ERR'
                                ,p_error_msg          =>  gc_err_msg
                                ,p_object_id          => c1_rec.Party_id);
              END;
          WHEN OTHERS THEN
				FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error ADDING SHIP-TO-SEQ - When Others - in XX_CS_MPS_CDH_SYNC.ADD_SHIP_TO - Major Block FOR PARTY :'||C1_REC.PARTY_ID||', ADDRESS :'||c1_rec.site_address_1||chr(10)||'Error :'||SQLERRM); -- Added for Defect#40649
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----------------------------------------'); -- Added for Defect#40649
			   -- FND_FILE.PUT_LINE(FND_FILE.LOG,'Error UPDATING SHIP-TO-SEQ FOR ADDRESS '||c1_rec.site_address_1);
                gc_err_msg    := 'error selecting ship-to for party '||c1_rec.party_id||' address '||c1_rec.site_address_1;
                 Log_Exception ( p_error_location     =>  'XX_CS_MPS_CDH_SYNC.ADD_SHIP_TO'
                                ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                                ,p_error_msg          =>  gc_err_msg
                                ,p_object_id          => c1_rec.Party_id);
          END;
		  --- Added for Defect#40649 - START
		  IF (LN_SHIP_SITE_ID IS NULL OR LC_SHIP_SEQ IS NULL) THEN
			FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to ADD SHIP-TO-SEQ for PARTY :'||C1_REC.PARTY_ID||', ADDRESS :'||c1_rec.site_address_1 ||'. Please check output for details.'); -- Added for Defect#40649
		  END IF;
		  --- Added for Defect#40649 - END
          IF LN_SHIP_SITE_ID IS NOT NULL THEN
            BEGIN
              UPDATE XX_CS_MPS_DEVICE_B
              SET SHIP_SITE_ID = LN_SHIP_SITE_ID,
                  ATTRIBUTE5 = LC_SHIP_SEQ,
                  seq_update_date  = SYSDATE
              WHERE ROWID = C1_REC.ROWID;
			  --
              COMMIT;
            EXCEPTION
               WHEN OTHERS THEN
                 gc_err_msg    := 'error while updating shipto '||c1_rec.party_id||' address '||c1_rec.site_address_1;
                 Log_Exception ( p_error_location     =>  'XX_CS_MPS_CDH_SYNC.ADD_SHIP_TO'
                                ,p_error_message_code =>   'XX_CS_0003_UNEXPECTED_ERR'
                                ,p_error_msg          =>  gc_err_msg
                                ,p_object_id          => c1_rec.Party_id);
            END;
		  END IF;
      END LOOP;
      CLOSE C1;
    END;
END ADD_SHIP_TO;

/*****************************************************************************/
  PROCEDURE UPDATE_SHIP_TO AS

  CURSOR C1 IS
  SELECT  DISTINCT MB.PARTY_ID,
          MB.SHIP_SITE_ID,
          MB.SITE_ADDRESS_1,
          MB.SITE_ADDRESS_2,
          MB.SITE_CITY,
          MB.SITE_STATE,
          MB.SITE_ZIP_CODE
   FROM HZ_CUST_ACCOUNTS HCA
        , HZ_CUST_SITE_USES_ALL HCS
        , HZ_CUST_ACCT_SITES_ALL HCSA
        , XX_CS_MPS_DEVICE_B MB
  WHERE HCA.PARTY_ID                  = MB.PARTY_ID
    AND HCA.CUST_ACCOUNT_ID           = HCSA.CUST_ACCOUNT_ID
    AND HCSA.CUST_ACCT_SITE_ID        = HCS.CUST_ACCT_SITE_ID
    AND HCS.STATUS                    <> 'A'
    AND HCS.SITE_USE_CODE             = 'SHIP_TO'
    AND HCS.SITE_USE_ID               = MB.SHIP_SITE_ID
    AND MB.SHIP_SITE_ID IS NOT NULL;

    C1_REC  C1%ROWTYPE;
    LN_SHIP_SITE_ID   NUMBER;
    LC_SHIP_SEQ       VARCHAR2(5);

   BEGIN
      OPEN C1;
      LOOP
      FETCH C1 INTO C1_REC;
      EXIT WHEN C1%NOTFOUND;

       BEGIN
	     LN_SHIP_SITE_ID := NULL ;    -- Added for Defect#40649
		 LC_SHIP_SEQ := NULL;		  -- Added for Defect#40649
         SELECT  DISTINCT HCS.SITE_USE_ID ,
                SUBSTR(HCSA.ORIG_SYSTEM_REFERENCE,10,5)
          INTO LN_SHIP_SITE_ID, LC_SHIP_SEQ
          FROM HZ_CUST_ACCOUNTS HCA
             , HZ_CUST_SITE_USES_ALL HCS
             , HZ_CUST_ACCT_SITES_ALL HCSA
             , HZ_PARTY_SITES HPS
             , HZ_LOCATIONS HL
         WHERE HCA.PARTY_ID                  = C1_REC.PARTY_ID
           AND HCA.CUST_ACCOUNT_ID           = HCSA.CUST_ACCOUNT_ID
           AND HCSA.CUST_ACCT_SITE_ID        = HCS.CUST_ACCT_SITE_ID
           AND HCSA.PARTY_SITE_ID            = HPS.PARTY_SITE_ID
           AND HPS.LOCATION_ID               = HL.LOCATION_ID
          AND HCS.STATUS                     = 'A'
           AND HCS.SITE_USE_CODE             = 'SHIP_TO'
          AND SUBSTR(HZ_TRANS_PKG.WRAddress_Cleanse(HL.ADDRESS1,'US','Address','Address','STAGE'),1,45) =
             SUBSTR(HZ_TRANS_PKG.WRAddress_Cleanse(C1_REC.SITE_ADDRESS_1,'US','Address','Address','STAGE'),1,45)
           AND SUBSTR(HZ_TRANS_PKG.WRAddress_Cleanse(HL.ADDRESS2,'US','Address','Address','STAGE'),1,45) =
             SUBSTR(HZ_TRANS_PKG.WRAddress_Cleanse(C1_REC.SITE_ADDRESS_2,'US','Address','Address','STAGE'),1,45)
           AND UPPER(HL.CITY)   = UPPER(C1_REC.SITE_CITY)
           AND UPPER(HL.STATE)  = UPPER(C1_REC.SITE_STATE)
           AND SUBSTR(HL.POSTAL_CODE,1,5) = SUBSTR(C1_REC.SITE_ZIP_CODE,1,5)
           AND HCSA.ORIG_SYSTEM_REFERENCE NOT LIKE '%00001-A0'
           AND ROWNUM < 2;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
		     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error UPDATING SHIP-TO-SEQ - No Data Found in XX_CS_MPS_CDH_SYNC.UPDATE_SHIP_TO - Major Block FOR PARTY :'||C1_REC.PARTY_ID||', ADDRESS :'||c1_rec.site_address_1); -- Added for Defect #40649
           -- SELECT WITHOUT ADDRESS2
             BEGIN
                SELECT  DISTINCT HCS.SITE_USE_ID ,
                SUBSTR(HCSA.ORIG_SYSTEM_REFERENCE,10,5)
                  INTO LN_SHIP_SITE_ID, LC_SHIP_SEQ
                  FROM HZ_CUST_ACCOUNTS HCA
                     , HZ_CUST_SITE_USES_ALL HCS
                     , HZ_CUST_ACCT_SITES_ALL HCSA
                     , HZ_PARTY_SITES HPS
                     , HZ_LOCATIONS HL
                 WHERE HCA.PARTY_ID                  = C1_REC.PARTY_ID
                   AND HCA.CUST_ACCOUNT_ID           = HCSA.CUST_ACCOUNT_ID
                   AND HCSA.CUST_ACCT_SITE_ID        = HCS.CUST_ACCT_SITE_ID
                   AND HCSA.PARTY_SITE_ID            = HPS.PARTY_SITE_ID
                   AND HPS.LOCATION_ID               = HL.LOCATION_ID
                  AND HCS.STATUS                     = 'A'
                   AND HCS.SITE_USE_CODE             = 'SHIP_TO'
                  AND SUBSTR(HZ_TRANS_PKG.WRAddress_Cleanse(HL.ADDRESS1,'US','Address','Address','STAGE'),1,45) =
                     SUBSTR(HZ_TRANS_PKG.WRAddress_Cleanse(C1_REC.SITE_ADDRESS_1,'US','Address','Address','STAGE'),1,45)
                   AND UPPER(HL.CITY)   = UPPER(C1_REC.SITE_CITY)
                   AND UPPER(HL.STATE)  = UPPER(C1_REC.SITE_STATE)
                   AND SUBSTR(HL.POSTAL_CODE,1,5) = SUBSTR(C1_REC.SITE_ZIP_CODE,1,5)
                   AND HCSA.ORIG_SYSTEM_REFERENCE NOT LIKE '%00001-A0'
                   AND ROWNUM < 2;
				 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----------------------------------------'); -- Added for Defect#40649
              EXCEPTION
                 WHEN NO_DATA_FOUND THEN
				 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error UPDATING SHIP-TO-SEQ - No Data Found in XX_CS_MPS_CDH_SYNC.UPDATE_SHIP_TO - Minor Block FOR PARTY :'||C1_REC.PARTY_ID||', ADDRESS :'||c1_rec.site_address_1); -- Added for Defect#40649
                 WHEN OTHERS THEN
				 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error UPDATING SHIP-TO-SEQ - When Others - in XX_CS_MPS_CDH_SYNC.UPDATE_SHIP_TO - Minor Block FOR PARTY :'||C1_REC.PARTY_ID||', ADDRESS :'||c1_rec.site_address_1||chr(10)||'Error :'||SQLERRM); -- Added for Defect#40649
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----------------------------------------'); -- Added for Defect#40649
				 gc_err_msg    := 'error selecting ship-to for party '||c1_rec.party_id||' address '||c1_rec.site_address_1;
                                
                  Log_Exception ( p_error_location     =>  'XX_CS_MPS_CDH_SYNC.UPDATE_SHIP_TO'
                                ,p_error_message_code =>   'XX_CS_0001_UNEXPECTED_ERR'
                                ,p_error_msg          =>  gc_err_msg
                                ,p_object_id          => c1_rec.Party_id);
              END;
          WHEN OTHERS THEN
				FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error UPDATING SHIP-TO-SEQ - When Others - in XX_CS_MPS_CDH_SYNC.UPDATE_SHIP_TO - Major Block FOR PARTY :'||C1_REC.PARTY_ID||', ADDRESS :'||c1_rec.site_address_1||chr(10)||'Error :'||SQLERRM); -- Added for Defect#40649
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----------------------------------------'); -- Added for Defect#40649
              -- FND_FILE.PUT_LINE(FND_FILE.LOG,'Error UPDATING SHIP-TO-SEQ FOR ADDRESS '||c1_rec.site_address_1);
                 gc_err_msg    := 'error selecting ship-to for party '||c1_rec.party_id||' address '||c1_rec.site_address_1;
                  Log_Exception ( p_error_location     =>  'XX_CS_MPS_CDH_SYNC.UPDATE_SHIP_TO'
                                ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                                ,p_error_msg          =>  gc_err_msg
                                ,p_object_id          => c1_rec.Party_id);
          END;
		  --- Added for Defect#40649 - START
		  IF (LN_SHIP_SITE_ID IS NULL OR LC_SHIP_SEQ IS NULL) THEN
			FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to UPDATE SHIP-TO-SEQ for PARTY :'||C1_REC.PARTY_ID||', ADDRESS :'||c1_rec.site_address_1 ||'. Please check output for details.'); -- Added for Defect#40649
		  END IF;
		  --- Added for Defect#40649 - END
          IF LN_SHIP_SITE_ID IS NOT NULL THEN
            BEGIN
              UPDATE XX_CS_MPS_DEVICE_B
              SET SHIP_SITE_ID = LN_SHIP_SITE_ID,
                  ATTRIBUTE5 = LC_SHIP_SEQ,
                  seq_update_date = SYSDATE
              WHERE SHIP_SITE_ID = C1_REC.SHIP_SITE_ID;

              COMMIT;
            EXCEPTION
               WHEN OTHERS THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Error UPDATING SHIP-TO-SEQ FOR ADDRESS '||c1_rec.site_address_1);
                  gc_err_msg    := 'error UPDATING ship-to for party '||c1_rec.party_id||' address '||c1_rec.site_address_1;
                  Log_Exception ( p_error_location     =>  'XX_CS_MPS_CDH_SYNC.UPDATE_SHIP_TO'
                                ,p_error_message_code =>   'XX_CS_0003_UNEXPECTED_ERR'
                                ,p_error_msg          =>  gc_err_msg
                                ,p_object_id          => c1_rec.Party_id);
            END;
		  END IF;
      END LOOP;
      CLOSE C1;
  END UPDATE_SHIP_TO;

END XX_CS_MPS_CDH_SYNC;
/
