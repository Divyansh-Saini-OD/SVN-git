SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_TM_AUTONM_UNASGND_SITES_PKG
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       :  XX_TM_AUTONM_UNASGND_SITES_PKG                                       |
-- |                                                                                |
-- | Description:                                                                   |
-- |                                                                                |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT1A   10-JUL-2009  Nabarun Ghosh            Initial draft Version.          |
-- +================================================================================+


 PROCEDURE write_log(
                      p_message IN VARCHAR2
                     )
  -- +===================================================================+
  -- | Name  : WRITE_LOG                                                 |
  -- |                                                                   |
  -- | Description:       This Procedure shall write to the concurrent   |
  -- |                    program log file                               |
  -- +===================================================================+
  
  IS
  
  BEGIN
  
     FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
  
  END write_log;
  
  
  PROCEDURE display_out(
                         p_message IN VARCHAR2
                        )
   
  IS
   
  BEGIN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
  END display_out;

 PROCEDURE fetch_wining_resources   ( p_party_site_id         IN hz_party_sites.party_site_id%TYPE 
                                     ,p_postal_code           IN hz_locations.postal_code%TYPE
                                     ,x_bulk_winners_rec_type OUT NOCOPY JTF_TERR_ASSIGN_PUB.bulk_winners_rec_type
                                    ) 
  IS

     lc_err_msg                   VARCHAR2(2000);
     ln_limit                     PLS_INTEGER := 200;
     ln_count                     PLS_INTEGER;
     
     ln_party_site_id             hz_party_sites.party_site_id%TYPE;
     lc_postal_code               hz_locations.postal_code%TYPE;
     
     lp_gen_bulk_rec              jtf_terr_assign_pub.bulk_trans_rec_type;
     lx_gen_return_rec            jtf_terr_assign_pub.bulk_winners_rec_type;
     ln_api_version               PLS_INTEGER := 1.0;
     lc_return_status             VARCHAR2(03);
     ln_msg_count                 PLS_INTEGER;
     lc_msg_data                  VARCHAR2(2000);
     l_counter                    PLS_INTEGER;
     lc_country        CONSTANT   VARCHAR2(2000) := 'US';
     
  BEGIN

     ln_party_site_id := p_party_site_id;
     lc_postal_code   := p_postal_code  ;
     
     lp_gen_bulk_rec.squal_num02.EXTEND;
     lp_gen_bulk_rec.squal_char06.EXTEND;
     --lp_gen_bulk_rec.squal_char07.EXTEND;
     lp_gen_bulk_rec.squal_char61.EXTEND;
     
     lp_gen_bulk_rec.squal_num02(1)  := ln_party_site_id;
     lp_gen_bulk_rec.squal_char06(1) := lc_postal_code;
    -- lp_gen_bulk_rec.squal_char07(1) := lc_country;
     lp_gen_bulk_rec.squal_char61(1) := lc_country;
     
     JTF_TERR_ASSIGN_PUB.get_winners(    p_api_version_number  => ln_api_version
                                       , p_init_msg_list     => FND_API.G_FALSE
                                       , p_use_type          => 'LOOKUP'
                                       , p_source_id         => -1001
                                       , p_trans_id          => -1002
                                       , p_trans_rec         => lp_gen_bulk_rec
                                       , p_resource_type     => FND_API.G_MISS_CHAR
                                       , p_role              => FND_API.G_MISS_CHAR
                                       , p_top_level_terr_id => FND_API.G_MISS_NUM
                                       , p_num_winners       => FND_API.G_MISS_NUM
                                       , x_return_status     => lc_return_status
                                       , x_msg_count         => ln_msg_count
                                       , x_msg_data          => lc_msg_data
                                       , x_winners_rec       => lx_gen_return_rec
                                 );
     IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        FOR k IN 1 .. ln_msg_count
        LOOP
           lc_msg_data := FND_MSG_PUB.GET(
                                             p_encoded     => FND_API.G_FALSE
                                           , p_msg_index => k
                                          );
           WRITE_LOG(lc_msg_data);
        END LOOP;
     ELSE
     
        x_bulk_winners_rec_type := lx_gen_return_rec;
        
     END IF;
     

  EXCEPTION

     WHEN OTHERS THEN
     lc_err_msg     := 'Unexpected error while fetching winning resources - '||SUBSTR(SQLERRM,1,250);     
     WRITE_LOG(lc_err_msg);
  END fetch_wining_resources;  
  
PROCEDURE Unasgnd_Party_Sites_Main
                                 ( x_errbuf              OUT NOCOPY  VARCHAR2 
          		          ,x_retcode             OUT NOCOPY  NUMBER
          		          ,p_party_type          IN hz_party_sites.attribute13%TYPE
          		          ,p_gdw_enriched        IN VARCHAR2
          		          ,p_from_party_site_id  IN VARCHAR2 
          		          ,p_to_party_site_id    IN VARCHAR2 
          		          ,p_chk_assignment_rule IN VARCHAR2
          		         )
