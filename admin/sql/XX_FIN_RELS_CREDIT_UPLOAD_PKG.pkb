create or replace
PACKAGE BODY XX_FIN_RELS_CREDIT_UPLOAD_PKG AS


-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       Oracle AMS                                       |
-- +========================================================================+
-- | Name        : XX_FIN_RELS_CREDIT_UPLOAD_PKG                            |
-- | Description : 1) Bulk import OD_FIN_HIER Relationships and credit Limit|
-- |                  into Oracle.                                          |
-- |                                                                        |
-- | RICE : E3056                                                           |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      05-MAY-2013  Dheeraj V            Initial version, QC 22804    |
-- |1.1      10-DEC-2013  Paddy Sanjeevi       Changed to BO_API Created    |
-- |                                           by module Defect 26964       |
-- |1.2      10-NOV-2015  Havish Kasina        Removed the schema references|
-- |                                           as per R12.2 Retrofit Changes|
-- +========================================================================+
  
  PROCEDURE write_log
  (
    p_message IN VARCHAR2
  )
  IS
  BEGIN
    fnd_file.put_line (fnd_file.log,p_message);
  END write_log;
  
  
  FUNCTION create_rel
  (
    p_parent_party_number IN hz_parties.party_number%TYPE,
    p_relationship_type IN hz_relationships.relationship_code%TYPE,
    p_child_party_number IN hz_parties.party_number%TYPE,
    p_start_date IN VARCHAR2,
    p_end_date IN VARCHAR2
  )
  RETURN VARCHAR2 
  AS
  
  le_invalid_input EXCEPTION;
  ln_p_partyid hz_parties.party_id%TYPE;
  ln_c_partyid hz_parties.party_id%TYPE;
  lc_error_str VARCHAR2(1000);
  lc_succ_str VARCHAR2(100);
  lc_entity VARCHAR2(100);
  ln_reltype_id NUMBER;
  ld_s_date DATE;
  ld_e_date DATE;
  
  lr_rel_rec hz_relationship_v2pub.relationship_rec_type;
  lc_ret_status VARCHAR2(1);
  ln_msg_count NUMBER;
  lc_msg_data VARCHAR2(1000);
  ln_party_ovn NUMBER;
  ln_cr_rel_id NUMBER;
  ln_cr_party_id NUMBER;
  ln_cr_party_number NUMBER;
  
  
  
  BEGIN
  
    write_log ('Starting create_rel procedure');
    
        BEGIN
          lc_entity := 'parent_party_number';
          SELECT party_id INTO ln_p_partyid
          from hz_parties where party_number = p_parent_party_number;
          
          lc_entity := 'child_party_number';
          SELECT party_id INTO ln_c_partyid
          from hz_parties where party_number = p_child_party_number;
          
          lc_entity := 'relationship_type';
          SELECT relationship_type_id INTO ln_reltype_id
          from hz_relationship_types 
          where relationship_type = 'OD_FIN_HIER'
          and forward_rel_code = p_relationship_type;
          
          lc_entity := 'start_date';
          IF p_start_date IS NOT NULL
          THEN
            SELECT to_date(p_start_date,'MM/DD/YYYY') INTO ld_s_date
            FROM DUAL;
          ELSE
            lc_entity := 'start_date cannot be blank';
            RAISE le_invalid_input;          
          END IF;
                    
          lc_entity := 'end_date';
          SELECT to_date(p_end_date,'MM/DD/YYYY') INTO ld_e_date
          FROM DUAL;          
          
          lc_entity := 'start_date cannot be greater than end_date';
          IF (ld_s_date > ld_e_date) THEN
            RAISE le_invalid_input ;
          END IF;
          
          
        EXCEPTION
        WHEN le_invalid_input THEN
         RETURN 'FALSE_Error","Invalid Input :'||lc_entity;
        
        WHEN OTHERS THEN
          RETURN 'FALSE_Error","Invalid Input :'||lc_entity;
        
        END;
    
        write_log ('Input data validated, calling API to create rels');
        
        
        lr_rel_rec := NULL;
        
        lr_rel_rec.subject_id            := ln_p_partyid;
        lr_rel_rec.subject_type          := 'ORGANIZATION';
        lr_rel_rec.subject_table_name    := 'HZ_PARTIES';
        lr_rel_rec.object_id             := ln_c_partyid;
        lr_rel_rec.object_type           := 'ORGANIZATION';
        lr_rel_rec.object_table_name     := 'HZ_PARTIES';
        lr_rel_rec.relationship_code     := p_relationship_type;
        lr_rel_rec.relationship_type     := 'OD_FIN_HIER';
        lr_rel_rec.start_date            := ld_s_date;
        lr_rel_rec.end_date              := ld_e_date;
        lr_rel_rec.created_by_module     := 'BO_API';
       
        hz_relationship_v2pub.create_relationship (p_init_msg_list               => FND_API.G_TRUE,
                                                   p_relationship_rec            => lr_rel_rec,
                                                   x_relationship_id             => ln_cr_rel_id,
                                                   x_party_id                    => ln_cr_party_id,
                                                   x_party_number                => ln_cr_party_number,
                                                   x_return_status               => lc_ret_status,
                                                   x_msg_count                   => ln_msg_count,
                                                   x_msg_data                    => lc_msg_data,
                                                   p_create_org_contact          => NULL
                                                   );
               
               IF lc_ret_status <> FND_API.G_RET_STS_SUCCESS THEN
                lc_msg_data:=NULL;
                  IF (ln_msg_count>0) THEN
                    FOR counter IN 1 .. ln_msg_count
                    LOOP
                    lc_msg_data := lc_msg_data || ' ' || fnd_msg_pub.GET(counter,fnd_api.g_false);
                    END LOOP;
                  END IF;
      						fnd_msg_pub.DELETE_MSG;
                  write_log( 'Error : '||lc_msg_data);
                  
                  RETURN 'FALSE_Error","'||lc_msg_data;
               ELSE
                  lc_succ_str := 'Created relationship_id: '|| ln_cr_rel_id;
                  write_log(lc_succ_str);
                  COMMIT;
                  RETURN 'TRUE'||'Success","'||lc_succ_str;
               END IF;             
    
  EXCEPTION
  WHEN OTHERS THEN
  
    RETURN 'FALSE_EXCEPTION : '||SQLERRM;    
    
  END create_rel;
  
  
  FUNCTION remove_rel
  (
    p_parent_party_number IN hz_parties.party_number%TYPE,
    p_relationship_type IN hz_relationships.relationship_code%TYPE,
    p_child_party_number IN hz_parties.party_number%TYPE,
    p_end_date IN VARCHAR2
  )
  RETURN VARCHAR2
  AS

  le_invalid_input EXCEPTION;
  ln_p_partyid hz_parties.party_id%TYPE;
  ln_c_partyid hz_parties.party_id%TYPE;
  lc_error_str VARCHAR2(1000);
  lc_succ_str VARCHAR2(100);
  lc_entity VARCHAR2(100);
  ln_reltype_id NUMBER;
  ld_e_date DATE;

  lr_rel_rec hz_relationship_v2pub.relationship_rec_type;
  lc_ret_status VARCHAR2(1);
  ln_msg_count NUMBER;
  lc_msg_data VARCHAR2(1000);
  ln_party_ovn NUMBER;
  ln_cr_rel_id NUMBER;
  ln_cr_party_id NUMBER;
  ln_cr_party_number NUMBER;
  lc_relship_id hz_relationships.relationship_id%TYPE;
  ln_ovn NUMBER;
  
  BEGIN
    
    write_log ('Starting remove_rel procedure');

        BEGIN
          
          lc_entity := 'parent_party_number';
          SELECT party_id INTO ln_p_partyid
          from hz_parties where party_number = p_parent_party_number;
          
          lc_entity := 'child_party_number';
          SELECT party_id INTO ln_c_partyid
          from hz_parties where party_number = p_child_party_number;
          
          lc_entity := 'relationship_type';
          SELECT relationship_type_id INTO ln_reltype_id
          from hz_relationship_types 
          where relationship_type = 'OD_FIN_HIER'
          and forward_rel_code = p_relationship_type;
                  
          lc_entity := 'end_date';
          IF p_end_date IS NOT NULL
          THEN
            SELECT to_date(p_end_date,'MM/DD/YYYY') INTO ld_e_date
            FROM DUAL;
          ELSE
            lc_entity := 'end_date cannot be blank';
            RAISE le_invalid_input;          
          END IF;
                    
        EXCEPTION
        WHEN le_invalid_input THEN
         RETURN 'FALSE_Error","Invalid Input :'||lc_entity;
        
        WHEN OTHERS THEN
          RETURN 'FALSE_Error","Invalid Input :'||lc_entity;
        
        END;

        write_log ('Input data validated, calling API to remove rels');
    
        BEGIN

        
        SELECT relationship_id, object_version_number into lc_relship_id, ln_ovn
        FROM hz_relationships 
        WHERE relationship_type='OD_FIN_HIER'
        AND subject_id=ln_p_partyid
        AND object_id=ln_c_partyid
        AND status='A'
        AND sysdate between start_date and NVL(end_date, sysdate+1)
        AND relationship_code = p_relationship_type;


        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN 'FALSE_Error","Active Relationship not found';

        WHEN OTHERS THEN
          RETURN 'FALSE_Error","Active Relationship not found, Error : '|| SQLERRM;

        END;


        lr_rel_rec.relationship_id := lc_relship_id;
        lr_rel_rec.status          := 'I';
        lr_rel_rec.end_date        := ld_e_date;
        
        hz_relationship_v2pub.update_relationship ( p_init_msg_list                 => FND_API.G_TRUE
                                                   ,p_relationship_rec              => lr_rel_rec
                                                   ,p_object_version_number         => ln_ovn
                                                   ,p_party_object_version_number   => ln_party_ovn
                                                   ,x_return_status                 => lc_ret_status
                                                   ,x_msg_count                     => ln_msg_count
                                                   ,x_msg_data                      => lc_msg_data );
         
               IF lc_ret_status <> FND_API.G_RET_STS_SUCCESS THEN
                lc_msg_data:=NULL;
                  IF (ln_msg_count>0) THEN
                    FOR counter IN 1 .. ln_msg_count
                    LOOP
                    lc_msg_data := lc_msg_data || ' ' || fnd_msg_pub.GET(counter,fnd_api.g_false);
                    END LOOP;
                  END IF;
      						fnd_msg_pub.DELETE_MSG;
                  write_log( 'Error : '||lc_msg_data);
                  
                  RETURN 'FALSE_Error"," '||lc_msg_data;
               ELSE
                  lc_succ_str := 'Removed relationship_id : '|| lc_relship_id;
                  write_log(lc_succ_str);
                  COMMIT;
                  RETURN 'TRUE'||'Success","'||lc_succ_str;
               END IF;
  
  EXCEPTION
  WHEN OTHERS THEN
  
    RETURN 'FALSE_Error","  '||SQLERRM;    
  
  END remove_rel;
  
 
  FUNCTION credit_update
  (
    p_account_number IN hz_cust_accounts.account_number%TYPE,
    p_credit_limit IN hz_cust_profile_amts.overall_credit_limit%TYPE,
    p_currency_code IN hz_cust_profile_amts.currency_code%TYPE
  )
  RETURN VARCHAR2
  AS

  le_invalid_input EXCEPTION;
  ln_cust_acct_id hz_cust_accounts.cust_account_id%TYPE;
  lc_curr_code hz_cust_profile_amts.currency_code%TYPE;
  ln_cr_limit hz_cust_profile_amts.overall_credit_limit%TYPE;
  ln_cust_prof_id hz_customer_profiles.cust_account_profile_id%TYPE;
  lr_amt_rec hz_customer_profile_v2pub.cust_profile_amt_rec_type;
  ln_prof_amt_id hz_cust_profile_amts.cust_acct_profile_amt_id%TYPE;
  lc_error_str VARCHAR2(1000);
  lc_succ_str VARCHAR2(100);
  lc_entity VARCHAR2(100);


  lc_return_status VARCHAR2(1);
  ln_msg_count NUMBER;
  lc_msg_data VARCHAR2(1000);
  ln_site_prf_amt_id NUMBER;
  ln_ovn NUMBER;
  
  BEGIN

    write_log ('Starting credit_update procedure');

        BEGIN
          
          lc_entity := 'account_number';
          SELECT cust_account_id INTO ln_cust_acct_id
          from hz_cust_accounts where account_number = p_account_number;
          
          IF p_currency_code IS NOT NULL
          THEN          
            lc_entity := 'currency_code';
            
            SELECT currency_code INTO lc_curr_code
            FROM fnd_currencies 
            WHERE currency_code = p_currency_code
            AND enabled_flag = 'Y'
            AND currency_flag = 'Y';  
            
          ELSE
            lc_curr_code := 'USD';
          END IF;
          
          lc_entity := 'credit_limit';
          SELECT to_number (p_credit_limit) INTO ln_cr_limit
          FROM DUAL;
          
          
        EXCEPTION
        WHEN le_invalid_input THEN
         RETURN 'FALSE_Error","Invalid Input '||lc_entity;
        
        WHEN OTHERS THEN
          RETURN 'FALSE_Error","Invalid Input '||lc_entity;
        
        END;

        write_log ('Input data validated, calling API to update credit limit');


        BEGIN
        
          SELECT cust_account_profile_id INTO ln_cust_prof_id
          FROM hz_customer_profiles 
          WHERE cust_account_id = ln_cust_acct_id
          AND site_use_id IS NULL;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN 'FALSE_Error","Customer profile does not exist';

        WHEN OTHERS THEN
          RETURN 'FALSE_Error","Error retrieving customer profile, '|| SQLERRM;

        END;
        
        
        
        BEGIN
        
          SELECT cust_acct_profile_amt_id, object_version_number
          INTO ln_prof_amt_id, ln_ovn
          FROM hz_cust_profile_amts
          WHERE cust_account_profile_id = ln_cust_prof_id
          AND currency_code = lc_curr_code;
        
          write_log('Updating credit limit');
          
          lr_amt_rec := NULL;
          lr_amt_rec.cust_acct_profile_amt_id := ln_prof_amt_id;
          lr_amt_rec.overall_credit_limit := ln_cr_limit;
          lr_amt_rec.trx_credit_limit := ln_cr_limit;

          hz_customer_profile_v2pub.update_cust_profile_amt(
                          p_init_msg_list                      => FND_API.G_TRUE,
                          p_cust_profile_amt_rec               => lr_amt_rec,
                          p_object_version_number              => ln_ovn,
                          x_return_status                      => lc_return_status,
                          x_msg_count                          => ln_msg_count,
                          x_msg_data                           => lc_msg_data
                        );          

               IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                lc_msg_data:=NULL;
                  IF (ln_msg_count>0) THEN
                    FOR counter IN 1 .. ln_msg_count
                    LOOP
                    lc_msg_data := lc_msg_data || ' ' || fnd_msg_pub.GET(counter,fnd_api.g_false);
                    END LOOP;
                  END IF;
      						fnd_msg_pub.DELETE_MSG;
                  write_log( 'Error : '||lc_msg_data);
                  
                  RETURN 'FALSE_Error","'||lc_msg_data;
               ELSE
                  lc_succ_str := 'Credit limit updated ';
                  write_log(lc_succ_str);
                  RETURN 'TRUE'||'Success","'||lc_succ_str;
               END IF;        
        
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
        
          write_log('Creating credit limit ');
          
          lr_amt_rec := NULL;
          lr_amt_rec.cust_account_id := ln_cust_acct_id;
          lr_amt_rec.cust_account_profile_id := ln_cust_prof_id;
          lr_amt_rec.currency_code := lc_curr_code;
          lr_amt_rec.overall_credit_limit := ln_cr_limit;
          lr_amt_rec.trx_credit_limit := ln_cr_limit;
          lr_amt_rec.created_by_module := 'BO_API';
          
          hz_customer_profile_v2pub.create_cust_profile_amt(
                          p_init_msg_list                      => FND_API.G_TRUE,
                          p_check_foreign_key                  => FND_API.G_FALSE,
                          p_cust_profile_amt_rec               => lr_amt_rec,
                          x_cust_acct_profile_amt_id           => ln_site_prf_amt_id,
                          x_return_status                      => lc_return_status,
                          x_msg_count                          => ln_msg_count,
                          x_msg_data                           => lc_msg_data
                        );

               IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                lc_msg_data:=NULL;
                  IF (ln_msg_count>0) THEN
                    FOR counter IN 1 .. ln_msg_count
                    LOOP
                    lc_msg_data := lc_msg_data || ' ' || fnd_msg_pub.GET(counter,fnd_api.g_false);
                    END LOOP;
                  END IF;
      						fnd_msg_pub.DELETE_MSG;
                  write_log( 'Error :'||lc_msg_data);
                  
                  RETURN 'FALSE_Error","'||lc_msg_data;
               ELSE
                  lc_succ_str := 'Created Credit with cust_acct_profile_amt_id: '|| ln_site_prf_amt_id;
                  write_log(lc_succ_str);
                  COMMIT;
                  RETURN 'TRUE'||'Success","'||lc_succ_str;
               END IF;
        
        WHEN OTHERS THEN
        
          RETURN 'FALSE_Error","Error while updating credit :'||SQLERRM;  
          
        END;
  
    
  EXCEPTION
  WHEN OTHERS THEN
  
    RETURN 'FALSE_Error","'||SQLERRM;    
  
  END credit_update;
   
  
END XX_FIN_RELS_CREDIT_UPLOAD_PKG;
/
SHOW ERRORS;