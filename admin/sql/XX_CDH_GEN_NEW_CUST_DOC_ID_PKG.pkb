SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_GEN_NEW_CUST_DOC_ID
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CDH_GEN_NEW_CUST_DOC_ID                                 |
-- | Description : Package to generate new Cust Doc ID from extensibles screen|
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      05-Feb-2008 Sreedhar Mohan         Initial Version               |
-- |                                                                          |
-- +==========================================================================+
AS
  function GET_NEW_CUST_DOC_ID 
  return number is
  doc_id number;
  begin
    select xxcrm.xx_cdh_cust_doc_id_s.nextval
    into doc_id 
    from dual;
    return doc_id;
  end;
end XX_CDH_GEN_NEW_CUST_DOC_ID;
/

SHOW ERRORS;
