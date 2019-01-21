CREATE OR REPLACE PACKAGE BODY XX_SFA_LEAD_REFF_CREATE_PKG
AS
-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |                     Wipro Technologies                                |
-- +=======================================================================+
-- | Name             :XX_SFA_LEAD_REFF_CREATE_PKG                         |
-- | Description      :Create leads referred through Lead Referral Form    |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     28-DEC-2010   Renupriya R      Initial Draft                  |
-- | 1.1     06-JAN-2011   Sathish RS       Addition of Email program      |
-- | 1.2     02-FEB-2011   Renupriya R      For defect 9955                |
-- | 1.3     04-MAR-2011   Renupriya R      For Defect 10321               |
-- | 1.4     15-APR-2011   Indra Varada     CPD Store Rep Email            |
-- | 1.5     26-APR-2011   Satish Silveri   For Defect 10822               |
-- | 1.6     18-MAY-2011   Satish Silveri   For Defect 10671 and 11226     |
-- | 1.7     14-MAR-2012   Satish Silveri   For Defect 17529               |
-- +=======================================================================+

PROCEDURE XX_LEAD_CREATE (
                             x_errbuf    OUT NOCOPY VARCHAR2
                           , x_retcode   OUT NOCOPY NUMBER)
AS
----------------------------------------------------------------------
---                Cursor Declarations                              ---
----------------------------------------------------------------------
    CURSOR lcu_lead_ref
    IS
    SELECT *
    FROM   xxcrm.xx_sfa_lead_referrals
    WHERE  NVL(PROCESS_STATUS,'NEW')  = 'NEW';

    CURSOR lcu_lead_source(p_lead_source VARCHAR2)
    IS
    SELECT  amscv.id as source_promotion_id
    FROM
                  (SELECT SOC.source_code_id id
                         ,CAMPT.campaign_name value
                   FROM  AMS_SOURCE_CODES SOC
                        ,AMS_CAMPAIGNS_ALL_TL CAMPT
                        ,AMS_CAMPAIGNS_ALL_B CAMPB
                   WHERE SOC.arc_source_code_for   = 'CAMP'
                   AND   SOC.active_flag           = 'Y'
                   AND   SOC.source_code_for_id    = campb.campaign_id
                   AND   CAMPB.campaign_id         = campt.campaign_id
                   AND   CAMPB.status_code        IN('ACTIVE', 'COMPLETED')
                   AND   CAMPT.LANGUAGE            = userenv('LANG')
                   UNION ALL
                   SELECT  SOC.source_code_id ID
                          ,eveht.event_header_name VALUE
                   FROM    AMS_SOURCE_CODES SOC
                          ,AMS_EVENT_HEADERS_ALL_B EVEHB
                          ,AMS_EVENT_HEADERS_ALL_TL EVEHT
                   WHERE  SOC.arc_source_code_for   = 'EVEH'
                   AND    SOC.active_flag           = 'Y'
                   AND    SOC.source_code_for_id    = evehb.event_header_id
                   AND    EVEHB.event_header_id     = eveht.event_header_id
                   AND    EVEHB.system_status_code IN('ACTIVE', 'COMPLETED')
                   AND    EVEHT.LANGUAGE            = userenv('LANG')
                   UNION ALL
                   SELECT SOC.source_code_id ID
                         ,eveot.event_offer_name VALUE
                   FROM   AMS_SOURCE_CODES SOC
                         ,AMS_EVENT_OFFERS_ALL_B EVEOB
                         ,AMS_EVENT_OFFERS_ALL_TL EVEOT
                   WHERE  SOC.arc_source_code_for IN('EVEO', 'EONE')
                   AND    SOC.active_flag            = 'Y'
                   AND    SOC.source_code_for_id     = eveob.event_offer_id
                   AND    EVEOB.event_offer_id       = eveot.event_offer_id
                   AND    EVEOB.system_status_code  IN('ACTIVE', 'COMPLETED')
                   AND    EVEOT.LANGUAGE             = userenv('LANG')
                   UNION ALL
                   SELECT SOC.source_code_id id
                         ,CHLST.schedule_name value
                   FROM   AMS_SOURCE_CODES SOC
                         ,AMS_CAMPAIGN_SCHEDULES_TL CHLST
                         ,AMS_CAMPAIGN_SCHEDULES_B CHLSB
                   WHERE SOC.arc_source_code_for   = 'CSCH'
                   AND   SOC.active_flag           = 'Y'
                   AND   SOC.source_code_for_id    = CHLSB.schedule_id
                   AND   CHLSB.schedule_id         = CHLST.schedule_id
                   AND   CHLSB.status_code        IN('ACTIVE', 'COMPLETED')
                   AND   CHLST.LANGUAGE            = userenv('LANG')
                   )amscv
    WHERE REPLACE(UPPER(amscv.value),' ','') = REPLACE(UPPER(trim(p_lead_source)),' ','');


----------------------------------------------------------------------
---                Variable Declaration                            ---
----------------------------------------------------------------------
   lc_req_data                        VARCHAR2(100);
   lc_source_promotion_id             VARCHAR2(500);
   ln_request_id                      NUMBER;
   ln_mail_req_id                     NUMBER;
   lc_resource_email                  VARCHAR2(100);
   lr_organization_rec                HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
   lr_person_rec                      hz_party_v2pub.person_rec_type;
   lr_contact_rec                     HZ_PARTY_CONTACT_V2PUB.org_contact_rec_type;
   lr_location_rec                    APPS.HZ_LOCATION_V2PUB.location_rec_type;
   lr_party_site_rec                  hz_party_site_v2pub.party_site_rec_type;
   lr_party_site_use_rec              hz_party_site_v2pub.party_site_use_rec_type;
   lr_contact_point_rec_phone         HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
   lr_contact_point_rec_email         HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
   lt_sales_lead_profile_tbl          APPS.AS_UTILITY_PUB.PROFILE_TBL_TYPE;
   lr_sales_lead_rec                  APPS.AS_SALES_LEADS_PUB.SALES_LEAD_REC_TYPE;
   lr_sales_lead_line_rec             APPS.AS_SALES_LEADS_PUB.SALES_LEAD_LINE_Rec_Type;
   lt_sales_lead_line_tbl             APPS.AS_SALES_LEADS_PUB.SALES_LEAD_LINE_TBL_TYPE;
   lt_sales_lead_contact_tbl          APPS.AS_SALES_LEADS_PUB.SALES_LEAD_CONTACT_TBL_TYPE;
   lt_sales_lead_con_tbl              APPS.AS_SALES_LEADS_PUB.SALES_LEAD_CONTACT_TBL_TYPE;
   lt_sales_lead_con_out_tbl          APPS.AS_SALES_LEADS_PUB.SALES_LEAD_CNT_OUT_Tbl_Type;
   lt_sales_lead_line_out_tbl         APPS.AS_SALES_LEADS_PUB.SALES_LEAD_LINE_OUT_TBL_TYPE;
   lt_sales_lead_cnt_out_tbl          APPS.AS_SALES_LEADS_PUB.SALES_LEAD_CNT_OUT_TBL_TYPE;
   lc_return_status                   VARCHAR2(2000);
   ln_msg_count                       NUMBER;
   lc_msg_data                        VARCHAR2(2000);
   ln_org_party_id                    NUMBER;
   lc_org_party_number                VARCHAR2(2000);
   ln_org_profile_id                  NUMBER;
   ln_API_VERSION_NUMBER              NUMBER;
   lc_INIT_MSG_LIST                   VARCHAR2(10);
   lc_create_lead_return_status       VARCHAR2(200);
   ln_create_lead_msg_count           NUMBER;
   ln_sales_lead_id                   NUMBER;
   lc_create_lead_msg_data            VARCHAR2(3000);
   lc_lead_cont_ret_status            VARCHAR2(200);
   ln_lead_cont_msg_count             NUMBER;
   lc_lead_cont_msg_data              VARCHAR2(3000);
   ln_var                             NUMBER :=1 ;
   ln_location_id                     NUMBER;
   lc_create_loc_ret_status           VARCHAR2(3000);
   ln_create_loc_msg_count            NUMBER;
   lc_create_loc_msg_data             VARCHAR2(3000);
   x_error_message                    VARCHAR2(3000);
   ln_pers_party_id                   NUMBER;
   ln_party_reln_id                   NUMBER;
   ln_cntct_party_id                  NUMBER;
   ln_pers_profile_id                 NUMBER;
   ln_party_site_id                   NUMBER;
   ln_party_site_use_id               NUMBER;
   ln_phone_contact_point_id          NUMBER;
   ln_email_contact_point_id          NUMBER;
   ln_note_id                         VARCHAR2(4000);
   lc_error_str                       VARCHAR2(32000);
   lc_ret_msg                         VARCHAR2(200);
   lc_terr_asgnmnt_source             VARCHAR2(200);
   lc_full_access_flag               XX_TM_NAM_TERR_ENTITY_DTLS.FULL_ACCESS_FLAG%TYPE;
   ln_resource_id                    JTF_RS_RESOURCE_EXTNS.RESOURCE_ID%TYPE;
   ln_role_id                        JTF_RS_ROLES_B.ROLE_ID%TYPE;
   ln_group_id                       JTF_RS_GROUPS_B.GROUP_ID%TYPE;
   ln_nam_terr_id                    XX_TM_NAM_TERR_DEFN.NAMED_ACCT_TERR_ID%TYPE;
   lc_party_site_id                  HZ_PARTY_SITES.PARTY_SITE_ID%TYPE;
   lr_site_contact_rec               SITE_CONTACTS_REC;
   lr_st_site_demo_rec               SITE_DEMOGRAPHICS_REC;
   lc_rel_id                         HZ_RELATIONSHIPS.RELATIONSHIP_ID%TYPE;
   jtf_note_contexts_tab_dflt        JTF_NOTES_PUB.JTF_NOTE_CONTEXTS_TBL_TYPE;
   lc_lead_number                    AS_SALES_LEADS.LEAD_NUMBER%TYPE;
   lc_sales_person                   JTF_RS_RESOURCE_EXTNS.SOURCE_NAME%TYPE;
   lr_email_rec                      HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE;
   lr_phone_rec                      HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   lc_party_site_number              HZ_PARTY_SITES.party_site_number%type;
   ln_org_contact_id                 HZ_PARTIES.party_id%type;
   lc_pers_party_number              HZ_PARTIES.party_number%type;
   lc_cntct_party_number             HZ_PARTIES.party_id%type;
   ln_address_id                     HZ_PARTY_SITES.PARTY_SITE_ID%TYPE;
   lc_seq_no                         VARCHAR2(20);
   lc_cust_no                        VARCHAR2(30);
   lc_orig_sys_ref                   VARCHAR2(30);
   lc_org_name                       VARCHAR2(400);
   lc_zip_code                       VARCHAR2(30);
   lc_postal_code                    VARCHAR2(30);
   lc_party_name                     VARCHAR2(400);
   lc_cur_row_status                 VARCHAR2(10);
   lc_party_exists_flag              VARCHAR2(10);
   lc_out_status                     VARCHAR2(20);
   lc_country                        VARCHAR2(20);
   lc_rev_band                       VARCHAR2(20);
   lc_created_by_module              VARCHAR2(20) := 'LEAD REFERRAL';
   lc_orig_system                    VARCHAR2(20) := 'LR';
   lc_source_system                  VARCHAR2(20) := 'LEAD REFERRAL';
   lc_prospect_osr        VARCHAR2(20); -- Added for OSR Defect
   lc_prospect_email_osr        VARCHAR2(20); -- Added for OSR Defect
   lc_prospect_phone_osr        VARCHAR2(20); -- Added for OSR Defect

