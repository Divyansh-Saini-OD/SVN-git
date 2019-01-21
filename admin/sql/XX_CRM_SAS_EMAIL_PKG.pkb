create or replace
PACKAGE BODY XX_CRM_SAS_EMAIL_PKG 
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CRM_SAS_EMAIL_PKG                                       |
-- | Description : SAS Behavioral EMAIL Campaign                              |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      09-Mar-2010 Indra Varada           Initial Version               |
-- |1.1      15-Jun-2010 Indra Varada          Added filter on CA and Puerto  |
-- |                                           Rico addresses                 |
-- |1.1       18-May-2016   Shubashree R     Removed the schema reference for GSCC compliance QC#37898|
-- +==========================================================================+
AS

PROCEDURE build_order_email (
    p_errbuf               OUT NOCOPY VARCHAR2,
    p_retcode              OUT NOCOPY VARCHAR2,
    p_include_pos_orders   IN  VARCHAR2
  )
AS

CURSOR hvop_file_cur (p_st_date  DATE, p_end_date DATE) IS
SELECT file_name,process_date
FROM xxom.xx_om_sacct_file_history
WHERE process_date BETWEEN TRUNC(p_st_date) AND TRUNC(p_end_date)
ORDER BY process_date asc;

CURSOR pos_trans_cur (p_file VARCHAR2) IS
SELECT  h.orig_sys_document_ref order_number
       ,x.advantage_card_number
       ,x.imp_file_name
       ,h.ordered_date
       ,h.booked_date
  FROM ont.oe_order_headers_all h
     , ont.oe_transaction_types_tl t
     , xxom.xx_om_header_attributes_all x
     , xxom.xx_om_sacct_file_history f
WHERE h.order_type_id = t.transaction_type_id
  AND t.language = USERENV('LANG')
  AND t.name ='SA US POS Standard'
  AND h.header_id = x.header_id
  AND x.imp_file_name = f.file_name
  AND f.file_name = p_file
  AND x.advantage_card_number is NOT NULL;

CURSOR regular_trans_cur (p_file VARCHAR2) IS
SELECT LPAD(SUBSTR(h.orig_sys_document_ref,0,9),24,0) order_number
      ,substr(ac.orig_system_reference,0,8) account_id
      ,LTRIM(c.orig_system_reference,0) contact_id
      ,p.email_address
      ,x.imp_file_name
      ,ac.attribute18 customer_type
      ,h.ordered_date
      ,h.booked_date
      ,x.advantage_card_number
      ,h.ship_to_org_id
  FROM ont.oe_order_headers_all h
     , ont.oe_transaction_types_tl t
     , hz_cust_account_roles c
     , hz_cust_accounts ac
     , hz_contact_points p
     , xxom.xx_om_header_attributes_all x
     , xxom.xx_om_sacct_file_history f
WHERE h.order_type_id = t.transaction_type_id
  AND t.language = USERENV('LANG')
  AND t.name ='SA US Standard'
  AND h.sold_to_contact_id = c.cust_account_role_id
  AND c.party_id = p.owner_table_id
  AND p.owner_table_name = 'HZ_PARTIES'
  AND p.contact_point_type = 'EMAIL'
  AND c.cust_account_id = ac.cust_account_id
  AND h.header_id = x.header_id
  AND x.imp_file_name = f.file_name
  AND f.file_name = p_file
  AND p.email_address IS NOT NULL;

l_st_date         DATE;
l_en_date         DATE;
l_st_char         VARCHAR2(30);
l_en_char         VARCHAR2(30);
l_commit_int      NUMBER := 200;
l_total           NUMBER := 0;
l_exists          NUMBER := 0;
l_pos_status      VARCHAR2(10);
l_reg_status      VARCHAR2(10);
l_pos_process     BOOLEAN := FALSE;
l_reg_process     BOOLEAN := FALSE;
l_dt_quer         VARCHAR2(1000);
l_country         VARCHAR2(20);
l_st_prov         VARCHAR2(20); 
BEGIN

   l_st_char                 := NVL(fnd_profile.value('XX_CRM_SAS_EMAIL_START_DATE'),'SYSDATE-1');
   l_en_char                 := NVL(fnd_profile.value('XX_CRM_SAS_EMAIL_END_DATE'),'SYSDATE');
   

   l_dt_quer := 'SELECT ' || l_st_char ||',' || l_en_char || ' FROM DUAL';
   EXECUTE IMMEDIATE l_dt_quer INTO l_st_date,l_en_date;
   
   fnd_file.put_line(fnd_file.log,'Start Date:' || l_st_date);
   fnd_file.put_line(fnd_file.log,'End Date:' || l_en_date);

