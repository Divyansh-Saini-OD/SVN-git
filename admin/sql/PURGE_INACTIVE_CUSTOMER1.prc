CREATE OR REPLACE PROCEDURE PURGE_INACTIVE_CUSTOMER1(P_START_ROW_ID IN VARCHAR2,P_END_ROW_ID IN VARCHAR2 )
IS
  -- +============================================================================================|
  -- |                                    Office Depot                                            |
  -- +============================================================================================|
  -- |  Name:  PURGE_INACTIVE_CUSTOMER1                                                                  |
  -- |                                                                                            |
  -- |  Description: This procedure is for Purging the inactive Customers                         |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         02/12/2021   Ankit Jaiswal        Initial version                              |
    -- +============================================================================================+
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
  cursor c1
  is
  select * 
  from   XXFIN_AOPS_PURGED_CUSTOMERS  
  where  1=1
  and    status in ('A','N')
  --and    status='N'
  --and    rownum < 1001
  and ID between P_START_ROW_ID and P_END_ROW_ID;

  cursor c2 (P_ORIG_SYSTEM_REFERENCE IN VARCHAR2)
  is
  select *
  from   hz_orig_sys_references
  where  ORIG_SYSTEM_REFERENCE like P_ORIG_SYSTEM_REFERENCE || '%'
  ;
