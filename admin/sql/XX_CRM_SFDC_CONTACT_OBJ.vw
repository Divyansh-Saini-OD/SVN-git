WHENEVER SQLERROR EXIT FAILURE

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_CRM_CONTACT_OBJ.sql                                    |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- +==========================================================================+

prompt Create xx_crm_sfdc_contact_obj...
create or replace type XX_CRM_SFDC_CONTACT_OBJ as object
                     (party_id              number, 
                      sfdc_account_osr      varchar2(255),
                      sfdc_message_version  number,
                      contact_objs          xx_crm_contact_obj_tbl,
    constructor function XX_CRM_SFDC_CONTACT_OBJ
      return self as result);
/
show err


prompt Create xx_crm_sfdc_contact_obj BODY...
create or replace type body XX_CRM_SFDC_CONTACT_OBJ as
    constructor function XX_CRM_SFDC_CONTACT_OBJ
        return self as result as
    begin
      contact_objs := xx_crm_contact_obj_tbl();
      return;
    end XX_CRM_SFDC_CONTACT_OBJ;
end;
/
show errors