BEGIN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'********************************** Log Message for Lead Create Program starts **********************************');
     ln_request_id := fnd_global.conc_request_id;
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Business Name'||'|'||
                                         'Lead Name'||'|'||
                                         'Lead Number'||'|'||
                                         'OD Store Number'||'|'||
                                         'Sales Rep Assigned'||'|'||
                                         'Contact Person First Name'||'|'||
                                         'Contact Person Last Name'||'|'||
                                         'Contact Person: Phone '||'|'||
                                         'Contact Person: Email '||'|'||
                                         'Status'||'|'||
                                         'Internid');

----------------------------------------------------------------------------------
      ---  Main loop Starts here ---
----------------------------------------------------------------------------------

     FOR lrec_lead_ref IN lcu_lead_ref LOOP  -- Main Loop
     BEGIN
       --Initializing the variables
       lc_party_name       :=NULL;
       lc_country          :=NULL;
       lc_rev_band         :=NULL;
       ln_party_site_id    :=NULL;
       lc_zip_code         :=NULL;
       lc_party_name       :=NULL;
       ln_org_party_id     :=NULL;
       lc_seq_no           :=NULL;
       lc_cust_no          :=NULL;
       lc_orig_sys_ref     :=NULL;
       lc_org_name         :=NULL;
       ln_sales_lead_id    :=NULL;
       lc_party_site_id    :=NULL;
       lc_rel_id           :=NULL;
       lc_error_str        :=NULL;
       lc_party_exists_flag:=NVL(lrec_lead_ref.existing_cust_flag,'N');
       lc_cur_row_status   :='TRUE';
       lc_resource_email   := NULL;
       lc_sales_person     := NULL;
       x_error_message     := NULL;
       lc_msg_data         := NULL;
       ln_msg_count        := 0;
       ln_location_id      := NULL;
       ln_pers_party_id    := NULL;
       ln_cntct_party_id   := NULL;
       lc_terr_asgnmnt_source := NULL;
       ln_address_id          :=NULL;  --Defect 10321
       ln_resource_id         := 0; 
       ln_role_id             := 0;
       ln_group_id            := 0;
       lc_lead_number         :=NULL;
       lc_out_status          :=NULL;
       lc_prospect_osr        :=NULL;
       lc_prospect_phone_osr  :=NULL;
       lc_prospect_email_osr  :=NULL;


       FND_FILE.PUT_LINE(FND_FILE.LOG,'');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'********************************** Current record Internid : '|| lrec_lead_ref.internid || ' **********************************');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'');

-----------------------------------------------------------------------
      ---      Getting the country code         ---
-----------------------------------------------------------------------

      BEGIN
        SELECT country_code
        INTO   lc_country
        FROM   (SELECT DISTINCT SUBSTR(lookup_type,1,2) country_code
                               ,lookup_code state_code
                FROM   fnd_common_lookups
                WHERE  lookup_type IN ( 'CA_PROVINCE'
                                       ,'US_STATE'))
        WHERE  state_code = lrec_lead_ref.state;
      EXCEPTION
        WHEN OTHERS THEN
           lc_error_str := 'No Country code exists for the given state '|| lrec_lead_ref.state;
           fnd_file.PUT_LINE(fnd_file.LOG, lc_error_str);
           lc_cur_row_status:='FALSE';
           lc_country:=NULL;
      END;

-----------------------------------------------------------------------
      ---      Getting the Revenue band based on OD WCC         ---
-----------------------------------------------------------------------
      IF lrec_lead_ref.num_wc_emp_od < 30 THEN
        lc_rev_band := 'STANDARD';
      ELSIF lrec_lead_ref.num_wc_emp_od BETWEEN 30 AND 50 THEN
        lc_rev_band := 'KEY_1';
      ELSIF lrec_lead_ref.num_wc_emp_od BETWEEN 51 AND 75 THEN
        lc_rev_band := 'KEY_2';
      ELSIF lrec_lead_ref.num_wc_emp_od BETWEEN 76 AND 150 THEN
        lc_rev_band := 'KEY_3';
      ELSIF lrec_lead_ref.num_wc_emp_od BETWEEN 151  AND 250 THEN
        lc_rev_band := 'KEY_4';
      ELSIF lrec_lead_ref.num_wc_emp_od BETWEEN 251 AND 500 THEN
        lc_rev_band := 'MAJOR_1';
      ELSIF lrec_lead_ref.num_wc_emp_od BETWEEN 501 AND 1000 THEN
        lc_rev_band := 'MAJOR_2';
      ELSIF lrec_lead_ref.num_wc_emp_od > 1000 THEN
        lc_rev_band := 'MAJOR_3';
      ELSE
           lc_error_str := 'Invalid OD WCC';
           fnd_file.PUT_LINE(fnd_file.LOG, lc_error_str);
           lc_cur_row_status:='FALSE';
      END IF;

-----------------------------------------------------------------------
      ---               Update Lead referral table    ---
-----------------------------------------------------------------------
      UPDATE xxcrm.xx_sfa_lead_referrals
      SET    process_status = 'IN_PROCESS'
            ,country = lc_country
            ,rev_band = lc_rev_band
            ,existing_cust_flag =lc_party_exists_flag
            ,prospect_osr = lpad(lrec_lead_ref.internid,8,'0')||'-00001-'||lc_orig_system
            ,prospect_site_osr = lpad(lrec_lead_ref.internid,8,'0')||'-00001-'||lc_orig_system --||'-00002-'||lc_orig_system
            ,contact_osr = lpad(lrec_lead_ref.internid,8,'0')||'-00001-'||lc_orig_system --||'-CONTACT'
            ,lead_osr = lpad(lrec_lead_ref.internid,8,'0')||'-00001-'||lc_orig_system
      WHERE  internid = lrec_lead_ref.internid;

      lc_prospect_osr         := lpad(lrec_lead_ref.internid,8,'0')||'-00001-'||lc_orig_system;  -- Added for OSR Defect
      lc_prospect_phone_osr   := lpad(lrec_lead_ref.internid,8,'0')||'-EMAIL-'||lc_orig_system;  -- Added for OSR Defect
      lc_prospect_email_osr   := lpad(lrec_lead_ref.internid,8,'0')||'-PHONE-'||lc_orig_system;  -- Added for OSR Defect


      COMMIT;

-----------------------------------------------------------------------
      ---   If party already exits, fetch the party details   ---
-----------------------------------------------------------------------

      IF lc_party_exists_flag = 'Y' THEN
            lc_seq_no  := lpad(lrec_lead_ref.ship_to_seq,5,'0');
            lc_cust_no := lpad(lrec_lead_ref.cust_aops_number,8,'0');
            lc_orig_sys_ref := lc_cust_no||'-'||lc_seq_no ||'-A0';  --Appending Cust no and Sequence number to get the orig sys ref
            fnd_file.PUT_LINE(fnd_file.LOG,   'Original system reference: ' ||lc_orig_sys_ref);

            BEGIN
               SELECT  HP.party_id
                      ,HP.party_site_id
                      ,HL.postal_code
                      ,PARTY.party_name
               INTO   ln_org_party_id
                     ,ln_address_id  -- added for defect 9955
                     ,lc_zip_code
                     ,lc_party_name
               FROM   apps.hz_orig_sys_references HOS
                     ,apps.hz_cust_acct_sites_all  HCAS
                     ,apps.hz_party_sites HP
                     ,apps.hz_parties PARTY
                     ,apps.hz_locations HL
               WHERE  HOS.owner_table_name      = 'HZ_CUST_ACCT_SITES_ALL'
               AND    HOS.orig_system_reference =  lc_orig_sys_ref
               AND    HCAS.cust_acct_site_id    =  HOS.owner_table_id
               AND    HP. party_site_id         =  HCAS. party_site_id
               AND    HP.status                 =  'A'
               AND    PARTY.party_id=HP.party_id
               AND    HP.location_id=HL.location_id;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
               lc_error_str := 'No Party ID exists for the user entered Cust AOPS and ship to number:' || lc_orig_sys_ref;
               FND_FILE.PUT_LINE(fnd_file.LOG, lc_error_str);
               lc_cur_row_status:='FALSE';
               lc_party_exists_flag := 'N';
               ln_address_id       :=NULL;
            WHEN OTHERS THEN
               lc_error_str :='Unexpected Error fetching Party ID for '||lc_orig_sys_ref ||' Error:'|| SQLERRM;
               FND_FILE.PUT_LINE(fnd_file.LOG,lc_error_str);
               lc_cur_row_status:='FALSE';
               lc_party_exists_flag := 'N';
               ln_address_id       :=NULL;
            END;
      END IF;  --  IF lc_party_exists_flag = 'Y'

--------------------------------------------------------------------------------------------------------------------------------------------------
 ---  If party does not exist already, create organization,address,party site,party site use and then create contact,contact point and lead  ---
 ---  If its already existing customer, go ahead with creating contact, contact ponits, lead and rep assignment ---
