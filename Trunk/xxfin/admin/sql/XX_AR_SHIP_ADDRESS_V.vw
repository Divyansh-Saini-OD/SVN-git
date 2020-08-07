SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT Creating VIEW XX_AR_SHIP_ADDRESS_V

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

---+========================================================================================================+
---|                                        Office Depot - Project Simplify                                 |
---|                                                Office Depot                                            |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       XX_AR_SHIP_ADDRESS_V                                                |
---|                                                                                                        |
---|    Description             :       Used by iRec E1327 in Account Details page view objects             |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                    |
---|    ------------    ----------------- ---------------    ---------------------                          |
---|    1.0             23-JUL-2009       Bushrod Thomas     Initial Version                                |
---|    2.0             16-Dec-2014       Sreedhar Mohan     Modified for iRec Enhancement changes          |
---|                                                                                                        |
---+========================================================================================================+

CREATE OR REPLACE FORCE VIEW "APPS"."XX_AR_SHIP_ADDRESS_V" ("SITE_USE_ID", "ADDRESS")
AS
  SELECT su.site_use_id,
    NVL2(address_lines_phonetic, address_lines_phonetic
    || ', ', '')
    || SUBSTR(a_loc.address1, 1, 25)
    || ', '
    || NVL2(a_loc.address2,SUBSTR(a_loc.address2, 1, 25)
    || ', ','')
    || NVL2(a_loc.address3,SUBSTR(a_loc.address3, 1, 25)
    || ', ','')
    || NVL2(a_loc.address4,SUBSTR(a_loc.address4, 1, 25)
    || ', ','')
    || NVL2(a_loc.city,a_loc.city
    || ', ','')
    || NVL(a_loc.state, a_loc.province)
    || '  '
    || NVL2(a_loc.postal_code,DECODE(LENGTH(a_loc.postal_code),9,SUBSTR(a_loc.postal_code,1,5)
    || '-'
    || SUBSTR(a_loc.postal_code,6),a_loc.postal_code)
    || ', ','')
    || a_loc.country address
  FROM hz_cust_site_uses_all su,
    hz_cust_acct_sites_all a,
    hz_party_sites a_ps,
    hz_locations a_loc
  WHERE a.cust_acct_site_id = su.cust_acct_site_id
  AND a.party_site_id       = a_ps.party_site_id
  AND a_loc.location_id     = a_ps.location_id
  AND su.site_use_code      = 'SHIP_TO';

SHOW ERROR