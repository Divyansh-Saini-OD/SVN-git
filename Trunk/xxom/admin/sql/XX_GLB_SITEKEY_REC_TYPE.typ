SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        Office Depot                               |
-- +===================================================================+
-- | Name             : CREATE_SITEKEY_object.sql                      |
-- | Rice ID          : I1176 CreateServiceRequest			     |
-- | Description      : This scipt creates the site key object that    |
-- | 			can be used in the PL/SQL APIs. 	       	     |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1   18-Dec-2007 Bibiana Penski    Initial Version            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROMPT
PROMPT Dropping OBJECT type XX_GLB_SITEKEY_REC_TYPE
PROMPT

DROP TYPE XX_GLB_SITEKEY_REC_TYPE FORCE;

PROMPT
PROMPT Creating OBJECT type XX_GLB_SITEKEY_REC_TYPE
PROMPT

CREATE or REPLACE TYPE XX_GLB_SITEKEY_REC_TYPE AS OBJECT (
    site_brand      VARCHAR2(40)
,   site_mode       VARCHAR2(40)
,   country_code    VARCHAR2(2)
,   language_code	  VARCHAR2(2)
,   operating_unit  NUMBER(15)
,   order_source    VARCHAR2(40) 
,   site_key_id	  NUMBER
);
/                                                                                                            

WHENEVER SQLERROR EXIT 1 
PROMPT 
PROMPT Exiting.... 
PROMPT 

SET FEEDBACK ON 

EXIT; 
