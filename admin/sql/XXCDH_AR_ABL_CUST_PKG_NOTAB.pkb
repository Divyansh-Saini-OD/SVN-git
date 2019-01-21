-- $Id:  $
-- $Rev:  $
-- $HeadURL:  $
-- $Author:  $
-- $Date:  $
SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XXCDH_AR_ABL_CUST_PKG_NOTAB
-- +=====================================================================================+
-- |                  Office Depot - Project Simplify  Rel 1.2                           |
-- +=====================================================================================+
-- |                                                                                     |
-- | Name             :  PRINT_CUSTOMER_DETAILS                                          |
-- |                                                                                     |
-- | Description      : Reporting package for all AB Customers                           |
-- |                                                                                     |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date        Author                       Remarks                           |
-- |=======   ==========  ====================         ==================================|
-- |Draft 1.0 20-Feb-10   Nabarun Ghosh                Draft version                     |
-- |V1.0      22-Feb-10   nabarun Ghosh                Incorporated the below performan	 |
-- |                                                   -ce advices from performance team:|
-- |                                                   Added the hint LEADING on the 02  |
-- |                                                   Functions.			 |
-- |                                                   No changes to the modified query  |
-- |                                                   of the main cursor lcu_abl_cust.  |
-- +=====================================================================================+
AS

FUNCTION Get_Ap_Phone(p_party_id IN NUMBER)
RETURN VARCHAR2
IS
  
BEGIN
          lt_phone_ap.delete;
          
          SELECT /*+ LEADING(rel,party) USE_NL(role_acct,acct_role) USE_NL(acct_role,rel) USE_NL(rel,cont_point) */
	         REGEXP_REPLACE(cont_point.phone_area_code||cont_point.phone_number,'([[:digit:]]{3})([[:digit:]]{3})([[:digit:]]{4})','\1-\2-\3')
	  INTO lt_phone_ap('PHONE')
	  FROM   APPS.hz_cust_accounts      role_acct,
	         APPS.hz_cust_account_roles acct_role,
	         APPS.hz_relationships      rel,
	         APPS.hz_contact_points     cont_point,
	         APPS.hz_parties            party,
	         APPS.hz_org_contacts       org_cont
	  WHERE  role_acct.party_id = p_party_id
	  AND    role_acct.cust_account_id = acct_role.cust_account_id
	  AND    rel.relationship_code = 'CONTACT_OF'
	  AND    role_acct.party_id = rel.object_id 
	  AND    acct_role.party_id = rel.party_id
	  AND    rel.party_id       = cont_point.owner_table_id 
	  AND    rel.subject_id     = party.party_id
	  AND    rel.relationship_id = org_cont.party_relationship_id
	  AND    role_acct.status = 'A'
	  AND    acct_role.role_type = 'CONTACT'
	  AND    acct_role.status = 'A'
	  AND    rel.status = 'A'
	  AND    cont_point.phone_line_type = 'GEN'
	  AND    cont_point.contact_point_type = 'PHONE'
	  AND    cont_point.status = 'A'
	  AND    cont_point.owner_table_name = 'HZ_PARTIES'
	  AND    party.person_last_name IS NOT NULL
	  AND    party.status = 'A'
	  AND    (TRIM(UPPER(org_cont.job_title))= 'AP' OR (TRIM(UPPER(org_cont.job_title)) LIKE 'ACCOUNT%PAY%'))
	  AND    org_cont.status = 'A'
	  AND EXISTS       
	             (      
	              SELECT 1
	              FROM   APPS.hz_cust_site_uses_all  hcsua,
	                     APPS.hz_cust_acct_sites_all hcasa
	              WHERE  hcsua.site_use_code     = 'BILL_TO'
	              AND    hcsua.PRIMARY_FLAG      = 'Y'
	              AND    hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
	              AND    hcasa.cust_account_id   = acct_role.cust_account_id 
	              AND    hcasa.cust_acct_site_id = acct_role.cust_acct_site_id
	             )  
          AND ROWNUM = 1 ;
          
          RETURN lt_phone_ap('PHONE');
  
EXCEPTION
  WHEN OTHERS THEN
  lt_phone_ap('PHONE') := NULL;
  RETURN lt_phone_ap('PHONE');
END Get_Ap_Phone;
          

FUNCTION Get_Ot_Phone(p_party_id IN NUMBER)
RETURN VARCHAR2
IS
  
 
  
BEGIN   
            
          lt_phone_ot.delete;
          

SELECT /*+ LEADING(rel,party) USE_NL(role_acct,acct_role) USE_NL(acct_role,rel) */
       REGEXP_REPLACE(cont_point.phone_area_code||cont_point.phone_number,'([[:digit:]]{3})([[:digit:]]{3})([[:digit:]]{4})','\1-\2-\3')
