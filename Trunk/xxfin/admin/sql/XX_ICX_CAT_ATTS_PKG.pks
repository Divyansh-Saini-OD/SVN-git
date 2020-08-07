CREATE OR REPLACE
PACKAGE XX_ICX_CAT_ATTS_PKG AS
/******************************************************************************
   NAME:       APPS.XX_ICX_CAT_ATTS_PKG
   EXTENTION:  E0991, E0978
   PURPOSE:    Maintain item category attributes for iProcurement.
   			   	Attributes include buyer and approver.
				Attributes are unique per organization. 

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        10/13/2006  Bushrod Thomas   1. Created this package.
******************************************************************************/

  PROCEDURE INSERT_ROW(
    p_org_id      IN NUMBER
   ,p_category_id IN NUMBER
   ,p_buyer_id    IN NUMBER
   ,p_approver_id IN NUMBER
   ,p_user_id     IN NUMBER := NULL
   ,p_login_id    IN NUMBER := NULL
  );

  PROCEDURE UPDATE_ROW(
    p_org_id      IN NUMBER
   ,p_category_id IN NUMBER
   ,p_buyer_id    IN NUMBER
   ,p_approver_id IN NUMBER
   ,p_user_id     IN NUMBER := NULL
   ,p_login_id    IN NUMBER := NULL
  );

  PROCEDURE DELETE_ROW (
    p_org_id      IN NUMBER
   ,p_category_id IN NUMBER
  );

  PROCEDURE LOAD_ROW(
    p_org_id        IN NUMBER
   ,p_category_id   IN NUMBER
   ,p_buyer_id      IN NUMBER
   ,p_approver_id   IN NUMBER
   ,p_user_id       IN NUMBER := NULL
   ,p_login_id      IN NUMBER := NULL
  );

  PROCEDURE LOAD_ROW(
    p_org_id        IN NUMBER
   ,p_category_id   IN NUMBER
   ,p_buyer_name    IN VARCHAR2
   ,p_approver_name IN VARCHAR2
   ,p_user_id       IN NUMBER := NULL
   ,p_login_id      IN NUMBER := NULL
  );

  PROCEDURE GET_PERSON_ID(
    p_employee_number_or_full_name IN     VARCHAR2
   ,x_person_id                    IN OUT VARCHAR2
  );
	
END XX_ICX_CAT_ATTS_PKG;

/
