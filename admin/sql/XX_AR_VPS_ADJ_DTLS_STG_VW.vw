SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===============================================================================================+
-- |                                     Office Depot                                              |
-- +===============================================================================================+
-- | Name        : XX_AR_VPS_ADJ_DTLS_STG_VW.vw                                            		   |
-- | Description : Scripts to create Editioned Views and synonym for object XX_AR_VPS_ADJ_DTLS_STG |
-- |                                                                                               |
-- |Change Record:                                                                                 |
-- |===============                                                                                |
-- |Version    Date             Author               Remarks                                       |
-- |=======    ===========      ================     ==============================================|
-- | V1.0      28-JUN-2018   	Havish Kasina        Initial version               				   |
-- +===============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_AR_VPS_ADJ_DTLS_STG .....
PROMPT **Edition View creates as XX_AR_VPS_ADJ_DTLS_STG# in XXFIN schema**
PROMPT **Synonym creates as XX_AR_VPS_ADJ_DTLS_STG in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN', 'XX_AR_VPS_ADJ_DTLS_STG'); 

SHOW ERRORS;
EXIT;