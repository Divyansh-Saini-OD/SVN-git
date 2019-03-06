SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET SHOW OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_DPS_APPS_INIT_PKG
-- +===================================================================+
-- | Name  :    XX_DPS_CONF_REL_PKG                                    |
-- | Description      : This package is used to call the various       |
-- |                    procedures to do all necessary validations     |
-- |                    get the informaton needed for updating the     |
-- |                    sales order.                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |  1.0     23.03.07   Ganesan JV                                    |
-- +===================================================================+
AS 
      PROCEDURE DPS_APPS_INIT(
   			   p_user_name IN VARCHAR
			   ,p_resp_name IN VARCHAR
			   ,x_status   OUT VARCHAR
			   ,x_message   OUT VARCHAR
			  )
AS
-- +===================================================================+
-- | Name  : DPS_APPS_INIT                                             |
-- | Description   : This Procedure will be used Initialise the Apps   |
-- |                 			                               |
-- |                                                                   |
-- | Parameters :       p_user_name                                    |
-- |  			p_resp_name				       |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_return_status				       |
-- |                    ,x_message                                     |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


   	ln_responsibility_id       fnd_responsibility_tl.responsibility_id%TYPE;
	ln_application_id          fnd_responsibility_tl.application_id%TYPE;
	ln_user_id 		   fnd_user.user_id%TYPE;

	BEGIN

		x_status := 'Success';
		x_message := 'Success';

		-- Apps Initialisation

      		fnd_message.set_name ('XXOM', 'ODP_OM_DPS_INVALID_RESP_NAME');
		x_message := fnd_message.get;
	      
	        SELECT responsibility_id
	              ,application_id
	        INTO  ln_responsibility_id
          	      ,ln_application_id
	        FROM  fnd_responsibility_tl
	        WHERE responsibility_name = p_resp_name   
	        AND language ='US';
		
	        fnd_message.set_name ('XXOM', 'ODP_OM_DPS_INVALID_USER_NAME');
 	        x_message := fnd_message.get;
		
	        SELECT user_id
	        INTO ln_user_id
	        FROM fnd_user
		WHERE user_name = p_user_name; 
		
	        fnd_message.set_name ('XXOM', 'ODP_OM_DPS_APPSINT_FAILED');
	        x_message := fnd_message.get;
	        fnd_global.apps_initialize (ln_user_id
	                                    ,ln_responsibility_id
	                                    ,ln_application_id
                                           );
		x_message := 'Successfully initiated';
		
							
	EXCEPTION
		WHEN OTHERS 
		THEN
		    x_status := 'Failure';                              
	END DPS_APPS_INIT;
END XX_OM_DPS_APPS_INIT_PKG;
/
SHOW ERROR
