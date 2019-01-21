create or replace PACKAGE BODY      XX_CDH_VPS_ORIG_SYS_REF
AS

PROCEDURE Create_OSR( party_id  IN NUMBER
                    ,acct_id    IN NUMBER
                    ,osr        IN VARCHAR2
                    ,table_name IN VARCHAR2
                    )

IS 
  P_INIT_MSG_LIST             VARCHAR2(200);
  P_ORIG_SYS_REFERENCE_REC    APPS.HZ_ORIG_SYSTEM_REF_PUB.ORIG_SYS_REFERENCE_REC_TYPE;
  X_RETURN_STATUS             VARCHAR2(200);
  X_MSG_COUNT                 NUMBER;
  X_MSG_DATA                  VARCHAR2(200);
  lv_init_msg_list            VARCHAR2 (1) := 'T';
  lv_msg_count                NUMBER;
  lv_msg_index_out            NUMBER;
  lv_output                   VARCHAR2(4000);
  lv_return_status            VARCHAR2(1);
  lv_msg_data                 VARCHAR2 (2000);
  lv_msg_dummy                VARCHAR2 (2000);
  lv_err_msg                  VARCHAR2 (2000);
BEGIN
  P_INIT_MSG_LIST                      := 'T';
  P_ORIG_SYS_REFERENCE_REC.orig_system := 'VPS';
  P_ORIG_SYS_REFERENCE_REC.orig_system_reference :=osr;
  P_ORIG_SYS_REFERENCE_REC.STATUS := 'A';
  P_ORIG_SYS_REFERENCE_REC.owner_table_name := table_name;
  P_ORIG_SYS_REFERENCE_REC.owner_table_id := acct_id; 
  P_ORIG_SYS_REFERENCE_REC.party_id :=party_id;
  P_ORIG_SYS_REFERENCE_REC.created_by_module:='TCA_V2_API';
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Start creating OSR: '||table_name);
  HZ_ORIG_SYSTEM_REF_PUB.CREATE_ORIG_SYSTEM_REFERENCE(
    P_INIT_MSG_LIST => P_INIT_MSG_LIST,
    P_ORIG_SYS_REFERENCE_REC => P_ORIG_SYS_REFERENCE_REC,
    --X_ORIG_SYSTEM_REF_ID=>lv_orig_system_ref_id,
    X_RETURN_STATUS => lv_return_status,
    X_MSG_COUNT => lv_msg_count,
    X_MSG_DATA => lv_msg_data
  );
 --If API fails
        IF lv_return_status <> 'S' THEN
          FOR i IN 1 .. lv_msg_count
          LOOP
            fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
            lv_output := (TO_CHAR (i) || ': ' || lv_msg_data);
          END LOOP;
          
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Create OSR: ' || lv_output);
        ELSE
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Create OSR: ' ||lv_return_status );
        END IF;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN 
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Unknown Create OSR: ' || SQLERRM);
END;


PROCEDURE update_origsystem_adhoc (
      p_errbuf_out              OUT      VARCHAR2
     ,p_retcod_out              OUT      VARCHAR2
     ,p_vendor_number           IN       VARCHAR2
     ,p_account_number          IN       VARCHAR2
    )
IS
  -- +============================================================================================+
  -- |  Office Depot                                                                          	  |
  -- +============================================================================================+
  -- |  Name:  XX_CDH_VPS_ORIG_SYS_REF                                                     	      |
  -- |                                                                                            |
  -- |  Description:  This package is used to update orig system reference.        	              |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         01-OCT-2017  Thejaswini Rajula    Initial version                              |
  -- +============================================================================================+
  lv_count                  NUMBER;
  lv_cnt_vendor_site        NUMBER;
  lv_org_id                 NUMBER;
  l_user_id                 NUMBER;
  l_responsibility_id       NUMBER;
  l_responsibility_appl_id  NUMBER;
  i                         NUMBER;
  lv_cust_account_id        NUMBER;
  lv_acct_osr               VARCHAR2(250);
  lv_site_acct_id           NUMBER;
  lv_site_osr               VARCHAR2(250);  
  lv_party_id               NUMBER;
