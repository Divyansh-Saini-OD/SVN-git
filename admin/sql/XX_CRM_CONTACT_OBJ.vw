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
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version    Date          Author                Remarks                    | 
-- |=======    ==========    =================    ============================+
-- |1.0        30-OCT-2014   Sridevi K            for Defect 32267            |
-- |                                              Added primary contact flag  |
-- +==========================================================================+

prompt Create xx_crm_contact_obj...
create or replace type XX_CRM_CONTACT_OBJ as object
                     (contact_role           varchar2(50),
                      salutation             varchar2(30),
                      first_name             varchar2(150),
                      last_name              varchar2(150),
                      job_title              varchar2(100),
                      email_address          varchar2(2000),
                      fax_number             varchar2(60),
                      phone_number           varchar2(60),
		      primary_contact_flag   varchar2(1),
    constructor function XX_CRM_CONTACT_OBJ
        return self as result);
/
show err


prompt Create xx_crm_contact_obj_tbl...
create or replace type XX_CRM_CONTACT_OBJ_TBL as table of XX_CRM_CONTACT_OBJ;
/
show err


prompt Create xx_crm_contact_obj BODY...
create or replace type body XX_CRM_CONTACT_OBJ as
    constructor function XX_CRM_CONTACT_OBJ
        return self as result as
    begin
      return;
    end XX_CRM_CONTACT_OBJ;
end;
/
show errors
