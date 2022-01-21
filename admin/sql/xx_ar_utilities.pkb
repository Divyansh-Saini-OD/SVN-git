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
create or replace package body APPS.XX_AR_UTILITIES_PKG as

FUNCTION get_field (v_delimiter IN VARCHAR2, n_field_no IN NUMBER ,v_line_read IN VARCHAR2 ) RETURN VARCHAR2 IS
   n_start_field_pos NUMBER;
   n_end_field_pos   NUMBER;
   v_get_field       VARCHAR2(2000);
 BEGIN
   IF n_field_no = 1 THEN
      n_start_field_pos := 1;
   ELSE
      n_start_field_pos := INSTR(v_line_read,v_delimiter,1,n_field_no-1)+1;
   END IF;
  
   n_end_field_pos   := INSTR(v_line_read,v_delimiter,1,n_field_no) -1;
   IF n_end_field_pos > 0 THEN
      v_get_field := SUBSTR(v_line_read,n_start_field_pos,(n_end_field_pos - n_start_field_pos)+1);
   ELSE
      v_get_field := SUBSTR(v_line_read,n_start_field_pos); 
   END IF;

   RETURN v_get_field;

 EXCEPTION
  WHEN OTHERS THEN
   Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'XXOD_GENERIC_TOOLS.get field: '||sqlerrm);
 END get_field;

FUNCTION get_remitaddressid (p_bill_to_site_use_id IN NUMBER)
  RETURN NUMBER IS

  CURSOR  remit_derive( inv_country     IN varchar2, 
                      inv_state     IN varchar2 , 
                      inv_postal_code     IN varchar2) IS

SELECT rt.address_id
  FROM hz_cust_acct_sites    a,
       hz_party_sites party_site,
       hz_locations loc,
       ra_remit_tos     rt
 WHERE a.cust_acct_site_id = rt.address_id
   AND a.party_site_id = party_site.party_site_id
   AND loc.location_id = party_site.location_id
   AND nvl(rt.status,'A') = 'A'
   AND nvl(a.status, 'A') = 'A'
   AND (nvl(rt.state, inv_state)= inv_state
        OR
        (inv_state IS NULL AND
         rt.state  IS NULL))
   AND ((inv_postal_code between
                rt.postal_code_low and rt.postal_code_high)
        OR
        (rt.postal_code_high IS NULL and rt.postal_code_low IS NULL))
   AND rt.country = inv_country
ORDER BY rt.postal_code_low, 
         rt.postal_code_high, 
         rt.state,
         loc.address1, 
         loc.address2;



CURSOR  address( bill_site_use_id IN number ) is
        SELECT loc.state, 
               loc.country,
               loc.postal_code
        FROM hz_cust_acct_sites a,
         hz_party_sites party_site,
             hz_locations loc,
             hz_cust_site_uses     s    
        WHERE a.cust_acct_site_id  = s.cust_acct_site_id
        AND   a.party_site_id = party_site.party_site_id
        AND   loc.location_id = party_site.location_id
        AND   s.site_use_id = bill_site_use_id;
 
        inv_state         hz_locations.state%type;
        inv_country         hz_locations.country%type;
        inv_postal_code     hz_locations.postal_code%type;
        remit_address_id     hz_cust_acct_sites.cust_acct_site_id%type;
        d             varchar2(240);

BEGIN

    OPEN address( p_bill_to_site_use_id );
    FETCH address into inv_state, 
                       inv_country,
                       inv_postal_code;


    IF address%NOTFOUND

    THEN

       /* No Default Remit to Address can be found, use the default */    
  
       inv_state := 'DEFAULT';
       inv_country := 'DEFAULT';
       inv_postal_code := null;

    END IF;

    CLOSE address;

    OPEN remit_derive( inv_country, inv_state, inv_postal_code );
    FETCH remit_derive into remit_address_id;


    IF remit_derive%NOTFOUND

    THEN

       CLOSE remit_derive;
       OPEN remit_derive( 'DEFAULT', inv_state, inv_postal_code );
       FETCH remit_derive into remit_address_id;

       IF remit_derive%NOTFOUND

       THEN

          CLOSE remit_derive;
          OPEN remit_derive( 'DEFAULT', inv_state, '' );
          FETCH remit_derive into remit_address_id;

          IF remit_derive%notfound

          THEN

             CLOSE remit_derive;
             OPEN remit_derive( 'DEFAULT', 'DEFAULT', '' );
             FETCH remit_derive into remit_address_id;

          END IF;

       END IF;

   END IF; 

   CLOSE remit_derive;
   RETURN( remit_address_id );

