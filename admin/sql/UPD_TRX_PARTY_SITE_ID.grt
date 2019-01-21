-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        : UPD_TRX_PARTY_SITE_ID.sql                           |
-- | Rice ID     : E1004_Custom_Collections                            |
-- | Description : Updating the Party Site ID for Extract Tables       |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======  ===========  =============    ============================|
-- |Draft 1a 05-Nov-2007  Vidhya Valantina Initial draft version       |
-- |1.0      06-Nov-2007  Vidhya Valantina Baselined after testing     |
-- |                                                                   |
-- +===================================================================+

SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Updating the Table XX_CN_AR_TRX .....
PROMPT

UPDATE xx_cn_ar_trx  XCAT
SET    party_site_id = ( SELECT HCAS.party_site_id
                         FROM   hz_cust_acct_sites_all   HCAS
                         WHERE  HCAS.cust_acct_site_id = XCAT.ship_to_address_id );

PROMPT
PROMPT Updating the Table XX_CN_FAN_TRX .....
PROMPT

UPDATE xx_cn_fan_trx  XCFT
SET    party_site_id = ( SELECT HCAS.party_site_id
                         FROM   hz_cust_acct_sites_all   HCAS
                         WHERE  HCAS.cust_acct_site_id = XCFT.ship_to_address_id );

PROMPT
PROMPT Updating the Table XX_CN_OM_TRX .....
PROMPT

UPDATE xx_cn_om_trx  XCOT
SET    party_site_id = ( SELECT HCAS.party_site_id
                         FROM   hz_cust_acct_sites_all   HCAS
                         WHERE  HCAS.cust_acct_site_id = XCOT.ship_to_address_id );

PROMPT
PROMPT Updating the Table XX_CN_SALES_REP_ASGN .....
PROMPT

UPDATE xx_cn_sales_rep_asgn  XCSRA
SET    party_site_id = ( SELECT HCAS.party_site_id
                         FROM   hz_cust_acct_sites_all   HCAS
                         WHERE  HCAS.cust_acct_site_id = XCSRA.ship_to_address_id );

COMMIT;

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
