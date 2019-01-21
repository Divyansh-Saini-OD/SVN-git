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

CREATE OR REPLACE PACKAGE BODY XXCDH_AR_ABL_CUST_AC_TEL_PKG
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
-- |Draft 1.0 02-DEC-09   Nabarun Ghosh                Draft version                     |
-- |V1.0      22-Feb-10   nabarun Ghosh                Incorporated the below performan	 |
-- |                                                   -ce advices from performance team:|
-- |                                                   Added the hint LEADING on the 02  |
-- |                                                   Functions.			 |
-- |                                                   Removed Parallel from the cursor	 |
-- |                                                   lcu_abl_cust.			 |
-- |						       Moved up the hz_customer_profile  |
-- |						       and ra_terms as inline view	 |
-- |V1.1      22-Feb-10   nabarun Ghosh		       Vladimir's suggestion as below:   |
-- |											 |
-- |                                                   Added rel.OBJECT_TABLE_NAME =     |
-- |						       'HZ_PARTIES'  		         |
-- |						       Removed the join acct_role.party_id|
-- |						       = rel.party_id	from the function|
-- |V1.2      23-Feb-10   Nabarun Ghosh                Made the subquery seperate and then|
-- |                                                   Join the out to site uses tables. | 
-- |											 |
-- +=====================================================================================+
AS

PROCEDURE Get_Ap_Phone(p_party_id          IN NUMBER
		      ,p_cust_account_id   IN NUMBER
		      ,p_cust_acct_site_id IN NUMBER
		      ,p_account_number    IN VARCHAR2
		      ,p_phone_number      OUT NOCOPY VARCHAR2
		      ,p_email_id          OUT NOCOPY VARCHAR2
		      ,p_contact_name      OUT NOCOPY VARCHAR2
		     )
IS
  
  lc_phone_number VARCHAR2(100);
  lc_email_id     VARCHAR2(100);
  lc_contact_name VARCHAR2(500);
  
BEGIN

         lc_email_id	 := NULL;
         lc_contact_name := NULL;
         lc_phone_number := NULL;

          
          SELECT 
	         REGEXP_REPLACE(cont_point.phone_area_code||cont_point.phone_number,'([[:digit:]]{3})([[:digit:]]{3})([[:digit:]]{4})','\1-\2-\3') phone_number
	        ,(SELECT email_address 
	          FROM   hz_contact_points 
	          WHERE  owner_table_id = rel.party_id
	          AND    contact_point_type = 'EMAIL'
	          AND    status = 'A'
	          AND rownum = 1
	         )  email_address       
	        ,(party.person_last_name||' '||party.person_first_name) contact_name
	  INTO   lc_phone_number
	        ,lc_email_id
	        ,lc_contact_name
	  FROM   APPS.hz_cust_accounts      role_acct,
	         APPS.hz_cust_account_roles acct_role,
	         APPS.hz_relationships      rel,
	         APPS.hz_contact_points     cont_point,
	         APPS.hz_parties            party,
	         APPS.hz_org_contacts       org_cont
	  WHERE  role_acct.party_id = p_party_id
	  AND    role_acct.cust_account_id = acct_role.cust_account_id||''
	  AND    role_acct.party_id = rel.object_id 
	  AND    acct_role.party_id = rel.party_id
	  AND    rel.party_id       = cont_point.owner_table_id 
	  AND    rel.subject_id     = party.party_id
	  AND    rel.relationship_id = org_cont.party_relationship_id
	  AND    rel.relationship_code = 'CONTACT_OF'
	  AND    rel.object_table_name = 'HZ_PARTIES'
	  AND    role_acct.status = 'A'
	  AND    acct_role.role_type = 'CONTACT'
	  AND    acct_role.status = 'A'
	  AND    rel.status = 'A'
	  AND    COALESCE(cont_point.phone_line_type,'GEN') = 'GEN'
	  AND    cont_point.contact_point_type = 'PHONE'
	  AND    cont_point.status = 'A'
	  AND    cont_point.owner_table_name = 'HZ_PARTIES'
	  AND    party.person_last_name IS NOT NULL
	  AND    party.status = 'A'
	  AND    (TRIM(UPPER(org_cont.job_title))= 'AP' OR (TRIM(UPPER(org_cont.job_title)) LIKE 'ACCOUNT%PAY%'))
	  AND    org_cont.status = 'A'
	  AND    role_acct.account_number    = p_account_number
	  AND    acct_role.cust_account_id   = p_cust_account_id
	  AND    acct_role.cust_acct_site_id = p_cust_acct_site_id
          AND ROWNUM = 1 ;

          p_phone_number  := lc_phone_number;
          p_email_id      := lc_email_id;
          p_contact_name  := lc_contact_name;
          
  