--------------------------------------------------------------------------------------------------------------------------------------------------

      IF  ln_org_party_id IS NULL  THEN -- if customer doesn't  exist already
           lc_org_name := lrec_lead_ref.name ;
           FND_FILE.PUT_LINE(FND_FILE.LOG,'**** Create Organization API *****');
           -- Create Organization
           lr_organization_rec.organization_name                := lrec_lead_ref.name;
           lr_organization_rec.created_by_module                := lc_created_by_module;
           lr_organization_rec.party_rec.attribute13            :='PROSPECT';
           lr_organization_rec.party_rec.orig_system_reference  := lc_prospect_osr;    -- Added for OSR Defect
           lr_organization_rec.party_rec.orig_system            := lc_orig_system ;    -- Added for OSR Defect

           --Added for Defect 10671 and 11226  
           lr_organization_rec.party_rec.attribute_category     := 'US';
           lr_organization_rec.party_rec.attribute24            := 'OD REWARDS';
                      
           HZ_PARTY_V2PUB.create_organization(
                 p_init_msg_list      => FND_API.g_true,
                 p_organization_rec   => lr_organization_rec,
                 x_return_status      => lc_return_status,
                 x_msg_count          => ln_msg_count,
                 x_msg_data           => lc_msg_data,
                 x_party_id           => ln_org_party_id,
                 x_party_number       => lc_org_party_number,
                 x_profile_id         => ln_org_profile_id);

           FND_FILE.PUT_LINE(FND_FILE.LOG,SUBSTR('lc_return_status = '||lc_return_status,1,255));
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Party ID: '||ln_org_party_id);
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Number: '||lc_org_party_number);

           IF lc_return_status <> 'S' then
              FOR i IN 1..ln_msg_count
              LOOP
                 lc_msg_data:=lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
              END LOOP;
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error msg: '||lc_msg_data);
              lc_error_str :=lc_error_str || lc_msg_data;
              lc_cur_row_status:='FALSE';
           END IF;

      --  API to Create address
          FND_FILE.PUT_LINE(FND_FILE.LOG,'');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'**** Create Address location API *****');
          lr_location_rec.address1          := lrec_lead_ref.addr1;
          lr_location_rec.created_by_module := lc_created_by_module;
          lr_location_rec.city              := lrec_lead_ref.city;
          lr_location_rec.postal_code       := lrec_lead_ref.zip;
          lr_location_rec.state             := lrec_lead_ref.state;
          lr_location_rec.country           := lc_country;

          HZ_LOCATION_V2PUB.create_location (
              p_init_msg_list              => 'T'
             ,p_location_rec               =>  lr_location_rec
             ,x_location_id                =>  ln_location_id
             ,x_return_status              =>  lc_return_status
             ,x_msg_count                  =>  ln_msg_count
             ,x_msg_data                   =>  lc_msg_data);

          FND_FILE.PUT_LINE(FND_FILE.LOG,SUBSTR('lc_return_status = '||lc_return_status,1,255));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Location ID: ' ||ln_location_id);

          IF ln_create_loc_msg_count >1 THEN
             FOR I IN 1..ln_create_loc_msg_count
              LOOP
                 lc_msg_data:=lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
              END LOOP;

             FND_FILE.PUT_LINE(FND_FILE.LOG,'Error msg: '||lc_msg_data);
             lc_error_str :=lc_error_str || lc_msg_data;
             lc_cur_row_status:='FALSE';
          END IF;

     --Create ship to Party Site

          FND_FILE.PUT_LINE(FND_FILE.LOG,'');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'**** Create  Party site API *****');
          lr_party_site_rec.party_id                 := ln_org_party_id;
          lr_party_site_rec.location_id              := ln_location_id;
          lr_party_site_rec.status                   := 'A';
          lr_party_site_rec.created_by_module        := lc_created_by_module;
          lr_party_site_rec.orig_system_reference    := lc_prospect_osr; -- Added for OSR Defect
          lr_party_site_rec.orig_system              := lc_orig_system ; -- Added for OSR Defect

          HZ_PARTY_SITE_V2PUB.Create_Party_Site (
               p_init_msg_list         => FND_API.g_true,
               p_party_site_rec        => lr_party_site_rec,
               x_party_site_id         => ln_party_site_id,
               x_party_site_number     => lc_party_site_number,
               x_return_status         => lc_return_status,
               x_msg_count             => ln_msg_count,
               x_msg_data              => lc_msg_data);
          FND_FILE.PUT_LINE(FND_FILE.LOG,SUBSTR('lc_return_status = '||lc_return_status,1,255));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Site ID: ' ||ln_party_site_id);
          IF lc_return_status <> 'S' THEN
              FOR i IN 1..ln_msg_count
               LOOP
                  lc_msg_data := lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
               END LOOP;

              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error msg:'||x_error_message);
              lc_error_str :=lc_error_str || lc_msg_data;
              lc_cur_row_status:='FALSE';
          END IF;

     --Create Ship to Party Site Use

          FND_FILE.PUT_LINE(FND_FILE.LOG,'');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'**** Create SHIP TO site use API *****');
          lr_party_site_use_rec.SITE_USE_TYPE      := 'SHIP_TO';
          lr_party_site_use_rec.PARTY_SITE_ID      := ln_party_site_id;
          lr_party_site_use_rec.PRIMARY_PER_TYPE   := 'Y';
          lr_party_site_use_rec.STATUS             := 'A';
          lr_party_site_use_rec.CREATED_BY_MODULE  := lc_created_by_module;

          HZ_PARTY_SITE_V2PUB.Create_Party_Site_Use(
                p_init_msg_list         => FND_API.g_true,
                p_party_site_use_rec    => lr_party_site_use_rec,
                x_party_site_use_id     => ln_party_site_use_id,
                x_return_status         => lc_return_status,
                x_msg_count             => ln_msg_count,
                x_msg_data              => lc_msg_data);

          FND_FILE.PUT_LINE(FND_FILE.LOG,SUBSTR('lc_return_status = '||lc_return_status,1,255));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Site Use ID: ' ||ln_party_site_use_id);

          IF lc_return_status <> 'S' then
              FOR i IN 1..ln_msg_count
               LOOP
                 lc_msg_data := lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
               END LOOP;

              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error msg: '||lc_msg_data);
              lc_error_str :=lc_error_str || lc_msg_data;
              lc_cur_row_status:='FALSE';
          END IF;
      END IF; -- IF  ln_org_party_id IS NULL  THEN

      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'**** Create Person API *****');

      lr_person_rec.person_first_name       := lrec_lead_ref.fname;
      lr_person_rec.person_last_name        := lrec_lead_ref.lname;
      lr_person_rec.created_by_module       := lc_created_by_module;

      HZ_PARTY_V2PUB.create_person(
                  p_init_msg_list      => FND_API.g_true,
                  p_person_rec         => lr_person_rec,
                  x_party_id           => ln_pers_party_id,
                  x_party_number       => lc_pers_party_number,
                  x_profile_id         => ln_pers_profile_id,
                  x_return_status      => lc_return_status,
                  x_msg_count          => ln_msg_count,
                  x_msg_data           => lc_msg_data);

      FND_FILE.PUT_LINE(FND_FILE.LOG,SubStr('lc_return_status = '||lc_return_status,1,255));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Person Party ID: ' ||ln_pers_party_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Person Party Number: '||lc_pers_party_number);

      IF lc_return_status <> 'S' then
         FOR i IN 1..ln_msg_count
           LOOP
                   lc_msg_data:=lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
           END LOOP;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error msg: '||lc_msg_data);
         lc_error_str :=lc_error_str || lc_msg_data;
         lc_error_str :=lc_error_str || lc_msg_data;
         lc_cur_row_status:='FALSE';
      END IF;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'**** Create Organization Contact API *****');

    --Create Organization Contact
      lr_contact_rec.created_by_module                := lc_created_by_module;
      lr_contact_rec.party_rel_rec.SUBJECT_ID         := ln_pers_party_id;
      lr_contact_rec.party_rel_rec.SUBJECT_TYPE       := 'PERSON';
      lr_contact_rec.party_rel_rec.SUBJECT_TABLE_NAME := 'HZ_PARTIES';
      lr_contact_rec.party_rel_rec.OBJECT_ID          := ln_org_party_id;
      lr_contact_rec.party_rel_rec.OBJECT_TYPE        := 'ORGANIZATION';
      lr_contact_rec.party_rel_rec.OBJECT_TABLE_NAME  := 'HZ_PARTIES';
      lr_contact_rec.party_rel_rec.RELATIONSHIP_CODE  := 'CONTACT_OF';
      lr_contact_rec.party_rel_rec.RELATIONSHIP_TYPE  := 'CONTACT';
      lr_contact_rec.party_rel_rec.START_DATE         := SYSDATE;
      lr_contact_rec.party_rel_rec.STATUS             := 'A';
      lr_contact_rec.party_rel_rec.created_by_module  := lc_created_by_module;
      lr_contact_rec.job_title                        := lrec_lead_ref.contact_title;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Sub Id:'||lr_contact_rec.party_rel_rec.SUBJECT_ID);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Obj ID:' ||lr_contact_rec.party_rel_rec.OBJECT_ID);


      HZ_PARTY_CONTACT_V2PUB.create_org_contact(
                  p_init_msg_list      => FND_API.g_true,
                  p_org_contact_rec    => lr_contact_rec,
                  x_org_contact_id     => ln_org_contact_id,
                  x_party_rel_id       => ln_party_reln_id,
                  x_party_id           => ln_cntct_party_id,
                  x_party_number       => lc_cntct_party_number,
                  x_return_status      => lc_return_status,
                  x_msg_count          => ln_msg_count,
                  x_msg_data           => lc_msg_data);

      FND_FILE.PUT_LINE(FND_FILE.LOG,SubStr('lc_return_status = '||lc_return_status,1,255));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Org Contact ID: ' ||ln_org_contact_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Relation ID: '||ln_party_reln_id);

      IF lc_return_status <> 'S' then
          FOR i IN 1..ln_msg_count
            LOOP
                lc_msg_data:=lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
            END LOOP;

          FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Msg: '||lc_msg_data);
          lc_error_str :=lc_error_str || lc_msg_data;
          lc_cur_row_status:='FALSE';
      END IF;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'**** Create Phone Contact Point API *****');

      --Create Contact Point of type 'PHONE'
      lr_contact_point_rec_phone.created_by_module      := lc_created_by_module;
      lr_contact_point_rec_phone.contact_point_type     := 'PHONE';
      lr_contact_point_rec_phone.status                 := 'A';
      lr_contact_point_rec_phone.owner_table_name       := 'HZ_PARTIES';
      lr_contact_point_rec_phone.owner_table_id         := ln_cntct_party_id;
      lr_contact_point_rec_phone.primary_flag           := 'Y';
      lr_contact_point_rec_phone.contact_point_purpose  := 'BUSINESS';
      lr_contact_point_rec_phone.primary_by_purpose     := 'Y';
      lr_contact_point_rec_phone.actual_content_source  := 'USER_ENTERED';
      lr_contact_point_rec_phone.orig_system_reference  := lc_prospect_phone_osr;  -- Added for OSR Defect
      lr_contact_point_rec_phone.orig_system            := lc_orig_system ; -- Added for OSR Defect
      lr_phone_rec.phone_number                         := lrec_lead_ref.phone;
      -- defect 10822, Changes done by Satish Silveri START
      lr_phone_rec.phone_area_code			:= lrec_lead_ref.PHONE_AREA_CODE;
      lr_phone_rec.phone_country_code			:= lrec_lead_ref.PHONE_COUNTRY_CODE;
      lr_phone_rec.phone_extension			:= lrec_lead_ref.PHONE_EXTENSION;
      -- defect 10822, Changes done by Satish Silveri END
      lr_phone_rec.phone_line_type                      :='GEN';

      hz_contact_point_v2pub.create_phone_contact_point (
              p_init_msg_list      => fnd_api.g_true,
              p_contact_point_rec  => lr_contact_point_rec_phone,
              p_phone_rec          => lr_phone_rec,
              x_contact_point_id   => ln_phone_contact_point_id,
              x_return_status      => lc_return_status,
              x_msg_count          => ln_msg_count,
              x_msg_data           => lc_msg_data);

      FND_FILE.PUT_LINE(FND_FILE.LOG,SubStr('lc_return_status = '||lc_return_status,1,255));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Contact Point ID (PHONE): ' ||ln_phone_contact_point_id);

      IF lc_return_status <> 'S' then
          FOR i IN 1..ln_msg_count
          LOOP
              lc_msg_data:=lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
          END LOOP;
            --x_error_message := x_error_message|| lc_msg_data;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error msg:' ||lc_msg_data);
            --x_error_message :='';
            lc_error_str :=lc_error_str || lc_msg_data;
            lc_cur_row_status:='FALSE';
      END IF;

      --Create Contact Point of type 'Email'
      FND_FILE.PUT_LINE(FND_FILE.LOG,'**** Create Email Contact Point API *****');
      lr_contact_point_rec_email.created_by_module      := lc_created_by_module;
      lr_contact_point_rec_email.contact_point_type     := 'EMAIL';
      lr_contact_point_rec_email.status                 := 'A';
      lr_contact_point_rec_email.owner_table_name       := 'HZ_PARTIES';
      lr_contact_point_rec_email.owner_table_id         := ln_cntct_party_id;
      lr_contact_point_rec_email.primary_flag           := 'Y';
      lr_contact_point_rec_email.contact_point_purpose  := 'BUSINESS';
      lr_contact_point_rec_email.primary_by_purpose     := 'Y';
      lr_contact_point_rec_email.actual_content_source  := 'USER_ENTERED';
      lr_contact_point_rec_email.orig_system_reference  := lc_prospect_email_osr;  -- Added for OSR Defect
      lr_contact_point_rec_email.orig_system            := lc_orig_system ; -- Added for OSR Defect
      lr_email_rec.email_address                        := lrec_lead_ref.contact_email_id;
      
      IF lr_email_rec.email_address IS NOT NULL THEN
      HZ_CONTACT_POINT_V2PUB.create_email_contact_point (
              p_init_msg_list      => fnd_api.g_true,
              p_contact_point_rec  => lr_contact_point_rec_email,
              p_email_rec          => lr_email_rec,
              x_contact_point_id   => ln_email_contact_point_id,
              x_return_status      => lc_return_status,
              x_msg_count          => ln_msg_count,
              x_msg_data           => lc_msg_data);

      FND_FILE.PUT_LINE(FND_FILE.LOG,SubStr('lc_return_status = '||lc_return_status,1,255));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Contact Point ID (EMAIL): ' ||ln_email_contact_point_id);

      IF lc_return_status <> 'S' then
          FOR i IN 1..ln_msg_count
          LOOP
              lc_msg_data:=lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
          END LOOP;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Error msg: '||lc_msg_data);
            lc_error_str :=lc_error_str || lc_msg_data;
            lc_cur_row_status:='FALSE';
      END IF;
     END IF;
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Fetching source promotion id from Source');

     OPEN lcu_lead_source(lrec_lead_ref.source);
     FETCH lcu_lead_source INTO lc_source_promotion_id;
       IF lcu_lead_source%NOTFOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error msg: Lead Source not found '||lrec_lead_ref.source);
            lc_error_str :=lc_error_str || 'Error msg: Lead Source not found '||lrec_lead_ref.source;
            lc_cur_row_status:='FALSE';
            lc_source_promotion_id:=NULL;
       END IF;
     CLOSE lcu_lead_source;

    --API call to create Sales Leads
       FND_FILE.PUT_LINE(FND_FILE.LOG,'');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'**** Create Sales Lead API *****');
       lr_sales_lead_rec.status_code         := 'NEW';
       lr_sales_lead_rec.source_promotion_id := lc_source_promotion_id;
       lr_sales_lead_rec.customer_id         := ln_org_party_id;
       lr_sales_lead_rec.address_id          := NVL(ln_address_id,ln_party_site_id);  -- added for defect 9955
       lr_sales_lead_rec.source_system       := lc_source_system;
       lr_sales_lead_rec.description         := NVL(lc_party_name,lrec_lead_ref.name )||' Lead';
       lr_sales_lead_rec.attribute4          := lrec_lead_ref.store_number;
       lr_sales_lead_rec.orig_system_reference  := lc_prospect_osr;  -- Added for OSR Defect
       --lr_sales_lead_rec.orig_system_code       := lc_orig_system;  -- Added for OSR Defect
       AS_SALES_LEADS_PUB.CREATE_SALES_LEAD(
                                         p_api_version_number         => 2.0
                                        ,p_init_msg_list              => 'T'
                                        ,p_commit                     => 'F'
                                        ,p_validation_level           => NULL
                                        ,p_check_access_flag          => NULL
                                        ,p_admin_flag                 => NULL
                                        ,p_admin_group_id             => NULL
                                        ,p_identity_salesforce_id     => NULL
                                        ,p_sales_lead_profile_tbl     => lt_sales_lead_profile_tbl
                                        ,p_sales_lead_rec             => lr_sales_lead_rec
                                        ,p_sales_lead_line_tbl        => lt_sales_lead_line_tbl
                                        ,p_sales_lead_contact_tbl     => lt_sales_lead_contact_tbl
                                        ,x_sales_lead_id              => ln_sales_lead_id
                                        ,x_sales_lead_line_out_tbl    => lt_sales_lead_line_out_tbl
                                        ,x_sales_lead_cnt_out_tbl     => lt_sales_lead_cnt_out_tbl
                                        ,x_return_status              => lc_return_status
                                        ,x_msg_count                  => ln_msg_count
                                        ,x_msg_data                   => lc_msg_data
                                    );
       FND_FILE.PUT_LINE(FND_FILE.LOG,SubStr('lc_return_status = '||lc_return_status,1,255));
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Sales Lead ID: ' ||ln_sales_lead_id);

       IF ln_msg_count >1 THEN
         FOR I IN 1..ln_msg_count
            LOOP
             lc_msg_data := lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
            END LOOP;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error msg: '||lc_msg_data);
        lc_error_str :=lc_error_str || lc_msg_data;
        lc_cur_row_status:='FALSE';
       END IF;

       --API to insert Notes
       IF lrec_lead_ref.notes IS NOT NULL THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'');
           FND_FILE.PUT_LINE(FND_FILE.LOG,'**** Create Notes API *****');
           JTF_NOTES_PUB.create_note(
                                    p_parent_note_id           => NULL,
                                    p_jtf_note_id              => NULL,
                                    p_api_version              => 1.0,
                                    p_init_msg_list            => fnd_api.g_false,
                                    p_commit                   => fnd_api.g_false,
                                    p_validation_level         => fnd_api.g_valid_level_full,
                                    x_return_status            => lc_return_status,
                                    x_msg_count                => ln_msg_count,
                                    x_msg_data                 => lc_msg_data,
                                    p_org_id                   => NULL,
                                    p_source_object_id         => ln_sales_lead_id,
                                    p_source_object_code       => 'LEAD',
                                    p_notes                    => lrec_lead_ref.notes,
                                    p_notes_detail             => NULL,
                                    p_note_status              => 'I',
                                    p_entered_by               => fnd_global.user_id,
                                    p_entered_date             => SYSDATE,
                                    x_jtf_note_id              => ln_note_id,
                                    p_last_update_date         => SYSDATE,
                                    p_last_updated_by          => fnd_global.user_id,
                                    p_creation_date            => SYSDATE,
                                    p_created_by               => fnd_global.user_id,
                                    p_last_update_login        => fnd_global.login_id,
                                    p_attribute1               => NULL,
                                    p_attribute2               => NULL,
                                    p_attribute3               => NULL,
                                    p_attribute4               => NULL,
                                    p_attribute5               => NULL,
                                    p_attribute6               => NULL,
                                    p_attribute7               => NULL,
                                    p_attribute8               => NULL,
                                    p_attribute9               => NULL,
                                    p_attribute10              => NULL,
                                    p_attribute11              => NULL,
                                    p_attribute12              => NULL,
                                    p_attribute13              => NULL,
                                    p_attribute14              => NULL,
                                    p_attribute15              => NULL,
                                    p_context                  => NULL,
                                    p_note_type                => NULL,
                                    p_jtf_note_contexts_tab    => jtf_note_contexts_tab_dflt);

           FND_FILE.PUT_LINE(FND_FILE.LOG,SubStr('lc_return_status = '||lc_return_status,1,255));
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Notes ID: ' ||ln_note_id);

           IF lc_return_status <> 'S' then
             FOR I IN 1..ln_msg_count
               LOOP
                 lc_msg_data := lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
               END LOOP;
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error msg: '||lc_msg_data);
                  lc_error_str :=lc_error_str || lc_msg_data;
                  lc_cur_row_status:='FALSE';
           END IF;
       END IF;

       lt_sales_lead_con_tbl(ln_var).CONTACT_PARTY_ID      := ln_cntct_party_id; --Party Id created from the call to hz_party_contact_v2pub.create_org_contact
       lt_sales_lead_con_tbl(ln_var).PRIMARY_CONTACT_FLAG  := 'Y';
       lt_sales_lead_con_tbl(ln_var).CUSTOMER_ID           := ln_org_party_id;
       FND_FILE.PUT_LINE(FND_FILE.LOG,'');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'**** Create Sales Lead Contact *****');
     --Call AS_SALES_LEADS_PUB.Create_sales_lead_contacts to add the contact to a Lead
       AS_SALES_LEADS_PUB.Create_sales_lead_contacts(P_Api_Version_Number      => 2.0
                                                ,P_Init_Msg_List           => 'T'
                                                ,P_Commit                  => 'F'
                                                ,p_validation_level        => NULL
                                                ,P_Check_Access_Flag       => NULL
                                                ,P_Admin_Flag              => NULL
                                                ,P_Admin_Group_Id          => NULL
                                                ,P_identity_salesforce_id  => NULL
                                                ,P_Sales_Lead_Profile_Tbl  => lt_sales_lead_profile_tbl
                                                ,P_SALES_LEAD_CONTACT_Tbl  => lt_sales_lead_con_tbl
                                                ,P_SALES_LEAD_ID           => ln_sales_lead_id
                                                ,X_SALES_LEAD_CNT_OUT_Tbl  => lt_sales_lead_con_out_tbl
                                                ,X_Return_Status           => lc_return_status
                                                ,X_Msg_Count               => ln_msg_count
                                                ,X_Msg_Data                => lc_msg_data
                                              );

       FND_FILE.PUT_LINE(FND_FILE.LOG,SubStr('lc_return_status = '||lc_return_status,1,255)||chr(13));

       IF lc_return_status <> 'S' THEN
          FOR I IN 1..ln_msg_count
            LOOP
              lc_msg_data := lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
            END LOOP;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Error msg: '||lc_msg_data);
          lc_error_str :=lc_error_str || lc_msg_data;
          lc_cur_row_status:='FALSE';
       END IF;

       IF lc_party_exists_flag = 'N' THEN
        -- Get Territory Assignment source for Lead Referral
       BEGIN
            SELECT description
            INTO   lc_terr_asgnmnt_source
            FROM   FND_LOOKUP_VALUES_VL
            WHERE  lookup_type = 'XX_SFA_TERR_ASGNMNT_SOURCE'
            AND  lookup_code = 'RULE_ASGNMNT_LR'
            AND  enabled_flag = 'Y'
            AND  SYSDATE BETWEEN start_date_active AND NVL(end_date_active, SYSDATE+1);
       EXCEPTION
         WHEN OTHERS THEN
           x_error_message := 'No Lookup Value defined for Territory Assignment Source for Lead Referral.';
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Error msg: '||x_error_message);
           lc_terr_asgnmnt_source := NULL;
       END;

       --Call the common API for getting the resource/role/group based on territory rule
             lc_postal_code := NVL(lc_zip_code,lrec_lead_ref.zip);
             FND_FILE.PUT_LINE(FND_FILE.LOG,'');
             FND_FILE.PUT_LINE(FND_FILE.LOG,'**** Getting the resource/role/group based on territory rule *****');

             XX_TM_TERRITORY_UTIL_PKG.TERR_RULE_BASED_WINNER_LOOKUP(
                   p_party_site_id              => ln_party_site_id,
                   p_org_type                   => 'PROSPECT',
                   p_od_wcw                     => lrec_lead_ref.num_wc_emp_od,
                   p_sic_code                   => NULL,
                   p_postal_code                => lc_postal_code,
                   p_division                   => 'BSD',
                   p_compare_creator_territory  => 'N',
                   p_nam_terr_id => ln_nam_terr_id,
                   p_resource_id => ln_resource_id,
                   p_role_id => ln_role_id,
                   p_group_id => ln_group_id,
                   p_full_access_flag => lc_full_access_flag,
                   x_return_status => lc_return_status,
                   x_message_data => lc_msg_data);

             IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'Get Winner Error for party site id: ' ||
                                                  ln_party_site_id || ' : ' || lc_msg_data);
             ELSE
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'**** Create Territory ****');
                 XX_JTF_RS_NAMED_ACC_TERR_PUB.Create_Territory(
                        p_api_version_number       => 1.0
                       ,p_named_acct_terr_id      => NULL
                       ,p_named_acct_terr_name    => NULL
                       ,p_named_acct_terr_desc    => NULL
                       ,p_status                  => 'A'
                       ,p_start_date_active       => SYSDATE
                       ,p_end_date_active         => NULL
                       ,p_full_access_flag        => lc_full_access_flag
                       ,p_source_terr_id          => NULL
                       ,p_resource_id             => ln_resource_id
                       ,p_role_id                 => ln_role_id
                       ,p_group_id                => ln_group_id
                       ,p_entity_type             => 'PARTY_SITE'
                       ,p_entity_id               => ln_party_site_id
                       ,p_source_entity_id        => NULL
                       ,p_source_system           => NULL
                       ,p_allow_inactive_resource => 'N'
                       ,p_set_extracted_status    => 'N'
                       ,p_terr_asgnmnt_source     => lc_terr_asgnmnt_source
                       ,p_commit                  => FALSE
                       ,x_error_code              => lc_return_status
                       ,x_error_message           => lc_msg_data);
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Resource assigned:' || ln_resource_id);

                 IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG, 'Create Territory Error for party site id: ' ||
                                                      ln_party_site_id || ' : ' || lc_msg_data);
                     lc_cur_row_status:='FALSE';
                     lc_error_str :=lc_error_str || lc_msg_data;
                 END IF;
             END IF;    --lc_return_status <> FND_API.G_RET_STS_SUCCESS
       END IF;     --lc_party_exists_flag

       -- Call XX_JTF_SALES_REP_LEAD_CRTN.CREATE_SALES_LEAD API to assign Sales Person to the Leads
       XX_JTF_SALES_REP_LEAD_CRTN.create_sales_lead(
                                              p_sales_lead_id => ln_sales_lead_id
                                             );

       IF lc_party_exists_flag = 'N' THEN
       -- Make a call to create Extensible attributes
       -- Fetch the Party Site Id from hz_party_sites
          IF (ln_sales_lead_id IS NOT NULL) THEN
             BEGIN
                 SELECT address_id -- this is the Party site Id
                 INTO   lc_party_site_id
                 FROM   as_sales_leads
                 WHERE  sales_lead_id  = ln_sales_lead_id;
             EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Fetch of Party Site Id - no data found');
                   x_error_message := 'Party Site Id not found';
                   lc_cur_row_status:='FALSE';
                   lc_error_str :=lc_error_str || x_error_message;
                 WHEN OTHERS THEN
                   fnd_file.PUT_LINE(fnd_file.LOG, 'Fetch of Party Site Id - TOO many records');
                   x_error_message := 'Error: Party Site Id';
                   lc_cur_row_status:='FALSE';
                   lc_error_str :=lc_error_str || x_error_message;
             END;

             BEGIN
                SELECT relationship_id
                INTO   lc_rel_id
                FROM   apps.hz_relationships
                WHERE  subject_id  =  ln_pers_party_id ;--Party Id of create Person
             EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Fetch of Relationship Id - no data found');
                    x_error_message := 'Error: Relationship Id not found';
                    lc_cur_row_status:='FALSE';
                    lc_error_str :=lc_error_str || x_error_message;
                WHEN OTHERS THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Fetch of Relationship Id - TOO many records');
                    x_error_message := 'Error: Relationship Id';
                    lc_cur_row_status:='FALSE';
                    lc_error_str :=lc_error_str || x_error_message;
             END;

             BEGIN
                 lr_site_contact_rec.N_EXT_ATTR1 := lc_rel_id;
                 lr_site_contact_rec.C_EXT_ATTR1 := 'A';
                 lr_site_contact_rec.D_EXT_ATTR1 := trunc(SYSDATE);
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'Process Site contacts for '      || lc_party_site_id);
                 PROCESS_SITE_CONTACTS (  p_party_site_id      => lc_party_site_id
                                         ,p_site_contact_rec   => lr_site_contact_rec
                                         ,x_return_msg         => lc_ret_msg
                                       );
                 x_error_message := x_error_message|| lc_msg_data;
                 IF lc_ret_msg IS NOT NULL THEN
                     lc_cur_row_status:='FALSE';
                     lc_error_str :=lc_error_str || x_error_message;
                 END IF;
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Message of Process Site contacts '      || lc_ret_msg);
             EXCEPTION
                 WHEN OTHERS THEN
                    lc_cur_row_status:='FALSE';
                    lc_error_str := SQLERRM;
                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Unexpected error in before call to Process Site contacts '|| lc_error_str);
             END;

             BEGIN
                   lr_st_site_demo_rec.RECORD_ID   := 20;
                   lr_st_site_demo_rec.N_EXT_ATTR8 := lrec_lead_ref.num_wc_emp_od;
                   lr_st_site_demo_rec.N_EXT_ATTR1 := lrec_lead_ref.duns_number;
                   process_site_demographics
                        ( p_party_site_id   => lc_party_site_id,
                          p_site_demo_rec   => lr_st_site_demo_rec,
                          x_return_msg      => lc_msg_data
                        );
                   x_error_message := x_error_message|| lc_msg_data;
                   IF lc_ret_msg IS NOT NULL THEN
                       lc_cur_row_status:='FALSE';
                       lc_error_str :=lc_error_str || x_error_message;
                   END IF;
                   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Message of Process Site demographics '      || lc_ret_msg);
             EXCEPTION
                WHEN OTHERS THEN
                   lc_cur_row_status:='FALSE';
                   lc_error_str := SQLERRM;
                   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Unexpected error in before call to Process Site Demographics '|| lc_error_str);
             END;

       END IF; -- End of ln_sales_id not null
       END IF; -- Party does not exist already