FOR l_files in hvop_file_cur (l_st_date, l_en_date) LOOP

      l_pos_status   := 'C';
      l_reg_status   := 'C';
      l_pos_process  := FALSE; 
      l_reg_process  := FALSE;           

      BEGIN 

       SELECT pos_status,regular_status INTO l_pos_status,l_reg_status
       FROM XXSAS_PROCESSED_FILES
       WHERE file_name = l_files.file_name;

       IF l_pos_status <> 'C' THEN

          UPDATE xxsas_processed_files
          SET last_update_date = SYSDATE,pos_status = 'P'
          WHERE file_name = l_files.file_name;
          COMMIT;
          l_pos_process := true;
          
       END IF;

       IF l_reg_status <> 'C' THEN

          UPDATE xxsas_processed_files
          SET last_update_date = SYSDATE,regular_status = 'P'
          WHERE file_name = l_files.file_name;
          COMMIT;
          l_reg_process := true;
          
       END IF;
       

      
      EXCEPTION WHEN NO_DATA_FOUND THEN
  
       INSERT INTO XXSAS_PROCESSED_FILES
       (
         FILE_NAME,
         HVOP_PROCESS_DATE,
         CREATION_DATE,
         POS_STATUS,
         REGULAR_STATUS,
         LAST_UPDATE_DATE
       )
       VALUES
       (
         l_files.file_name,
         l_files.process_date,
         SYSDATE,
         'P',
         'P',
         SYSDATE
       );

       COMMIT;

       l_pos_process := true;
       l_reg_process := true;
      END;

-- Override POS processing is user does not want to process the POS orders

IF p_include_pos_orders <> 'Y' THEN
   l_pos_process := false;
END IF;

 IF l_pos_process THEN                             

 -- Populate POS Transactions

  BEGIN

   FOR l_pos IN pos_trans_cur (l_files.file_name) LOOP

      
       l_exists := 0;
 
       SELECT count(1) INTO l_exists
       FROM xxsas_email_campaign
       WHERE order_id = l_pos.order_number;

       IF l_exists = 0 THEN
        INSERT INTO xxsas_email_campaign
        (
               ORDER_ID
	      ,WLR_ID
	      ,EMAIL_ADDRESS
	      ,AOPS_ACCOUNT_ID
	      ,AOPS_CONTACT_ID
	      ,ACCOUNT_TYPE
	      ,HVOP_ORDER_FILE
              ,CREATION_DATE
              ,LAST_UPDATE_DATE
              ,CREATED_BY_MODULE
              ,ORDERED_DATE
              ,BOOKED_DATE
        )
        VALUES
        (
         l_pos.order_number
        ,l_pos.advantage_card_number
        ,null
        ,null
        ,null
       ,'RETAIL'
       ,l_pos.imp_file_name
       ,SYSDATE
       ,SYSDATE
       ,'SAS_PROG'
       ,l_pos.ordered_date
       ,l_pos.booked_date
        );

        l_total := l_total + SQL%ROWCOUNT;

       END IF;
        
         IF mod(l_total,l_commit_int) = 0 THEN
            COMMIT;
         END IF;

      END LOOP;

      l_total := 0;

     UPDATE xxsas_processed_files
     SET last_update_date = SYSDATE,pos_status = 'C'
     WHERE file_name = l_files.file_name;
     
     COMMIT;     

   EXCEPTION WHEN OTHERS THEN
     
     UPDATE xxsas_processed_files
     SET last_update_date = SYSDATE,pos_status = 'E'
     WHERE file_name = l_files.file_name;
     
     COMMIT;  

   END ;
       
END IF;


IF l_reg_process THEN 

   BEGIN