EXCEPTION
  
  WHEN OTHERS THEN
  lc_email_id	  := NULL;
  lc_contact_name := NULL;
  lc_phone_number := NULL;
  
  p_email_id      := lc_email_id;
  p_contact_name  := lc_contact_name;
  p_phone_number  := lc_phone_number;
  
  
END Get_Ap_Phone;
          

PROCEDURE Get_Ot_Phone(p_party_id          IN NUMBER
		      ,p_cust_account_id   IN NUMBER
		      ,p_cust_acct_site_id IN NUMBER
		      ,p_account_number    IN VARCHAR2
		      ,p_phone_number      OUT NOCOPY VARCHAR2
		      ,p_email_id          OUT NOCOPY VARCHAR2
		      ,p_contact_name      OUT NOCOPY VARCHAR2
		     )
IS
  
  lc_phone_number VARCHAR2(100);
  lc_email_id     VARCHAR2(100);
  lc_contact_name VARCHAR2(500);
  
BEGIN   
            
         lc_email_id	 := NULL;
         lc_contact_name := NULL;
         lc_phone_number := NULL;

	SELECT 
	       REGEXP_REPLACE(cont_point.phone_area_code||cont_point.phone_number,'([[:digit:]]{3})([[:digit:]]{3})([[:digit:]]{4})','\1-\2-\3') phone_number
	      ,(SELECT email_address   
	        FROM   hz_contact_points 
	        WHERE  owner_table_id = rel.party_id
	        AND    contact_point_type = 'EMAIL'
	        AND    status = 'A'
	        AND rownum = 1
	       )  email_address       
	      ,(party.person_last_name||' '||party.person_first_name) contact_name
	INTO   lc_phone_number
	      ,lc_email_id
	      ,lc_contact_name
	FROM   APPS.hz_cust_accounts      role_acct,
	       APPS.hz_cust_account_roles acct_role,
	       APPS.hz_relationships      rel,
	       APPS.hz_contact_points     cont_point,
	       APPS.hz_parties            party
	WHERE  role_acct.party_id = p_party_id
	AND    role_acct.cust_account_id = acct_role.cust_account_id||''
	AND    role_acct.party_id = rel.object_id 
	AND    acct_role.party_id = rel.party_id
	AND    rel.party_id       = cont_point.owner_table_id 
	AND    rel.subject_id     = party.party_id
	AND    rel.relationship_code = 'CONTACT_OF'
	AND    rel.object_table_name = 'HZ_PARTIES'
	AND    role_acct.status = 'A'
	AND    acct_role.role_type = 'CONTACT'
	AND    acct_role.status = 'A'
	AND    rel.status = 'A'
	AND    COALESCE(cont_point.phone_line_type,'GEN') = 'GEN'
	AND    cont_point.contact_point_type = 'PHONE'
	AND    cont_point.status = 'A'
	AND    cont_point.owner_table_name = 'HZ_PARTIES'
	AND    party.person_last_name IS NOT NULL
	AND    party.status = 'A'
	AND    role_acct.account_number    = p_account_number
	AND    acct_role.cust_account_id   = p_cust_account_id
	AND    acct_role.cust_acct_site_id = p_cust_acct_site_id
	AND ROWNUM = 1  ;  

          p_phone_number  := lc_phone_number;
          p_email_id      := lc_email_id;
          p_contact_name  := lc_contact_name;

  
EXCEPTION
  WHEN OTHERS THEN
  
  lc_email_id	  := NULL;
  lc_contact_name := NULL;
  lc_phone_number := NULL;
  p_email_id      := lc_email_id;
  p_contact_name  := lc_contact_name;
  p_phone_number  := lc_phone_number;
  
END Get_Ot_Phone;

FUNCTION Get_abl_cust_Details 
RETURN XXCDH_AR_ABL_CUST_AC_TEL_PKG.lt_subq_func
PIPELINED
 