END get_remitaddressid;
function addr_fmt (siteuseid in number,
                                          def_country in char,
                                          def_country_desc in char,
                                          addr_type in char
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
 IF addr_type ='REMIT' THEN
    remit_to_address_id := xx_ar_utilities_pkg.get_remitaddressid(siteuseid);

    --DBMS_OUTPUT.PUT_LINE('Remit to address id: '||to_char(remit_to_address_id));

    select loc.address1, loc.address2, loc.address3, 
           loc.address4, loc.city, loc.state, loc.province,
           loc.postal_code, loc.country, t.territory_short_name
      into address1, address2, address3, address4, city, state, province,
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
    /* 
    
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
    */      
    IF def_country='US' THEN 
     return(address1||'|'||address2||'|'||city||', '||state||' '||postal_code);
    ELSIF def_country='CA' THEN
     return(address1||'|'||address2||'|'||city||' '||province||' '||postal_code||'|CANADA');
    ELSE
     return('');     
    END IF;
 ELSIF addr_type ='BILL-TO' THEN
     address1 :=TO_CHAR(NULL);
     address2 :=TO_CHAR(NULL);
     city :=TO_CHAR(NULL);
     state :=TO_CHAR(NULL);
     postal_code :=TO_CHAR(NULL); 
     province :=TO_CHAR(NULL);
     begin      
       select loc.address1, loc.address2, loc.city, loc.state, loc.postal_code, loc.province
       into address1, address2, city, state, postal_code, province
        from hz_cust_acct_sites a,
             hz_party_sites party_site,
             hz_locations loc,
             hz_cust_site_uses sites
       where sites.site_use_id =siteuseid
         and a.cust_acct_site_id = sites.cust_acct_site_id
         and a.party_site_id = party_site.party_site_id
         and loc.location_id = party_site.location_id;
   IF def_country='US' THEN 
     return(address1||'|'||address2||'|'||city||', '||state||' '||postal_code);
    ELSIF def_country='CA' THEN
     return(address1||'|'||address2||'|'||city||' '||province||' '||postal_code||'|CANADA');
    ELSE
     return('');     
    END IF;
     exception
      when no_data_found then
       return('');
      when others then
        return('');
     end;
 ELSE
  RETURN('');
 END IF;    

end addr_fmt;
function get_period_receipts (consinv_id   in number
                                   ,cust_id in number
                                   ,siteuse_id   in number
                                   ) return number as
 n_period_receipts NUMBER(14,2);
begin
select NVL(SUM(arcit.amount_original),0) 
into n_period_receipts
from ar_cons_inv_trx arcit, ar_cons_inv arci
where arcit.cons_inv_id = consinv_id
  and arcit.transaction_type in
            ('RECEIPT',
             'RECEIPT REV',
             'XSITE RECREV',
             'XSITE RECAPP',
             'XCURR RECREV',
             'XCURR RECAPP',
             'XSITE XCURR RECREV',
             'XSITE XCURR RECAPP',
             'EXCLUDE RECREV',
             'EXCLUDE RECAPP'
            )
   and arci.cons_inv_id =arcit.cons_inv_id
   and arci.customer_id =cust_id
   and arci.site_use_id =siteuse_id;
   return (-1)*n_period_receipts;
exception
 when no_data_found then
  --dbms_output.put_line('error1'||sqlerrm);
  return 0.00;
 when others then
  --dbms_output.put_line('error2'||sqlerrm); 
  return 0.00;
end get_period_receipts;
function get_trx_amount (consinv_id in number
                                   ,cust_id     in number
                                   ,siteuse_id  in number
                                   ) return number as 
 trxamt NUMBER;                                    
begin                                   
 select nvl(sum(arcit.amount_original),0) 
 into trxamt        
 from ar_cons_inv_trx arcit, ar_payment_schedules ps, ar_cons_inv arci
 where arcit.cons_inv_id = arci.cons_inv_id
   and arcit.transaction_type in
          ('INVOICE',
           'CREDIT_MEMO',
           'ADJUSTMENT',
           'XSITE_CMREV',
           'XSITE_CMAPP',
           'EXCLUDE_CMREV',
           'EXCLUDE_CMAPP'
          )
   and ps.payment_schedule_id(+) =
          decode (arcit.transaction_type,
                  'INVOICE', arcit.adj_ps_id,
                  'CREDIT_MEMO', arcit.adj_ps_id,
                  null
                 )
   and arci.cons_inv_id =consinv_id
   and arci.customer_id =cust_id
   and arci.site_use_id =siteuse_id; 
   return trxamt;                
exception
 when no_data_found then
   trxamt   :=0;
   return trxamt;
 when others then
   trxamt   :=0;
   return trxamt;   
end get_trx_amount;    
function get_tax_amount (consinv_id in number
                                   ,cust_id     in number
                                   ,siteuse_id  in number
                                   ) return number as 
 taxamt NUMBER;                                   
begin                                   
 select nvl(sum (arcit.tax_original),0)  
 into taxamt       
 from ar_cons_inv_trx arcit, ar_payment_schedules ps, ar_cons_inv arci
 where arcit.cons_inv_id = arci.cons_inv_id
   and arcit.transaction_type in
          ('INVOICE',
           'CREDIT_MEMO',
           'ADJUSTMENT',
           'XSITE_CMREV',
           'XSITE_CMAPP',
           'EXCLUDE_CMREV',
           'EXCLUDE_CMAPP'
          )
   and ps.payment_schedule_id(+) =
          decode (arcit.transaction_type,
                  'INVOICE', arcit.adj_ps_id,
                  'CREDIT_MEMO', arcit.adj_ps_id,
                  null
                 )
   and arci.cons_inv_id =consinv_id
   and arci.customer_id =cust_id
   and arci.site_use_id =siteuse_id;  
   return taxamt;               
exception
 when no_data_found then
   taxamt   :=0; 
   return taxamt;   
 when others then
   taxamt   :=0; 
   return taxamt;   
end get_tax_amount;
function get_gross_amount (consinv_id in number
                                   ,cust_id     in number
                                   ,siteuse_id  in number
                                   ) return number as 
 grossamt NUMBER;                                   
begin                                   
 select nvl(sum(arcit.amount_original),0) - nvl(sum(arcit.tax_original), 0)  
 into grossamt        
 from ar_cons_inv_trx arcit, ar_payment_schedules ps, ar_cons_inv arci
 where arcit.cons_inv_id = arci.cons_inv_id
   and arcit.transaction_type in
          ('INVOICE',
           'CREDIT_MEMO',
           'ADJUSTMENT',
           'XSITE_CMREV',
           'XSITE_CMAPP',
           'EXCLUDE_CMREV',
           'EXCLUDE_CMAPP'
          )
   and ps.payment_schedule_id(+) =
          decode (arcit.transaction_type,
                  'INVOICE', arcit.adj_ps_id,
                  'CREDIT_MEMO', arcit.adj_ps_id,
                  null
                 )
   and arci.cons_inv_id =consinv_id
   and arci.customer_id =cust_id
   and arci.site_use_id =siteuse_id; 
   return grossamt;                
exception
 when no_data_found then
   grossamt :=0; 
   return grossamt;
 when others then   
   grossamt :=0;
   return grossamt;   
end get_gross_amount;
end XX_AR_UTILITIES_PKG;
/