--Following is the logic to fetch Lead Number and the Resource name to be displayed in the OUT file
       BEGIN
            SELECT lead_number
            INTO  lc_lead_number
            FROM  as_sales_leads
            WHERE sales_lead_id =ln_sales_lead_id;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
            x_error_message := 'Sales Lead Number not found';
            lc_cur_row_status:='FALSE';
            lc_error_str :=lc_error_str || x_error_message;
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception in Lead number fetch logic :' || lc_error_str);
          WHEN OTHERS THEN
            x_error_message :=  'Lead Number  : '||ln_sales_lead_id||' Error: '|| SQLERRM;
            lc_cur_row_status:='FALSE';
            lc_error_str :=lc_error_str || x_error_message;
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Unexpected Error in Lead number fetch logic :' || lc_error_str);
       END;

       BEGIN
            SELECT REPLACE(RES.source_name, ',',NULL)
                  ,RES.source_email
            INTO   lc_sales_person
                  ,lc_resource_email
            FROM   apps.XX_TM_NAM_TERR_CURR_ASSIGN_V ASGN
                  ,jtf_rs_resource_extns RES
            WHERE  entity_type     = 'LEAD'
            AND    entity_id       = ln_sales_lead_id
            AND    RES.resource_id = ASGN.resource_id;
       EXCEPTION
            WHEN NO_DATA_FOUND THEN
                x_error_message := 'Lead Created but no sales rep found for the party site for AOPS No. '||lc_orig_sys_ref;
                --lc_cur_row_status:='FALSE'; -- For 10321.Error msg changed since party site does not have rep assigned to it.
                lc_error_str :=lc_error_str || x_error_message;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Error: '||lc_error_str); 
            WHEN OTHERS THEN
                x_error_message:= 'Sales Person : '||lc_sales_person||' Error: '|| SQLERRM;
                lc_cur_row_status:='FALSE';
                lc_error_str :=lc_error_str || x_error_message;
       END;

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Sales person Email: '||lc_resource_email); 

       UPDATE xxcrm.xx_sfa_lead_referrals
       SET    sales_rep_email=lc_resource_email
             ,attribute1=ln_request_id
             ,attribute15=ln_sales_lead_id  -- Added to track sales lead id
             ,error_message=lc_error_str
       WHERE internid=lrec_lead_ref.internid;

       SELECT
       DECODE (lc_cur_row_status , 'TRUE','PROCESSED','FALSE','ERRORED')
       INTO lc_out_status
       FROM DUAL;

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,NVL(lc_party_name,lrec_lead_ref.name)||'|'||
                                         NVL(lc_party_name,lrec_lead_ref.name)||' Lead '||'|'||
                                         lc_lead_number||'|'||
                                         lrec_lead_ref.store_number||'|'||
                                         lc_sales_person||'|'||
                                         lrec_lead_ref.fname||'|'||
                                         lrec_lead_ref.lname||'|'||
                                         lrec_lead_ref.Phone ||'|'||
                                         lrec_lead_ref.contact_email_id||'|'||
                                         lc_out_status||'|'||
                                         lrec_lead_ref.internid);

       IF lc_cur_row_status = 'FALSE' THEN
           UPDATE apps.xx_sfa_lead_referrals
           SET    process_status = 'ERRORED' 
           WHERE internid=lrec_lead_ref.internid;
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message : '|| lrec_lead_ref.error_message);
       END IF;

    EXCEPTION
       WHEN OTHERS THEN
          x_error_message  := '"Error"' || ',' || SQLERRM;
          lc_cur_row_status := 'FALSE';
          lc_error_str :=lc_error_str || x_error_message;

          UPDATE apps.xx_sfa_lead_referrals
          SET PROCESS_STATUS='ERRORED'
          WHERE internid=lrec_lead_ref.internid;

          FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected error in XX_LEAD_CREATE Loop : '||lc_error_str);
    END; -- begin inside main loop
    END LOOP; -- main loop

