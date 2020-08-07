SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE XX_OM_OFP_FRAUD_POOL_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       OD Staff                                    |
-- +===================================================================+
-- | Name  :  xx_om_ofp_fraud_pool_pkg                                 |
-- | Description:  Following actions done through this package         |
-- |                    1. Release hold on the order                   |
-- |                    2. Cancel the hold on an order                 |
-- |                    3. Update hold information on an order         |
-- |               The action required will depend on the ACTION passed|
-- |               by the front end pools program.                     |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 29-Sep-2007  Dedra Maloy      Initial draft version       |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

AS

  lrec_exception_obj_type xx_om_report_exception_t:=
                          xx_om_report_exception_t(NULL
                                                  ,NULL
                                                  ,NULL
                                                  ,NULL
                                                  ,NULL
                                                  ,NULL
                                                  ,NULL
                                                  ,NULL);

   -- +===================================================================+
   -- | Name  : fraud_log_exceptions                                      |
   -- | Description: This procedure will be responsible to store all      |
   -- |              the exceptions occured during the procees using      |
   -- |              global custom exception handling framework           |
   -- |                                                                   |
   -- | Parameters:  IN:                                                  |
   -- |     P_Error_Code        --Custom error code                       |
   -- |     P_Error_Description --Custom Error Description                |
   -- |     p_exception_header  --Errors occured under the exception      |
   -- |                           'NO_DATA_FOUND / OTHERS'                |
   -- |     p_entity_ref        --'Hold id'                               |
   -- |     p_entity_ref_id     --'Value of the Hold Id'                  |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE fraud_log_exceptions( p_error_code        IN  VARCHAR2
                                  ,p_error_description IN  VARCHAR2
                                  ,p_entity_ref        IN  VARCHAR2
                                  ,p_entity_ref_id     IN  PLS_INTEGER
                                 );
   -- +===================================================================+
   -- | Name  : Fraud_Pool                                                |
   -- | Description: This procedure is called by the front end pool       |
   -- |              processing programs for fraud.  The actions          |
   -- |              'Approve', 'Cancel', and 'Hold' will update the      |
   -- |              order and XX_OM_POOL_RECORDS_ALL appropriately       |
   -- | Parameters:  IN:                                                  |
   -- |     p_pool_id           --pool id sent from front end 'OFP'       |
   -- |     p_order_header_id   --order from the front end needing action |
   -- |     p_hold_id           --type of hold sent by the front end      |
   -- |     p_action            --'Approve','Cancel','Hold'               |
   -- |     p_CSR               --Identifies the CSR performing the action|
   -- | Parameters OUT                                                    |
   -- |     x_retcode           --return the status to the front end      |
   -- |                           'S' is success                          |
   -- |                           'E' is error                            |
   -- |                           'U' is unexpected error                 |
   -- |     x_err_buff          --return error information                |
   -- +===================================================================+
 
      PROCEDURE Fraud_Pool (p_pool_id          IN VARCHAR2 
                           ,p_order_header_id  IN NUMBER 
                           ,p_release_comments IN VARCHAR2
                           ,p_hold_id          IN NUMBER
                           ,p_action           IN VARCHAR2
                           ,p_csr_id           IN NUMBER
                           ,p_context          IN VARCHAR2
                           ,x_ret_code         OUT NOCOPY VARCHAR2
                           ,x_err_buff         OUT NOCOPY VARCHAR2
                           );

END XX_OM_OFP_FRAUD_POOL_PKG;
/
EXIT
/
   
