SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;      
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE; 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE xx_om_global_exception_pkg AS

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                                                                     |
-- +=====================================================================+
-- | Name  : XX_OM_GLOBALEXCEPTION_PKG.PKS                               |
-- | Description      : This Package is used by all custome programs     |
-- |                     to insert exceptions into xx_om_global_         |
-- |                     exceptions.Once the errors are fixed it insert  |
-- |                     into xx_om_global_exceptions_out with released  |
-- |                     flag as Y                                       |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version    Date          Author           Remarks                    |
-- |=======    ==========    =============    ========================   |
-- |DRAFT 1A   06-MAR-2007   Bapuji          Initial draft version       |
-- |      1B   07-JUN-2007   Bapuji          changed to coding standards |
-- |                                                                     |
-- +=====================================================================+

 -- Global Varibales
G_err_buf VARCHAR2(240);
G_ret_code VARCHAR2(30);
G_exc_out         CLOB;
G_user_id         NUMBER := NVL(TO_NUMBER(FND_PROFILE.VALUE('USER_ID')),-1);

-- +=============================================================+
-- | Name  : INSERT_EXCEPTION                                    |
-- | Description: This Procedure will insert all the exceptions  |
-- |              generated by custom programs                   |
-- |                                                             |
-- | Parameters:  p_report_exception IN error msg capture by     |
-- |              object xx_om_report_eception_t                 |
-- | Return:      x_err_buf OUT Sucess or Failure to insert      |
-- |              x_ret_code OUT Message of sucess or failure    |
-- +=============================================================+

 PROCEDURE insert_exception  (
                 p_report_exception  IN xx_om_report_exception_t
               , x_err_buf          OUT NOCOPY VARCHAR2
               , x_ret_code         OUT NOCOPY VARCHAR2
               );

-- +=============================================================+
-- | Name  : GENERATE_XML                                        |
-- | Description: This Procedure will capture the errors inserted|
-- |              xx_om_global_exception in xml data format      |
-- |              and insert it into xx_om_global_exceptions_out |
-- |                                                             |
-- | Return:      x_err_buf OUT Sucess or Failure to insert      |
-- |              x_ret_code OUT Message of sucess or failure    |
-- +=============================================================+

PROCEDURE generate_xml (
                x_err_buf          OUT NOCOPY VARCHAR2
              , x_ret_code         OUT NOCOPY VARCHAR2
              );

END xx_om_global_exception_pkg;


/

SHOW ERRORS;
