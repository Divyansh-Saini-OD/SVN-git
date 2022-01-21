CREATE OR REPLACE PROCEDURE XX_UPDATE_SITE_ATTR( p_extension_id IN NUMBER,
                                                 p_cust_doc_id  IN NUMBER)

AS

BEGIN

 UPDATE xxcrm.xx_cdh_acct_site_ext_b
 SET    N_EXT_ATTR1 =p_cust_doc_id
 WHERE  extension_id=p_extension_id
 AND    ATTR_GROUP_ID=173;

 COMMIT;

END XX_UPDATE_SITE_ATTR;
/