SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_C2T_AJB_GetToken

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_C2T_AJB_GetToken AS 
-- +=====================================================================================================+
-- |                              Office Depot                                                           |
-- +=====================================================================================================+
-- |  Name:  XX_C2T_AJB_GetToken                                                                              |
-- |                                                                                                     |
-- |  Description: Package to call AJB service to getToken for cc value                                  |
-- |                                                                                                     |
-- |  Rice ID: C0705                                                                                 |
-- +=====================================================================================================+
-- | Version     Date         Author               Remarks                                               |
-- | =========   ===========  =============        ======================================================|
-- |    1.0      01-Mar-2016  Avinash Baddam       Initial Version                                       |
---+=====================================================================================================+
    FUNCTION getToken(Timeout NUMBER, AJBServerIP VARCHAR2, Port NUMBER, request_message VARCHAR2) return VARCHAR2; 
    
    PROCEDURE get_cc_token(p_cc_value IN VARCHAR2,p_token OUT NOCOPY VARCHAR2, x_error_message OUT NOCOPY VARCHAR2);
END; 
/
SHOW ERROR