IS

  CURSOR lcu_sub_query
  IS
            WITH cust_profile AS
              (SELECT /*+ NO_MERGE */
                      cust_prof.cust_account_id,
                      cust_prof.standard_terms
               FROM    APPS.hz_customer_profiles   cust_prof
               WHERE   cust_prof.standard_terms IS NOT NULL
               AND     cust_prof.site_use_id    IS NULL
               AND NOT EXISTS
                           ( SELECT /*+ NL_AJ */
                                    1
                             FROM    APPS.ra_terms terms
                             WHERE   UPPER(TERMS.NAME) = 'IMMEDIATE'
                             AND     TRUNC(SYSDATE) BETWEEN TERMS.start_date_active AND NVL(TERMS.end_date_active,TRUNC(SYSDATE))
                             AND     terms.term_id = cust_prof.standard_terms
                           )
              ) 
              ,Party AS
               (
                SELECT /*+ FIRST_ROWS(10) */
                       hp.party_id          party_id
                      ,hp.party_name        party_name
                FROM   APPS.hz_parties      hp   
                WHERE  hp.status             = 'A'
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
              ) 
              SELECT     party.party_id          party_id
                        ,party.party_name        party_name
                        ,hca.account_number   account_number
                        ,hzps.party_site_id   party_site_id
                        ,hzl.address1         address1   
                        ,hzl.address2         address2 
                        ,hzl.city		city
                        ,hzl.state		state
                        ,hzl.Province         province     
                        ,hzl.postal_code      postal_code 	
                        ,(CASE hzl.country
                          WHEN 'US' THEN
                                'United States'
                          ELSE    
                                'Canada'
                          END )               country     
                         ,hzl.country         country_code 
                         ,hca.cust_account_id cust_account_id
                  FROM  cust_profile             prof,     	                                           
                        APPS.hz_cust_accounts    hca,
                        party                    party,
                        APPS.hz_party_sites      hzps, 
                        APPS.hz_locations        hzl   
                  WHERE prof.cust_account_id = hca.cust_account_id
                  AND   hca.party_id         = party.party_id
                  AND   party.party_id       = hzps.party_id
                  AND   hzps.location_id     = hzl.location_id
                  AND   hzps.identifying_address_flag = 'Y'
                  AND   TRIM(hzl.country) IN ('US','CA')                    
                  AND   hzps.status   = 'A'                        
                  AND   hca.status    = 'A';
     
     
     lc_err_msg                   VARCHAR2(300);
     t_abl_cust_row               xxcdh_abl_cust_rec;  
     
     TYPE ltab_subq_cur_rec  IS TABLE OF lcu_sub_query%ROWTYPE INDEX BY PLS_INTEGER; 
     lt_subq_cur_rec         ltab_subq_cur_rec; 

     
     
BEGIN

        OPEN  lcu_sub_query;
        FETCH lcu_sub_query BULK COLLECT INTO lt_subq_cur_rec;
        CLOSE lcu_sub_query;
                
        IF lt_subq_cur_rec.COUNT > 0 THEN
        
         FOR i IN 1 .. lt_subq_cur_rec.COUNT 
         LOOP

          XXCDH_AR_ABL_CUST_AC_TEL_PKG.lrec_subq_func_out.party_id         :=  lt_subq_cur_rec(i).party_id          ;
          XXCDH_AR_ABL_CUST_AC_TEL_PKG.lrec_subq_func_out.party_name       :=  lt_subq_cur_rec(i).party_name        ;
          XXCDH_AR_ABL_CUST_AC_TEL_PKG.lrec_subq_func_out.account_number   :=  lt_subq_cur_rec(i).account_number    ;
          XXCDH_AR_ABL_CUST_AC_TEL_PKG.lrec_subq_func_out.party_site_id    :=  lt_subq_cur_rec(i).party_site_id     ;
          XXCDH_AR_ABL_CUST_AC_TEL_PKG.lrec_subq_func_out.address1         :=  lt_subq_cur_rec(i).address1          ;
          XXCDH_AR_ABL_CUST_AC_TEL_PKG.lrec_subq_func_out.address2         :=  lt_subq_cur_rec(i).address2          ;
          XXCDH_AR_ABL_CUST_AC_TEL_PKG.lrec_subq_func_out.city             :=  lt_subq_cur_rec(i).city              ;
          XXCDH_AR_ABL_CUST_AC_TEL_PKG.lrec_subq_func_out.state            :=  lt_subq_cur_rec(i).state             ;
          XXCDH_AR_ABL_CUST_AC_TEL_PKG.lrec_subq_func_out.province         :=  lt_subq_cur_rec(i).province          ;
          XXCDH_AR_ABL_CUST_AC_TEL_PKG.lrec_subq_func_out.postal_code      :=  lt_subq_cur_rec(i).postal_code       ;
          XXCDH_AR_ABL_CUST_AC_TEL_PKG.lrec_subq_func_out.country          :=  lt_subq_cur_rec(i).country           ;
          XXCDH_AR_ABL_CUST_AC_TEL_PKG.lrec_subq_func_out.country_code     :=  lt_subq_cur_rec(i).country_code      ;
          XXCDH_AR_ABL_CUST_AC_TEL_PKG.lrec_subq_func_out.cust_account_id  :=  lt_subq_cur_rec(i).cust_account_id	 ;	
          
          
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'party_site_id: ' ||lt_subq_cur_rec(i).party_site_id);
          
          PIPE ROW (XXCDH_AR_ABL_CUST_AC_TEL_PKG.lrec_subq_func_out);							
     															 
         END LOOP;													 
     
        END IF;
     
     RETURN;  

