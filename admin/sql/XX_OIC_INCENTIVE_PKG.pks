SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OIC_INCENTIVE_PKG
-- +===================================================================================== +
-- |                  Office Depot - Project Simplify                                     |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
-- +===================================================================================== +
-- |                                                                                      |
-- | Name             :  XX_OIC_INCENTIVE_PKG                                             |
-- | Description      : This custom package extracts the OIC Payment details              |
-- |                    from Oracle Incentive Compensation and populates the custom table |
-- |                    XX_OIC_PAYMENT_DETAILS_STG.This will also purge the payment table |
-- |                    and the audit table                                               |
-- |                                                                                      |
-- | This package contains the following sub programs:                                    |
-- | =================================================                                    |
-- |Type         Name                  Description                                        |
-- |=========    ===========           ================================================   |
-- |PROCEDURE    MAIN_PROC             This procedure will be used to extract the         |
-- |                                   OIC payment details and to raise the custom        |
-- |                                   business event                                     |                                
-- |PROCEDURE    PURGE_PROC            This procedure will be used to purge the custom    |
-- |                                   payment details and audit history table            |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version   Date         Author           Remarks                                       |
-- |=======   ==========   =============    ============================================= |
-- |Draft 1a  27-Aug-2007  Gowri Nagarajan  Initial draft version                         |
-- |Draft 1b  04-Oct-2007  Susheel Raina    Reviewed and Updated                          |
-- +===================================================================================== +

AS
   -- ---------------------------
   -- Global Variable Declaration
   -- ---------------------------



   PROCEDURE MAIN_PROC
                     (
                       x_errbuf           OUT VARCHAR2
                     , x_retcode          OUT NUMBER
                     , p_period           IN  VARCHAR2
                     , p_payrun           IN  VARCHAR2
                     );

   PROCEDURE PURGE_PROC
                     (
                       x_errbuf           OUT VARCHAR2
                     , x_retcode          OUT NUMBER                     
                     );


END  XX_OIC_INCENTIVE_PKG;
/
SHOW ERRORS;

EXIT

REM============================================================================================
REM                                   End Of Script
REM============================================================================================