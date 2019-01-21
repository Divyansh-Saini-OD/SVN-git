SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_EBL_UPD_CUST_PROFILE

-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_CDH_EBL_UPD_CUST_PROFILE                                 |
-- | Description :                                                             |
-- | This package helps us to update the customer Profiles when Pay Doc is     |
-- | Changed. This package is created as part of CR 738 (Mid-Cycle CR).        |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 17-MAR-2010 Srini         Initial draft version                   |
-- |                                                                           |
-- +===========================================================================+

AS
-- +===========================================================================+
-- |                                                                           |
-- | Name        : MAIN                                                        |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure is main procedure and this will call all other procedures  |
-- | as on required.                                                           |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
  
  PROCEDURE main
  (
      x_errbuf            OUT VARCHAR2
     ,x_retcode           OUT NUMBER
     ,p_cycle_date        IN  VARCHAR2
  );

-- +===========================================================================+
-- |                                                                           |
-- | Name        : CONVERT_INDIRECT_TO_DIRECT                                  |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure is change the customer set-up from Indirect to Direct.     |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
  
  PROCEDURE convert_indirect_to_direct
  (
      p_cust_account_id   IN  NUMBER
    , x_error_message     OUT VARCHAR2
    , x_retcode           OUT VARCHAR2
  );


-- +===========================================================================+
-- |                                                                           |
-- | Name        : CONVERT_DIRECT_TO_INDIRECT                                  |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure is change the customer set-up from Direct to Indirect.     |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
  
  PROCEDURE convert_direct_to_indirect
  (
      p_cust_account_id   IN  NUMBER
    , x_error_message     OUT VARCHAR2
    , x_retcode           OUT VARCHAR2
  );

   
-- +===========================================================================+
-- |                                                                           |
-- | Name        : XX_UPDATE_CUST_PROFILE_PROC                                 |
-- |                                                                           |
-- | Description : This procedure is to update the payment term, consolidated  |
-- |               invoice flag and type.                                      |
-- |                                                                           |
-- +===========================================================================+
   PROCEDURE XX_UPDATE_CUST_PROFILE_PROC 
   (
      p_cust_account_id   IN      NUMBER
    , p_doc_type          IN      VARCHAR2
    , p_payment_term      IN      VARCHAR2
    , x_error_message     OUT     VARCHAR2
    , x_retcode           OUT     VARCHAR2
   );   
   
-- +===========================================================================+
-- |                                                                           |
-- | Name        : XX_UPDATE_CUST_PROFILE_PROC                                 |
-- |                                                                           |
-- | Description : This procedure is to update the payment term, consolidated  |
-- |               invoice flag and type.                                      |
-- |                                                                           |
-- +===========================================================================+
   PROCEDURE XX_UPDATE_CUST_PROFILE_PROC 
   (
      p_cust_account_id   IN      NUMBER
    , p_doc_type   IN      VARCHAR2
    , x_error_message     OUT     VARCHAR2
    , x_retcode           OUT     VARCHAR2
   );    

  
  END XX_CDH_EBL_UPD_CUST_PROFILE;
/

SHOW ERROR;
