SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                  Office Depot - CR-798							|
-- +============================================================================================+
-- | Name        : xxcrm_remitto_sales_batch_pkg.pks                                            |
-- | Description : This procedure is One time Script to update                                  |
-- |		   Remit to sale channel.                                                       |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        08/07/11       Devendra Petkar        Initial version                            |
-- +============================================================================================+

CREATE OR REPLACE PACKAGE xxcrm_remitto_sales_batch_pkg
-- +====================================================================+
-- |                  Office Depot -  Ebiz to SFDC Conversion.		|
-- +====================================================================+
-- | Name       :  xxcrm_remitto_sales_batch_pkg		        |
-- | Description: This procedure is One time Script to update		|
-- |		  Remit to sale channel.				|
-- |									|
-- |									|
-- |									|
-- |Change Record:							|
-- |===============							|
-- |Version   Date        Author           Remarks			|
-- |=======   ==========  =============    =============================|
-- |V 1.0    08/07/11   Devendra Petkar					|
-- +====================================================================+
AS


-- +===================================================================+
-- | Name             : update_remitto_sales                           |
-- | Description      : This procedure is One time Script to update    |
-- |			Remit to sale channel.	                       |
-- |                                                                   |
-- | parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE update_remitto_sales(
    x_errbuf OUT NOCOPY  VARCHAR2,
    x_retcode OUT NOCOPY NUMBER,
    P_COMMIT   IN VARCHAR2 DEFAULT 'N',
    p_start_date IN VARCHAR2 DEFAULT NULL,
    p_end_date   IN VARCHAR2 DEFAULT NULL )    ;


END xxcrm_remitto_sales_batch_pkg;
/
SHOW ERRORS;

EXIT;
