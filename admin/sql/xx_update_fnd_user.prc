/*
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAC Consulting Organization                 |
-- +===================================================================+
-- | Name        :  XX_UPDATE_FND_USER.prc                             |
-- | Description :  Procedure for E1328_BSD_iReceivables_interface     |
-- |                conversion                                         |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  03-Oct-2007 Ramesh Raghupathi Initial draft version      |
-- +===================================================================+
*/
CREATE OR REPLACE PROCEDURE xx_update_fnd_user
IS
  ln_party_id hz_parties.party_id%TYPE;
  ln_retcode  number;
  ln_org_id   number;  

  --  CONSTANTS  
  gcn_site_key  CONSTANT varchar2(20) := '001'; 
  gcn_us_resp   CONSTANT number       := 50778;
  gcn_ca_resp   CONSTANT number       := 50779;
  gcn_null_resp CONSTANT number       := 0;


  CURSOR lc_fetch_conv_cur
  IS
  SELECT * from xxcrm.xx_external_users
  WHERE nvl(load_status,0) in (0, 'CONVERTED', 'ERROR' ); 
BEGIN

  ln_party_id := NULL;
  ln_retcode  := NULL;

  FOR lc_fetch_conv_rec in lc_fetch_conv_cur 
  LOOP  
    xx_get_party_id ( p_cust_acct_cnt_os  => 'A0'
                    , p_cust_acct_cnt_osr => lc_fetch_conv_rec.contact_osr
                    , x_party_id          => ln_party_id
                    , x_retcode           => ln_retcode
                    );

    IF ln_retcode = 1 or ln_party_id IS NULL   
    THEN
      update xxcrm.xx_external_users set load_status = 'ERROR'
                                       , last_update_date = SYSDATE
      where userid = lc_fetch_conv_rec.userid;  

      xx_com_error_log_pub.log_error
      ( p_application_name        => 'E1328_BSDNET_iReceivables'
      , p_program_type            => 'CONVERSION'
      , p_program_name            => 'XX_UPDATE_FND_USER'
      , p_module_name             => 'CDH'
      , p_error_message_code      => 'XX_CDH_0006_PARTY_ID_NULL'
      , p_error_message           => ' Party id null for:'|| lc_fetch_conv_rec.userid 
      , p_error_message_severity  => 1 
      );

      COMMIT;
    END IF;

    IF ln_party_id IS NOT NULL
    THEN     
      BEGIN
        select org_id into ln_org_id
        from hz_cust_acct_sites_all
        where cust_acct_site_id = 
        ( select cust_acct_site_id from hz_cust_account_roles
           where party_id = ln_party_id
        ); 
      EXCEPTION 
        when no_data_found then
          BEGIN            
            null; -- Fill the logic here 
          EXCEPTION 
            when no_data_found then
              xx_com_error_log_pub.log_error
              ( p_application_name        => 'E1328_BSDNET_iReceivables'
              , p_program_type            => 'CONVERSION'
              , p_program_name            => 'XX_UPDATE_FND_USER'
              , p_module_name             => 'CDH'
              , p_error_message_code      => 'XX_CDH_0008_ORG_ID_NULL'
              , p_error_message           => 'ORG ID is null for party id:'|| ln_party_id ||' and USER ID: '||lc_fetch_conv_rec.userid 
              , p_error_message_severity  => 1 
              );

              update xxcrm.xx_external_users set load_status = 'ERROR'
                                               , last_update_date = SYSDATE
              where userid = lc_fetch_conv_rec.userid;  

              COMMIT;
          END; 
      END;
 
      IF ln_org_id is NOT NULL and lc_fetch_conv_rec.bsd_access_code in ( 2, 3 )
      THEN
        IF ln_org_id in (141)
        THEN 
          fnd_user_pkg.updateuser
		   ( x_user_name   => gcn_site_key||lc_fetch_conv_rec.userid
                   , x_owner       => 'CUST'
                   , x_customer_id => ln_party_id
                   );
      
          fnd_user_resp_groups_api.upload_assignment
           ( user_id                       => gcn_site_key||lc_fetch_conv_rec.userid
           , responsibility_id             => gcn_us_resp
           , responsibility_application_id => 222
           , start_date                    => SYSDATE
           , end_date                      => NULL
           , description                   => 'OD AR iReceivables Account Management'
           );
        ELSIF ln_org_id = (161)
        THEN
          fnd_user_pkg.updateuser 
		  ( x_user_name   => gcn_site_key||lc_fetch_conv_rec.userid
                  , x_owner       => 'CUST'
                  , x_customer_id => ln_party_id
                  );
      
          fnd_user_resp_groups_api.upload_assignment
           ( user_id                       => gcn_site_key||lc_fetch_conv_rec.userid
           , responsibility_id             => gcn_ca_resp
           , responsibility_application_id => 222
           , start_date                    => SYSDATE
           , end_date                      => NULL
           , description                   => 'OD AR iReceivables Account Management'
           );
        END IF;  
      END IF; 
      ln_retcode  := NULL; 
      ln_party_id := NULL;
    END IF;
  END LOOP;
EXCEPTION
  when others then
    xx_com_error_log_pub.log_error
           ( p_application_name        => 'E1328_BSDNET_iReceivables'
           , p_program_type            => 'CONVERSION'
           , p_program_name            => 'XX_UPDATE_FND_USER'
           , p_module_name             => 'CDH'
           , p_error_message_code      => 'XX_CDH_0012_CONVERSION_ERROR'
           , p_error_message           => 'SQLCODE: '|| sqlcode || 'SQLERRM: '||sqlerrm 
           , p_error_message_severity  => 1 
           );
END xx_update_fnd_user;