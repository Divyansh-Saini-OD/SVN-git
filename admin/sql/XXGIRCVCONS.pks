CREATE OR REPLACE PACKAGE XX_CNV_GI_RCV_PKG
AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name 	 : PO, Inter-Org Transfer Rec, RTV Conversion          |
-- | Description : To convert the 'GI- RECEIPTS' that are fully        |
-- |		   received as well as partially received,             |
-- |		   from the OD Legacy system to Oracle EBS.	       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       2-APR-2007  Murali Krishnan       Initial version        |
-- |                      Ramachandran                                 |
-- +===================================================================+
-- +===================================================================+
-- | Name        : xx_gi_conv_mst                                   |
-- | Description : To create the batches of Receipt Source Code and    |
-- |		   Receipt Number lines not exceeding 10000 records    |
-- |		   from the custom staging tables XX_GI_RCV_STG.       |
-- |		   It will call the "OD: GI Conversion		       |
-- |		   Child Program", "OD Conversion Exception Log Report",|
-- |		   "OD Conversion Processing Summary Report"
-- |		   for each batch.  This procedure will be the	       |
-- |		   executable of Concurrent program		       |
-- |		   "OD: RECEIVING TRANSACTION PROCESSOR" and  	       |
-- |               "OD: PROCESS TRANSACTIONS INTERFACE".               |
-- | Parameters : x_error_buff, x_ret_code,p_process_name,             |
-- |              ,p_validate_only_flag,p_reset_status_flag            |
-- +===================================================================+

    PROCEDURE xx_gi_conv_mst(
        x_error_buff         OUT VARCHAR2
       ,x_ret_code           OUT NUMBER
       ,p_process_name       IN VARCHAR2
       ,p_validate_only_flag IN VARCHAR2
       ,p_reset_status_flag  IN VARCHAR2);

-- +===================================================================+
-- | Name        : xx_gi_conv_chd                                    |
-- | Description : To perform translation, validations, Import of      |
-- |               Receipt Source Code and Receipt Number lines        |
-- |               not exceeding 10000 records, for each batch.        |
-- |               This procedure will be the executable of Concurrent |
-- |               Program "OD: RECEIVING TRANSACTION PROCESSOR" and   |
-- |			   "OD: PROCESS TRANSACTIONS INTERFACE".       |
-- | Parameters : x_error_buff, x_ret_code,p_process_name,             |
-- |              ,p_validate_only_flag,p_reset_status_flag,p_batch_id |
-- +===================================================================+
    PROCEDURE xx_gi_conv_chd(
        x_error_buff         OUT VARCHAR2
       ,x_ret_code           OUT NUMBER
       ,p_process_name       IN VARCHAR2
       ,p_validate_only_flag IN VARCHAR2
       ,p_reset_status_flag  IN VARCHAR2
       ,p_batch_id           IN NUMBER);

END XX_CNV_GI_RCV_PKG;
/
SHOW ERROR