begin

  --mo_global.init('AR');--commented as Concurrent program created 
  --mo_global.set_policy_context('S','404');
  --fnd_global.apps_initialize(58590,50658,222);--commented by Ankit
  for i_rec in c1
  loop
    BEGIN
    --update orig_system_references
    P_ORIG_SYSTEM_REF_ID          := NULL;
    P_OBJECT_VERSION_NUMBER       := null;
    P_PARTY_OBJECT_VERSION_NUMBER := null;
    X_PROFILE_ID                  := null;
    
    --Check if there are any open AR transactions
    select count(1)
    into   l_trx_count
    from   ar_payment_schedules_all
    where  1=1
    AND    TRX_DATE > SYSDATE - 7*365
    AND    STATUS <> 'CL'
    and    customer_id=i_rec.cust_account_id
    ;     
    
    IF l_trx_count = 0 THEN
	  for j_rec in c2(i_rec.ORIG_SYSTEM_REFERENCE)--Added by Ankit
      loop
        ---
        --update hz_orig_sys_references set status='A' where ORIG_SYSTEM_REF_ID=j_rec.ORIG_SYSTEM_REF_ID;
        --
        IF j_rec.status = 'A'
        THEN
        
          P_INIT_MSG_LIST := 'T';
          
          X_ORIG_SYS_REFERENCE_REC.orig_system_ref_id        := j_rec.ORIG_SYSTEM_REF_ID;
          X_ORIG_SYS_REFERENCE_REC.orig_system               := j_rec.orig_system;
          X_ORIG_SYS_REFERENCE_REC.orig_system_reference := substrb(j_rec.ORIG_SYSTEM_REFERENCE 
                                                                   ,1
                                                                   ,instrb(j_rec.ORIG_SYSTEM_REFERENCE,'-')-1)
                                                            ||'P' 
                                                            || substrb(j_rec.ORIG_SYSTEM_REFERENCE
                                                              , instrb(j_rec.ORIG_SYSTEM_REFERENCE,'-')
                                                              , length(j_rec.ORIG_SYSTEM_REFERENCE)
                                                                      ); 
          --dbms_output.put_line(sysdate || 'X_ORIG_SYS_REFERENCE_REC.orig_system_reference:' || X_ORIG_SYS_REFERENCE_REC.orig_system_reference);                                                                  
          X_ORIG_SYS_REFERENCE_REC.owner_table_name          := j_rec.OWNER_TABLE_NAME;
          X_ORIG_SYS_REFERENCE_REC.owner_table_id            := j_rec.owner_table_id;
          X_ORIG_SYS_REFERENCE_REC.old_orig_system_reference := j_rec.ORIG_SYSTEM_REFERENCE;     
          --X_ORIG_SYS_REFERENCE_REC.start_date_active         := j_rec.creation_date;      
          X_ORIG_SYS_REFERENCE_REC.end_date_active           := sysdate;
          X_ORIG_SYS_REFERENCE_REC.status                    := 'I';
          P_OBJECT_VERSION_NUMBER                            := j_rec.OBJECT_VERSION_NUMBER;
          X_ORIG_SYS_REFERENCE_REC.created_by_module         := j_rec.created_by_module;
          
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
               null;
            END LOOP;
          END IF;
        ELSE
          update hz_orig_sys_references 
          set ORIG_SYSTEM_REFERENCE=X_ORIG_SYS_REFERENCE_REC.orig_system_reference, status='I', end_date_active=sysdate 
          where orig_system_ref_id=j_rec.orig_system_ref_id;     
        END IF;
      
        
        IF (j_rec.OWNER_TABLE_NAME = 'HZ_CUST_ACCOUNTS') THEN
          --Inactivate account
		  update HZ_CUST_ACCOUNTS set orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference, status='I' where cust_account_id=j_rec.owner_table_id;         
         
        ELSIF(j_rec.OWNER_TABLE_NAME = 'HZ_PARTIES') THEN               
          --Inactivate Party
  
          update HZ_PARTIES set orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference, status='I' where party_id=j_rec.owner_table_id;
		       
        ELSIF(j_rec.OWNER_TABLE_NAME = 'HZ_PARTY_SITES') THEN
       
          update HZ_PARTY_SITES set orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference, status='I' --last_update_by
          where party_site_id=j_rec.owner_table_id;
		   
        
        ELSIF(j_rec.OWNER_TABLE_NAME = 'HZ_CUST_ACCT_SITES_ALL') THEN
          --Inactivate account site
		  
          update HZ_CUST_ACCT_SITES_ALL set orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference, status='I' where cust_acct_site_id=j_rec.owner_table_id;
		   
      
        ELSIF(j_rec.OWNER_TABLE_NAME = 'HZ_CUST_SITE_USES_ALL') THEN
          --Inactivate two site uses       
          IF (INSTR(j_rec.orig_system_reference,'SHIP_TO')>0) THEN

            update HZ_CUST_SITE_USES_ALL set orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference, status='I' where site_use_id=j_rec.owner_table_id;
			
          END IF;   
      
          IF (INSTR(j_rec.orig_system_reference,'BILL_TO')>0) THEN
            
			
            update HZ_CUST_SITE_USES_ALL set orig_system_reference = X_ORIG_SYS_REFERENCE_REC.orig_system_reference, status='I' where site_use_id=j_rec.owner_table_id;
			
          END IF;           
              
           --Check for XX_EXTERNAL_USERS table--TO be checked
        END IF;

        
      end loop;
      --update the purge_status	  
	  update XXFIN_AOPS_PURGED_CUSTOMERS set purge_status='Y', purged_date=sysdate where orig_system_reference = i_rec.ORIG_SYSTEM_REFERENCE;
	  --altered the table name and purge_status to status--Added by Ankit
	  
	  insert into XXFIN_FINAL_PURGED_CUSTOMERS  select * from XXFIN_AOPS_PURGED_CUSTOMERS  where  ORIG_SYSTEM_REFERENCE=i_rec.ORIG_SYSTEM_REFERENCE; --Table Added by Ankit    
	  
    ELSE
	  update XXFIN_AOPS_PURGED_CUSTOMERS set purge_status='N', purged_date=sysdate where orig_system_reference = i_rec.ORIG_SYSTEM_REFERENCE;
	  --altered purge_status to status--Added by Ankit
	 
      --dba_col_tabs with column as orig_system_reference
    END IF;
    --Exception block        
    EXCEPTION
      when others then
		fnd_file.put_line(fnd_file.log,'Exception in Setting Inactive Statuses- '||SQLERRM);
      -- commit; --Commented by Ankit
    END;    
    --commit;--Commented by Ankit
  end loop;

exception
  when others then
    fnd_file.put_line(fnd_file.log,'Exception:- '||SQLERRM);
end;
/