EXCEPTION
    WHEN OTHERS THEN
       lc_error_str := '"Error"' || ',' || SQLERRM;
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected error in XX_LEAD_CREATE : '||lc_error_str);
END XX_LEAD_CREATE;

-- +===================================================================+
-- | Name        :  PROCESS_SITE_CONTACTS                              |
-- | Description :  This procedure is used to construct the table      |
-- |                Structure used by the extensiable api's.           |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE PROCESS_SITE_CONTACTS
   (    p_party_site_id      IN   NUMBER
       ,p_site_contact_rec   IN   SITE_CONTACTS_REC
       ,x_return_msg         OUT  VARCHAR2
   )
IS
   le_exception                  EXCEPTION;
   ln_party_site_id              NUMBER;
   lc_user_table                 EGO_USER_ATTR_ROW_TABLE  := EGO_USER_ATTR_ROW_TABLE();
   lc_temp_user_table            EGO_USER_ATTR_ROW_TABLE  := EGO_USER_ATTR_ROW_TABLE();
   lc_row_temp_obj               EGO_USER_ATTR_ROW_OBJ    := EGO_USER_ATTR_ROW_OBJ(null,null,null,null,null,null,null,null,null);
   lc_data_table                 EGO_USER_ATTR_DATA_TABLE := EGO_USER_ATTR_DATA_TABLE();
   lc_temp_data_table            EGO_USER_ATTR_DATA_TABLE := EGO_USER_ATTR_DATA_TABLE();
   lc_data_temp_obj              EGO_USER_ATTR_DATA_OBJ   := EGO_USER_ATTR_DATA_OBJ(null,null,null,null,null,null,null,null);
   ln_retcode                    NUMBER;
   ln_errbuf                     VARCHAR2(2000);
   lc_rowid                      VARCHAR2(100);
   lc_failed_row_id_list         VARCHAR2(1000);
   lc_return_status              VARCHAR2(1000);
   lc_errorcode                  NUMBER;
   ln_msg_count                  NUMBER;
   lc_msg_data                   VARCHAR2(1000);
   lv_return_msg                 VARCHAR2(1000);
   lc_errors_tbl                 ERROR_HANDLER.Error_Tbl_Type;
   ln_msg_text                   VARCHAR2(32000);
   lr_site_contact_rec           SITE_CONTACTS_REC;

