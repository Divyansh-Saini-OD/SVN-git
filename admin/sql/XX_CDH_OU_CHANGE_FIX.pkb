SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace
PACKAGE BODY XX_CDH_OU_CHANGE_FIX 
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CDH_OU_CHANGE_FIX                                       |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Code to Correct Existing DIRECT CUSTOMER OU Data           |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      20-Oct-2008 Indra Varada           Initial Version               |
-- |                                                                          |
-- +==========================================================================+
AS
------- This code has to be Run 4 times in the below Order -----------
-- 1. US Resp - p_process_billto_dup = 'N' --
-- 2. CA Resp - p_process_billto_dup = 'N' --
-- 3. US Resp - p_process_billto_dup = 'Y' --
-- 4. CA Resp - p_process_billto_dup = 'Y' --
----------------------------------------------------------------------
PROCEDURE ou_fix_main (
                  x_errbuf              OUT NOCOPY VARCHAR2,
                  x_retcode             OUT NOCOPY VARCHAR2,
                  p_process_billto_dup  IN VARCHAR2,
                  p_commit              IN VARCHAR2
                 ) AS
                 
-- Cursor to Fetch all the account sites for the the 'DIRECT' Customers
                 
CURSOR ou_change_cur
IS
SELECT 
  DECODE(loc.country,'CA',403,404) loc_org_id,
  asi.*
FROM HZ_CUST_ACCT_SITES_ALL asi,HZ_PARTY_SITES psi, HZ_LOCATIONS loc,HZ_ORIG_SYS_REFERENCES osr
WHERE asi.party_site_id = psi.party_site_id
AND psi.location_id = loc.location_id
AND osr.owner_table_id = asi.cust_acct_site_id
AND osr.owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
AND osr.orig_system_reference = asi.orig_system_reference
AND osr.orig_system = 'A0'
AND osr.status = 'A'
--AND asi.org_id != NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1,1),' ',NULL,SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99)
AND EXISTS (SELECT 1 FROM
             HZ_CUST_ACCOUNTS
             WHERE cust_account_id = asi.cust_account_id
             AND attribute18 = 'DIRECT');

-- Cursor to Append 'CA' to All the BILL_TO Sites/uses For 'DIRECT' Customers             

CURSOR upd_ca_osr
IS
SELECT asi.*
FROM hz_cust_acct_sites_all asi
WHERE orig_system_reference like '%-00001-%'
AND org_id = 403
AND EXISTS (SELECT 1 FROM
             HZ_CUST_ACCOUNTS
             WHERE cust_account_id = asi.cust_account_id
             AND attribute18 = 'DIRECT');


/*CURSOR lc_fetch_cust_acct_sites_cur ( p_cust_site_id IN VARCHAR2)
IS
SELECT *
FROM HZ_CUST_ACCT_SITES_aLL
WHERE cust_acct_site_id = p_cust_site_id;*/

-- Cursor To Duplicate BILL_TO sites if all SHIP_TOs are not in the same OU as the BILL_TO

CURSOR billto_dup_cur
IS
SELECT asi.*
FROM HZ_CUST_ACCT_SITES_ALL asi
WHERE REGEXP_LIKE(asi.orig_system_reference,'-00001-')
AND asi.org_id <> NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1,1),' ',NULL,SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99)
AND asi.status = 'A'
AND ((asi.org_id = 404 AND EXISTS ( SELECT 1 
             FROM hz_cust_acct_sites_all asi2
             WHERE asi2.cust_account_id = asi.cust_account_id
             AND asi.org_id <> asi2.org_id
             AND asi2.status = 'A'
             AND asi2.orig_system_reference NOT LIKE '%-00001-%')) OR asi.org_id = 403)
AND EXISTS (SELECT 1
            FROM hz_cust_accounts
            WHERE attribute18 = 'DIRECT'
            AND cust_account_id = asi.cust_account_id
            );

-- Cursor to Fetch All Site Use Records For a Cust Account Site

CURSOR lc_fetch_acct_site_uses_cur ( p_in_cust_acct_site_id IN NUMBER)
IS
SELECT hcsu.*
FROM   hz_cust_site_uses_all      hcsu
WHERE  hcsu.cust_acct_site_id     = p_in_cust_acct_site_id;


lr_cust_acct_site_rec             HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
lr_def_cust_acct_site_rec         HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
lv_return_status                  VARCHAR2(10);
ln_msg_count                      NUMBER;
lv_msg_data                       VARCHAR2(2000);
l_transaction_error               BOOLEAN := FALSE;
ln_cust_acct_site_id              NUMBER;
ln_cust_site_use_id               NUMBER;

lr_cust_site_use_rec              HZ_CUST_ACCOUNT_SITE_V2PUB.cust_site_use_rec_type;
lr_def_cust_site_use_rec          HZ_CUST_ACCOUNT_SITE_V2PUB.cust_site_use_rec_type;

lr_orig_sys_reference_rec         HZ_ORIG_SYSTEM_REF_PUB.orig_sys_reference_rec_type;
lr_def_orig_sys_reference_rec     HZ_ORIG_SYSTEM_REF_PUB.orig_sys_reference_rec_type;
l_operation                       VARCHAR2(10);
l_use_osr_value                   VARCHAR2(100);
l_site_osr_value                  VARCHAR2(100);
l_orig_sys_ref_id                 NUMBER;
l_osr                             NUMBER;
l_tot_records_process             NUMBER := 0;
  
BEGIN

