create or replace
PACKAGE  XX_PA_CREATE_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :OD:PA Projects Interface                                    |
-- | Description : To get the Projects detail from                     |
-- |                legacy system(EJM) to Oracle Project Accounting.   |
-- |                                                                   |
-- |                                                                   |
-- | Change Record:                                                    |
-- | ===============                                                   |
-- | Version   Date          Author              Remarks               |
-- | =======   ==========   =============        ======================|
-- | 1.0       26-MAR-2007  Raj Patel            Initial version       |
-- | 2.0       02-JUL-2007  Raj Patel                                  |
-- | 2.1       03-NOV-2007  Raghu                added code to trap API|
-- |                                             error.		       |
-- | 2.2       04-JAN-2008  KK		         Added to code to      |
-- | 						 handle defect 3152    |
-- | 3.0       22-MAR-2012  P.Marco              EJM Rewrite for SOA   |
-- |                                             PR000370              | 
-- | 3.1       28-JUN-2012 P.Marco               Defect 19010          |
-- |                                             Fix Error handling    |
-- |                                             Format Email notifica-|
--|                                              tion                  |
-- +===================================================================+
-- +===================================================================+
-- | Name  : XX_PA_GET_PROJECT_DATA                                    |
-- | Description      : This Procedure will be used to fetch Proejct   |
-- |                    data from source system(SQL SERVER) and        |
-- |                    if successfully then update with "R"           |
-- |                    otherwise update with "E" and send error       |
-- |                    notification.                                  |
-- |                                                                   |
-- | Parameters :       p_pm_product_code,p_budget_type,               |
-- |                    p_budget_entry_mth_code,                       |
-- |                    p_resource_list_id,p_email_addr                |
-- | Returns    :       x_error_code,x_error_buff                      |
-- +===================================================================+

  PROCEDURE SERVICE_EJM_QUEUE(

     p_proj_rec                IN XX_PA_EJM_PROJ_INT_TBL
    ,p_debug_flag              IN  VARCHAR2
    ,x_email_status            OUT VARCHAR2
    ,x_email_message           OUT VARCHAR2
    ,x_proj_out_tbl            OUT XX_PA_EJM_PROJ_OUT_TBL
  );


END XX_PA_CREATE_PKG;

/
