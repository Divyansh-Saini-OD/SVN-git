SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY XXFIN_PURGE_INACTIVE_CUSTOMERS
AS
  -- +============================================================================================|
  -- |                                    Office Depot                                            |
  -- +============================================================================================|
  -- |  Name:  XXFIN_PURGE_INACTIVE_CUSTOMERS                                                     |
  -- |                                                                                            |
  -- |  Description: This package is created for Purging the inactive Customers              |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         02/12/2021   Ankit Jaiswal        Initial version                              |
    -- +============================================================================================+
	
  /* **************************************************
       MAIN Procedure for Purging Inactive Customers
   *************************************************** */
  PROCEDURE PURGE_INACTIVE_CUSTOMERS(P_START_ROW_ID IN VARCHAR2							
                                    ,P_END_ROW_ID IN VARCHAR2 
									)                               
  IS
  P_INIT_MSG_LIST               VARCHAR2(200);
  P_ORIG_SYS_REFERENCE_REC      HZ_ORIG_SYSTEM_REF_PUB.ORIG_SYS_REFERENCE_REC_TYPE;
  P_OBJECT_VERSION_NUMBER       NUMBER;
  P_PARTY_OBJECT_VERSION_NUMBER NUMBER;
  X_PROFILE_ID                  NUMBER;
  X_RETURN_STATUS               VARCHAR2(200);
  X_MSG_COUNT                   NUMBER;
  X_MSG_DATA                    VARCHAR2(200);
                                
  P_ORIG_SYSTEM_REF_ID          NUMBER;
                                
  X_ORIG_SYS_REFERENCE_REC      HZ_ORIG_SYSTEM_REF_PUB.ORIG_SYS_REFERENCE_REC_TYPE;
  P_CUST_ACCOUNT_REC            HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
  P_CUST_ACCT_SITE_REC          HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
  P_CUST_SITE_USE_REC           HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
  P_ORGANIZATION_REC            HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
  P_PARTY_SITE_REC              HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
                                
  l_trx_count                   NUMBER := 0;
  CURSOR c1 
  IS
      SELECT * 
      FROM XXFIN_AOPS_PURGED_CUSTOMERS  
      WHERE 1=1
      AND ID BETWEEN P_START_ROW_ID AND P_END_ROW_ID; 

  CURSOR c2 (P_ORIG_SYSTEM_REFERENCE IN VARCHAR2)
  IS
      SELECT *
      FROM hz_orig_sys_references
      WHERE 1=1
      AND ORIG_SYSTEM_REFERENCE LIKE P_ORIG_SYSTEM_REFERENCE || '%' ;
  BEGIN
	  hz_common_pub.disable_cont_source_security;
      FOR i_rec IN c1
      LOOP
          BEGIN
              P_ORIG_SYSTEM_REF_ID          := NULL;
              P_OBJECT_VERSION_NUMBER       := NULL;
              P_PARTY_OBJECT_VERSION_NUMBER := NULL;
              X_PROFILE_ID                  := NULL;
              
              --Check if there are any open AR transactions
              SELECT COUNT(1)
              INTO l_trx_count
              FROM ar_payment_schedules_all
              WHERE 1=1
              AND TRX_DATE > SYSDATE - 7*365
              AND STATUS <> 'CL'
              AND customer_id=i_rec.cust_account_id ;     
              
              IF l_trx_count = 0 THEN
	              FOR j_rec IN c2(substr(i_rec.ORIG_SYSTEM_REFERENCE,1,8))
                  LOOP
                      IF j_rec.status = 'A' THEN
                          P_INIT_MSG_LIST := 'T';
                          X_ORIG_SYS_REFERENCE_REC.orig_system_ref_id := j_rec.ORIG_SYSTEM_REF_ID;
                          X_ORIG_SYS_REFERENCE_REC.orig_system := j_rec.orig_system;
                          X_ORIG_SYS_REFERENCE_REC.orig_system_reference := SUBSTRB(j_rec.ORIG_SYSTEM_REFERENCE 
                                                                                   ,1
                                                                                   ,INSTRB(j_rec.ORIG_SYSTEM_REFERENCE,'-')-1)
                                                                            ||'P' 
                                                                            || SUBSTRB(j_rec.ORIG_SYSTEM_REFERENCE
                                                                              , INSTRB(j_rec.ORIG_SYSTEM_REFERENCE,'-')
                                                                              , LENGTH(j_rec.ORIG_SYSTEM_REFERENCE)
                                                                                      );  
                          X_ORIG_SYS_REFERENCE_REC.owner_table_name := j_rec.OWNER_TABLE_NAME;
                          X_ORIG_SYS_REFERENCE_REC.owner_table_id := j_rec.owner_table_id;
                          X_ORIG_SYS_REFERENCE_REC.old_orig_system_reference := j_rec.ORIG_SYSTEM_REFERENCE;  
                          X_ORIG_SYS_REFERENCE_REC.start_date_active := j_rec.creation_date;						  
                          X_ORIG_SYS_REFERENCE_REC.end_date_active := SYSDATE;
                          X_ORIG_SYS_REFERENCE_REC.status := 'I';
                          P_OBJECT_VERSION_NUMBER := j_rec.OBJECT_VERSION_NUMBER;
                          X_ORIG_SYS_REFERENCE_REC.created_by_module := j_rec.created_by_module;
                    
                          HZ_ORIG_SYSTEM_REF_PUB.UPDATE_ORIG_SYSTEM_REFERENCE(
                            P_INIT_MSG_LIST          => P_INIT_MSG_LIST,
                            P_ORIG_SYS_REFERENCE_REC => X_ORIG_SYS_REFERENCE_REC,
                            P_OBJECT_VERSION_NUMBER  => P_OBJECT_VERSION_NUMBER,
                            X_RETURN_STATUS          => X_RETURN_STATUS,
                            X_MSG_COUNT              => X_MSG_COUNT,
                            X_MSG_DATA               => X_MSG_DATA
                          );
                
                      ELSE
                          UPDATE hz_orig_sys_references 
                          SET ORIG_SYSTEM_REFERENCE=X_ORIG_SYS_REFERENCE_REC.orig_system_reference,
						      status='I',
						      end_date_active=SYSDATE 
                          WHERE orig_system_ref_id=j_rec.orig_system_ref_id;     
                      END IF;              
                      IF (j_rec.OWNER_TABLE_NAME = 'HZ_CUST_ACCOUNTS') THEN
	          	        UPDATE HZ_CUST_ACCOUNTS
						SET orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference,
       						status='I' 
						WHERE cust_account_id=j_rec.owner_table_id;
	          			
                      ELSIF(j_rec.OWNER_TABLE_NAME = 'HZ_PARTIES') THEN               
                          UPDATE HZ_PARTIES 
						  SET orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference, 
						      status='I'
						  WHERE party_id=j_rec.owner_table_id;
	          	       
                      ELSIF(j_rec.OWNER_TABLE_NAME = 'HZ_PARTY_SITES') THEN
                          UPDATE HZ_PARTY_SITES 
						  SET orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference,
     						  status='I'
                          WHERE party_site_id=j_rec.owner_table_id;	   
                  
                      ELSIF(j_rec.OWNER_TABLE_NAME = 'HZ_CUST_ACCT_SITES_ALL') THEN  
                          UPDATE HZ_CUST_ACCT_SITES_ALL 
						  SET orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference, 
						      status='I' 
						  WHERE cust_acct_site_id=j_rec.owner_table_id;	 
						  
                       --Update account site OSR in XX_EXTERNAL_USERS with P at the end of AOPS cust ID e.g. 10010001P-00001-A0
                          UPDATE XX_EXTERNAL_USERS
                          SET ACCT_SITE_OSR  = X_ORIG_SYS_REFERENCE_REC.orig_system_reference
                          WHERE ACCT_SITE_OSR    =j_rec.orig_system_reference;						  
                
                      ELSIF(j_rec.OWNER_TABLE_NAME = 'HZ_CUST_SITE_USES_ALL') THEN     
                          IF (INSTR(j_rec.orig_system_reference,'SHIP_TO')>0) THEN
                              UPDATE HZ_CUST_SITE_USES_ALL 
							  SET orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference,
							      status='I' 
							  WHERE site_use_id=j_rec.owner_table_id;		
                          END IF;   
                
                          IF (INSTR(j_rec.orig_system_reference,'BILL_TO')>0) THEN	
                              UPDATE HZ_CUST_SITE_USES_ALL 
							  SET orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference, 
							      status='I' 
							  WHERE site_use_id=j_rec.owner_table_id;
                          END IF;                     
                      END IF;                     					  
                  END LOOP;
                  UPDATE XXFIN_AOPS_PURGED_CUSTOMERS
                  SET purge_status            ='Y',
                      purged_date               =SYSDATE
                  WHERE orig_system_reference = i_rec.ORIG_SYSTEM_REFERENCE;
                ELSE
                  UPDATE XXFIN_AOPS_PURGED_CUSTOMERS
                  SET purge_status            ='N',
                      purged_date               =SYSDATE
                  WHERE orig_system_reference = i_rec.ORIG_SYSTEM_REFERENCE;
                 END IF;
               EXCEPTION
               WHEN OTHERS THEN
                  UPDATE XXFIN_AOPS_PURGED_CUSTOMERS
                  SET purge_status            ='N',
                      purged_date               =SYSDATE
                  WHERE orig_system_reference = i_rec.ORIG_SYSTEM_REFERENCE;
    END;
  END LOOP;
  hz_common_pub.enable_cont_source_security;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.LOG,'Exception:- '||SQLERRM);
END PURGE_INACTIVE_CUSTOMERS;
END XXFIN_PURGE_INACTIVE_CUSTOMERS;                
/
show error;