EXCEPTION

     WHEN OTHERS THEN
     lc_err_msg     := 'Unexpected error: Function: Get_abl_cust_Details: - '||SUBSTR(SQLERRM,1,250);
     FND_FILE.PUT_LINE (FND_FILE.LOG, 'Exception in Get_abl_cust_Details: ' ||lc_err_msg);
  
END Get_abl_cust_Details;


PROCEDURE PRINT_CUSTOMER_DETAILS ( p_errbuf    OUT NOCOPY VARCHAR2
                                 , p_retcode   OUT NOCOPY VARCHAR2               
                                 )
AS


    lb_status               BOOLEAN;
    
    CURSOR lcu_abl_cust     
    IS
    SELECT /*+ NO_MERGE(CUST) */
           DISTINCT
           CUST.country_code
          ,CUST.account_number
          ,CUST.account_name
          ,CUST.address1
          ,CUST.address2
          ,CUST.city
          ,CUST.state
          ,CUST.Province
          ,CUST.postal_code
          ,CUST.country
          ,CUST.party_id
          ,CUST.cust_account_id
          ,CUST.cust_acct_site_id
    FROM(  
           SELECT 
    	            subq_func.party_id        
    		   ,subq_func.party_name    account_name    
    		   ,subq_func.account_number  
    		   ,subq_func.party_site_id   
    		   ,subq_func.address1        
    		   ,subq_func.address2       
    		   ,subq_func.city           
    		   ,subq_func.state           
    		   ,subq_func.province        
    		   ,subq_func.postal_code    
    		   ,subq_func.country         
    		   ,subq_func.country_code    
    		   ,subq_func.cust_account_id
    		   ,hcasa.cust_acct_site_id
    	   FROM  TABLE(XXCDH_AR_ABL_CUST_AC_TEL_PKG.Get_abl_cust_Details) subq_func,
    	          APPS.hz_cust_site_uses_all                               hcsua,
    	          APPS.hz_cust_acct_sites_all                              hcasa
    	   WHERE  hcsua.site_use_code     = 'BILL_TO'
    	   AND    hcsua.PRIMARY_FLAG      = 'Y'
    	   AND    hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
     	   AND    hcasa.cust_account_id   = subq_func.cust_account_id
    	   AND    hcasa.party_site_id     = subq_func.party_site_id
    	   
       ) CUST
       ORDER BY CUST.country_code
               ,CUST.account_number;
    
      lc_phone_number VARCHAR2(100);
      lc_email_id     VARCHAR2(100);
      lc_contact_name VARCHAR2(500);
      
      
