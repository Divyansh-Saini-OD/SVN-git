-- +===========================================================================+
-- |                              Office Depot                                 |
-- |                                                                           |
-- +===========================================================================+
-- | Name         : XX_DEFECT25498_DEL.sql                         |
-- | Rice Id      : DEFECT 25498                                               | 
-- | Description  :                                                            |  
-- | Purpose      : To remove personalizations and customizations referring    |
-- |                components under /od/oracle/apps/xxcrm/ar/hz               |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date          Author               Remarks                      | 
-- |=======    ==========    =================    =============================+
-- |1.0        26-SEP-2013   Sridevi K            Initial Version              |
-- |2.0        11-OCT-2013   Sridevi K            Included changes for         |
-- |                                              ITG Request 140352, 140276   |
-- +===========================================================================+
SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT SETTING CONTEXT XX_DEFECT25498_DEL.sql
PROMPT

begin
/*
dbms_output.put_line('print document /oracle/apps/ar/hz/extension/webui/customizations/site/0/HzExtEntryPagePG');
jdr_utils.printdocument('/oracle/apps/ar/hz/extension/webui/customizations/site/0/HzExtEntryPagePG');
*/

dbms_output.put_line('delete document /oracle/apps/ar/hz/extension/webui/customizations/site/0/HzExtEntryPagePG');
jdr_utils.deletedocument('/oracle/apps/ar/hz/extension/webui/customizations/site/0/HzExtEntryPagePG');
/**********************************************************************************************************************/
dbms_output.put_line('/oracle/apps/ar/hz/components/address/webui/HzPuiAddressCreateUpdate');
dbms_output.put_line('deleting doc /oracle/apps/ar/hz/components/address/webui/HzPuiAddressCreateUpdate');
jdr_utils.deletedocument('/oracle/apps/ar/hz/components/address/webui/customizations/site/0/HzPuiAddressCreateUpdate');

dbms_output.put_line('deleting doc /oracle/apps/ar/hz/components/address/server/customizations/site/0/HzPuiAddressTableVO');
/*jdr_utils.printdocument('/oracle/apps/ar/hz/components/address/server/customizations/site/0/HzPuiAddressTableVO');*/
jdr_utils.deletedocument('/oracle/apps/ar/hz/components/address/server/customizations/site/0/HzPuiAddressTableVO');

dbms_output.put_line('deleting doc /od/oracle/apps/ar/hz/components/address/server/customizations/site/0/HzPuiPartySiteVO');
/*jdr_utils.printdocument('/od/oracle/apps/ar/hz/components/address/server/customizations/site/0/HzPuiPartySiteVO');*/
//jdr_utils.deletedocument('/od/oracle/apps/ar/hz/components/address/server/customizations/site/0/HzPuiPartySiteVO');
jdr_utils.deletedocument('/oracle/apps/ar/hz/components/address/server/customizations/site/0/HzPuiPartySiteVO');
/**********************************************************************************************************************/
dbms_output.put_line('deleting site level personalizations');
dbms_output.put_line('print document /oracle/apps/ar/hz/components/contactpoints/webui/customizations/site/0/HzPuiContactPointPhoneTable');
/*jdr_utils.printdocument('/oracle/apps/ar/hz/components/contactpoints/webui/customizations/site/0/HzPuiContactPointPhoneTable');*/
jdr_utils.deletedocument('/oracle/apps/ar/hz/components/contactpoints/webui/customizations/site/0/HzPuiContactPointPhoneTable');

/**********************************************************************************************************************/
dbms_output.put_line('print document /oracle/apps/ar/hz/components/extension/webui/customizations/site/0/HzPuiPartySiteExtRN');
/*jdr_utils.printdocument('/oracle/apps/ar/hz/components/extension/webui/customizations/site/0/HzPuiPartySiteExtRN');*/
jdr_utils.deletedocument('/oracle/apps/ar/hz/components/extension/webui/customizations/site/0/HzPuiPartySiteExtRN');


/* Added for ITG Request 140352 */
JDR_UTILS.deleteDocument('/oracle/apps/ar/hz/components/party/organization/webui/customizations/site/0/HzPuiOrgProfileQuickComponent'); 

/* Added for ITG Request 140276 */
JDR_UTILS.deleteDocument('/oracle/apps/ar/hz/components/party/organization/webui/customizations/function/ASN_ORGCREATEPG/HzPuiOrgProfileQuickComponent');

commit;
end;
/

SHOW ERR
