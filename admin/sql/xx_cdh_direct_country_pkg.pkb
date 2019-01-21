CREATE OR REPLACE
PACKAGE BODY xx_cdh_direct_country_pkg
AS
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- +====================================================================================+
-- | Name        :  xx_cdh_direct_country_pkg.pkb                                       |
-- | Description :  The AOPS system allows user to change the country for Direct        |
-- |                customers. BPEL sync has to inactivate the existing account site and|
-- |                the corresponsing OSRs. Also, Avtivate the new account site related |
-- |                entries which are related to the new country.    
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date        Author             Remarks                                    |
-- |========  =========== ================== ===========================================|
-- |DRAFT 1a  15-Oct-2008 Kathirvel          Initial draft version                      |
-- +=====================================================================================+

/*
----------------------------------------------
--Before creating/updating the party_site, this procedure check_country_main
--is invoked from the BPEL Process SaveAddressProcess if the customer is Direct custromer.
----------------------------------------------
*/

PROCEDURE check_country_main(
                            p_orig_system            IN   VARCHAR2
                          , p_acct_site_osr          IN   VARCHAR2
                          , p_current_country_code   IN   VARCHAR2
			  , p_current_org_id         IN   NUMBER
			  , x_country_change_flg     OUT  NOCOPY   VARCHAR2
			  , x_return_status          OUT  NOCOPY   VARCHAR2
			  , x_error_message          OUT  NOCOPY   VARCHAR2
			  ) IS

CURSOR l_exist_countr_code_cur IS
SELECT hl.country,asl.cust_acct_site_id
FROM   hz_cust_acct_sites_all asl,
       hz_party_sites hps,
       hz_locations hl
WHERE  asl.orig_system_reference   = p_acct_site_osr
AND    asl.party_site_id           = hps.party_site_id
AND    hps.location_id             = hl.location_id
AND    asl.status                  = 'A';

CURSOR l_site_uses_cur(cur_acct_site_id NUMBER) IS
SELECT sua.orig_system_reference , sua.site_use_id
FROM   hz_cust_site_uses_all sua
WHERE  sua.cust_acct_site_id   = cur_acct_site_id;


l_exist_country_code     VARCHAR2(25);
l_cust_acct_site_id      NUMBER;

BEGIN

x_return_status := 'S';

/*
----------------------------------------------
--Get the account site ID and old(existing) country code
----------------------------------------------
*/

OPEN  l_exist_countr_code_cur ;
FETCH l_exist_countr_code_cur INTO  l_exist_country_code,l_cust_acct_site_id;
CLOSE l_exist_countr_code_cur ; 



IF l_exist_country_code IS NOT NULL and l_exist_country_code <> p_current_country_code
THEN
 
/*
----------------------------------------------
--If the old country and new country are different, Inactivate the acct_site OSR entry which was 
--created for the old country and activate the OSR entry (acct_site) if any previously inactivated for the new country. 
----------------------------------------------
*/
	UPDATE   hz_orig_sys_references
	SET      status           = 'I',
	         last_updated_by  = fnd_global.user_id(),
		 last_update_date = sysdate
	WHERE    orig_system_reference = p_acct_site_osr 
	AND      orig_system           = p_orig_system
	AND      owner_table_name      = 'HZ_CUST_ACCT_SITES_ALL'
	AND      owner_table_id        = l_cust_acct_site_id
	AND      status                = 'A';

	UPDATE   hz_orig_sys_references
	SET      status           = 'A',
	         last_updated_by  = fnd_global.user_id(),
		 last_update_date = sysdate
	WHERE    orig_system_reference = p_acct_site_osr 
	AND      orig_system           = p_orig_system
	AND      owner_table_name      = 'HZ_CUST_ACCT_SITES_ALL'
	AND      owner_table_id        <> l_cust_acct_site_id
	AND      status                = 'I';

