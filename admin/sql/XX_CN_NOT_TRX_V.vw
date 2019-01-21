-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        : XX_CN_NOT_TRX_V.vw                                  |
-- | Rice ID     : E1004A_CustomCollections_(TableDesign)              |
-- | Description : XX_CN_NOT_TRX Table - Multi Org View Creation Script|
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======  ===========  =============    ============================|
-- |Draft 1a 03-Oct-2007  Vidhya Valantina Initial draft version       |
-- |1.0      04-Oct-2007  Vidhya Valantina Baselined after testing     |
-- |                                                                   |
-- +===================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

PROMPT
PROMPT Creating or Replacing View XX_CN_NOT_TRX_V....
PROMPT

CREATE OR REPLACE VIEW xx_cn_not_trx_v (
       not_trx_id
      ,row_id
      ,org_id
      ,notified_date
      ,process_audit_id
      ,batch_id
      ,last_extracted_date
      ,extracted_flag
      ,event_id
      ,source_doc_type
      ,source_trx_id
      ,source_trx_line_id
      ,processed_date
      ,request_id
      ,program_application_id
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      )
AS
SELECT XCNT.not_trx_id
      ,XCNT.row_id
      ,XCNT.org_id
      ,XCNT.notified_date
      ,XCNT.process_audit_id
      ,XCNT.batch_id
      ,XCNT.last_extracted_date
      ,XCNT.extracted_flag
      ,XCNT.event_id
      ,XCNT.source_doc_type
      ,XCNT.source_trx_id
      ,XCNT.source_trx_line_id
      ,XCNT.processed_date
      ,XCNT.request_id
      ,XCNT.program_application_id
      ,XCNT.created_by
      ,XCNT.creation_date
      ,XCNT.last_updated_by
      ,XCNT.last_update_date
      ,XCNT.last_update_login
FROM   xx_cn_not_trx              XCNT
WHERE  NVL( XCNT.org_id
           ,NVL( TO_NUMBER( DECODE( SUBSTRB(USERENV('CLIENT_INFO'),1,1) , ' '
                                   ,NULL, SUBSTRB(USERENV('CLIENT_INFO'),1,10) ) )
                ,-99) ) = NVL( TO_NUMBER( DECODE( SUBSTRB(USERENV('CLIENT_INFO'),1,1), ' '
                                                 ,NULL, SUBSTRB(USERENV('CLIENT_INFO'),1,10) ) )
                              ,-99 );
/
SHOW ERRORS;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
