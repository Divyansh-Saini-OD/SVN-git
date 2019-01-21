
CREATE OR REPLACE PACKAGE BODY XX_LEAD_ADDR_DATA_FIX_PKG
AS

PROCEDURE XX_LEAD_ADDR_DATA_FIX_PROC (   x_errbuf  OUT VARCHAR2
                                        ,x_retcode OUT NUMBER
                                        ,p_commit_flag IN VARCHAR2
                                        ,p_process_status IN VARCHAR2)
AS
CURSOR lcu_address_update (p_process_status IN VARCHAR2)
IS
SELECT ASL.lead_number,
       ASL.sales_lead_id,
       HP.party_id,
       HP.party_name,
       HP.orig_system_reference, 
       HPS.party_site_id,
       ASL.address_id, 
       --LEAD.internid,
       ASL.last_update_date
FROM   apps.hz_parties HP,  
       apps.xx_sfa_lead_referrals LEAD, 
       apps.as_sales_leads ASL, 
       apps.hz_party_sites HPS 
WHERE  (HP.party_name = LEAD.name OR HP.party_name = trim(LEAD.name))
AND    HP.attribute13='PROSPECT' 
AND    HP.creation_date > TO_DATE('12-FEB-2011') 
--AND    LEAD.existing_cust_flag='N'  
AND    LEAD.process_status = p_process_status
AND    LEAD.creation_date > TO_DATE('12-FEB-2011') 
AND    ASL.customer_id=HP.party_id 
AND    HPS.party_id=HP.party_id 
AND    ASL.address_id <> HPS.party_site_id 
AND    TRUNC(ASL.creation_date) = TRUNC(HP.creation_date)
AND    HP.created_by_module = 'LEAD REFERRAL'
AND    ASL.source_system = 'LEAD REFERRAL'
AND    HPS.created_by_module =  'LEAD REFERRAL'
UNION
SELECT ASL.lead_number,         -- Union to process lead 2132049
       ASL.sales_lead_id,
       HP.party_id,
       HP.party_name,
       HP.orig_system_reference, 
       HPS.party_site_id,
       ASL.address_id, 
       ASL.last_update_date
FROM apps.hz_party_sites HPS
   , apps.hz_parties HP 
   , apps.as_sales_leads ASL
WHERE HPS.party_id = HP.party_id
AND HP.party_id = ASL.customer_id
AND HPS.party_site_id <> ASL.address_id
AND TRUNC(asl.creation_date) > TO_DATE('12-FEB-2011')
AND ASL.sales_lead_id = 2132049;


--lrec_address_update lcu_address_update%rowtype;
lt_sales_lead_profile_tbl          APPS.AS_UTILITY_PUB.PROFILE_TBL_TYPE;
lr_sales_lead_rec                  APPS.AS_SALES_LEADS_PUB.SALES_LEAD_REC_TYPE;
lc_return_status                   VARCHAR2(20);
ln_msg_count                       NUMBER;
lc_msg_data                        VARCHAR2(2000);
ln_api_version                     PLS_INTEGER := 1.0;
lc_message                         VARCHAR2(2000);
ln_named_acct_terr_id              PLS_INTEGER;
ld_start_date_active               DATE;

 BEGIN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Lead Number'||'|'|| 'Wrong Address ID ' ||'|'||'Correct Address ID ');
    FOR lrec_address_update IN lcu_address_update(p_process_status) 
    LOOP
        ln_named_acct_terr_id := NULL;
        ld_start_date_active  := NULL;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lrec_address_update.sales_lead_id ||'|'||lrec_address_update.address_id ||'|'||lrec_address_update.party_site_id);

        lr_sales_lead_rec.sales_lead_id    := lrec_address_update.sales_lead_id;
        lr_sales_lead_rec.last_update_date := lrec_address_update.last_update_date;
        lr_sales_lead_rec.address_id       := lrec_address_update.party_site_id;

        IF NVL(p_commit_flag,'N') = 'Y' THEN

           AS_SALES_LEADS_PUB.UPDATE_SALES_LEAD(
                          P_Api_Version_Number        => 2.0,
                          P_Init_Msg_List             => 'T',
                          P_Commit                    => 'T',
                          P_Validation_Level          => NULL,
                          P_Check_Access_Flag         => NULL,
                          P_Admin_Flag                => NULL,
                          P_Admin_Group_Id            => NULL,
                          P_identity_salesforce_id    => NULL,
                          P_Sales_Lead_Profile_Tbl    => lt_sales_lead_profile_tbl,
                          P_SALES_LEAD_Rec            => lr_sales_lead_rec,
                          x_return_status             => lc_return_status,
                          x_msg_count                 => ln_msg_count,
                          x_msg_data                  => lc_msg_data);
        
        
            FND_FILE.PUT_LINE(FND_FILE.LOG,SubStr('lc_return_status = '||lc_return_status,1,255)||chr(13));
            IF lc_return_status <> 'S' THEN
               FOR I IN 1..ln_msg_count
               LOOP
                  lc_msg_data := lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
               END LOOP;
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Error msg in Update sales Lead: '||lc_msg_data);
            END IF;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Updated to correct Address_id '||lrec_address_update.party_site_id);

        END IF; --p_commit_flag
        
    END LOOP;

 END XX_LEAD_ADDR_DATA_FIX_PROC;
END XX_LEAD_ADDR_DATA_FIX_PKG;

/
SHOW ERRORS;
