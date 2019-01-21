SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CDH_ABL_CUSTOMERS_PKG
-- +===================================================================================+
-- |                  Office Depot - Project Simplify  Rel 1.1                         |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  PRINT_CUSTOMER_DETAILS                                        |
-- |                                                                                   |
-- | Description      : Reporting package for all AB Customers                         |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1.0 12-Oct-09   Sreedhar Mohan               Draft version                   |
-- +===================================================================================+
AS

PROCEDURE PRINT_CUSTOMER_DETAILS ( p_errbuf            OUT NOCOPY VARCHAR2
                                   , p_retcode         OUT NOCOPY VARCHAR2               
                                 )
AS
  ln_standard_terms              NUMBER;
  lc_phone_number_ap             VARCHAR2(60);
  lc_phone_number_ot             VARCHAR2(60);
  lc_phone_number                VARCHAR2(60);
  lc_usage_code                  VARCHAR2(30);
  ln_nophone_count               NUMBER;

  cursor c_standard_terms
  is
  select term_id
  from   ra_terms
  where  name = 'IMMEDIATE';

  cursor c1 (p_standard_terms number)
  is
  select acct.account_number,
         party.party_name,
         party.address1, 
         party.address2, 
         party.city,
         party.state,
         party.province,
         party.postal_code,
         party.country,
         acct.party_id,
         acct.attribute18
  from   apps.hz_parties party,
         apps.hz_cust_accounts acct,
         apps.hz_party_sites ps,
         apps.hz_customer_profiles prof
  where  acct.party_id = party.party_id
  and    party.party_id = ps.party_id
  and    acct.status='A'
  and    party.status = 'A'
  and    ps.status = 'A'
  and    ps.identifying_address_flag='Y'
  and    acct.cust_account_id = prof.cust_account_id
  and    prof.site_use_id is null
  and    prof.standard_terms <> p_standard_terms
  and    prof.status = 'A'
  and    country in ('US', 'CA')
  order  by country, account_number;

  cursor c_phone_number_ap(p_party_id number)
  is
  select cp.phone_area_code || '-' || substr(phone_number,1,3) || '-' || substr(phone_number,4,7) "phone_number"         
  from   apps.hz_parties              party,
         apps.hz_party_relationships  rel,
         apps.hz_org_contacts         cont,
         apps.hz_contact_points     cp
  where  party.party_id = rel.object_id
  and    rel.party_relationship_id = cont.party_relationship_id
  and    cont.status='A'
  and    rel.status='A'
  and    (trim(upper(cont.job_title))= 'AP' or (trim(upper(cont.job_title)) like 'ACCOUNT%PAY%'))
  and    cp.owner_table_id = rel.party_id
  and    cp.contact_point_type='PHONE'
  and    cp.phone_line_type='GEN'
  and    cp.status='A'
  and    party.party_id = p_party_id
  and    rownum=1;

  cursor c_phone_number_ot(p_party_id number)
  is
  select cp.phone_area_code || '-' || substr(phone_number,1,3) || '-' || substr(phone_number,4,7) "phone_number"         
  from   apps.hz_parties              party,
         apps.hz_party_relationships  rel,
         apps.hz_org_contacts         cont,
         apps.hz_contact_points     cp
  where  party.party_id = rel.object_id
  and    rel.party_relationship_id = cont.party_relationship_id
  and    cont.status='A'
  and    rel.status='A'
  and    cp.owner_table_id = rel.party_id
  and    cp.contact_point_type='PHONE'
  and    cp.phone_line_type='GEN'
  and    cp.status='A'
  and    party.party_id = p_party_id
  and    rownum = 1;


BEGIN
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'CUSTOMER_NUMBER|COMPANY_NAME|ADDRESS1|ADDRESS2|CITY|STATE|PROVINCE|POSTAL_CODE|COUNTRY|PHONE_NUMBER');
  
  ln_nophone_count := 0;
  lc_phone_number:= null;
  lc_phone_number_ap:= null;
  lc_phone_number_ot:= null;
  open c_standard_terms;
  fetch c_standard_terms into ln_standard_terms;
  for i_rec in c1(ln_standard_terms)
  LOOP
    lc_phone_number:= null;
    lc_phone_number_ap:= null;
    lc_phone_number_ot:= null;
    
    open c_phone_number_ap(i_rec.party_id);
    fetch c_phone_number_ap into lc_phone_number_ap;
    lc_phone_number := lc_phone_number_ap;
    if (trim(lc_phone_number_ap)) is null then
        open c_phone_number_ot(i_rec.party_id);
        fetch c_phone_number_ot into lc_phone_number_ot;
        lc_phone_number := lc_phone_number_ot;
        if(trim(lc_phone_number_ot)) is null then
          ln_nophone_count := ln_nophone_count+1;
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'No phone for customer number: ' || i_rec.account_number);
        end if;
    end if;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                      i_rec.account_number || '|' ||
                      i_rec.party_name     || '|' ||
                      i_rec.address1       || '|' ||
                      i_rec.address2       || '|' ||
                      i_rec.city           || '|' ||
                      i_rec.state          || '|' ||
                      i_rec.province       || '|' ||
                      i_rec.postal_code    || '|' ||
                      i_rec.country        || '|' ||
                      lc_phone_number
                     );
    if c_phone_number_ap%isopen then
      close c_phone_number_ap;
    end if;
    if c_phone_number_ot%isopen then
      close c_phone_number_ot; 
    end if;      
  END LOOP;
  close c_standard_terms;

  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Number Of AB Customers with no Phone Number: ' || ln_nophone_count);        

EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception in PRINT_CUSTOMER_DETAILS: ' || SQLERRM);        

END PRINT_CUSTOMER_DETAILS;

END XX_CDH_ABL_CUSTOMERS_PKG;
/
SHOW ERRORS;