AS

    lc_gdw_enriched            VARCHAR2(2000);
    lc_site_use_id             VARCHAR2(2000);
    
    ln_from_party_site_id      hz_party_sites.party_site_id%TYPE;
    ln_to_party_site_id        hz_party_sites.party_site_id%TYPE;
    lc_chk_assignment_rule     VARCHAR2(2000);
    lx_gen_return_rec          jtf_terr_assign_pub.bulk_winners_rec_type;
    lx_gen_return_rec1         jtf_terr_assign_pub.bulk_winners_rec_type;    
    
    ln_pros_counter            PLS_INTEGER;
    ln_cust_counter            PLS_INTEGER;    
    ln_resource_id             PLS_INTEGER;
    lc_resource_name           VARCHAR2(2000);
    
    lc_prospect_str            VARCHAR2(32000);
    lc_customer_str            VARCHAR2(32000);    
    
    ln_tabcnt number;
  
  lt_pro_Pros_Cust              DBMS_SQL.VARCHAR2_TABLE;     
  lt_pro_party_site_id          DBMS_SQL.NUMBER_TABLE; 
  lt_pro_party_site_num         DBMS_SQL.VARCHAR2_TABLE;     
  lt_pro_party_number           DBMS_SQL.VARCHAR2_TABLE;     
  lt_pro_party_id               DBMS_SQL.NUMBER_TABLE; 
  lt_pro_orig_system_ref        DBMS_SQL.VARCHAR2_TABLE;     
  lt_pro_account                DBMS_SQL.VARCHAR2_TABLE;     
  lt_pro_sequence               DBMS_SQL.VARCHAR2_TABLE;     
  lt_pro_party_name             DBMS_SQL.VARCHAR2_TABLE;     
  lt_pro_Address                DBMS_SQL.VARCHAR2_TABLE;     
  lt_pro_Postal_code            DBMS_SQL.VARCHAR2_TABLE;     
  lt_pro_site_use_id            DBMS_SQL.NUMBER_TABLE; 
  lt_pro_site_use_code          DBMS_SQL.VARCHAR2_TABLE;     

  lt_cus_Pros_Cust              DBMS_SQL.VARCHAR2_TABLE;     
  lt_cus_party_site_id          DBMS_SQL.NUMBER_TABLE; 
  lt_cus_party_site_num         DBMS_SQL.VARCHAR2_TABLE;     
  lt_cus_party_number           DBMS_SQL.VARCHAR2_TABLE;     
  lt_cus_party_id               DBMS_SQL.NUMBER_TABLE; 
  lt_cus_orig_system_ref        DBMS_SQL.VARCHAR2_TABLE;     
  lt_cus_account                DBMS_SQL.VARCHAR2_TABLE;     
  lt_cus_sequence               DBMS_SQL.VARCHAR2_TABLE;     
  lt_cus_party_name             DBMS_SQL.VARCHAR2_TABLE;     
  lt_cus_Address                DBMS_SQL.VARCHAR2_TABLE;     
  lt_cus_Postal_code            DBMS_SQL.VARCHAR2_TABLE;     
  lt_cus_site_use_id            DBMS_SQL.NUMBER_TABLE; 
  lt_cus_site_use_code          DBMS_SQL.VARCHAR2_TABLE;     


    
