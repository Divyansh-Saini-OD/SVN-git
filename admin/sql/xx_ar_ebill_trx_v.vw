SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT Creating VIEW APPS.XX_AR_EBILL_TRX_V

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                       Wipro Technologies                                       |
-- +================================================================================+
-- | Name : XX_AR_EBILL_TRX_V                                                       |
-- |                                                                                |
-- | Description : Custom view for AR Consolidated Electronic Billing Invoices      |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date          Author                Remarks                           |
-- |=======   ==========   ================      ===================================|
-- | 1.0     03-SEP-2009   Balaguru Seshadri     Initial Verison                    |
-- | 1.1     20-MAR-2009   RamyaPriya M          Modified for defect 13372(CR#562)  |
-- |                                                                                |
-- |                                                                                |
-- |                                                                                |
-- +================================================================================+

create or replace view apps.xx_ar_ebill_trx_v as
select aihv.customer_trx_id                            customer_trx_id
      ,aihv.trx_number                                 trx_number
      ,aihv.bill_to_site_use_id                        bill_to_site_use_id
      ,aihv.ship_to_site_use_id                        ship_to_site_use_id
      ,aihv.interface_header_attribute1                interface_header_attribute1
      ,null                                            location
      ,hzcp.phone_area_code||hzcp.phone_number         phone_number              
      ,nvl
        (
          substr(b_cust.orig_system_reference 
         ,1 
         ,instr(b_cust.orig_system_reference ,'-')-1) 
         ,b_cust.orig_system_reference
        )                                              orig_system_reference
      ,null                                            site_use_code  
      ,aihv.purchase_order                             purchase_order_number
      ,b_cust.account_number                           bill_to_customer_number
    --,b_cust.account_name                             bus_name                --Commented for the defect 13372(CR#562)
      ,nvl(bill_loc.address_lines_phonetic,b_party.party_name) bus_name        --Added for the defect 13372(CR#562)
      ,null                                            term_name 
      ,aihv.interface_header_attribute2                interface_header_attribute2
--      ,:p_tax_id                                       tax_registration_number
      ,sales.name                                      primary_salesrep_name   
    --,s_cust.account_name                             ship_to_customer_name   --Commented for the defect 13372(CR#562)
      ,nvl(ship_loc.address_lines_phonetic,b_party.party_name) ship_to_customer_name --Added for the defect 13372(CR#562)
      ,ship_loc.address1                               ship_to_address1                                   
      ,ship_loc.address2                               ship_to_address2
      ,ship_loc.city                                   ship_to_city
      ,ship_loc.state                                  ship_to_state
      ,ship_loc.postal_code                            ship_to_postal_code
      ,ship_loc.country                                ship_to_country  
      ,SUBSTRB (c_ship_party.person_first_name,
                   1,
                   40
                  )||
          SUBSTRB (c_ship_party.person_last_name,
                   1,
                   40
                  )                                    ship_to_contact  
      ,aihv.trx_date                                   trx_date
      ,ship_site.location                              ship_to_location    
    --,b_cust.account_name                             bill_to_name            --Commented for the defect 13372(CR#562)
      ,nvl(bill_loc.address_lines_phonetic,b_party.party_name) bill_to_name    --Added for the defect 13372(CR#562)
      ,bill_site.location                              bill_to_location
      ,bill_loc.address1                               bill_to_address1
      ,bill_loc.address2                               bill_to_address2
      ,bill_loc.city                                   bill_to_city
      ,bill_loc.state                                  bill_to_state
      ,bill_loc.postal_code                            bill_to_postal_code
      ,bill_loc.province                               bill_to_province
      ,bill_loc.country                                bill_to_country  
      ,SUBSTRB (c_bill_party.person_first_name, 1, 40)
       || ' '
       ||SUBSTRB (c_bill_party.person_last_name, 1,50) default_bill_attn 
      ,null                                            ordsourcecd
      ,trunc(aihv.ship_date_actual)                    ordcompletedate
      ,aihv_prev.trx_number                            orgordnbr  
      ,trx_type.type                                   trx_class
      ,batch_source.name                               invoice_source
      ,aihv.batch_source_id                            invoice_source_id
      ,aihv.attribute14                                order_header_id  
--      ,c_bill_org_cont.mail_stop                       bill_to_mail_stop
--      ,c_ship_org_cont.mail_stop                       ship_to_mail_stop                                                                  
from  ra_customer_trx       aihv
     ,hz_cust_accounts      b_cust
     ,hz_cust_accounts      s_cust
     ,hz_parties            b_party
     ,ra_salesreps          sales   
     ,hz_cust_acct_sites    ship_acct
     ,hz_cust_site_uses     ship_site
     ,hz_party_sites        ship_ps  
     ,hz_locations          ship_loc  
     ,hz_cust_account_roles c_ship
     ,hz_parties            c_ship_party
     ,hz_relationships      c_ship_rel
     ,hz_org_contacts       c_ship_org_cont 
     ,hz_cust_acct_sites    bill_acct
     ,hz_cust_site_uses     bill_site
     ,hz_party_sites        bill_ps  
     ,hz_locations          bill_loc 
     ,hz_cust_account_roles c_bill
     ,hz_parties            c_bill_party
     ,hz_relationships      c_bill_rel
     ,hz_org_contacts       c_bill_org_cont      
     ,ra_customer_trx       aihv_prev  
     ,ra_cust_trx_types     trx_type  
     ,ra_batch_sources      batch_source
     ,hz_contact_points     hzcp          
where 1 =1
  and b_cust.cust_account_id        =aihv.bill_to_customer_id
  and b_party.party_id              =b_cust.party_id
  and aihv.ship_to_customer_id      =s_cust.cust_account_id(+)
  and aihv.primary_salesrep_id      = sales.salesrep_id(+)
  and aihv.ship_to_site_use_id      =ship_site.site_use_id(+)
  and ship_site.cust_acct_site_id   =ship_acct.cust_acct_site_id(+)
  and ship_acct.party_site_id       =ship_ps.party_site_id(+)
  and ship_loc.location_id(+)       =ship_ps.location_id
  and aihv.bill_to_site_use_id      =bill_site.site_use_id
  and bill_site.cust_acct_site_id   =bill_acct.cust_acct_site_id(+)
  and bill_acct.party_site_id       =bill_ps.party_site_id(+)
  and bill_loc.location_id(+)       =bill_ps.location_id 
  and aihv.previous_customer_trx_id =aihv_prev.customer_trx_id(+) 
  and trx_type.cust_trx_type_id     =aihv.cust_trx_type_id
  and batch_source.batch_source_id  =aihv.batch_source_id  
  -- ====   
  and aihv.ship_to_contact_id                  =c_ship.cust_account_role_id(+)
  and c_ship.party_id                          =c_ship_rel.party_id(+)
  and c_ship_rel.subject_table_name(+)         ='HZ_PARTIES'
  and c_ship_rel.object_table_name(+)          ='HZ_PARTIES'
  and c_ship_rel.directional_flag(+)           ='F'
  and c_ship.role_type(+)                      ='CONTACT'
  and c_ship_org_cont.party_relationship_id(+) =c_ship_rel.relationship_id
  and c_ship_rel.subject_id                    =c_ship_party.party_id(+) 
  -- ====  
  and aihv.bill_to_contact_id                  =c_bill.cust_account_role_id(+)
  and c_bill.party_id                          =c_bill_rel.party_id(+)
  and c_bill_rel.subject_table_name(+)         ='HZ_PARTIES'
  and c_bill_rel.object_table_name(+)          ='HZ_PARTIES'
  and c_bill_rel.directional_flag(+)           ='F'
  and c_bill.role_type(+)                      ='CONTACT'
  and c_bill_org_cont.party_relationship_id(+) =c_bill_rel.relationship_id
  and c_bill_rel.subject_id                    =c_bill_party.party_id(+)
  and hzcp.owner_table_id(+)                   =c_bill_party.party_id
  and hzcp.owner_table_name(+)                 ='HZ_PARTIES'
  and hzcp.contact_point_type(+)               ='PHONE'
  and hzcp.primary_flag(+)                     ='Y'
  and hzcp.contact_point_purpose(+)            ='BUSINESS'  
  and hzcp.status(+)                           ='A' ; 
  --  and aihv.customer_trx_id          =:p_trx_id  
  
SHOW ERROR
