create or replace package XX_PO_RCV_ADJ_INT_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_PO_RCV_ADJ_INT_PKG                                                       |
-- |  RICE ID 	 :  I2194_WMS_Receipts_to_EBS_Interface  			                |
-- |  Description:         								        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         04/25/2017   Avinash Baddam   Initial version                                  |
-- +============================================================================================+
              
PROCEDURE load_staging(p_errbuf       OUT  VARCHAR2
                      ,p_retcode      OUT  VARCHAR2
                      ,p_filepath          VARCHAR2
                      ,p_file_name 	   VARCHAR2
                      ,p_debug             VARCHAR2);
                      
PROCEDURE interface_child(p_errbuf       OUT  VARCHAR2
                         ,p_retcode      OUT  VARCHAR2
                         ,p_batch_id          NUMBER
                      	 ,p_debug             VARCHAR2);
                      	  
PROCEDURE interface_master(p_errbuf       OUT  VARCHAR2
                          ,p_retcode      OUT  VARCHAR2
                      	  ,p_child_threads     NUMBER
                      	  ,p_retry_errors      VARCHAR2
                      	  ,p_debug             VARCHAR2);
                      	  
END XX_PO_RCV_ADJ_INT_PKG;
/