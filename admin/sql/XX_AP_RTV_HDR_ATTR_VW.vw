SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_AP_RTV_HDR_ATTR_VW.vw                                                     |
-- | Description : Scripts to create Editioned Views and synonym for object XX_AP_RTV_HDR_ATTR  |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- | V1.0     01-10-2018        Havish Kasina        Initial version       			|
-- | V2.0     11-13-2018   	Arun DSouza          Touched to increment version in SVN for ITG|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_AP_RTV_HDR_ATTR .....
PROMPT **Edition View creates as XX_AP_RTV_HDR_ATTR# in XXFIN schema**
PROMPT **Synonym creates as XX_AP_RTV_HDR_ATTR in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN', 'XX_AP_RTV_HDR_ATTR'); 

SHOW ERRORS;
EXIT;