/*
----------------------------------------------
--Inactivate the acct_site_uses OSR entries which were created for the old country and 
--activate the OSR entries (acct_site_uses) if any previously inactivated for the new country. 
----------------------------------------------
*/

        FOR I IN l_site_uses_cur(l_cust_acct_site_id)
	LOOP
		UPDATE   hz_orig_sys_references
		SET      status = 'I',
	                 last_updated_by   = fnd_global.user_id(),
		         last_update_date  = sysdate
		WHERE    orig_system_reference = I.orig_system_reference  
		AND      orig_system           = p_orig_system
		AND      owner_table_name      = 'HZ_CUST_SITE_USES_ALL'
	        AND      owner_table_id        = I.site_use_id
		AND      status                = 'A';

		UPDATE   hz_orig_sys_references
		SET      status = 'A',
			 last_updated_by   = fnd_global.user_id(),
			 last_update_date  = sysdate
		WHERE    orig_system_reference = I.orig_system_reference  
		AND      orig_system           = p_orig_system
		AND      owner_table_name      = 'HZ_CUST_SITE_USES_ALL'
		AND      owner_table_id        <> I.site_use_id
		AND      status                = 'I';

        END LOOP;


        /*
	inactivate_acct_site (
                            p_acct_site_osr     => p_acct_site_osr
			  , p_current_org_id    => p_current_org_id
			  , x_return_status     => x_return_status
			  , x_error_message     => x_error_message 
			  );

        IF x_return_status ='S'
	THEN
           x_country_change_flg := 'Y';
        END IF;
	*/
/*        
----------------------------------------------
--Set the output parameter x_country_change_flg to Y 
----------------------------------------------
*/
	x_country_change_flg := 'Y';


 END IF;


EXCEPTION
	WHEN OTHERS
	THEN
	    x_return_status   := 'E';
	    x_error_message   := SQLERRM;
END check_country_main;

/*
----------------------------------------------
--After creating/updateing the account site, the BPEL Process SaveAddressProcess invokes 
--this procedure with acct_site OSR and new country's Org ID if x_country_change_flg is 'Y' (the old country and new country are different for direct customers)
----------------------------------------------
*/

PROCEDURE inactivate_acct_site(
                            p_acct_site_osr          IN   VARCHAR2
			  , p_current_org_id         IN   NUMBER
			  , x_return_status          OUT  NOCOPY   VARCHAR2
			  , x_error_message          OUT  NOCOPY   VARCHAR2
			  ) IS
CURSOR l_acct_site_cur IS 
SELECT cust_acct_site_id  
FROM   hz_cust_acct_sites_all
WHERE  orig_system_reference =  p_acct_site_osr
AND    org_id                <> p_current_org_id;


CURSOR l_curr_acct_site_cur IS 
SELECT cust_acct_site_id  
FROM   hz_cust_acct_sites_all
WHERE  orig_system_reference = p_acct_site_osr
AND    org_id                = p_current_org_id;

BEGIN
x_return_status := 'S';

/*
----------------------------------------------
--Inactivate the acct_site entry which was created for the old country
----------------------------------------------
*/

UPDATE hz_cust_acct_sites_all 
SET    status = 'I',
       last_updated_by   = fnd_global.user_id(),
       last_update_date = sysdate
WHERE  orig_system_reference =  p_acct_site_osr
AND    org_id                <> p_current_org_id
AND    status                =  'A';

/*
----------------------------------------------
--Sometimes, BO API creates account site with Inactive status for the new country (new operating unit) though we pass Active.
--In such cases , Activate the acct_site entry which was created for the new country if it is with Inactive status.
----------------------------------------------
*/

UPDATE hz_cust_acct_sites_all 
SET    status = 'A',
       last_updated_by   = fnd_global.user_id(),
       last_update_date = sysdate
WHERE  orig_system_reference = p_acct_site_osr
AND    org_id                = p_current_org_id
AND    status                = 'I';

/*
----------------------------------------------
--Inactivate the acct_site_uses entries which were created for the old country
----------------------------------------------
*/

FOR I IN l_acct_site_cur
LOOP
	UPDATE hz_cust_site_uses_all 
	SET    status = 'I',
	       last_updated_by   = fnd_global.user_id(),
               last_update_date  = sysdate	
	WHERE  cust_acct_site_id = I.cust_acct_site_id
	AND    status            = 'A';


END LOOP;

/*
----------------------------------------------
--Sometimes, BO API creates account site and site Uses with Inactive status for the new country (new operating unit) though we pass Active.
--In such cases , Activate the acct_site_uses entries which were created for the new country if it is with Inactive status.
----------------------------------------------
*/

FOR I IN l_curr_acct_site_cur
LOOP
	UPDATE hz_cust_site_uses_all 
	SET    status = 'A',
	       last_updated_by   = fnd_global.user_id(),
               last_update_date  = sysdate	
	WHERE  cust_acct_site_id = I.cust_acct_site_id
	AND    status            = 'I';

END LOOP;


EXCEPTION
	WHEN OTHERS
	THEN
	    x_return_status   := 'E';
	    x_error_message   := SQLERRM;
END inactivate_acct_site;

END xx_cdh_direct_country_pkg;
/