INTO   lt_phone_ot('PHONE')
FROM   APPS.hz_cust_accounts      role_acct,
       APPS.hz_cust_account_roles acct_role,
       APPS.hz_relationships      rel,
       APPS.hz_contact_points     cont_point,
       APPS.hz_parties            party
WHERE  role_acct.party_id = p_party_id
AND    role_acct.cust_account_id = acct_role.cust_account_id
AND    rel.relationship_code = 'CONTACT_OF'
AND    role_acct.party_id = rel.object_id 
AND    acct_role.party_id = rel.party_id
AND    rel.party_id       = cont_point.owner_table_id 
AND    rel.subject_id     = party.party_id
AND    role_acct.status = 'A'
AND    acct_role.role_type = 'CONTACT'
AND    acct_role.status = 'A'
AND    rel.status = 'A'
AND    cont_point.phone_line_type = 'GEN'
AND    cont_point.contact_point_type = 'PHONE'
AND    cont_point.status = 'A'
AND    cont_point.owner_table_name = 'HZ_PARTIES'
AND    party.person_last_name IS NOT NULL
AND    party.status = 'A'
AND EXISTS       
           (      
            SELECT 1
            FROM   APPS.hz_cust_site_uses_all  hcsua,
                   APPS.hz_cust_acct_sites_all hcasa
            WHERE  hcsua.site_use_code     = 'BILL_TO'
            AND    hcsua.PRIMARY_FLAG      = 'Y'
            AND    hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
            AND    hcasa.cust_account_id   = acct_role.cust_account_id 
            AND    hcasa.cust_acct_site_id = acct_role.cust_acct_site_id
           )  
AND ROWNUM = 1  ;          
          
          RETURN lt_phone_ot('PHONE');
  
EXCEPTION
  WHEN OTHERS THEN
  lt_phone_ot('PHONE') := NULL;
  RETURN lt_phone_ot('PHONE');
END Get_Ot_Phone;

PROCEDURE PRINT_CUSTOMER_DETAILS ( p_errbuf    OUT NOCOPY VARCHAR2
                                 , p_retcode   OUT NOCOPY VARCHAR2               
                                 )
AS


    lb_status               BOOLEAN;
    CURSOR lcu_abl_cust
    IS
    SELECT /*+ NO_MERGE(M) */
      DISTINCT 
       M.country_code
      ,M.account_number
      ,M.account_name
      ,M.address1
      ,M.address2
      ,M.city
      ,M.state
      ,M.Province
      ,M.postal_code
      ,M.country
      ,M.party_id 
     FROM(
    SELECT                      
                     party.party_id                   party_id,
                     party.party_name                 account_name, 
                     party.party_site_id              party_site_id,
                     party.address1                   address1,
                     party.address2                   address2,
                     party.city                       city,
                     party.state                      state,
                     party.province                   province,
                     party.postal_code                postal_code,
                     party.country                    country,
                     party.country_code               country_code,
                     party.account_number             account_number,
                     party.standard_terms             standard_terms
            FROM     APPS.hz_cust_site_uses_all       hcsua,                        
                     APPS.hz_cust_acct_sites_all      hcasa,                         
                     (                        
                       SELECT   /*+ FIRST_ROWS(10) */                      
                              hp.party_id
                             ,hp.party_name 
                             ,hzps.party_site_id
                             ,hzl.address1        
                             ,hzl.address2        
                             ,hzl.city		
                             ,hzl.state		
                             ,(CASE UPPER(TRIM(hzl.country))
                               WHEN 'US' THEN
                                     hzl.county 
                               ELSE    
                                     hzl.Province
                               END ) province     
                             ,hzl.postal_code	
                             ,(SELECT terr.territory_short_name 
                             FROM APPS.fnd_territories_tl        terr
                             WHERE terr.territory_code = hzl.country) country
                             ,hzl.country               country_code 
                             ,hca.account_number
                             ,prof.standard_terms
                             ,hca.cust_account_id
                       FROM  APPS.hz_parties          hp,                        
                             APPS.hz_party_sites      hzps,                         
                             APPS.hz_locations        hzl,
                             APPS.hz_cust_accounts    hca,
                             APPS.hz_customer_profiles   prof                        
                       WHERE hp.party_id   = hzps.party_id  
                       AND   hzps.location_id = hzl.location_id
                       AND   hzps.party_id = hca.party_id 
                       AND   hca.cust_account_id  = prof.cust_account_id   
                       AND   hzps.identifying_address_flag = 'Y'
        	           AND   TRIM(hzl.country) IN ('US','CA')                    
                       AND   hp.status     = 'A'                        
                       AND   hzps.status   = 'A'                        
                       AND   hca.status    = 'A' 
                       AND   prof.standard_terms IS NOT NULL
                       AND   prof.site_use_id  IS NULL
                       AND   (
                              (UPPER(TRIM(hp.party_name)) NOT LIKE 'OD%TEST%') OR
                              (UPPER(TRIM(hp.party_name)) NOT LIKE 'OFFICE%DEPOT%TEST%') OR
                              (UPPER(TRIM(hp.party_name)) NOT LIKE 'CAROL%TEST%')  OR
                              (UPPER(TRIM(hp.party_name)) NOT LIKE 'TEST%NAME') OR
                              (UPPER(TRIM(hp.party_name)) NOT LIKE 'TEST%CANADA') OR
                              (UPPER(TRIM(hp.party_name)) NOT LIKE 'TEST%')  OR
                              (UPPER(TRIM(hp.party_name)) NOT LIKE 'SIT0%')  OR
                              (UPPER(TRIM(hp.party_name)) NOT LIKE 'SIT%TEST%')  
                             )
                     ) party                       
            WHERE  hcasa.cust_acct_site_id          = hcsua.cust_acct_site_id                        
            AND    hcasa.cust_account_id            = party.cust_account_id                         
            AND    COALESCE(hcasa.party_site_id,0)  = COALESCE(party.party_site_id,0)                                
            AND    hcsua.site_use_code                = 'BILL_TO'
            AND    hcsua.primary_flag                 = 'Y'
            AND NOT EXISTS
                               (
                                SELECT /*+ NL_AJ */1
                                FROM   apps.ra_terms terms
                                WHERE  UPPER(terms.name) = 'IMMEDIATE'
                                AND TRUNC(sysdate) BETWEEN terms.start_date_active 
                                AND NVL(terms.end_date_active,TRUNC(sysdate))
                                AND terms.term_id = party.standard_terms   
                               )
    ) M  
    ORDER BY M.country_code
        ,M.account_number;
  	             
              
     lc_phone_number  VARCHAR2(50);
     
