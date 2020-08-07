---+========================================================================================================+        
---|                                        Office Depot - Project Simplify                                 |
---|                             Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       xx_ar_print_summbill.pkb                                      |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                     |
---|    ------------    ----------------- ---------------    ---------------------                           |
---|    1.0             02-AUG-2007       Balaguru Seshadri  Initial Version                                 |
---|                                                                                                        |
---+========================================================================================================+
create or replace function apps.xx_ar_remitaddr_fmt (siteuseid in number,
                                          def_country in char,
                                          def_country_desc in char 
                                         ) 
                                     return char as

    remit_to_address_id         number;
    string            varchar2(1000);        
    address_style         varchar2(30);
    address1            varchar2(240);
    address2            varchar2(240);
    address3            varchar2(240);
    address4            varchar2(240);
    city            varchar2(60);
    county            varchar2(60);
    state            varchar2(60);
    province            varchar2(60);
    postal_code            varchar2(60);
    territory_short_name    varchar2(80);
    country_code        varchar2(60);
    customer_name        varchar2(100);
    bill_to_location            varchar2(40);
    first_name            varchar2(50);
    last_name            varchar2(50);
    mail_stop            varchar2(60);
    default_country_code    varchar2(60);
    default_country_desc    varchar2(80);
    print_home_country_flag    varchar2(5);
    print_default_attn_flag    varchar2(5);
    width            number(3);
    height_min            number(3);
    height_max            number(3);

begin

    remit_to_address_id := derive_remit_to_address_id(siteuseid);

    DBMS_OUTPUT.PUT_LINE('Remit to address id: '||to_char(remit_to_address_id));

    select loc.address1, loc.address2, loc.address3, 
           loc.address4, loc.city, loc.state,
           loc.postal_code, loc.country, t.territory_short_name
      into address1, address2, address3, address4, city, state,
           postal_code, country_code, territory_short_name
      from hz_cust_acct_sites a,
           hz_party_sites party_site,
           hz_locations loc,
           fnd_territories_vl t
     where a.cust_acct_site_id = remit_to_address_id
       and a.party_site_id = party_site.party_site_id
       and loc.location_id = party_site.location_id
       and loc.country    = t.territory_code(+);
  
    address_style        := null;
    county            := null;
    province            := null;
    customer_name        := null;
    bill_to_location            := null;
    first_name            := null;
    last_name            := null;
    mail_stop            := null;
    default_country_code    :=def_country;
    default_country_desc    :=def_country_desc;
    print_home_country_flag     := 'y';
    print_default_attn_flag     := 'n';

    width            := 50;
    height_min            := 8;
    height_max            := 8;


    string := arp_addr_label_pkg.format_address(
    address_style,
    address1, address2, address3, address4,
    city, county, state, province, postal_code,
    territory_short_name, 
    country_code, customer_name, bill_to_location,
    first_name, last_name, mail_stop,
    default_country_code, default_country_desc,
    print_home_country_flag, print_default_attn_flag,
    width, height_min, height_max );


    return( string );

end xx_ar_remitaddr_fmt;
/