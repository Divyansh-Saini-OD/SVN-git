create or replace package XX_PO_RCV_INT_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_PO_RCV_INT_PKG                                                               |
-- |  RICE ID 	 :  I2194_WMS_Receipts_to_EBS_Interface  			                            |
-- |  Description:         								                                        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         04/25/2017   Avinash Baddam   Initial version                                  |
-- | 1.1         10/31/2017   Havish Kasina    Added the new parameters in the procedure        |
-- |                                           mtl_transaction_int                              |
-- +============================================================================================+

PROCEDURE mtl_transaction_int(p_errbuf       		OUT  VARCHAR2,
                      	      p_retcode      		OUT  VARCHAR2,
			                  p_transaction_type_name 	 VARCHAR2,
			                  p_inventory_item_id	     NUMBER,
			                  p_organization_id		     NUMBER,
			                  p_transaction_qty		     NUMBER,
			                  p_transaction_cost	     NUMBER,
			                  p_transaction_uom_code 	 VARCHAR2,
			                  p_transaction_date	     DATE,
			                  p_subinventory_code	     VARCHAR2,
			                  p_transaction_source	     VARCHAR2,
			                  p_vendor_site		         VARCHAR2,
							  p_original_rtv             VARCHAR2,  -- Added as per Version 1.1
							  p_rga_number               VARCHAR2,
							  p_freight_carrier          VARCHAR2,
							  p_freight_bill             VARCHAR2,
							  p_vendor_prod_code         VARCHAR2,
							  p_sku                      VARCHAR2,
							  p_location                 VARCHAR2);
              
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
                      	  
END XX_PO_RCV_INT_PKG;
/