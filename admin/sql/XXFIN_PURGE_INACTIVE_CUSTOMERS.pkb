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
  
  --PRAGMA autonomous_transaction; --commented by Ankit
  CURSOR c1 IS
      SELECT 
	      * 
      FROM 
	      XXFIN_AOPS_PURGED_CUSTOMERS  
      WHERE  
	      1=1
          --AND    status IN ('A','N')
          --AND    purge_status = 'N'
          --AND    status='N'
          --AND    rownum < 1001
          AND ID BETWEEN P_START_ROW_ID AND P_END_ROW_ID; /* Important condition for creation of chunk through Number Column  */

  CURSOR c2 (P_ORIG_SYSTEM_REFERENCE IN VARCHAR2) IS
      SELECT 
	      *
      FROM 
          hz_orig_sys_references
      WHERE  
	      1=1
	      AND ORIG_SYSTEM_REFERENCE LIKE P_ORIG_SYSTEM_REFERENCE || '%' ;
  BEGIN
      --mo_global.init('AR');--commented as Concurrent program created 
      --mo_global.set_policy_context('S','404');
      --fnd_global.apps_initialize(58590,50658,222);--commented by Ankit
	  hz_common_pub.disable_cont_source_security;
      FOR i_rec IN c1
      LOOP
          BEGIN
              --update orig_system_references
              P_ORIG_SYSTEM_REF_ID          := NULL;
              P_OBJECT_VERSION_NUMBER       := NULL;
              P_PARTY_OBJECT_VERSION_NUMBER := NULL;
              X_PROFILE_ID                  := NULL;
              
              --Check if there are any open AR transactions
              SELECT 
	              COUNT(1)
              INTO 
	              l_trx_count
              FROM  
	              ar_payment_schedules_all
              WHERE  
	              1=1
                  AND TRX_DATE > SYSDATE - 7*365
                  AND STATUS <> 'CL'
                  AND customer_id=i_rec.cust_account_id ;     
              
              IF l_trx_count = 0 THEN
	              FOR j_rec IN c2(i_rec.ORIG_SYSTEM_REFERENCE)--Added by Ankit
                  LOOP
				      fnd_file.put_line(fnd_file.LOG,'Inside For Loop for Orig_SYstem_Reference:- '||i_rec.ORIG_SYSTEM_REFERENCE);--Added by Ankit
                      --update hz_orig_sys_references set status='A' where ORIG_SYSTEM_REF_ID=j_rec.ORIG_SYSTEM_REF_ID;
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
                          --dbms_output.put_line(sysdate || 'X_ORIG_SYS_REFERENCE_REC.orig_system_reference:' || X_ORIG_SYS_REFERENCE_REC.orig_system_reference);  
                          X_ORIG_SYS_REFERENCE_REC.owner_table_name := j_rec.OWNER_TABLE_NAME;
                          X_ORIG_SYS_REFERENCE_REC.owner_table_id := j_rec.owner_table_id;
                          X_ORIG_SYS_REFERENCE_REC.old_orig_system_reference := j_rec.ORIG_SYSTEM_REFERENCE;     
                          --X_ORIG_SYS_REFERENCE_REC.start_date_active := j_rec.creation_date;      
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
                   
                         
                          IF x_msg_count >1 THEN
                              FOR I IN 1..x_msg_count
                              LOOP
                                  --dbms_output.put_line(I||'. '||SubStr(FND_MSG_PUB.Get(p_encoded =>
                                  --                     FND_API.G_FALSE ), 1, 255));
                                  NULL;
                              END LOOP;
                          END IF;
                      ELSE
                          UPDATE hz_orig_sys_references 
                          SET ORIG_SYSTEM_REFERENCE=X_ORIG_SYS_REFERENCE_REC.orig_system_reference, status='I', end_date_active=SYSDATE 
                          WHERE orig_system_ref_id=j_rec.orig_system_ref_id;     
                      END IF;  
                      
                      IF (j_rec.OWNER_TABLE_NAME = 'HZ_CUST_ACCOUNTS') THEN
                          --Inactivate account--Added by Ankit attribute1
	          	        UPDATE HZ_CUST_ACCOUNTS SET orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference, status='I' WHERE cust_account_id=j_rec.owner_table_id;
	          			
                      ELSIF(j_rec.OWNER_TABLE_NAME = 'HZ_PARTIES') THEN               
                          --Inactivate Party
                          UPDATE HZ_PARTIES SET orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference, status='I' WHERE party_id=j_rec.owner_table_id;
	          	       
                      ELSIF(j_rec.OWNER_TABLE_NAME = 'HZ_PARTY_SITES') THEN
                          --Inactivate Party Sites
                          UPDATE HZ_PARTY_SITES SET orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference, status='I' --last_update_by
                          WHERE party_site_id=j_rec.owner_table_id;	   
                  
                      ELSIF(j_rec.OWNER_TABLE_NAME = 'HZ_CUST_ACCT_SITES_ALL') THEN
                          --Inactivate account site	  
                          UPDATE HZ_CUST_ACCT_SITES_ALL SET orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference, status='I' WHERE cust_acct_site_id=j_rec.owner_table_id;	   
                
                      ELSIF(j_rec.OWNER_TABLE_NAME = 'HZ_CUST_SITE_USES_ALL') THEN
                          --Inactivate two site uses       
                          IF (INSTR(j_rec.orig_system_reference,'SHIP_TO')>0) THEN
                              UPDATE HZ_CUST_SITE_USES_ALL SET orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference, status='I' WHERE site_use_id=j_rec.owner_table_id;		
                          END IF;   
                
                          IF (INSTR(j_rec.orig_system_reference,'BILL_TO')>0) THEN	
                              UPDATE HZ_CUST_SITE_USES_ALL SET orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference, status='I' WHERE site_use_id=j_rec.owner_table_id;
                          END IF;                     
                      --Check for XX_EXTERNAL_USERS table--To be checked
                      END IF;
                      					  
                  END LOOP;
                --update the purge_status and altered the table name and purge_status to status--Added by Ankit	  
	              UPDATE XXFIN_AOPS_PURGED_CUSTOMERS SET purge_status='Y', purged_date=SYSDATE WHERE orig_system_reference = i_rec.ORIG_SYSTEM_REFERENCE;
	            
	              INSERT INTO XXFIN_FINAL_PURGED_CUSTOMERS  SELECT * FROM XXFIN_AOPS_PURGED_CUSTOMERS  WHERE  ORIG_SYSTEM_REFERENCE=i_rec.ORIG_SYSTEM_REFERENCE; --Table Added by Ankit    
	            
              ELSE
	            UPDATE XXFIN_AOPS_PURGED_CUSTOMERS SET purge_status='N', purged_date=SYSDATE WHERE orig_system_reference = i_rec.ORIG_SYSTEM_REFERENCE;
	            --altered purge_status to status--Added by Ankit
	           
                --dba_col_tabs with column as orig_system_reference
              END IF;
              --Exception block        
              EXCEPTION
                WHEN OTHERS THEN
	          	fnd_file.put_line(fnd_file.LOG,'Exception in Setting Inactive Statuses- '||SQLERRM);
                 --commit; --Commented by Ankit
          END;    
         -- commit;--Commented by Ankit
      END LOOP;
	  hz_common_pub.enable_cont_source_security;
      commit;--Added by Ankit outside LOOP 
  EXCEPTION WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.LOG,'Exception:- '||SQLERRM);
  END PURGE_INACTIVE_CUSTOMERS;
END XXFIN_PURGE_INACTIVE_CUSTOMERS;
/
show error;