BEGIN
  
    
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'CUSTOMER_NUMBER|COMPANY_NAME|ADDRESS1|ADDRESS2|CITY|STATE|PROVINCE|POSTAL_CODE|COUNTRY|PHONE_NUMBER');
    
    
    FND_FILE.PUT_LINE (FND_FILE.LOG,'Start Populating main plsql table: '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    
    OPEN lcu_abl_cust;
    FETCH lcu_abl_cust 
    BULK COLLECT INTO lt_abl_cust_rec;
    CLOSE lcu_abl_cust;
    
    FND_FILE.PUT_LINE (FND_FILE.LOG,'End Populating main plsql table: '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    
    
    IF lt_abl_cust_rec.COUNT > 0 THEN
    
       FND_FILE.PUT_LINE (FND_FILE.LOG,'Start looping main plsql table: '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    
       FOR ln_idx IN lt_abl_cust_rec.FIRST..lt_abl_cust_rec.LAST
       LOOP
         
         lc_phone_number := NULL;
         
         lc_phone_number := Get_Ap_Phone(p_party_id => lt_abl_cust_rec(ln_idx).party_id);
         
         IF lc_phone_number IS NULL THEN
             lc_phone_number  := Get_Ot_Phone(p_party_id => lt_abl_cust_rec(ln_idx).party_id);
         END IF;
         
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,  
                                          lt_abl_cust_rec(ln_idx).account_number     
              			        ||'|'			
            			        ||lt_abl_cust_rec(ln_idx).account_name	
            			        ||'|'			
            			        ||lt_abl_cust_rec(ln_idx).address1		
            			        ||'|'			
            			        ||lt_abl_cust_rec(ln_idx).address2		
            			        ||'|'			  	
            			        ||lt_abl_cust_rec(ln_idx).city		
            			        ||'|'			
            			        ||lt_abl_cust_rec(ln_idx).Province
            			        ||'|'
            			        ||lt_abl_cust_rec(ln_idx).state		   
            			        ||'|'  				   
            			        ||lt_abl_cust_rec(ln_idx).postal_code
            			        ||'|'
            			        ||lt_abl_cust_rec(ln_idx).country
            			        ||'|'
            			        ||lc_phone_number
            			        ||'|'
            	                        );  
       
       END LOOP;    
       FND_FILE.PUT_LINE (FND_FILE.LOG,'End looping thru staging main plsql table: '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    END IF;
    
    lt_abl_cust_rec.delete ;
    lt_abl_cust_rec := lt_abl_cust_rec_init;
    
    
EXCEPTION
    WHEN OTHERS THEN
      lb_status := FND_CONCURRENT.SET_COMPLETION_STATUS ('ERROR', NULL);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Exception in PRINT_CUSTOMER_DETAILS: ' ||SUBSTR(SQLERRM, 1, 255));

END PRINT_CUSTOMER_DETAILS;

END XXCDH_AR_ABL_CUST_PKG_NOTAB;
/
SHOW ERRORS;
