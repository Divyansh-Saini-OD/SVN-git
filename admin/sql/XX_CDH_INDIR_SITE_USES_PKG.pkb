create or replace
PACKAGE BODY xx_cdh_indir_site_uses_pkg
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                       WIPRO Technologies                                       |
-- +================================================================================+
-- | Name        : XX_CDH_CLEANUP_INDIRECT_SITE_USES_PKG                            |
-- | Description : 1) To cleanup indirect sites by creating BILL TO site            |
-- |                  use if does not exists.                                       |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date          Author              Remarks                             |
-- |=======  ==========   ==================    ====================================|
-- |1.0      20-AUG-2010  Devi Viswanathan     Initial version                      |
-- |2.0      30-SEP-2010  Devi Viswanathan     To eliminate inactive ship to and    |
-- |                                           create profile for existing Bill to  |
-- |                                           to if not already existing.          |
-- |3.0      18-Jan-2011  Devi Viswanathan     To update new bill to site use for   |
-- |                                           SHIP_TO if it is inactive Defect#9579|
-- |4.0      02-Jun-2011  Dheeraj Vernekar     If Inactive Bill-To usage exist then |
-- |                                           reactivate instead of creating new one|
-- |                                           Defect #11365                        |
-- |4.1      11-Jan-2013  Dheeraj V            QC 21670, Add Billing cycle          |
-- |                                           date as parameter                    |
-- |4.2      08-MAR-2014  Arun Gannarapu       Made changes as per R12 retrofit     |
-- |                                                defect # 28030                  |
-- |4.3      11-Dec-2015  Vasu Raparla         Removed Schema References for R.12.2 |
-- +================================================================================+

-- +================================================================================+
-- | Name        : main                                                             |
-- | Description : 1) To cleanup indirect sites by creating BILL TO site            |
-- |                  use if does not exists.                                       |
-- | Returns     :                                                                  |
-- +================================================================================+


  procedure main( x_errbuf   OUT NOCOPY  VARCHAR2
                , x_retcode  OUT NOCOPY  VARCHAR2
                , p_commit   IN          VARCHAR2
                , p_cycle_date IN        VARCHAR2)
IS

   lc_return_status            VARCHAR2(4000);
   ln_msg_count                NUMBER;
   lc_msg_data                 VARCHAR2(4000);
   lc_bp_return_status         VARCHAR2(4000);
   ln_bp_msg_count             NUMBER;
   lc_bp_msg_data              VARCHAR2(4000);
   lc_pr_return_status         VARCHAR2(4000);
   ln_pr_msg_count             NUMBER;
   lc_pr_msg_data              VARCHAR2(4000);
   lc_gst_return_status        VARCHAR2(4000);
   ln_gst_msg_count            NUMBER;
   lc_gst_msg_data             VARCHAR2(4000);
   lc_ust_return_status        VARCHAR2(4000);
   ln_ust_msg_count            NUMBER;
   lc_ust_msg_data             VARCHAR2(4000);
   ln_object_version_number    NUMBER;
   lc_api_call                 VARCHAR2(4000);
   lc_profile_update_flag      VARCHAR2(10);
   lc_billto_loc_flag          VARCHAR2(10);
   lc_output_msg               VARCHAR2(4000);
   lc_cust_account_number      hz_cust_accounts.account_number%TYPE;
   lc_location                 hz_cust_site_uses_all.location%TYPE;
   ln_cust_account_id          hz_cust_accounts.cust_account_id%TYPE;
   ln_cust_acct_site_id        hz_cust_acct_sites_all.cust_acct_site_id%TYPE;
   ln_cust_account_profile_id  hz_customer_profiles.cust_account_profile_id%TYPE;
   ln_shipto_site_use_id       hz_cust_site_uses_all.site_use_id%TYPE;
   ln_billto_site_use_id       hz_cust_site_uses_all.site_use_id%TYPE;
   ln_shipto_profile_id        hz_customer_profiles.cust_account_profile_id%TYPE;
   lr_billto_site_use_rec      hz_cust_account_site_v2pub.cust_site_use_rec_type;
   lr_shipto_site_use_rec      hz_cust_account_site_v2pub.cust_site_use_rec_type;
   lr_customer_profile_rec     hz_customer_profile_v2pub.customer_profile_rec_type;
   lr_shipto_profile_rec       hz_customer_profile_v2pub.customer_profile_rec_type;
   
   -- defect # 11365 start
   lr_inact_billto_site_use_rec      hz_cust_account_site_v2pub.cust_site_use_rec_type;
   --defect # 11365 end
   
   ld_cycle_date               DATE;

   api_failed_exception        EXCEPTION;

   lc_msg_index_out            VARCHAR2(4000);
   lx_msg_data                 VARCHAR2(4000);
   lx_msg_count                NUMBER;

