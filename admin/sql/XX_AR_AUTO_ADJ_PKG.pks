SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE SPEC XX_AR_AUTO_ADJ_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE APPS.XX_AR_AUTO_ADJ_PKG AS   
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |  Providge Consulting                                                                       |
-- +============================================================================================+
-- |  Name:  XX_AR_AUTO_ADJ_PKG                                                                 |
-- |  Description:  This package creates and approves adjustments using the API AR_ADJUST_PUB   |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         16-AUG-2010  Sneha Anand         Initial version                               |
-- +============================================================================================+


-- +============================================================================================+ 
-- |  Name: SET_DEBUG                                                                           | 
-- |  Description: This procedure turns on/off the debug mode.                                  |
-- |                                                                                            | 
-- |  Parameters:  p_debug - Debug Mode: TRUE=On, FALSE=Off                                     |
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          |
-- +============================================================================================+
PROCEDURE set_debug
( p_debug      IN      BOOLEAN       DEFAULT TRUE );

-- +============================================================================================+ 
-- |  Name: MASTER_PROGRAM                                                                      | 
-- |  Description: This procedure is the master program that handles the creation and approval  |
-- |               of Adjustments setup as a concurrent program that will be scheduled on a     |
-- |               regular basis.                                                               |
-- |                                                                                            | 
-- |                                                                                            | 
-- |  Returns:     x_error_buffer - std conc program output buffer                              |
-- |               x_return_code  - std conc program return value                               |
-- |                                (0=Success,1=Warning,2=Error)                               |
-- +============================================================================================+
PROCEDURE master_program
( x_error_buffer           OUT     VARCHAR2
 ,x_return_code            OUT     NUMBER
 ,p_org_id                 IN      NUMBER
 ,p_currency_code          IN      VARCHAR2
 ,p_amount_rem_low         IN      NUMBER
 ,p_amount_rem_high        IN      NUMBER
 ,p_due_date_low           IN      VARCHAR2
 ,p_due_date_high          IN      VARCHAR2
 ,p_cust_trx_id_low        IN      NUMBER
 ,p_cust_trx_id_high       IN      NUMBER
 ,p_activity_id            IN      NUMBER);


-- +============================================================================================+ 
-- |  Name: MULTI_THREAD_MASTER                                                                 | 
-- |  Description: This procedure is the master program that handles the multi thread concept   |
-- |               used for submission of multiple threads of Adjustment creation and approval  |
-- |                                                                                            | 
-- |                                                                                            | 
-- |  Returns:     x_error_buffer - std conc program output buffer                              |
-- |               x_return_code  - std conc program return value                               |
-- |                                (0=Success,1=Warning,2=Error)                               |
-- +============================================================================================+
PROCEDURE multi_thread_master
( x_error_buffer           OUT     VARCHAR2
 ,x_return_code            OUT     NUMBER
 ,p_org_id                 IN      NUMBER
 ,p_currency_code          IN      VARCHAR2
 ,p_amount_rem_low         IN      NUMBER
 ,p_amount_rem_high        IN      NUMBER
 ,p_due_date_low           IN      VARCHAR2
 ,p_due_date_high          IN      VARCHAR2
 ,p_activity_id            IN      NUMBER
 ,p_number_of_batches      IN      NUMBER
 ,p_submit_adj_api         IN      VARCHAR2);

  END;
/
SHO ERR