BEGIN 
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Start');
  lv_count          :=NULL;
  lv_cnt_vendor_site:=NULL;
  SELECT organization_id 
    INTO lv_org_id
    FROM hr_operating_units
    WHERE name='OU_US_VPS';
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Org Id  : ' || lv_org_id);
		mo_global.set_policy_context('S',lv_org_id); 
 	BEGIN
    SELECT user_id,
           responsibility_id,
           responsibility_application_id
    INTO   l_user_id,
           l_responsibility_id,
           l_responsibility_appl_id
      FROM fnd_user_resp_groups
     WHERE user_id=(SELECT user_id
                      FROM fnd_user
                     WHERE user_name='ODCDH')
     AND   responsibility_id=(SELECT responsibility_id
                                FROM FND_RESPONSIBILITY
                               WHERE responsibility_key = 'OD_US_VPS_CDH_ADMINSTRATOR');
    FND_GLOBAL.apps_initialize(
                         l_user_id,
                         l_responsibility_id,
                         l_responsibility_appl_id
                       );
   EXCEPTION
    WHEN OTHERS THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in initializing : ' || SQLERRM);
     NULL;
   END; ---END apps intialization
    -- Check for OSR at Account level
      select Count(1) 
        into lv_count
        from   hz_cust_accounts_all
        where  1=1
        and    orig_system_reference=p_vendor_number||'-VPS';
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Existence of OSR Account  : ' || lv_count);
    -- Check for existence of vendor at site level 
      select Count(ssa.vendor_site_code_alt) 
        into lv_cnt_vendor_site
        from   ap_supplier_sites_all ssa
              ,ap_suppliers          sup
        where  1=1
        and    sup.vendor_id = ssa.vendor_id
        and    ltrim(ssa.vendor_site_code_alt,'0')=p_vendor_number
        and    ssa.attribute8 like 'TR%'
        and    ssa.pay_site_flag='Y'
        and  	( ssa.inactive_date IS NULL OR  ssa.inactive_date > SYSDATE);
      
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Existence of Vendor in AP  : ' || lv_cnt_vendor_site);
  IF  (lv_cnt_vendor_site =0 AND lv_count=0)THEN 
    --Update Organization
       BEGIN 
        UPDATE hz_parties
            SET orig_system_reference=p_vendor_number||'-VPS'
                ,last_update_date = SYSDATE
          WHERE 1=1
            AND party_id IN (SELECT party_id
                              FROM hz_cust_accounts_all
                              WHERE 1=1
                                AND account_number=p_account_number);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found hz_parties'||p_vendor_number);
            NULL;
          WHEN OTHERS THEN 
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Others Exception hz_parties'||p_vendor_number);
            NULL;
        END;
        i := sql%rowcount;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Update OSR Party : '||i);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Update Party Reference :'||p_vendor_number||'-VPS');

    -- Update Account  
       BEGIN 
        UPDATE hz_cust_accounts_all
            SET orig_system_reference=p_vendor_number||'-VPS'
                ,last_update_date = SYSDATE
          WHERE 1=1
            AND account_number=p_account_number;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found hz_cust_accounts_all'||p_vendor_number);
            NULL;
          WHEN OTHERS THEN 
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Others Exception hz_cust_accounts_all'||p_vendor_number);
            NULL;
        END;
        i := sql%rowcount;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Update OSR Account : '||i);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Update Account Reference :'||p_vendor_number||'-VPS');
            
    -- Update Account sites
      BEGIN 
        UPDATE hz_cust_acct_sites_all
            SET orig_system_reference=p_vendor_number||'-01-'||'VPS'
                ,last_update_date = SYSDATE
          WHERE 1=1
            AND cust_account_id IN (SELECT cust_account_id
                                      FROM hz_cust_accounts_all 
                                      WHERE 1=1
                                        AND account_number=p_account_number
                                        )
            ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found hz_cust_acct_sites_all'||p_vendor_number);
            NULL;
          WHEN OTHERS THEN 
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Others Exception hz_cust_acct_sites_all'||p_vendor_number);
            NULL;
        END; 
        i := sql%rowcount;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Update OSR Account Site : '||i);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Update Account Site Reference :'||p_vendor_number||'-01-'||'VPS');
      -- Update Account Site Uses all BILL TO 
      BEGIN 
        UPDATE hz_cust_site_uses_all
            SET orig_system_reference=p_vendor_number||'-01-VPS-BILL_TO'
                ,last_update_date = SYSDATE
          WHERE 1=1
            AND cust_acct_site_id IN (SELECT cust_acct_site_id
                                          FROM hz_cust_acct_sites_all 
                                          WHERE 1=1
                                            AND cust_account_id IN (SELECT cust_account_id
                                                                      FROM hz_cust_accounts_all 
                                                                     WHERE 1=1
                                                                      AND account_number=p_account_number))
            AND site_use_code='BILL_TO';
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found hz_cust_site_uses_all BILL_TO:'||p_vendor_number);
            NULL;
          WHEN OTHERS THEN 
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Others Exception hz_cust_site_uses_all BILL_TO:'||p_vendor_number);
            NULL;
        END;
        i := sql%rowcount;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Update OSR Account Site : '||i);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Update Account Site Use BILL TO Reference:'||p_vendor_number||'-01-VPS-BILL_TO');
     --Update Account Site Uses all SHIP TO   
      BEGIN 
        UPDATE hz_cust_site_uses_all
            SET orig_system_reference=p_vendor_number||'-01-VPS-SHIP_TO'
                ,last_update_date = SYSDATE
          WHERE 1=1
            AND cust_acct_site_id IN (SELECT cust_acct_site_id
                                          FROM hz_cust_acct_sites_all 
                                          WHERE 1=1
                                            AND cust_account_id IN (SELECT cust_account_id
                                                                      FROM hz_cust_accounts_all 
                                                                     WHERE 1=1
                                                                      AND account_number=p_account_number))
            AND site_use_code='SHIP_TO';
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found hz_cust_acct_sites_all SHIP_TO:'||p_vendor_number);
            NULL;
          WHEN OTHERS THEN 
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Others Exception hz_cust_acct_sites_all SHIP_TO:'||p_vendor_number);
            NULL;
        END;
       i := sql%rowcount;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Update OSR Account Site Uses SHIP TO : '||i);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Update Account Site Use SHIP TO Reference:'||p_vendor_number||'-01-VPS-SHIP_TO');
   COMMIT;     
    -- Create OSR 
      BEGIN 
        SELECT hca.party_id,hca.cust_account_id,hca.orig_system_reference,hcas.cust_acct_site_id site_id,hcas.orig_system_reference site_osr
          INTO lv_party_id,lv_cust_account_id,lv_acct_osr,lv_site_acct_id,lv_site_osr
          FROM hz_cust_accounts_all hca
              ,hz_cust_acct_sites_all hcas
      WHERE 1=1
        AND hca.orig_system_reference=p_vendor_number||'-VPS'
        AND hca.cust_account_id=hcas.cust_account_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN 
          FND_FILE.PUT_LINE(FND_FILE.LOG,'NO OSR Data FOUND For : '||p_vendor_number);
          NULL;
        WHEN TOO_MANY_ROWS THEN 
          FND_FILE.PUT_LINE(FND_FILE.LOG,'TOO MANY ROWS for OSR  : '||p_vendor_number);
          NULL;
        WHEN OTHERS THEN 
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Unknown error for OSR  : '||p_vendor_number);
          NULL;
      END;
      IF lv_acct_osr IS NOT NULL THEN 
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Account Id : '||lv_cust_account_id);
        Create_OSR(lv_party_id,lv_cust_account_id,lv_acct_osr,'HZ_CUST_ACCOUNTS');
      END IF;
      IF lv_acct_osr IS NOT NULL THEN 
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Account Site Id : '||lv_site_acct_id);
        Create_OSR(lv_party_id,lv_site_acct_id,lv_site_osr,'HZ_CUST_ACCT_SITES_ALL');
      END IF;
                
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Reference already exists for vendor number: '||p_vendor_number||' .Please check Vendor Number and Account Number');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_vendor_number||': Vendor number already exists on an existing customer. Please check Vendor Number and Account Number');
      p_retcod_out:=2;
    END IF;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'END');
EXCEPTION 
  WHEN OTHERS THEN 
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected Error in updating orig system system references : ' || SQLERRM);
    NULL;
END;
END XX_CDH_VPS_ORIG_SYS_REF;
/