BEGIN

   
   --start_time := DBMS_UTILITY.get_time;
  
   write_log('Parameters Passed:  ');
   write_log('-----------------------------------------------------:  ');
   write_log('Party Type:  '||p_party_type);
   write_log('GDW Enriched? :  '||COALESCE(p_gdw_enriched,'N'));
   write_log('From Party Siye Id: '||p_from_party_site_id);
   write_log('To Party Siye Id: '||p_to_party_site_id ); 
   write_log('Check Rules For Assignments? : '||p_chk_assignment_rule ); 
   write_log('-----------------------------------------------------:  ');
   
   lc_gdw_enriched        := COALESCE(p_gdw_enriched,'N');
   ln_from_party_site_id  := TO_NUMBER(p_from_party_site_id);
   ln_to_party_site_id    := TO_NUMBER(p_to_party_site_id);
   lc_chk_assignment_rule := p_chk_assignment_rule;

   lc_prospect_str :=   NULL;
   lc_customer_str :=   NULL;   
   
                               lc_prospect_str := q'[SELECT   
				                  'PROSPECT'                Prospect_Customer,
				                  hps.party_site_id         party_site_id,
				                  hps.party_site_number     party_site_number,
				                  hp.party_number           party_number,
				                  hps.party_id              party_id,
				                  hps.orig_system_reference orig_system_reference,
				                  REGEXP_SUBSTR(hps.orig_system_reference,'[[:digit:]]+',1,1) account,
				                  COALESCE((REGEXP_SUBSTR(hps.orig_system_reference,'[[:digit:]]+',1,2)),(REGEXP_SUBSTR(hps.orig_system_reference,'^.....'))) sequence,
				                  hp.party_name             party_name,
				                  (
				                     hl.address1
				                  || '.'
				                  || hl.address2
				                  || '.'
				                  || hl.address3
				                  || '.'
				                  || hl.address4
				                  || '.'
				                  || hl.state
				                  || '.'
				                  || hl.county
				                  || '.'
				                  || hl.city
				                  || '.'
				                  || hl.postal_code
				                  )                            Address,
				                  hl.postal_code               postal_code,
				                  -1                           site_use_id,
				                  'NA'                           site_use       
				           FROM  apps.hz_parties               HP ,
				                 apps.hz_party_sites           HPS ,
				                 apps.hz_locations             HL,
				                 (SELECT HPSB.party_site_id
						  FROM apps.hz_party_sites_ext_b HPSB
						       ,apps.ego_attr_groups_v EAGV ]';
						  
						  IF lc_gdw_enriched = 'Y' THEN
                                                     lc_prospect_str := lc_prospect_str || q'[ ,apps.hz_imp_batch_summary HIBS ]';
                                                  END IF;   
						       
			                    lc_prospect_str := lc_prospect_str || q'[ WHERE EAGV.attr_group_type = 'HZ_PARTY_SITES_GROUP'
						  AND EAGV.attr_group_name   = 'SITE_DEMOGRAPHICS'
						  AND HPSB.attr_group_id     = EAGV.attr_group_id ]';
				    IF lc_gdw_enriched = 'Y' THEN				       
				       lc_prospect_str := lc_prospect_str || q'[ AND HIBS.batch_id  = HPSB.n_ext_attr20 AND HIBS.original_system = 'GDW' ]';
				    END IF;						  
					          
					   lc_prospect_str := lc_prospect_str || q'[ ) EXT 
				           WHERE HP.party_type                = 'ORGANIZATION' 
				           AND   HP.attribute13               = 'PROSPECT'
				           AND   HPS.status                   = 'A'
				           AND   HP.status                    = 'A'
				           AND   HP.party_id                  = HPS.party_id ]';
				    IF  ln_from_party_site_id IS NOT NULL AND
				        ln_to_party_site_id IS NOT NULL THEN
				        lc_prospect_str := lc_prospect_str || q'[ AND (HPS.party_site_id BETWEEN ]'||ln_from_party_site_id||q'[ and ]'|| ln_to_party_site_id||q'[ ) ]';
				    ELSIF ln_from_party_site_id IS NOT NULL AND
				          ln_to_party_site_id IS NULL THEN
				          lc_prospect_str := lc_prospect_str || q'[ AND (HPS.party_site_id >= ]'||ln_from_party_site_id||q'[ ) ]';				    
				    ELSIF ln_from_party_site_id IS NULL AND
				          ln_to_party_site_id IS NOT NULL THEN
				          lc_prospect_str := lc_prospect_str || q'[ AND (HPS.party_site_id <= ]'||ln_to_party_site_id||q'[ ) ]';				    
				    END IF;
				    
				    lc_prospect_str := lc_prospect_str || q'[
                                    AND HPS.location_id              = HL.location_id  
                                    AND EXT.party_site_id     = hps.party_site_id 
				    AND   NOT EXISTS
							     (SELECT 1
							     FROM apps.xx_tm_nam_terr_defn TERR ,
							       apps.xx_tm_nam_terr_entity_dtls TERR_ENT ,
							       apps.xx_tm_nam_terr_rsc_dtls TERR_RSC
							     WHERE TERR.named_acct_terr_id = TERR_ENT.named_acct_terr_id
							     AND TERR_ENT.named_acct_terr_id   = TERR_RSC.named_acct_terr_id
							     AND SYSDATE BETWEEN TERR.start_date_active AND COALESCE(TERR.end_date_active,SYSDATE)
							     AND SYSDATE BETWEEN TERR_ENT.start_date_active AND COALESCE(TERR_ENT.end_date_active,SYSDATE)
							     AND SYSDATE BETWEEN TERR_RSC.start_date_active AND COALESCE(TERR_RSC.end_date_active,SYSDATE)
							     AND COALESCE(TERR.status,'A')     = 'A'
							     AND COALESCE(TERR_ENT.status,'A') = 'A'
							     AND COALESCE(TERR_RSC.status,'A') = 'A'
							     AND TERR_ENT.entity_type     = 'PARTY_SITE'
                                                             AND TERR_ENT.entity_id       = hps.party_site_id
                                                           )]';


                               lc_customer_str := q'[SELECT 'CUSTOMER'      Prospect_Customer,
				                  hps.party_site_id         party_site_id,
				                  hps.party_site_number     party_site_number,
				                  hp.party_number           party_number,
				                  hps.party_id              party_id,
				                  hps.orig_system_reference orig_system_reference,
				                  REGEXP_SUBSTR(hps.orig_system_reference,'[[:digit:]]+',1,1) account,
				                  COALESCE((REGEXP_SUBSTR(hps.orig_system_reference,'[[:digit:]]+',1,2)),(REGEXP_SUBSTR(hps.orig_system_reference,'^.....'))) sequence,
				                  hp.party_name             party_name,
				                  (
				                     hl.address1
				                  || '.'
				                  || hl.address2
				                  || '.'
				                  || hl.address3
				                  || '.'
				                  || hl.address4
				                  || '.'
				                  || hl.state
				                  || '.'
				                  || hl.county
				                  || '.'
				                  || hl.city
				                  || '.'
				                  || hl.postal_code
				                  )                              Address,
				                  hl.postal_code                 postal_code,
				                  hcsu.site_use_id               site_use_id,
				                  hcsu.site_use_code             site_use       
				           FROM  apps.hz_parties               HP ,
					         apps.hz_party_sites           HPS ,
					   	 apps.hz_locations             HL , 
					   	 apps.hz_cust_accounts         HCA,
					   	 apps.hz_cust_acct_sites   HCASA ,
				                 apps.hz_cust_site_uses    HCSU
				           WHERE HP.party_type                = 'ORGANIZATION' 
				           AND   HP.attribute13               = 'CUSTOMER'
				           AND   HPS.status                   = 'A'
				           AND   HP.status                    = 'A'
				           AND   HP.party_id                  = HPS.party_id ]';
				           
				    IF  ln_from_party_site_id IS NOT NULL AND
				        ln_to_party_site_id IS NOT NULL THEN
				        lc_customer_str := lc_customer_str || q'[ AND (HPS.party_site_id BETWEEN ]'||ln_from_party_site_id||q'[ and ]'|| ln_to_party_site_id||q'[ ) ]';
				    ELSIF ln_from_party_site_id IS NOT NULL AND
				          ln_to_party_site_id IS NULL THEN
				          lc_customer_str := lc_customer_str || q'[ AND (HPS.party_site_id >= ]'||ln_from_party_site_id||q'[ ) ]';				    
				    ELSIF ln_from_party_site_id IS NULL AND
				          ln_to_party_site_id IS NOT NULL THEN
				          lc_customer_str := lc_customer_str || q'[ AND (HPS.party_site_id <= ]'||ln_to_party_site_id||q'[ ) ]';				    
				    END IF;
				    
				    lc_customer_str := lc_customer_str || q'[ AND   HPS.location_id   = HL.location_id
				           AND   HL.country                  = 'US'          
				           AND   HP.party_id                  = HCA.party_id
				           AND   HCA.status = 'A'
				           AND   COALESCE(HCA.customer_type, 'X') <> 'I'
				           AND   HCA.attribute18              = 'CONTRACT'          
				           AND   HCA.cust_account_id          = HCASA.cust_account_id
				           AND   HCASA.cust_acct_site_id      = HCSU.cust_acct_site_id
				           AND   COALESCE(HCASA.party_site_id,0)   = COALESCE(HPS.party_site_id,0)   
				           AND   NOT EXISTS  (SELECT 1
					   		      FROM apps.xx_tm_nam_terr_defn TERR ,
					   			   apps.xx_tm_nam_terr_entity_dtls TERR_ENT ,
					   			   apps.xx_tm_nam_terr_rsc_dtls TERR_RSC
					   		      WHERE TERR.named_acct_terr_id = TERR_ENT.named_acct_terr_id
					   		      --AND TERR.named_acct_terr_id   = TERR_RSC.named_acct_terr_id
					   		      AND TERR_ENT.named_acct_terr_id   = TERR_RSC.named_acct_terr_id
					   		      AND SYSDATE BETWEEN TERR.start_date_active AND COALESCE(TERR.end_date_active,SYSDATE)
					   		      AND SYSDATE BETWEEN TERR_ENT.start_date_active AND COALESCE(TERR_ENT.end_date_active,SYSDATE)
					   		      AND SYSDATE BETWEEN TERR_RSC.start_date_active AND COALESCE(TERR_RSC.end_date_active,SYSDATE)
					   		      AND COALESCE(TERR.status,'A')     = 'A'
					   		      AND COALESCE(TERR_ENT.status,'A') = 'A'
					   		      AND COALESCE(TERR_RSC.status,'A') = 'A'
					   		      AND TERR_ENT.entity_type     = 'PARTY_SITE'
					                      AND TERR_ENT.entity_id  = hps.party_site_id
					                      ) ]';
				    
      --Write_log('Prospect SQL Statement: '||lc_prospect_str);                                                     
       --+-----------------------------------------------------------------------------------+
       --|Displaying the output                                                              | 
       --+-----------------------------------------------------------------------------------+
       
   Display_Out(
                 RPAD('PARTY_TYPE'             ,11) ||CHR(9)
               ||RPAD('PARTY_SITE_NUMBER'      ,16) ||CHR(9)
               ||RPAD('PARTY_NUMBER'           ,10) ||CHR(9)
               ||RPAD('ORIG_SYSTEM_REFERENCE'  ,21) ||CHR(9)
               ||RPAD('ACCOUNT'                ,12) ||CHR(9)                   
               ||RPAD('SEQUENCE'               ,10) ||CHR(9)
               ||RPAD('PARTY_NAME'             ,35) ||CHR(9)                   
               ||RPAD('ADDRESS'                ,50) ||CHR(9)
               ||RPAD('SITE_USE_ID'            ,11) ||CHR(9)
               ||RPAD('SITE_USE_CODE'          ,8)  ||CHR(9)
               ||RPAD('SALES_PERSONS_NAME'     ,25) ||CHR(9)
               --||CHR(10)                   
              );
   

   lc_site_use_id  :=   NULL;
   ln_resource_id  :=   NULL;
   
   IF p_party_type = 'PROSPECT' THEN
     
      EXECUTE IMMEDIATE lc_prospect_str
      BULK COLLECT INTO   lt_pro_Pros_Cust      
      			, lt_pro_party_site_id  
      			, lt_pro_party_site_num 
      			, lt_pro_party_number   
      			, lt_pro_party_id       
      			, lt_pro_orig_system_ref
      			, lt_pro_account        
      			, lt_pro_sequence       
      			, lt_pro_party_name     
      			, lt_pro_Address        
      			, lt_pro_Postal_code    
      			, lt_pro_site_use_id    
      			, lt_pro_site_use_code  
                        ;  
      
      
   ELSIF p_party_type = 'CUSTOMER' THEN
   
     --DBMS_SESSION.free_unused_user_memory;
      EXECUTE IMMEDIATE lc_customer_str
      BULK COLLECT INTO   lt_cus_Pros_Cust      
      			, lt_cus_party_site_id  
      			, lt_cus_party_site_num 
      			, lt_cus_party_number   
      			, lt_cus_party_id       
      			, lt_cus_orig_system_ref
      			, lt_cus_account        
      			, lt_cus_sequence       
      			, lt_cus_party_name     
      			, lt_cus_Address        
      			, lt_cus_Postal_code    
      			, lt_cus_site_use_id    
      			, lt_cus_site_use_code  
                        ;  

   ELSE
      EXECUTE IMMEDIATE lc_prospect_str
      BULK COLLECT INTO   lt_pro_Pros_Cust      
      			, lt_pro_party_site_id  
      			, lt_pro_party_site_num 
      			, lt_pro_party_number   
      			, lt_pro_party_id       
      			, lt_pro_orig_system_ref
      			, lt_pro_account        
      			, lt_pro_sequence       
      			, lt_pro_party_name     
      			, lt_pro_Address        
      			, lt_pro_Postal_code    
      			, lt_pro_site_use_id    
      			, lt_pro_site_use_code  
                        ;  

      EXECUTE IMMEDIATE lc_customer_str
      BULK COLLECT INTO   lt_cus_Pros_Cust      
      			, lt_cus_party_site_id  
      			, lt_cus_party_site_num 
      			, lt_cus_party_number   
      			, lt_cus_party_id       
      			, lt_cus_orig_system_ref
      			, lt_cus_account        
      			, lt_cus_sequence       
      			, lt_cus_party_name     
      			, lt_cus_Address        
      			, lt_cus_Postal_code    
      			, lt_cus_site_use_id    
      			, lt_cus_site_use_code  
                        ;  
   END IF;     
   
   IF p_party_type = 'PROSPECT' THEN

     ln_pros_counter := 0;     
     IF lt_pro_Pros_Cust.count > 0 THEN
     
      FOR ln_pros_rows IN lt_pro_Pros_Cust.FIRST..lt_pro_Pros_Cust.LAST
      LOOP   
         IF lt_pro_site_use_id(ln_pros_rows) = -1 THEN
            lc_site_use_id  := 'NA';
         ELSE
            lc_site_use_id :=  TO_CHAR(lt_pro_site_use_id(ln_pros_rows));
         END IF; 

       IF lc_chk_assignment_rule = 'Y' AND lc_chk_assignment_rule IS NOT NULL THEN
     
          fetch_wining_resources   (  p_party_site_id         => lt_pro_party_site_id(ln_pros_rows)
		                     ,p_postal_code           => lt_pro_Postal_code(ln_pros_rows) 
		                     ,x_bulk_winners_rec_type => lx_gen_return_rec
	                           ); 
	         
          ln_pros_counter := COALESCE(lx_gen_return_rec.resource_id.FIRST,0);
        
          IF ln_pros_counter > 0 THEN
        
            WHILE (ln_pros_counter <= lx_gen_return_rec.resource_id.LAST)
            LOOP
            
             ln_resource_id := lx_gen_return_rec.resource_id(ln_pros_counter);
             
             SELECT resource_name
             INTO   lc_resource_name
             FROM   jtf_rs_resource_extns_vl
             WHERE  resource_id = ln_resource_id;
             
             Display_Out(     RPAD(COALESCE(lt_pro_Pros_Cust(ln_pros_rows),'--')     ,11)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_site_num(ln_pros_rows),'--')     ,16)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_number(ln_pros_rows),'--')          ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_orig_system_ref(ln_pros_rows),'--') ,21)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_account(ln_pros_rows),'--')               ,12)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_sequence(ln_pros_rows),'--')              ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_name(ln_pros_rows),'--')            ,35)||chr(9) 
        		    ||RPAD(COALESCE(lt_pro_Address(ln_pros_rows),'--')               ,50)||chr(9)      
        		    ||RPAD(lc_site_use_id                                        ,11)||chr(9)       
        		    ||RPAD(COALESCE(lt_pro_site_use_code(ln_pros_rows),'--')         ,8) ||chr(9)
        		    ||RPAD(COALESCE(lc_resource_name                             ,'--') ,25)||chr(9)
            		    );
               ln_pros_counter := ln_pros_counter + 1; 
               
            END LOOP;
           
          ELSE
             Display_Out(     RPAD(COALESCE(lt_pro_Pros_Cust(ln_pros_rows),'--')     ,11)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_site_num(ln_pros_rows),'--')     ,16)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_number(ln_pros_rows),'--')          ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_orig_system_ref(ln_pros_rows),'--') ,21)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_account(ln_pros_rows),'--')               ,12)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_sequence(ln_pros_rows),'--')              ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_name(ln_pros_rows),'--')            ,35)||chr(9) 
        		    ||RPAD(COALESCE(lt_pro_Address(ln_pros_rows),'--')               ,50)||chr(9)      
        		    ||RPAD(lc_site_use_id                                        ,11)||chr(9)       
        		    ||RPAD(COALESCE(lt_pro_site_use_code(ln_pros_rows),'--')         ,8) ||chr(9)
        		    );
        
          END IF;--IF ln_counter > 0 THEN
       ELSE
       
             ln_pros_counter := 0;             
             Display_Out(     RPAD(COALESCE(lt_pro_Pros_Cust(ln_pros_rows),'--')     ,11)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_site_num(ln_pros_rows),'--')     ,16)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_number(ln_pros_rows),'--')          ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_orig_system_ref(ln_pros_rows),'--') ,21)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_account(ln_pros_rows),'--')               ,12)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_sequence(ln_pros_rows),'--')              ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_name(ln_pros_rows),'--')            ,35)||chr(9) 
        		    ||RPAD(COALESCE(lt_pro_Address(ln_pros_rows),'--')               ,50)||chr(9)      
        		    ||RPAD(lc_site_use_id                                        ,11)||chr(9)       
        		    ||RPAD(COALESCE(lt_pro_site_use_code(ln_pros_rows),'--')         ,8) ||chr(9)
        		    );
       
       END IF; --IF lc_chk_assignment_rule = 'Y'
      END LOOP; 
     END IF  ; --IF lt_Prospect_Customer.count > 0 
     
     lt_pro_Pros_Cust.DELETE;    
     lt_pro_party_site_id.DELETE;        
     lt_pro_party_site_num.DELETE;    
     lt_pro_party_number.DELETE;         
     lt_pro_party_id.DELETE;             
     lt_pro_orig_system_ref.DELETE;
     lt_pro_account.DELETE;              
     lt_pro_sequence.DELETE;             
     lt_pro_party_name.DELETE;           
     lt_pro_Address.DELETE;              
     lt_pro_Postal_code.DELETE;          
     lt_pro_site_use_id.DELETE;          
     lt_pro_site_use_code.DELETE;        

     --end_time := DBMS_UTILITY.get_time;
     --write_log('Tab Count At the end of report('||ln_tabcnt||'): '||to_char(end_time-start_time)); 
   
   ELSIF p_party_type = 'CUSTOMER' THEN  --IF p_party_type is CUSTOMER

     ln_tabcnt := lt_cus_Pros_Cust.count;
     ln_cust_counter := 0;

     IF lt_cus_Pros_Cust.count > 0 THEN
     
      FOR ln_pros_rows IN lt_cus_Pros_Cust.FIRST..lt_cus_Pros_Cust.LAST
      LOOP   
         
       IF lc_chk_assignment_rule = 'Y' AND lc_chk_assignment_rule IS NOT NULL THEN
     
          fetch_wining_resources   (  p_party_site_id         => lt_cus_party_site_id(ln_pros_rows)
		                     ,p_postal_code           => lt_cus_Postal_code(ln_pros_rows) 
		                     ,x_bulk_winners_rec_type => lx_gen_return_rec
	                           ); 
	         
          ln_cust_counter := COALESCE(lx_gen_return_rec.resource_id.FIRST,0);
        
          IF ln_cust_counter > 0 THEN
        
            WHILE (ln_cust_counter <= lx_gen_return_rec.resource_id.LAST)
            LOOP
            
             ln_resource_id := lx_gen_return_rec.resource_id(ln_cust_counter);
             
             SELECT resource_name
             INTO   lc_resource_name
             FROM   jtf_rs_resource_extns_vl
             WHERE  resource_id = ln_resource_id;
             
             Display_Out(     RPAD(COALESCE(lt_cus_Pros_Cust(ln_pros_rows),'--')     ,11)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_site_num(ln_pros_rows),'--')     ,16)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_number(ln_pros_rows),'--')          ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_orig_system_ref(ln_pros_rows),'--') ,21)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_account(ln_pros_rows),'--')               ,12)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_sequence(ln_pros_rows),'--')              ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_name(ln_pros_rows),'--')            ,35)||chr(9) 
        		    ||RPAD(COALESCE(lt_cus_Address(ln_pros_rows),'--')               ,50)||chr(9)      
        		    ||RPAD(COALESCE(TO_CHAR(lt_cus_site_use_id(ln_pros_rows)),'--')   ,11)||chr(9)      
        		    ||RPAD(COALESCE(lt_cus_site_use_code(ln_pros_rows),'--')         ,8) ||chr(9)
        		    ||RPAD(COALESCE(lc_resource_name,'--')                       ,25)||chr(9)
            		    );
               ln_cust_counter := ln_cust_counter + 1; 
               
            END LOOP;
           
          ELSE
             ln_cust_counter := 0;             
             Display_Out(     RPAD(COALESCE(lt_cus_Pros_Cust(ln_pros_rows),'--')     ,11)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_site_num(ln_pros_rows),'--')     ,16)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_number(ln_pros_rows),'--')          ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_orig_system_ref(ln_pros_rows),'--') ,21)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_account(ln_pros_rows),'--')               ,12)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_sequence(ln_pros_rows),'--')              ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_name(ln_pros_rows),'--')            ,35)||chr(9) 
        		    ||RPAD(COALESCE(lt_cus_Address(ln_pros_rows),'--')               ,50)||chr(9)      
        		    ||RPAD(COALESCE(TO_CHAR(lt_cus_site_use_id(ln_pros_rows)),'--')   ,11)||chr(9)       
        		    ||RPAD(COALESCE(lt_cus_site_use_code(ln_pros_rows),'--')         ,8) ||chr(9)
        		    );
        
          END IF;--IF ln_counter > 0 THEN
       ELSE
       
             Display_Out(     RPAD(COALESCE(lt_cus_Pros_Cust(ln_pros_rows),'--')     ,11)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_site_num(ln_pros_rows),'--')     ,16)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_number(ln_pros_rows),'--')          ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_orig_system_ref(ln_pros_rows),'--') ,21)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_account(ln_pros_rows),'--')               ,12)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_sequence(ln_pros_rows),'--')              ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_name(ln_pros_rows),'--')            ,35)||chr(9) 
        		    ||RPAD(COALESCE(lt_cus_Address(ln_pros_rows),'--')               ,50)||chr(9)      
        		    ||RPAD(COALESCE(TO_CHAR(lt_cus_site_use_id(ln_pros_rows)),'--')   ,11)||chr(9)       
        		    ||RPAD(COALESCE(lt_cus_site_use_code(ln_pros_rows),'--')         ,8) ||chr(9)
        		    );
       
       END IF; --IF lc_chk_assignment_rule = 'Y'
      END LOOP; 
     END IF  ; --IF lt_Prospect_Customer.count > 0 
     
     lt_cus_Pros_Cust.DELETE;    
     lt_cus_party_site_id.DELETE;        
     lt_cus_party_site_num.DELETE;    
     lt_cus_party_number.DELETE;         
     lt_cus_party_id.DELETE;             
     lt_cus_orig_system_ref.DELETE;
     lt_cus_account.DELETE;              
     lt_cus_sequence.DELETE;             
     lt_cus_party_name.DELETE;           
     lt_cus_Address.DELETE;              
     lt_cus_Postal_code.DELETE;          
     lt_cus_site_use_id.DELETE;          
     lt_cus_site_use_code.DELETE;        
     
     --end_time := DBMS_UTILITY.get_time;
     --write_log('Tab Count At the end of report('||ln_tabcnt||'): '||to_char(end_time-start_time)); 
   
   ELSE    --IF p_party_type is both PROSPECT and CUSTOMER

     --/--Call Prodpect Display
     --------------------------

     ln_pros_counter := 0;     
     IF lt_pro_Pros_Cust.count > 0 THEN
     
      FOR ln_pros_rows IN lt_pro_Pros_Cust.FIRST..lt_pro_Pros_Cust.LAST
      LOOP   
         IF lt_pro_site_use_id(ln_pros_rows) = -1 THEN
            lc_site_use_id  := 'NA';
         ELSE
            lc_site_use_id :=  TO_CHAR(lt_pro_site_use_id(ln_pros_rows));
         END IF; 

       IF lc_chk_assignment_rule = 'Y' AND lc_chk_assignment_rule IS NOT NULL THEN
     
          fetch_wining_resources   (  p_party_site_id         => lt_pro_party_site_id(ln_pros_rows)
		                     ,p_postal_code           => lt_pro_Postal_code(ln_pros_rows) 
		                     ,x_bulk_winners_rec_type => lx_gen_return_rec
	                           ); 
	         
          ln_pros_counter := COALESCE(lx_gen_return_rec.resource_id.FIRST,0);
        
          IF ln_pros_counter > 0 THEN
        
            WHILE (ln_pros_counter <= lx_gen_return_rec.resource_id.LAST)
            LOOP
            
             ln_resource_id := lx_gen_return_rec.resource_id(ln_pros_counter);
             
             SELECT resource_name
             INTO   lc_resource_name
             FROM   jtf_rs_resource_extns_vl
             WHERE  resource_id = ln_resource_id;
             
             Display_Out(     RPAD(COALESCE(lt_pro_Pros_Cust(ln_pros_rows),'--')     ,11)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_site_num(ln_pros_rows),'--')     ,16)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_number(ln_pros_rows),'--')          ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_orig_system_ref(ln_pros_rows),'--') ,21)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_account(ln_pros_rows),'--')               ,12)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_sequence(ln_pros_rows),'--')              ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_name(ln_pros_rows),'--')            ,35)||chr(9) 
        		    ||RPAD(COALESCE(lt_pro_Address(ln_pros_rows),'--')               ,50)||chr(9)      
        		    ||RPAD(lc_site_use_id                                        ,11)||chr(9)       
        		    ||RPAD(COALESCE(lt_pro_site_use_code(ln_pros_rows),'--')         ,8) ||chr(9)
        		    ||RPAD(COALESCE(lc_resource_name                             ,'--') ,25)||chr(9)
            		    );
               ln_pros_counter := ln_pros_counter + 1; 
               
            END LOOP;
           
          ELSE
             Display_Out(     RPAD(COALESCE(lt_pro_Pros_Cust(ln_pros_rows),'--')     ,11)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_site_num(ln_pros_rows),'--')     ,16)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_number(ln_pros_rows),'--')          ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_orig_system_ref(ln_pros_rows),'--') ,21)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_account(ln_pros_rows),'--')               ,12)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_sequence(ln_pros_rows),'--')              ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_name(ln_pros_rows),'--')            ,35)||chr(9) 
        		    ||RPAD(COALESCE(lt_pro_Address(ln_pros_rows),'--')               ,50)||chr(9)      
        		    ||RPAD(lc_site_use_id                                        ,11)||chr(9)       
        		    ||RPAD(COALESCE(lt_pro_site_use_code(ln_pros_rows),'--')         ,8) ||chr(9)
        		    );
        
          END IF;--IF ln_counter > 0 THEN
       ELSE
       
             ln_pros_counter := 0;             
             Display_Out(     RPAD(COALESCE(lt_pro_Pros_Cust(ln_pros_rows),'--')     ,11)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_site_num(ln_pros_rows),'--')     ,16)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_number(ln_pros_rows),'--')          ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_orig_system_ref(ln_pros_rows),'--') ,21)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_account(ln_pros_rows),'--')               ,12)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_sequence(ln_pros_rows),'--')              ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_pro_party_name(ln_pros_rows),'--')            ,35)||chr(9) 
        		    ||RPAD(COALESCE(lt_pro_Address(ln_pros_rows),'--')               ,50)||chr(9)      
        		    ||RPAD(lc_site_use_id                                        ,11)||chr(9)       
        		    ||RPAD(COALESCE(lt_pro_site_use_code(ln_pros_rows),'--')         ,8) ||chr(9)
        		    );
       
       END IF; --IF lc_chk_assignment_rule = 'Y'
      END LOOP; 
     END IF  ; --IF lt_Prospect_Customer.count > 0 
     
     lt_pro_Pros_Cust.DELETE;    
     lt_pro_party_site_id.DELETE;        
     lt_pro_party_site_num.DELETE;    
     lt_pro_party_number.DELETE;         
     lt_pro_party_id.DELETE;             
     lt_pro_orig_system_ref.DELETE;
     lt_pro_account.DELETE;              
     lt_pro_sequence.DELETE;             
     lt_pro_party_name.DELETE;           
     lt_pro_Address.DELETE;              
     lt_pro_Postal_code.DELETE;          
     lt_pro_site_use_id.DELETE;          
     lt_pro_site_use_code.DELETE;  
     
     
     --/--Call Customer Display
     --------------------------
     ln_cust_counter := 0;

     IF lt_cus_Pros_Cust.count > 0 THEN
     
      FOR ln_pros_rows IN lt_cus_Pros_Cust.FIRST..lt_cus_Pros_Cust.LAST
      LOOP   
         
       IF lc_chk_assignment_rule = 'Y' AND lc_chk_assignment_rule IS NOT NULL THEN
     
          fetch_wining_resources   (  p_party_site_id         => lt_cus_party_site_id(ln_pros_rows)
		                     ,p_postal_code           => lt_cus_Postal_code(ln_pros_rows) 
		                     ,x_bulk_winners_rec_type => lx_gen_return_rec
	                           ); 
	         
          ln_cust_counter := COALESCE(lx_gen_return_rec.resource_id.FIRST,0);
        
          IF ln_cust_counter > 0 THEN
        
            WHILE (ln_cust_counter <= lx_gen_return_rec.resource_id.LAST)
            LOOP
            
             ln_resource_id := lx_gen_return_rec.resource_id(ln_cust_counter);
             
             SELECT resource_name
             INTO   lc_resource_name
             FROM   jtf_rs_resource_extns_vl
             WHERE  resource_id = ln_resource_id;
             
             Display_Out(     RPAD(COALESCE(lt_cus_Pros_Cust(ln_pros_rows),'--')     ,11)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_site_num(ln_pros_rows),'--')     ,16)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_number(ln_pros_rows),'--')          ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_orig_system_ref(ln_pros_rows),'--') ,21)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_account(ln_pros_rows),'--')               ,12)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_sequence(ln_pros_rows),'--')              ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_name(ln_pros_rows),'--')            ,35)||chr(9) 
        		    ||RPAD(COALESCE(lt_cus_Address(ln_pros_rows),'--')               ,50)||chr(9)      
        		    ||RPAD(COALESCE(TO_CHAR(lt_cus_site_use_id(ln_pros_rows)),'--')   ,11)||chr(9)      
        		    ||RPAD(COALESCE(lt_cus_site_use_code(ln_pros_rows),'--')         ,8) ||chr(9)
        		    ||RPAD(COALESCE(lc_resource_name,'--')                       ,25)||chr(9)
            		    );
               ln_cust_counter := ln_cust_counter + 1; 
               
            END LOOP;
           
          ELSE
             ln_cust_counter := 0;             
             Display_Out(     RPAD(COALESCE(lt_cus_Pros_Cust(ln_pros_rows),'--')     ,11)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_site_num(ln_pros_rows),'--')     ,16)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_number(ln_pros_rows),'--')          ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_orig_system_ref(ln_pros_rows),'--') ,21)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_account(ln_pros_rows),'--')               ,12)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_sequence(ln_pros_rows),'--')              ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_name(ln_pros_rows),'--')            ,35)||chr(9) 
        		    ||RPAD(COALESCE(lt_cus_Address(ln_pros_rows),'--')               ,50)||chr(9)      
        		    ||RPAD(COALESCE(TO_CHAR(lt_cus_site_use_id(ln_pros_rows)),'--')   ,11)||chr(9)       
        		    ||RPAD(COALESCE(lt_cus_site_use_code(ln_pros_rows),'--')         ,8) ||chr(9)
        		    );
        
          END IF;--IF ln_counter > 0 THEN
       ELSE
       
             Display_Out(     RPAD(COALESCE(lt_cus_Pros_Cust(ln_pros_rows),'--')     ,11)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_site_num(ln_pros_rows),'--')     ,16)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_number(ln_pros_rows),'--')          ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_orig_system_ref(ln_pros_rows),'--') ,21)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_account(ln_pros_rows),'--')               ,12)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_sequence(ln_pros_rows),'--')              ,10)||chr(9)
        		    ||RPAD(COALESCE(lt_cus_party_name(ln_pros_rows),'--')            ,35)||chr(9) 
        		    ||RPAD(COALESCE(lt_cus_Address(ln_pros_rows),'--')               ,50)||chr(9)      
        		    ||RPAD(COALESCE(TO_CHAR(lt_cus_site_use_id(ln_pros_rows)),'--')   ,11)||chr(9)       
        		    ||RPAD(COALESCE(lt_cus_site_use_code(ln_pros_rows),'--')         ,8) ||chr(9)
        		    );
       
       END IF; --IF lc_chk_assignment_rule = 'Y'
      END LOOP; 
     END IF  ; --IF lt_Prospect_Customer.count > 0 
     
     lt_cus_Pros_Cust.DELETE;    
     lt_cus_party_site_id.DELETE;        
     lt_cus_party_site_num.DELETE;    
     lt_cus_party_number.DELETE;         
     lt_cus_party_id.DELETE;             
     lt_cus_orig_system_ref.DELETE;
     lt_cus_account.DELETE;              
     lt_cus_sequence.DELETE;             
     lt_cus_party_name.DELETE;           
     lt_cus_Address.DELETE;              
     lt_cus_Postal_code.DELETE;          
     lt_cus_site_use_id.DELETE;          
     lt_cus_site_use_code.DELETE;        
     
   END IF; --End of IF p_party_type = 'PROSPECT'     
        
END Unasgnd_Party_Sites_Main;

END XX_TM_AUTONM_UNASGND_SITES_PKG;  
/
SHOW ERRORS;
--EXIT;