/* Commented below cursor for QC 21670

   CURSOR indirect_customer_cur
       IS
   SELECT + parallel (a,4)  XCCAE.cust_account_id cust_account_id
        , HCA.account_number                          cust_account_number
        , HCP.cust_account_profile_id                 cust_account_profile_id
     FROM xx_cdh_cust_acct_ext_vl XCCAE
        , hz_customer_profiles HCP
        , hz_cust_accounts HCA
    WHERE XCCAE.attr_group_id        = 166
      AND XCCAE.c_ext_attr2          = 'Y'
      AND NVL(XCCAE.c_ext_attr7,'N') = 'N'
      AND SYSDATE BETWEEN XCCAE.D_EXT_ATTR1 AND NVL(XCCAE.D_EXT_ATTR2, SYSDATE + 1)
      AND XCCAE.CUST_ACCOUNT_ID      = HCA.CUST_ACCOUNT_ID
      AND XCCAE.CUST_ACCOUNT_ID      = HCP.CUST_ACCOUNT_ID (+)
      AND HCP.SITE_USE_ID            IS  NULL;
      -- Run the script for few customers to test the procedure.
      --AND XCCAE.cust_account_id IN (7234);
*/

   /* Cursor to get all indirect customers
    */

   CURSOR indirect_customer_cur (pd_cycle_date DATE)
       IS
   SELECT /*+ parallel (a,4) */ XCCAE.cust_account_id cust_account_id
        , HCA.account_number                          cust_account_number
        , HCP.cust_account_profile_id                 cust_account_profile_id
     FROM xx_cdh_cust_acct_ext_vl XCCAE
        , hz_customer_profiles HCP
        , hz_cust_accounts HCA
    WHERE XCCAE.attr_group_id        = 166
      AND XCCAE.c_ext_attr2          = 'Y'
      AND NVL(XCCAE.c_ext_attr7,'N') = 'N'
      AND pd_cycle_date+1 BETWEEN XCCAE.D_EXT_ATTR1 AND NVL(XCCAE.D_EXT_ATTR2, SYSDATE + 1)
      AND XCCAE.CUST_ACCOUNT_ID      = HCA.CUST_ACCOUNT_ID
      AND XCCAE.CUST_ACCOUNT_ID      = HCP.CUST_ACCOUNT_ID (+)
      AND HCP.SITE_USE_ID            IS  NULL;
      -- Run the script for few customers to test the procedure.
      --AND XCCAE.cust_account_id IN (7234);      
      
    /* Cursor to get all ship_tos
     * for a given account number. */
    CURSOR shipto_cur(c_cust_account_id hz_cust_accounts.cust_account_id%TYPE)
        IS
    SELECT HCSU.cust_acct_site_id   cust_acct_site_id
         , HCSU.site_use_id         shipto_site_use_id
         , HCSU.location            location
         , HCSU.bill_to_site_use_id bill_to_site_use_id
         , HCAS.org_id              org_id
         , HCSU1.status             billto_site_use_status -- Added for Defect 9579
      FROM hz_cust_acct_sites_all HCAS
         , hz_cust_site_uses_all  HCSU
         , hz_cust_site_uses_all  HCSU1 -- Added for Defect 9579
     WHERE HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
       AND HCSU.site_use_code     = 'SHIP_TO'
       AND HCSU.status            = 'A' -- To take only active site use.
       -- Added for Defect 9579 Begin
       AND HCSU1.site_use_id   (+)   = HCSU.bill_to_site_use_id
       AND HCSU1.site_use_code (+)   = 'BILL_TO'
       -- Added for Defect 9579 End
       AND HCAS.cust_account_id   = c_cust_account_id;


    /* Cursor to get Bill to of a given site.
     */
    CURSOR billto_cur(c_cust_acct_site_id hz_cust_acct_sites_all.cust_acct_site_id%TYPE)
        IS
    SELECT HCSU.site_use_id              billto_site_use_id
         , HCP.cust_account_profile_id   billto_profile_id
      FROM hz_cust_site_uses_all  HCSU
         , hz_customer_profiles   HCP
     WHERE HCSU.site_use_code     = 'BILL_TO'
       AND HCSU.status            = 'A'
       AND HCP.site_use_id (+)    = HCSU.site_use_id
       AND HCSU.cust_acct_site_id = c_cust_acct_site_id;

    type billto_type is record ( billto_site_use_id hz_cust_site_uses_all.site_use_id%type
                               , billto_profile_id hz_customer_profiles.cust_account_profile_id%type );
    billto_rec billto_type;

