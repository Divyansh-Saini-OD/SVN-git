SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_PA_TASK_MGR_ALLOC_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_TASK_MGR_ALLOC_PKG.pkb               |
-- | Description :  OD PB PA Task Manager Allocation                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       10-Jun-2008 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS

------------------------------------------------------------------------------------------------
--Declaring xx_pa_task_mgr_alloc
------------------------------------------------------------------------------------------------

PROCEDURE SEND_NOTIFICATION( p_subject IN VARCHAR2
                ,p_email_list IN VARCHAR2
                ,p_cc_email_list IN VARCHAR2
                ,p_text IN VARCHAR2 );

PROCEDURE xx_pa_task_mgr_alloc(  x_errbuf               OUT NOCOPY VARCHAR2
                        ,x_retcode              OUT NOCOPY VARCHAR2
                         ,p_project_no            IN  VARCHAR2
                ,p_agent        IN  VARCHAR2
                ,p_dept            IN  VARCHAR2
                ,p_US_COMPLIANCE    IN  NUMBER
                ,p_US_CREATIVE        IN  NUMBER
                ,p_US_DUTY_TARIFF     IN  NUMBER
                ,p_US_FINAL_COMP    IN  NUMBER
                ,p_US_PROD_DEV        IN  NUMBER
                ,p_US_PROD_SUPP     IN  NUMBER
                ,p_US_QA        IN  NUMBER
                ,p_GSO_COMP        IN  NUMBER
                ,p_GSO_MO        IN  NUMBER
                ,p_GSO_PE        IN  NUMBER
                ,p_GSO_PKG        IN  NUMBER
                ,p_GSO_QA        IN  NUMBER
                ,p_GSO_SPD        IN  NUMBER
                            );
END;
/
