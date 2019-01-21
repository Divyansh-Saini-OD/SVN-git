SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE SPECIFICATION XX_CM_TRACK_LOG_WRAP_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_CM_TRACK_LOG_WRAP_PKG
AS
-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name        : XX_CM_TRACK_LOG_WRAP_PKG                                 |
-- | RICE ID     : R0472                                                    |
-- | Description : This package is the executable of the wrapper program    |
-- |               that is used for submitting the OD: CM Tracking Log      |
-- |               Report with the desirable format of the user, and the    |
-- |		   default format is EXCEL                                  |
-- |                                                                        |
-- | Change Record:                                                         |
-- | ==============                                                         |
-- | Version      Date          Author            Remarks                   |
-- | ========     =========     =============     ===============           |
-- | Draft 1A     09-APR-09     Trisha Saxena     Initial version           |
-- |                                                                        |
-- +========================================================================+

-- +========================================================================+
-- | Name        : XX_CM_TRACK_LOG_WRAP_PROC                                |
-- | Description : The procedure will submit the OD: CM Tracking Log Report |
-- |               in the specified format                                  |
-- | Parameters  : p_provider_code, p_credit_card_type, p_transmit_date_from|
-- |               , p_transmit_date_to                                     |  
-- | Returns     :  x_err_buff,x_ret_code                                   |
-- +========================================================================+

PROCEDURE XX_CM_TRACK_LOG_WRAP_PROC(x_err_buff             OUT VARCHAR2
                                    ,x_ret_code            OUT NUMBER
                  		    ,p_provider_code       IN  VARCHAR2
				    ,p_credit_card_type    IN  VARCHAR2
				    ,p_transmit_date_from  IN  VARCHAR2
				    ,p_transmit_date_to    IN  VARCHAR2
       				   );
END XX_CM_TRACK_LOG_WRAP_PKG;
/

SHO ERR 
