SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
Prompt Creating package spec XX_CDH_CUST_ACHID... ;

CREATE OR REPLACE PACKAGE XX_CDH_CUST_ACHID

-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_CDH_CUST_ACHID                                           |
-- | Description :                                                             |
-- | This package helps us to get the list of Accounts with ACH_ID's. Used in  |
-- | Program: OD: CDH Customer ACHID List                                      |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 11-MAY-2011 Srini         Initial draft version                   |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

AS
-- +===========================================================================+
-- |                                                                           |
-- | Name        : LIST_ACHID_CUSTOMERS                                        |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure is to get the list of Accounts with ACH_ID's. This         |
-- | procedure is used in Concurrent Program: OD: CDH ACH Sending Id List.     |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
  
  PROCEDURE LIST_ACHID_CUSTOMERS
  (
       x_errbuf            OUT VARCHAR2
     , x_retcode           OUT NUMBER
  );


-- +===========================================================================+
-- |                                                                           |
-- | Name        : VALIDATE_RESP_ACCESS                                        |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure is to make sure that the Responsibility have access to     |
-- | update each attribute group. This procedure is called from ATTRGROUP page.|
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
  
  PROCEDURE VALIDATE_RESP_ACCESS
  (
       P_ATTRIBUTE_GROUP  IN  VARCHAR2
     , P_MESSAGE          OUT VARCHAR2
     , P_STATUS           OUT VARCHAR2
  );
  

-- +===========================================================================+
-- |                                                                           |
-- | Name        : VALIDATE_ACH_ID                                             |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure is to make sure that ACH_ID is valid (No Duplicate values).|
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
  
  PROCEDURE VALIDATE_ACH_ID
  (
       P_CUST_ACCOUNT_ID  IN  NUMBER
     , P_ACH_ID           IN  VARCHAR2
     , P_MESSAGE          OUT VARCHAR2
     , P_STATUS           OUT VARCHAR2
  );
  
  END XX_CDH_CUST_ACHID;
/

  
SHOW ERRORS;