BEGIN
     ln_party_site_id := p_party_site_id;
     IF ln_party_site_id IS NULL THEN
        x_return_msg := 'Party Site Id is not Provided';
        RAISE le_exception;
     END IF;
       lr_site_contact_rec := p_site_contact_rec;
       Build_ext_table_site_contact
        (   p_user_row_table        => lc_user_table
           ,p_user_data_table       => lc_data_table
           ,p_ext_attribs_row       => lr_site_contact_rec
           ,x_return_msg            => lv_return_msg
        );
     IF lv_return_msg IS NOT NULL THEN
        x_return_msg := lv_return_msg;
        fnd_file.PUT_LINE(fnd_file.LOG,' Error in Building ext attr for Site contacts:' || x_return_msg);
        RAISE le_exception;
     END IF;
     HZ_EXTENSIBILITY_PUB.process_partysite_record
        (   p_api_version           => xx_cdh_cust_exten_attri_pkg.g_api_version
           ,p_party_site_id         => ln_party_site_id
           ,p_attributes_row_table  => lc_user_table
           ,p_attributes_data_table => lc_data_table
           ,x_failed_row_id_list    => lc_failed_row_id_list
           ,x_return_status         => lc_return_status
           ,x_errorcode             => lc_errorcode
           ,x_msg_count             => ln_msg_count
           ,x_msg_data              => lc_msg_data
        );
     FND_FILE.PUT_LINE(FND_FILE.LOG,   ' PROCESS_SITE_CONTACTS: ');
     FND_FILE.PUT_LINE(FND_FILE.LOG,   ' Return status: ' || lc_return_status);
     FND_FILE.PUT_LINE(FND_FILE.LOG,   ' Error code: ' || lc_errorcode);
     FND_FILE.PUT_LINE(FND_FILE.LOG,   ' Msg count: ' || ln_msg_count);
     FND_FILE.PUT_LINE(FND_FILE.LOG,   ' Msg data: ' || lc_msg_data);
     IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN
        x_return_msg := NULL;
        COMMIT;
     ELSE
        IF ln_msg_count > 0 THEN
           ERROR_HANDLER.Get_Message_List(lc_errors_tbl);
           FOR i IN 1..lc_errors_tbl.COUNT
             LOOP
              ln_msg_text := ln_msg_text||' '||lc_errors_tbl(i).message_text;
             END LOOP;
           x_return_msg := ln_msg_text;
         END IF;
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return msg in process site contacts: ' || x_return_msg);
EXCEPTION
   WHEN le_exception THEN
      NULL;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in Process site contacts'|| x_return_msg);
   WHEN OTHERS THEN
      x_return_msg := 'Unexpected Error in Process Site contacts - '||SQLERRM;
      FND_FILE.PUT_LINE(FND_FILE.LOG, x_return_msg);
END PROCESS_SITE_CONTACTS;

-- +===================================================================+
-- | Name        :  PROCESS_SITE_DEMOGRAPHICS                          |
-- | Description :  This procedure is used to construct the table      |
-- |                Structure used by the extensiable api's.           |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE PROCESS_SITE_DEMOGRAPHICS
   (   p_party_site_id   IN   NUMBER,
       p_site_demo_rec   IN   SITE_DEMOGRAPHICS_REC,
       x_return_msg     OUT   VARCHAR2
   )
IS
   le_exception                  EXCEPTION;
   ln_party_site_id              NUMBER;
   lc_user_table                 EGO_USER_ATTR_ROW_TABLE  := EGO_USER_ATTR_ROW_TABLE();
   lc_temp_user_table            EGO_USER_ATTR_ROW_TABLE  := EGO_USER_ATTR_ROW_TABLE();
   lc_row_temp_obj               EGO_USER_ATTR_ROW_OBJ    := EGO_USER_ATTR_ROW_OBJ(null,null,null,null,null,null,null,null,null);
   lc_data_table                 EGO_USER_ATTR_DATA_TABLE := EGO_USER_ATTR_DATA_TABLE();
   lc_temp_data_table            EGO_USER_ATTR_DATA_TABLE := EGO_USER_ATTR_DATA_TABLE();
   lc_data_temp_obj              EGO_USER_ATTR_DATA_OBJ   := EGO_USER_ATTR_DATA_OBJ(null,null,null,null,null,null,null,null);
   ln_retcode                    NUMBER;
   ln_errbuf                     VARCHAR2(2000);
   lc_rowid                      VARCHAR2(100);
   l_failed_row_id_list          VARCHAR2(1000);
   l_return_status               VARCHAR2(1000);
   l_errorcode                   NUMBER;
   l_msg_count                   NUMBER;
   l_msg_data                    VARCHAR2(1000);
   lv_return_msg                 VARCHAR2(1000);
   l_errors_tbl                  ERROR_HANDLER.Error_Tbl_Type;
   ln_msg_text                   VARCHAR2(32000);
   l_site_demo_rec               SITE_DEMOGRAPHICS_REC;