--Defect # 11365 Start
    /* Cursor to retrieve Inactive Bill-To usages that can be reactivated for a given site.
    */
    CURSOR inactive_billto_cur(c_cust_acct_site_id hz_cust_acct_sites_all.cust_acct_site_id%TYPE)
        IS  
    SELECT HCSU.site_use_id              billto_site_use_id
         , HCP.cust_account_profile_id   billto_profile_id
    FROM hz_cust_site_uses_all  HCSU
         , hz_customer_profiles   HCP
     where HCSU.site_use_code     = 'BILL_TO'
       AND HCP.site_use_id (+)    = HCSU.site_use_id
       AND HCSU.site_use_id = (SELECT  MAX(site_use_id)
                                FROM hz_cust_site_uses_all 
                                WHERE cust_acct_site_id = HCSU.cust_acct_site_id
                                AND site_use_code='BILL_TO'
                                AND status='I'
                                )
       AND HCSU.cust_acct_site_id=c_cust_acct_site_id;
 
--Defect # 11365 End        





  BEGIN
    -- QC 21670 Begin
    ld_cycle_date          := TRUNC(NVL(fnd_conc_date.string_to_date(p_cycle_date),SYSDATE));
    fnd_file.put_line(fnd_file.log,'Billing cycle date :'||to_char(ld_cycle_date) );
    
    -- QC 21670 End
    
    fnd_file.put_line (fnd_file.log,'Inside xx_cdh_indir_site_uses_pkg. p_commit: ' || p_commit);
    fnd_file.put_line (fnd_file.log,'***********************************************');


    DBMS_output.put_line('start main: p_commit: ' || p_commit);
    fnd_file.put_line (fnd_file.output,'Oracle Account Number|Location|Cust Account Id|Cust Account Profile Id|Cust Acct Site Id|Ship Site Use Id|Bill Site Use Id|(Billto: Created\Updated\Failed)');

    SAVEPOINT main_start;
    
    lc_cust_account_number      := NULL;
    ln_cust_account_id          := NULL;
    ln_cust_account_profile_id  := NULL;
    
    -- QC 21670 Begin, passing billing cycle date 
    FOR indirect_customer_rec IN indirect_customer_cur(ld_cycle_date)
    LOOP

       /* To get customer profile value
        */
       
       SAVEPOINT customer_level;
       
       lc_cust_account_number        := indirect_customer_rec.cust_account_number;       
       ln_cust_account_id            := indirect_customer_rec.cust_account_id;
       ln_cust_account_profile_id    := indirect_customer_rec.cust_account_profile_id;

       IF indirect_customer_rec.cust_account_profile_id IS NOT NULL THEN

        lc_api_call := 'hz_customer_profile_v2pub.get_customer_profile_rec';

        hz_customer_profile_v2pub.get_customer_profile_rec( p_init_msg_list           => FND_API.G_FALSE
                                                          , p_cust_account_profile_id => indirect_customer_rec.cust_account_profile_id
                                                          , x_customer_profile_rec    => lr_customer_profile_rec
                                                          , x_return_status           => lc_pr_return_status
                                                          , x_msg_count               => ln_pr_msg_count
                                                          , x_msg_data                => lc_pr_msg_data
                                                          );

        IF lc_pr_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          -- hz_customer_profile_v2pub.get_customer_profile_rec failed
          lx_msg_data := null;

            FOR ro_err_ser_count IN FND_MSG_PUB.count_msg-ln_pr_msg_count..fnd_msg_pub.count_msg
            LOOP

              FND_MSG_PUB.get( p_msg_index      => ro_err_ser_count
                             , p_encoded        => 'F'
                             , p_data           => lc_pr_msg_data
                             , p_msg_index_out  => lc_msg_index_out);

              lx_msg_data := lx_msg_data||' : '||lc_pr_msg_data;
 
            END LOOP;

            fnd_file.put_line (fnd_file.log,'Error in hz_customer_profile_v2pub.get_customer_profile_rec: ' || lx_msg_data);

           RAISE api_failed_exception;

          END IF; -- IF lc_pr_return_status <> FND_API.G_RET_STS_SUCCESS THEN

        END IF;  --  IF indirect_customer_rec.cust_account_profile_id IS NOT NULL THEN 
        
      /* Looping through the ship to of a customer account
       */

      FOR shipto_rec IN shipto_cur(indirect_customer_rec.cust_account_id)
      LOOP

        BEGIN

           SAVEPOINT site_level;

           fnd_file.put_line (fnd_file.log,'Cust Account Id: ' || indirect_customer_rec.cust_account_id || '|' || 'Cust Account Profile Id: ' || indirect_customer_rec.cust_account_profile_id || '|' || 'Cust Acct Site Id: ' || shipto_rec.cust_acct_site_id );
           DBMS_output.put_line('Cust Account Id: ' || indirect_customer_rec.cust_account_id);
           DBMS_output.put_line('Cust Account Profile Id: ' || indirect_customer_rec.cust_account_profile_id);
           DBMS_output.put_line('Cust Acct Site Id: ' || shipto_rec.cust_acct_site_id);
           lc_location                 := NULL;    
           ln_cust_acct_site_id        := NULL;    
           ln_shipto_site_use_id       := NULL;
           ln_billto_site_use_id       := NULL;
           ln_shipto_profile_id        := NULL;  
           lc_profile_update_flag      := NULL;
           lc_billto_loc_flag          := NULL;           
           
           /* Setting Org context based on the sites org id.
            */
           
           fnd_client_info.set_org_context(shipto_rec.org_id);

           /* Checking if BILL TO site use already exists for the site.
            */
            
           ln_cust_acct_site_id                     := shipto_rec.cust_acct_site_id;
           lc_location                              := shipto_rec.location;
           ln_shipto_site_use_id                    := shipto_rec.shipto_site_use_id;

           OPEN billto_cur(shipto_rec.cust_acct_site_id);
           FETCH billto_cur INTO billto_rec;

           IF billto_cur%FOUND THEN
           
             /* BILL TO site use exists for the site. 
              */
              
             CLOSE billto_cur; 

             lr_customer_profile_rec.cust_account_profile_id := null;
             lr_customer_profile_rec.site_use_id             := billto_rec.billto_site_use_id;
             ln_billto_site_use_id                           := billto_rec.billto_site_use_id;
             
             /* Checking if profile already exists for the BILL TO site use 
              */

             IF billto_rec.billto_profile_id IS NULL THEN

               lc_api_call := 'hz_customer_profile_v2pub.create_customer_profile';

               hz_customer_profile_v2pub.create_customer_profile ( p_init_msg_list            => FND_API.G_FALSE
                                                                 , p_customer_profile_rec     => lr_customer_profile_rec
                                                                 , p_create_profile_amt       => FND_API.G_TRUE
                                                                 , x_cust_account_profile_id  => billto_rec.billto_profile_id
                                                                 , x_return_status            => lc_bp_return_status
                                                                 , x_msg_count                => ln_bp_msg_count
                                                                 , x_msg_data                 => lc_bp_msg_data
                                                                 );

               IF lc_bp_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               -- hz_customer_profile_v2pub.create_customer_profile API failed
               lx_msg_data := null;
               FOR ro_err_ser_count IN FND_MSG_PUB.count_msg-ln_bp_msg_count..fnd_msg_pub.count_msg
               LOOP

                  FND_MSG_PUB.get( p_msg_index => ro_err_ser_count
                                 , p_encoded        => 'F'
                                 , p_data           => lc_gst_msg_data
                                 , p_msg_index_out  => lc_msg_index_out);

                  lx_msg_data := lx_msg_data||' : '||lc_bp_msg_data;

                 END LOOP;  
                 
                 fnd_file.put_line (fnd_file.log,'Error in hz_customer_profile_v2pub.create_customer_profile: ' || lx_msg_data);                 

                 RAISE api_failed_exception;

               END IF; -- IF lc_bp_return_status <> FND_API.G_RET_STS_SUCCESS THEN
               
               lc_profile_update_flag := 'U';
               
               fnd_file.put_line (fnd_file.log,'Profile created for the Bill TO Site Use Id: ' || ln_billto_site_use_id || ' for the SHIP TO: ' || shipto_rec.cust_acct_site_id);                            
              
             END IF; -- IF billto_rec.billto_profile_id IS NULL THEN

           ELSE -- IF billto_cur%FOUND THEN
           
             CLOSE billto_cur;
             
