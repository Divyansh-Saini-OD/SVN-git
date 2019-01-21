SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_UPD_LOC_ASSOCIATIONS
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CDH_UPD_LOC_ASSOCIATIONS                                |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Copies the location values from hz_cust_site_uses_all      |
-- |               to po_location_associations_all                            |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      11-Oct-2007 Sreedhar Mohan         Initial Version               |
-- |                                                                          |
-- +==========================================================================+
AS
  PROCEDURE MAIN( 
                  p_errbuf   OUT NOCOPY VARCHAR2,
                  p_retcode  OUT NOCOPY VARCHAR2
                )
  AS
    cursor c1 
    is
    select u.location
    from   hz_cust_site_uses_all u,
           hz_cust_acct_sites_all s,
           hz_cust_accounts_all a,
           hr_locations l
    where  u.cust_acct_site_id = s.cust_acct_site_id
    and    s.cust_account_id = a.cust_account_id
    and    u.location = l.location_code
    and    u.site_use_code='SHIP_TO'
    and    a.customer_class_code = 'STORE'
    and    location_id not in (     select location_id
                                    from   po_location_associations_all);
    BEGIN
      for c1_rec in c1 
      loop
        XX_CDH_UPD_LOC_ASSOCIATIONS.UPD_LOC_ASSOCIATIONS(
                                                         p_errbuf,
                                                         p_retcode,
                                                          c1_rec.location
                                                        );
      end loop;

    EXCEPTION
      when others then
        fnd_file.put_line(FND_FILE.OUTPUT,SQLERRM);
  
  END MAIN;

  PROCEDURE UPD_LOC_ASSOCIATIONS (
                                p_errbuf   OUT NOCOPY VARCHAR2,
                                p_retcode  OUT NOCOPY VARCHAR2,
                                p_location IN         VARCHAR2
                                )
  AS

  l_location_id        hr_locations.location_id%type;
  l_organization_id    hr_locations.inventory_organization_id%type;
  l_site_use_id        hz_cust_site_uses_all.site_use_id%type;
  l_address_id         hz_cust_acct_sites_all.cust_acct_site_id%type;
  l_customer_id        hz_cust_accounts.cust_account_id%type;
  l_location           hz_cust_site_uses_all.location%type;
  l_org_id             hz_cust_site_uses_all.org_id%type;

  CURSOR c_site_uses (p_cs_location in varchar2)
  is
  select u.site_use_id,
         u.cust_acct_site_id,
         u.location,
         u.org_id,
         a.cust_account_id,
         l.location_id,
         l.inventory_organization_id
  from   hz_cust_site_uses_all u,
         hz_cust_acct_sites_all s,
         hz_cust_accounts_all a,
         hr_locations l
  where  u.cust_acct_site_id = s.cust_acct_site_id
  and    s.cust_account_id = a.cust_account_id
  and    u.location = l.location_code
  and    u.site_use_code='SHIP_TO'
  and    a.customer_class_code = 'STORE'
  --and    u.orig_system_reference like '0000%US%';
  and    location = p_location;

  BEGIN

    l_site_use_id := null;
    l_address_id  := null;
    l_org_id := null;
    
    open c_site_uses(p_location);
    fetch c_site_uses into l_site_use_id, l_address_id, l_location, 
    l_org_id, l_customer_id,l_location_id, l_organization_id;

    IF (c_site_uses%NOTFOUND) THEN
      CLOSE c_site_uses;
      RAISE NO_DATA_FOUND;
    END IF;

    insert into po_location_associations_all (
    location_id,
    customer_id,
    address_id,
    site_use_id,
    organization_id,
    org_id,
    created_by,
    creation_date,
    last_updated_by,
    last_update_date,
    last_update_login,
    attribute_category)
    values (
    l_location_id,
    l_customer_id,
    l_address_id, 
    l_site_use_id, 
    l_organization_id,
    l_org_id,
    fnd_global.user_id,
    sysdate,
    fnd_global.user_id,
    sysdate,
    fnd_global.login_id,
    'SHIP_TO');

    commit;
    
    close c_site_uses;

  EXCEPTION
    when NO_DATA_FOUND then
      fnd_file.put_line(FND_FILE.OUTPUT,'No Data Found!');

    when others then
      fnd_file.put_line(FND_FILE.OUTPUT,SQLERRM);
  
  END UPD_LOC_ASSOCIATIONS;

END XX_CDH_UPD_LOC_ASSOCIATIONS;
/

SHOW ERRORS;
