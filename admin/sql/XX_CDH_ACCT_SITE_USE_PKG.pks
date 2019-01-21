create or replace
PACKAGE XX_CDH_ACCT_SITE_USE_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_ACCT_SITE_USE_PKG.pks                       |
-- | Description :  Custom Account Site Usage package to nullify       |
-- |                inactive BILL_TO usages tied to a SHIP_TO.         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- | 1        12-Nov-2008 Naga Kalyan        Initial Draft.            |
-- +===================================================================+
AS
--+=========================================================================================================+
--| PROCEDURE  : update_shipto_use                                                                          |
--| p_bill_to_osr           IN   hz_cust_acct_sites_all.orig_system_reference%TYPE                          |
--|                              Site OSR of inactivated BILL_TO usage                                      |
--| x_return_status         OUT  VARCHAR2   Returns return status                                           |
--| x_error_message         OUT  VARCHAR2   Returns return message                                          |
--| x_msg_count             OUT  VARCHAR2   Returns error message count                                     |
--+=========================================================================================================+
PROCEDURE update_shipto_use (
      p_bill_to_osr            IN       hz_cust_acct_sites_all.orig_system_reference%TYPE,
      x_return_status          OUT      NOCOPY VARCHAR2,
      x_error_message	         OUT      NOCOPY VARCHAR2,
      x_mSg_count              OUT      NOCOPY NUMBER
   );
END XX_CDH_ACCT_SITE_USE_PKG;
/