-- Populate Regular Transactions

    FOR l_reg IN regular_trans_cur (l_files.file_name) LOOP

         l_exists := 0;

       SELECT count(1) INTO l_exists
       FROM xxsas_email_campaign
       WHERE order_id = l_reg.order_number;
       
       l_country := NULL;
       l_st_prov := NULL;
       
       BEGIN
         
         select lo.country,
                CASE WHEN lo.state IS NOT NULL THEN lo.state
                     ELSE lo.province
                END
         INTO l_country,l_st_prov
         from hz_cust_site_uses_all su,
              hz_cust_acct_sites_all si,
              hz_party_sites ps,
              hz_locations lo
         where site_use_id = l_reg.ship_to_org_id
         and su.cust_acct_site_id = si.cust_acct_site_id
         and si.party_site_id = ps.party_site_id
         and ps.location_id = lo.location_id
         and lo.country = 'US' and NVL(lo.state,'XX') <> 'PR'
         and ROWNUM = 1;

       IF l_exists = 0 THEN
          INSERT INTO xxsas_email_campaign
           (
               ORDER_ID
              ,WLR_ID
              ,EMAIL_ADDRESS
              ,AOPS_ACCOUNT_ID
              ,AOPS_CONTACT_ID
              ,ACCOUNT_TYPE
              ,HVOP_ORDER_FILE
              ,CREATION_DATE
              ,LAST_UPDATE_DATE
              ,CREATED_BY_MODULE
              ,ORDERED_DATE
              ,BOOKED_DATE
              ,COUNTRY
              ,STATE_PROVINCE
           )
           VALUES
           (
               l_reg.order_number
              ,l_reg.advantage_card_number
              ,l_reg.email_address
              ,l_reg.account_id
              ,l_reg.contact_id
              ,l_reg.customer_type
              ,l_reg.imp_file_name
              ,SYSDATE
              ,SYSDATE
              ,'SAS_PROG'
              ,l_reg.ordered_date
              ,l_reg.booked_date
              ,l_country
              ,l_st_prov
            );

            l_total := l_total + SQL%ROWCOUNT;

         END IF;
         
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;
        
         IF mod(l_total,l_commit_int) = 0 THEN
            COMMIT;
         END IF;

      END LOOP;

      l_total := 0;

     UPDATE xxsas_processed_files
     SET last_update_date = SYSDATE,regular_status = 'C'
     WHERE file_name = l_files.file_name;

      COMMIT;  



    EXCEPTION WHEN OTHERS THEN
     
     UPDATE xxsas_processed_files
     SET last_update_date = SYSDATE,regular_status = 'E'
     WHERE file_name = l_files.file_name;

    END ;
       
 END IF;
 
END LOOP;

EXCEPTION WHEN OTHERS THEN
fnd_file.put_line(fnd_file.log, 'Unexpected Exception In build_order_email:' || SQLERRM);
p_retcode := 2; 
END build_order_email;

PROCEDURE purge_order_email (
    p_errbuf               OUT NOCOPY VARCHAR2,
    p_retcode              OUT NOCOPY VARCHAR2
  )
AS

l_purge_days            NUMBER;
l_del_quer1              VARCHAR2(1000);
l_del_quer2              VARCHAR2(1000);

BEGIN

l_purge_days                 := NVL(fnd_profile.value('XX_SAS_EMAIL_TABLE_PURGE'),7);
l_del_quer1    := 'DELETE FROM XXSAS_EMAIL_CAMPAIGN WHERE CREATION_DATE < TRUNC(SYSDATE-' || l_purge_days || ')';
l_del_quer2    := 'DELETE FROM XXSAS_PROCESSED_FILES WHERE CREATION_DATE < TRUNC(SYSDATE-' || l_purge_days || ')';

fnd_file.put_line(fnd_file.log,'Execution SQL:' || l_del_quer1);
EXECUTE IMMEDIATE l_del_quer1;
fnd_file.put_line(fnd_file.log,'Total Records Deleted in XXSAS_EMAIL_CAMPAIGN:' || SQL%ROWCOUNT);
fnd_file.put_line(fnd_file.log,'Execution SQL:' || l_del_quer2);
EXECUTE IMMEDIATE l_del_quer2;
fnd_file.put_line(fnd_file.log,'Total Records Deleted in XXSAS_PROCESSED_FILES:' || SQL%ROWCOUNT);

COMMIT;

EXCEPTION WHEN OTHERS THEN
fnd_file.put_line(fnd_file.log, 'Unexpected Exception In purge_order_email:' || SQLERRM);
p_retcode := 2;
END purge_order_email;

END XX_CRM_SAS_EMAIL_PKG;
/
