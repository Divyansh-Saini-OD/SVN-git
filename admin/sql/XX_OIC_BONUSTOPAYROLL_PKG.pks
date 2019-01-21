SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE XX_OIC_BONUSTOPAYROLL_PKG
AS
        -- +===================================================================+
        -- |                  Office Depot - Project Simplify                  |
        -- |                       WIPRO Technologies                          |
        -- +===================================================================+
        -- | Name       :  XX_OIC_BONUSTOPAYROLL_PKG                           |
        -- | Rice ID    :  I0607_IncentiveAndBonusToPayroll                    |
        -- | Description:  This package contains procedure to update audit     |
        -- |               history table.                                      |
        -- |                                                                   |
        -- |Change Record:                                                     |
        -- |===============                                                    |
        -- |Version   Date        Author           Remarks                     |
        -- |=======   ==========  =============    ============================|
        -- |1.0      23-SEP-2007  Rizwan           Initial draft version       |
        -- |                                                                   |
        -- |                                                                   |
        -- +===================================================================+

        -- +===================================================================+
        -- | Name             : Maintain_Audit_History                         |
        -- | Description      : This procedure update the status of Payroll    |
        -- |                    transmission in the audit history table at     |
        -- |                    various stages.                                |
        -- |                                                                   |
        -- | parameters :      p_payrun (Payrun||':'||Operating Unit)          |
        -- |                   p_bpel_transfer_date                            |
        -- |                   p_transfer_status                               |
        -- |                   p_reason                                        |
        -- |                   p_log                                           |
        -- |                   p_user_name                                     |
        -- |                   p_resp_name                                     |
        -- |                                                                   |
        -- | retutns:          x_status                                        |
        -- |                   x_message                                       |
        -- |                                                                   |
        -- +===================================================================+

PROCEDURE Maintain_Audit_History(p_payrun                   IN      VARCHAR2
                                ,p_bpel_transfer_date       IN      DATE
                                ,p_transfer_status          IN      VARCHAR2
                                ,p_reason                   IN      VARCHAR2
                                ,p_log                      IN      VARCHAR2
                                ,p_user_name                IN      VARCHAR2
                                ,p_resp_name                IN      VARCHAR2 
                                ,x_status                   OUT     VARCHAR2
                                ,x_message                  OUT     VARCHAR2);


END XX_OIC_BONUSTOPAYROLL_PKG;
/
SHOW ERRORS;