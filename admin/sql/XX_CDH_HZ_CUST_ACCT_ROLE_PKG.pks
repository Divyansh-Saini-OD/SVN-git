SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace package XX_CDH_HZ_CUST_ACCT_ROLE_PKG AUTHID CURRENT_USER

-- +======================================================================================+
-- |                  Office Depot - Project Simplify                                     |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
-- +======================================================================================|
-- | Name       : XX_CDH_HZ_CUST_ACCOUNT_ROLE_PKG                                         |
-- | Description: This package body is for linking  Contact, roles , Responsiblities      |
-- |                                                .                                     |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version     Date         Author               Remarks                                 |
-- |=======   ===========  ==================   ==========================================|
-- |DRAFT 1A  08-APR-2010  Mangala                Initial draft version                   |
-- +======================================================================================+
AS
      
-- +========================================================================================+
-- | Name             : CREATE_CUST_ACCOUNT_ROLE                                            |
-- | Description      : This procedure is for linking the Contact, Roles, Responsibilities  |
-- |                                                                                        |
-- |                                                                                        |
-- +========================================================================================+
procedure CREATE_CUST_ACCOUNT_ROLE(p_rel_party_id             IN  NUMBER,
                                   p_cust_account_id          IN  NUMBER,
                                   x_cust_account_role_id     OUT NUMBER,
                                   x_responsibility_id        OUT NUMBER,
                                   x_return_status            OUT VARCHAR2,
                                   x_msg_count                OUT NUMBER,
                                   x_msg_data                 OUT VARCHAR2
                                   );


-- +========================================================================================+
-- | Name             : CREATE_CUST_ACCOUNT_ROLE                                            |
-- | Description      : This procedure is for linking the Contact, Roles, Responsibilities  |
-- |                                                                                        |
-- |                                                                                        |
-- +========================================================================================+

PROCEDURE CREATE_CUST_ACCOUNT_ROLE(p_rel_party_id             IN  NUMBER,
                                   p_cust_account_id          IN  NUMBER,
                                   x_return_status            OUT VARCHAR2
                                   );

END XX_CDH_HZ_CUST_ACCT_ROLE_PKG;

/
SHOW ERRORS;