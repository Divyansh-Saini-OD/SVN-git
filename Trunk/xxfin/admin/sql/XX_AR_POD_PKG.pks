create or replace
PACKAGE XX_AR_POD_PKG AS

/******************************************************************************
   NAME:       APPS.XX_AR_POD_PKG
   EXTENTION:  E0059_ExternalLinkToPOD
   PURPOSE:    Verify permission, and lookup info needed to retrieve POD from SigCap
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        4/9/2007    Bushrod Thomas   1. Created this package.
   2.0        1/3/2014    Sridevi K        For defect 28643

******************************************************************************/

  PROCEDURE LOG_ERROR (
     p_message_name        IN  VARCHAR2
    ,p_user_id             IN  VARCHAR2
    ,p_location            IN  VARCHAR2
    ,p_invoice             IN  VARCHAR2
    ,p_severity            IN  VARCHAR2
    ,p_message             OUT  VARCHAR2
  );

  PROCEDURE VALIDATE_POD_AUTH (
      p_user_id            IN  VARCHAR2,
      p_auth               OUT VARCHAR2
  );

  PROCEDURE GET_ORDER_INFO (
      p_invoice            IN  VARCHAR2,
      p_spcnum             OUT VARCHAR2,
      p_docref             OUT VARCHAR2
  );

  FUNCTION USER_HAS_RESP(
      p_user_id            IN  NUMBER, 
      p_responsibility_key IN  VARCHAR2
  ) RETURN VARCHAR2;

/* Added for Defect 28643 */
PROCEDURE GET_PODURL(
    p_devurl OUT VARCHAR2,
    p_url OUT VARCHAR2,
    p_errormsg OUT VARCHAR2 );

END XX_AR_POD_PKG;
/


