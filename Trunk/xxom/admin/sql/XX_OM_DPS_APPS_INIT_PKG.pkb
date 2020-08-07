SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET SHOW OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_DPS_APPS_INIT_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name  :    XX_OM_DPS_APPS_INIT_PKG                                |
-- | Description      : This package contains procedure                |
-- |                    to initialise Apps.                            |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |  1.0     23-Mar-07   Ganesan JV       Initial Version             |
-- +===================================================================+
AS 
   gc_exception_header    xx_om_global_exceptions.exception_header%TYPE   :=  'OTHERS';
   gc_track_code          xx_om_global_exceptions.track_code%TYPE         :=  'OTC';
   gc_solution_domain     xx_om_global_exceptions.solution_domain%TYPE    :=  'External Fulfillment';

      PROCEDURE DPS_APPS_INIT(
                               p_user_name IN  VARCHAR
                              ,p_resp_name IN  VARCHAR
                              ,x_status    OUT VARCHAR
                              ,x_message   OUT VARCHAR
                          )
AS
-- +===================================================================+
-- | Name  : DPS_APPS_INIT                                             |
-- | Description   : This Procedure will be used to initialise the Apps|
-- |                                                                   |
-- | Parameters :       p_user_name                                    |
-- |                    p_resp_name                                    |
-- |                                                                   |
-- | Returns :          x_return_status                                |
-- |                    x_message                                      |
-- |                                                                   |
-- +===================================================================+


        ln_responsibility_id       fnd_responsibility_tl.responsibility_id%TYPE;
        ln_application_id          fnd_responsibility_tl.application_id%TYPE;
        ln_user_id                 fnd_user.user_id%TYPE;
        lc_err_desc                xxom.xx_om_global_exceptions.description%TYPE DEFAULT 'OTHERS';
        lc_entity_ref              xxom.xx_om_global_exceptions.entity_ref%TYPE;
        lc_entity_ref_id           xxom.xx_om_global_exceptions.entity_ref_id%TYPE;
        lc_err_code                xxom.xx_om_global_exceptions.error_code%TYPE;
        lc_function                VARCHAR2(100) :=  'I1153_DPSJobConfirmationInbound';
        lr_rep_exp_type            xxom.XX_OM_REPORT_EXCEPTION_T;
        lc_err_buf                  VARCHAR2 (1000);
        lc_ret_code                 VARCHAR2 (40);


        BEGIN

                x_status := 'S';
                x_message := 'Success';

                -- Apps Initialization

                FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_DPS_INVALID_RESP_NAME');
                x_message := FND_MESSAGE.GET;
              
                SELECT responsibility_id
                      ,application_id
                INTO  ln_responsibility_id
                      ,ln_application_id
                FROM  fnd_responsibility_tl
                WHERE responsibility_name = p_resp_name   
                AND language = USERENV('LANG');
                
                FND_MESSAGE.SET_NAME('XXOM', 'ODP_OM_DPS_INVALID_USER_NAME');
                x_message := FND_MESSAGE.GET;
                
                SELECT user_id
                INTO ln_user_id
                FROM fnd_user
                WHERE user_name = p_user_name; 
                
                FND_MESSAGE.SET_NAME('XXOM', 'ODP_OM_DPS_APPSINT_FAILED');
                lc_err_code := 'ODP_OM_DPS_APPSINT_FAILED';
                lc_err_desc := FND_MESSAGE.GET;
                lc_entity_ref := 'User ID';
                lc_entity_ref_id := TO_CHAR(ln_user_id);
                x_message := FND_MESSAGE.GET;
                FND_GLOBAL.APPS_INITIALIZE (
                                             ln_user_id
                                            ,ln_responsibility_id
                                            ,ln_application_id
                                           );
                x_message := 'Successfully initialized Apps';
                
                                                        
        EXCEPTION
                WHEN OTHERS 
                THEN
                    lr_rep_exp_type :=
                                 XX_OM_REPORT_EXCEPTION_T (
                                                            gc_exception_header              
                                                           ,gc_track_code                    
                                                           ,gc_solution_domain               
                                                           ,lc_function                      
                                                           ,lc_err_code
                                                           ,SUBSTR(lc_err_desc,1,1000)
                                                           ,lc_entity_ref
                                                           ,NVL(lc_entity_ref_id,0)
                                                          );
                   XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
		                                                lr_rep_exp_type
                                                               ,lc_err_buf
                                                               ,lc_ret_code
                                                             );
                    x_status := 'E';                              
        END DPS_APPS_INIT;
END XX_OM_DPS_APPS_INIT_PKG;
/
SHOW ERROR