BEGIN
     ln_party_site_id := p_party_site_id;
     IF ln_party_site_id IS NULL THEN
        x_return_msg := 'Party Site Id is not Provided';
        RAISE le_exception;
     END IF;
     l_site_demo_rec := p_site_demo_rec;
     Build_ext_table_site_demo
        (  p_user_row_table        => lc_user_table,
           p_user_data_table       => lc_data_table,
           p_ext_attribs_row       => l_site_demo_rec,
           x_return_msg            => lv_return_msg
        );
     IF lv_return_msg IS NOT NULL THEN
        x_return_msg := lv_return_msg;
        fnd_file.PUT_LINE(fnd_file.LOG,' Error in Building ext attr for Site demo:' || x_return_msg);
        RAISE le_exception;
     END IF;
     HZ_EXTENSIBILITY_PUB.process_partysite_record
        (  p_api_version           => xx_cdh_cust_exten_attri_pkg.g_api_version,
           p_party_site_id         => ln_party_site_id,
           p_attributes_row_table  => lc_user_table,
           p_attributes_data_table => lc_data_table,
           x_failed_row_id_list    => l_failed_row_id_list,
           x_return_status         => l_return_status,
           x_errorcode             => l_errorcode,
           x_msg_count             => l_msg_count,
           x_msg_data              => l_msg_data
        );
     IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
        x_return_msg := NULL;
        COMMIT;
     ELSE
        IF l_msg_count > 0 THEN
           ERROR_HANDLER.Get_Message_List(l_errors_tbl);
           FOR i IN 1..l_errors_tbl.COUNT
           LOOP
              ln_msg_text := ln_msg_text||' '||l_errors_tbl(i).message_text;
           END LOOP;
           x_return_msg := ln_msg_text;
         END IF;
      END IF;
EXCEPTION
   WHEN le_exception THEN
      NULL;
      fnd_file.PUT_LINE(fnd_file.LOG,'Error in Process site demo'|| x_return_msg);
   WHEN OTHERS THEN
      x_return_msg := 'Unexpected Error in Process Site demo - '||SQLERRM;
      fnd_file.PUT_LINE(fnd_file.LOG, x_return_msg);
END PROCESS_SITE_DEMOGRAPHICS;

-- +===================================================================+
-- | Name        :  Build_ext_table_site_contact                       |
-- | Description :  This procedure is used to construct the table      |
-- |                Structure used by the extensiable api's.           |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |              p_user_row_table is table structure contains the     |
-- |              Attribute group information                          |
-- |              p_user_data_table is table structure contains the    |
-- |              attribute columns informations                       |
-- |              p_ext_attribs_row is staging table row information   |
-- |              which needs to be create/updated to extensible attrs |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Build_ext_table_site_contact
      (    p_user_row_table  IN OUT EGO_USER_ATTR_ROW_TABLE
          ,p_user_data_table IN OUT EGO_USER_ATTR_DATA_TABLE
          ,p_ext_attribs_row IN OUT SITE_CONTACTS_REC
          ,x_return_msg         OUT VARCHAR2
      )
IS
--Retrieve Attribute Group id based on the Attribute Group code and
-- Flexfleid Name
        CURSOR c_ego_attr_grp_id ( p_flexfleid_name VARCHAR2, p_context_code VARCHAR2)
        IS
        SELECT attr_group_id
        FROM   ego_fnd_dsc_flx_ctx_ext
        WHERE  descriptive_flexfield_name    = p_flexfleid_name
        AND    descriptive_flex_context_code = p_context_code;
--
       CURSOR c_ext_attr_name( p_flexfleid_name VARCHAR2, p_context_code VARCHAR2)
       IS
       SELECT *
       FROM   fnd_descr_flex_column_usages
       WHERE  descriptive_flexfield_name    = p_flexfleid_name
       AND    descriptive_flex_context_code = p_context_code
       AND    enabled_flag                  = 'Y';

       TYPE l_xxod_ext_attribs_stg IS TABLE OF c_ext_attr_name%ROWTYPE INDEX BY BINARY_INTEGER;
       lx_od_ext_attrib_stg        l_xxod_ext_attribs_stg;
       lc_row_temp_obj             EGO_USER_ATTR_ROW_OBJ := EGO_USER_ATTR_ROW_OBJ(null,null,null,null,null,null,null,null,null);
       lc_data_temp_obj            EGO_USER_ATTR_DATA_OBJ:= EGO_USER_ATTR_DATA_OBJ(null,null,null,null,null,null,null,null);
       lc_count                    NUMBER:=1;
       lc_flexfleid_name            VARCHAR2(50);
       lc_attr_group_id             NUMBER;
       lc_exception                EXCEPTION;
BEGIN
       lc_flexfleid_name := 'HZ_PARTY_SITES_GROUP';
       OPEN  c_ego_attr_grp_id ( lc_flexfleid_name,'SITE_CONTACTS' );
          FETCH c_ego_attr_grp_id INTO lc_attr_group_id;
       CLOSE c_ego_attr_grp_id;

       IF lc_attr_group_id IS NULL THEN
          x_return_msg := 'Attribute Group ''Site Contacts'' is not found';
          RAISE lc_exception;
       END IF;

       OPEN  c_ext_attr_name ( lc_flexfleid_name,'SITE_CONTACTS');
          FETCH c_ext_attr_name BULK COLLECT INTO lx_od_ext_attrib_stg;
       CLOSE c_ext_attr_name;

       p_user_row_table.extend;
       p_user_row_table(1)                  := lc_row_temp_obj;
       p_user_row_table(1).Row_identifier   := P_ext_attribs_row.record_id;
       p_user_row_table(1).Attr_group_id    := lc_attr_group_id;
       p_user_row_table(1).transaction_type := EGO_USER_ATTRS_DATA_PVT.G_SYNC_MODE;

       FOR i IN 1 .. lx_od_ext_attrib_stg.COUNT
       LOOP
           p_user_data_table.extend;
           p_user_data_table(i)                := lc_data_temp_obj;
           p_user_data_table(i).ROW_IDENTIFIER := P_EXT_ATTRIBS_ROW.record_id;
           p_user_data_table(i).ATTR_NAME      := lx_od_ext_attrib_stg(i).END_USER_COLUMN_NAME;
           IF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR1' THEN
              p_user_data_table(i).attr_value_str := p_ext_attribs_row.c_ext_attr1;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR2' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR2;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR3' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR3;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR4' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR4;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR5' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR5;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR6' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR6;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR7' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR7;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR8' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR8;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR9' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR9;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR10' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR10;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR11' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR11;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR12' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR12;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR13' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR13;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR14' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR14;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR15' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR15;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR16' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR16;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR17' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR17;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR18' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR18;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR19' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR19;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR20' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR20;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR1' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR1;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR2' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR2;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR3' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR3;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR4' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR4;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR5' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR5;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR6' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR6;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR7' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR7;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR8' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR8;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR9' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR9;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR10' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR10;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR11' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR11;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR12' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR12;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR13' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR13;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR14' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR14;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR15' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR15;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR16' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR16;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR17' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR17;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR18' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR18;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR19' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR19;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR20' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR20;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR1' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR1;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR2' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR2;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR3' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR3;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR4' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR4;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR5' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR5;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR6' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR6;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR7' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR7;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR8' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR8;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR9' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR9;
           ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR10' THEN
              P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR10;
           END IF;
       END LOOP;
EXCEPTION
   WHEN lc_exception THEN
      NULL;
      x_return_msg := 'Error in Build Extensible Table for site contacts';
      fnd_file.PUT_LINE(fnd_file.LOG, x_return_msg);
   WHEN OTHERS THEN
      x_return_msg := 'Unexpected Error in Build Extensible Table for site contacts'||SQLERRM;
      fnd_file.PUT_LINE(fnd_file.LOG, x_return_msg);
END Build_ext_table_site_contact;

-- +===================================================================+
-- | Name        :  Build_ext_table_site_demo                          |
-- | Description :  This procedure is used to construct the table      |
-- |                Structure used by the extensiable api's.           |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |              p_user_row_table is table structure contains the     |
-- |              Attribute group information                          |
-- |              p_user_data_table is table structure contains the    |
-- |              attribute columns informations                       |
-- |              p_ext_attribs_row is staging table row information   |
-- |              which needs to be create/updated to extensible attrs |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Build_ext_table_site_demo
      (   p_user_row_table  IN OUT EGO_USER_ATTR_ROW_TABLE,
          p_user_data_table IN OUT EGO_USER_ATTR_DATA_TABLE,
          p_ext_attribs_row IN OUT SITE_DEMOGRAPHICS_REC,
          x_return_msg         OUT VARCHAR2
      )
IS
--Retrieve Attribute Group id based on the Attribute Group code and
-- Flexfleid Name
         CURSOR c_ego_attr_grp_id ( p_flexfleid_name VARCHAR2, p_context_code VARCHAR2)
         IS
         SELECT attr_group_id
         FROM   ego_fnd_dsc_flx_ctx_ext
         WHERE  descriptive_flexfield_name    = p_flexfleid_name
         AND    descriptive_flex_context_code = p_context_code;

         CURSOR c_ext_attr_name( p_flexfleid_name VARCHAR2, p_context_code VARCHAR2)
         IS
         SELECT *
         FROM   fnd_descr_flex_column_usages
         WHERE  descriptive_flexfield_name    = p_flexfleid_name
         AND    descriptive_flex_context_code = p_context_code
         AND    enabled_flag                  = 'Y';

         TYPE l_xxod_ext_attribs_stg IS TABLE OF c_ext_attr_name%ROWTYPE INDEX BY BINARY_INTEGER;
         lx_od_ext_attrib_stg        l_xxod_ext_attribs_stg;
         lc_row_temp_obj             EGO_USER_ATTR_ROW_OBJ := EGO_USER_ATTR_ROW_OBJ(null,null,null,null,null,null,null,null,null);
         lc_data_temp_obj            EGO_USER_ATTR_DATA_OBJ:= EGO_USER_ATTR_DATA_OBJ(null,null,null,null,null,null,null,null);
         lc_count                    NUMBER:=1;
         l_flexfleid_name            VARCHAR2(50);
         l_attr_group_id             NUMBER;
         lc_exception                EXCEPTION;
