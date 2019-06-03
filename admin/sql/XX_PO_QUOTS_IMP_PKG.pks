SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

PROMPT
PROMPT 'Creating XX_PO_QUOTS_IMP_PKG package specification'
PROMPT
CREATE OR REPLACE PACKAGE  XX_PO_QUOTS_IMP_PKG
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                Oracle NAIO/WIPRO/Office Depot/Consulting Organization     |
-- +===========================================================================+
-- | Name  :        XX_PO_QUOTS_IMP_PKG.pks                                    |
-- |                                                                           |
-- | This package contains the following sub programs:                         |
-- | =================================================                         |
-- |Type         Name          Description                                     |
-- |=========    ===========  =================================================|
-- |PROCEDURE    batch_main   This procedure is invoked from OD:PO Quotations  |
-- |                          Conversion Master Concurrent Request.This would  |
-- |                          submit child programs based on batch_size.       |
-- |                                                                           |
-- |PROCEDURE    main         This Procedure picks the records from the staging|
-- |                          table for belonging to that batch,validates them | 
-- |                          and processes them by calling the  custom API to |
-- |                          import the records to EBS tables.                |
-- |                                                                           |
-- |Version   Date        Author           Remarks                             |
-- |=======   ==========  =============    ====================================|
-- |Draft 1a  16-MAY-2007 Chandan U H      Initial draft version with Master   |
-- |                                       Conversion  Program Logic.          |
-- |Draft 1b  23-MAY-2007 Chandan U H      Incorporated Review Comments.       |
-- | 1.0      25-MAY-2007 Chandan U H      Baselined.                          |   
-- +===========================================================================+ 


AS

PROCEDURE batch_main       (
                             x_errbuf                  OUT     VARCHAR2
                            ,x_retcode                 OUT     NUMBER                         
                            ,p_validate_only_flag      IN      VARCHAR2
                            ,p_reset_status_flag       IN      VARCHAR2
                             );

PROCEDURE  main             (
                              x_errbuf                OUT     VARCHAR2
                             ,x_retcode               OUT     NUMBER                          
                             ,p_validate_only_flag    IN      VARCHAR2
                             ,p_reset_status_flag     IN      VARCHAR2
                             ,p_batch_id              IN      NUMBER
                            );

END  XX_PO_QUOTS_IMP_PKG;
/
SHOW ERRORS;
EXIT;
