CREATE OR REPLACE VIEW XX_FIN_BILLTO_ADDRESSES_V AS
SELECT   csu.site_use_id,
         NVL2(address_lines_phonetic, address_lines_phonetic
         || ', ', '')
         || SUBSTR(hzl.address1, 1, 25)
         || ', '
         || NVL2(hzl.address2,SUBSTR(hzl.address2, 1, 25)
         || ', ','')
         || NVL2(hzl.address3,SUBSTR(hzl.address3, 1, 25)
         || ', ','')
         || NVL2(hzl.address4,SUBSTR(hzl.address4, 1, 25)
         || ', ','')
         || NVL2(hzl.city,hzl.city
         || ', ','')
         || NVL(hzl.state, hzl.province)
         || '  '
         || NVL2(hzl.postal_code,DECODE(LENGTH(hzl.postal_code),9,SUBSTR(hzl.postal_code,1,5)
         || '-'
         || SUBSTR(hzl.postal_code,6),hzl.postal_code)
         || ', ','')
         || hzl.country address,
         csu.location,
         csu.site_use_code,
         cas.ORIG_SYSTEM_REFERENCE,
         hps.IDENTIFYING_ADDRESS_FLAG,
         cas.bill_to_flag
from     hz_cust_site_uses      csu
       , hz_cust_acct_sites     cas
       , hz_party_sites         hps
       , hz_locations           hzl
where  csu.cust_acct_site_id = cas.cust_acct_site_id
AND    csu.site_use_code     = 'BILL_TO'
AND    csu.status = 'A'
AND    cas.party_site_id     = hps.party_site_id
AND    cas.bill_to_flag      = 'P'
AND    cas.status = 'A'
AND    hps.status = 'A'
and    hps.location_id       = hzl.location_id
;
/
SHOW ERRORS;
EXIT;