BEGIN
  
  
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'CUSTOMER_NUMBER|COMPANY_NAME|ADDRESS1|ADDRESS2|CITY|STATE|PROVINCE|POSTAL_CODE|COUNTRY|PHONE_NUMBER|EMAIL_ADDRESS|CONTACT_NAME');
    
    OPEN lcu_abl_cust;
    FETCH lcu_abl_cust 
    BULK COLLECT INTO lt_abl_cust_rec;
    CLOSE lcu_abl_cust;
    
    IF lt_abl_cust_rec.COUNT > 0 THEN
     
         FOR i IN lt_abl_cust_rec.FIRST..lt_abl_cust_rec.LAST
         LOOP 
         
        
          lc_phone_number := NULL;
          
          Get_Ap_Phone(
                        p_party_id           => lt_abl_cust_rec(i).party_id
                       ,p_cust_account_id    => lt_abl_cust_rec(i).cust_account_id
                       ,p_cust_acct_site_id  => lt_abl_cust_rec(i).cust_acct_site_id
                       ,p_account_number     => lt_abl_cust_rec(i).account_number
                       ,p_phone_number       => lc_phone_number
                       ,p_email_id           => lc_email_id
                       ,p_contact_name       => lc_contact_name
                      );
         
          IF lc_phone_number IS NULL THEN
             lc_phone_number := NULL;
             lc_email_id     := NULL;
             lc_contact_name := NULL;
             
             Get_Ot_Phone(
                           p_party_id           => lt_abl_cust_rec(i).party_id
                          ,p_cust_account_id    => lt_abl_cust_rec(i).cust_account_id
                          ,p_cust_acct_site_id  => lt_abl_cust_rec(i).cust_acct_site_id
                          ,p_account_number     => lt_abl_cust_rec(i).account_number
                          ,p_phone_number       => lc_phone_number
                          ,p_email_id           => lc_email_id
                          ,p_contact_name       => lc_contact_name
                         );
          END IF;
          
          IF lc_phone_number IS NULL THEN 
            
            lc_phone_number := NULL;
            lc_email_id     := NULL;
            lc_contact_name := NULL;
            
            BEGIN
            
                   SELECT REGEXP_REPLACE(cont_point.phone_area_code||cont_point.phone_number,'([[:digit:]]{3})([[:digit:]]{3})([[:digit:]]{4})','\1-\2-\3') phone_number
	                 ,(SELECT email_address 
	                   FROM   hz_contact_points 
	                   WHERE  owner_table_id = rel.party_id
	                   AND    contact_point_type = 'EMAIL'
	                   AND    status = 'A'
	                   AND rownum = 1
	                  )  email_address       
	                 ,(party.person_last_name||' '||party.person_first_name) contact_name 
	           INTO    lc_phone_number
	                  ,lc_email_id
	                  ,lc_contact_name
	           FROM   APPS.hz_relationships   rel 
	                 ,APPS.hz_parties         party
	                 ,APPS.hz_contact_points  cont_point
	           WHERE  REL.object_id                 =  lt_abl_cust_rec(i).party_id
	           AND    REL.object_table_name         = 'HZ_PARTIES'
	           AND    REL.status                    = 'A'
	           AND    REL.relationship_code         = 'CONTACT_OF'
	           AND    rel.subject_id                = party.party_id
	           AND    party.person_last_name IS NOT NULL
		   AND    party.status = 'A'
	           AND    REL.party_id                  = cont_point.owner_table_id 
	           AND    cont_point.contact_point_type = 'PHONE'
	           AND    cont_point.status             = 'A'
	           AND    cont_point.owner_table_name   = 'HZ_PARTIES'     
	           AND    COALESCE(cont_point.phone_line_type,'GEN') = 'GEN'
	           AND    ROWNUM = 1;
            
            EXCEPTION
             WHEN NO_DATA_FOUND THEN
               lc_phone_number := NULL;
               lc_email_id     := NULL;
               lc_contact_name := NULL;
             WHEN OTHERS THEN
               lc_phone_number := NULL;
               lc_email_id     := NULL;
               lc_contact_name := NULL;
            END;   
               
          END IF;

          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,  
                                          lt_abl_cust_rec(i).account_number     
      	   			        ||'|'			
  				        ||lt_abl_cust_rec(i).account_name		
  				        ||'|'			
  				        ||lt_abl_cust_rec(i).address1		
  				        ||'|'			
  				        ||lt_abl_cust_rec(i).address2		
  				        ||'|'			  				        		
  				        ||lt_abl_cust_rec(i).city			
  				        ||'|'			
  				        ||lt_abl_cust_rec(i).state
  				        ||'|'
  				        ||lt_abl_cust_rec(i).Province		     
  				        ||'|'  				        
  				        ||lt_abl_cust_rec(i).postal_code
  				        ||'|'
  				        ||lt_abl_cust_rec(i).country
  				        ||'|'
  				        ||lc_phone_number
  				        ||'|'
  				        ||lc_email_id
  				        ||'|'
  				        ||lc_contact_name  				        
  		                        );  
  	
  	
       END LOOP;
       
    END IF;

    lt_abl_cust_rec.delete;
    lt_abl_cust_rec := lt_abl_cust_rec_init;
    
EXCEPTION
    WHEN OTHERS THEN
      lb_status := FND_CONCURRENT.SET_COMPLETION_STATUS ('ERROR', NULL);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Exception in PRINT_CUSTOMER_DETAILS: ' ||SUBSTR(SQLERRM, 1, 255));

END PRINT_CUSTOMER_DETAILS;

END XXCDH_AR_ABL_CUST_AC_TEL_PKG;
/
SHOW ERRORS;