IF p_process_billto_dup = 'N' THEN

 FOR l_ou_change_cur IN ou_change_cur LOOP
 
  -- If the COUNTRY and the current OU for an account site/uses is different then Inactivate the existing site
  --  and site uses and convert it into the correct OU.

  IF l_ou_change_cur.loc_org_id != l_ou_change_cur.org_id AND l_ou_change_cur.loc_org_id = NVL(TO_NUMBER(SUBSTRB(USERENV('CLIENT_INFO'),1,10)),-99) THEN
      
       l_transaction_error := FALSE;
       SAVEPOINT ou_change_savepoint;  
     BEGIN
        
          SELECT cust_acct_site_id,orig_system_reference INTO  ln_cust_acct_site_id,l_site_osr_value
          FROM hz_cust_acct_sites_all
          WHERE cust_account_id =  l_ou_change_cur.cust_account_id 
          AND party_site_id     =  l_ou_change_cur.party_site_id
          AND org_id            =  NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1,1),' ',NULL,SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99);
          
          ---------------------------------------
          -- Reactivate Inactive Account Site
          ---------------------------------------
       
          UPDATE hz_cust_acct_sites_all
          SET    status = l_ou_change_cur.status,
                 last_update_date = SYSDATE,
                 orig_system_reference = RTRIM(orig_system_reference,'CA')
          WHERE  cust_acct_site_id = ln_cust_acct_site_id;    
          
          UPDATE hz_orig_sys_references
          SET    status = 'A',
                 last_update_date = SYSDATE,
                 end_date_active = NULL,
                 orig_system_reference = RTRIM(orig_system_reference,'CA')
          WHERE  orig_system_reference = l_site_osr_value
            AND  orig_system  = 'A0'
            AND  owner_table_id = ln_cust_acct_site_id
            AND  owner_table_name = 'HZ_CUST_ACCT_SITES_ALL';
        
          
      EXCEPTION WHEN NO_DATA_FOUND THEN    

         
      ---------------------------------------
      -- API Call to Create account site
      ---------------------------------------
      
      lr_cust_acct_site_rec                            := lr_def_cust_acct_site_rec;

      --lr_cust_acct_site_rec.cust_acct_site_id          :=
      lr_cust_acct_site_rec.cust_account_id            := l_ou_change_cur.cust_account_id           ;
      lr_cust_acct_site_rec.party_site_id              := l_ou_change_cur.party_site_id             ;
      lr_cust_acct_site_rec.attribute_category         := l_ou_change_cur.attribute_category        ;
      lr_cust_acct_site_rec.attribute1                 := l_ou_change_cur.attribute1                ;
      lr_cust_acct_site_rec.attribute2                 := l_ou_change_cur.attribute2                ;
      lr_cust_acct_site_rec.attribute3                 := l_ou_change_cur.attribute3                ;
      lr_cust_acct_site_rec.attribute4                 := l_ou_change_cur.attribute4                ;
      lr_cust_acct_site_rec.attribute5                 := l_ou_change_cur.attribute5                ;
      lr_cust_acct_site_rec.attribute6                 := l_ou_change_cur.attribute6                ;
      lr_cust_acct_site_rec.attribute7                 := l_ou_change_cur.attribute7                ;
      lr_cust_acct_site_rec.attribute8                 := l_ou_change_cur.attribute8                ;
      lr_cust_acct_site_rec.attribute9                 := l_ou_change_cur.attribute9                ;
      lr_cust_acct_site_rec.attribute10                := l_ou_change_cur.attribute10               ;
      lr_cust_acct_site_rec.attribute11                := l_ou_change_cur.attribute11               ;
      lr_cust_acct_site_rec.attribute12                := l_ou_change_cur.attribute12               ;
      lr_cust_acct_site_rec.attribute13                := l_ou_change_cur.attribute13               ;
      lr_cust_acct_site_rec.attribute14                := l_ou_change_cur.attribute14               ;
      lr_cust_acct_site_rec.attribute15                := l_ou_change_cur.attribute15               ;
      lr_cust_acct_site_rec.attribute16                := l_ou_change_cur.attribute16               ;
      lr_cust_acct_site_rec.attribute17                := l_ou_change_cur.attribute17               ;
      lr_cust_acct_site_rec.attribute18                := l_ou_change_cur.attribute18               ;
      lr_cust_acct_site_rec.attribute19                := l_ou_change_cur.attribute19               ;
      lr_cust_acct_site_rec.attribute20                := l_ou_change_cur.attribute20               ;
      lr_cust_acct_site_rec.global_attribute_category  := l_ou_change_cur.global_attribute_category ;
      lr_cust_acct_site_rec.global_attribute1          := l_ou_change_cur.global_attribute1         ;
      lr_cust_acct_site_rec.global_attribute2          := l_ou_change_cur.global_attribute2         ;
      lr_cust_acct_site_rec.global_attribute3          := l_ou_change_cur.global_attribute3         ;
      lr_cust_acct_site_rec.global_attribute4          := l_ou_change_cur.global_attribute4         ;
      lr_cust_acct_site_rec.global_attribute5          := l_ou_change_cur.global_attribute5         ;
      lr_cust_acct_site_rec.global_attribute6          := l_ou_change_cur.global_attribute6         ;
      lr_cust_acct_site_rec.global_attribute7          := l_ou_change_cur.global_attribute7         ;
      lr_cust_acct_site_rec.global_attribute8          := l_ou_change_cur.global_attribute8         ;
      lr_cust_acct_site_rec.global_attribute9          := l_ou_change_cur.global_attribute9         ;
      lr_cust_acct_site_rec.global_attribute10         := l_ou_change_cur.global_attribute10        ;
      lr_cust_acct_site_rec.global_attribute11         := l_ou_change_cur.global_attribute11        ;
      lr_cust_acct_site_rec.global_attribute12         := l_ou_change_cur.global_attribute12        ;
      lr_cust_acct_site_rec.global_attribute13         := l_ou_change_cur.global_attribute13        ;
      lr_cust_acct_site_rec.global_attribute14         := l_ou_change_cur.global_attribute14        ;
      lr_cust_acct_site_rec.global_attribute15         := l_ou_change_cur.global_attribute15        ;
      lr_cust_acct_site_rec.global_attribute16         := l_ou_change_cur.global_attribute16        ;
      lr_cust_acct_site_rec.global_attribute17         := l_ou_change_cur.global_attribute17        ;
      lr_cust_acct_site_rec.global_attribute18         := l_ou_change_cur.global_attribute18        ;
      lr_cust_acct_site_rec.global_attribute19         := l_ou_change_cur.global_attribute19        ;
      lr_cust_acct_site_rec.global_attribute20         := l_ou_change_cur.global_attribute20        ;
      lr_cust_acct_site_rec.orig_system_reference      := RTRIM(l_ou_change_cur.orig_system_reference,'CA');
      lr_cust_acct_site_rec.orig_system                := 'A0'                                              ;
      lr_cust_acct_site_rec.status                     := l_ou_change_cur.status                                              ;
      lr_cust_acct_site_rec.customer_category_code     := l_ou_change_cur.customer_category_code    ;
      lr_cust_acct_site_rec.language                   := l_ou_change_cur.language                  ;
      lr_cust_acct_site_rec.key_account_flag           := l_ou_change_cur.key_account_flag          ;
      lr_cust_acct_site_rec.tp_header_id               := l_ou_change_cur.tp_header_id              ;
      lr_cust_acct_site_rec.ece_tp_location_code       := l_ou_change_cur.ece_tp_location_code      ;
      lr_cust_acct_site_rec.primary_specialist_id      := l_ou_change_cur.primary_specialist_id     ;
      lr_cust_acct_site_rec.secondary_specialist_id    := l_ou_change_cur.secondary_specialist_id   ;
      lr_cust_acct_site_rec.territory_id               := l_ou_change_cur.territory_id              ;
      lr_cust_acct_site_rec.territory                  := l_ou_change_cur.territory                 ;
      lr_cust_acct_site_rec.translated_customer_name   := l_ou_change_cur.translated_customer_name  ;
      lr_cust_acct_site_rec.created_by_module          := 'XXCONV'                                          ;
      lr_cust_acct_site_rec.application_id             := l_ou_change_cur.application_id            ;

      fnd_file.put_line(fnd_file.log, 'Create Account Site :'||l_ou_change_cur.orig_system_reference);
          
      HZ_CUST_ACCOUNT_SITE_V2PUB.create_cust_acct_site
         (   p_init_msg_list              => FND_API.G_TRUE,
             p_cust_acct_site_rec         => lr_cust_acct_site_rec,
             x_cust_acct_site_id          => ln_cust_acct_site_id,
             x_return_status              => lv_return_status,
             x_msg_count                  => ln_msg_count,
             x_msg_data                   => lv_msg_data
         );
         
      IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN
         l_transaction_error := TRUE;
         fnd_file.put_line(fnd_file.log, 'Error During Account Site Creation:' || lv_msg_data);
      END IF;
         
     END;
      
         FOR lc_fetch_acct_site_uses_rec IN lc_fetch_acct_site_uses_cur (l_ou_change_cur.cust_acct_site_id)
         LOOP            
            
          BEGIN
        
            SELECT site_use_id,orig_system_reference INTO  ln_cust_site_use_id,l_use_osr_value
            FROM hz_cust_site_uses_all
            WHERE cust_acct_site_id =  ln_cust_acct_site_id 
            AND site_use_code       =  lc_fetch_acct_site_uses_rec.site_use_code
            AND org_id              =  NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1,1),' ',NULL,SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99);
            
             ------------------------------------------
              -- Reactivate Inactive Account Site Use
             ------------------------------------------
          
            UPDATE hz_cust_site_uses_all
            SET    status = lc_fetch_acct_site_uses_rec.status,
                   primary_flag = lc_fetch_acct_site_uses_rec.primary_flag,
                   last_update_date = SYSDATE,
                   orig_system_reference = RTRIM(l_site_osr_value,'CA') || '-' || site_use_code
            WHERE  site_use_id = ln_cust_site_use_id;  
            
            UPDATE hz_orig_sys_references
            SET    status = 'A',
                   last_update_date = SYSDATE,
                   end_date_active = NULL,
                   orig_system_reference = RTRIM(l_site_osr_value,'CA') || '-' || lc_fetch_acct_site_uses_rec.site_use_code
            WHERE  orig_system_reference = l_use_osr_value
            AND    orig_system  = 'A0'
            AND    owner_table_id = ln_cust_site_use_id
            AND    owner_table_name = 'HZ_CUST_SITE_USES_ALL';
         

          EXCEPTION WHEN NO_DATA_FOUND THEN
          
             ---------------------------------------
              -- API Call to Create account site Uses
             ---------------------------------------
            
            lr_cust_site_use_rec                                 := lr_def_cust_site_use_rec;

            --lr_cust_site_use_rec.site_use_id                     :=
            lr_cust_site_use_rec.cust_acct_site_id               := ln_cust_acct_site_id                                         ;
            lr_cust_site_use_rec.site_use_code                   := lc_fetch_acct_site_uses_rec.site_use_code                    ;
            lr_cust_site_use_rec.primary_flag                    := lc_fetch_acct_site_uses_rec.primary_flag                     ;
            lr_cust_site_use_rec.status                          := lc_fetch_acct_site_uses_rec.status                                                          ;
            lr_cust_site_use_rec.location                        := lc_fetch_acct_site_uses_rec.location                         ;
            lr_cust_site_use_rec.contact_id                      := lc_fetch_acct_site_uses_rec.contact_id                       ;
            lr_cust_site_use_rec.bill_to_site_use_id             := lc_fetch_acct_site_uses_rec.bill_to_site_use_id;
            lr_cust_site_use_rec.orig_system_reference           := RTRIM(l_ou_change_cur.orig_system_reference,'CA') || '-' || lc_fetch_acct_site_uses_rec.site_use_code;
            lr_cust_site_use_rec.orig_system                     := 'A0'                                                         ;
            lr_cust_site_use_rec.sic_code                        := lc_fetch_acct_site_uses_rec.sic_code                         ;
            lr_cust_site_use_rec.payment_term_id                 := lc_fetch_acct_site_uses_rec.payment_term_id                  ;
            lr_cust_site_use_rec.gsa_indicator                   := lc_fetch_acct_site_uses_rec.gsa_indicator                    ;
            lr_cust_site_use_rec.ship_partial                    := lc_fetch_acct_site_uses_rec.ship_partial                     ;
            lr_cust_site_use_rec.ship_via                        := lc_fetch_acct_site_uses_rec.ship_via                         ;
            lr_cust_site_use_rec.fob_point                       := lc_fetch_acct_site_uses_rec.fob_point                        ;
            lr_cust_site_use_rec.order_type_id                   := lc_fetch_acct_site_uses_rec.order_type_id                    ;
            lr_cust_site_use_rec.price_list_id                   := lc_fetch_acct_site_uses_rec.price_list_id                    ;
            lr_cust_site_use_rec.freight_term                    := lc_fetch_acct_site_uses_rec.freight_term                     ;
            lr_cust_site_use_rec.warehouse_id                    := lc_fetch_acct_site_uses_rec.warehouse_id                     ;
            lr_cust_site_use_rec.territory_id                    := lc_fetch_acct_site_uses_rec.territory_id                     ;
            lr_cust_site_use_rec.attribute_category              := lc_fetch_acct_site_uses_rec.attribute_category               ;
            lr_cust_site_use_rec.attribute1                      := lc_fetch_acct_site_uses_rec.attribute1                       ;
            lr_cust_site_use_rec.attribute2                      := lc_fetch_acct_site_uses_rec.attribute2                       ;
            lr_cust_site_use_rec.attribute3                      := lc_fetch_acct_site_uses_rec.attribute3                       ;
            lr_cust_site_use_rec.attribute4                      := lc_fetch_acct_site_uses_rec.attribute4                       ;
            lr_cust_site_use_rec.attribute5                      := lc_fetch_acct_site_uses_rec.attribute5                       ;
            lr_cust_site_use_rec.attribute6                      := lc_fetch_acct_site_uses_rec.attribute6                       ;
            lr_cust_site_use_rec.attribute7                      := lc_fetch_acct_site_uses_rec.attribute7                       ;
            lr_cust_site_use_rec.attribute8                      := lc_fetch_acct_site_uses_rec.attribute8                       ;
            lr_cust_site_use_rec.attribute9                      := lc_fetch_acct_site_uses_rec.attribute9                       ;
            lr_cust_site_use_rec.attribute10                     := lc_fetch_acct_site_uses_rec.attribute10                      ;
            lr_cust_site_use_rec.tax_reference                   := lc_fetch_acct_site_uses_rec.tax_reference                    ;
            lr_cust_site_use_rec.sort_priority                   := lc_fetch_acct_site_uses_rec.sort_priority                    ;
            lr_cust_site_use_rec.tax_code                        := lc_fetch_acct_site_uses_rec.tax_code                         ;
            lr_cust_site_use_rec.attribute11                     := lc_fetch_acct_site_uses_rec.attribute11                      ;
            lr_cust_site_use_rec.attribute12                     := lc_fetch_acct_site_uses_rec.attribute12                      ;
            lr_cust_site_use_rec.attribute13                     := lc_fetch_acct_site_uses_rec.attribute13                      ;
            lr_cust_site_use_rec.attribute14                     := lc_fetch_acct_site_uses_rec.attribute14                      ;
            lr_cust_site_use_rec.attribute15                     := lc_fetch_acct_site_uses_rec.attribute15                      ;
            lr_cust_site_use_rec.attribute16                     := lc_fetch_acct_site_uses_rec.attribute16                      ;
            lr_cust_site_use_rec.attribute17                     := lc_fetch_acct_site_uses_rec.attribute17                      ;
            lr_cust_site_use_rec.attribute18                     := lc_fetch_acct_site_uses_rec.attribute18                      ;
            lr_cust_site_use_rec.attribute19                     := lc_fetch_acct_site_uses_rec.attribute19                      ;
            lr_cust_site_use_rec.attribute20                     := lc_fetch_acct_site_uses_rec.attribute20                      ;
            lr_cust_site_use_rec.attribute21                     := lc_fetch_acct_site_uses_rec.attribute21                      ;
            lr_cust_site_use_rec.attribute22                     := lc_fetch_acct_site_uses_rec.attribute22                      ;
            lr_cust_site_use_rec.attribute23                     := lc_fetch_acct_site_uses_rec.attribute23                      ;
            lr_cust_site_use_rec.attribute24                     := lc_fetch_acct_site_uses_rec.attribute24                      ;
            lr_cust_site_use_rec.attribute25                     := lc_fetch_acct_site_uses_rec.attribute25                      ;
            lr_cust_site_use_rec.demand_class_code               := lc_fetch_acct_site_uses_rec.demand_class_code                ;
            lr_cust_site_use_rec.tax_header_level_flag           := lc_fetch_acct_site_uses_rec.tax_header_level_flag            ;
            lr_cust_site_use_rec.tax_rounding_rule               := lc_fetch_acct_site_uses_rec.tax_rounding_rule                ;
            lr_cust_site_use_rec.global_attribute1               := lc_fetch_acct_site_uses_rec.global_attribute1                ;
            lr_cust_site_use_rec.global_attribute2               := lc_fetch_acct_site_uses_rec.global_attribute2                ;
            lr_cust_site_use_rec.global_attribute3               := lc_fetch_acct_site_uses_rec.global_attribute3                ;
            lr_cust_site_use_rec.global_attribute4               := lc_fetch_acct_site_uses_rec.global_attribute4                ;
            lr_cust_site_use_rec.global_attribute5               := lc_fetch_acct_site_uses_rec.global_attribute5                ;
            lr_cust_site_use_rec.global_attribute6               := lc_fetch_acct_site_uses_rec.global_attribute6                ;
            lr_cust_site_use_rec.global_attribute7               := lc_fetch_acct_site_uses_rec.global_attribute7                ;
            lr_cust_site_use_rec.global_attribute8               := lc_fetch_acct_site_uses_rec.global_attribute8                ;
            lr_cust_site_use_rec.global_attribute9               := lc_fetch_acct_site_uses_rec.global_attribute9                ;
            lr_cust_site_use_rec.global_attribute10              := lc_fetch_acct_site_uses_rec.global_attribute10               ;
            lr_cust_site_use_rec.global_attribute11              := lc_fetch_acct_site_uses_rec.global_attribute11               ;
            lr_cust_site_use_rec.global_attribute12              := lc_fetch_acct_site_uses_rec.global_attribute12               ;
            lr_cust_site_use_rec.global_attribute13              := lc_fetch_acct_site_uses_rec.global_attribute13               ;
            lr_cust_site_use_rec.global_attribute14              := lc_fetch_acct_site_uses_rec.global_attribute14               ;
            lr_cust_site_use_rec.global_attribute15              := lc_fetch_acct_site_uses_rec.global_attribute15               ;
            lr_cust_site_use_rec.global_attribute16              := lc_fetch_acct_site_uses_rec.global_attribute16               ;
            lr_cust_site_use_rec.global_attribute17              := lc_fetch_acct_site_uses_rec.global_attribute17               ;
            lr_cust_site_use_rec.global_attribute18              := lc_fetch_acct_site_uses_rec.global_attribute18               ;
            lr_cust_site_use_rec.global_attribute19              := lc_fetch_acct_site_uses_rec.global_attribute19               ;
            lr_cust_site_use_rec.global_attribute20              := lc_fetch_acct_site_uses_rec.global_attribute20               ;
            lr_cust_site_use_rec.global_attribute_category       := lc_fetch_acct_site_uses_rec.global_attribute_category        ;
            lr_cust_site_use_rec.primary_salesrep_id             := lc_fetch_acct_site_uses_rec.primary_salesrep_id              ;
            lr_cust_site_use_rec.finchrg_receivables_trx_id      := lc_fetch_acct_site_uses_rec.finchrg_receivables_trx_id       ;
            lr_cust_site_use_rec.dates_negative_tolerance        := lc_fetch_acct_site_uses_rec.dates_negative_tolerance         ;
            lr_cust_site_use_rec.dates_positive_tolerance        := lc_fetch_acct_site_uses_rec.dates_positive_tolerance         ;
            lr_cust_site_use_rec.date_type_preference            := lc_fetch_acct_site_uses_rec.date_type_preference             ;
            lr_cust_site_use_rec.over_shipment_tolerance         := lc_fetch_acct_site_uses_rec.over_shipment_tolerance          ;
            lr_cust_site_use_rec.under_shipment_tolerance        := lc_fetch_acct_site_uses_rec.under_shipment_tolerance         ;
            lr_cust_site_use_rec.item_cross_ref_pref             := lc_fetch_acct_site_uses_rec.item_cross_ref_pref              ;
            lr_cust_site_use_rec.over_return_tolerance           := lc_fetch_acct_site_uses_rec.over_return_tolerance            ;
            lr_cust_site_use_rec.under_return_tolerance          := lc_fetch_acct_site_uses_rec.under_return_tolerance           ;
            lr_cust_site_use_rec.ship_sets_include_lines_flag    := lc_fetch_acct_site_uses_rec.ship_sets_include_lines_flag     ;
            lr_cust_site_use_rec.arrivalsets_include_lines_flag  := lc_fetch_acct_site_uses_rec.arrivalsets_include_lines_flag   ;
            lr_cust_site_use_rec.sched_date_push_flag            := lc_fetch_acct_site_uses_rec.sched_date_push_flag             ;
            lr_cust_site_use_rec.invoice_quantity_rule           := lc_fetch_acct_site_uses_rec.invoice_quantity_rule            ;
            lr_cust_site_use_rec.pricing_event                   := lc_fetch_acct_site_uses_rec.pricing_event                    ;
            lr_cust_site_use_rec.gl_id_rec                       := lc_fetch_acct_site_uses_rec.gl_id_rec                        ;
            lr_cust_site_use_rec.gl_id_rev                       := lc_fetch_acct_site_uses_rec.gl_id_rev                        ;
            lr_cust_site_use_rec.gl_id_tax                       := lc_fetch_acct_site_uses_rec.gl_id_tax                        ;
            lr_cust_site_use_rec.gl_id_freight                   := lc_fetch_acct_site_uses_rec.gl_id_freight                    ;
            lr_cust_site_use_rec.gl_id_clearing                  := lc_fetch_acct_site_uses_rec.gl_id_clearing                   ;
            lr_cust_site_use_rec.gl_id_unbilled                  := lc_fetch_acct_site_uses_rec.gl_id_unbilled                   ;
            lr_cust_site_use_rec.gl_id_unearned                  := lc_fetch_acct_site_uses_rec.gl_id_unearned                   ;
            lr_cust_site_use_rec.gl_id_unpaid_rec                := lc_fetch_acct_site_uses_rec.gl_id_unpaid_rec                 ;
            lr_cust_site_use_rec.gl_id_remittance                := lc_fetch_acct_site_uses_rec.gl_id_remittance                 ;
            lr_cust_site_use_rec.gl_id_factor                    := lc_fetch_acct_site_uses_rec.gl_id_factor                     ;
            lr_cust_site_use_rec.tax_classification              := lc_fetch_acct_site_uses_rec.tax_classification               ;
            lr_cust_site_use_rec.created_by_module               := 'XXCONV'                                                     ;
            lr_cust_site_use_rec.application_id                  := lc_fetch_acct_site_uses_rec.application_id                   ;

            fnd_file.put_line(fnd_file.log, 'Create Account Site Use :'||lc_fetch_acct_site_uses_rec.orig_system_reference);
            
            HZ_CUST_ACCOUNT_SITE_V2PUB.create_cust_site_use
               (   p_init_msg_list           => FND_API.G_TRUE,
                   p_cust_site_use_rec       => lr_cust_site_use_rec,
                   p_customer_profile_rec    => NULL,
                   p_create_profile          => FND_API.G_FALSE,
                   p_create_profile_amt      => FND_API.G_FALSE,
                   x_site_use_id             => ln_cust_site_use_id,
                   x_return_status           => lv_return_status,
                   x_msg_count               => ln_msg_count,
                   x_msg_data                => lv_msg_data
               );
             
             IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                l_transaction_error := TRUE;
                fnd_file.put_line(fnd_file.log, 'Error During Site Use Creation:' || lv_msg_data);
             END IF;
               
          END;
          
          UPDATE hz_cust_site_uses_all
          SET primary_flag='N',
              status='I',
              last_update_date = SYSDATE
          WHERE site_use_id = lc_fetch_acct_site_uses_rec.site_use_id;

             BEGIN
               SELECT orig_system_ref_id,object_version_number INTO l_orig_sys_ref_id,l_osr
               FROM hz_orig_sys_references
               WHERE orig_system_reference = lc_fetch_acct_site_uses_rec.orig_system_reference
               AND   orig_system = 'A0'
               AND   owner_table_name = 'HZ_CUST_SITE_USES_ALL'
               AND   owner_table_id   =  lc_fetch_acct_site_uses_rec.site_use_id
               AND   status = 'A';
               
                ------------------------------------------------------------
                -- API Call to inactivate record in hz_orig_sys_references
                 ------------------------------------------------------------

                 
                  lr_orig_sys_reference_rec                       := lr_def_orig_sys_reference_rec;

                  lr_orig_sys_reference_rec.orig_system_ref_id    := l_orig_sys_ref_id;
                  lr_orig_sys_reference_rec.orig_system           := 'A0';
                  lr_orig_sys_reference_rec.orig_system_reference := lc_fetch_acct_site_uses_rec.orig_system_reference;   
                  lr_orig_sys_reference_rec.owner_table_name      := 'HZ_CUST_SITE_USES_ALL';
                  lr_orig_sys_reference_rec.owner_table_id        := lc_fetch_acct_site_uses_rec.site_use_id;
                  lr_orig_sys_reference_rec.status                := 'I';
                  lr_orig_sys_reference_rec.end_date_active       := TRUNC(SYSDATE);

                  HZ_ORIG_SYSTEM_REF_PUB.update_orig_system_reference
                      (   p_init_msg_list             => FND_API.G_TRUE,
                          p_orig_sys_reference_rec    => lr_orig_sys_reference_rec,
                          p_object_version_number     => l_osr,
                          x_return_status             => lv_return_status,
                          x_msg_count                 => ln_msg_count,
                          x_msg_data                  => lv_msg_data
                      );
                      
                  IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                    l_transaction_error := TRUE;
                    fnd_file.put_line(fnd_file.log, 'Error Site Use OSR Inactivation API Call:' || lv_msg_data);
                  END IF;

                EXCEPTION WHEN NO_DATA_FOUND THEN
                   fnd_file.put_line(fnd_file.log,'Error - OSR Entry Not Found For SiteUse OSR: '|| lc_fetch_acct_site_uses_rec.orig_system_reference);
                   l_transaction_error := TRUE;
                END;   
         END LOOP;
      
     UPDATE hz_cust_acct_sites_all
     SET status = 'I',
         last_update_date = SYSDATE
     WHERE cust_acct_site_id = l_ou_change_cur.cust_acct_site_id;


         ------------------------------------------------------------
         -- API Call to inactivate record in hz_orig_sys_references
         ------------------------------------------------------------
         
               SELECT orig_system_ref_id,object_version_number INTO l_orig_sys_ref_id,l_osr
               FROM hz_orig_sys_references
               WHERE orig_system_reference = l_ou_change_cur.orig_system_reference
               AND   orig_system = 'A0'
               AND   owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
               AND   owner_table_id   =  l_ou_change_cur.cust_acct_site_id
               AND   status = 'A';

         lr_orig_sys_reference_rec                       := lr_def_orig_sys_reference_rec;

         lr_orig_sys_reference_rec.orig_system_ref_id    := l_orig_sys_ref_id;
         lr_orig_sys_reference_rec.orig_system           := 'A0';
         lr_orig_sys_reference_rec.orig_system_reference := l_ou_change_cur.orig_system_reference;
         lr_orig_sys_reference_rec.owner_table_name      := 'HZ_CUST_ACCT_SITES_ALL';
         lr_orig_sys_reference_rec.owner_table_id        := l_ou_change_cur.cust_acct_site_id;
         lr_orig_sys_reference_rec.status                := 'I';
         lr_orig_sys_reference_rec.end_date_active       := TRUNC(SYSDATE);

         HZ_ORIG_SYSTEM_REF_PUB.update_orig_system_reference
            (   p_init_msg_list             => FND_API.G_TRUE,
                p_orig_sys_reference_rec    => lr_orig_sys_reference_rec,
                p_object_version_number     => l_osr,
                x_return_status             => lv_return_status,
                x_msg_count                 => ln_msg_count,
                x_msg_data                  => lv_msg_data
            );
            
          IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN
              l_transaction_error := TRUE;
              fnd_file.put_line(fnd_file.log, 'Error Account Site OSR Inactivation API Call:' || lv_msg_data);
          END IF;
          
        IF l_transaction_error THEN
         ROLLBACK TO ou_change_savepoint;
        ELSE
         IF (p_commit = 'Y') THEN
          COMMIT;
         END IF;
         l_tot_records_process := l_tot_records_process + 1;
         fnd_file.put_line(fnd_file.output, 'AccountID:SiteID -- '|| l_ou_change_cur.cust_account_id || ':' || l_ou_change_cur.cust_acct_site_id ||  ' Processed Successfully');
        END IF;
           
       END IF;    
      
    END LOOP;
    
    fnd_file.put_line(fnd_file.output, 'Total Account Sites Modified for OU:' || l_tot_records_process);
    
 
  IF  NVL(TO_NUMBER(SUBSTRB(USERENV('CLIENT_INFO'),1,10)),-99) = 403  THEN   
    FOR l_upd_ca_osr IN upd_ca_osr LOOP
           
      UPDATE hz_cust_acct_sites_all
      SET orig_system_reference = RTRIM(orig_system_reference,'CA') || 'CA'
      WHERE cust_acct_site_id = l_upd_ca_osr.cust_acct_site_id;

      UPDATE hz_cust_site_uses_all
      SET orig_system_reference = RTRIM(l_upd_ca_osr.orig_system_reference,'CA') || 'CA-BILL_TO'
      WHERE cust_acct_site_id = l_upd_ca_osr.cust_acct_site_id 
      AND site_use_code = 'BILL_TO';
      
      UPDATE hz_orig_sys_references
      SET orig_system_reference = RTRIM(orig_system_reference,'CA') || 'CA'
      WHERE owner_table_id = l_upd_ca_osr.cust_acct_site_id 
      AND owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
      AND orig_system_reference = l_upd_ca_osr.orig_system_reference
      AND orig_system = 'A0';
      
      FOR l_upd_uses_cur IN lc_fetch_acct_site_uses_cur (l_upd_ca_osr.cust_acct_site_id) LOOP
       IF  l_upd_uses_cur.site_use_code = 'BILL_TO' THEN
         UPDATE hz_orig_sys_references
         SET orig_system_reference = RTRIM(l_upd_ca_osr.orig_system_reference,'CA') || 'CA-BILL_TO'
         WHERE owner_table_id = l_upd_uses_cur.site_use_id
         AND owner_table_name = 'HZ_CUST_SITE_USES_ALL'
         AND orig_system = 'A0';
       END IF;
      END LOOP; 
    END LOOP;  
  END IF;
    
    IF (p_commit = 'Y') THEN
       COMMIT;
    ELSE
       ROLLBACK;
    END IF; 
     
