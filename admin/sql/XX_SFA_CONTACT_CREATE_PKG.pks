--SET SHOW        OFF;
--SET VERIFY      OFF;
--SET ECHO        OFF;
--SET TAB         OFF;
--SET FEEDBACK    OFF;
--WHENEVER SQLERROR CONTINUE;
--WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_SFA_CONTACT_CREATE_PKG
AS
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |                      Oracle NAIO Consulting Organization                                |
-- +=========================================================================================+
-- | Name   : XX_SFA_CONTACT_CREATE_PKG                                                      |
-- | Description      : Package Body containing procedure to create org contact              |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date         Author              Remarks                                      |
-- |=======    ==========   =============       ========================                     |
-- |DRAFT 1A   21-DEC-2009  Anirban Chaudhuri   Initial draft version                        |
-- +=========================================================================================+

-- | Subversion Info:

-- |

-- |   $HeadURL$

-- |       $Rev$

-- |      $Date$

-- |

-- Declare a Exception used globally
-- invalid_contact_roles_exp  EXCEPTION;
-- invalid_contact_assoc_exp  EXCEPTION;

invalid_create_person_exp     EXCEPTION;
invalid_create_org_exp        EXCEPTION;
invalid_contact_points_exp    EXCEPTION;

invalid_update_person_exp     EXCEPTION;
invalid_update_org_exp        EXCEPTION;
invalid_update_cpoints_exp    EXCEPTION;

invalid_create_Sales_per_exp  EXCEPTION;
invalid_create_Sales_org_exp  EXCEPTION;
invalid_Sales_cpoints_exp     EXCEPTION;

invalid_update_Sales_per_exp  EXCEPTION;
invalid_update_Sales_org_exp  EXCEPTION;
invalid_upd_Sales_cpoints_exp EXCEPTION;

invalid_email_add_exp         EXCEPTION;


--This Function will be used to create org AP contact.
PROCEDURE Create_Org_APContact (
    p_person_pre_name_adjunct    IN VARCHAR2,
    p_person_first_name          IN VARCHAR2,
    p_person_middle_name         IN VARCHAR2,
    p_person_last_name           IN VARCHAR2,
    p_email_address              IN VARCHAR2,
    p_phone_country_code         IN VARCHAR2,
    p_phone_area_code            IN VARCHAR2,
    p_phone_number               IN VARCHAR2,
    p_phone_extension            IN VARCHAR2,
    p_fax_country_code           IN VARCHAR2,
    p_fax_area_code              IN VARCHAR2,
    p_fax_number                 IN VARCHAR2,
    p_party_id                   IN NUMBER,
    p_party_site_id              IN NUMBER,
    x_org_contact_id             OUT NUMBER,
    x_return_status              IN OUT NOCOPY   VARCHAR2,
    x_msg_count                  OUT    NOCOPY   NUMBER,
    x_msg_data                   OUT    NOCOPY   VARCHAR2 );

--This Function will be used to create org Sales contact.
PROCEDURE Create_Org_SalesContact (
    p_person_pre_name_adjunct    IN VARCHAR2,
    p_person_first_name          IN VARCHAR2,
    p_person_middle_name         IN VARCHAR2,
    p_person_last_name           IN VARCHAR2,
    p_email_address              IN VARCHAR2,
    p_phone_country_code         IN VARCHAR2,
    p_phone_area_code            IN VARCHAR2,
    p_phone_number               IN VARCHAR2,
    p_phone_extension            IN VARCHAR2,
    p_fax_country_code           IN VARCHAR2,
    p_fax_area_code              IN VARCHAR2,
    p_fax_number                 IN VARCHAR2,
    p_party_id                   IN NUMBER,
    p_party_site_id              IN NUMBER,
    x_org_contact_id             OUT NUMBER,
    x_return_status              IN OUT NOCOPY   VARCHAR2,
    x_msg_count                  OUT    NOCOPY   NUMBER,
    x_msg_data                   OUT    NOCOPY   VARCHAR2 );

--This Function will be used to update org AP contact.
PROCEDURE Update_Org_APContact (
    p_person_pre_name_adjunct    IN VARCHAR2,
    p_person_first_name          IN VARCHAR2,
    p_person_middle_name         IN VARCHAR2,
    p_person_last_name           IN VARCHAR2,
    p_email_address              IN VARCHAR2,
    p_phone_country_code         IN VARCHAR2,
    p_phone_area_code            IN VARCHAR2,
    p_phone_number               IN VARCHAR2,
    p_phone_extension            IN VARCHAR2,
    p_fax_country_code           IN VARCHAR2,
    p_fax_area_code              IN VARCHAR2,
    p_fax_number                 IN VARCHAR2,
    p_party_id                   IN NUMBER,
    p_party_site_id              IN NUMBER,
    p_org_contact_id             IN VARCHAR2,
    x_return_status              IN OUT NOCOPY   VARCHAR2,
    x_msg_count                  OUT    NOCOPY   NUMBER,
    x_msg_data                   OUT    NOCOPY   VARCHAR2 );

--This Function will be used to update org Sales contact.
PROCEDURE Update_Org_SalesContact (
    p_person_pre_name_adjunct    IN VARCHAR2,
    p_person_first_name          IN VARCHAR2,
    p_person_middle_name         IN VARCHAR2,
    p_person_last_name           IN VARCHAR2,
    p_email_address              IN VARCHAR2,
    p_phone_country_code         IN VARCHAR2,
    p_phone_area_code            IN VARCHAR2,
    p_phone_number               IN VARCHAR2,
    p_phone_extension            IN VARCHAR2,
    p_fax_country_code           IN VARCHAR2,
    p_fax_area_code              IN VARCHAR2,
    p_fax_number                 IN VARCHAR2,
    p_party_id                   IN NUMBER,
    p_party_site_id              IN NUMBER,
    p_org_contact_id             IN VARCHAR2,
    x_return_status              IN OUT NOCOPY   VARCHAR2,
    x_msg_count                  OUT    NOCOPY   NUMBER,
    x_msg_data                   OUT    NOCOPY   VARCHAR2 );

END XX_SFA_CONTACT_CREATE_PKG;
/
--SHOW ERRORS;
--EXIT;