-- Defect #11365 Start
             
            
                          
              OPEN inactive_billto_cur(shipto_rec.cust_acct_site_id);
              FETCH inactive_billto_cur into billto_rec;
             
              IF inactive_billto_cur%FOUND THEN
              
              CLOSE inactive_billto_cur;
              
                            
              ln_billto_site_use_id      := billto_rec.billto_site_use_id;
              lr_inact_billto_site_use_rec := NULL;
              
              /* Reactivating the Inactive Bill-TO usage.
              */
                          
                                    
              lr_inact_billto_site_use_rec.site_use_id := billto_rec.billto_site_use_id;
              lr_inact_billto_site_use_rec.status := 'A';
             
              ln_object_version_number := null;
             
              SELECT object_version_number,
                     cust_acct_site_id
              INTO ln_object_version_number,
                   lr_inact_billto_site_use_rec.cust_acct_site_id
              FROM hz_cust_site_uses_all 
              WHERE site_use_id = billto_rec.billto_site_use_id  ;
             
              hz_cust_account_site_v2pub.update_cust_site_use(p_init_msg_list         => FND_API.G_FALSE
                                                            ,p_cust_site_use_rec      => lr_inact_billto_site_use_rec
                                                            ,p_object_version_number  => ln_object_version_number
                                                            ,x_return_status          => lc_return_status
                                                            ,x_msg_count              => ln_msg_count
                                                            ,x_msg_data               => lc_msg_data
                                                            );
             
                IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                -- hz_cust_account_site_v2pub.update_cust_site_use failed
                lx_msg_data := null;
                FOR ro_err_ser_count IN fnd_msg_pub.count_msg-ln_msg_count..fnd_msg_pub.count_msg
                LOOP
                 FND_MSG_PUB.get( p_msg_index      => ro_err_ser_count
                               , p_encoded        => 'F'
                               , p_data           => lc_msg_data
                               , p_msg_index_out  => lc_msg_index_out);

                lx_msg_data := lx_msg_data||' : '||lc_msg_data;

                END LOOP;

                fnd_file.put_line (fnd_file.log,'Error in hz_cust_account_site_v2pub.update_cust_site_use: ' || lx_msg_data);

                DBMS_output.put_line('lc_return_status:' || lc_return_status ||':' || lx_msg_data);

                RAISE api_failed_exception;
              
                END IF; -- IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
             
                fnd_file.put_line (fnd_file.log,'BILL TO site use id activated successfully: Bill To Site Use Id: ' || ln_billto_site_use_id || ' for the SHIP TO: ' || shipto_rec.cust_acct_site_id);
            
                dbms_output.put_line('BILL TO site use id activated successfully: Bill To Site Use Id: ' || ln_billto_site_use_id);
              
              
              lr_customer_profile_rec.cust_account_profile_id := null;
              lr_customer_profile_rec.site_use_id             := billto_rec.billto_site_use_id;
                           
             /* Checking if profile already exists for the BILL TO site use 
              */

             IF billto_rec.billto_profile_id IS NULL THEN

               lc_api_call := 'hz_customer_profile_v2pub.create_customer_profile';

               hz_customer_profile_v2pub.create_customer_profile ( p_init_msg_list            => FND_API.G_FALSE
                                                                 , p_customer_profile_rec     => lr_customer_profile_rec
                                                                 , p_create_profile_amt       => FND_API.G_TRUE
                                                                 , x_cust_account_profile_id  => billto_rec.billto_profile_id
                                                                 , x_return_status            => lc_bp_return_status
                                                                 , x_msg_count                => ln_bp_msg_count
                                                                 , x_msg_data                 => lc_bp_msg_data
                                                                 );

               IF lc_bp_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               -- hz_customer_profile_v2pub.create_customer_profile API failed
               lx_msg_data := null;
               FOR ro_err_ser_count IN FND_MSG_PUB.count_msg-ln_bp_msg_count..fnd_msg_pub.count_msg
               LOOP

                  FND_MSG_PUB.get( p_msg_index => ro_err_ser_count
                                 , p_encoded        => 'F'
                                 , p_data           => lc_gst_msg_data
                                 , p_msg_index_out  => lc_msg_index_out);

                  lx_msg_data := lx_msg_data||' : '||lc_bp_msg_data;

                 END LOOP;  
                 
                 fnd_file.put_line (fnd_file.log,'Error in hz_customer_profile_v2pub.create_customer_profile: ' || lx_msg_data);                 

                 RAISE api_failed_exception;

               END IF; -- IF lc_bp_return_status <> FND_API.G_RET_STS_SUCCESS THEN
               
               lc_profile_update_flag := 'U';
               
               fnd_file.put_line (fnd_file.log,'Profile created for the Bill TO Site Use Id: ' || ln_billto_site_use_id || ' for the SHIP TO: ' || shipto_rec.cust_acct_site_id);                            
              
             END IF; -- IF billto_rec.billto_profile_id IS NULL THEN

              
              
              ELSE -- inactive_billto_cur%FOUND THEN
              
                CLOSE inactive_billto_cur;
             
  -- Defect #11365 End                        

                lr_customer_profile_rec.cust_account_profile_id := null;

                /* Creating BILL TO site use for the site with customer profile same as at customer account level.
                */

                LC_API_CALL := 'hz_cust_account_site_v2pub.create_cust_site_use';
                LN_BILLTO_SITE_USE_ID := NULL;
                lr_billto_site_use_rec.cust_acct_site_id := shipto_rec.cust_acct_site_id;
                lr_billto_site_use_rec.site_use_code     := 'BILL_TO';
                lr_billto_site_use_rec.created_by_module := 'XXCRM';
                lr_billto_site_use_rec.location          := shipto_rec.location;             

                hz_cust_account_site_v2pub.create_cust_site_use ( p_init_msg_list        => FND_API.G_FALSE
                                                             , p_cust_site_use_rec    => lr_billto_site_use_rec
                                                             , p_customer_profile_rec => lr_customer_profile_rec
                                                             , p_create_profile       => FND_API.G_TRUE
                                                             , p_create_profile_amt   => FND_API.G_TRUE
                                                             , x_site_use_id          => ln_billto_site_use_id
                                                             , x_return_status        => lc_return_status
                                                             , x_msg_count            => ln_msg_count
                                                             , x_msg_data             => lc_msg_data
                                                             );


                IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                -- hz_cust_account_site_v2pub.create_cust_site_use failed
                lx_msg_data := null;
                FOR ro_err_ser_count IN FND_MSG_PUB.count_msg-ln_msg_count..fnd_msg_pub.count_msg
                  LOOP
                  FND_MSG_PUB.get( p_msg_index      => ro_err_ser_count
                               , p_encoded        => 'F'
                               , p_data           => lc_msg_data
                               , p_msg_index_out  => lc_msg_index_out);

                  lx_msg_data := lx_msg_data||' : '||lc_msg_data;

                  END LOOP;

                  fnd_file.put_line (fnd_file.log,'Error in hz_cust_account_site_v2pub.create_cust_site_use: ' || lx_msg_data);

                  DBMS_output.put_line('lc_return_status:' || lc_return_status ||':' || lx_msg_data);

                  RAISE api_failed_exception;
              
                END IF; -- IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                fnd_file.put_line (fnd_file.log,'BILL TO site use id created successfully: Bill To Site Use Id: ' || ln_billto_site_use_id || ' for the SHIP TO: ' || shipto_rec.cust_acct_site_id);
            
                DBMS_output.put_line('BILL TO site use id created successfully: Bill To Site Use Id: ' || ln_billto_site_use_id);
            
                lc_profile_update_flag := 'C';
 
 -- Defect # 11365 Start           
                         
              END IF;  -- IF inactive_billto_cur%FOUND THEN

 -- Defect # 11365 End              

          END IF; -- IF billto_cur%FOUND THEN
          
          /* Update SHIP TO with BILL TO location if BILL TO location is NULL for the SHIP TO.
           */          
