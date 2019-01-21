create or replace
PACKAGE BODY XX_CDH_ACCT_SITE_USE_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_ACCT_SITE_USE_PKG.pkb                       |
-- | Description :  Custom Account Site Usage package to nullify       |
-- |                inactive BILL_TO usages tied to a SHIP_TO.         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- | 1        12-Nov-2008 Naga Kalyan        Initial Draft.            |
-- | 1.1      17-Jul-2009 Naga Kalyan        Removed status check on   |
-- |                                         SHIP_TO usage.            |
-- | 1.2      20-Mar-2014 Arun Gannarapu     Made changes to pass the
-- |                                         cust acct site id for R12 |
-- |                                         defect 29090              |
-- +===================================================================+
AS
--+=========================================================================================================+
--| PROCEDURE  : update_shipto_use                                                                          |
--| p_bill_to_osr           IN   hz_cust_acct_sites_all.orig_system_reference%TYPE                          |
--|                              Site OSR of inactivated BILL_TO usage                                      |
--| x_return_status         OUT  VARCHAR2   Returns return status                                           |
--| x_error_message         OUT  VARCHAR2   Returns return message                                          |
--| x_msg_count             OUT  VARCHAR2   Returns error message count                                     |
--+=========================================================================================================+
   PROCEDURE update_shipto_use (
      p_bill_to_osr            IN       hz_cust_acct_sites_all.orig_system_reference%TYPE,
      x_return_status          OUT      NOCOPY VARCHAR2,
      x_error_message	         OUT      NOCOPY VARCHAR2,
      x_msg_count              OUT      NOCOPY NUMBER
   )
   IS
	l_site_use_id  		hz_cust_site_uses_all.site_use_id%TYPE;
	l_cust_account_id 	hz_cust_acct_sites_all.cust_account_id%TYPE;
        l_cust_acct_site_id     hz_cust_site_uses_all.cust_Acct_site_id%TYPE; 
  
  cursor c_update_shipto (p_cust_acct_id		hz_cust_acct_sites_all.cust_account_id%TYPE,
                          p_billto_site_use_id 	hz_cust_site_uses_all.site_use_id%TYPE) IS
	select  csu.site_use_id,csu.object_version_number , csu.cust_acct_site_id
	from    hz_cust_site_uses_all  csu, 
        	hz_cust_acct_sites_all cas
	where   csu.CUST_ACCT_SITE_ID = cas.cust_acct_site_id
	and     csu.SITE_USE_CODE = 'SHIP_TO'
	and 	  cas.cust_account_id = p_cust_acct_id
	and     csu.bill_to_site_use_id = p_billto_site_use_id;
        --removed status check
	--and     csu.status = 'A';  

  BEGIN
      	x_return_status := 'S';
        
    begin
        -- this should return only 1 row
      select site_use_id , 
             cust_account_id  
      into   l_site_use_id , 
             l_cust_account_id
      from    hz_cust_site_uses_all  csu, 
              hz_cust_acct_sites_all cas
      where   csu.CUST_ACCT_SITE_ID = cas.cust_acct_site_id
      and     csu.SITE_USE_CODE = 'BILL_TO'
        -- Commented the following since this seems to be an issue when BPEL is invoking this API.
        -- The status has not been detected as 'I' which does not return any rows.  Thus, 
        -- the assumption is the only time this API call is made is when a site is supppose to be
        -- inactive.  This is an issue with not having the same transaction session within BPEL.
      --and     csu.status = 'I'
      and     cas.orig_system_reference = ltrim(rtrim(p_bill_to_osr));
        
    EXCEPTION
      WHEN NO_DATA_FOUND THEN	
            x_error_message := 'No Data Found FOR ' || '**' ||p_bill_to_osr || '**' ;
            RETURN ;
      WHEN TOO_MANY_ROWS THEN	
            x_error_message := 'Too many rows returned FOR p_bill_to_osr';
            x_return_status := 'E';
            RETURN ;
    END;
	
    FOR update_shipto_rec In c_update_shipto(l_cust_account_id,l_site_use_id)  loop
          -- Call v2 API to update cust_acct_site_use
      DECLARE
        P_INIT_MSG_LIST VARCHAR2(200);
        P_CUST_SITE_USE_REC APPS.HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
        P_OBJECT_VERSION_NUMBER NUMBER;
        X_MSG_DATA VARCHAR2(200);

      BEGIN
        P_INIT_MSG_LIST := NULL;
        P_CUST_SITE_USE_REC.site_use_id := update_shipto_rec.site_use_id ;
        P_CUST_SITE_USE_REC.bill_to_site_use_id := FND_API.G_MISS_NUM;
        p_cust_site_use_rec.cust_acct_site_id   := update_shipto_rec.cust_acct_site_id;
        P_OBJECT_VERSION_NUMBER := update_shipto_rec.object_version_number;

        HZ_CUST_ACCOUNT_SITE_V2PUB.UPDATE_CUST_SITE_USE(
          P_INIT_MSG_LIST => P_INIT_MSG_LIST,
          P_CUST_SITE_USE_REC => P_CUST_SITE_USE_REC,
          P_OBJECT_VERSION_NUMBER => P_OBJECT_VERSION_NUMBER,
          X_RETURN_STATUS => x_return_status,
          X_MSG_COUNT => x_msg_count,
          X_MSG_DATA => x_error_message
        );
                    
        IF x_return_status <> 'S' THEN   
         RETURN ;
        END IF;
      END;
  END LOOP;
  
  EXCEPTION
      
      WHEN OTHERS THEN
        x_return_status := 'E';
        x_error_message := 'Unexpected error.'|| sqlerrm;
        
  END update_shipto_use;
  
 END XX_CDH_ACCT_SITE_USE_PKG;
/