ELSE -- p_process_billto_dup = 'Y'

    FOR l_billto_dup_cur IN billto_dup_cur LOOP
    
        l_transaction_error := false;
        SAVEPOINT dup_billto;
        
      BEGIN
        
          SELECT cust_acct_site_id,orig_system_reference INTO  ln_cust_acct_site_id,l_site_osr_value
          FROM hz_cust_acct_sites_all
          WHERE cust_account_id =  l_billto_dup_cur.cust_account_id 
          AND party_site_id     =  l_billto_dup_cur.party_site_id
          AND org_id            =  NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1,1),' ',NULL,SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99);
          
          ---------------------------------------
          -- Reactivate Inactive Account Site
          ---------------------------------------
          IF l_billto_dup_cur.org_id = 404 THEN
            UPDATE hz_cust_acct_sites_all
            SET    status = l_billto_dup_cur.status,
                   last_update_date = SYSDATE,
                   orig_system_reference = RTRIM (orig_system_reference,'CA') || 'CA'
            WHERE  cust_acct_site_id = ln_cust_acct_site_id;    
          
            UPDATE hz_orig_sys_references
            SET    status = 'A',
                   last_update_date = SYSDATE,
                   end_date_active = NULL,
                   orig_system_reference = RTRIM (orig_system_reference,'CA') || 'CA'
            WHERE  orig_system_reference = l_site_osr_value
              AND  orig_system  = 'A0'
              AND  owner_table_id = ln_cust_acct_site_id
              AND  owner_table_name = 'HZ_CUST_ACCT_SITES_ALL';
          ELSE
             UPDATE hz_cust_acct_sites_all
             SET    status = l_billto_dup_cur.status,
                   last_update_date = SYSDATE,
                   orig_system_reference = RTRIM (orig_system_reference,'CA')
             WHERE  cust_acct_site_id = ln_cust_acct_site_id;    
          
            UPDATE hz_orig_sys_references
            SET    status = 'A',
                   last_update_date = SYSDATE,
                   end_date_active = NULL,
                   orig_system_reference = RTRIM (orig_system_reference,'CA')
            WHERE  orig_system_reference = l_site_osr_value
              AND  orig_system  = 'A0'
              AND  owner_table_id = ln_cust_acct_site_id
              AND  owner_table_name = 'HZ_CUST_ACCT_SITES_ALL';
           END IF;
      EXCEPTION WHEN NO_DATA_FOUND THEN    

         
      ---------------------------------------
      -- API Call to Create account site
      ---------------------------------------
      
      lr_cust_acct_site_rec                            := lr_def_cust_acct_site_rec;

      --lr_cust_acct_site_rec.cust_acct_site_id          :=
      lr_cust_acct_site_rec.cust_account_id            := l_billto_dup_cur.cust_account_id           ;
      lr_cust_acct_site_rec.party_site_id              := l_billto_dup_cur.party_site_id             ;
      lr_cust_acct_site_rec.attribute_category         := l_billto_dup_cur.attribute_category        ;
      lr_cust_acct_site_rec.attribute1                 := l_billto_dup_cur.attribute1                ;
      lr_cust_acct_site_rec.attribute2                 := l_billto_dup_cur.attribute2                ;
      lr_cust_acct_site_rec.attribute3                 := l_billto_dup_cur.attribute3                ;
      lr_cust_acct_site_rec.attribute4                 := l_billto_dup_cur.attribute4                ;
      lr_cust_acct_site_rec.attribute5                 := l_billto_dup_cur.attribute5                ;
      lr_cust_acct_site_rec.attribute6                 := l_billto_dup_cur.attribute6                ;
      lr_cust_acct_site_rec.attribute7                 := l_billto_dup_cur.attribute7                ;
      lr_cust_acct_site_rec.attribute8                 := l_billto_dup_cur.attribute8                ;
      lr_cust_acct_site_rec.attribute9                 := l_billto_dup_cur.attribute9                ;
      lr_cust_acct_site_rec.attribute10                := l_billto_dup_cur.attribute10               ;
      lr_cust_acct_site_rec.attribute11                := l_billto_dup_cur.attribute11               ;
      lr_cust_acct_site_rec.attribute12                := l_billto_dup_cur.attribute12               ;
      lr_cust_acct_site_rec.attribute13                := l_billto_dup_cur.attribute13               ;
      lr_cust_acct_site_rec.attribute14                := l_billto_dup_cur.attribute14               ;
      lr_cust_acct_site_rec.attribute15                := l_billto_dup_cur.attribute15               ;
      lr_cust_acct_site_rec.attribute16                := l_billto_dup_cur.attribute16               ;
      lr_cust_acct_site_rec.attribute17                := l_billto_dup_cur.attribute17               ;
      lr_cust_acct_site_rec.attribute18                := l_billto_dup_cur.attribute18               ;
      lr_cust_acct_site_rec.attribute19                := l_billto_dup_cur.attribute19               ;
      lr_cust_acct_site_rec.attribute20                := l_billto_dup_cur.attribute20               ;
      lr_cust_acct_site_rec.global_attribute_category  := l_billto_dup_cur.global_attribute_category ;
      lr_cust_acct_site_rec.global_attribute1          := l_billto_dup_cur.global_attribute1         ;
      lr_cust_acct_site_rec.global_attribute2          := l_billto_dup_cur.global_attribute2         ;
      lr_cust_acct_site_rec.global_attribute3          := l_billto_dup_cur.global_attribute3         ;
      lr_cust_acct_site_rec.global_attribute4          := l_billto_dup_cur.global_attribute4         ;
      lr_cust_acct_site_rec.global_attribute5          := l_billto_dup_cur.global_attribute5         ;
      lr_cust_acct_site_rec.global_attribute6          := l_billto_dup_cur.global_attribute6         ;
      lr_cust_acct_site_rec.global_attribute7          := l_billto_dup_cur.global_attribute7         ;
      lr_cust_acct_site_rec.global_attribute8          := l_billto_dup_cur.global_attribute8         ;
      lr_cust_acct_site_rec.global_attribute9          := l_billto_dup_cur.global_attribute9         ;
      lr_cust_acct_site_rec.global_attribute10         := l_billto_dup_cur.global_attribute10        ;
      lr_cust_acct_site_rec.global_attribute11         := l_billto_dup_cur.global_attribute11        ;
      lr_cust_acct_site_rec.global_attribute12         := l_billto_dup_cur.global_attribute12        ;
      lr_cust_acct_site_rec.global_attribute13         := l_billto_dup_cur.global_attribute13        ;
      lr_cust_acct_site_rec.global_attribute14         := l_billto_dup_cur.global_attribute14        ;
      lr_cust_acct_site_rec.global_attribute15         := l_billto_dup_cur.global_attribute15        ;
      lr_cust_acct_site_rec.global_attribute16         := l_billto_dup_cur.global_attribute16        ;
      lr_cust_acct_site_rec.global_attribute17         := l_billto_dup_cur.global_attribute17        ;
      lr_cust_acct_site_rec.global_attribute18         := l_billto_dup_cur.global_attribute18        ;
      lr_cust_acct_site_rec.global_attribute19         := l_billto_dup_cur.global_attribute19        ;
      lr_cust_acct_site_rec.global_attribute20         := l_billto_dup_cur.global_attribute20        ;
      
      IF l_billto_dup_cur.org_id = 404 THEN
         lr_cust_acct_site_rec.orig_system_reference      := RTRIM(l_billto_dup_cur.orig_system_reference,'CA') || 'CA';
      ELSE
         lr_cust_acct_site_rec.orig_system_reference      := RTRIM(l_billto_dup_cur.orig_system_reference,'CA');
      END IF;
      
      lr_cust_acct_site_rec.orig_system                := 'A0'                                              ;
      lr_cust_acct_site_rec.status                     := l_billto_dup_cur.status                                               ;
      lr_cust_acct_site_rec.customer_category_code     := l_billto_dup_cur.customer_category_code    ;
      lr_cust_acct_site_rec.language                   := l_billto_dup_cur.language                  ;
      lr_cust_acct_site_rec.key_account_flag           := l_billto_dup_cur.key_account_flag          ;
      lr_cust_acct_site_rec.tp_header_id               := l_billto_dup_cur.tp_header_id              ;
      lr_cust_acct_site_rec.ece_tp_location_code       := l_billto_dup_cur.ece_tp_location_code      ;
      lr_cust_acct_site_rec.primary_specialist_id      := l_billto_dup_cur.primary_specialist_id     ;
      lr_cust_acct_site_rec.secondary_specialist_id    := l_billto_dup_cur.secondary_specialist_id   ;
      lr_cust_acct_site_rec.territory_id               := l_billto_dup_cur.territory_id              ;
      lr_cust_acct_site_rec.territory                  := l_billto_dup_cur.territory                 ;
      lr_cust_acct_site_rec.translated_customer_name   := l_billto_dup_cur.translated_customer_name  ;
      lr_cust_acct_site_rec.created_by_module          := 'XXCONV'                                          ;
      lr_cust_acct_site_rec.application_id             := l_billto_dup_cur.application_id            ;

      fnd_file.put_line(fnd_file.log, 'Create Account Site :'||l_billto_dup_cur.orig_system_reference);
          
      HZ_CUST_ACCOUNT_SITE_V2PUB.create_cust_acct_site
         (   p_init_msg_list              => FND_API.G_TRUE,
             p_cust_acct_site_rec         => lr_cust_acct_site_rec,
             x_cust_acct_site_id          => ln_cust_acct_site_id,
             x_return_status              => lv_return_status,
             x_msg_count                  => ln_msg_count,
             x_msg_data                   => lv_msg_data
         );
         
      IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN
              l_transaction_error := TRUE;
              fnd_file.put_line(fnd_file.log, 'Error In Account Site Creation API Call:' || lv_msg_data);
      END IF;
      
     END;
     
     FOR lc_fetch_acct_site_uses_rec IN lc_fetch_acct_site_uses_cur (l_billto_dup_cur.cust_acct_site_id)
     LOOP            
       IF lc_fetch_acct_site_uses_rec.site_use_code = 'BILL_TO' THEN       
          BEGIN
        
            SELECT site_use_id,orig_system_reference INTO  ln_cust_site_use_id,l_use_osr_value
            FROM hz_cust_site_uses_all
            WHERE cust_acct_site_id =  ln_cust_acct_site_id 
            AND site_use_code       =  lc_fetch_acct_site_uses_rec.site_use_code
            AND org_id              =  NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1,1),' ',NULL,SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99);
            
             ------------------------------------------
              -- Reactivate Inactive Account Site Use
             ------------------------------------------
          IF l_billto_dup_cur.org_id = 404 THEN  
            UPDATE hz_cust_site_uses_all
            SET    status = lc_fetch_acct_site_uses_rec.status,
                   primary_flag = lc_fetch_acct_site_uses_rec.primary_flag,
                   last_update_date = SYSDATE,
                   orig_system_reference = RTRIM(l_site_osr_value,'CA') || 'CA-BILL_TO'
            WHERE  site_use_id = ln_cust_site_use_id;  
            
            UPDATE hz_orig_sys_references
            SET    status = 'A',
                   last_update_date = SYSDATE,
                   end_date_active = NULL,
                   orig_system_reference = RTRIM(l_site_osr_value,'CA') || 'CA-BILL_TO'
            WHERE  orig_system_reference = l_use_osr_value
            AND    orig_system  = 'A0'
            AND    owner_table_id = ln_cust_site_use_id
            AND    owner_table_name = 'HZ_CUST_SITE_USES_ALL';
          ELSE
            UPDATE hz_cust_site_uses_all
            SET    status = lc_fetch_acct_site_uses_rec.status,
                   primary_flag = lc_fetch_acct_site_uses_rec.primary_flag,
                   last_update_date = SYSDATE,
                   orig_system_reference = RTRIM(l_site_osr_value,'CA') || '-BILL_TO'
            WHERE  site_use_id = ln_cust_site_use_id;  
            
            UPDATE hz_orig_sys_references
            SET    status = 'A',
                   last_update_date = SYSDATE,
                   end_date_active = NULL,
                   orig_system_reference = RTRIM(l_site_osr_value,'CA') || '-BILL_TO'
            WHERE  orig_system_reference = l_use_osr_value
            AND    orig_system  = 'A0'
            AND    owner_table_id = ln_cust_site_use_id
            AND    owner_table_name = 'HZ_CUST_SITE_USES_ALL';
          
          END IF; 

          EXCEPTION WHEN NO_DATA_FOUND THEN
          
             ---------------------------------------
              -- API Call to Create account site Uses
             ---------------------------------------
            
            lr_cust_site_use_rec                                 := lr_def_cust_site_use_rec;

            --lr_cust_site_use_rec.site_use_id                     :=
            lr_cust_site_use_rec.cust_acct_site_id               := ln_cust_acct_site_id                                         ;
            lr_cust_site_use_rec.site_use_code                   := lc_fetch_acct_site_uses_rec.site_use_code                    ;
            lr_cust_site_use_rec.primary_flag                    := lc_fetch_acct_site_uses_rec.primary_flag                     ;
            lr_cust_site_use_rec.status                          := lc_fetch_acct_site_uses_rec.status                                                          ;
            lr_cust_site_use_rec.location                        := lc_fetch_acct_site_uses_rec.location                         ;
            lr_cust_site_use_rec.contact_id                      := lc_fetch_acct_site_uses_rec.contact_id                       ;
            lr_cust_site_use_rec.bill_to_site_use_id             := lc_fetch_acct_site_uses_rec.bill_to_site_use_id  ;
            
            IF l_billto_dup_cur.org_id = 404 THEN
               lr_cust_site_use_rec.orig_system_reference           := RTRIM(l_billto_dup_cur.orig_system_reference,'CA') || 'CA-BILL_TO';
            ELSE
               lr_cust_site_use_rec.orig_system_reference           := RTRIM(l_billto_dup_cur.orig_system_reference,'CA') || '-BILL_TO'; 
            END IF;
            
            lr_cust_site_use_rec.orig_system                     := 'A0'                                                         ;
            lr_cust_site_use_rec.sic_code                        := lc_fetch_acct_site_uses_rec.sic_code                         ;
            lr_cust_site_use_rec.payment_term_id                 := lc_fetch_acct_site_uses_rec.payment_term_id                  ;
            lr_cust_site_use_rec.gsa_indicator                   := lc_fetch_acct_site_uses_rec.gsa_indicator                    ;
            lr_cust_site_use_rec.ship_partial                    := lc_fetch_acct_site_uses_rec.ship_partial                     ;
            lr_cust_site_use_rec.ship_via                        := lc_fetch_acct_site_uses_rec.ship_via                         ;
            lr_cust_site_use_rec.fob_point                       := lc_fetch_acct_site_uses_rec.fob_point                        ;
            lr_cust_site_use_rec.order_type_id                   := lc_fetch_acct_site_uses_rec.order_type_id                    ;
            lr_cust_site_use_rec.price_list_id                   := lc_fetch_acct_site_uses_rec.price_list_id                    ;
            lr_cust_site_use_rec.freight_term                    := lc_fetch_acct_site_uses_rec.freight_term                     ;
            lr_cust_site_use_rec.warehouse_id                    := lc_fetch_acct_site_uses_rec.warehouse_id                     ;
            lr_cust_site_use_rec.territory_id                    := lc_fetch_acct_site_uses_rec.territory_id                     ;
            lr_cust_site_use_rec.attribute_category              := lc_fetch_acct_site_uses_rec.attribute_category               ;
            lr_cust_site_use_rec.attribute1                      := lc_fetch_acct_site_uses_rec.attribute1                       ;
            lr_cust_site_use_rec.attribute2                      := lc_fetch_acct_site_uses_rec.attribute2                       ;
            lr_cust_site_use_rec.attribute3                      := lc_fetch_acct_site_uses_rec.attribute3                       ;
            lr_cust_site_use_rec.attribute4                      := lc_fetch_acct_site_uses_rec.attribute4                       ;
            lr_cust_site_use_rec.attribute5                      := lc_fetch_acct_site_uses_rec.attribute5                       ;
            lr_cust_site_use_rec.attribute6                      := lc_fetch_acct_site_uses_rec.attribute6                       ;
            lr_cust_site_use_rec.attribute7                      := lc_fetch_acct_site_uses_rec.attribute7                       ;
            lr_cust_site_use_rec.attribute8                      := lc_fetch_acct_site_uses_rec.attribute8                       ;
            lr_cust_site_use_rec.attribute9                      := lc_fetch_acct_site_uses_rec.attribute9                       ;
            lr_cust_site_use_rec.attribute10                     := lc_fetch_acct_site_uses_rec.attribute10                      ;
            lr_cust_site_use_rec.tax_reference                   := lc_fetch_acct_site_uses_rec.tax_reference                    ;
            lr_cust_site_use_rec.sort_priority                   := lc_fetch_acct_site_uses_rec.sort_priority                    ;
            lr_cust_site_use_rec.tax_code                        := lc_fetch_acct_site_uses_rec.tax_code                         ;
            lr_cust_site_use_rec.attribute11                     := lc_fetch_acct_site_uses_rec.attribute11                      ;
            lr_cust_site_use_rec.attribute12                     := lc_fetch_acct_site_uses_rec.attribute12                      ;
            lr_cust_site_use_rec.attribute13                     := lc_fetch_acct_site_uses_rec.attribute13                      ;
            lr_cust_site_use_rec.attribute14                     := lc_fetch_acct_site_uses_rec.attribute14                      ;
            lr_cust_site_use_rec.attribute15                     := lc_fetch_acct_site_uses_rec.attribute15                      ;
            lr_cust_site_use_rec.attribute16                     := lc_fetch_acct_site_uses_rec.attribute16                      ;
            lr_cust_site_use_rec.attribute17                     := lc_fetch_acct_site_uses_rec.attribute17                      ;
            lr_cust_site_use_rec.attribute18                     := lc_fetch_acct_site_uses_rec.attribute18                      ;
            lr_cust_site_use_rec.attribute19                     := lc_fetch_acct_site_uses_rec.attribute19                      ;
            lr_cust_site_use_rec.attribute20                     := lc_fetch_acct_site_uses_rec.attribute20                      ;
            lr_cust_site_use_rec.attribute21                     := lc_fetch_acct_site_uses_rec.attribute21                      ;
            lr_cust_site_use_rec.attribute22                     := lc_fetch_acct_site_uses_rec.attribute22                      ;
            lr_cust_site_use_rec.attribute23                     := lc_fetch_acct_site_uses_rec.attribute23                      ;
            lr_cust_site_use_rec.attribute24                     := lc_fetch_acct_site_uses_rec.attribute24                      ;
            lr_cust_site_use_rec.attribute25                     := lc_fetch_acct_site_uses_rec.attribute25                      ;
            lr_cust_site_use_rec.demand_class_code               := lc_fetch_acct_site_uses_rec.demand_class_code                ;
            lr_cust_site_use_rec.tax_header_level_flag           := lc_fetch_acct_site_uses_rec.tax_header_level_flag            ;
            lr_cust_site_use_rec.tax_rounding_rule               := lc_fetch_acct_site_uses_rec.tax_rounding_rule                ;
            lr_cust_site_use_rec.global_attribute1               := lc_fetch_acct_site_uses_rec.global_attribute1                ;
            lr_cust_site_use_rec.global_attribute2               := lc_fetch_acct_site_uses_rec.global_attribute2                ;
            lr_cust_site_use_rec.global_attribute3               := lc_fetch_acct_site_uses_rec.global_attribute3                ;
            lr_cust_site_use_rec.global_attribute4               := lc_fetch_acct_site_uses_rec.global_attribute4                ;
            lr_cust_site_use_rec.global_attribute5               := lc_fetch_acct_site_uses_rec.global_attribute5                ;
            lr_cust_site_use_rec.global_attribute6               := lc_fetch_acct_site_uses_rec.global_attribute6                ;
            lr_cust_site_use_rec.global_attribute7               := lc_fetch_acct_site_uses_rec.global_attribute7                ;
            lr_cust_site_use_rec.global_attribute8               := lc_fetch_acct_site_uses_rec.global_attribute8                ;
            lr_cust_site_use_rec.global_attribute9               := lc_fetch_acct_site_uses_rec.global_attribute9                ;
            lr_cust_site_use_rec.global_attribute10              := lc_fetch_acct_site_uses_rec.global_attribute10               ;
            lr_cust_site_use_rec.global_attribute11              := lc_fetch_acct_site_uses_rec.global_attribute11               ;
            lr_cust_site_use_rec.global_attribute12              := lc_fetch_acct_site_uses_rec.global_attribute12               ;
            lr_cust_site_use_rec.global_attribute13              := lc_fetch_acct_site_uses_rec.global_attribute13               ;
            lr_cust_site_use_rec.global_attribute14              := lc_fetch_acct_site_uses_rec.global_attribute14               ;
            lr_cust_site_use_rec.global_attribute15              := lc_fetch_acct_site_uses_rec.global_attribute15               ;
            lr_cust_site_use_rec.global_attribute16              := lc_fetch_acct_site_uses_rec.global_attribute16               ;
            lr_cust_site_use_rec.global_attribute17              := lc_fetch_acct_site_uses_rec.global_attribute17               ;
            lr_cust_site_use_rec.global_attribute18              := lc_fetch_acct_site_uses_rec.global_attribute18               ;
            lr_cust_site_use_rec.global_attribute19              := lc_fetch_acct_site_uses_rec.global_attribute19               ;
            lr_cust_site_use_rec.global_attribute20              := lc_fetch_acct_site_uses_rec.global_attribute20               ;
            lr_cust_site_use_rec.global_attribute_category       := lc_fetch_acct_site_uses_rec.global_attribute_category        ;
            lr_cust_site_use_rec.primary_salesrep_id             := lc_fetch_acct_site_uses_rec.primary_salesrep_id              ;
            lr_cust_site_use_rec.finchrg_receivables_trx_id      := lc_fetch_acct_site_uses_rec.finchrg_receivables_trx_id       ;
            lr_cust_site_use_rec.dates_negative_tolerance        := lc_fetch_acct_site_uses_rec.dates_negative_tolerance         ;
            lr_cust_site_use_rec.dates_positive_tolerance        := lc_fetch_acct_site_uses_rec.dates_positive_tolerance         ;
            lr_cust_site_use_rec.date_type_preference            := lc_fetch_acct_site_uses_rec.date_type_preference             ;
            lr_cust_site_use_rec.over_shipment_tolerance         := lc_fetch_acct_site_uses_rec.over_shipment_tolerance          ;
            lr_cust_site_use_rec.under_shipment_tolerance        := lc_fetch_acct_site_uses_rec.under_shipment_tolerance         ;
            lr_cust_site_use_rec.item_cross_ref_pref             := lc_fetch_acct_site_uses_rec.item_cross_ref_pref              ;
            lr_cust_site_use_rec.over_return_tolerance           := lc_fetch_acct_site_uses_rec.over_return_tolerance            ;
            lr_cust_site_use_rec.under_return_tolerance          := lc_fetch_acct_site_uses_rec.under_return_tolerance           ;
            lr_cust_site_use_rec.ship_sets_include_lines_flag    := lc_fetch_acct_site_uses_rec.ship_sets_include_lines_flag     ;
            lr_cust_site_use_rec.arrivalsets_include_lines_flag  := lc_fetch_acct_site_uses_rec.arrivalsets_include_lines_flag   ;
            lr_cust_site_use_rec.sched_date_push_flag            := lc_fetch_acct_site_uses_rec.sched_date_push_flag             ;
            lr_cust_site_use_rec.invoice_quantity_rule           := lc_fetch_acct_site_uses_rec.invoice_quantity_rule            ;
            lr_cust_site_use_rec.pricing_event                   := lc_fetch_acct_site_uses_rec.pricing_event                    ;
            lr_cust_site_use_rec.gl_id_rec                       := lc_fetch_acct_site_uses_rec.gl_id_rec                        ;
            lr_cust_site_use_rec.gl_id_rev                       := lc_fetch_acct_site_uses_rec.gl_id_rev                        ;
            lr_cust_site_use_rec.gl_id_tax                       := lc_fetch_acct_site_uses_rec.gl_id_tax                        ;
            lr_cust_site_use_rec.gl_id_freight                   := lc_fetch_acct_site_uses_rec.gl_id_freight                    ;
            lr_cust_site_use_rec.gl_id_clearing                  := lc_fetch_acct_site_uses_rec.gl_id_clearing                   ;
            lr_cust_site_use_rec.gl_id_unbilled                  := lc_fetch_acct_site_uses_rec.gl_id_unbilled                   ;
            lr_cust_site_use_rec.gl_id_unearned                  := lc_fetch_acct_site_uses_rec.gl_id_unearned                   ;
            lr_cust_site_use_rec.gl_id_unpaid_rec                := lc_fetch_acct_site_uses_rec.gl_id_unpaid_rec                 ;
            lr_cust_site_use_rec.gl_id_remittance                := lc_fetch_acct_site_uses_rec.gl_id_remittance                 ;
            lr_cust_site_use_rec.gl_id_factor                    := lc_fetch_acct_site_uses_rec.gl_id_factor                     ;
            lr_cust_site_use_rec.tax_classification              := lc_fetch_acct_site_uses_rec.tax_classification               ;
            lr_cust_site_use_rec.created_by_module               := 'XXCONV'                                                     ;
            lr_cust_site_use_rec.application_id                  := lc_fetch_acct_site_uses_rec.application_id                   ;

            fnd_file.put_line(fnd_file.log, 'Create Account Site Use :'||lc_fetch_acct_site_uses_rec.orig_system_reference);
            
            HZ_CUST_ACCOUNT_SITE_V2PUB.create_cust_site_use
               (   p_init_msg_list           => FND_API.G_TRUE,
                   p_cust_site_use_rec       => lr_cust_site_use_rec,
                   p_customer_profile_rec    => NULL,
                   p_create_profile          => FND_API.G_FALSE,
                   p_create_profile_amt      => FND_API.G_FALSE,
                   x_site_use_id             => ln_cust_site_use_id,
                   x_return_status           => lv_return_status,
                   x_msg_count               => ln_msg_count,
                   x_msg_data                => lv_msg_data
               );
               
            IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN
              l_transaction_error := TRUE;
              fnd_file.put_line(fnd_file.log, 'Error In Site Use Creation API Call:' || lv_msg_data);
            END IF;        
          END;
       END IF;     
     END LOOP;
        
        IF l_transaction_error THEN
           ROLLBACK TO dup_billto;
        ELSE
           IF (p_commit = 'Y') THEN
             COMMIT;
           END IF;
           l_tot_records_process := l_tot_records_process + 1; 
           fnd_file.put_line(fnd_file.output, 'AccountID:SiteID -- '|| l_billto_dup_cur.cust_account_id || ':' || l_billto_dup_cur.cust_acct_site_id ||  ' Processed Successfully For BILL_TO Duplication');
        END IF; 
      END LOOP;
        
       fnd_file.put_line(fnd_file.output, 'Total Account Sites Duplicated in Bot OUs:' || l_tot_records_process);
        
    IF (p_commit = 'Y') THEN
       COMMIT;
    ELSE
       ROLLBACK;
    END IF; 
    
END IF;

 EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      x_retcode := 1;
      x_errbuf  := 'Unexpected Error in procedure process_acct_sites'||SQLERRM;
    
 END ou_fix_main;

END XX_CDH_OU_CHANGE_FIX;
/
SHOW ERRORS;