BEGIN
         l_flexfleid_name := 'HZ_PARTY_SITES_GROUP';
         OPEN  c_ego_attr_grp_id ( l_flexfleid_name,'SITE_DEMOGRAPHICS' );
            FETCH c_ego_attr_grp_id INTO l_attr_group_id;
         CLOSE c_ego_attr_grp_id;

         IF l_attr_group_id IS NULL THEN
              x_return_msg := 'Attribute Group ''Site Demographics'' is not found';
              RAISE lc_exception;
         END IF;

         OPEN  c_ext_attr_name ( l_flexfleid_name,'SITE_DEMOGRAPHICS');
            FETCH c_ext_attr_name BULK COLLECT INTO lx_od_ext_attrib_stg;
         CLOSE c_ext_attr_name;

         p_user_row_table.extend;
         p_user_row_table(1)                  := lc_row_temp_obj;
         p_user_row_table(1).Row_identifier   := P_ext_attribs_row.record_id;
         p_user_row_table(1).Attr_group_id    := l_attr_group_id;
         p_user_row_table(1).transaction_type := EGO_USER_ATTRS_DATA_PVT.G_SYNC_MODE;

         FOR i IN 1 .. lx_od_ext_attrib_stg.COUNT
         LOOP
             p_user_data_table.extend;
             p_user_data_table(i)                := lc_data_temp_obj;
             p_user_data_table(i).ROW_IDENTIFIER := P_EXT_ATTRIBS_ROW.record_id;
             p_user_data_table(i).ATTR_NAME      := lx_od_ext_attrib_stg(i).END_USER_COLUMN_NAME;
             IF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR1' THEN
                p_user_data_table(i).attr_value_str := p_ext_attribs_row.c_ext_attr1;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR2' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR2;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR3' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR3;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR4' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR4;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR5' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR5;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR6' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR6;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR7' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR7;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR8' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR8;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR9' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR9;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR10' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR10;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR11' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR11;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR12' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR12;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR13' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR13;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR14' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR14;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR15' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR15;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR16' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR16;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR17' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR17;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR18' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR18;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR19' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR19;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR20' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR20;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR1' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR1;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR2' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR2;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR3' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR3;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR4' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR4;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR5' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR5;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR6' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR6;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR7' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR7;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR8' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR8;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR9' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR9;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR10' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR10;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR11' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR11;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR12' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR12;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR13' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR13;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR14' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR14;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR15' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR15;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR16' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR16;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR17' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR17;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR18' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR18;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR19' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR19;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR20' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR20;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR1' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR1;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR2' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR2;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR3' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR3;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR4' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR4;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR5' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR5;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR6' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR6;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR7' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR7;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR8' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR8;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR9' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR9;
             ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR10' THEN
                P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR10;
             END IF;
         END LOOP;
EXCEPTION
   WHEN lc_exception THEN
      NULL;
       x_return_msg := 'Error in Build Extensible Table for site demo';
       fnd_file.PUT_LINE(fnd_file.LOG, x_return_msg);
   WHEN OTHERS THEN
        x_return_msg := 'Unexpected Error in Build Extensible Table for site deommo'||SQLERRM;
        fnd_file.PUT_LINE(fnd_file.LOG, x_return_msg);
END Build_ext_table_site_demo;

-- +===================================================================+
-- | Name        :  update_mask_email                                  |
-- | Description :  This procedure is used mask email for non prod     |
-- |                 instances                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE update_mask_email
      (   x_errbuf OUT VARCHAR2
        , x_retcode OUT VARCHAR2
        , p_req_id IN VARCHAR2
        , p_mask_email IN VARCHAR2
      )
IS
    lc_default_email VARCHAR2(100);
    lc_req_data VARCHAR2(100);
BEGIN
  --lc_default_email:=FND_PROFILE.value('XX_LDREF_DEF_EMAIL');
  --FND_FILE.PUT_LINE(FND_FILE.LOG,'Default Email Value from Profile :'||lc_default_email);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameter Mask Email :'||p_mask_email);
  BEGIN
      UPDATE xx_sfa_lead_referrals
      SET SALES_REP_EMAIL=p_mask_email  --,lc_default_email)
      WHERE ATTRIBUTE1=p_req_id;
  EXCEPTION
    WHEN OTHERS THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in Updating Sales Rep email with :'||p_mask_email);--||'OR'||lc_default_email);
  END;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Updating Attribute1 with REQUEST ID :'||p_req_id);

EXCEPTION
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in Update Mask Email :'||SQLERRM||'---'||SQLCODE);
END update_mask_email;

-- +===================================================================+
-- | Name        :  lead_ref_email                                     |
-- | Description :  This procedure is used to send email to the        |
-- |                respective sales person about leads assigned       |
-- |                to them                                            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE lead_ref_email
          ( x_errbuf OUT VARCHAR2
          , x_retcode OUT VARCHAR2
          , p_req_id IN VARCHAR2)
IS
     CURSOR lcu_sales_rep
     IS
     SELECT DISTINCT sales_rep_email,
                 lead_count
     FROM
     (   
     SELECT sales_rep_email
           ,COUNT(internid) lead_count
     FROM   xx_sfa_lead_referrals
     WHERE attribute1=p_req_id
     GROUP BY sales_rep_email
     UNION
     SELECT rs.source_email sales_rep_email,
            count(lref.internid) lead_count
     FROM  apps.xx_sfa_lead_referrals lref,
           xxcrm.xxcrm_rep_store_map mp,
           APPS.JTF_RS_RESOURCE_EXTNS_VL rs
     WHERE lref.store_number=mp.store_id
     AND   mp.resource_id = rs.resource_id
     AND   sysdate between mp.start_date_active and  nvl(mp.end_date_active, sysdate+1) /* defect 17529 fix*/
     AND   lref.attribute1=p_req_id
     GROUP BY rs.source_email
     );

     ln_mail_req_id  NUMBER;
     ln_conc_id      NUMBER;
     lc_req_data     VARCHAR2(100);
     ln_request_id   NUMBER;
     lc_def_email    VARCHAR2(1000);
     lc_rep_email    VARCHAR2(1000);
     lc_mail_body    VARCHAR2(4000);
     lc_mail_subj    VARCHAR2(1000);
     lc_mail_txt     VARCHAR2(1000);
BEGIN
      lc_def_email := fnd_profile.value('XX_LDREF_DEF_EMAIL');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Default Email Value from Profile :'||lc_def_email);
      FND_MESSAGE.SET_NAME('XXCRM','XXOD_LDRF_ESUB');
      lc_mail_subj:=FND_MESSAGE.GET;
      FOR lrec_sales_rep IN lcu_sales_rep 
        LOOP
           BEGIN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Sending Leads Information mail to :'||lrec_sales_rep.sales_rep_email);
             lc_rep_email := NVL(lrec_sales_rep.sales_rep_email,lc_def_email);
             --lc_mail_body:='You have been assigned '||lrec_sales_rep.lead_count ||' no. of WEB/STORE Lead(s).Please go in Sales Online and work your new leads';
             FND_MESSAGE.SET_NAME('XXCRM','XXOD_LDRF_ETXT');
             FND_MESSAGE.SET_TOKEN('LEAD_COUNT',lrec_sales_rep.lead_count);
             lc_mail_txt:=FND_MESSAGE.GET;
             ln_mail_req_id := FND_REQUEST.SUBMIT_REQUEST ( application         => 'xxcrm'
                                                           ,program             => 'XXCRMEMAILER'
                                                           ,description         => 'OD: CRM Emailer Program'
                                                           ,start_time          => NULL
                                                           ,sub_request         => FALSE
                                                           ,argument1           => lc_rep_email
                                                           ,argument2           => lc_mail_subj
                                                           ,argument3           => lc_mail_txt
                                                           );
           EXCEPTION
             WHEN OTHERS THEN
               UPDATE xx_sfa_lead_referrals
               SET process_status='ERROR_IN_EMAIL_SENDING'
               WHERE sales_rep_email=lrec_sales_rep.sales_rep_email
               AND attribute1=p_req_id;
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in Sending Email');
           END;
        END LOOP;

      BEGIN
          UPDATE xxcrm.xx_sfa_lead_referrals
          SET    process_status='PROCESSED'
          WHERE  attribute1=p_req_id
          AND    process_status='IN_PROCESS';
      EXCEPTION
      WHEN OTHERS THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in Updating Process Status for req id :'||p_req_id);
      END;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Updating PROCESS STATUS TO PROCESSED after email is Sent');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'for Request id :'||p_req_id);

EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in Lead Send Email :'||SQLERRM||'---'||SQLCODE);
END LEAD_REF_EMAIL;

-- +===================================================================+
-- | Name        :  lead_ref_process_main                              |
-- | Description :  This procedure is main procedure that calls lead   |
-- |                create package , update email pgm , email send pgm |
-- |                                                                   |
-- +===================================================================+

PROCEDURE lead_ref_process_main
          ( x_errbuf OUT VARCHAR2
          , x_retcode OUT VARCHAR2)
IS
     ln_request_id NUMBER;
     lc_alt_email VARCHAR2(100);
BEGIN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'In main Program');
     ln_request_id:=fnd_global.conc_request_id;
     XX_LEAD_CREATE(x_errbuf,x_retcode);
     FND_FILE.PUT_LINE(FND_FILE.LOG,'********************************** Lead Create Program Ends **********************************');
     lc_alt_email := FND_PROFILE.value('XX_LDREF_ALT_EMAIL');

     FND_FILE.PUT_LINE(FND_FILE.LOG,'');
     FND_FILE.PUT_LINE(FND_FILE.LOG,'FND PROFILE value for Alternate email:'||lc_alt_email);

     IF lc_alt_email IS NOT NULL THEN
              UPDATE_MASK_EMAIL(  x_errbuf
                                , x_retcode
                                , ln_request_id
                                , lc_alt_email);
     END IF;
     LEAD_REF_EMAIL(  x_errbuf
                    , x_retcode
                    , ln_request_id);
EXCEPTION
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in Main Lead Referral Program :'||SQLERRM||'---'||SQLCODE);
END lead_ref_process_main;
END XX_SFA_LEAD_REFF_CREATE_PKG;

/
SHOW ERRORS;