--          Code change for Defect 9579 Begin
--          IF shipto_rec.bill_to_site_use_id IS NULL THEN 
            IF shipto_rec.bill_to_site_use_id IS NULL OR shipto_rec.billto_site_use_status != 'A' THEN 
--          Code change for Defect 9579 End            

            lc_api_call := 'hz_cust_account_site_v2pub.get_cust_site_use_rec';

            hz_cust_account_site_v2pub.get_cust_site_use_rec ( p_init_msg_list           => FND_API.G_FALSE
                                                             , p_site_use_id             => shipto_rec.shipto_site_use_id
                                                             , x_cust_site_use_rec       => lr_shipto_site_use_rec
                                                             , x_customer_profile_rec    => lr_shipto_profile_rec
                                                             , x_return_status           => lc_gst_return_status
                                                             , x_msg_count               => ln_gst_msg_count
                                                             , x_msg_data                => lc_gst_msg_data
                                                             );


            IF lc_gst_return_status <> FND_API.G_RET_STS_SUCCESS THEN

              -- hz_cust_account_site_v2pub.get_cust_site_use_rec API failed
              lx_msg_data := null;
              FOR ro_err_ser_count IN FND_MSG_PUB.count_msg-ln_gst_msg_count..fnd_msg_pub.count_msg
              LOOP

                FND_MSG_PUB.get( p_msg_index      => ro_err_ser_count
                   , p_encoded        => 'F'
                   , p_data           => lc_gst_msg_data
                   , p_msg_index_out  => lc_msg_index_out);

                lx_msg_data := lx_msg_data||' : '||lc_gst_msg_data;

              END LOOP;
              
              fnd_file.put_line (fnd_file.log,'Error in hz_cust_account_site_v2pub.get_cust_site_use_rec: ' || lx_msg_data);                               

              RAISE api_failed_exception;

            END IF; -- IF lc_gst_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            lc_api_call := 'hz_cust_account_site_v2pub.update_cust_site_use';

            lr_shipto_site_use_rec.bill_to_site_use_id := ln_billto_site_use_id;

            SELECT object_version_number,
                   cust_acct_site_id
              INTO ln_object_version_number,
                   lr_shipto_site_use_rec.cust_acct_site_id
              FROM hz_cust_site_uses_all
             WHERE site_use_id = shipto_rec.shipto_site_use_id;

            hz_cust_account_site_v2pub.update_cust_site_use ( p_init_msg_list          => FND_API.G_FALSE
                                                            , p_cust_site_use_rec      => lr_shipto_site_use_rec
                                                            , p_object_version_number  => ln_object_version_number
                                                            , x_return_status          => lc_gst_return_status
                                                            , x_msg_count              => ln_gst_msg_count
                                                            , x_msg_data               => lc_gst_msg_data
                                                            );

            IF lc_ust_return_status <> FND_API.G_RET_STS_SUCCESS THEN

              -- hz_cust_account_site_v2pub.get_cust_site_use_rec API failed
              lx_msg_data := null;

              FOR ro_err_ser_count IN FND_MSG_PUB.count_msg-ln_ust_msg_count..fnd_msg_pub.count_msg
              LOOP
                FND_MSG_PUB.get( p_msg_index      => ro_err_ser_count
                   , p_encoded        => 'F'
                   , p_data           => lc_ust_msg_data
                   , p_msg_index_out  => lc_msg_index_out);

                lx_msg_data := lx_msg_data||' : '||lc_ust_msg_data;

              END LOOP;

              fnd_file.put_line (fnd_file.log,'Error in hz_cust_account_site_v2pub.update_cust_site_use: ' || lx_msg_data);                               

              RAISE api_failed_exception;

            END IF; -- IF lc_ust_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            
            fnd_file.put_line (fnd_file.log, 'SHIP TO (' || shipto_rec.shipto_site_use_id || ') updated with BILL TO LOCATION: ' || ln_billto_site_use_id);
            
            lc_billto_loc_flag := 'U'; 
           
          END IF; -- IF shipto_rec.bill_to_site_use_id IS NULL THEN
          
          lc_output_msg := lc_cust_account_number || '|' || lc_location || '|' || ln_cust_account_id || '|' || ln_cust_account_profile_id || '|' || ln_cust_acct_site_id || '|' || ln_shipto_site_use_id || '|' || ln_billto_site_use_id ;
          
          IF lc_profile_update_flag = 'U' THEN 
          
             lc_output_msg := lc_output_msg || '|' || 'BILL TO profile updated';
             
          ELSIF lc_profile_update_flag = 'C' THEN 
          
             lc_output_msg := lc_output_msg || '|' || 'BILL TO created with profile vale';
             
          END IF; -- IF lc_profile_update_flag = 'U' THEN 
          
          IF lc_billto_loc_flag = 'U' THEN
          
            lc_output_msg := lc_output_msg || ', BILL TO Location updated in SHIP TO';
            
          ELSE
          
            lc_output_msg := lc_output_msg || ', BILL TO Location already exists for SHIP TO';          
            
          END IF; -- IF lc_billto_loc_flag = 'U' THEN
          
          IF lc_profile_update_flag IS NOT NULL OR lc_billto_loc_flag IS NOT NULL THEN
          
            fnd_file.put_line (fnd_file.output, lc_output_msg);
            
          END IF; 
        
        EXCEPTION

        WHEN api_failed_exception THEN

          fnd_file.put_line (fnd_file.log,'Standard API FAILED: ' || lc_api_call || ', Error message: ' || SQLERRM);
          
          fnd_file.put_line (fnd_file.output, lc_cust_account_number || '|' || lc_location || '|' || ln_cust_account_id || '|' || ln_cust_account_profile_id || '|' || ln_cust_acct_site_id || '|' || ln_shipto_site_use_id || '|' || ln_billto_site_use_id || '|' || 'Standard API Failed: ' || lc_api_call);            

          ROLLBACK TO site_level;

         WHEN OTHERS THEN

          fnd_file.put_line (fnd_file.log,'Unexpected exception: ' || SQLERRM);
          
          fnd_file.put_line (fnd_file.output, lc_cust_account_number || '|' || lc_location || '|' || ln_cust_account_id || '|' || ln_cust_account_profile_id || '|' || ln_cust_acct_site_id || '|' || ln_shipto_site_use_id || '|' || ln_billto_site_use_id || '|' || 'Exception: ' || SQLERRM);       

          ROLLBACK TO site_level;

        END;

      END LOOP; -- FOR indirect_customer_rec IN indirect_customer_cur
      
      fnd_file.put_line (fnd_file.log,'_______________________________________________________________________________');      

    END LOOP; -- FOR shipto_rec IN shipto_cur

    fnd_file.put_line (fnd_file.log,'End of xx_cdh_indir_site_uses_pkg.main');
    fnd_file.put_line (fnd_file.log,'**************************************');
    
    
    /* If concurrent program with commit flag as No then all the changes are rollbacked.
     */
    IF p_commit = 'N' THEN
    
      ROLLBACK TO main_start;      
      fnd_file.put_line (fnd_file.log,'Inside No Commit: ' );      
      
    ELSE  -- IF p_commit = 'N' THEN
    
      COMMIT;
      fnd_file.put_line (fnd_file.log,'Inside Commit: ' );
    
    END IF; -- IF p_commit = 'N' THEN

  EXCEPTION
  
    WHEN api_failed_exception THEN

    fnd_file.put_line (fnd_file.log,'Standard API FAILED: ' || lc_api_call || ', Error message: ' || SQLERRM);    
 
    fnd_file.put_line (fnd_file.output, lc_cust_account_number || '|' || lc_location || '|' || ln_cust_account_id || '|' || ln_cust_account_profile_id || '|' || ln_cust_acct_site_id || '|' || ln_shipto_site_use_id || '|' || ln_billto_site_use_id || '|' || 'Standard API Failed: ' || lc_api_call);            

    ROLLBACK TO customer_level;

  WHEN OTHERS THEN

    fnd_file.put_line (fnd_file.log, 'Exception: ' || sqlerrm);
    --x_errbuf  := 'Exception in fix_ab_collect_rec: ' || SQLERRM;
    --x_retcode := 2;
    
    fnd_file.put_line (fnd_file.output, lc_cust_account_number || '|' || lc_location || '|' || ln_cust_account_id || '|' || ln_cust_account_profile_id || '|' || ln_cust_acct_site_id || '|' || ln_shipto_site_use_id || '|' || ln_billto_site_use_id || '|' || 'Exception: ' || SQLERRM);                
    
    ROLLBACK TO customer_level;

  END main;

end XX_CDH_INDIR_SITE_USES_PKG;
/
SHOW ERRORS;