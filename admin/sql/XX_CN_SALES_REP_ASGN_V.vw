-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        : XX_CN_SALES_REP_ASGN_V.vw                           |
-- | Rice ID     : E1004A_CustomCollections_(TableDesign)              |
-- | Description : XX_CN_SALES_REP_ASGN Table - Multi Org View Creation|
-- |               Script                                              |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======  ===========  =============    ============================|
-- |Draft 1a 03-Oct-2007  Vidhya Valantina Initial draft version       |
-- |1.0      04-Oct-2007  Vidhya Valantina Baselined after testing     |
-- |1.1      18-Oct-2007  Sarah Justina    Changed view definition to  |
-- |                                       reflect table changes       |
-- |1.2      07-Nov-2007  Vidhya Valantina Changes due to addition of  |
-- |                                       new column 'Party_Site_Id'  |
-- |                                       in the Extract Tables.      |
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
PROMPT Creating or Replacing View XX_CN_SALES_REP_ASGN_V....
PROMPT

CREATE OR REPLACE VIEW xx_cn_sales_rep_asgn_v (
       sales_rep_asgn_id
      ,org_id
      ,ship_to_address_id
      ,party_site_id       -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 07-Nov-2007
      ,rollup_date
      ,division
      ,named_acct_terr_id
      ,resource_id
      ,resource_org_id
      ,salesrep_id
      ,employee_number
      ,salesrep_division
      ,resource_role_id
      ,group_id
      ,revenue_type
      ,start_date_active
      ,end_date_active
      ,comments
      ,obsolete_flag
      ,batch_id
      ,process_audit_id
      ,request_id
      ,program_application_id
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      )
AS
SELECT XCSRA.sales_rep_asgn_id
      ,XCSRA.org_id
      ,XCSRA.ship_to_address_id
      ,XCSRA.party_site_id       -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 07-Nov-2007
      ,XCSRA.rollup_date
      ,XCSRA.division
      ,XCSRA.named_acct_terr_id
      ,XCSRA.resource_id
      ,XCSRA.resource_org_id
      ,XCSRA.salesrep_id
      ,XCSRA.employee_number
      ,XCSRA.salesrep_division
      ,XCSRA.resource_role_id
      ,XCSRA.group_id
      ,XCSRA.revenue_type
      ,XCSRA.start_date_active
      ,XCSRA.end_date_active
      ,XCSRA.comments
      ,XCSRA.obsolete_flag
      ,XCSRA.batch_id
      ,XCSRA.process_audit_id
      ,XCSRA.request_id
      ,XCSRA.program_application_id
      ,XCSRA.created_by
      ,XCSRA.creation_date
      ,XCSRA.last_updated_by
      ,XCSRA.last_update_date
      ,XCSRA.last_update_login
FROM   xx_cn_sales_rep_asgn            XCSRA
WHERE  NVL( XCSRA.org_id
           ,NVL( TO_NUMBER( DECODE( SUBSTRB(USERENV('CLIENT_INFO'),1,1) , ' '
                                   ,NULL, SUBSTRB(USERENV('CLIENT_INFO'),1,10) ) )
                ,-99) ) = NVL( TO_NUMBER( DECODE( SUBSTRB(USERENV('CLIENT_INFO'),1,1), ' '
                                                 ,NULL, SUBSTRB(USERENV('CLIENT_INFO'),1,10) ) )
                              ,-99 );
/
SHOW ERRORS;

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
