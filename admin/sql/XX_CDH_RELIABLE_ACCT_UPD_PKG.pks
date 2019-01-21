create or replace PACKAGE XX_CDH_RELIABLE_ACCT_UPD_PKG

-- +===========================================================================+
-- |                  Office Depot - Office Max Integration Project            |
-- +===========================================================================+
-- | Name        : XX_CDH_RELIABLE_ACCT_UPD_PKG                                |
-- | RICE        : I3092                                                       |
-- |                                                                           |
-- | Description :                                                             |
-- | This package helps is to update the credit limits and update OMX number   |
-- | for Reliable Customer                                                     |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author            Remarks                             |
-- |======== =========== =============     ====================================|
-- |DRAFT 1  11-MAR-2015 Sreedhar Mohan    Initial draft version               |
-- +===========================================================================+

AS

  PROCEDURE main
  (
     x_errbuf                   OUT VARCHAR2
    ,x_retcode                  OUT NUMBER
    ,p_credit_limit_update       IN VARCHAR2  DEFAULT 'Y'
    ,p_reliable_number_update    IN VARCHAR2  DEFAULT 'Y'
    ,p_debug                     IN VARCHAR2  DEFAULT 'N'
    ,p_last_run_date             IN VARCHAR2    
    ,p_ap_contacts_update        IN VARCHAR2  DEFAULT 'Y'
  );

END XX_CDH_RELIABLE_ACCT_UPD_PKG;