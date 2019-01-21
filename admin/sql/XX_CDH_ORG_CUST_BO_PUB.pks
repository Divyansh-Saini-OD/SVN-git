SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_ORG_CUST_BO_PUB
-- +=========================================================================================+
-- |                  Office Depot                                                           |
-- +=========================================================================================+
-- | Name        : XX_CDH_ORG_CUST_BO_PUB                                             |
-- | Description :                                                                           |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |Draft 1a   15-Oct-2012     Sreedhar Mohan       Initial draft version                    |
-- +=========================================================================================+

AS

--IF CUSTOMER_TYPE IS NOT KNOWN AND NEED OUTPUT RESULT, USE THIS PROC                           
PROCEDURE process_account (
    p_xx_cdh_customer_bo   IN         HZ_ORG_CUST_BO,
    p_xx_cdh_ext_objs      IN         XX_CDH_EXT_BO_TBL,
    p_bpel_process_id      IN         NUMBER DEFAULT   0,
    p_cust_prof_cls_name   IN         VARCHAR2,
    p_ab_flag              IN         VARCHAR2,
    p_reactivated_flag     IN         VARCHAR2,
    p_created_by_module    IN         VARCHAR2,
    x_account_osr          OUT NOCOPY VARCHAR2,
    x_account_id           OUT NOCOPY NUMBER,
    x_party_id             OUT NOCOPY NUMBER,
    x_return_status        OUT NOCOPY VARCHAR2,
    x_errbuf               OUT NOCOPY VARCHAR2
);                           
--IF CUSTOMER_TYPE IS NOT KNOWN AND DON'T NEED OUTPUT RESULT, USE THIS PROC                           
PROCEDURE process_account (
    p_xx_cdh_customer_bo   IN         HZ_ORG_CUST_BO,
    p_xx_cdh_ext_objs      IN         XX_CDH_EXT_BO_TBL,
    p_bpel_process_id      IN         NUMBER DEFAULT   0,
    p_cust_prof_cls_name   IN         VARCHAR2,
    p_ab_flag              IN         VARCHAR2,
    p_reactivated_flag     IN         VARCHAR2,
    p_created_by_module    IN         VARCHAR2
);                           
 
PROCEDURE process_customer_data(
    p_bpel_process_id       IN         NUMBER DEFAULT   0,
    p_orig_system_reference IN         VARCHAR2
);
 
PROCEDURE sync_customer(
    p_bpel_process_id       IN         NUMBER DEFAULT   0,
    p_xx_cdh_customer_bo    IN         HZ_ORG_CUST_BO,
    p_xx_cdh_acct_ext_bo    IN         XX_CDH_ACCT_EXT_BO,
    p_orig_system_reference IN         VARCHAR2
);

PROCEDURE process_external_user(
    p_bpel_process_id       IN         NUMBER DEFAULT   0,
    p_xx_cdh_ext_user_bo    IN         XX_CDH_EXT_USER_BO,
    p_orig_system_reference IN         VARCHAR2
);

                           
END XX_CDH_ORG_CUST_BO_PUB;
/
SHOW ERRORS;