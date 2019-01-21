SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_CRM_CREATE_ACCESSES_PKG

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_CRM_CREATE_ACCESSES_PKG
AS

-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name        : XX_CRM_CREATE_ACCESSES_PKG                                    |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      02-JUL-2010  Vasan Santhanam       Initial version             |
-- +========================================================================+

-- +========================================================================+
-- | Name        : CREATE_MISSING_ACCESSES                                     |
-- | Description : 1)Insert a row into Accesses table where the row not exist |
-- |                                                                        |
-- |                                                                        |
-- |                            "|
-- |                                                                        |
-- | Returns     : x_error_buf, x_ret_code                                  |
-- +========================================================================+
   PROCEDURE CREATE_MISSING_ACCESSES ( x_error_buf          OUT VARCHAR2
                                     , x_ret_code           OUT NUMBER
                                     , p_opp_number         IN  VARCHAR2
                                     );
END XX_CRM_CREATE_ACCESSES_PKG;
/
SHOW ERRORS