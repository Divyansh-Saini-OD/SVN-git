WHENEVER SQLERROR EXIT FAILURE

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  DROP_XX_CRM_CONTACT_OBJ_32267.vw                          |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |   $HeadURL: $
-- |       $Rev: $
-- |      $Date: $
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- +==========================================================================+

prompt Dropping XX_CRM_SFDC_CONTACT_OBJ...

drop type "APPS"."XX_CRM_SFDC_CONTACT_OBJ"
/
show err


prompt Dropping XX_CRM_CONTACT_OBJ_TBL...

drop type "APPS"."XX_CRM_CONTACT_OBJ_TBL"
/
show err


prompt Dropping XX_CRM_CONTACT_OBJ...

drop type "APPS"."XX_CRM_CONTACT_OBJ"
/
show err


