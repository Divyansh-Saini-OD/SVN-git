SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_COPY_STORE_SITE_USES
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CDH_COPY_STORE_SITE_USES                                |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Copies Store site uses to dummy internal customer and      |
-- |               Copies the location values from hz_cust_site_uses_all      |
-- |               to po_location_associations_all                            |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      18-Feb-2008 Sreedhar Mohan         Initial Version               |
-- |                                                                          |
-- +==========================================================================+
AS
  g_us_sites_count               number := 0;
  g_ca_sites_count               number := 0;

   procedure create_party_sites (
    p_party_site_id         IN         NUMBER,
    p_party_id              IN         NUMBER,
    p_new_party_site_id     OUT NOCOPY NUMBER,
    p_location_id           OUT NOCOPY NUMBER
  );
  procedure create_acct_site_n_site_uses (
    p_cust_account_id       IN         NUMBER,
    p_party_site_id         IN         NUMBER,
    p_cust_acct_site_id     IN         NUMBER,
    p_site_use_id           IN         NUMBER,
    p_site_use_code         IN         HZ_CUST_SITE_USES_ALL.SITE_USE_CODE%TYPE,
    p_location              IN         HZ_CUST_SITE_USES_ALL.LOCATION%TYPE,
    p_org_id                IN         NUMBER,
    p_new_cust_acct_site_id OUT NOCOPY NUMBER,
    p_new_site_use_id       OUT NOCOPY NUMBER
  );
  PROCEDURE upd_loc_associations (
    p_location_id        IN         NUMBER,
    p_cust_account_id    IN         NUMBER,
    p_cust_acct_site_id  IN         NUMBER,
    p_site_use_id        IN         NUMBER,
    p_org_id             IN         NUMBER,
    p_inv_org_id         IN         NUMBER
  );
  PROCEDURE MAIN ( 
    p_errbuf                OUT NOCOPY VARCHAR2,
    p_retcode               OUT NOCOPY VARCHAR2,
    p_us_party_name         IN         VARCHAR2,
    p_ca_party_name         IN         VARCHAR2,
    p_us_org_name           IN         VARCHAR2,
    p_ca_org_name           IN         VARCHAR2
  )
  AS
  l_party_id                     NUMBER;
  l_location_id                  NUMBER;
  l_party_site_id                NUMBER;
  l_new_party_site_id            NUMBER;
  l_party_site_number            HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE;
  l_cust_account_id              NUMBER;
  l_us_party_id                  NUMBER;
  l_us_cust_account_id           NUMBER;
  l_ca_party_id                  NUMBER;
  l_us_org_id                    NUMBER;
  l_ca_org_id                    NUMBER;
  l_ca_cust_account_id           NUMBER;
  l_cust_acct_site_rec           HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
  l_cust_site_use_rec            HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
  l_party_site_rec               HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
  l_customer_profile_rec         HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
  l_cust_acct_site_id            NUMBER;
  l_cust_site_use_id             NUMBER;
  l_new_cust_acct_site_id        NUMBER;
  l_new_site_use_id              NUMBER;
  l_return_status                VARCHAR2(2000);
  l_msg_count                    NUMBER;
  l_msg_data                     VARCHAR2(4000);

    cursor c1 
    is
    select u.location,
           s.cust_acct_site_id,
           s.party_site_id,
           u.site_use_id,
           u.site_use_code,
           a.account_number,
           a.cust_account_id,
           u.org_id,
           l.inventory_organization_id,
	   l.location_id
    from   hz_cust_site_uses_all u,
           hz_cust_acct_sites_all s,
           hz_cust_accounts_all a,
           hr_locations l
    where  u.cust_acct_site_id = s.cust_acct_site_id
    and    s.cust_account_id = a.cust_account_id
    and    u.location = l.location_code
    and    u.site_use_code='SHIP_TO'
    and    a.customer_type = 'I';

    BEGIN

       select p.party_id,
              c.cust_account_id
       into   l_us_party_id,
              l_us_cust_account_id
       from   hz_parties p,
              hz_cust_accounts c
       where  p.party_id = c.party_id and
              p.party_name = p_us_party_name and
              p.status='A';

       select p.party_id,
              c.cust_account_id
       into   l_ca_party_id,
              l_ca_cust_account_id
       from   hz_parties p,
              hz_cust_accounts c
       where  p.party_id = c.party_id and
              p.party_name = p_ca_party_name and
              p.status='A';

       select organization_id
       into   l_us_org_id
       from   hr_all_organization_units
       where  name=p_us_org_name;

       select organization_id
       into   l_ca_org_id
       from   hr_all_organization_units
       where  name=p_ca_org_name;

      for c1_rec in c1 
      loop
         l_return_status := null;
         l_msg_count     := 0;
         l_msg_data      := null;

         l_new_cust_acct_site_id := null;
         l_new_site_use_id := null;
         l_new_party_site_id := null;

         IF (c1_rec.org_id = l_us_org_id) then

           --Create Party Site in US
           create_party_sites (
                                 c1_rec.party_site_id,
                                 l_us_party_id,
                                 l_new_party_site_id,
                                 l_location_id
           );
           --Create Acct Site and Site Uses in US
           create_acct_site_n_site_uses(
                                        l_us_cust_account_id,
                                        l_new_party_site_id,
                                        c1_rec.cust_acct_site_id,
                                        c1_rec.site_use_id,
					c1_rec.site_use_code,
					c1_rec.location,
                                        c1_rec.org_id,
                                        l_new_cust_acct_site_id,
                                        l_new_site_use_id);
          UPD_LOC_ASSOCIATIONS(
                              c1_rec.location_id,
                              l_us_cust_account_id,
                              l_new_cust_acct_site_id,
                              l_new_site_use_id,
                              c1_rec.org_id,
                              c1_rec.inventory_organization_id
                            );

        ELSIF (c1_rec.org_id = l_ca_org_id) THEN
           --Create Party Site in CA
           create_party_sites (
                                 c1_rec.party_site_id,
                                 l_ca_party_id,
                                 l_new_party_site_id,
                                 l_location_id
           );

           --For CA account sites, create in US as well in CA
           --So Create Acct Site and Site Uses in CA
           create_acct_site_n_site_uses(
                                        l_ca_cust_account_id,
                                        l_new_party_site_id,
                                        c1_rec.cust_acct_site_id,
                                        c1_rec.site_use_id,
					c1_rec.site_use_code,
					c1_rec.location,
                                        c1_rec.org_id,
                                        l_new_cust_acct_site_id,
                                        l_new_site_use_id);
	   UPD_LOC_ASSOCIATIONS(
                                c1_rec.location_id,
                                l_ca_cust_account_id,
                                l_new_cust_acct_site_id,
                                l_new_site_use_id,
                                c1_rec.org_id,
                                c1_rec.inventory_organization_id
                              );
	   --Next, create Acct Site and Site Uses in US
           l_new_cust_acct_site_id := null;
           l_new_site_use_id := null;
           create_acct_site_n_site_uses(
                                        l_us_cust_account_id,
                                        l_new_party_site_id,
                                        c1_rec.cust_acct_site_id,
                                        c1_rec.site_use_id,
					c1_rec.site_use_code,
					c1_rec.location,
                                        l_us_org_id,
                                        l_new_cust_acct_site_id,
                                        l_new_site_use_id);
	   UPD_LOC_ASSOCIATIONS(
                                c1_rec.location_id,
                                l_us_cust_account_id,
                                l_new_cust_acct_site_id,
                                l_new_site_use_id,
                                l_us_org_id,
                                c1_rec.inventory_organization_id
                              );
        ELSE
          null;
        END IF;
        
      end loop;
      
      fnd_file.put_line(FND_FILE.OUTPUT, 'US Sites Count: ' || g_us_sites_count);
      fnd_file.put_line(FND_FILE.OUTPUT, 'CA Sites Count: ' || g_ca_sites_count);

      commit;

    EXCEPTION
      when others then
        fnd_file.put_line(FND_FILE.OUTPUT, 'Exception in Main: ' || SQLERRM);
  
  END MAIN;

  procedure create_party_sites (
                                 p_party_site_id     IN         NUMBER,
                                 p_party_id          IN         NUMBER,
                                 p_new_party_site_id OUT NOCOPY NUMBER,
                                 p_location_id       OUT NOCOPY NUMBER
  ) is
  l_party_id                     NUMBER;
  l_location_id                  NUMBER;
  l_party_site_id                NUMBER;
  l_party_site_number            HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE;
  l_return_status                VARCHAR2(2000);
  l_msg_count                    NUMBER;
  l_msg_data                     VARCHAR2(4000);
  l_party_site_rec               HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;

  cursor c2( p_party_site_id number)
  is
  select location_id
  from   hz_party_sites
  where  party_site_id = p_party_site_id;

  BEGIN

           open c2 (p_party_site_id);
           fetch c2 into l_location_id;
           p_location_id := l_location_id;

           l_party_site_rec.party_site_id := null        ;
           l_party_site_rec.party_site_number := null    ;
           l_party_site_rec.party_id := p_party_id       ;
           l_party_site_rec.location_id :=  l_location_id;
           l_party_site_rec.created_by_module := 'XXCONV';

           l_return_status := null;
           l_msg_count     := 0;
           l_msg_data      := null;

           HZ_PARTY_SITE_V2PUB.create_party_site (
             p_party_site_rec        => l_party_site_rec,
             x_party_site_id         => p_new_party_site_id,
             x_party_site_number     => l_party_site_number,
             x_return_status         => l_return_status,
             x_msg_count             => l_msg_count,
             x_msg_data              => l_msg_data
           );
           close c2;
           IF l_return_status = 'S' THEN
            fnd_file.put_line(FND_FILE.OUTPUT,'Return Status After create_party_site: ' || l_return_status
                              || ', New Party_Site_Id: ' || p_new_party_site_id);
           ELSE
            IF l_msg_count >= 1 THEN
                FOR I IN 1..l_msg_count
                LOOP
                    l_msg_data := l_msg_data||' '||SUBSTR ( fnd_msg_pub.get ( p_encoded => fnd_api.g_false ), 1, 250 ); 
                END LOOP;
             END IF;
           fnd_file.put_line(FND_FILE.OUTPUT,'create_party_site Error MsgData: ' || l_msg_data);
           END IF;

    EXCEPTION
      when others then
        fnd_file.put_line(FND_FILE.OUTPUT, 'Exception in create_party_sites: ' || SQLERRM);

  END create_party_sites;

  procedure create_acct_site_n_site_uses(
                                         p_cust_account_id       IN         NUMBER,
                                         p_party_site_id         IN         NUMBER,
                                         p_cust_acct_site_id     IN         NUMBER,
                                         p_site_use_id           IN         NUMBER,
                                         p_site_use_code         IN         HZ_CUST_SITE_USES_ALL.SITE_USE_CODE%TYPE,
                                         p_location              IN         HZ_CUST_SITE_USES_ALL.LOCATION%TYPE,
                                         p_org_id                IN         NUMBER,
                                         p_new_cust_acct_site_id OUT NOCOPY NUMBER,
                                         p_new_site_use_id       OUT NOCOPY NUMBER
  ) is
  l_cust_acct_site_id            NUMBER;
  l_cust_site_use_id             NUMBER;
  l_us_org_id                    NUMBER;
  l_ca_org_id                    NUMBER;
  l_return_status                VARCHAR2(2000);
  l_msg_count                    NUMBER;
  l_msg_data                     VARCHAR2(4000);

  l_cust_acct_site_rec           HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
  l_cust_site_use_rec            HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
  l_customer_profile_rec         HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
  begin

    FND_CLIENT_INFO.SETUP_CLIENT_INFO (
      FND_GLOBAL.RESP_APPL_ID,
      FND_GLOBAL.RESP_ID,
      FND_GLOBAL.USER_ID,
      FND_GLOBAL.SECURITY_GROUP_ID,
      p_ORG_ID
    );
    --Create Cust Acct Site    
    l_cust_acct_site_rec.cust_acct_site_id := null;
    l_cust_acct_site_rec.cust_account_id   := p_cust_account_id;
    l_cust_acct_site_rec.party_site_id     := p_party_site_id;
    l_cust_acct_site_rec.orig_system_reference := null;
    l_cust_acct_site_rec.created_by_module := 'XXCONV';

    l_return_status := null;
    l_msg_count     := 0;
    l_msg_data      := null;

    hz_cust_account_site_v2pub.create_cust_acct_site (
      p_cust_acct_site_rec     => l_cust_acct_site_rec,
      x_cust_acct_site_id      => l_cust_acct_site_id,
      x_return_status          => l_return_status,
      x_msg_count              => l_msg_count,
      x_msg_data               => l_msg_data
    );
    p_new_cust_acct_site_id := l_cust_acct_site_id;
    IF l_return_status = 'S' THEN
     fnd_file.put_line(FND_FILE.OUTPUT,'Return Status After create_cust_acct_site: ' 
                       || l_return_status || ', cust_acct_site_id: ' || l_cust_acct_site_id);
     if (p_ORG_ID = l_us_org_id) then
       g_us_sites_count := g_us_sites_count + 1;
     elsif ( p_ORG_ID = l_ca_org_id) then
       g_ca_sites_count := g_us_sites_count + 1;
     end if;
    ELSE
     IF l_msg_count >= 1 THEN
         FOR I IN 1..l_msg_count
         LOOP
             l_msg_data := l_msg_data||' '||SUBSTR ( fnd_msg_pub.get ( p_encoded => fnd_api.g_false ), 1, 250 ); 
         END LOOP;
      END IF;
    fnd_file.put_line(FND_FILE.OUTPUT,'create_cust_acct_site Error MsgData: ' || l_msg_data);
    END IF;

    --Create Cust Site Use

    l_cust_site_use_rec.site_use_id         := null;
    l_cust_site_use_rec.cust_acct_site_id   := l_cust_acct_site_id;
    l_cust_site_use_rec.site_use_code       := p_site_use_code;
    l_cust_site_use_rec.location            := p_location;
    l_cust_site_use_rec.created_by_module   := 'XXCONV';

    l_return_status := null;
    l_msg_count     := 0;
    l_msg_data      := null;

    hz_cust_account_site_v2pub.create_cust_site_use
             (
                 p_init_msg_list           => FND_API.G_TRUE,
                 p_cust_site_use_rec       => l_cust_site_use_rec,
                 p_customer_profile_rec    => NULL,
                 p_create_profile          => FND_API.G_FALSE,
                 p_create_profile_amt      => FND_API.G_FALSE,
                 x_site_use_id             => l_cust_site_use_id,
                 x_return_status           => l_return_status,
                 x_msg_count               => l_msg_count,
                 x_msg_data                => l_msg_data
             );
    p_new_site_use_id := l_cust_site_use_id;
    IF l_return_status = 'S' THEN
     fnd_file.put_line(FND_FILE.OUTPUT,'Return Status After create_cust_site_use: ' || l_return_status
                       || ', cust_site_use_id: ' || l_cust_site_use_id);
         null;
    ELSE
     IF l_msg_count >= 1 THEN
         FOR I IN 1..l_msg_count
         LOOP
             l_msg_data := l_msg_data||' '||SUBSTR ( fnd_msg_pub.get ( p_encoded => fnd_api.g_false ), 1, 250 ); 
         END LOOP;
      END IF;
    fnd_file.put_line(FND_FILE.OUTPUT,'create_cust_site_use Error MsgData: ' || l_msg_data);
    END IF;

    EXCEPTION
      when others then
        fnd_file.put_line(FND_FILE.OUTPUT, 'Exception in create_acct_site_n_site_uses: ' || SQLERRM);

  END create_acct_site_n_site_uses;

  PROCEDURE upd_loc_associations (
                                  p_location_id        IN         NUMBER,
                                  p_cust_account_id    IN         NUMBER,
                                  p_cust_acct_site_id  IN         NUMBER,
                                  p_site_use_id        IN         NUMBER,
                                  p_org_id             IN         NUMBER,
                                  p_inv_org_id         IN         NUMBER
                                 )
  AS

  l_location_id        hr_locations.location_id%type;
  l_organization_id    hr_locations.inventory_organization_id%type;
  l_site_use_id        hz_cust_site_uses_all.site_use_id%type;
  l_address_id         hz_cust_acct_sites_all.cust_acct_site_id%type;
  l_customer_id        hz_cust_accounts.cust_account_id%type;
  l_location           hz_cust_site_uses_all.location%type;
  l_org_id             hz_cust_site_uses_all.org_id%type;

  BEGIN

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
    p_location_id,
    p_cust_account_id,
    p_cust_acct_site_id, 
    p_site_use_id, 
    p_inv_org_id,
    p_org_id,
    fnd_global.user_id,
    sysdate,
    fnd_global.user_id,
    sysdate,
    fnd_global.login_id,
    'SHIP_TO');

  EXCEPTION
    
    WHEN OTHERS THEN
      fnd_file.put_line(FND_FILE.OUTPUT,'Exception in UPD_LOC_ASSOCIATIONS: ' || SQLERRM);
  
  END upd_loc_associations;

END XX_CDH_COPY_STORE_SITE_USES;
/

SHOW ERRORS;
