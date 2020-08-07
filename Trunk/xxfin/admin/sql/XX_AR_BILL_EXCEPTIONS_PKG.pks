create or replace
PACKAGE XX_AR_BILL_EXCEPTIONS_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_AR_BILL_EXCEPTIONS_PKG                                    |
-- | RICE ID :  R0539                                                    |
-- | Description :This package is to validate billing exceptions         |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  15-FEB-09      Jennifer Jegam         Initial version      |
-- |1.1       28-FEB-09     Kantharaja           Changes for             |
-- |                        Velayutham           the defect#13420        |
-- |                                                                     |
-- +=====================================================================+

PROCEDURE XX_AR_BILL_MAIN_PROC(
                               x_err_buff           OUT VARCHAR2 --Added for the defect#13420
                              ,x_ret_code           OUT NUMBER   --Added for the defect#13420
                              --,p_cust_id_from       IN  NUMBER   --Added for the defect#13420
                              --,p_cust_id_to         IN  NUMBER   --Added for the defect#13420
                              ,p_request_id         IN  NUMBER   --Added for the defect#13420
                              --,p_last_upd_date_from IN  DATE     --Added for the defect#13420
                              --,p_last_upd_date_to   IN  DATE     --Added for the defect#13420
                              );

PROCEDURE XX_AR_BILL_INSERT_PROC(p_customerid      NUMBER
                                ,p_cust_number     VARCHAR2
			                       ,p_cust_name       VARCHAR2
			                       ,p_legacy_number   VARCHAR2
			                       ,p_delivery_method VARCHAR2
			                       ,p_paydoc_ind      VARCHAR2
			                       ,p_cust_doc_id     NUMBER
			                       ,p_send_to_addr    VARCHAR2
			                       ,p_code            VARCHAR2
                                ,p_request_id      NUMBER   --Added for the defect#13420
                                );

PROCEDURE XX_AR_BILL_COMBO_PROC(p_customerid      NUMBER
                               ,p_cust_number     VARCHAR2
			                      ,p_cust_name       VARCHAR2
			                      ,p_legacy_number   VARCHAR2
			                      ,p_delivery_method VARCHAR2
			                      ,p_paydoc_ind      VARCHAR2
			                      ,p_cust_doc_id     NUMBER
			                      ,p_send_to_addr    VARCHAR2
                               ,p_request_id      NUMBER   --Added for the defect#13420
                               );

PROCEDURE XX_AR_BILL_SITE_PROC(p_customerid         NUMBER
                               ,p_cust_number       VARCHAR2
			                      ,p_cust_name         VARCHAR2
			                      ,p_legacy_number     VARCHAR2
			                      ,p_delivery_method   VARCHAR2
			                      ,p_paydoc_ind        VARCHAR2
			                      ,p_cust_doc_id       NUMBER
			                      ,p_send_to_addr      VARCHAR2
                               ,p_request_id        NUMBER   --Added for the defect#13420
                               );

PROCEDURE XX_AR_BILL_INDIRECT_PROC(p_customerid           NUMBER
                                   ,p_cust_number         VARCHAR2
			                          ,p_cust_name           VARCHAR2
			                          ,p_legacy_number       VARCHAR2
			                          ,p_delivery_method     VARCHAR2
			                          ,p_paydoc_ind          VARCHAR2
			                          ,p_cust_doc_id         NUMBER
			                          ,p_send_to_addr        VARCHAR2
                                   ,p_request_id          NUMBER);   --Added for the defect#13420

--Commented for the defect#13420
/*
PROCEDURE XX_AR_BILL_EXC_EXCEL_PROC(
                                   x_err_buff      OUT VARCHAR2
                                  ,x_ret_code      OUT NUMBER
				  );
*/

--Added for the defect#13420
PROCEDURE XX_AR_BILL_EXC_EXCEL_PROC(
                                    p_mast_req_id IN  NUMBER
                                   ,x_request_id  OUT NUMBER
                                   ,p_format      IN  VARCHAR2
                                   );

PROCEDURE XX_AR_INFODOC_FREQ_PROC(p_customerid       NUMBER
                                 ,p_cust_number      VARCHAR2
                                 ,p_cust_name        VARCHAR2
                                 ,p_legacy_number    VARCHAR2
                                 ,p_delivery_method  VARCHAR2
                                 ,p_paydoc_ind       VARCHAR2
                                 ,p_cust_doc_id      NUMBER
                                 ,p_send_to_addr     VARCHAR2
                                 ,p_request_id       NUMBER
                                 );       --Added for the defect#13420

--Added the procedure for the defect#13420
-- +=====================================================================+
-- | Name        : XX_AR_BILL_EX_MASTER_PROC                             |
-- | Description : The procedure will call the child program             |
-- |               OD: AR Billing Exceptions Child using batching and    |
-- |               multi-threading                                       |
-- | Parameters  :p_batch_size,p_format_type                             |
-- | Returns     :x_err_buff,x_ret_code                                  |
-- +=====================================================================+

PROCEDURE XX_AR_BILL_EX_MASTER_PROC(
                                    x_err_buff           OUT VARCHAR2
                                   ,x_ret_code           OUT NUMBER
                                   ,p_batch_size         IN  NUMBER
                                   ,p_format_type        IN VARCHAR2
                                   ,p_last_upd_date_from IN  VARCHAR2  --Changed the data type to varchar for 13420
                                   ,p_last_upd_date_to   IN  VARCHAR2  --Changed the data type to varchar for 13420
                                   );

END XX_AR_BILL_EXCEPTIONS_PKG;
/
SHO ERR;
